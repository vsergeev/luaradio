local radio = require('radio')

local application = {
    name = "rx_ert",
    description = "ERT Receiver (IDM, SCM, SCM+)",
    supported_inputs = {
        {"rtlsdr", defaults = {_rate = 2555904, _decimation = 6}},
        {"airspy", defaults = {_rate = 6000000, _decimation = 6}},
        {"airspyhf", defaults = {_rate = 768000, _decimation = 6}},
        {"bladerf", defaults = {_rate = 8060928, _decimation = 6}},
        {"hackrf", defaults = {_rate = 8060928, _decimation = 6}},
	{"hydrasdr", defaults = {_rate = 10000000, _decimation = 6}},
        {"sdrplay", defaults = {_rate = 8060928, _decimation = 6}},
        {"uhd", defaults = {_rate = 8060928, _decimation = 6}},
        {"soapysdr"},
        {"networkclient"},
        {"networkserver"},
        {"iqfile"},
    },
    supported_outputs = {
        {"text", defaults = {timestamp = true}},
        {"json"},
    },
    arguments = {},
    options = {
        {"frequency", "f", true, "Center frequency in Hz (default 915e6)"},
        {"sample-rate", "r", true, "Sample rate in Hz (default depends on input)"},
        {"protocols", nil, true, "Comma-separated list of protocols (default idm,scm,scm+)"},
    },
}

function application.run(input, output, args)
    local frequency = tonumber(args.frequency) or 915e6
    local rate = tonumber(args['sample-rate']) or input.options._rate
    local protocols = args.protocols or "idm,scm,scm+"

    local protocols_arr = {}
    for protocol in string.gmatch(protocols, "[^,]+") do
        protocols_arr[#protocols_arr + 1] = protocol
    end

    local source = input.block(frequency, rate)
    local receiver = radio.ERTReceiver(protocols_arr, {decimation = input.options._decimation})
    local sinks = {}
    for i = 1, #protocols_arr do
        sinks[i] = output.block()
    end

    radio.debug.printf("[rx_ert] Source sample rate %u Hz\n", source:get_rate())

    local top = radio.CompositeBlock()
    top:connect(source, receiver)
    for i = 1, #protocols_arr do
        top:connect(receiver, 'out' .. i, sinks[i], 'in')
    end

    top:run()
end

return application
