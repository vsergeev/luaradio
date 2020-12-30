local ffi = require('ffi')

local radio = require('radio')
local format_utils = require('radio.utilities.format_utils')

local buffer = require('tests.buffer')

describe("network tests", function ()
    math.randomseed(1)

    -- Generate f32le test vector
    local test_vector_float = ffi.new("format_f32_t[?]", 4096)
    for i = 0, 4096-1 do
        test_vector_float[i].value = math.random()
        if format_utils.formats.f32le.swap then
            format_utils.swap_bytes(test_vector_float[i])
        end
    end
    test_vector_float = ffi.string(test_vector_float, ffi.sizeof(test_vector_float))

    -- Generate cstruct type test vector
    ffi.cdef[[
        typedef struct {
            uint8_t a, b, c;
        } mytype_t;
    ]]
    local MyCStructType = radio.types.CStructType.factory("mytype_t", mytype_mt)
    local test_vector_cstruct = MyCStructType.vector(4096)
    for i = 0, test_vector_cstruct.length-1 do
        test_vector_cstruct.data[i].a = math.random(0, 255)
        test_vector_cstruct.data[i].b = math.random(0, 255)
        test_vector_cstruct.data[i].c = math.random(0, 255)
    end
    test_vector_cstruct = ffi.string(test_vector_cstruct.data, test_vector_cstruct.size)

    -- Generate object type test vector
    local MyObjectType = radio.types.ObjectType.factory()
    function MyObjectType.new(foo, bar)
        local self = setmetatable({}, MyObjectType)
        self.foo = foo
        self.bar = bar
        return self
    end
    local test_vector_object = ""
    for i = 0, 1024-1 do
        test_vector_object = test_vector_object .. MyObjectType(math.random(0, 1023), math.random(0, 1023)):to_json() .. "\n"
    end

    ---------------------------------------------------------------------------
    -- NetworkServerSink + NetworkClientSource
    ---------------------------------------------------------------------------

    it("NetworkServerSink + NetworkClientSource (ComplexFloat32)", function ()
        local src_fd = buffer.open(test_vector_float)
        local snk_fd = buffer.open()

        local top_server = radio.CompositeBlock():connect(
            radio.IQFileSource(src_fd, 'f32le', 1000000),
            radio.NetworkServerSink('f32le', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_client = radio.CompositeBlock():connect(
            radio.NetworkClientSource(radio.types.ComplexFloat32, 1000000, 'f32le', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.IQFileSink(snk_fd, 'f32le')
        )

        top_server:start()
        top_client:start()

        top_client:wait()
        top_server:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_float*2)
        assert.is_true(buf == test_vector_float)
    end)
    it("NetworkServerSink + NetworkClientSource (Float32)", function ()
        local src_fd = buffer.open(test_vector_float)
        local snk_fd = buffer.open()

        local top_server = radio.CompositeBlock():connect(
            radio.RealFileSource(src_fd, 'f32le', 1000000),
            radio.NetworkServerSink('f32le', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_client = radio.CompositeBlock():connect(
            radio.NetworkClientSource(radio.types.Float32, 1000000, 'f32le', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.RealFileSink(snk_fd, 'f32le')
        )

        top_server:start()
        top_client:start()

        top_client:wait()
        top_server:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_float*2)
        assert.is_true(buf == test_vector_float)
    end)
    it("NetworkServerSink + NetworkClientSource (CStructType)", function ()
        local src_fd = buffer.open(test_vector_cstruct)
        local snk_fd = buffer.open()

        local top_server = radio.CompositeBlock():connect(
            radio.RawFileSource(src_fd, MyCStructType, 1000000),
            radio.NetworkServerSink('raw', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_client = radio.CompositeBlock():connect(
            radio.NetworkClientSource(MyCStructType, 1000000, 'raw', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.RawFileSink(snk_fd)
        )

        top_server:start()
        top_client:start()

        top_client:wait()
        top_server:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_cstruct*2)
        assert.is_true(buf == test_vector_cstruct)
    end)
    it("NetworkServerSink + NetworkClientSource (ObjectType)", function ()
        local src_fd = buffer.open(test_vector_object)
        local snk_fd = buffer.open()

        local top_server = radio.CompositeBlock():connect(
            radio.JSONSource(src_fd, MyObjectType, 1000000),
            radio.NetworkServerSink('json', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_client = radio.CompositeBlock():connect(
            radio.NetworkClientSource(MyObjectType, 1000000, 'json', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.JSONSink(snk_fd)
        )

        top_server:start()
        top_client:start()

        top_client:wait()
        top_server:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_object*2)
        assert.is_true(buf == test_vector_object)
    end)

    ---------------------------------------------------------------------------
    -- NetworkClientSink + NetworkServerSource
    ---------------------------------------------------------------------------

    it("NetworkClientSink + NetworkServerSource (ComplexFloat32)", function ()
        local src_fd = buffer.open(test_vector_float)
        local snk_fd = buffer.open()

        local top_client = radio.CompositeBlock():connect(
            radio.IQFileSource(src_fd, 'f32le', 1000000),
            radio.NetworkClientSink('f32le', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_server = radio.CompositeBlock():connect(
            radio.NetworkServerSource(radio.types.ComplexFloat32, 1000000, 'f32le', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.IQFileSink(snk_fd, 'f32le')
        )

        top_server:start()
        top_client:start()

        top_server:wait()
        top_client:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_float*2)
        assert.is_true(buf == test_vector_float)
    end)
    it("NetworkClientSink + NetworkServerSource (Float32)", function ()
        local src_fd = buffer.open(test_vector_float)
        local snk_fd = buffer.open()

        local top_client = radio.CompositeBlock():connect(
            radio.RealFileSource(src_fd, 'f32le', 1000000),
            radio.NetworkClientSink('f32le', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_server = radio.CompositeBlock():connect(
            radio.NetworkServerSource(radio.types.Float32, 1000000, 'f32le', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.RealFileSink(snk_fd, 'f32le')
        )

        top_server:start()
        top_client:start()

        top_server:wait()
        top_client:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_float*2)
        assert.is_true(buf == test_vector_float)
    end)
    it("NetworkClientSink + NetworkServerSource (CStructType)", function ()
        local src_fd = buffer.open(test_vector_cstruct)
        local snk_fd = buffer.open()

        local top_client = radio.CompositeBlock():connect(
            radio.RawFileSource(src_fd, MyCStructType, 1000000),
            radio.NetworkClientSink('raw', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_server = radio.CompositeBlock():connect(
            radio.NetworkServerSource(MyCStructType, 1000000, 'raw', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.RawFileSink(snk_fd)
        )

        top_server:start()
        top_client:start()

        top_server:wait()
        top_client:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_cstruct*2)
        assert.is_true(buf == test_vector_cstruct)
    end)
    it("NetworkClientSink + NetworkServerSource (ObjectType)", function ()
        local src_fd = buffer.open(test_vector_object)
        local snk_fd = buffer.open()

        local top_client = radio.CompositeBlock():connect(
            radio.JSONSource(src_fd, MyObjectType, 1000000),
            radio.NetworkClientSink('json', 'unix', '/tmp/radio.sock', {backpressure = true})
        )
        local top_server = radio.CompositeBlock():connect(
            radio.NetworkServerSource(MyObjectType, 1000000, 'json', 'unix', '/tmp/radio.sock', {reconnect = false}),
            radio.JSONSink(snk_fd)
        )

        top_server:start()
        top_client:start()

        top_server:wait()
        top_client:wait()

        buffer.rewind(snk_fd)
        local buf = buffer.read(snk_fd, #test_vector_object*2)
        assert.is_true(buf == test_vector_object)
    end)
end)
