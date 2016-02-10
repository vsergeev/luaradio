local ffi = require('ffi')
local string = require('string')
local io = require('io')

local object = require('radio.core.object')
local block = require('radio.core.block')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

local CompositeBlock = block.factory("CompositeBlock")

function CompositeBlock:instantiate()
    self._running = false
    self._connections = {}
end

function CompositeBlock:add_type_signature(inputs, outputs)
    block.Block.add_type_signature(self, inputs, outputs)

    -- Replace PipeInput's with AliasedPipeInput's
    for i = 1, #self.inputs do
        if object.isinstanceof(self.inputs[i], pipe.PipeInput) then
            self.inputs[i] = pipe.AliasedPipeInput(self, self.inputs[i].name)
        end
    end

    -- Replace PipeOutput's with AliasedPipeOutput's
    for i = 1, #self.outputs do
        if object.isinstanceof(self.outputs[i], pipe.PipeOutput) then
            self.outputs[i] = pipe.AliasedPipeOutput(self, self.outputs[i].name)
        end
    end
end

function CompositeBlock:connect(...)
    if util.array_all({...}, function (b) return object.isinstanceof(b, block.Block) end) then
        local blocks = {...}
        local first, second = blocks[1], nil

        for i = 2, #blocks do
            local second = blocks[i]
            self:connect_by_name(first, first.outputs[1].name, second, second.inputs[1].name)
            first = blocks[i]
        end
    else
        self:connect_by_name(...)
    end
end

