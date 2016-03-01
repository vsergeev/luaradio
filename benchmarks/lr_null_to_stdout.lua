local radio = require('radio')

radio.CompositeBlock():connect(
    radio.NullSource(),
    radio.FileSink(1)
):run()
