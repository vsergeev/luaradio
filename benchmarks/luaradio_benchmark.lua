local ffi = require('ffi')
local json = require('radio.thirdparty.json')
local buffer = require('tests.buffer')

local radio = require('radio')

-- Benchmark parameters

-- Duration of each benchmark trial
local BENCH_TRIAL_DURATION  = 5

-- Number of benchmark trials to average
local BENCH_NUM_TRIALS      = 5

-- Benchmark suite
local BenchmarkSuite = {
    {
        "Five Back to Back FIR Filters (256 Real-valued taps, Complex-valued input, Complex-valued output)",
        "FIRFilterBlock",
        function (results_fd)
            local taps = {}
            for i = 1, 256 do
                taps[i] = math.random(1.0)
            end
            taps = radio.types.Float32.vector_from_array(taps)

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.FIRFilterBlock(taps),
                radio.FIRFilterBlock(taps),
                radio.FIRFilterBlock(taps),
                radio.FIRFilterBlock(taps),
                radio.FIRFilterBlock(taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Null Source (Complex-valued)",
        "NullSource",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Null Source (Real-valued)",
        "NullSource",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "IQ File Source (f32le)",
        "IQFileSource",
        function (results_fd)
            local random_vec = radio.types.ComplexFloat32.vector(262144)
            for i = 0, random_vec.length-1 do
                random_vec.data[i].real = 2*math.random(1.0)-1.0
                random_vec.data[i].imag = 2*math.random(1.0)-1.0
            end
            local src_fd = buffer.open(ffi.string(random_vec.data, random_vec.size))

            return radio.CompositeBlock():connect(
                radio.IQFileSource(src_fd, 'f32le', 1.0, true),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Real File Source (f32le)",
        "RealFileSource",
        function (results_fd)
            local random_vec = radio.types.Float32.vector(262144)
            for i = 0, random_vec.length-1 do
                random_vec.data[i].value = 2*math.random(1.0)-1.0
            end
            local src_fd = buffer.open(ffi.string(random_vec.data, random_vec.size))

            return radio.CompositeBlock():connect(
                radio.RealFileSource(src_fd, 'f32le', 1.0, true),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Raw File Source (float)",
        "RawFileSource",
        function (results_fd)
            local random_vec = radio.types.Float32.vector(262144)
            for i = 0, random_vec.length-1 do
                random_vec.data[i].value = 2*math.random(1.0)-1.0
            end
            local src_fd = buffer.open(ffi.string(random_vec.data, random_vec.size))

            return radio.CompositeBlock():connect(
                radio.RawFileSource(src_fd, radio.types.Float32, 1.0, true),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Uniform Random Source (Complex-valued)",
        "UniformRandomSource",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.UniformRandomSource(radio.types.ComplexFloat32, 1.0),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Uniform Random Source (Real-valued)",
        "UniformRandomSource",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.UniformRandomSource(radio.types.Float32, 1.0),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Signal Source (Complex Exponential)",
        "SignalSource",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.SignalSource('exponential', 200e3, 1e6),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Signal Source (Cosine)",
        "SignalSource",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.SignalSource('cosine', 200e3, 1e6),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Signal Source (Square)",
        "SignalSource",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.SignalSource('square', 200e3, 1e6),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "FIR Filter (64 Real-valued taps, Complex-valued input, Complex-valued output)",
        "FIRFilterBlock",
        function (results_fd)
            local taps = {}
            for i = 1, 64 do
                taps[i] = math.random(1.0)
            end
            taps = radio.types.Float32.vector_from_array(taps)

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.FIRFilterBlock(taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "FIR Filter (64 Real-valued taps, Real-valued input, Real-valued output)",
        "FIRFilterBlock",
        function (results_fd)
            local taps = {}
            for i = 1, 64 do
                taps[i] = math.random(1.0)
            end
            taps = radio.types.Float32.vector_from_array(taps)

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.FIRFilterBlock(taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "FIR Filter (64 Complex-valued taps, Complex-valued input, Complex-valued output)",
        "FIRFilterBlock",
        function (results_fd)
            local taps = {}
            for i = 1, 64 do
                taps[i] = {math.random(1.0), math.random(1.0)}
            end
            taps = radio.types.ComplexFloat32.vector_from_array(taps)

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.FIRFilterBlock(taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "FIR Filter (256 Real-valued taps, Complex-valued input, Complex-valued output)",
        "FIRFilterBlock",
        function (results_fd)
            local taps = {}
            for i = 1, 256 do
                taps[i] = math.random(1.0)
            end
            taps = radio.types.Float32.vector_from_array(taps)

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.FIRFilterBlock(taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "FIR Filter (256 Real-valued taps, Real-valued input, Real-valued output)",
        "FIRFilterBlock",
        function (results_fd)
            local taps = {}
            for i = 1, 256 do
                taps[i] = math.random(1.0)
            end
            taps = radio.types.Float32.vector_from_array(taps)

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.FIRFilterBlock(taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "FIR Filter (256 Complex-valued taps, Complex-valued input, Complex-valued output)",
        "FIRFilterBlock",
        function (results_fd)
            local taps = {}
            for i = 1, 256 do
                taps[i] = {math.random(1.0), math.random(1.0)}
            end
            taps = radio.types.ComplexFloat32.vector_from_array(taps)

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.FIRFilterBlock(taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "IIR Filter (5 ff 3 fb Real-valued taps, Complex-valued input, Complex-valued output)",
        "IIRFilterBlock",
        function (results_fd)
            local b_taps = {math.random(1.0), math.random(1.0), math.random(1.0), math.random(1.0)}
            local a_taps = {math.random(1.0), math.random(1.0), math.random(1.0)}

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.IIRFilterBlock(b_taps, a_taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "IIR Filter (5 ff 3 fb Real-valued taps, Real-valued input, Real-valued output)",
        "IIRFilterBlock",
        function (results_fd)
            local b_taps = {math.random(1.0), math.random(1.0), math.random(1.0), math.random(1.0)}
            local a_taps = {math.random(1.0), math.random(1.0), math.random(1.0)}

            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.IIRFilterBlock(b_taps, a_taps),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "FM Deemphasis Filter",
        "FMDeemphasisFilterBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 30e3),
                radio.FMDeemphasisFilterBlock(75e-6),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Downsampler (M = 5), Complex-valued",
        "DownsamplerBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.DownsamplerBlock(5),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Downsampler (M = 5), Real-valued",
        "DownsamplerBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.DownsamplerBlock(5),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Upsampler (L = 3), Complex-valued",
        "UpsamplerBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.UpsamplerBlock(3),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Upsampler (L = 3), Real-valued",
        "UpsamplerBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.UpsamplerBlock(3),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Frequency Translator",
        "FrequencyTranslatorBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1e6),
                radio.FrequencyTranslatorBlock(200e3),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Hilbert Transform (65 taps)",
        "HilbertTransformBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.HilbertTransformBlock(65),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Hilbert Transform (257 taps)",
        "HilbertTransformBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.HilbertTransformBlock(257),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Frequency Discriminator",
        "FrequencyDiscriminatorBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.FrequencyDiscriminatorBlock(1.25),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "PLL",
        "PLLBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.UniformRandomSource(radio.types.ComplexFloat32, 1e6),
                radio.PLLBlock(1e3, 200e3, 220e3),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Zero Crossing Clock Recovery",
        "ZeroCrossingClockRecoveryBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.UniformRandomSource(radio.types.Float32, 1e6),
                radio.ZeroCrossingClockRecoveryBlock(1200),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Binary Phase Corrector",
        "BinaryPhaseCorrectorBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.UniformRandomSource(radio.types.ComplexFloat32, 1.0),
                radio.BinaryPhaseCorrectorBlock(3000),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Add (Complex-valued)",
        "AddBlock",
        function (results_fd)
            local src = radio.NullSource(radio.types.ComplexFloat32, 1.0)
            local adder = radio.AddBlock()
            local top = radio.CompositeBlock()
            top:connect(src, 'out', adder, 'in1')
            top:connect(src, 'out', adder, 'in2')
            return top:connect(adder, radio.BenchmarkSink(results_fd, true))
        end
    },
    {
        "Subtract (Complex-valued)",
        "SubtractBlock",
        function (results_fd)
            local src = radio.NullSource(radio.types.ComplexFloat32, 1.0)
            local subtractor = radio.SubtractBlock()
            local top = radio.CompositeBlock()
            top:connect(src, 'out', subtractor, 'in1')
            top:connect(src, 'out', subtractor, 'in2')
            return top:connect(subtractor, radio.BenchmarkSink(results_fd, true))
        end
    },
    {
        "Multiply (Complex-valued)",
        "MultiplyBlock",
        function (results_fd)
            local src = radio.NullSource(radio.types.ComplexFloat32, 1.0)
            local multiplier = radio.MultiplyBlock()
            local top = radio.CompositeBlock()
            top:connect(src, 'out', multiplier, 'in1')
            top:connect(src, 'out', multiplier, 'in2')
            return top:connect(multiplier, radio.BenchmarkSink(results_fd, true))
        end
    },
    {
        "Multiply (Real-valued)",
        "MultiplyBlock",
        function (results_fd)
            local src = radio.NullSource(radio.types.Float32, 1.0)
            local multiplier = radio.MultiplyBlock()
            local top = radio.CompositeBlock()
            top:connect(src, 'out', multiplier, 'in1')
            top:connect(src, 'out', multiplier, 'in2')
            return top:connect(multiplier, radio.BenchmarkSink(results_fd, true))
        end
    },
    {
        "Multiply Conjugate",
        "MultiplyConjugateBlock",
        function (results_fd)
            local src = radio.NullSource(radio.types.ComplexFloat32, 1.0)
            local multiplier = radio.MultiplyConjugateBlock()
            local top = radio.CompositeBlock()
            top:connect(src, 'out', multiplier, 'in1')
            top:connect(src, 'out', multiplier, 'in2')
            return top:connect(multiplier, radio.BenchmarkSink(results_fd, true))
        end
    },
    {
        "Multiply Constant (Real-valued constant, Complex-valued input)",
        "MultiplyConstantBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.MultiplyConstantBlock(5.0),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Multiply Constant (Complex-valued constant, Complex-valued input)",
        "MultiplyConstantBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.MultiplyConstantBlock(radio.types.ComplexFloat32(math.random(), math.random())),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Multiply Constant (Real-valued constant, Real-valued input)",
        "MultiplyConstantBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.MultiplyConstantBlock(5.0),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Absolute Value",
        "AbsoluteValueBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.Float32, 1.0),
                radio.AbsoluteValueBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Complex Conjugate",
        "ComplexConjugateBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.ComplexConjugateBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Complex Magnitude",
        "ComplexMagnitudeBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.ComplexMagnitudeBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Complex Phase",
        "ComplexPhaseBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.ComplexPhaseBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Delay (N = 3000, Complex-valued input)",
        "DelayBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.DelayBlock(3000),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Bit Slicer",
        "SlicerBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.UniformRandomSource(radio.types.Float32, 1.0),
                radio.SlicerBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Differential Decoder",
        "DifferentialDecoderBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.UniformRandomSource(radio.types.Bit, 1.0),
                radio.DifferentialDecoderBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Complex to Real",
        "ComplexToRealBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.ComplexToRealBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Complex to Imaginary",
        "ComplexToImagBlock",
        function (results_fd)
            return radio.CompositeBlock():connect(
                radio.NullSource(radio.types.ComplexFloat32, 1.0),
                radio.ComplexToImagBlock(),
                radio.BenchmarkSink(results_fd, true)
            )
        end
    },
    {
        "Float to Complex",
        "FloatToComplexBlock",
        function (results_fd)
            local src = radio.NullSource(radio.types.Float32, 1.0)
            local floattocomplex = radio.FloatToComplexBlock()
            local top = radio.CompositeBlock()
            top:connect(src, 'out', floattocomplex, 'real')
            top:connect(src, 'out', floattocomplex, 'imag')
            return top:connect(floattocomplex, radio.BenchmarkSink(results_fd, true))
        end
    },
}

--------------------------------------------------------------------------------

-- Benchmark runner

local test_name_match = arg[1]

-- If a test name was specified, filter the benchmark suite
-- by fuzzy-matching by test name
if test_name_match then
    local MatchedBenchmarkSuite = {}

    for _, benchmark in ipairs(BenchmarkSuite) do
        local test_name = benchmark[1]
        if test_name:lower():find(test_name_match:lower(), 1, true) then
            MatchedBenchmarkSuite[#MatchedBenchmarkSuite + 1] = benchmark
        end
    end

    BenchmarkSuite = MatchedBenchmarkSuite
end

-- Results
local benchmark_results = {
    version = radio.version,
    platform = {
        luajit_version = radio.platform.luajit_version,
        os = radio.platform.os,
        arch = radio.platform.arch,
        page_size = radio.platform.page_size,
        cpu_count = radio.platform.cpu_count,
        cpu_model = radio.platform.cpu_model,
        features = radio.platform.features
    },
    parameters = {
        num_trials = BENCH_NUM_TRIALS,
        trial_duration = BENCH_TRIAL_DURATION,
    },
    benchmarks = {}
}

ffi.cdef[[
unsigned alarm(unsigned seconds);
]]

-- Block SIGINT and SIGALRM so we can catch them with sigwait()
local sigset = ffi.new("sigset_t[1]")
ffi.C.sigemptyset(sigset)
ffi.C.sigaddset(sigset, ffi.C.SIGINT)
ffi.C.sigaddset(sigset, ffi.C.SIGALRM)
if ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) ~= 0 then
    error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

for index, benchmark in ipairs(BenchmarkSuite) do
    local test_name, block_name, test_factory = unpack(benchmark)

    io.stderr:write(string.format("Running benchmark %d/%d \"%s\"\n", index, #BenchmarkSuite, test_name))

    local samples_per_second, bytes_per_second = 0.0, 0.0
    local sig = ffi.new("int[1]")

    -- Run each trial
    for trial = 1, BENCH_NUM_TRIALS do
        -- Create results buffer
        local results_fd = buffer.open()

        -- Create the test top block
        local top = test_factory(results_fd)

        -- Run the trial
        top:start()
        ffi.C.alarm(BENCH_TRIAL_DURATION)
        if ffi.C.sigwait(sigset, sig) ~= 0 then
            error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
        top:stop()

        -- Check for user abort
        if sig[0] == ffi.C.SIGINT then
            io.stderr:write("Caught SIGINT, aborting...\n")
            os.exit(0)
        end

        -- Read and deserialize results buffer
        buffer.rewind(results_fd)
        local results = json.decode(buffer.read(results_fd, 256))
        buffer.close(results_fd)

        io.stderr:write(string.format("\tTrial %d - %.1f MS/s, %.1f MiB/s\n", trial, results.samples_per_second/1e6, results.bytes_per_second/1048576))

        samples_per_second = samples_per_second + results.samples_per_second
        bytes_per_second = bytes_per_second + results.bytes_per_second
    end

    -- Average results
    samples_per_second = samples_per_second / BENCH_NUM_TRIALS
    bytes_per_second = bytes_per_second / BENCH_NUM_TRIALS

    io.stderr:write(string.format("\tAverage - %.1f MS/s, %.1f MiB/s\n", samples_per_second/1e6, bytes_per_second/1048576))

    -- Add it to our table
    benchmark_results.benchmarks[index] = {name = test_name, block_name = block_name, results = {samples_per_second = samples_per_second, bytes_per_second = bytes_per_second}}
end

print(json.encode(benchmark_results))
