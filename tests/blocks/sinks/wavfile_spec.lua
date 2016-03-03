local radio = require('radio')
local jigs = require('tests.jigs')
local buffer = require('tests.buffer')

math.randomseed(1)

local function random_float32(n)
    local vec = radio.Float32Type.vector(n)
    for i = 0, n-1 do
        vec.data[i].value = 2*math.random() - 1
    end
    return vec
end

describe("RealFileSink", function ()
    local formats = {
        [8]     = {elem_size = 1, epsilon = 1e-2},
        [16]    = {elem_size = 2, epsilon = 1e-4},
        [32]    = {elem_size = 4, epsilon = 1e-6},
    }
    local headers = {
        [8]     = {
            [1] = "\x52\x49\x46\x46\x24\x01\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x44\xac\x00\x00\x44\xac\x00\x00\x01\x00\x08\x00\x64\x61\x74\x61\x00\x01\x00\x00",
            [2] = "\x52\x49\x46\x46\x24\x02\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x02\x00\x44\xac\x00\x00\x88\x58\x01\x00\x02\x00\x08\x00\x64\x61\x74\x61\x00\x02\x00\x00",
        },
        [16]    = {
            [1] = "\x52\x49\x46\x46\x24\x02\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x44\xac\x00\x00\x88\x58\x01\x00\x02\x00\x10\x00\x64\x61\x74\x61\x00\x02\x00\x00",
            [2] = "\x52\x49\x46\x46\x24\x04\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x02\x00\x44\xac\x00\x00\x10\xb1\x02\x00\x04\x00\x10\x00\x64\x61\x74\x61\x00\x04\x00\x00",
        },
        [32]    = {
            [1] = "\x52\x49\x46\x46\x24\x04\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x44\xac\x00\x00\x10\xb1\x02\x00\x04\x00\x20\x00\x64\x61\x74\x61\x00\x04\x00\x00",
            [2] = "\x52\x49\x46\x46\x24\x08\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x02\x00\x44\xac\x00\x00\x20\x62\x05\x00\x08\x00\x20\x00\x64\x61\x74\x61\x00\x08\x00\x00",
        },
    }

    local test_vectors = {random_float32(256), random_float32(256)}

    for _, bits_per_sample in ipairs({8, 16, 32}) do
        for _, num_channels in ipairs({1, 2}) do
            it("test vector " .. bits_per_sample .. " bits per sample " .. num_channels .. " channels", function ()
                local props = formats[bits_per_sample]

                -- Write test vector to sink
                local snk_fd = buffer.open()
                local snk = radio.WAVFileSink(snk_fd, num_channels, bits_per_sample)
                snk.get_rate = function () return 44100 end

                -- Run sink block
                signature = {}
                for i = 1, num_channels do
                    signature[i] = radio.Float32Type
                end
                snk:differentiate(signature)
                snk:initialize()
                snk:process(unpack(test_vectors))
                snk:cleanup()

                -- Read sink file descriptor into buf
                buffer.rewind(snk_fd)
 		        local buf = buffer.read(snk_fd, 2*props.elem_size*test_vectors[1].length*num_channels)
                assert.is.equal(44 + props.elem_size*num_channels*test_vectors[1].length, #buf)

                -- Check header
                assert.is.equal(headers[bits_per_sample][num_channels], string.sub(buf, 1, 44))

                -- Run source block
                local src_fd = buffer.open(buf)
                local src = radio.WAVFileSource(src_fd, num_channels)
                src:differentiate({})
                src:initialize()
                local vectors = {src:process()}
                src:cleanup()

                -- Compare vectors
                for i = 1, num_channels do
                    jigs.assert_vector_equal(test_vectors[i], vectors[i], props.epsilon)
                end
            end)
        end
    end
end)
