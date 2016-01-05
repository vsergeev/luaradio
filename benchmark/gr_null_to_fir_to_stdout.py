import sys
import random
from gnuradio import gr
from gnuradio import audio, analog, filter, blocks

NUM_FILTER_TAPS = 256
NUM_FILTERS = 5

class test_block(gr.top_block):
    def __init__(self):
        gr.top_block.__init__(self)

        src = blocks.null_source(gr.sizeof_gr_complex)
        filters = [filter.fir_filter_ccf(1, [random.random() for i in range(NUM_FILTER_TAPS)]) for _ in range(NUM_FILTERS)]
        dst = blocks.file_descriptor_sink(gr.sizeof_gr_complex, sys.stdout.fileno())

        self.connect(*([src] + filters + [dst]))

if __name__ == '__main__':
    test_block().run()
