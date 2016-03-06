local radio = require('radio')

radio.CompositeBlock():connect(
    radio.NullSource(radio.ComplexFloat32Type),
    radio.RawFileSink(1)
):run()
