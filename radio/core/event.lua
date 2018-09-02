local class = require('radio.core.class')
local ffi = require('ffi')

ffi.cdef[[
typedef struct {
    uint32_t value;
} event_t;
]]

ffi.cdef[[
void *mmap(void *addr, size_t len, int prot, int flags, int fildes, long int off);
int munmap(void *addr, size_t len);

enum { PROT_READ = 0x1, PROT_WRITE = 0x2 };
enum { MAP_SHARED = 0x1, MAP_ANONYMOUS = 0x20 };
]]

local Event = class.factory()

function Event.new(value)
    -- FIXME need atomic qualifier
    local event = ffi.C.mmap(nil, ffi.sizeof("event_t"), bit.bor(ffi.C.PROT_READ, ffi.C.PROT_WRITE), bit.bor(ffi.C.MAP_SHARED, ffi.C.MAP_ANONYMOUS), -1, 0)
    event = ffi.gc(ffi.cast("event_t *", self.event), Event._free)
    event.value = value or 0
    return event
end

function Event:get()
    return self.value == 1
end

function Event:set(value)
    self.value = value
end

function Event:_free()
    if ffi.C.munmap(self, ffi.sizeof("event_t")) ~= 0 then
        error("munmap(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

Event = ffi.metatype("event_t", Event)

return {Event = Event}
