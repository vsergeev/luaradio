local ffi = require('ffi')
local json = require('radio.thirdparty.json')

local block = require('radio.core.block')

local BenchmarkSink = block.factory("BenchmarkSink")

function BenchmarkSink:instantiate(file)
    if type(file) == "number" then
        self.fd = file
    elseif type(file) == "string" then
        self.filename = file
    elseif file == nil then
        -- Default to io.stdout
        self.file = io.stdout
    end

    -- Accept all input types
    self:add_type_signature({block.Input("in", function (t) return true end)}, {})
end

-- Clock
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

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fclose(FILE *stream);
    int fflush(FILE *stream);
]]

function BenchmarkSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "w")
        if self.file == nil then
            error("fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif self.fd then
        self.file = ffi.C.fdopen(self.fd, "w")
        if self.file == nil then
            error("fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Register open file
    self.files[self.file] = true

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
    local bytes_per_second = ffi.sizeof(self:get_input_type()) * samples_per_second

    -- Serialize results to file
    local results_json = json.encode({samples_per_second = samples_per_second, bytes_per_second = bytes_per_second})
    if ffi.C.fwrite(results_json, 1, #results_json, self.file) ~= #results_json then
        error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Close or flush file
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif self.fd then
        if ffi.C.fflush(self.file) ~= 0 then
            error("fflush(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    else
        self.file:flush()
    end
end

return BenchmarkSink
