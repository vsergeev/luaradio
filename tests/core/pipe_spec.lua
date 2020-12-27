local ffi = require('ffi')

local radio = require('radio')
local block = require('radio.core.block')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

describe("pipe", function ()
    local function random_byte_vector(n)
        local vec = radio.types.Byte.vector(n)
        for i = 0, vec.length - 1 do
            vec.data[i].value = math.random(0, 255)
        end
        return vec
    end

    local function random_float32_vector(n)
        local vec = radio.types.Float32.vector(n)
        for i = 0, vec.length - 1 do
            vec.data[i].value = 2*math.random() - 1.0
        end
        return vec
    end

    local function random_complexfloat32_vector(n)
        local vec = radio.types.ComplexFloat32.vector(n)
        for i = 0, vec.length - 1 do
            vec.data[i].real = 2*math.random() - 1.0
            vec.data[i].imag = 2*math.random() - 1.0
        end
        return vec
    end

    local cstruct_types = {
        ["Byte"] = {data_type = radio.types.Byte, random_vector_fn = random_byte_vector},
        ["Float32"] = {data_type = radio.types.Float32, random_vector_fn = random_float32_vector},
        ["ComplexFloat32"] = {data_type = radio.types.Float32, random_vector_fn = random_float32_vector},
    }

    it("read buffer", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        assert.is.equal(p:_read_buffer_count(), 0)
        assert.is_false(p:_read_buffer_full())

        local write_vec = random_complexfloat32_vector(128)
        p:write(write_vec)

        assert.is.equal(p:_read_buffer_update(), write_vec.size)
        assert.is.equal(p:_read_buffer_count(), write_vec.length)
        assert.is_false(p:_read_buffer_full())

        -- Read 3
        local read_vec = p:_read_buffer_deserialize(3)
        assert.is.equal(read_vec.length, 3)
        assert.is_true(ffi.C.memcmp(read_vec.data, write_vec.data, 3 * ffi.sizeof(radio.types.ComplexFloat32)) == 0)

        assert.is.equal(p:_read_buffer_count(), 125)

        -- Read 125
        local read_vec = p:_read_buffer_deserialize(125)
        assert.is.equal(read_vec.length, 125)
        assert.is_true(ffi.C.memcmp(read_vec.data, ffi.cast("char *", write_vec.data) + 3 * ffi.sizeof(radio.types.ComplexFloat32), 125 * ffi.sizeof(radio.types.ComplexFloat32)) == 0)

        assert.is.equal(p:_read_buffer_count(), 0)

        while not p:_read_buffer_full() do
            local write_vec = random_complexfloat32_vector(128)
            p:write(write_vec)
            p:_read_buffer_update()
        end

        assert.is.equal(p:_read_buffer_count(), p._rbuf_capacity / ffi.sizeof(radio.types.ComplexFloat32))
    end)

    it("read buffer eof", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        assert.is.equal(p:_read_buffer_count(), 0)
        assert.is_false(p:_read_buffer_full())

        p:close_output()
        assert.is.equal(p:_read_buffer_update(), nil)
        assert.is.equal(p:_read_buffer_count(), nil)
        assert.is_false(p:_read_buffer_full())
    end)

    it("write buffer", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        assert.is_true(p:_write_buffer_empty(), true)

        local write_vec = random_complexfloat32_vector(128)

        p:_write_buffer_serialize(write_vec)
        assert.is.equal(p:_write_buffer_empty(), false)
        assert.is.equal(p:_write_buffer_update(), write_vec.size)
        assert.is.equal(p:_write_buffer_empty(), true)

        local read_vec = p:read(128)
        assert.is.equal(read_vec.length, 128)
        assert.is_true(ffi.C.memcmp(read_vec.data, write_vec.data, 128 * ffi.sizeof(radio.types.ComplexFloat32)) == 0)
    end)

    it ("write buffer eof", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        -- Ignore SIGPIPE, handle with error from write()
        ffi.C.signal(ffi.C.SIGPIPE, ffi.cast("sighandler_t", ffi.C.SIG_IGN))

        p:close_input()
        assert.is.equal(p:_write_buffer_serialize(random_complexfloat32_vector(128)), nil)
        assert.is.equal(p:_write_buffer_update(), nil)
    end)

    for type_name, _ in pairs(cstruct_types) do
        it("write and read cstruct " .. type_name, function ()
            local data_type = cstruct_types[type_name].data_type
            local test_vector = cstruct_types[type_name].random_vector_fn(512)

            for _, write_num in ipairs({1, 123, test_vector.length}) do
                for _, read_num in ipairs({1, 123, test_vector.length}) do
                    local p = pipe.Pipe()
                    p.get_data_type = function () return data_type end
                    p:initialize()

                    -- Write and read offsets into test vector
                    local write_offset = 0
                    local read_offset = 0

                    while true do
                        -- Write up to write_num elements to pipe
                        if write_offset < test_vector.size then
                            -- Pull out next write_num elements into write_vec
                            local size = math.min(write_num * ffi.sizeof(data_type), test_vector.size - write_offset)
                            local write_vec = data_type.deserialize(ffi.cast("char *", test_vector.data) + write_offset, size)

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
                        p:_read_buffer_update()
                        -- Get buffer item count
                        local num_elems = p:_read_buffer_count()
                        assert.is.equal(write_offset - read_offset, num_elems*ffi.sizeof(data_type))

                        -- Read up to read_num elements from pipe
                        local n = math.min(read_num, num_elems)
                        local read_vec = p:_read_buffer_deserialize(n)
                        assert.is.equal(n, read_vec.length)
                        assert.is.equal(data_type, read_vec.data_type)

                        -- Compare read vector with test vector
                        assert.is_true(ffi.C.memcmp(ffi.cast("char *", test_vector.data) + read_offset, read_vec.data, read_vec.size) == 0)

                        -- Update read offset
                        read_offset = read_offset + read_vec.size

                        -- Stop when we've read the entire test vector
                        if write_offset == test_vector.size and read_offset == write_offset then
                            break
                        end
                    end

                    -- Update pipe read buffer
                    p:_read_buffer_update()
                    -- Get buffer item is EOF / nil
                    assert.is_true(p:_read_buffer_count() == nil)
                end
            end
        end)
    end

    it("write and read object type", function ()
        local FooType = radio.types.ObjectType.factory()

        function FooType.new(a, b, c)
            return setmetatable({a = a, b = b, c = c}, FooType)
        end

        local function random_foo_vector(n)
            local vec = FooType.vector()
            for i = 1, n do
                vec:append(FooType(math.random(), string.char(math.random(0x41, 0x5a)), false))
            end
            return vec
        end

        local test_vector = random_foo_vector(175)

        for _, write_num in ipairs({1, 123, test_vector.length}) do
            for _, read_num in ipairs({1, 123, test_vector.length}) do
                local p = pipe.Pipe()
                p.get_data_type = function () return FooType end
                p:initialize()

                -- Write and read counts of test vector
                local write_count = 0
                local read_count = 0

                while true do
                    -- Write up to write_num elements to pipe
                    if write_count < test_vector.length then
                        -- Pull out next write_num elements into write_vec
                        local n = math.min(write_num, test_vector.length - write_count)
                        local write_vec = FooType.vector()
                        for i = 0, n-1 do
                            write_vec:append(test_vector.data[write_count + i])
                        end

                        -- Write to pipe
                        p:write(write_vec)

                        -- Update write count
                        write_count = write_count + write_vec.length

                        -- Close the write end of the pipe when we've reached the end
                        if write_count == test_vector.length then
                            p:close_output()
                        end
                    end

                    -- Update pipe read buffer
                    p:_read_buffer_update()
                    -- Get buffer item count
                    local num_elems = p:_read_buffer_count()

                    -- Read up to read_num elements from pipe
                    local n = math.min(read_num, num_elems)
                    local read_vec = p:_read_buffer_deserialize(n)
                    assert.is.equal(n, read_vec.length)
                    assert.is.equal(FooType, read_vec.data_type)

                    -- Compare read vector with test vector
                    for i = 0, read_vec.length-1 do
                        assert.are.same(test_vector.data[read_count+i], read_vec.data[i])
                    end

                    -- Update read count
                    read_count = read_count + read_vec.length

                    -- Stop when we've read the entire test vector
                    if write_count == test_vector.length and read_count == test_vector.length then
                        break
                    end
                end

                -- Update pipe read buffer
                p:_read_buffer_update()
                -- Get buffer item is EOF / nil
                assert.is_true(p:_read_buffer_count() == nil)
            end
        end
    end)

    it("write and read synchronous", function ()
        local test_vectors = {
            random_byte_vector(512),
            random_float32_vector(512),
            random_complexfloat32_vector(512),
        }

        -- Create three pipes
        local pipes = {
            pipe.Pipe(),
            pipe.Pipe(),
            pipe.Pipe(),
        }

        -- Initialize pipes
        for i = 1, #pipes do
            pipes[i].get_data_type = function () return test_vectors[i].data_type end
            pipes[i]:initialize()
        end

        -- Write and read offsets into test_vectors for each pipe
        local write_offsets = {0, 0, 0}
        local read_offsets = {0, 0, 0}

        while true do
            -- For each pipe
            for i = 1, #pipes do
                local data_type = pipes[i].data_type

                -- Write elements to pipe
                if write_offsets[i] < test_vectors[i].size then
                    -- Pull out next random number of elements into write_vec
                    local size = math.random(1, (test_vectors[i].size - write_offsets[i])/ffi.sizeof(data_type))*ffi.sizeof(data_type)
                    local write_vec = data_type.deserialize(ffi.cast("char *", test_vectors[i].data) + write_offsets[i], size)

                    -- Write to pipe
                    pipes[i]:write(write_vec)

                    -- Update write offset
                    write_offsets[i] = write_offsets[i] + write_vec.size

                    -- Close the write end of the pipe when we've reached the end
                    if write_offsets[i] == test_vectors[i].size then
                        pipes[i]:close_output()
                    end
                end
            end

            -- Read synchronously from all three pipes
            local read_vectors = pipe.read_synchronous(pipes)

            local n = read_vectors[1].length

            -- Check length, types, data and update offsets
            for i = 1, #pipes do
                assert.is.equal(n, read_vectors[i].length)
                assert.is.equal(pipes[i].data_type, read_vectors[i].data_type)
                assert.is_true(ffi.C.memcmp(ffi.cast("char *", test_vectors[i].data) + read_offsets[i], read_vectors[i].data, read_vectors[i].size) == 0)

                read_offsets[i] = read_offsets[i] + read_vectors[i].size
            end

            -- Stop when we've read the entire test vector
            local eof = true
            for i = 1, #pipes do
                if write_offsets[i] ~= test_vectors[i].size or read_offsets[i] ~= test_vectors[i].size then
                    eof = false
                    break
                end
            end
            if eof then
                break
            end
        end
    end)

    it("get rate", function ()
        local TestSource = block.factory("TestSource")

        function TestSource:instantiate()
            self:add_type_signature({}, {block.Output("out", radio.types.Float32)})
        end

        function TestSource:get_rate()
            return 5
        end

        local TestSink = block.factory("TestSink")

        function TestSink:instantiate()
            self:add_type_signature({block.Input("in", radio.types.Float32)}, {})
        end

        -- Connect TestSource to TestSink
        local b0 = TestSource()
        local b1 = TestSink()

        b0:differentiate({})
        b1:differentiate({radio.types.Float32})

        local p = pipe.Pipe(b0.outputs[1], b1.inputs[1])
        b0.outputs[1].pipes = {p}
        b1.inputs[1].pipe = p

        -- Check pipe and TestSink rates
        assert.is.equal(5, p:get_rate())
        assert.is.equal(5, b1:get_rate())
    end)
end)
