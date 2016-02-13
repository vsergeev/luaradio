local radio = require('radio')

radio.CompositeBlock():connect(
    radio.NullSource(),
    radio.FileDescriptorSink(1)
):run()
