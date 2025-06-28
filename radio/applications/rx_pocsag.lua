local radio = require('radio')

local application = {
    name = "rx_pocsag",
    description = "POCSAG Receiver",
    supported_inputs = {
        {"rtlsdr", defaults = {_rate = 1000000}},
        {"airspy", defaults = {_rate = 3000000}},
        {"airspyhf", defaults = {_rate = 768000}},
        {"bladerf", defaults = {_rate = 1000000}},
        {"hackrf", defaults = {_rate = 8000000}},
	{"hydrasdr", defaults = {_rate = 10000000}},
        {"sdrplay", defaults = {_rate = 2000000}},
        {"uhd", defaults = {_rate = 1000000}},
        {"soapysdr"},
        {"networkclient", defaults = {_tune_offset = 0}},
        {"networkserver", defaults = {_tune_offset = 0}},
        {"iqfile", defaults = {_tune_offset = 0}},
    },
    supported_outputs = {
        {"text", defaults = {timestamp = true}},
        {"json"},
    },
    arguments = {
        {"frequency", "Station frequency in Hz, e.g. 152.840e6"},
    },
    options = {
        {"baudrate", "b", true, "Baudrate in Hz, choice of 512, 1200 (default 1200)"},
    },
}

function application.run(input, output, args)
    local tune_offset = input.options._tune_offset or -100e3
    local baudrate = tonumber(args.baudrate) or 1200
    local frequency = tonumber(args[1])

    local source = input.block(frequency + tune_offset, input.options._rate)
    local if_downsample = math.floor(source:get_rate() / 12.5e3 + 0.5)

    radio.debug.printf("[rx_pocsag] Source sample rate %u Hz\n", source:get_rate())
    radio.debug.printf("[rx_pocsag] IF downsample %u -> IF rate %u Hz\n", if_downsample, source:get_rate() / if_downsample)

    local tuner = radio.TunerBlock(tune_offset, 12e3, if_downsample)
    local receiver = radio.POCSAGReceiver(baudrate)
    local sink = output.block()

    local top = radio.CompositeBlock()
    top:connect(source, tuner, receiver, sink)

    top:run()
end

return application
