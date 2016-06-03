import os
import sys
import time
import json
import math
import array
import tempfile
import random
import collections

from gnuradio import gr
from gnuradio import audio, analog, digital, filter, blocks

################################################################################

# Benchmark parameters

# Duration of each benchmark trial
BENCH_TRIAL_DURATION    = 5.0

# Number of benchmark trials to average
BENCH_NUM_TRIALS        = 3

# Benchmark Suite
BenchmarkSuite = []

################################################################################

# Decorator for defining benchmarks in the suite
def benchmark(test_name, block_name):
    def wrapped(f):
        BenchmarkSuite.append((test_name, block_name, f))
        return f
    return wrapped

################################################################################

@benchmark("Five Back to Back FIR Filters (256 Real-valued taps, Complex-valued input, Complex-valued output)", "filter.fir_filter_ccf")
def test_five_fir_filter():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    filters = [filter.fir_filter_ccf(1, [random.random() for j in range(256)]) for i in range(5)]
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(*([src] + filters + [probe]))

    return top, probe

@benchmark("Null Source (Complex-valued)", "blocks.null_source")
def test_null_source_complex():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, probe)

    return top, probe

@benchmark("Null Source (Real-valued)", "blocks.null_source")
def test_null_source_real():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, probe)

    return top, probe

@benchmark("Raw File Source (float)", "blocks.file_descriptor_source")
def test_file_descriptor_source():
    tmp_f = tempfile.TemporaryFile()
    array.array('f', [random.random() for _ in range(262144)]).tofile(tmp_f)
    tmp_f.seek(0)

    top = gr.top_block()
    src = blocks.file_descriptor_source(gr.sizeof_float, os.dup(tmp_f.fileno()), True)
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, probe)

    return top, probe

@benchmark("Uniform Random Source (Complex-valued)", "analog.fastnoise_source_c")
def test_noise_source_complex():
    top = gr.top_block()
    src = analog.fastnoise_source_c(analog.GR_UNIFORM, math.sqrt(2))
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, probe)

    return top, probe

@benchmark("Uniform Random Source (Real-valued)", "analog.fastnoise_source_f")
def test_noise_source_real():
    top = gr.top_block()
    src = analog.fastnoise_source_f(analog.GR_UNIFORM, math.sqrt(2))
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, probe)

    return top, probe

@benchmark("Signal Source (Complex Exponential)", "analog.sig_source_c")
def test_sig_source_complex_exponential():
    top = gr.top_block()
    src = analog.sig_source_c(1e6, analog.GR_COS_WAVE, 200e3, 1.0)
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, probe)

    return top, probe

@benchmark("Signal Source (Cosine)", "analog.sig_source_f")
def test_sig_source_cosine():
    top = gr.top_block()
    src = analog.sig_source_f(1e6, analog.GR_COS_WAVE, 200e3, 1.0)
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, probe)

    return top, probe

@benchmark("Signal Source (Square)", "analog.sig_source_f")
def test_sig_source_square():
    top = gr.top_block()
    src = analog.sig_source_f(1e6, analog.GR_SQR_WAVE, 200e3, 1.0)
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, probe)

    return top, probe

@benchmark("FIR Filter (64 Real-valued taps, Complex-valued input, Complex-valued output)", "filter.fir_filter_ccf")
def test_fir_filter_ccf():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    firfilter = filter.fir_filter_ccf(1, [random.random() for _ in range(64)])
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("FIR Filter (64 Real-valued taps, Real-valued input, Real-valued output)", "filter.fir_filter_fff")
def test_fir_filter_fff():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    firfilter = filter.fir_filter_fff(1, [random.random() for _ in range(64)])
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("FIR Filter (64 Complex-valued taps, Complex-valued input, Complex-valued output)", "filter.fir_filter_ccc")
def test_fir_filter_ccc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    firfilter = filter.fir_filter_ccc(1, [complex(random.random(), random.random()) for _ in range(64)])
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("FIR Filter (64 Complex-valued taps, Real-valued input, Complex-valued output)", "filter.fir_filter_fcc")
def test_fir_filter_fcc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    firfilter = filter.fir_filter_fcc(1, [complex(random.random(), random.random()) for _ in range(64)])
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("FIR Filter (256 Real-valued taps, Complex-valued input, Complex-valued output)", "filter.fir_filter_ccf")
def test_fir_filter_ccf():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    firfilter = filter.fir_filter_ccf(1, [random.random() for _ in range(256)])
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("FIR Filter (256 Real-valued taps, Real-valued input, Real-valued output)", "filter.fir_filter_fff")
def test_fir_filter_fff():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    firfilter = filter.fir_filter_fff(1, [random.random() for _ in range(256)])
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("FIR Filter (256 Complex-valued taps, Complex-valued input, Complex-valued output)", "filter.fir_filter_ccc")
def test_fir_filter_ccc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    firfilter = filter.fir_filter_ccc(1, [complex(random.random(), random.random()) for _ in range(256)])
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("FIR Filter (256 Complex-valued taps, Real-valued input, Complex-valued output)", "filter.fir_filter_fcc")
def test_fir_filter_fcc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    firfilter = filter.fir_filter_fcc(1, [complex(random.random(), random.random()) for _ in range(256)])
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, firfilter, probe)

    return top, probe

