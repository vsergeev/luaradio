local ffi = require('ffi')

local radio = require('radio')
local jigs = require('tests.jigs')
local buffer = require('tests.buffer')

local test_vectors = require('tests.top_vectors')

describe("top level test", function ()
    --[[
            [ Source ] -- [ Mul. Conj. ] -- [ LPF ] -- [ Freq. Discrim. ] -- [ Decimator ] -- [ Sink ]
                                |
                                |
                            [ Source ]
    --]]

    for _, multiprocess in pairs({true, false}) do
        it("run " .. (multiprocess and "multiprocess" or "singleprocess"), function ()
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
end)
