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
local class = require('radio.core.class')
local pipe = require('radio.core.pipe')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')

local ThrottleBlock = block.factory("ThrottleBlock")

function ThrottleBlock:instantiate()
    self:add_type_signature({block.Input("in", function (type) return class.isinstanceof(type, types.CStructType) end)}, {block.Output("out", "copy")})
end

function ThrottleBlock:initialize()
    self.target_rate = self:get_rate()
    self.chunk_size = 16384
    self.sleep_time = self.chunk_size/self.target_rate

    self.adjust_period = 10*self.sleep_time
    self.adjust_gain = 1000
    self.max_chunk_size = 262144
    self.min_sleep_time = 25e-6
end

function ThrottleBlock:run()
    local samples_written = 0
    local tic = platform.time_us()

    -- Gather input pipes
    local input_pipes = {self.inputs[1].pipe}

    -- Gather output pipes
    local output_pipes = {}
    for i=1, #self.outputs do
        output_pipes[i] = {}
        for j=1, #self.outputs[i].pipes do
            output_pipes[i][j] = self.outputs[i].pipes[j]
        end
    end

    -- Create pipe mux
    local pipe_mux = pipe.PipeMux(input_pipes, output_pipes, self.control_socket)

    while true do
        -- Read input up to chunk size
        local data_in, eof, shutdown = pipe_mux:read(self.chunk_size)

        -- Check for upstream EOF or control socket shutdown
        if eof or shutdown then
            break
        end

        -- Write outputs
        local eof, eof_pipe, shutdown = pipe_mux:write(data_in)

        -- Check for downstream EOF or control socket shutdown
        if shutdown then
            break
        elseif eof then
            io.stderr:write(string.format("[%s] Downstream block %s terminated unexpectedly.\n", self.name, eof_pipe.input.owner.name))
            break
        end

        -- Sleep for this batch of samples
        ffi.C.usleep(math.floor(self.sleep_time*1e6))

        -- Update samples written
        samples_written = samples_written + data_in[1].length

        local toc = platform.time_us()

        if (toc - tic) > self.adjust_period then
            -- Calculate actual rate
            local actual_rate = samples_written/(toc - tic)

            debug.printf("[ThrottleBlock] Target rate: %.2f | Actual Rate: %.2f | Error: %.2f | Sleep time: %g | Chunk Size: %u\n", self.target_rate, actual_rate, self.target_rate - actual_rate, self.sleep_time, self.chunk_size)

            -- Adjust sleep time
            self.sleep_time = self.sleep_time + self.adjust_gain*(1/self.target_rate - 1/actual_rate)
            self.sleep_time = math.max(0, self.sleep_time)

            -- Double chunk size and sleep time if sleep time falls below min sleep time
            if self.sleep_time < self.min_sleep_time and self.chunk_size < self.max_chunk_size then
                self.chunk_size = 2 * self.chunk_size
                self.sleep_time = 2 * self.sleep_time
            end

            samples_written = 0
            tic = toc
        end
    end
end

return ThrottleBlock
