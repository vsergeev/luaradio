local radio = require('radio')

radio.CompositeBlock():connect(
    radio.NullSource(),
    radio.RawFileSink(1)
):run()
