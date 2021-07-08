local radio = require('radio')

-- Supported applications
local applications = {
    require('radio.applications.rx_raw'),
    require('radio.applications.rx_wbfm'),
    require('radio.applications.rx_nbfm'),
    require('radio.applications.rx_am'),
    require('radio.applications.rx_ssb'),
    require('radio.applications.rx_rds'),
    require('radio.applications.rx_ax25'),
    require('radio.applications.rx_pocsag'),
    require('radio.applications.rx_ert'),
    require('radio.applications.iq_converter'),
}

-- Supported inputs
local inputs = {
    -- SDR sources
    rtlsdr = {
        factory = function (options)
            return function (frequency, rate)
                return radio.RtlSdrSource(frequency, rate, options)
            end
        end,
        args = {},
    },
    airspy = {
        factory = function (options)
            return function (frequency, rate)
                return radio.AirspySource(frequency, rate, options)
            end
        end,
        args = {},
    },
    airspyhf = {
        factory = function (options)
            return function (frequency, rate)
                return radio.AirspyHFSource(frequency, rate, options)
            end
        end,
        args = {},
    },
    bladerf = {
        factory = function (options)
            return function (frequency, rate)
                return radio.BladeRFSource(frequency, rate, options)
            end
        end,
        args = {},
    },
    hackrf = {
        factory = function (options)
            return function (frequency, rate)
                return radio.HackRFSource(frequency, rate, options)
            end
        end,
        args = {},
    },
    sdrplay = {
        factory = function (options)
            return function (frequency, rate)
                return radio.SDRplaySource(frequency, rate, options)
            end
        end,
        args = {},
    },
    uhd = {
        factory = function (options)
            return function (frequency, rate)
                return radio.UHDSource(options[1], frequency, rate, options)
            end
        end,
        args = {"device"},
    },
    soapysdr = {
        factory = function (options)
            return function (frequency, rate)
                return radio.SoapySDRSource(options[1], frequency, tonumber(options[2]), options)
            end
        end,
        args = {"driver", "rate"},
    },

    -- Network sources
    networkclient = {
        factory = function (options)
            return function (frequency, rate)
                return radio.NetworkClientSource(radio.types.ComplexFloat32, tonumber(options[1]), options[2], options[3], options[4], options)
            end
        end,
        args = {"rate", "format", "tcp/unix", "address"}
    },
    networkserver = {
        factory = function (options)
            return function (frequency, rate)
                return radio.NetworkServerSource(radio.types.ComplexFloat32, tonumber(options[1]), options[2], options[3], options[4], options)
            end
        end,
        args = {"rate", "format", "tcp/unix", "address"}
    },

    -- IQ file source
    iqfile = {
        factory = function (options)
            return function (frequency, rate)
                return radio.IQFileSource(options[1], options[2], tonumber(options[3]))
            end
        end,
        args = {"filename", "format", "rate"},
    },
}

-- Supported sinks
local outputs = {
    -- Audio sinks
    pulseaudio = {
        factory = function (options)
            return function (num_channels)
                return radio.PulseAudioSink(num_channels)
            end
        end,
        args = {},
    },
    portaudio = {
        factory = function (options)
            return function (num_channels)
                return radio.PulseAudioSink(num_channels)
            end
        end,
        args = {},
    },
    wavfile = {
        factory = function (options)
            return function (num_channels)
                return radio.WAVFileSink(options[1], num_channels)
            end
        end,
        args = {"filename"},
    },

    -- IQ file sink
    iqfile = {
        factory = function (options)
            return function ()
                return radio.IQFileSink(options[1], options[2])
            end
        end,
        args = {"filename", "format"},
    },

    -- Network sinks
    networkclient = {
        factory = function (options)
            return function ()
                return radio.NetworkClientSink(options[1], options[2], options[3], options)
            end
        end,
        args = {"format", "tcp/unix", "address"}
    },
    networkserver = {
        factory = function (options)
            return function ()
                return radio.NetworkServerSink(options[1], options[2], options[3], options)
            end
        end,
        args = {"format", "tcp/unix", "address"}
    },

    -- Data sinks
    text = {
        factory = function (options)
            return function ()
                return radio.PrintSink(nil, options)
            end
        end,
        args = {},
    },
    json = {
        factory = function (options)
            return function ()
                return radio.JSONSink(nil, options)
            end
        end,
        args = {},
    },
}

