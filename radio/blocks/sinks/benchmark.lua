local ffi = require('ffi')
local json = require('radio.thirdparty.json')

local block = require('radio.core.block')

local BenchmarkSink = block.factory("BenchmarkSink")

function BenchmarkSink:instantiate(file, use_json)
    if type(file) == "number" then
        self.fd = file
    elseif type(file) == "string" then
        self.filename = file
    elseif file == nil then
        -- Default to stderr
        self.file = io.stderr
    end

    self.use_json = use_json or false
    self.report_period = 3.0

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

local function normalize(amount)
    if amount > 1e9 then
        return amount/1e9, "G"
    elseif amount > 1e6 then
        return amount/1e6, "M"
    elseif amount > 1e3 then
        return amount/1e3, "K"
    else
        return amount, ""
    end
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
    self.tic = time_us()
end

function BenchmarkSink:process(x)
    self.count = self.count + x.length

    if not self.use_json then
        local toc = time_us()

        if (toc - self.tic) > self.report_period then
            -- Compute rate
            local samples_per_second = self.count / (toc - self.tic)
            local bytes_per_second = ffi.sizeof(self:get_input_type()) * samples_per_second

            -- Normalize rate with unit prefix
            local sps, sps_prefix = normalize(samples_per_second)
            local bps, bps_prefix = normalize(bytes_per_second)

            -- Form report string
            local s = string.format("[BenchmarkSink] %.2f %sS/s (%.2f %sB/s)\n", sps, sps_prefix, bps, bps_prefix)

            -- Write to file
            if ffi.C.fwrite(s, 1, #s, self.file) ~= #s then
                error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end

            -- Flush file
            if ffi.C.fflush(self.file) ~= 0 then
                error("fflush(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end

            -- Reset tic and count
            self.tic = toc
            self.count = 0
        end
    end
end

function BenchmarkSink:cleanup()
    if self.use_json then
        local toc = time_us()

        -- Calculate throughput
        local samples_per_second = self.count / (toc - self.tic)
        local bytes_per_second = ffi.sizeof(self:get_input_type()) * samples_per_second

        -- Serialize aggregate rate results to file
        local results_json = json.encode({samples_per_second = samples_per_second, bytes_per_second = bytes_per_second})
        if ffi.C.fwrite(results_json, 1, #results_json, self.file) ~= #results_json then
            error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
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
