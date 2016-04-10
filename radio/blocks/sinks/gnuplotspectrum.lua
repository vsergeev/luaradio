local ffi = require('ffi')
local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')
local spectrum_utils = require('radio.blocks.signal.spectrum_utils')

local GnuplotSpectrumSink = block.factory("GnuplotSpectrumSink")

function GnuplotSpectrumSink:instantiate(num_samples, title, options)
    self.num_samples = num_samples or 1024
    self.title = title or ""
    self.options = options or {}
    self.update_time = self.options.update_time or 0.10
    self.overlap = self.options.overlap or 0.00
    self.reference_level = self.options.reference_level or 0.00

    assert(self.overlap < 1, "Overlap should be a fraction in [0.00, 1.00).")

    self:add_type_signature({block.Input("in", types.Float32Type)}, {})
    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {})
end

function GnuplotSpectrumSink:initialize()
    -- Check gnuplot exists
    assert(os.execute("gnuplot --version >/dev/null 2>&1") == 0, "gnuplot not found.")
end

function GnuplotSpectrumSink:initialize_gnuplot()
    local sample_rate = self:get_rate()
    local data_type = self.signature.inputs[1].data_type

    -- Initialize gnuplot
    self.gnuplot_f = io.popen("gnuplot >/dev/null 2>&1", "w")
    self.gnuplot_f:write("set xtics\n")
    self.gnuplot_f:write("set ytics\n")
    self.gnuplot_f:write("set grid\n")
    self.gnuplot_f:write("set style data lines\n")
    self.gnuplot_f:write("unset key\n")
    self.gnuplot_f:write("set xlabel 'Frequency (Hz)'\n")
    self.gnuplot_f:write("set ylabel 'Magnitude (dB)'\n")
    self.gnuplot_f:write(string.format("set title '%s'\n", self.title))

    -- Use xrange if it was specified, otherwise default to sample rate
    if self.options.xrange then
        self.gnuplot_f:write(string.format("set xrange [%f:%f]\n", self.options.xrange[1], self.options.xrange[2]))
    else
        -- Default to one-sided spectrum if input is real
        local onesided = (self.options.onesided == nil) and true or self.options.onesided

        if data_type == types.Float32Type and onesided then
            self.gnuplot_f:write(string.format("set xrange [0:%f]\n", sample_rate/2))
        else
            self.gnuplot_f:write(string.format("set xrange [%f:%f]\n", -sample_rate/2, sample_rate/2))
        end
    end

    -- Use yrange if it was specified, otherwise default to autoscale
    if self.options.yrange then
        self.gnuplot_f:write(string.format("set yrange [%f:%f]\n", self.options.yrange[1], self.options.yrange[2]))
    else
        self.gnuplot_f:write("set autoscale y\n")
    end

    -- Apply any extra settings
    if self.options.extra_settings then
        for i = 1, #self.options.extra_settings do
            self.gnuplot_f:write(self.options.extra_settings[i] .. "\n")
        end
    end

    -- Build plot string
    self.plot_str = string.format("plot '-' binary format='%%float32' array=%d origin=(%.3f,0) dx=%.3f using 1\n", self.num_samples, -sample_rate/2, sample_rate/self.num_samples)

    -- Build DFT context
    local window_type = self.options.window or "hamming"
    self.dft = spectrum_utils.DFT(self.num_samples, data_type, window_type, sample_rate)

    -- Create state buffer and counters
    self.state = data_type.vector(self.num_samples)
    self.state_index = 0
    self.sample_count = 0
    self.num_overlap = math.floor(self.overlap*self.num_samples)
    self.num_plot_update = math.floor(self.update_time*sample_rate)

    -- Create our PSD averaging buffer
    self.psd_average = types.Float32Type.vector(self.num_samples)
    self.psd_average_count = 0
end

ffi.cdef[[
    void *memcpy(void *dest, const void *src, size_t n);
    void *memmove(void *dest, const void *src, size_t n);
]]

function GnuplotSpectrumSink:process(x)
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
        self.sample_count = self.sample_count + num
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

        if self.sample_count >= self.num_plot_update and self.psd_average_count > 0 then
            -- Normalize our average
            for i = 0, self.psd_average.length-1 do
                self.psd_average.data[i].value = (self.psd_average.data[i].value / self.psd_average_count) - self.reference_level
            end

            -- Plot power spectrum
            self.gnuplot_f:write(self.plot_str)
            self.gnuplot_f:write(ffi.string(self.psd_average.data, self.psd_average.length*ffi.sizeof(self.psd_average.data[0])))

            -- Reset psd average and count
            ffi.fill(self.psd_average.data, self.psd_average.size)
            self.psd_average_count = 0

            -- Reset sample count
            self.sample_count = 0
        end
    end
end

function GnuplotSpectrumSink:cleanup()
    if not self.gnuplot_f then
        return
    end

    self.gnuplot_f:write("quit\n")
    self.gnuplot_f:close()
end

return {GnuplotSpectrumSink = GnuplotSpectrumSink}
