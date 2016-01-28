local ffi = require('ffi')

local function class_factory(cls)
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

local function isinstanceof(o, cls)
    return (o._types and o._types[cls]) and true or false
end

return {class_factory = class_factory, isinstanceof = isinstanceof}