@benchmark("IIR Filter (5 ff 3 fb Real-valued taps, Complex-valued input, Complex-valued output)", "filter.iir_filter_ccf")
def test_iir_filter_ccf():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    iirfilter = filter.iir_filter_ccf([random.random() for _ in range(5)], [random.random() for _ in range(3)])
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, iirfilter, probe)

    return top, probe

@benchmark("FM Deemphasis Filter", "analog.fm_deemph")
def test_fm_deemph():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    deemph = analog.fm_deemph(30e3, 75e-6)
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, deemph, probe)

    return top, probe

@benchmark("Frequency Translator", "blocks.rotator_cc")
def test_rotator_cc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    rotator = blocks.rotator_cc(2*math.pi*(200e3/1e6))
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, rotator, probe)

    return top, probe

@benchmark("Hilbert Transform (65 taps)", "filter.hilbert_fc")
def test_hilbert():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    hilbert = filter.hilbert_fc(65)
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, hilbert, probe)

    return top, probe

@benchmark("Hilbert Transform (257 taps)", "filter.hilbert_fc")
def test_hilbert():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    hilbert = filter.hilbert_fc(257)
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, hilbert, probe)

    return top, probe

@benchmark("Frequency Discriminator", "analog.quadrature_demod_cf")
def test_quadrature_demod_cf():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    fdisc = analog.quadrature_demod_cf(5.0)
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, fdisc, probe)

    return top, probe

@benchmark("PLL", "analog.pll_refout_cc")
def test_pll_refout_cc():
    top = gr.top_block()
    src = analog.fastnoise_source_c(analog.GR_UNIFORM, math.sqrt(2))
    pll = analog.pll_refout_cc(2*math.pi*1e3/300e3, 2*math.pi*200e3/300e3, 2*math.pi*220e3/300)
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, pll, probe)

    return top, probe

@benchmark("Add (Complex-valued)", "blocks.add_cc")
def test_add_cc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    add = blocks.add_cc()
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect((src, 0), (add, 0))
    top.connect((src, 0), (add, 1))
    top.connect(add, probe)

    return top, probe

@benchmark("Subtract (Complex-valued)", "blocks.sub_cc")
def test_sub_cc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    sub = blocks.sub_cc()
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect((src, 0), (sub, 0))
    top.connect((src, 0), (sub, 1))
    top.connect(sub, probe)

    return top, probe

@benchmark("Multiply (Complex-valued)", "blocks.multiply_cc")
def test_multiply_cc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    mul = blocks.multiply_cc()
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect((src, 0), (mul, 0))
    top.connect((src, 0), (mul, 1))
    top.connect(mul, probe)

    return top, probe

@benchmark("Multiply (Real-valued)", "blocks.multiply_ff")
def test_multiply_ff():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    mul = blocks.multiply_ff()
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect((src, 0), (mul, 0))
    top.connect((src, 0), (mul, 1))
    top.connect(mul, probe)

    return top, probe

@benchmark("Multiply Conjugate", "blocks.multiply_conjugate_cc")
def test_multiply_conjugate_cc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    mul = blocks.multiply_conjugate_cc()
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect((src, 0), (mul, 0))
    top.connect((src, 0), (mul, 1))
    top.connect(mul, probe)

    return top, probe

@benchmark("Multiply Constant (Complex-valued constant, Complex-valued input)", "blocks.multiply_const_cc")
def test_multiply_const_cc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    mul = blocks.multiply_const_cc(complex(random.random(), random.random()))
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, mul, probe)

    return top, probe

@benchmark("Multiply Constant (Real-valued constant, Real-valued input)", "blocks.multiply_const_ff")
def test_multiply_const_ff():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    mul = blocks.multiply_const_ff(random.random())
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, mul, probe)

    return top, probe

@benchmark("Absolute Value", "blocks.abs_ff")
def test_abs_ff():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    abs = blocks.abs_ff()
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, abs, probe)

    return top, probe

@benchmark("Complex Conjugate", "blocks.conjugate_cc")
def test_conjugate_cc():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    conj = blocks.conjugate_cc()
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, conj, probe)

    return top, probe

@benchmark("Complex Magnitude", "blocks.complex_to_mag")
def test_complex_to_mag():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    mag = blocks.complex_to_mag()
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, mag, probe)

    return top, probe

@benchmark("Complex Phase", "blocks.complex_to_arg")
def test_complex_to_arg():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    arg = blocks.complex_to_arg()
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, arg, probe)

    return top, probe

@benchmark("Delay (N = 3000, Complex-valued input)", "blocks.delay")
def test_delay():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    delay = blocks.delay(gr.sizeof_gr_complex, 3000)
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect(src, delay, probe)

    return top, probe

