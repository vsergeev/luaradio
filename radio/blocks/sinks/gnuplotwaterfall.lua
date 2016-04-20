local ffi = require('ffi')
local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')
local spectrum_utils = require('radio.blocks.signal.spectrum_utils')

local GnuplotWaterfallSink = block.factory("GnuplotWaterfallSink")

function GnuplotWaterfallSink:instantiate(num_samples, title, options)
    self.num_samples = num_samples or 1024
    self.title = title or ""
    self.options = options or {}
    self.overlap = self.options.overlap or 0.00
    self.rows = self.options.plot_height or 64
    self.columns = num_samples
    self.num_psd_averages = 1
    self.min_magnitude = self.options.min_magnitude or -150
    self.max_magnitude = self.options.max_magnitude or 0

    assert(self.overlap < 1, "Overlap should be a fraction in [0.00, 1.00).")

    self:add_type_signature({block.Input("in", types.Float32Type)}, {})
    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {})
end

function GnuplotWaterfallSink:initialize()
    -- Check gnuplot exists
    assert(os.execute("gnuplot --version >/dev/null 2>&1") == 0, "gnuplot not found. Is gnuplot installed?")
end

function GnuplotWaterfallSink:initialize_gnuplot()
    local sample_rate = self:get_rate()
    local data_type = self:get_input_types()[1]

    -- Initialize gnuplot
    self.gnuplot_f = io.popen("gnuplot >/dev/null 2>&1", "w")
    self.gnuplot_f:write("set xtics\n")
    self.gnuplot_f:write("set ytics\n")
    self.gnuplot_f:write("set grid\n")
    self.gnuplot_f:write("set style data lines\n")
    self.gnuplot_f:write("set xlabel 'Frequency (Hz)'\n")
    self.gnuplot_f:write("set ylabel 'Time (s)'\n")
    self.gnuplot_f:write("unset key\n")
    self.gnuplot_f:write(string.format("set title '%s'\n", self.title))

    -- Calculate plot duration
    -- Plot Duration = Number of Rows * ( (PSD Length * Number of PSD Averages) / Sample Rate )
    self.plot_duration = self.rows * ((self.num_samples * self.num_psd_averages) / sample_rate)

    -- Use yrange if it was specified, otherwise default to autoscale
    if self.options.yrange then
        self.gnuplot_f:write(string.format("set yrange [%f:%f]\n", self.options.yrange[1], self.options.yrange[2]))
    else
        self.gnuplot_f:write(string.format("set yrange [0:%f]\n", -self.plot_duration))
    end

    -- Use xrange if it was specified, otherwise default to sample rate
    if self.options.xrange then
        self.gnuplot_f:write(string.format("set xrange [%f:%f]\n", self.options.xrange[1], self.options.xrange[2]))
    else
        -- Show onesided spectrum if input is real and onesided is enabled
        local onesided = (self.options.onesided == nil) and true or self.options.onesided

        if data_type == types.Float32Type and onesided then
           self.gnuplot_f:write(string.format("set xrange [0:%f]\n", sample_rate/2))
        else
           self.gnuplot_f:write(string.format("set xrange [%f:%f]\n", -sample_rate/2, sample_rate/2))
        end
    end

    -- Apply any extra settings
    if self.options.extra_settings then
        for i = 1, #self.options.extra_settings do
            self.gnuplot_f:write(self.options.extra_settings[i] .. "\n")
        end
    end

    -- Build plot string
    self.plot_str = string.format("plot '-' binary format='%%uchar' array=%dx%d origin=(%.3f,%.3f) dx=%.3f dy=%f with rgbimage\n", self.columns, self.rows, -sample_rate/2, -self.plot_duration, sample_rate/self.num_samples, self.plot_duration/self.rows)

    -- Build DFT context
    local window_type = self.options.window or "hanning"
    self.dft = spectrum_utils.DFT(self.num_samples, data_type, window_type, sample_rate)

    -- Create state buffer and counters
    self.state = data_type.vector(self.num_samples)
    self.state_index = 0
    self.num_overlap = math.floor(self.overlap*self.num_samples)

    -- Create our PSD averaging buffer
    self.psd_average = types.Float32Type.vector(self.num_samples)
    self.psd_average_count = 0

    -- Create our RGB pixel buffer
    self.pixels = ffi.new(string.format("uint8_t[%d][%d][3]", self.rows, self.columns))
