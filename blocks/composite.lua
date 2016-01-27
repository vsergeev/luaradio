local object = require('object')

local string = require('string')
local pipe = require('pipe')
local block = require('block')

local CompositeBlock = block.BlockFactory("CompositeBlock")

function CompositeBlock:instantiate(multiprocess)
    self._multiprocess = multiprocess
    self._blocks = {}
    self._connections = {}
    self._unconnected_inputs = {}
    self._unconnected_outputs = {}
end

function table_length(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

function lookup_pipe_by_name(pipes, name)
    for _, pipe in pairs(pipes) do
        if pipe.name == name then
            return pipe
        end
    end

    return nil
end

function build_dependency_graph(blocks, connections)
    local graph = {}

    -- Add dependency-free sources
    for block, _ in pairs(blocks) do
        if #block.inputs == 0 then
            graph[block] = {}
        end
    end

    -- Add dependencies between connected blocks
    for pipe_input, pipe_output in pairs(connections) do
        local src = pipe_output.owner
        local dst = pipe_input.owner

        if graph[dst] == nil then
            graph[dst] = {src}
        else
            graph[dst][#graph[dst] + 1] = src
        end
    end

    return graph
end

function build_execution_order(dependency_graph)
    local order = {}

    -- Copy dependency graph and count the number of blocks
    local graph_copy = {}
    local count = 0
    for k, v in pairs(dependency_graph) do
        graph_copy[k] = v
        count = count + 1
    end

    -- Helper function that returns boolean for existence of an element in an
    -- array
    function exists(array, elem)
        for _, k in pairs(array) do
            if k == elem then
                return true
            end
        end
        return false
    end

    while #order < count do
        for block, deps in pairs(graph_copy) do
            local deps_met = true

            -- Check if dependencies exists in order list
            for _, dep in pairs(deps) do
                if not exists(order, dep) then
                    deps_met = false
                    break
                end
            end

            -- If dependencies are met
            if deps_met then
                -- Add block next to the execution order
                order[#order + 1] = block
                -- Remove the entry from the graph
                graph_copy[block] = nil

                break
            end
        end
    end

    return order
end

function CompositeBlock:connect(src, output_name, dst, input_name)
    -- Look up pipe objects
    local pipe_output = assert(lookup_pipe_by_name(src.outputs, output_name), "Output pipe not found.")
    local pipe_input = assert(lookup_pipe_by_name(dst.inputs, input_name), "Input pipe not found.")

    -- Assert types match
    --assert(object.isinstanceof(pipe_output.data_type, pipe_input.data_type) or object.isinstanceof(pipe_input.data_type, pipe_output.data_type), "Input-output pipe data type mismatch.")

    -- Assert input is not already connected
    assert(not self._connections[dst_pipe_input], "Input already connected.")

    -- If this is our first time seeing either of these blocks, add them to our
    -- book-keeping data structures
    for _, block in pairs({src, dst}) do
        if not self._blocks[block] then
            self._blocks[block] = true

            for _, input in pairs(block.inputs) do
                self._unconnected_inputs[input] = true
            end
            for _, output in pairs(block.outputs) do
                self._unconnected_outputs[output] = true
            end
        end
    end

    -- Create a pipe from output to input
    if self._multiprocess then
        local p = pipe.ProcessPipe(pipe_output, pipe_input)
    else
        local p = pipe.InternalPipe(pipe_output, pipe_input)
    end

    -- Update book-keeping
    self._connections[pipe_input] = pipe_output
    self._unconnected_inputs[pipe_input] = nil
    self._unconnected_outputs[pipe_output] = nil

    print(string.format("Connected source %s.%s to destination %s.%s", src.name, output_name, dst.name, input_name))
end

function CompositeBlock:_prepare_to_run()
    -- Check all inputs are connected
    assert(table_length(self._unconnected_inputs) == 0, "Unconnected inputs exist.")

    -- Initialize all blocks
    for block, _ in pairs(self._blocks) do
        block:initialize()
    end

    -- Build dependency graph
    local dependency_graph = build_dependency_graph(self._blocks, self._connections)

    -- Build execution order
    self._execution_order = build_execution_order(dependency_graph)

    print("Running in order:")
    for _, k in ipairs(self._execution_order) do
        print("\t" .. tostring(k) .. " " .. k.name)
    end
end

function CompositeBlock:run_once()
    -- Prepare to run
    if not self._execution_order then
        self:_prepare_tor_run()
    end

    -- Run blocks once
    for _, block in ipairs(self._execution_order) do
        block:run_once()
    end
end

local ffi = require('ffi')

ffi.cdef[[
    typedef int pid_t;
    pid_t fork(void);
    pid_t waitpid(pid_t pid, int *status, int options);
]]

function CompositeBlock:run()
    -- Prepare to run
    if not self._execution_order then
        self:_prepare_to_run()
    end

    if not self._multiprocess then
        -- Run blocks single-threaded
        while true do
            for _, block in ipairs(self._execution_order) do
                block:run_once()
            end
        end
    else
        local pids = {}

        -- Fork and run blocks
        for _, block in ipairs(self._execution_order) do
            local pid = ffi.C.fork()
            if pid == 0 then
                block:run()
            else
                pids[#pids + 1] = pid
            end
        end

        -- Wait for pids
        for _, pid in pairs(pids) do
            ffi.C.waitpid(pid, nil, 0)
        end
    end
end

return {CompositeBlock = CompositeBlock}
