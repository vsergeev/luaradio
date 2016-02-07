local ffi = require('ffi')
local string = require('string')
local io = require('io')

local block = require('radio.core.block')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

local CompositeBlock = block.factory("CompositeBlock")

function CompositeBlock:instantiate(multiprocess)
    self._multiprocess = multiprocess
    self._connections = {}
end

local function build_dependency_graph(connections)
    local graph = {}

    -- Add dependencies between connected blocks
    for pipe_input, pipe_output in pairs(connections) do
        local src = pipe_output.owner
        local dst = pipe_input.owner

        if graph[src] == nil then
            graph[src] = {}
        end

        if graph[dst] == nil then
            graph[dst] = {src}
        else
            graph[dst][#graph[dst] + 1] = src
        end
    end

    return graph
end

local function build_execution_order(dependency_graph)
    local order = {}

    -- Copy dependency graph and count the number of blocks
    local graph_copy = {}
    local count = 0
    for k, v in pairs(dependency_graph) do
        graph_copy[k] = v
        count = count + 1
    end

    -- While we still have blocks left to add to our order
    while #order < count do
        for block, deps in pairs(graph_copy) do
            local deps_met = true

            -- Check if dependencies exists in order list
            for _, dep in pairs(deps) do
                if not util.array_exists(order, dep) then
                    deps_met = false
                    break
                end
            end

            -- If dependencies are met
            if deps_met then
                -- Add block next to the execution order
                order[#order + 1] = block
                -- Remove the block from the dependency graph
                graph_copy[block] = nil

                break
            end
        end
    end

    return order
end

function CompositeBlock:connect(src, output_name, dst, input_name)
    -- Look up pipe objects
    local pipe_output = util.array_search(src.outputs, function (p) return p.name == output_name end)
    local pipe_input = util.array_search(dst.inputs, function (p) return p.name == input_name end)
    assert(pipe_output, string.format("Output pipe \"%s\" of block \"%s\" not found.", output_name, src.name))
    assert(pipe_input, string.format("Input pipe \"%s\" of block \"%s\" not found.", input_name, dst.name))

    -- Assert input is not already connected
    assert(not self._connections[dst_pipe_input], "Input already connected.")

    -- Create a pipe from output to input
    local p = self._multiprocess and pipe.ProcessPipe(pipe_output, pipe_input) or pipe.InternalPipe(pipe_output, pipe_input)
    -- Link the pipe to the input and output ends
    pipe_output.pipes[#pipe_output.pipes+1] = p
    pipe_input.pipe = p

    -- Update our connections table
    self._connections[pipe_input] = pipe_output

    io.stderr:write(string.format("Connected source %s.%s to destination %s.%s\n", src.name, output_name, dst.name, input_name))
end

function CompositeBlock:_prepare_to_run()
    local blocks = {}

    -- Build list of blocks
    for input, output in pairs(self._connections) do
        blocks[input.owner] = true
        blocks[output.owner] = true
    end

    -- Check all inputs are connected
    for block, _ in pairs(blocks) do
        for i=1, #block.inputs do
            assert(block.inputs[i].pipe ~= nil, string.format("Block \"%s\" input \"%s\" is unconnected.", block.name, block.inputs[i].name))
        end
    end

    -- Build dependency graph and execution order
    self._execution_order = build_execution_order(build_dependency_graph(self._connections))

    -- Differentiate all blocks
    for _, block in ipairs(self._execution_order) do
        -- Gather input data types to this block
        local input_data_types = {}
        for _, input in ipairs(block.inputs) do
            input_data_types[#input_data_types+1] = input.pipe.data_type
        end

        -- Differentiate the block
        block:differentiate(input_data_types)
    end

    -- Initialize all blocks
    for block, _ in pairs(blocks) do
        block:initialize()
    end

    io.stderr:write("Running in order:\n")
    for _, k in ipairs(self._execution_order) do
        io.stderr:write("\t" .. tostring(k) .. " " .. k.name .. "\n")
    end
end

function CompositeBlock:run_once()
    -- Prepare to run
    if not self._execution_order then
        self:_prepare_to_run()
    end

    -- Run blocks once
    for _, block in ipairs(self._execution_order) do
        block:run_once()
    end
end

ffi.cdef[[
    typedef int pid_t;
    pid_t fork(void);
    pid_t wait(int *status);
    pid_t waitpid(pid_t pid, int *status, int options);
    int kill(pid_t pid, int sig);
]]

ffi.cdef[[
    enum {SIGINT = 2, SIGKILL = 9, SIGTERM = 15, SIGCHLD = 17};

    /* sigset handling */
    typedef struct { uint8_t set[128]; } sigset_t;
    int sigemptyset(sigset_t *set);
    int sigfillset(sigset_t *set);
    int sigaddset(sigset_t *set, int signum);
    int sigdelset(sigset_t *set, int signum);
    int sigismember(const sigset_t *set, int signum);

    /* sigprocmask() */
    enum {SIG_BLOCK, SIG_UNBLOCK, SIG_SETMASK};
    int sigprocmask(int how, const sigset_t *restrict set, sigset_t *restrict oset);

    /* sigpending() */
    int sigpending(sigset_t *set);

    unsigned int sleep(unsigned int seconds);
]]

function CompositeBlock:run()
    -- Block handling of SIGINT and SIGCHLD
    local sigset = ffi.new("sigset_t[1]")
    ffi.C.sigemptyset(sigset)
    ffi.C.sigaddset(sigset, ffi.C.SIGINT)
    ffi.C.sigaddset(sigset, ffi.C.SIGCHLD)
    assert(ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) == 0, "sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Prepare to run
    if not self._execution_order then
        self:_prepare_to_run()
    end

    if not self._multiprocess then
        -- Run blocks single-threaded in round-robin order
        while true do
            for _, block in ipairs(self._execution_order) do
                block:run_once()
            end

            assert(ffi.C.sigpending(sigset) == 0, "sigpending(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            if ffi.C.sigismember(sigset, ffi.C.SIGINT) == 1 then
                io.stderr:write("Received SIGINT. Shutting down...\n")
                break
            end
        end
    else
        local pids = {}

        -- Fork and run blocks
        for _, block in ipairs(self._execution_order) do
            local pid = ffi.C.fork()
            assert(pid >= 0, "fork(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            if pid == 0 then
                block:run()
            else
                pids[#pids + 1] = pid
            end
        end

        -- Wait for SIGINT or SIGCHLD
        while true do
            -- FIXME cleaner check that is still portable?
            ffi.C.sleep(1)
            assert(ffi.C.sigpending(sigset) == 0, "sigpending(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

            if ffi.C.sigismember(sigset, ffi.C.SIGINT) == 1 then
                io.stderr:write("Received SIGINT. Shutting down...\n")
                break
            elseif ffi.C.sigismember(sigset, ffi.C.SIGCHLD) == 1 then
                io.stderr:write("Child exited. Shutting down...\n")
                break
            end
        end

        -- Kill and wait for all children
        for _, pid in pairs(pids) do
            ffi.C.kill(pid, ffi.C.SIGTERM)
            ffi.C.waitpid(pid, nil, 0)
        end
    end
end

return {CompositeBlock = CompositeBlock}
