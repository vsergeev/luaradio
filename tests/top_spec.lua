local ffi = require('ffi')

local radio = require('radio')
local jigs = require('tests.jigs')
local buffer = require('tests.buffer')

local test_vectors = dofile('tests/top_vectors.gen.lua')

ffi.cdef[[
int pipe(int fildes[2]);
]]

describe("top level test", function ()
    for _, multiprocess in pairs({true, false}) do
        it("example " .. (multiprocess and "multiprocess" or "singleprocess"), function ()
            --[[
                    [ Source ] -- [ Mul. Conj. ] -- [ LPF ] -- [ Freq. Discrim. ] -- [ Decimator ] -- [ Sink ]
                                        |
                                        |
                                    [ Source ]
            --]]

            -- Prepare our source and sink file descriptors
            local src1_fd = buffer.open(test_vectors.SRC1_TEST_VECTOR)
            local src2_fd = buffer.open(test_vectors.SRC2_TEST_VECTOR)
            local snk_fd = buffer.open()

            -- Build the pipeline
            local top = radio.CompositeBlock()
            local src1 = radio.IQFileSource(src1_fd, 'f32le', 1000000)
            local src2 = radio.IQFileSource(src2_fd, 'f32le', 1000000)
            local b1 = radio.MultiplyConjugateBlock()
            local b2 = radio.LowpassFilterBlock(16, 100e3)
            local b3 = radio.FrequencyDiscriminatorBlock(5.0)
            local b4 = radio.DecimatorBlock(25, {num_taps = 16})
            local snk = radio.RawFileSink(snk_fd)
            top:connect(src1, 'out', b1, 'in1')
            top:connect(src2, 'out', b1, 'in2')
            top:connect(b1, b2, b3, b4, snk)
            top:run(multiprocess)

            -- Rewind the sink buffer
            buffer.rewind(snk_fd)

            -- Read the sink buffer
            local buf = buffer.read(snk_fd, #test_vectors.SNK_TEST_VECTOR*2)
            assert.is.equal(#test_vectors.SNK_TEST_VECTOR, #buf)

            -- Deserialize actual and expected test vectors
            local actual = radio.types.Float32.deserialize(buf, #test_vectors.SNK_TEST_VECTOR/4)
            local expected = radio.types.Float32.deserialize(test_vectors.SNK_TEST_VECTOR, #test_vectors.SNK_TEST_VECTOR/4)

            jigs.assert_vector_equal(expected, actual, 1e-6)
        end)
    end

    it("flow graph wait()", function ()
        -- Create a pipe
        local pipe_fds = ffi.new("int[2]")
        assert(ffi.C.pipe(pipe_fds) == 0)

        -- Build and start flow graph
        local top = radio.CompositeBlock():connect(
            radio.RawFileSource(pipe_fds[0], radio.types.Byte, 1),
            radio.DelayBlock(10),
            radio.PrintSink()
        ):start()

        -- Close write end of pipe
        assert(ffi.C.close(pipe_fds[1]) == 0)

        -- Wait for flow graph to finish
        top:wait()

        -- Close read end of pipe
        assert(ffi.C.close(pipe_fds[0]) == 0)
    end)

    it("flow graph stop()", function ()
        -- Build and start flow graph
        local top = radio.CompositeBlock():connect(
            radio.UniformRandomSource(radio.types.ComplexFloat32, 1e6),
            radio.DelayBlock(10),
            radio.NopSink()
        ):start()

        ffi.C.usleep(1000)

        -- Stop flow graph
        top:stop()
    end)

    it("flow graph stop() unresponsive", function ()
        -- Create a pipe
        local pipe_fds = ffi.new("int[2]")
        assert(ffi.C.pipe(pipe_fds) == 0)

        -- Build and start flow graph
        local top = radio.CompositeBlock():connect(
            radio.RawFileSource(pipe_fds[0], radio.types.Byte, 1),
            radio.DelayBlock(10),
            radio.PrintSink()
        ):start()

        -- Stop flow graph
        top:stop()

        -- Close pipe
        assert(ffi.C.close(pipe_fds[1]) == 0)
        assert(ffi.C.close(pipe_fds[0]) == 0)
    end)

    it("flow graph status()", function ()
        -- Create a pipe
        local pipe_fds = ffi.new("int[2]")
        assert(ffi.C.pipe(pipe_fds) == 0)

        -- Build and start flow graph
        local top = radio.CompositeBlock():connect(
            radio.RawFileSource(pipe_fds[0], radio.types.Byte, 1),
            radio.DelayBlock(10),
            radio.PrintSink()
        ):start()

        -- Check running status
        assert.is.equal(top:status().running, true)

        -- Close write end of pipe
        assert(ffi.C.close(pipe_fds[1]) == 0)

        -- Wait for running status to trip
        local tic = os.time()
        while true do
            if not top:status().running then
                break
            end

            -- Timeout after 5 seconds
            assert.is_true((os.time() - tic) < 5)
        end

        -- Close read end of pipe
        assert(ffi.C.close(pipe_fds[0]) == 0)
    end)

    it("flow graph data integrity", function ()
        local SRC_SIZE = 4*1048576

        -- Create source and sink buffers
        local src_fd = buffer.open()
        local snk_fd = buffer.open()

        -- Write random bytes to source
        local f_random = io.open("/dev/urandom", "rb")
        buffer.write(src_fd, f_random:read(SRC_SIZE))
        f_random:close()
        buffer.rewind(src_fd)

        -- Create and run the pipeline
        local top = radio.CompositeBlock():connect(
            radio.RawFileSource(src_fd, radio.types.Byte, 1),
            radio.RawFileSink(snk_fd)
        ):run()

        -- Rewind buffers
        buffer.rewind(src_fd)
        buffer.rewind(snk_fd)

        -- Compare buffers
        local a = buffer.read(src_fd, SRC_SIZE*2)
        local b = buffer.read(snk_fd, SRC_SIZE*2)
        assert.is.equal(SRC_SIZE, #a)
        assert.is.equal(#a, #b)
        assert.is_true(a == b)
    end)
end)
