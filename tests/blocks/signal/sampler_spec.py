import numpy
from generate import *


def generate():
    def process(data, clock):
        sampled_data = []
        hysteresis = False

        for i in range(len(clock)):
            if hysteresis == False and clock[i] > 0:
                sampled_data.append(data[i])
                hysteresis = True
            elif hysteresis == True and clock[i] < 0:
                hysteresis = False

        return [numpy.array(sampled_data)]

    vectors = []

    data, clock = random_complex64(256), random_float32(256)
    vectors.append(TestVector([], [data, clock], process(data, clock), "256 ComplexFloat32 data, 256 Float32 clock, 256 Float32 output"))

    data, clock = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [data, clock], process(data, clock), "256 Float32 data, 256 Float32 clock, 256 Float32 output"))

    return BlockSpec("SamplerBlock", vectors, 1e-6)
