local ffi = require('ffi')

function class_factory(cls)
    cls = cls or {__call = function(self, ...) return self.new(...) end}

    local dcls = setmetatable({}, cls)
    dcls.__index = dcls

    -- "Inherit" metamethods and cache other methods
    for k, v in pairs(cls) do
        if k ~= "__index" and type(v) == "function" then
            dcls[k] = v
        end
    end

    return dcls
end

function isinstanceof(o, cls)
    -- Handle FFI objects and types
    if rawequal(getmetatable(o), "ffi") then
        if rawequal(getmetatable(cls), "ffi") then
            return ffi.istype(cls, o)
        else
            return rawequal(o.__index, cls) or isinstanceof(o.__index, cls)
        end
    end

    -- Base case, after ascending all parents
    if rawequal(o, nil) then
        return false
    end

    return rawequal(getmetatable(o), cls) or isinstanceof(getmetatable(o), cls)
end

ffi.cdef[[
    void *calloc(size_t nmemb, size_t size);
    void free(void *ptr);
]]

function vector_alloc(ffi_type, n)
    local data = ffi.cast(ffi.typeof("$ *", ffi_type), ffi.gc(ffi.C.calloc(n, ffi.sizeof(ffi_type)), ffi.C.free))
    return {data = data, length = n, raw_length = n*ffi.sizeof(ffi_type)}
end

function vector_alloc_factory(ffi_type)
    local ctype = ffi.typeof("$ *", ffi_type)
    local sz = ffi.sizeof(ffi_type)
    return function (n)
        local data = ffi.cast(ctype, ffi.gc(ffi.C.calloc(n, sz), ffi.C.free))
        return {data = data, length = n, raw_length = n*sz}
    end
end
