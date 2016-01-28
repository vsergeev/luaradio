import sys
from gnuradio import gr
from gnuradio import audio, analog,  blocks

class test_block(gr.top_block):
    def __init__(self):
        gr.top_block.__init__(self)

        src = blocks.null_source(gr.sizeof_gr_complex)
        dst = blocks.file_descriptor_sink(gr.sizeof_gr_complex, sys.stdout.fileno())

        self.connect(src, dst)

if __name__ == '__main__':
    test_block().run()
