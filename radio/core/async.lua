---
-- Asynchronous callback shim.
--
-- @module radio.core.async

local ffi = require('ffi')

-- Lua C API
ffi.cdef[[
    typedef double lua_Number;
    typedef void lua_State;
    typedef int (*lua_CFunction)(lua_State *L);

    lua_State *luaL_newstate(void);
    void lua_close(lua_State *L);
    void luaL_openlibs(lua_State *L);

    int luaL_loadbuffer(lua_State *L, const char *buff, size_t sz, const char *name);
    const char *lua_tolstring(lua_State *L, int index, size_t *len);

    void lua_pushnumber(lua_State *L, lua_Number n);
    void lua_pushlstring(lua_State *L, const char *s, size_t len);
    void lua_pushboolean(lua_State *L, int b);
    void lua_pushnil(lua_State *L);

    int lua_pcall(lua_State *L, int nargs, int nresults, int errfunc);
    const void *lua_topointer(lua_State *L, int index);
    void lua_settop(lua_State *L, int index);
]]

---
-- Wrap a callback for asynchronous calling. This function creates a callback
-- in a new Lua state and returns its function pointer, which can be safely
-- called asynchronously, e.g. from another thread or as a signal handler.
--
-- @function callback
-- @tparam function callback_factory Factory function that creates a callback
--                                   and return its function pointer
-- @param ... Arguments to factory function, can only be primitive types
--            number, string, boolean, and nil
-- @treturn pointer Function pointer of callback
-- @treturn pointer Lua state that owns callback
--
-- @usage
-- local function callback_factory(foo)
--     local ffi = require('ffi')
--
--     local function callback(sig)
--         print(foo, sig)
--     end
--
--     return ffi.cast('void (*)(int)', callback)
-- end
--
-- ffi.cdef[[
--     sighandler_t signal(int signum, void (*handler)(int));
--     unsigned int alarm(unsigned int seconds);
--     unsigned int sleep(unsigned int seconds);
-- ]]
--
-- local async = require('radio.core.async')
-- local callback, callback_state = radio.async.callback(callback_factory, 123)
-- ffi.C.signal(ffi.C.SIGALRM, callback)
--
-- ffi.C.alarm(5)
-- while true do
--     print('bar')
--     ffi.C.sleep(1)
-- end
function callback(callback_factory, ...)
    -- Create a new Lua state
    local L = ffi.gc(ffi.C.luaL_newstate(), ffi.C.lua_close)
    if L == nil then
        error("luaL_newstate(): Allocating Lua state.")
    end

    -- Open standard libraries in the Lua state
    ffi.C.luaL_openlibs(L)

    -- Load the callback factory bytecode into the Lua state
    local bytecode = string.dump(callback_factory)
    if ffi.C.luaL_loadbuffer(L, bytecode, #bytecode, nil) ~= 0 then
        error("luaL_loadbuffer(): " .. ffi.string(ffi.C.lua_tolstring(L, -1, nil)))
    end

    -- Push arguments into the Lua state
    local args, num_args = {...}, select("#", ...)
    for i = 1, num_args do
        if type(args[i]) == "number" then
            ffi.C.lua_pushnumber(L, args[i])
        elseif type(args[i]) == "string" then
            ffi.C.lua_pushlstring(L, args[i], #args[i])
        elseif type(args[i]) == "boolean" then
            ffi.C.lua_pushboolean(L, args[i])
        elseif type(args[i]) == "nil" then
            ffi.C.lua_pushnil(L)
        else
            error(string.format("Unsupported argument type \"%s\" (index %d).", type(args[i]), i))
        end
    end

    -- Call the callback factory inside the Lua state
    if ffi.C.lua_pcall(L, num_args, 1, 0) ~= 0 then
        error("lua_pcall(): " .. ffi.string(ffi.C.lua_tolstring(L, -1, nil)))
    end

    -- Pop the returned callback function pointer
    local callback_ptrptr = ffi.C.lua_topointer(L, -1)
    if callback_ptrptr == nil then
        error("Callback factory did not return a function pointer.")
    end
    local callback_ptr = ffi.cast('void **', callback_ptrptr)[0]

    -- Clear the Lua state stack
    ffi.C.lua_settop(L, -1)

    -- Return the callback function pointer and Lua state
    return callback_ptr, L
end

return {callback = callback}
