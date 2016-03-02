local radio = require('radio')
local jigs = require('tests.jigs')
local buffer = require('tests.buffer')

math.randomseed(1)

local function random_complexfloat32(n)
    local vec = radio.ComplexFloat32Type.vector(n)
    for i = 0, n-1 do
        vec.data[i].real = 2*math.random() - 1
        vec.data[i].imag = 2*math.random() - 1
    end
    return vec
end

describe("IQFileSink", function ()
    local formats = {
        u8      = {elem_size = 2, epsilon = 1e-1},
        s8      = {elem_size = 2, epsilon = 1e-1},
        u16le   = {elem_size = 4, epsilon = 1e-4},
        u16be   = {elem_size = 4, epsilon = 1e-4},
        s16le   = {elem_size = 4, epsilon = 1e-4},
        s16be   = {elem_size = 4, epsilon = 1e-4},
        u32le   = {elem_size = 8, epsilon = 1e-6},
        u32be   = {elem_size = 8, epsilon = 1e-6},
        s32le   = {elem_size = 8, epsilon = 1e-6},
        s32be   = {elem_size = 8, epsilon = 1e-6},
        f32le   = {elem_size = 8, epsilon = 1e-6},
        f32be   = {elem_size = 8, epsilon = 1e-6},
        f64le   = {elem_size = 16, epsilon = 1e-6},
        f64be   = {elem_size = 16, epsilon = 1e-6},
    }

    local test_vector = random_complexfloat32(256)

    for fmt, props in pairs(formats) do
    	it("test vector " .. fmt, function ()
            -- Write test vector to sink
            local snk_fd = buffer.open()
            local snk = radio.IQFileSink(snk_fd, fmt)
            snk:differentiate({radio.ComplexFloat32Type})
            snk:initialize()
            snk:process(test_vector)
            snk:cleanup()

            -- Read sink file descriptor into buf
            buffer.rewind(snk_fd)
 		    local buf = buffer.read(snk_fd, 2*props.elem_size*test_vector.length)
            assert.is.equal(props.elem_size*test_vector.length, #buf)

            -- Write buf to source
            local src_fd = buffer.open(buf)
            local src = radio.IQFileSource(src_fd, fmt)
            src:differentiate({})
            src:initialize()
            local vec = src:process()
            src:cleanup()

            -- Check vector
            assert.is.equal(test_vector.length, vec.length)
            jigs.assert_vector_equal(test_vector, vec, props.epsilon)
        end)
    end
end)