function CompositeBlock:connect_by_name(src, src_pipe_name, dst, dst_pipe_name)
    -- Look up pipe objects
    local src_pipe = util.array_search(src.outputs, function (p) return p.name == src_pipe_name end) or
                        util.array_search(src.inputs, function (p) return p.name == src_pipe_name end)
    local dst_pipe = util.array_search(dst.outputs, function (p) return p.name == dst_pipe_name end) or
                        util.array_search(dst.inputs, function (p) return p.name == dst_pipe_name end)
    assert(src_pipe, string.format("Source pipe \"%s\" of block \"%s\" not found.", src_pipe_name, src.name))
    assert(dst_pipe, string.format("Destination pipe \"%s\" of block \"%s\" not found.", dst_pipe_name, dst.name))

    -- Map aliased outputs or aliased inputs to their real pipes
    src_pipe = (object.isinstanceof(src_pipe, pipe.AliasedPipeOutput) and src_pipe.real_pipe) and src_pipe.real_pipe or src_pipe
    dst_pipe = (object.isinstanceof(dst_pipe, pipe.AliasedPipeInput) and dst_pipe.real_pipe) and dst_pipe.real_pipe or dst_pipe

    if object.isinstanceof(src_pipe, pipe.PipeOutput) and object.isinstanceof(dst_pipe, pipe.PipeInput) then
        -- If we are connecting an output pipe to an input pipe

        -- Assert input is not already connected
        assert(not self._connections[dst_pipe], "Input already connected.")

        -- Create a pipe from output to input
        local p = pipe.Pipe(src_pipe, dst_pipe)
        -- Link the pipe to the input and output ends
        src_pipe.pipes[#src_pipe.pipes+1] = p
        dst_pipe.pipe = p

        -- Update our connections table
        self._connections[dst_pipe] = src_pipe

        io.stderr:write(string.format("Connected source %s.%s to destination %s.%s\n", src.name, src_pipe.name, dst.name, dst_pipe.name))
    elseif object.isinstanceof(src_pipe, pipe.AliasedPipeInput) and object.isinstanceof(dst_pipe, pipe.PipeInput) then
        -- If we are aliasing a composite block input pipe to a real input pipe
        src_pipe.real_pipe = dst_pipe
        io.stderr:write(string.format("Aliased input %s.%s to input %s.%s\n", src.name, src_pipe.name, dst.name, dst_pipe.name))
    elseif object.isinstanceof(src_pipe, pipe.PipeInput) and object.isinstanceof(dst_pipe, pipe.AliasedPipeInput) then
        -- If we are aliasing a composite block input pipe to a real input pipe
        dst_pipe.real_pipe = src_pipe
        io.stderr:write(string.format("Aliased input %s.%s to input %s.%s\n", dst.name, dst_pipe.name, src.name, src_pipe.name))
    elseif object.isinstanceof(src_pipe, pipe.AliasedPipeOutput) and object.isinstanceof(dst_pipe, pipe.PipeOutput) then
        -- If we are aliasing a composite block input pipe to a real input pipe
        src_pipe.real_pipe = dst_pipe
        io.stderr:write(string.format("Aliased output %s.%s to input %s.%s\n", src.name, src_pipe.name, dst.name, dst_pipe.name))
    elseif object.isinstanceof(src_pipe, pipe.PipeOutput) and object.isinstanceof(dst_pipe, pipe.AliasedPipeOutput) then
        -- If we are aliasing a composite block input pipe to a real input pipe
        dst_pipe.real_pipe = src_pipe
        io.stderr:write(string.format("Aliased output %s.%s to input %s.%s\n", dst.name, dst_pipe.name, src.name, src_pipe.name))
    else
        error("Malformed pipe connection.")
    end
end

local function crawl_connections(connections)
    local blocks = {}
    local connections_copy = util.table_copy(connections)

    local new_blocks_found
    repeat
        new_blocks_found = false

        for pipe_input, pipe_output in pairs(connections_copy) do
            local src = pipe_output.owner
            local dst = pipe_input.owner

            for _, block in ipairs({src, dst}) do
                -- If we haven't seen this block before
                if not blocks[block] then
                    -- Add its input -> output mapping to our connections table
                    for i=1, #block.inputs do
                        if block.inputs[i].pipe then
                            connections_copy[block.inputs[i]] = block.inputs[i].pipe.pipe_output
                        end
                    end

                    -- Add it to our blocks table
                    blocks[block] = true

                    new_blocks_found = true
                end
            end
        end
    until new_blocks_found == false

    return blocks, connections_copy
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

function CompositeBlock:_prepare_to_run(multiprocess)
    -- Crawl our connections to get the full list of blocks and connections
    local blocks, all_connections = crawl_connections(self._connections)

    -- Check all inputs are connected
    for block, _ in pairs(blocks) do
        for i=1, #block.inputs do
            assert(block.inputs[i].pipe ~= nil, string.format("Block \"%s\" input \"%s\" is unconnected.", block.name, block.inputs[i].name))
        end
    end

    -- Build dependency graph and execution order
    self._execution_order = build_execution_order(build_dependency_graph(all_connections))

    -- Differentiate all blocks
    for _, block in ipairs(self._execution_order) do
        -- Gather input data types to this block
        local input_data_types = {}
        for _, input in ipairs(block.inputs) do
            input_data_types[#input_data_types+1] = input.pipe.data_type
        end

        -- Differentiate the block
        block:differentiate(input_data_types)

        -- Set output pipe data types
        for i = 1, #block.signature.outputs do
            for _, pipe in ipairs(block.outputs[i].pipes) do
                pipe.data_type = block.signature.outputs[i].data_type
            end
        end
    end

    -- Initialize all blocks
    for block, _ in pairs(blocks) do
        block:initialize()
    end

    -- Initialize all pipes
    for pipe_input, pipe_output in pairs(all_connections) do
        pipe_input.pipe:initialize(multiprocess)
    end

    io.stderr:write("Running in order:\n")
    for _, k in ipairs(self._execution_order) do
        io.stderr:write("\t" .. tostring(k) .. " " .. k.name .. "\n")
    end
end

ffi.cdef[[
    typedef int pid_t;
    pid_t fork(void);
    pid_t waitpid(pid_t pid, int *status, int options);

    /* kill() */
    int kill(pid_t pid, int sig);
    enum {SIGINT = 2, SIGKILL = 9, SIGTERM = 15, SIGCHLD = 17};

    /* sigset handling */
    typedef struct { uint8_t set[128]; } sigset_t;
    int sigemptyset(sigset_t *set);
    int sigfillset(sigset_t *set);
    int sigaddset(sigset_t *set, int signum);
    int sigdelset(sigset_t *set, int signum);
    int sigismember(const sigset_t *set, int signum);

    /* sigwait() */
    int sigwait(const sigset_t *set, int *sig);

    /* sigprocmask() */
    enum {SIG_BLOCK, SIG_UNBLOCK, SIG_SETMASK};
    int sigprocmask(int how, const sigset_t *restrict set, sigset_t *restrict oset);

    /* sigpending() */
    int sigpending(sigset_t *set);

    unsigned int sleep(unsigned int seconds);
]]

function CompositeBlock:run(multiprocess)
    self:start(multiprocess)
    self:wait()
end

function CompositeBlock:start(multiprocess)
    assert(not self._running, "CompositeBlock already running!")

    -- Block handling of SIGINT and SIGCHLD
    local sigset = ffi.new("sigset_t[1]")
    ffi.C.sigemptyset(sigset)
    ffi.C.sigaddset(sigset, ffi.C.SIGINT)
    ffi.C.sigaddset(sigset, ffi.C.SIGCHLD)
    assert(ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) == 0, "sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Clear any pending signals
    while true do
        assert(ffi.C.sigpending(sigset) == 0, "sigpending(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        if ffi.C.sigismember(sigset, ffi.C.SIGINT) == 1 or ffi.C.sigismember(sigset, ffi.C.SIGCHLD) == 1 then
            local sig = ffi.new("int[1]")
            assert(ffi.C.sigwait(sigset, sig) == 0, "sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        else
            break
        end
    end

    -- Prepare to run
    self:_prepare_to_run(multiprocess)

    if not multiprocess then
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
        self._pids = {}

        -- Fork and run blocks
        for _, block in ipairs(self._execution_order) do
            local pid = ffi.C.fork()
            assert(pid >= 0, "fork(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            if pid == 0 then
                block:run()
            else
                self._pids[#self._pids + 1] = pid
            end
        end

        -- Mark ourselves as running
        self._running = true
    end
end

function CompositeBlock:stop()
    if self._running and self._pids then
        -- Kill and wait for all children
        for _, pid in pairs(self._pids) do
            ffi.C.kill(pid, ffi.C.SIGTERM)
            ffi.C.waitpid(pid, nil, 0)
        end

        -- Mark ourselves as not running
        self._running = false
    end
end

function CompositeBlock:wait()
    if self._running and self._pids then
        local sigset = ffi.new("sigset_t[1]")

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

        -- Kill remaining children
        self:stop()
    end
end

return {CompositeBlock = CompositeBlock}
