local radio = require('radio')

local application = {
    name = "iq_converter",
    description = "IQ File Converter",
    long_description = "Example usage:\n" ..
                       "  -a iq_converter -i iqfile:samples.iq,s8 -o iqfile:samples.out.iq,f32le\n\n" ..
                       "Supported formats:\n" ..
                       "  s8, u8, u16le, u16be, s16le, s16be, u32le, u32be,\n" ..
                       "  s32le, s32be, f32le, f32be, f64le, f64be",
    supported_inputs = {
        {"iqfile"},
    },
    supported_outputs = {
        {"iqfile"},
    },
    arguments = {},
    options = {},
}

function application.run(input, output, args)
    local source = input.block(0)
    local sink = output.block()

    local top = radio.CompositeBlock()
    top:connect(source, sink)

    top:run()
end

return application