end

local function normalize(value, min, max)
    return (math.max(math.min(value, max), min) - min) / (max - min)
end

local function value_to_pixel(value)
    local rgb
    if value < 1/5 then
        -- Black (0, 0, 0) to Blue (0, 0, 1)
        local c = math.floor(255*normalize(value, 0, 1/5))
        rgb = {0, 0, c}
    elseif value < 2/5 then
        -- Blue (0, 0, 1) to Green (0, 1, 0)
        local c = math.floor(255*normalize(value, 1/5, 2/5))
        rgb = {0, c, 255-c}
    elseif value < 3/5 then
        -- Green (0, 1, 0) to Yellow (1, 1, 0)
        local c = math.floor(255*normalize(value, 2/5, 3/5))
        rgb = {c, 255, 0}
    elseif value < 4/5 then
        -- Yellow (1, 1, 0) to Red (1, 0, 0)
        local c = math.floor(255*normalize(value, 3/5, 4/5))
        rgb = {255, 255 - c, 0}
    else
        -- Red (1, 0, 0) to White (1, 1, 1)
        local c = math.floor(255*normalize(value, 4/5, 5/5))
        rgb = {255, c, c}
    end

    return rgb
end

ffi.cdef[[
    void *memcpy(void *dest, const void *src, size_t n);
    void *memmove(void *dest, const void *src, size_t n);
]]

function GnuplotWaterfallSink:process(x)
    -- This implements Bartlett's/Welch's method for power spectral density
    -- estimation. See https://en.wikipedia.org/wiki/Bartlett%27s_method and
    -- https://en.wikipedia.org/wiki/Welch%27s_method for more information.

    if not self.gnuplot_f then
        self:initialize_gnuplot()
    end

    local sample_index = 0
    while sample_index < x.length do
        -- Fill our state buffer
        local num = math.min(self.num_samples - self.state_index, x.length - sample_index)
        ffi.C.memcpy(self.state.data + self.state_index, x.data + sample_index, num*ffi.sizeof(self.state.data[0]))

        -- Update indices
        self.state_index = self.state_index + num
        sample_index = sample_index + num

        if self.state_index == self.num_samples then
            -- Compute power spectrum
            local psd = self.dft:psd(self.state, true)

            -- Accumulate it in our average
            for i = 0, self.psd_average.length-1 do
                self.psd_average.data[i] = self.psd_average.data[i] + psd.data[i]
            end
            self.psd_average_count = self.psd_average_count + 1

            -- Shift overlap samples down
            ffi.C.memmove(self.state.data, self.state.data[self.num_samples - self.num_overlap], self.num_overlap*ffi.sizeof(self.state.data[0]))

            -- Reset state index to overlap
            self.state_index = self.num_overlap
        end

        if self.psd_average_count == self.num_psd_averages then
            -- Normalize our average
            for i = 0, self.psd_average.length-1 do
                self.psd_average.data[i].value = self.psd_average.data[i].value / self.psd_average_count
            end

            -- Shift pixels one row up
            ffi.C.memmove(self.pixels, self.pixels[1], (self.rows-1)*self.columns*3)

            -- Compute new pixel row
            for i = 0, self.columns-1 do
                local value = normalize(self.psd_average.data[i].value, self.min_magnitude, self.max_magnitude)
                self.pixels[self.rows-1][i] = value_to_pixel(value)
            end

            -- Reset psd average and count
            ffi.fill(self.psd_average.data, self.psd_average.size)
            self.psd_average_count = 0

            -- Plot waterfall
            self.gnuplot_f:write(self.plot_str)
            self.gnuplot_f:write(ffi.string(self.pixels, 3*self.rows*self.columns))
        end
    end
end

function GnuplotWaterfallSink:cleanup()
    if not self.gnuplot_f then
        return
    end

    self.gnuplot_f:write("quit\n")
    self.gnuplot_f:close()
end

return GnuplotWaterfallSink
