local radio = require('radio')

local application = {
    name = "rx_am",
    description = "AM Receiver",
    supported_inputs = {
        {"rtlsdr", defaults = {_rate = 1102500}},
        {"airspy", defaults = {_rate = 3000000}},
        {"airspyhf", defaults = {_rate = 768000}},
        {"bladerf", defaults = {_rate = 1102500}},
        {"hackrf", defaults = {_rate = 8820000}},
        {"sdrplay", defaults = {_rate = 2205000}},
        {"uhd", defaults = {_rate = 1102500}},
        {"soapysdr"},
        {"networkclient", defaults = {_tune_offset = 0}},
        {"networkserver", defaults = {_tune_offset = 0}},
        {"iqfile", defaults = {_tune_offset = 0}},
    },
    supported_outputs = {
        {"pulseaudio"},
        {"portaudio"},
        {"wavfile"},
    },
    arguments = {
        {"frequency", "Station frequency in Hz, e.g. 560e3"},
    },
    options = {
        {"bandwidth", "b", true, "Bandwidth in Hz (default 5e3)"},
        {"synchronous", false, false, "Synchronous demodulator (default is envelope)"},
    },
}

function application.run(input, output, args)
    local tune_offset = input.options._tune_offset or -50e3
    local frequency = tonumber(args[1])
    local bandwidth = args.bandwidth or 5e3

    local source = input.block(frequency + tune_offset, input.options._rate)
    local sink = output.block(1)

    local top = radio.CompositeBlock()

    if not args.synchronous then
        local if_downsample = math.floor(source:get_rate() / 44.1e3 + 0.5)

        radio.debug.printf("[rx_am] Using envelope demodulator\n")
        radio.debug.printf("[rx_am] Source sample rate %u Hz\n", source:get_rate())
        radio.debug.printf("[rx_am] IF downsample %u -> IF rate %u Hz\n", if_downsample, source:get_rate() / if_downsample)

        -- Envelope demodulator
        local tuner = radio.TunerBlock(tune_offset, 2 * bandwidth, if_downsample)
        local demod = radio.AMEnvelopeDemodulator(bandwidth)
        local af_gain = radio.AGCBlock('slow')

        top:connect(source, tuner, demod, af_gain, sink)
    else
        local if_downsample = math.floor(source:get_rate() / 220.5e3 + 0.5)
        local af_downsample = math.floor(source:get_rate() / if_downsample / 44.1e3 + 0.5)

        radio.debug.printf("[rx_am] Using synchronous demodulator\n")
        radio.debug.printf("[rx_am] Source sample rate %u Hz\n", source:get_rate())
        radio.debug.printf("[rx_am] IF downsample %u -> IF rate %u Hz\n", if_downsample, source:get_rate() / if_downsample)
        radio.debug.printf("[rx_am] AF downsample %u -> AF rate %u Hz\n", af_downsample, source:get_rate() / if_downsample / af_downsample)

        -- Synchronous demodulator
        local if_decimator = radio.DecimatorBlock(if_downsample)
        local demod = radio.AMSynchronousDemodulator(-tune_offset, bandwidth)
        local af_downsampler = radio.DownsamplerBlock(af_downsample)
        local af_gain = radio.AGCBlock('slow')

        top:connect(source, if_decimator, demod, af_downsampler, af_gain, sink)
    end

    top:run()
end

return application
