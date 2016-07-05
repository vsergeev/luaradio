local radio = require('radio')
local async = require('radio.core.async')
local buffer = require('tests.buffer')

local ffi = require('ffi')

describe("async callbacks", function ()
    it("valid callback", function ()
        -- Return function pointer
        local function callback_factory()
            local ffi = require('ffi')
            return ffi.cast('void (*)()', 1234)
        end

        local callback, callback_state = async.callback(callback_factory)
        assert.is_true(ffi.istype("void *", callback))
        assert.is_true(ffi.istype("lua_State *", callback_state))
    end)

    it("invalid callback", function ()
        -- Return nil for function pointer
        local function callback_factory()
            return nil
        end

        assert.has_error(function () async.callback(callback_factory) end)
    end)

    it("callback arguments", function ()
        -- Validate arguments inside callback
        local function callback_factory(a, b, c, d)
            local ffi = require('ffi')

            assert(type(a) == "number" and a == 1)
            assert(type(b) == "boolean" and b == true)
            assert(type(c) == "nil" and c == nil)
            assert(type(d) == "string" and d == "test")

            return ffi.cast("void *", nil)
        end

        -- No arguments
        assert.has_error(function () async.callback(callback_factory) end)

        -- Unsupported arguments
        assert.has_error(function () async.callback(callback_factory, 1, true, nil, "test", {}) end)

        -- Incorrect arguments
        assert.has_error(function () async.callback(callback_factory, 1, 1, 1, 1) end)

        -- Correct arguments
        local callback, callback_state = async.callback(callback_factory, 1, true, nil, "test")
        assert.is_true(ffi.istype("void *", callback))
        assert.is_true(ffi.istype("lua_State *", callback_state))
    end)

    it("signal handler callback", function ()
        -- Return function pointer
        local function callback_factory(fd)
            local ffi = require('ffi')
            local buffer = require('tests.buffer')

            local function callback(sig)
                buffer.write(fd, "test")
            end

            return ffi.cast('void (*)(int)', callback)
        end

        -- Create buffer
        local fd = buffer.open()

        -- Wrap callback
        local callback, callback_state = async.callback(callback_factory, fd)

        -- Register signal handler
        ffi.C.signal(ffi.C.SIGALRM, callback)

        -- Trigger alarm
        ffi.C.kill(ffi.C.getpid(), ffi.C.SIGALRM)

        -- Check buffer
        buffer.rewind(fd)
        assert.is.equal(buffer.read(fd, 100), "test")
    end)
end)
