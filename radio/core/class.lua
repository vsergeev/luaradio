---
-- Object oriented class creation and instance testing.
--
-- @module radio.class

local ffi = require('ffi')

---
-- Create a new class, optionally inheriting from an existing one.
--
-- This factory attaches a __call metamethod to the class, which wraps the
-- .new() static method, so the class can be instantiated by calling its name.
--
-- @internal
-- @function factory
-- @tparam[opt=nil] class Class to inherit
-- @treturn class Class
local function factory(cls)
    cls = cls or {__call = function(self, ...) return self.new(...) end, _types = {}}

    local dcls = setmetatable({}, cls)
    dcls.__index = dcls

    -- "Inherit" metamethods and cache other methods
    for k, v in pairs(cls) do
        if k ~= "__index" and type(v) == "function" then
            dcls[k] = v
        end
    end

    -- Inherit and update types
    dcls._types = {}
    for k, v in pairs(cls._types) do
        dcls._types[k] = v
    end
    dcls._types[dcls] = true

    return dcls
end

---
-- Test if an object is an instance of the specified class.
--
-- @internal
-- @function isinstanceof
-- @param obj Object
-- @tparam class|cdata|string Class, ctype, or type string
-- @treturn bool Result
local function isinstanceof(obj, cls)
    if type(cls) == "string" then
        return type(obj) == cls
    elseif type(cls) == "table" then
        return ((type(obj) == "cdata" or type(obj) == "table") and obj._types and obj._types[cls]) and true or false
    elseif type(cls) == "cdata" then
        return (type(obj) == "cdata" and obj._types and obj._types[cls.__index]) and true or false
    end
    return false
end

return {factory = factory, isinstanceof = isinstanceof}
