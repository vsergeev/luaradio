local radio = require('radio')

function random_taps(n)
    taps = {}
    for i = 1, n do
        taps[i] = math.random()
    end
    return taps
end

radio.CompositeBlock():connect(
    radio.NullSource(radio.ComplexFloat32Type),
    radio.FIRFilterBlock(random_taps(256)),
    radio.FIRFilterBlock(random_taps(256)),
    radio.FIRFilterBlock(random_taps(256)),
    radio.FIRFilterBlock(random_taps(256)),
    radio.FIRFilterBlock(random_taps(256)),
    radio.RawFileSink(1)
):run()
