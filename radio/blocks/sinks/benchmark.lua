---
-- Report the average rate of samples delivered to the sink.
--
-- ```
-- [BenchmarkSink] 314.38 MS/s (2.52 GB/s)
-- [BenchmarkSink] 313.32 MS/s (2.51 GB/s)
-- [BenchmarkSink] 313.83 MS/s (2.51 GB/s)
-- ...
-- ```
--
-- @category Sinks
-- @block BenchmarkSink
-- @tparam[opt=io.stderr] string|file|int file Filename, file object, or file descriptor
-- @tparam[opt=false] bool use_json Serialize aggregate results in JSON on termination
-- @tparam[opt="BenchmarkSink"] string title Title in reporting
--
-- @signature in:any >
--
-- @usage
-- -- Benchmark a source, writing periodic results to stderr
-- local snk = radio.BenchmarkSink()
-- top:connect(src, snk)
--
-- -- Benchmark a source and a block, writing final results in JSON to fd 3
-- local snk = radio.BenchmarkSink(3, true)
-- top:connect(src, blk, snk)

local ffi = require('ffi')
local json = require('radio.thirdparty.json')

local block = require('radio.core.block')
local platform = require('radio.core.platform')

local BenchmarkSink = block.factory("BenchmarkSink")

function BenchmarkSink:instantiate(file, use_json, title)
    if type(file) == "number" then
        self.fd = file
    elseif type(file) == "string" then
        self.filename = file
    elseif type(file) == "userdata" then
        self.file = file
    elseif file == nil then
        -- Default to stderr
        self.file = io.stderr
    end

    self.use_json = use_json or false
    self.title = title or "BenchmarkSink"
    self.report_period = 3.0

    -- Accept all input types
    self:add_type_signature({block.Input("in", function (t) return true end)}, {})
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
    self.tic = platform.time_us()
end

function BenchmarkSink:process(x)
    self.count = self.count + x.length

    if not self.use_json then
        local toc = platform.time_us()

        if (toc - self.tic) > self.report_period then
            -- Compute rate
            local samples_per_second = self.count / (toc - self.tic)
            local bytes_per_second = ffi.sizeof(self:get_input_type()) * samples_per_second

            -- Normalize rate with unit prefix
            local sps, sps_prefix = normalize(samples_per_second)
            local bps, bps_prefix = normalize(bytes_per_second)

            -- Form report string
            local s = string.format("[%s] %.2f %sS/s (%.2f %sB/s)\n", self.title, sps, sps_prefix, bps, bps_prefix)

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
        local toc = platform.time_us()

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
