local radio = require('radio')

local application = {
    name = "rx_wbfm",
    description = "Wideband FM Receiver",
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
        {"frequency", "Station frequency in Hz, e.g. 104.3e6"},
    },
    options = {
        {"mono", nil, false, "Mono receiver (default stereo)"},
    },
}

function application.run(input, output, args)
    local tune_offset = input.options._tune_offset or -250e3
    local frequency = tonumber(args[1])
    local num_channels = args.mono and 1 or 2

    local source = input.block(frequency + tune_offset, input.options._rate)
    local if_downsample = math.floor(source:get_rate() / 220.5e3 + 0.5)
    local af_downsample = math.floor(source:get_rate() / if_downsample / 44.1e3 + 0.5)

    radio.debug.printf("[rx_wbfm] Source sample rate %u Hz\n", source:get_rate())
    radio.debug.printf("[rx_wbfm] IF downsample %u -> IF rate %u Hz\n", if_downsample, source:get_rate() / if_downsample)
    radio.debug.printf("[rx_wbfm] AF downsample %u -> AF rate %u Hz\n", af_downsample, source:get_rate() / if_downsample / af_downsample)

    local tuner = radio.TunerBlock(tune_offset, 200e3, if_downsample)
    local sink = output.block(num_channels)

    local top = radio.CompositeBlock()

    if args.mono then
        local demod = radio.WBFMMonoDemodulator()
        local downsampler = radio.DownsamplerBlock(af_downsample)

        top:connect(source, tuner, demod, downsampler, sink)
    else
        local demod = radio.WBFMStereoDemodulator()
        local l_downsampler = radio.DownsamplerBlock(af_downsample)
        local r_downsampler = radio.DownsamplerBlock(af_downsample)

        top:connect(source, tuner, demod)
        top:connect(demod, 'left', l_downsampler, 'in')
        top:connect(demod, 'right', r_downsampler, 'in')
        top:connect(l_downsampler, 'out', sink, 'in1')
        top:connect(r_downsampler, 'out', sink, 'in2')
    end

    top:run()
end

return application
