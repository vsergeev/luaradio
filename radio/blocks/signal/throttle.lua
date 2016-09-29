---
-- Throttle a signal to limit CPU usage and pace plotting sinks.
--
-- $$ y[n] = x[n] $$
--
-- @category Miscellaneous
-- @block ThrottleBlock
--
-- @signature in:any > out:copy
--
-- @usage
-- local throttle = radio.ThrottleBlock()
-- top:connect(src, throttle, snk)

local ffi = require('ffi')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local types = require('radio.types')

local ThrottleBlock = block.factory("ThrottleBlock")

function ThrottleBlock:instantiate()
    -- Add a dummy type signature
    self:add_type_signature({block.Input("in", nil)}, {block.Output("out", nil)})
end

function ThrottleBlock:differentiate(input_data_types)
    -- Absorb data type into dummy type signature
    self.signatures[1].inputs[1].data_type = input_data_types[1]
    self.signatures[1].outputs[1].data_type = input_data_types[1]

    block.Block.differentiate(self, input_data_types)
end

function ThrottleBlock:initialize()
    -- Target 1% above sample rate
    self.target_rate = 1.01*self:get_rate()
    self.chunk_size = 1024
    self.sleep_time = self.chunk_size/self.target_rate

    -- Adjust chunk size and sleep time for 5us minimum sleep
    if self.sleep_time < 5e-6 then
        self.chunk_size = self.chunk_size * math.ceil(5e-6/self.sleep_time)
        self.sleep_time = 5e-6
    end

    self.data_out = self:get_input_type().vector(self.chunk_size)
end

ffi.cdef[[
    int usleep(unsigned int usec);
]]

local function time_us()
    local tp = ffi.new("struct timespec")
    if ffi.C.clock_gettime(ffi.C.CLOCK_REALTIME, tp) ~= 0 then
        error("clock_gettime(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    return tonumber(tp.tv_sec) + (tonumber(tp.tv_nsec) / 1e9)
end

function ThrottleBlock:run()
    local data_in_offset = 0
    local data_out_offset = 0

    while true do
        -- Read input vector
        local data_in = self.inputs[1].pipe:read()
        if data_in == nil then
            break
        end
        data_in_offset = 0

        -- Write throttled input vector
        local tic = time_us()
        while data_in_offset < data_in.length do
            -- Shift from data_in to data_out vector
            local shift_length = math.min(self.chunk_size - data_out_offset, data_in.length - data_in_offset)
            ffi.C.memcpy(self.data_out.data + data_out_offset, data_in.data + data_in_offset, shift_length*ffi.sizeof(self.data_out.data[0]))
            data_out_offset = data_out_offset + shift_length
            data_in_offset = data_in_offset + shift_length

            -- If we've filled our data_out vector up to chunk size, emit it
            if data_out_offset == self.chunk_size then
                -- Write output to pipes
                for j=1, #self.outputs[1].pipes do
                    self.outputs[1].pipes[j]:write(self.data_out)
                end

                -- Sleep for this batch of samples
                ffi.C.usleep(math.floor(self.sleep_time*1e6))

                data_out_offset = 0
            end
        end
        local toc = time_us()

        -- Adjust sleep time based on actual rate
        local actual_rate = (data_in.length - data_out_offset)/(toc - tic)
        debug.printf("[ThrottleBlock] Target rate: %.2f   Actual Rate: %.2f   Error: %.2f   Sleep time: %g\n", self.target_rate, actual_rate, self.target_rate - actual_rate, self.sleep_time)
        self.sleep_time = self.sleep_time - 1*(1/self.target_rate - 1/actual_rate)
        self.sleep_time = math.max(self.sleep_time, 0)
    end
end

return ThrottleBlock
