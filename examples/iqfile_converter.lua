local radio = require('radio')

if #arg < 4 then
    io.stderr:write("Usage: " .. arg[0] ..
                    " <input IQ file> <input format> <output IQ file> <output format>\n")
    io.stderr:write("\nSupported formats:\n" ..
                    "   s8, u8,\n" ..
                    "   u16le, u16be, s16le, s16be,\n" ..
                    "   u32le, u32be, s32le, s32be,\n" ..
                    "   f32le, f32be, f64le, f64be\n")
    os.exit(1)
end

radio.CompositeBlock():connect(
    radio.IQFileSource(arg[1], arg[2], 0),
    radio.IQFileSink(arg[3], arg[4])
):run()
