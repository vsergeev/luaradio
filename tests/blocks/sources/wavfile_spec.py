import io
import numpy
import scipy.io.wavfile
from generate import *


def generate():
    def float32_to_u8(x):
        return ((x * 127.5) + 127.5).astype(numpy.uint8)

    def u8_to_float32(x):
        return ((x - 127.5) / 127.5).astype(numpy.float32)

    def float32_to_s16(x):
        return ((x * 32767.5) + 0.0).astype(numpy.int16)

    def s16_to_float32(x):
        return ((x - 0.0) / 32767.5).astype(numpy.float32)

    def float32_to_s32(x):
        return ((x * 2147483647.5) + 0.0).astype(numpy.int32)

    def s32_to_float32(x):
        return ((x - 0.0) / 2147483647.5).astype(numpy.float32)

    vectors = []

    test_vector = random_float32(256)
    for bits_per_sample in (8, 16, 32):
        for num_channels in (1, 2):
            # Prepare wav and float vectors
            if bits_per_sample == 8:
                wav_vector = float32_to_u8(test_vector)
                expected_vector = u8_to_float32(wav_vector)
            elif bits_per_sample == 16:
                wav_vector = float32_to_s16(test_vector)
                expected_vector = s16_to_float32(wav_vector)
            elif bits_per_sample == 32:
                wav_vector = float32_to_s32(test_vector)
                expected_vector = s32_to_float32(wav_vector)

            # Reshape vectors with num channels
            wav_vector.shape = (len(wav_vector) // num_channels, num_channels)
            expected_vector.shape = (len(expected_vector) // num_channels, num_channels)

            # Write WAV file to bytes array
            f_buf = io.BytesIO()
            scipy.io.wavfile.write(f_buf, 44100, wav_vector)
            buf = ''.join(["\\x%02x" % b for b in f_buf.getvalue()])

            # Build test vector
            vectors.append(TestVector(["require('tests.buffer').open(\"%s\")" % buf, num_channels, 44100], [], [expected_vector[:, i] for i in range(num_channels)], "bits per sample %d, num channels %d" % (bits_per_sample, num_channels)))

    return BlockSpec("WAVFileSource", vectors, 1e-6)
