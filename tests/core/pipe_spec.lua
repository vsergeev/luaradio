local ffi = require('ffi')

local radio = require('radio')
local block = require('radio.core.block')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

function random_byte_vector(n)
    local vec = radio.ByteType.vector(n)
    for i = 0, vec.length - 1 do
        vec.data[i].value = math.random(0, 255)
    end
    return vec
end

ffi.cdef[[
    int memcmp(const void *s1, const void *s2, size_t n);
    void memcpy(void *dest, const void *src, size_t n);
]]

describe("pipe", function ()
    it("write and read", function ()
        local test_vector = random_byte_vector(4096)

        for _, write_size in ipairs({1, 1235, test_vector.size}) do
            for _, read_size in ipairs({1, 1235, test_vector.size}) do
                local p = pipe.Pipe(nil, nil, radio.ByteType)
                p:initialize(true)

                local write_offset = 0
                local read_offset = 0

                while true do
                    -- Write up to write_size bytes to pipe
                    if write_offset < test_vector.size then
                        -- Pull out next write_size bytes into write_vec
                        local write_len = math.min(write_size, test_vector.size - write_offset)
                        local write_vec = radio.ByteType.deserialize(ffi.cast("char *", test_vector.data) + write_offset, write_len)
                        -- Write to pipe
                        p:write(write_vec)

                        -- Update write offset
                        write_offset = write_offset + write_vec.size

                        -- Close the write end of the pipe when we've reached the end
                        if write_offset == test_vector.size then
                            p:close_output()
                        end
                    end

                    -- Update pipe read buffer
                    local num_elems = p:read_update()
                    assert.is.equal(write_offset - read_offset, num_elems)

                    -- Read up to read_size bytes from pipe
                    local read_len = math.min(read_size, num_elems)
                    local read_vec = p:read_n(read_len)
                    assert.is_true(ffi.C.memcmp(ffi.cast("char *", test_vector.data) + read_offset, read_vec.data, read_vec.size) == 0)

                    -- Update read offset
                    read_offset = read_offset + read_vec.size

                    -- Stop when we've read the entire test vector
                    if write_offset == test_vector.size and read_offset == write_offset then
                        break
                    end
                end

                -- Assert that read_update() returns EOF / nil
                assert.is_true(p:read_update() == nil)
            end
        end
    end)

    it("write and read synchronous", function ()
        local test_vector = random_byte_vector(4096)

        local pipes = {
            pipe.Pipe(nil, nil, radio.ByteType),
            pipe.Pipe(nil, nil, radio.ByteType),
            pipe.Pipe(nil, nil, radio.ByteType),
        }

        for i = 1, #pipes do
            pipes[i]:initialize(true)
        end

        local write_offsets = {0, 0, 0}
        local read_offsets = {0, 0, 0}

        while true do
            for i = 1, #pipes do
                -- Write bytes to pipe
                if write_offsets[i] < test_vector.size then
                    -- Get next vector to write
                    local write_len = math.random(1, test_vector.size - write_offsets[i])
                    local write_vec = radio.ByteType.deserialize(ffi.cast("char *", test_vector.data) + write_offsets[i], write_len)
                    -- Write to pipe
                    pipes[i]:write(write_vec)

                    -- Update write offset
                    write_offsets[i] = write_offsets[i] + write_vec.size

                    -- Close the write end of the pipe when we've reached the end
                    if write_offsets[i] == test_vector.size then
                        pipes[i]:close_output()
                    end
                end
            end

            -- Read synchronously from all three pipes
            local read_vectors = pipe.read_synchronous(pipes)

            -- Check data and update offsets
            for i = 1, #pipes do
                assert.is_true(ffi.C.memcmp(ffi.cast("char *", test_vector.data) + read_offsets[i], read_vectors[i].data, read_vectors[i].size) == 0)
                read_offsets[i] = read_offsets[i] + read_vectors[i].size
            end

            -- Stop when we've read the entire test vector
            if util.array_all(write_offsets, function (offset) return offset == test_vector.size end) and util.array_all(read_offsets, function (offset) return offset == test_vector.size end) then
                break
            end
        end
    end)

    it("get rate", function ()
        local TestSource = block.factory("TestSource")

        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.Float32Type)})
        end

        function TestSource:get_rate()
            return 5
        end

        local TestSink = block.factory("TestSink")

        function TestSink:instantiate()
            self:add_type_signature({block.Input("in", radio.Float32Type)}, {})
        end

        -- Connect TestSource to TestSink
        local b0 = TestSource()
        local b1 = TestSink()

        b0:differentiate({})
        b1:differentiate({radio.Float32Type})

        local p = pipe.Pipe(b0.outputs[1], b1.inputs[1], radio.Float32Type)
        b0.outputs[1].pipes = {p}
        b1.inputs[1].pipe = p

        -- Check pipe and TestSink rates
        assert.is_equal(5, p:get_rate())
        assert.is_equal(5, b1:get_rate())
    end)
end)
