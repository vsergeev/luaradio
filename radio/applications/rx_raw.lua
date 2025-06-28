local radio = require('radio')

local application = {
    name = "rx_raw",
    description = "Raw Receiver",
    supported_inputs = {
        {"rtlsdr"},
        {"airspy"},
        {"airspyhf"},
        {"bladerf"},
        {"hackrf"},
	{"hydrasdr"},
        {"sdrplay"},
        {"uhd"},
        {"soapysdr"},
        {"networkclient"},
        {"networkserver"},
    },
    supported_outputs = {
        {"iqfile"},
        {"networkclient"},
        {"networkserver"},
    },
    arguments = {
        {"frequency", "Tuning frequency in Hz, e.g. 144.390e6"},
        {"sample rate", "Sample rate in Hz, e.g. 1e6"},
    },
    options = {
        {"tune-offset", nil, true, "Tune offset in Hz"},
    },
}

function application.run(input, output, args)
    local frequency = tonumber(args[1])
    local sample_rate = tonumber(args[2])
    local tune_offset = tonumber(args['tune-offset'])

    local source = input.block(frequency + (tune_offset or 0), sample_rate)
    local sink = output.block()

    local top = radio.CompositeBlock()

    if not tune_offset then
        top:connect(source, sink)
    else
        local translator = radio.FrequencyTranslatorBlock(tune_offset)
        top:connect(source, translator, sink)
    end

    top:run()
end

return application