--------------------------------------------------------------------------------
-- Top-level
--------------------------------------------------------------------------------

local util = require('radio.core.util')

local options = {
    {"help", "h", false, "Print application help and exit"},
    {"input", "i", true, "Input, in format <input>[:<options>]"},
    {"output", "o", true, "Output, in format <output>[:<options>]"},
}

local function print_usage(program_name)
    local usage = string.format("Application Usage: %s -a <application> [args]\n", program_name)

    usage = usage .. "\nBuilt-in Applications:\n"
    local lines = {}
    for _, app in ipairs(applications) do
        lines[#lines + 1] = string.format("%-24s%s", "  " .. app.name, app.description)
    end
    usage = usage .. table.concat(lines, "\n")

    print(usage)
end

local function print_application_usage(program_name, app)
    local args = util.array_map(app.arguments, function (a) return string.format("<%s>", a[1]) end)

    local usage = string.format("Usage: %s -a %s -i <input> [-o <output>] [options] %s\n\n%s",
                                program_name, app.name, table.concat(args, " "), app.description)

    if app.long_description then
        usage = usage .. "\n\n" .. app.long_description
    end

    usage = usage .. "\n\nSupported Inputs:\n"
    local lines = {}
    for _, input in ipairs(app.supported_inputs) do
        assert(inputs[input[1]], string.format("Unknown input type \"%s\" for application %s", input[1], app.name))

        block_args = table.concat(util.array_map(inputs[input[1]].args, function (a) return string.format("<%s>", a) end), ",")
        if block_args ~= "" then
            lines[#lines + 1] = string.format("%-24s%s:%s", "  " .. input[1], input[1], block_args)
        else
            lines[#lines + 1] = string.format("%-24s%s", "  " .. input[1], input[1])
            --lines[#lines + 1] = "  " .. input[1] FIXME decide
        end
    end
    usage = usage .. table.concat(lines, "\n")

    usage = usage .. "\n\nSupported Outputs:\n"
    local lines = {}
    for _, output in ipairs(app.supported_outputs) do
        assert(outputs[output[1]], string.format("Unknown output type \"%s\" for application %s", output[1], app.name))

        block_args = table.concat(util.array_map(outputs[output[1]].args, function (a) return string.format("<%s>", a) end), ",")
        if block_args ~= "" then
            lines[#lines + 1] = string.format("%-24s%s:%s", "  " .. output[1], output[1], block_args)
        else
            lines[#lines + 1] = string.format("%-24s%s", "  " .. output[1], output[1])
            --lines[#lines + 1] = "  " .. output[1] FIXME decide
        end
    end
    usage = usage .. table.concat(lines, "\n")

    usage = usage .. "\n\nOptions:\n"
    usage = usage .. util.format_options(util.array_concat(options, app.options or {}))

    if #app.arguments > 0 then
        usage = usage .. "\n\nArguments:\n"
        local lines = {}
        for _, arg in ipairs(app.arguments) do
            lines[#lines + 1] = string.format("%-24s%s", "  " .. arg[1], arg[2])
        end
        usage = usage .. table.concat(lines, "\n")
    end

    usage = usage .. "\n\n"
    usage = usage .. "Options for inputs and outputs can be specified\n"
    usage = usage .. "with comma delimited key-value pairs. Example:\n\n"
    usage = usage .. "  rtlsdr:biastee=true,freq_correction=10"

    print(usage)
end

local function parse_block_args(arg)
    -- If no string was provided
    if arg == nil then
        return nil, {}
    end

    local block_name, block_args_str = string.match(arg, "([^:]+)[:]?(.*)")

    -- If no options were provided
    if block_args_str == "" then
        return block_name, {}
    end

    local function decode_value(s)
        if s == "true" then
            return true
        elseif s == "false" then
            return false
        elseif s == "nil" then
            return nil
        elseif string.sub(s, 1, 1) == "\"" and string.sub(s, -1, -1) == "\"" then
            return string.sub(s, 2, -2)
        else
            return tonumber(s) or s
        end
    end

    local block_args = {}

    -- Decode positional arguments
    for p in string.gmatch(block_args_str, "([^,]+)") do
        block_args[#block_args + 1] = not string.find(p, "=") and decode_value(p) or nil
    end

    -- Decode optional key-value arguments
    for k, v in string.gmatch(block_args_str, "([^=,]+)=([^=,]+)") do
        block_args[k] = decode_value(v)
    end

    return block_name, block_args
end

local function run(program_name, name, args)
    -- Lookup application
    local app = util.array_search(applications, function (a) return a.name == name end)
    if not app then
        print(string.format("Error: unknown application specified: %s\n", name))
        print_usage(program_name)
        os.exit(1)
    end

    -- Parse arguments
    local parsed_args = util.parse_args(args, util.array_concat(options, app.options or {}))
    if #args == 0 or parsed_args.help then
        print_application_usage(program_name, app)
        os.exit(0)
    elseif not parsed_args.input then
        print("Error: missing input source\n")
        print_application_usage(program_name, app)
        os.exit(1)
    end

    ----------------------------------------
    -- Input handling
    ----------------------------------------

    -- Parse input arguments
    local input_name, input_options = parse_block_args(parsed_args.input)

    -- Lookup app input spec
    local app_input = util.array_search(app.supported_inputs, function (e) return e[1] == input_name end)
    if not app_input then
        print(string.format("Error: unsupported input source \"%s\"\n", parsed_args.input))
        print_application_usage(program_name, app)
        os.exit(1)
    end

    -- Validate input arguments
    if #input_options < #inputs[input_name].args then
        print(string.format("Error: insufficient arguments for input source \"%s\"\n", input_name))
        print_application_usage(program_name, app)
        os.exit(1)
    end

    -- Extend application input defaults with user options
    input_options = util.table_extend(app_input.defaults or {}, input_options)

    -- Construct input
    local input = {block = inputs[input_name].factory(input_options), options = input_options}

    ----------------------------------------
    -- Output handling
    ----------------------------------------

    -- Parse output arguments
    local output_name, output_options = parse_block_args(parsed_args.output)
    output_name = output_name or app.supported_outputs[1][1]

    -- Lookup app output spec
    local app_output = output_name and util.array_search(app.supported_outputs, function (e) return e[1] == output_name end)
    if not app_output then
        print(string.format("Error: unsupported output sink \"%s\"\n", parsed_args.output))
        print_application_usage(program_name, app)
        os.exit(1)
    end

    -- Validate output arguments
    if #output_options < #outputs[output_name].args then
        print(string.format("Error: insufficient arguments for output source \"%s\"\n", output_name))
        print_application_usage(program_name, app)
        os.exit(1)
    end

    -- Extend application output defaults with user options
    output_options = util.table_extend(app_output.defaults or {}, output_options)

    -- Construct output
    local output = {block = outputs[output_name].factory(output_options), options = output_options}

    ----------------------------------------
    -- Application
    ----------------------------------------

    -- Check for sufficent positional arguments
    if #parsed_args < #app.arguments then
        print("Error: insufficient positional arguments\n")
        print_application_usage(program_name, app)
        os.exit(1)
    end

    -- Run application
    local status, err = pcall(function () app.run(input, output, parsed_args) end)
    if not status then
        print("Error: " .. err .. "\n")
        print_application_usage(program_name, app)
        os.exit(1)
    end
end

return {print_usage = print_usage, run = run}
