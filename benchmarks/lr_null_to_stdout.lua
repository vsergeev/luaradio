local radio = require('radio')

radio.CompositeBlock():connect(
    radio.NullSourceBlock(),
    radio.FileDescriptorSinkBlock(1)
):run()
