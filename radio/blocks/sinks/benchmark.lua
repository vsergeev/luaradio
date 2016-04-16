local ffi = require('ffi')
local json = require('radio.thirdparty.json')

local block = require('radio.core.block')

local BenchmarkSink = block.factory("BenchmarkSink")

function BenchmarkSink:instantiate(fd)
    self.fd = fd

    -- Accept all input types
    self:add_type_signature({block.Input("in", function (t) return true end)}, {})
end

ffi.cdef[[
    enum { CLOCK_REALTIME = 0 };
    typedef long int time_t;
    typedef int clockid_t;

    struct timespec {
        time_t tv_sec;
        long tv_nsec;
    };
    int clock_gettime(clockid_t clk_id, struct timespec *tp);
]]

local function time_us()
    local tp = ffi.new("struct timespec")
    if ffi.C.clock_gettime(ffi.C.CLOCK_REALTIME, tp) ~= 0 then
        error("clock_gettime(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    return tonumber(tp.tv_sec) + (tonumber(tp.tv_nsec) / 1e9)
end

function BenchmarkSink:initialize()
    self.count = 0
    self.toc = nil
    self.tic = time_us()
end

function BenchmarkSink:process(x)
    self.count = self.count + x.length
end

function BenchmarkSink:cleanup()
    self.toc = time_us()

    -- Calculate throughput
    local samples_per_second = self.count / (self.toc - self.tic)
    local bytes_per_second = ffi.sizeof(self:get_input_types()[1]) * samples_per_second

    -- Serialize results to fd
    local results_json = json.encode({samples_per_second = samples_per_second, bytes_per_second = bytes_per_second})
    if ffi.C.write(self.fd, results_json, #results_json) ~= #results_json then
        error("write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

return {BenchmarkSink = BenchmarkSink}
