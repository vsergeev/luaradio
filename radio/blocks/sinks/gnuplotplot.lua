local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local GnuplotPlotSink = block.factory("GnuplotPlotSink")

function GnuplotPlotSink:instantiate(num_samples, title, options)
    self.num_samples = num_samples
    self.title = title or ""
    self.options = options or {}

    self.sample_count = 0

    self:add_type_signature({block.Input("in", types.Float32Type)}, {})
end

function GnuplotPlotSink:initialize()
    -- Check gnuplot exists
    assert(os.execute("gnuplot --version >/dev/null 2>&1") == 0, "gnuplot not found.")
end

function GnuplotPlotSink:initialize_gnuplot()
    -- Initialize gnuplot
    self.gnuplot_f = io.popen("gnuplot >/dev/null 2>&1", "w")
    self.gnuplot_f:write("set xtics\n")
    self.gnuplot_f:write("set ytics\n")
    self.gnuplot_f:write("set grid\n")
    self.gnuplot_f:write("set style data linespoints\n")
    self.gnuplot_f:write("unset key\n")
    self.gnuplot_f:write(string.format("set xlabel '%s'\n", self.options.xlabel or "Sample Number"))
    self.gnuplot_f:write(string.format("set ylabel '%s'\n", self.options.ylabel or "Value"))
    self.gnuplot_f:write(string.format("set title '%s'\n", self.title))

    -- Autoscale x
    self.gnuplot_f:write("set autoscale x\n")

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
    self.plot_str = string.format("plot '-' binary format='%%float32' array=%d using 1\n", self.num_samples)
    self.gnuplot_f:write(self.plot_str)
end

function GnuplotPlotSink:process(x)
    if not self.gnuplot_f then
        self:initialize_gnuplot()
    end

    for i = 0, x.length-1 do
        -- Write each raw sample
        self.gnuplot_f:write(ffi.string(x.data[i], ffi.sizeof(x.data[0])))
        self.sample_count = self.sample_count + 1

        -- Restart plot when we reach num_samples
        if self.sample_count == self.num_samples then
            self.sample_count = 0
            self.gnuplot_f:write(self.plot_str)
        end
    end
end

function GnuplotPlotSink:cleanup()
    if not self.gnuplot_f then
        return
    end

    self.gnuplot_f:write("quit\n")
    self.gnuplot_f:close()
end

return {GnuplotPlotSink = GnuplotPlotSink}
