local string = require('string')
local types = require('types')
local pipe = require('pipe')

local callable_mt = {__call = function(self, ...) return self.new(...) end}

-- Pipeline class
local Pipeline = setmetatable({}, callable_mt)
Pipeline.__index = Pipeline

function Pipeline.new(name)
    local self = setmetatable({}, Pipeline)
    self.name = name
    self.blocks = {}
    self.connected = {}
    self.unconnected = {}
    return self
end

function lookup_pipe_by_name(pipes, name)
    for _, pipe in pairs(pipes) do
        if pipe.name == name then
            return pipe
        end
    end

    return nil
end

function Pipeline:connect(src, pipeout, dst, pipein)
    -- Look up pipe objects
    src_pipe_output = assert(lookup_pipe_by_name(src.outputs, pipeout), "Output pipe not found.")
    dst_pipe_input = assert(lookup_pipe_by_name(dst.inputs, pipein), "Input pipe not found.")

    -- Assert types match
    if dst_pipe_input.data_type ~= types.AnyType then
        assert(dst_pipe_input.data_type == src_pipe_output.data_type, "Input-output pipe type mismatch.")
    end

    -- Assert input is not already connected
    assert(not self.connected[dst_pipe_input], "Input already connected.")

    -- Add the blocks to our book-keeping
    for _, b in pairs({src, dst}) do
        if not self.blocks[b] then
            self.blocks[b] = true

            for _, input in pairs(b.inputs) do
                self.unconnected[input] = b
            end
        end
    end

    -- Create a pipe from output to input
    local p = pipe.InternalPipe(src, dst)
    src_pipe_output.pipes[#src_pipe_output.pipes+1] = p
    dst_pipe_input.pipe = p
    self.connected[dst_pipe_input] = src_pipe_output
    self.unconnected[dst_pipe_input] = nil

    print("Connected", src.name, "output", pipeout, "and", dst.name, "input", pipein)
end

function Pipeline:run()
    -- Initialize all blocks
    for block, _ in pairs(self.blocks) do
        block:initialize()
    end

    -- Determine our sources
    local sources = {}
    for block, _ in pairs(self.blocks) do
        if #block.inputs == 0 then
            sources[#sources+1] = block
        end
    end

    while true do
        -- Start with the sources
        local activation = sources

        -- While there are blocks to run
        while #activation > 0 do
            local next_activation = {}

            -- For each block
            for _, block in pairs(activation) do
                -- Read inputs from pipes
                local data_in = {}
                for i=1, #block.inputs do
                    data_in[#data_in+1] = block.inputs[i].pipe:read()
                end

                -- Run the block
                --print("Running block", block.name)
                local data_out = {block:process(unpack(data_in))}

                -- Write outputs to pipes
                for i=1, #block.outputs do
                    for j=1, #block.outputs[i].pipes do
                        block.outputs[i].pipes[j]:write(data_out[i])
                        -- FIXME copy for j > 1
                    end
                end

                local visited = {}

                -- For each block output
                for i=1, #block.outputs do
                    for j=1, #block.outputs[i].pipes do
                        -- Look up the destination block
                        local dblock = block.outputs[i].pipes[j].dst

                        -- If we haven't visited this block
                        if not visited[dblock] then
                            -- Check if all input pipes have data
                            local activated = true
                            for k=1, #dblock.inputs do
                                if not dblock.inputs[k].pipe:has_data() then
                                    activated = false
                                    break
                                end
                            end

                            -- Mark the block in our next activation list
                            if activated then
                                next_activation[#next_activation + 1] = dblock
                            end
                            visited[dblock] = true
                        end
                    end
                end
            end

            activation = next_activation
        end
    end
end

-- Exported module
return {Pipeline = Pipeline}
