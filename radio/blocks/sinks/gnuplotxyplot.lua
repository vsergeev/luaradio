---
-- Plot two real-valued signals, or the real and imaginary components of one
-- complex-valued signal, in a gnuplot XY plot. This sink requires the gnuplot
-- program. This sink should be used with relatively low sample rates, as it
-- does not skip any samples, or it may otherwise throttle a flow graph.
--
-- @category Sinks
-- @block GnuplotXYPlotSink
-- @tparam int num_samples Number of samples to plot
-- @tparam[opt=""] string title Title of plot
-- @tparam[opt={}] table options Additional options, specifying:
--                            * `complex` (bool, default false)
--                            * `xlabel` (string, default "")
--                            * `ylabel` (string, default "")
--                            * `xrange` (array of two numbers, default `nil`
--                            for autoscale)
--                            * `yrange` (array of two numbers, default `nil`
--                            for autoscale)
--                            * `extra_settings` (array of strings containing
--                            gnuplot commands)
--
-- @signature x:Float32, y:Float32 >
-- @signature in:ComplexFloat32 >
--
-- @usage
-- -- Plot a 1 KHz complex exponential sampled at 250 KHz
-- local snk = radio.SignalSource('exponential', 1e3, 250e3)
-- local throttle = radio.ThrottleBlock()
-- local snk = radio.GnuplotXYPlotSink(1000, 'Complex Exponential', {complex = true})
-- top:connect(src, throttle, snk)
--
-- -- Plot two real-valued signals
-- local snk = radio.GnuplotXYPlotSink(1000, 'XY')
-- top:connect(src1, 'out', snk, 'x')
-- top:connect(src2, 'out', snk, 'y')

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local GnuplotXYPlotSink = block.factory("GnuplotXYPlotSink")

function GnuplotXYPlotSink:instantiate(num_samples, title, options)
    self.num_samples = assert(num_samples, "Missing argument #1 (num_samples)")
    self.title = title or ""
    self.options = options or {}

    self.sample_count = 0

    if options.complex then
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {}, self.process_complex)
    else
        self:add_type_signature({block.Input("x", types.Float32), block.Input("y", types.Float32)}, {})
    end
end

function GnuplotXYPlotSink:initialize()
    -- Check gnuplot exists
    assert(os.execute("gnuplot --version >/dev/null 2>&1") == 0, "gnuplot not found. Is gnuplot installed?")
end

function GnuplotXYPlotSink:initialize_gnuplot()
    -- Initialize gnuplot
    self.gnuplot_f = io.popen("gnuplot >/dev/null 2>&1", "w")
    self.gnuplot_f:write("set xtics\n")
    self.gnuplot_f:write("set ytics\n")
    self.gnuplot_f:write("set grid\n")
    self.gnuplot_f:write("set style data points\n")
    self.gnuplot_f:write("unset key\n")
    self.gnuplot_f:write(string.format("set xlabel '%s'\n", self.options.xlabel or ""))
    self.gnuplot_f:write(string.format("set ylabel '%s'\n", self.options.ylabel or ""))
    self.gnuplot_f:write(string.format("set title '%s'\n", self.title))

    -- Use xrange if it was specified, otherwise default to autoscale
    if self.options.xrange then
        self.gnuplot_f:write(string.format("set xrange [%f:%f]\n", self.options.xrange[1], self.options.xrange[2]))
    else
        self.gnuplot_f:write("set autoscale x\n")
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
    self.plot_str = string.format("plot '-' binary format='%%float32%%float32' record=%d using 1:2 linestyle 1\n", self.num_samples)
    self.gnuplot_f:write(self.plot_str)
end

function GnuplotXYPlotSink:process(x, y)
    if not self.gnuplot_f then
        self:initialize_gnuplot()
    end

    for i = 0, x.length-1 do
        -- Write each raw sample
        self.gnuplot_f:write(ffi.string(x.data[i], ffi.sizeof(x.data[0])))
        self.gnuplot_f:write(ffi.string(y.data[i], ffi.sizeof(y.data[0])))
        self.sample_count = self.sample_count + 1

        -- Rewrite plot string when we reach num_samples
        if self.sample_count == self.num_samples then
            self.sample_count = 0
            self.gnuplot_f:write(self.plot_str)
        end
    end
end

function GnuplotXYPlotSink:process_complex(x)
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

function GnuplotXYPlotSink:cleanup()
    if not self.gnuplot_f then
        return
    end

    self.gnuplot_f:write("quit\n")
    self.gnuplot_f:close()
end

return GnuplotXYPlotSink
