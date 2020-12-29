local ffi = require('ffi')

local radio = require('radio')
local block = require('radio.core.block')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

describe("pipe", function ()
    local FooType = radio.types.ObjectType.factory()

    function FooType.new(a, b, c)
        return setmetatable({a = a, b = b, c = c}, FooType)
    end

    local BarType = radio.types.ObjectType.factory()

    function BarType.new(x, y)
        return setmetatable({x = x, y = y}, BarType)
    end

    local function random_foo_vector(n)
        local vec = FooType.vector()
        for i = 1, n do
            vec:append(FooType(math.random(), string.char(math.random(0x41, 0x5a)), false))
        end
        return vec
    end

    local function random_bar_vector(n)
        local vec = BarType.vector()
        for i = 1, n do
            vec:append(BarType(math.random() > 5 and true or false, math.random(1, 100), false))
        end
        return vec
    end

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

    it("PipeMux read none", function ()
        local pipe_mux = pipe.PipeMux({}, {})

        local data_in, eof = pipe_mux:read()
        assert.is.same(data_in, {})
        assert.is_false(eof)
    end)

    it("PipeMux read cstruct single", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        local pipe_mux = pipe.PipeMux({p}, {})

        local vec = random_complexfloat32_vector(128)
        p:write(vec)

        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 1)
        assert.is.equal(data_in[1].data_type, vec.data_type)
        assert.is.equal(data_in[1].length, vec.length)
        assert.is.equal(ffi.C.memcmp(data_in[1].data, vec.data, 128 * ffi.sizeof(radio.types.ComplexFloat32)), 0)
    end)

    it("PipeMux read object single", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return FooType end
        p:initialize()

        local pipe_mux = pipe.PipeMux({p}, {})

        local vec = random_foo_vector(12)
        p:write(vec)

        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 1)
        assert.is.equal(data_in[1].data_type, vec.data_type)
        assert.is.equal(data_in[1].length, vec.length)
        for i = 0, vec.length-1 do
            assert.are.same(data_in[1].data[i], vec.data[i])
        end
    end)

    it("PipeMux read cstruct multiple", function ()
        local p1 = pipe.Pipe()
        p1.get_data_type = function () return radio.types.Byte end
        p1:initialize()

        local p2 = pipe.Pipe()
        p2.get_data_type = function () return radio.types.Float32 end
        p2:initialize()

        local p3 = pipe.Pipe()
        p3.get_data_type = function () return radio.types.ComplexFloat32 end
        p3:initialize()

        local pipe_mux = pipe.PipeMux({p1, p2, p3}, {})

        local vec1 = random_byte_vector(7)
        local vec2 = random_float32_vector(11)
        local vec3 = random_complexfloat32_vector(17)

        p1:write(vec1)
        p2:write(vec2)
        p3:write(vec3)

        -- Read 7 elements from all three input pipes
        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 3)

        assert.is.equal(data_in[1].data_type, radio.types.Byte)
        assert.is.equal(data_in[1].length, 7)
        assert.is.equal(ffi.C.memcmp(data_in[1].data, vec1.data, 3 * ffi.sizeof(radio.types.Byte)), 0)

        assert.is.equal(data_in[2].data_type, radio.types.Float32)
        assert.is.equal(data_in[2].length, 7)
        assert.is.equal(ffi.C.memcmp(data_in[2].data, vec2.data, 3 * ffi.sizeof(radio.types.Float32)), 0)

        assert.is.equal(data_in[3].data_type, radio.types.ComplexFloat32)
        assert.is.equal(data_in[3].length, 7)
        assert.is.equal(ffi.C.memcmp(data_in[3].data, vec3.data, 3 * ffi.sizeof(radio.types.ComplexFloat32)), 0)

        -- Remaining elements: 0, 4, 10

        local vec11 = random_byte_vector(4)
        p1:write(vec11)

        -- Read 4 elements from all three input pipes
        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 3)

        assert.is.equal(data_in[1].data_type, radio.types.Byte)
        assert.is.equal(data_in[1].length, 4)
        assert.is.equal(ffi.C.memcmp(data_in[1].data, vec11.data, 4 * ffi.sizeof(radio.types.Byte)), 0)

        assert.is.equal(data_in[2].data_type, radio.types.Float32)
        assert.is.equal(data_in[2].length, 4)
        assert.is.equal(ffi.C.memcmp(data_in[2].data, vec2.data + 7, 4 * ffi.sizeof(radio.types.Float32)), 0)

        assert.is.equal(data_in[3].data_type, radio.types.ComplexFloat32)
        assert.is.equal(data_in[3].length, 4)
        assert.is.equal(ffi.C.memcmp(data_in[3].data, vec3.data + 7, 4 * ffi.sizeof(radio.types.ComplexFloat32)), 0)

        -- Remaining elements: 0, 0, 6

        local vec111 = random_byte_vector(6)
        local vec22 = random_float32_vector(6)

        p1:write(vec111)
        p2:write(vec22)

        -- Read 6 elements from all three input pipes
        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 3)

        assert.is.equal(data_in[1].data_type, radio.types.Byte)
        assert.is.equal(data_in[1].length, 6)
        assert.is.equal(ffi.C.memcmp(data_in[1].data, vec111.data, 6 * ffi.sizeof(radio.types.Byte)), 0)

        assert.is.equal(data_in[2].data_type, radio.types.Float32)
        assert.is.equal(data_in[2].length, 6)
        assert.is.equal(ffi.C.memcmp(data_in[2].data, vec22.data, 6 * ffi.sizeof(radio.types.Float32)), 0)

        assert.is.equal(data_in[3].data_type, radio.types.ComplexFloat32)
        assert.is.equal(data_in[3].length, 6)
        assert.is.equal(ffi.C.memcmp(data_in[3].data, vec3.data + 11, 6 * ffi.sizeof(radio.types.ComplexFloat32)), 0)
    end)

    it("PipeMux read object multiple", function ()
        local p1 = pipe.Pipe()
        p1.get_data_type = function () return FooType end
        p1:initialize()

        local p2 = pipe.Pipe()
        p2.get_data_type = function () return BarType end
        p2:initialize()

        local pipe_mux = pipe.PipeMux({p1, p2}, {})

        local vec1 = random_foo_vector(7)
        local vec2 = random_bar_vector(11)

        p1:write(vec1)
        p2:write(vec2)

        -- Read 7 elements from both input pipes
        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 2)

        assert.is.equal(data_in[1].data_type, FooType)
        assert.is.equal(data_in[1].length, 7)
        for i = 0, 6 do
            assert.are.same(data_in[1].data[i], vec1.data[i])
        end

        assert.is.equal(data_in[2].data_type, BarType)
        assert.is.equal(data_in[2].length, 7)
        for i = 0, 6 do
            assert.are.same(data_in[2].data[i], vec2.data[i])
        end

        -- Remaining elements: 0, 4

        local vec11 = random_foo_vector(4)
        p1:write(vec11)

        -- Read 4 elements from both input pipes
        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 2)

        assert.is.equal(data_in[1].data_type, FooType)
        assert.is.equal(data_in[1].length, 4)
        for i = 0, 3 do
            assert.are.same(data_in[1].data[i], vec11.data[i])
        end

        assert.is.equal(data_in[2].data_type, BarType)
        assert.is.equal(data_in[2].length, 4)
        for i = 7, 10 do
            assert.are.same(data_in[2].data[i - 7], vec2.data[i])
        end
    end)

    it("PipeMux read single eof", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        local pipe_mux = pipe.PipeMux({p}, {})

        local vec = random_complexfloat32_vector(128)
        p:write(vec)

        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 1)
        assert.is.equal(data_in[1].length, vec.length)

        p:close_output()
        local data_in, eof = pipe_mux:read()
        assert.is_true(eof)
        assert.is.same(data_in, {})
    end)

    it("PipeMux read multiple eof", function ()
        local p1 = pipe.Pipe()
        p1.get_data_type = function () return radio.types.Byte end
        p1:initialize()

        local p2 = pipe.Pipe()
        p2.get_data_type = function () return radio.types.Float32 end
        p2:initialize()

        local p3 = pipe.Pipe()
        p3.get_data_type = function () return radio.types.ComplexFloat32 end
        p3:initialize()

        local pipe_mux = pipe.PipeMux({p1, p2, p3}, {})

        local vec1 = random_byte_vector(11)
        local vec2 = random_float32_vector(7)
        local vec3 = random_complexfloat32_vector(17)

        p1:write(vec1)
        p2:write(vec2)
        p3:write(vec3)

        -- Read 7
        local data_in, eof = pipe_mux:read()
        assert.is_false(eof)
        assert.is.equal(#data_in, 3)
        assert.is.equal(data_in[1].length, 7)
        assert.is.equal(data_in[1].length, 7)
        assert.is.equal(data_in[1].length, 7)

        -- Close p2
        p2:close_output()
        local data_in, eof = pipe_mux:read()
        assert.is_true(eof)
        assert.is.same(data_in, {})
    end)

    it("PipeMux write none", function ()
        local pipe_mux = pipe.PipeMux({}, {})

        local eof, eof_pipe = pipe_mux:write({})
        assert.is.equal(eof, false)
        assert.is_nil(eof_pipe)
    end)

    it("PipeMux write cstruct single", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        local pipe_mux = pipe.PipeMux({}, {{p}})

        local vec = random_complexfloat32_vector(128)

        local eof, eof_pipe = pipe_mux:write({vec})
        assert.is_false(eof)
        assert.is_nil(eof_pipe)

        local read_vec = p:read()
        assert.is.equal(read_vec.data_type, vec.data_type)
        assert.is.equal(read_vec.length, vec.length)
        assert.is.equal(ffi.C.memcmp(read_vec.data, vec.data, 128 * ffi.sizeof(radio.types.ComplexFloat32)), 0)
    end)

    it("PipeMux write object single", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return FooType end
        p:initialize()

        local pipe_mux = pipe.PipeMux({}, {{p}})

        local vec = random_foo_vector(12)

        local eof, eof_pipe = pipe_mux:write({vec})
        assert.is_false(eof)
        assert.is_nil(eof_pipe)

        local read_vec = p:read()
        assert.is.equal(read_vec.data_type, vec.data_type)
        assert.is.equal(read_vec.length, vec.length)
        for i = 0, vec.length-1 do
            assert.are.same(read_vec.data[i], vec.data[i])
        end
    end)

    it("PipeMux write cstruct multiple", function ()
        local p11 = pipe.Pipe()
        p11.get_data_type = function () return radio.types.Byte end
        p11:initialize()

        local p12 = pipe.Pipe()
        p12.get_data_type = function () return radio.types.Byte end
        p12:initialize()

        local p2 = pipe.Pipe()
        p2.get_data_type = function () return radio.types.Float32 end
        p2:initialize()

        local p31 = pipe.Pipe()
        p31.get_data_type = function () return radio.types.ComplexFloat32 end
        p31:initialize()

        local p32 = pipe.Pipe()
        p32.get_data_type = function () return radio.types.ComplexFloat32 end
        p32:initialize()

        local p33 = pipe.Pipe()
        p33.get_data_type = function () return radio.types.ComplexFloat32 end
        p33:initialize()

        local pipe_mux = pipe.PipeMux({}, {{p11, p12}, {p2}, {p31, p32, p33}})

        local vec1 = random_byte_vector(11)
        local vec2 = random_float32_vector(7)
        local vec3 = random_complexfloat32_vector(17)

        local eof, eof_pipe = pipe_mux:write({vec1, vec2, vec3})
        assert.is_false(eof)
        assert.is_nil(eof_pipe)

        function check_pipe(p, vec)
            local read_vec = p:read()
            assert.is.equal(read_vec.data_type, vec.data_type)
            assert.is.equal(read_vec.length, vec.length)
            assert.is.equal(ffi.C.memcmp(read_vec.data, vec.data, vec.length * ffi.sizeof(vec.data_type)), 0)
        end

        check_pipe(p11, vec1)
        check_pipe(p12, vec1)
        check_pipe(p2, vec2)
        check_pipe(p31, vec3)
        check_pipe(p32, vec3)
        check_pipe(p33, vec3)
    end)

    it("PipeMux write object multiple", function ()
        local p11 = pipe.Pipe()
        p11.get_data_type = function () return FooType end
        p11:initialize()

        local p21 = pipe.Pipe()
        p21.get_data_type = function () return BarType end
        p21:initialize()

        local p22 = pipe.Pipe()
        p22.get_data_type = function () return BarType end
        p22:initialize()

        local pipe_mux = pipe.PipeMux({}, {{p11}, {p21, p22}})

        local vec1 = random_foo_vector(4)
        local vec2 = random_bar_vector(7)

        local eof, eof_pipe = pipe_mux:write({vec1, vec2})
        assert.is_false(eof)
        assert.is_nil(eof_pipe)

        function check_pipe(p, vec)
            local read_vec = p:read()
            assert.is.equal(read_vec.data_type, vec.data_type)
            assert.is.equal(read_vec.length, vec.length)
            for i = 0, vec.length-1 do
                assert.are.same(read_vec.data[i], vec.data[i])
            end
        end

        check_pipe(p11, vec1)
        check_pipe(p21, vec2)
        check_pipe(p22, vec2)
    end)

    it("PipeMux write single eof", function ()
        local p = pipe.Pipe()
        p.get_data_type = function () return radio.types.ComplexFloat32 end
        p:initialize()

        local pipe_mux = pipe.PipeMux({}, {{p}})

        local vec = random_complexfloat32_vector(128)

        local eof, eof_pipe = pipe_mux:write({vec})
        assert.is_false(eof)
        assert.is_nil(eof_pipe)

        p:read()
        p:close_input()

        local eof, eof_pipe = pipe_mux:write({vec})
        assert.is_true(eof)
        assert.is.equal(eof_pipe, p)
    end)

    it("PipeMux write multiple eof", function ()
        local p1 = pipe.Pipe()
        p1.get_data_type = function () return radio.types.Byte end
        p1:initialize()

        local p21 = pipe.Pipe()
        p21.get_data_type = function () return radio.types.Float32 end
        p21:initialize()

        local p22 = pipe.Pipe()
        p22.get_data_type = function () return radio.types.Float32 end
        p22:initialize()

        local p31 = pipe.Pipe()
        p31.get_data_type = function () return radio.types.ComplexFloat32 end
        p31:initialize()

        local p32 = pipe.Pipe()
        p32.get_data_type = function () return radio.types.ComplexFloat32 end
        p32:initialize()

        local p33 = pipe.Pipe()
        p33.get_data_type = function () return radio.types.ComplexFloat32 end
        p33:initialize()

        local pipe_mux = pipe.PipeMux({}, {{p1}, {p21, p22}, {p31, p32, p33}})

        local vec1 = random_byte_vector(11)
        local vec2 = random_float32_vector(7)
        local vec3 = random_complexfloat32_vector(17)

        local eof, eof_pipe = pipe_mux:write({vec1, vec2, vec3})
        assert.is_false(eof)
        assert.is_nil(eof_pipe)

        p1:read()
        p21:read()
        p22:read()
        p31:read()
        p32:read()
        p33:read()

        p22:close_input()

        local eof, eof_pipe = pipe_mux:write({vec1, vec2, vec3})
        assert.is_true(eof)
        assert.is.equal(eof_pipe, p22)
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
