local radio = require('radio')

radio.CompositeBlock():connect(
    radio.NullSource(),
    radio.FileDescriptorSinkBlock(1)
):run()
