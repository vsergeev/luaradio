local radio = require('radio')

local application = {
    name = "rx_nbfm",
    description = "Narrowband FM Receiver",
    supported_inputs = {
        {"rtlsdr", defaults = {_rate = 1102500}},
        {"airspy", defaults = {_rate = 3000000}},
        {"airspyhf", defaults = {_rate = 768000}},
        {"bladerf", defaults = {_rate = 1102500}},
        {"hackrf", defaults = {_rate = 8820000}},
	{"hydrasdr", defaults = {_rate = 10000000}},
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
        {"frequency", "Station frequency in Hz, e.g. 162.550e6"},
    },
    options = {
        {"deviation", "d", true, "Deviation in Hz (default 5e3)"},
        {"bandwidth", "b", true, "Bandwidth in Hz (default 4e3)"},
    },
}

function application.run(input, output, args)
    local tune_offset = input.options._tune_offset or -100e3
    local frequency = tonumber(args[1])
    local deviation = args.deviation or 5e3
    local bandwidth = args.bandwidth or 4e3

    local source = input.block(frequency + tune_offset, input.options._rate)
    local if_downsample = math.floor(source:get_rate() / 44.1e3 + 0.5)

    radio.debug.printf("[rx_nbfm] Source sample rate %u Hz\n", source:get_rate())
    radio.debug.printf("[rx_nbfm] IF downsample %u -> IF rate %u Hz\n", if_downsample, source:get_rate() / if_downsample)

    local tuner = radio.TunerBlock(tune_offset, 2*(deviation + bandwidth), if_downsample)
    local demod = radio.NBFMDemodulator(deviation, bandwidth)
    local sink = output.block(1)

    local top = radio.CompositeBlock()

    top:connect(source, tuner, demod, sink)

    top:run()
end

return application
