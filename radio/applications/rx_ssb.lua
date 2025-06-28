local radio = require('radio')

local application = {
    name = "rx_ssb",
    description = "SSB Receiver",
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
        {"frequency", "Station frequency in Hz, e.g. 1.840e6"},
        {"sideband", "Sideband as lsb or usb"},
    },
    options = {
        {"bandwidth", "b", true, "Bandwidth in Hz (default 3e3)"},
    },
}

function application.run(input, output, args)
    local tune_offset = input.options._tune_offset or -100e3
    local frequency = tonumber(args[1])
    local sideband = args[2]
    local bandwidth = args.bandwidth or 3e3

    if sideband ~= "lsb" and sideband ~= "usb" then
        error("Sideband should be 'lsb' or 'usb'.")
    end

    local source = input.block(frequency + tune_offset, input.options._rate)
    local if_downsample = math.floor(source:get_rate() / 44.1e3 + 0.5)

    radio.debug.printf("[rx_ssb] Source sample rate %u Hz\n", source:get_rate())
    radio.debug.printf("[rx_ssb] IF downsample %u -> IF rate %u Hz\n", if_downsample, source:get_rate() / if_downsample)

    local tuner = radio.TunerBlock(tune_offset, 2 * bandwidth, if_downsample)
    local demod = radio.SSBDemodulator(sideband, bandwidth)
    local sink = output.block(1)

    local top = radio.CompositeBlock()

    top:connect(source, tuner, demod, sink)

    top:run()
end

return application