@benchmark("Bit Slicer", "digtal.binary_slicer_fb")
def test_binary_slicer_fb():
    top = gr.top_block()
    src = analog.fastnoise_source_f(analog.GR_UNIFORM, math.sqrt(2))
    slicer = digital.binary_slicer_fb()
    probe = blocks.probe_rate(gr.sizeof_char)
    top.connect(src, slicer, probe)

    return top, probe

@benchmark("Differential Decoder", "digital.diff_decoder_bb")
def test_diff_decoder_bb():
    top = gr.top_block()
    src = digital.glfsr_source_b(7)
    diffdecoder = digital.diff_decoder_bb(2)
    probe = blocks.probe_rate(gr.sizeof_char)
    top.connect(src, diffdecoder, probe)

    return top, probe

@benchmark("Complex to Real", "blocks.complex_to_real")
def test_complex_to_real():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    complextoreal = blocks.complex_to_real()
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, complextoreal, probe)

    return top, probe

@benchmark("Complex to Imaginary", "blocks.complex_to_imag")
def test_complex_to_imag():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_gr_complex)
    complextoimag = blocks.complex_to_imag()
    probe = blocks.probe_rate(gr.sizeof_float)
    top.connect(src, complextoimag, probe)

    return top, probe

@benchmark("Float to Complex", "blocks.float_to_complex")
def test_float_to_complex():
    top = gr.top_block()
    src = blocks.null_source(gr.sizeof_float)
    floattocomplex = blocks.float_to_complex()
    probe = blocks.probe_rate(gr.sizeof_gr_complex)
    top.connect((src, 0), (floattocomplex, 0))
    top.connect((src, 0), (floattocomplex, 1))
    top.connect(floattocomplex, probe)

    return top, probe

# Missing comparable blocks to:
#   @benchmark("IQ File Source (f32le)", "IQFileSource")
#   @benchmark("Real File Source (f32le)", "RealFileSource")
#   @benchmark("IIR Filter (5 feedforward & 3 feedback Real-valued taps, Real-valued input, Real-valued output)", "iir_filter_fff")
#   @benchmark("Downsampler (M = 7), Complex-valued", "DownsamplerBlock")
#   @benchmark("Downsampler (M = 7), Real-valued", "DownsamplerBlock")
#   @benchmark("Upsampler (L = 7), Complex-valued", "UpsamplerBlock")
#   @benchmark("Upsampler (L = 7), Real-valued", "UpsamplerBlock")
#   @benchmark("Zero Crossing Clock Recovery", "ZeroCrossingClockRecoveryBlock")
#   @benchmark("Binary Phase Corrector", "BinaryPhaseCorrectorBlock")
#   @benchmark("Multiply Constant (Real-valued constant, Complex-valued input)", "blocks.multiply_const_cc")

################################################################################

# Benchmark runner

if __name__ == '__main__':
    # If a test name was specified, filter the benchmark suite by fuzzy-matching
    # by test name
    if len(sys.argv) > 1:
        MatchedBenchmarkSuite = []

        for benchmark in BenchmarkSuite:
            if benchmark[0].lower().find(sys.argv[1].lower()) >= 0:
                MatchedBenchmarkSuite.append(benchmark)

        BenchmarkSuite = MatchedBenchmarkSuite

    benchmark_results = {
        'version': gr.version(),
        'parameters': {
            'num_trials': BENCH_NUM_TRIALS,
            'trial_duration': BENCH_TRIAL_DURATION
        },
        'benchmarks': []
    }

    for index, benchmark in enumerate(BenchmarkSuite):
        test_name, block_name, test_factory = benchmark

        sys.stderr.write("Running benchmark {}/{} \"{}\"\n".format(index+1, len(BenchmarkSuite), test_name))

        samples_per_second, bytes_per_second = 0.0, 0.0

        # Run each trial
        for trial in range(BENCH_NUM_TRIALS):
            # Create the test top block
            test_top, test_probe = test_factory()

            # Run the trial
            test_top.start()
            time.sleep(BENCH_TRIAL_DURATION)
            test_top.stop()

            trial_samples_per_second = test_probe.rate()
            trial_bytes_per_second = trial_samples_per_second * test_probe.input_signature().sizeof_stream_item(0)

            sys.stderr.write("\tTrial {} - {:.1f} MS/s, {:.1f} MiB/s\n".format(trial+1, trial_samples_per_second/1e6, trial_bytes_per_second/1048576))

            samples_per_second += trial_samples_per_second
            bytes_per_second += trial_bytes_per_second

        # Average results
        samples_per_second /= BENCH_NUM_TRIALS
        bytes_per_second /= BENCH_NUM_TRIALS

        sys.stderr.write("\tAverage - {:.1f} MS/s, {:.1f} MiB/s\n".format(samples_per_second/1e6, bytes_per_second/1048576))

        # Add it to our table
        benchmark_results['benchmarks'].append({'name': test_name, 'block_name': block_name, 'results': {'samples_per_second': samples_per_second, 'bytes_per_second': bytes_per_second}})

    print(json.dumps(benchmark_results))
