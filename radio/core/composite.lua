local ffi = require('ffi')
local string = require('string')
local io = require('io')

local class = require('radio.core.class')
local block = require('radio.core.block')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')
local debug = require('radio.core.debug')

local CompositeBlock = block.factory("CompositeBlock")

-- Connection logic

function CompositeBlock:instantiate()
    self._running = false
    self._connections = {}
end

function CompositeBlock:add_type_signature(inputs, outputs)
    block.Block.add_type_signature(self, inputs, outputs)

    -- Replace PipeInput's with AliasedPipeInput's
    for i = 1, #self.inputs do
        if class.isinstanceof(self.inputs[i], pipe.PipeInput) then
            self.inputs[i] = pipe.AliasedPipeInput(self, self.inputs[i].name)
        end
    end

    -- Replace PipeOutput's with AliasedPipeOutput's
    for i = 1, #self.outputs do
        if class.isinstanceof(self.outputs[i], pipe.PipeOutput) then
            self.outputs[i] = pipe.AliasedPipeOutput(self, self.outputs[i].name)
        end
    end
end

function CompositeBlock:connect(...)
    if util.array_all({...}, function (b) return class.isinstanceof(b, block.Block) end) then
        local blocks = {...}
        local first, second = blocks[1], nil

        for i = 2, #blocks do
            local second = blocks[i]
            self:_connect_by_name(first, first.outputs[1].name, second, second.inputs[1].name)
            first = blocks[i]
        end
    else
        self:_connect_by_name(...)
    end

    return self
end

function CompositeBlock:_connect_by_name(src, src_pipe_name, dst, dst_pipe_name)
    -- Look up pipe objects
    local src_pipe = util.array_search(src.outputs, function (p) return p.name == src_pipe_name end) or
                        util.array_search(src.inputs, function (p) return p.name == src_pipe_name end)
    local dst_pipe = util.array_search(dst.outputs, function (p) return p.name == dst_pipe_name end) or
                        util.array_search(dst.inputs, function (p) return p.name == dst_pipe_name end)
    assert(src_pipe, string.format("Source pipe \"%s\" of block \"%s\" not found.", src_pipe_name, src.name))
    assert(dst_pipe, string.format("Destination pipe \"%s\" of block \"%s\" not found.", dst_pipe_name, dst.name))

    -- If this is a block to block connection in a top composite block
    if src ~= self and dst ~= self then
        -- Map aliased outputs and inputs to their real pipes
        src_pipe = class.isinstanceof(src_pipe, pipe.AliasedPipeOutput) and src_pipe.real_output or src_pipe
        dst_pipes = class.isinstanceof(dst_pipe, pipe.AliasedPipeInput) and dst_pipe.real_inputs or {dst_pipe}

        for i = 1, #dst_pipes do
            -- Assert input is not already connected
            assert(not self._connections[dst_pipes[i]], "Input already connected.")

            -- Create a pipe from output to input
            local p = pipe.Pipe(src_pipe, dst_pipes[i])
            -- Link the pipe to the input and output ends
            src_pipe.pipes[#src_pipe.pipes+1] = p
            dst_pipes[i].pipe = p

            -- Update our connections table
            self._connections[dst_pipes[i]] = src_pipe

            debug.printf("[CompositeBlock] Connected source %s.%s to destination %s.%s\n", src.name, src_pipe.name, dst.name, dst_pipe.name)
        end
    else
        -- Otherwise, we are aliasing an input or output of a composite block

        -- Map src and dst pipe to alias pipe and real pipe
        local alias_pipe = (src == self) and src_pipe or dst_pipe
        local target_pipe = (src == self) and dst_pipe or src_pipe

        if class.isinstanceof(alias_pipe, pipe.AliasedPipeInput) and class.isinstanceof(target_pipe, pipe.PipeInput) then
            -- If we are aliasing a composite block input to a concrete block input

            alias_pipe.real_inputs[#alias_pipe.real_inputs + 1] = target_pipe
            debug.printf("[CompositeBlock] Aliased input %s.%s to input %s.%s\n", alias_pipe.owner.name, alias_pipe.name, target_pipe.owner.name, target_pipe.name)
        elseif class.isinstanceof(alias_pipe, pipe.AliasedPipeOutput) and class.isinstanceof(target_pipe, pipe.PipeOutput) then
            -- If we are aliasing a composite block output to a concrete block output

            assert(not alias_pipe.real_output, "Aliased output already connected.")
            alias_pipe.real_output = target_pipe
            debug.printf("[CompositeBlock] Aliased output %s.%s to output %s.%s\n", alias_pipe.owner.name, alias_pipe.name, target_pipe.owner.name, target_pipe.name)
        elseif class.isinstanceof(alias_pipe, pipe.AliasedPipeInput) and class.isinstanceof(target_pipe, pipe.AliasedPipeInput) then
            -- If we are aliasing a composite block input to a composite block input

            -- Absorb destination alias real inputs
            for i = 1, #target_pipe.real_inputs do
                alias_pipe.real_inputs[#alias_pipe.real_inputs + 1] = target_pipe.real_inputs[i]
            end
            debug.printf("[CompositeBlock] Aliased input %s.%s to input %s.%s\n", alias_pipe.owner.name, alias_pipe.name, target_pipe.owner.name, target_pipe.name)
        elseif class.isinstanceof(alias_pipe, pipe.AliasedPipeOutput) and class.isinstanceof(target_pipe, pipe.AliasedPipeOutput) then
            -- If we are aliasing a composite block output to a composite block output

            assert(not alias_pipe.real_output, "Aliased output already connected.")
            alias_pipe.real_output = target_pipe.real_output
            debug.printf("[CompositeBlock] Aliased output %s.%s to output %s.%s\n", alias_pipe.owner.name, alias_pipe.name, target_pipe.owner.name, target_pipe.name)
        else
            error("Malformed pipe connection.")
        end
    end
end

local function crawl_connections(connections)
    local blocks = {}
    local connections_copy = util.table_copy(connections)

    repeat
        local new_blocks_found = false

        for pipe_input, pipe_output in pairs(connections_copy) do
            local src = pipe_output.owner
            local dst = pipe_input.owner

            for _, block in ipairs({src, dst}) do
                -- If we haven't seen this block before
                if not blocks[block] then
                    -- Add all of the block's inputs our connections table
                    for i=1, #block.inputs do
                        if block.inputs[i].pipe then
                            connections_copy[block.inputs[i]] = block.inputs[i].pipe.pipe_output
                        end
                    end
                    -- Add all of the block's outputs to to our connection table
                    for i=1, #block.outputs do
                        for j=1, #block.outputs[i].pipes do
                            local input = block.outputs[i].pipes[j].pipe_input
                            connections_copy[input] = block.outputs[i]
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

local function build_reverse_dependency_graph(connections)
    local graph = {}

    -- Add dependencies between connected blocks
    for pipe_input, pipe_output in pairs(connections) do
        local src = pipe_output.owner
        local dst = pipe_input.owner

        if graph[src] == nil then
            graph[src] = {dst}
        else
            graph[src][#graph[src] + 1] = dst
        end

        if graph[dst] == nil then
            graph[dst] = {}
        end
    end

    return graph
end

local function build_skip_set(connections)
    local dep_graph = build_reverse_dependency_graph(connections)
    local graph = {}

    -- Generate a set of downstream dependencies to block
    local function recurse_dependencies(block, set)
        set = set or {}

        for _, dependency in ipairs(dep_graph[block]) do
            set[dependency] = true
            recurse_dependencies(dependency, set)
        end

        return set
    end

    for block, _ in pairs(dep_graph) do
        graph[block] = recurse_dependencies(block)
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

-- Execution

ffi.cdef[[
    typedef int pid_t;
    pid_t fork(void);
    pid_t waitpid(pid_t pid, int *status, int options);

    /* kill() */
    int kill(pid_t pid, int sig);

    /* sigset handling */
    typedef struct { uint8_t set[128]; } sigset_t;
    int sigemptyset(sigset_t *set);
    int sigfillset(sigset_t *set);
    int sigaddset(sigset_t *set, int signum);
    int sigdelset(sigset_t *set, int signum);
    int sigismember(const sigset_t *set, int signum);

    /* signal() */
    typedef void (*sighandler_t)(int);
    sighandler_t signal(int signum, sighandler_t handler);

    /* sigwait() */
    int sigwait(const sigset_t *set, int *sig);

    /* sigprocmask() */
    int sigprocmask(int how, const sigset_t *restrict set, sigset_t *restrict oset);

    /* sigpending() */
    int sigpending(sigset_t *set);

    unsigned int sleep(unsigned int seconds);
]]

function CompositeBlock:_prepare_to_run()
    -- Crawl our connections to get the full list of blocks and connections
    local blocks, all_connections = crawl_connections(self._connections)

    -- Check all inputs are connected
    for block, _ in pairs(blocks) do
        for i=1, #block.inputs do
            assert(block.inputs[i].pipe ~= nil, string.format("Block \"%s\" input \"%s\" is unconnected.", block.name, block.inputs[i].name))
        end
    end

    -- Build dependency graph and execution order
    local execution_order = build_execution_order(build_dependency_graph(all_connections))

    -- Differentiate all blocks
    for _, block in ipairs(execution_order) do
        -- Gather input data types to this block
        local input_data_types = {}
        for _, input in ipairs(block.inputs) do
            input_data_types[#input_data_types+1] = input.pipe:get_data_type()
        end

        -- Differentiate the block
        block:differentiate(input_data_types)
    end

    -- Initialize all blocks
    for _, block in ipairs(execution_order) do
        block:initialize()
    end

    -- Initialize all pipes
    for pipe_input, pipe_output in pairs(all_connections) do
        pipe_input.pipe:initialize()
    end

    debug.print("[CompositeBlock] Execution order:")
    for _, k in ipairs(execution_order) do
        local s = string.gsub(tostring(k), "\n", "\n[CompositeBlock]\t")
        debug.print("[CompositeBlock]\t" .. s)
    end

    return all_connections, execution_order
end

function CompositeBlock:run(multiprocess)
    self:start(multiprocess)
    self:wait()

    return self
end

function CompositeBlock:start(multiprocess)
    -- Default to multiprocess
    multiprocess = (multiprocess == nil) and true or multiprocess

    if self._running then
        error("CompositeBlock already running!")
    end

    -- Install dummy signal handler for SIGCHLD as BSD platforms
    -- discard this signal by default.
    ffi.C.signal(ffi.C.SIGCHLD, function (sig) end)

    -- Block handling of SIGINT and SIGCHLD
    local sigset = ffi.new("sigset_t[1]")
    ffi.C.sigemptyset(sigset)
    ffi.C.sigaddset(sigset, ffi.C.SIGINT)
    ffi.C.sigaddset(sigset, ffi.C.SIGCHLD)
    if ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) ~= 0 then
        error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Prepare to run
    local all_connections, execution_order = self:_prepare_to_run()

    -- Clear any pending SIGINT or SIGCHLD signals
    while true do
        if ffi.C.sigpending(sigset) ~= 0 then
            error("sigpending(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        if ffi.C.sigismember(sigset, ffi.C.SIGINT) == 1 or ffi.C.sigismember(sigset, ffi.C.SIGCHLD) == 1 then
            -- Consume this signal
            local sig = ffi.new("int[1]")
            if ffi.C.sigwait(sigset, sig) ~= 0 then
                error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
        else
            break
        end
    end

    if not multiprocess then
        -- Build a skip set, containing the set of blocks to skip for each
        -- block, if it produces no new samples.
        local skip_set = build_skip_set(all_connections)

        -- Run blocks in round-robin order
        local running = true
        while running do
            local skip = {}

            for _, block in ipairs(execution_order) do
                if not skip[block] then
                    local ret = block:run_once()
                    if ret == false then
                        -- No new samples produced, mark downstream blocks in
                        -- our skip set
                        for b , _ in pairs(skip_set[block]) do
                            skip[b] = true
                        end
                    elseif ret == nil then
                        -- EOF reached, stop running
                        running = false
                        break
                    end
                end
            end

            -- Check for SIGINT
            if ffi.C.sigpending(sigset) ~= 0 then
                error("sigpending(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
            if ffi.C.sigismember(sigset, ffi.C.SIGINT) == 1 then
                debug.print("[CompositeBlock] Received SIGINT. Shutting down...")
                running = false
            end
        end

        -- Clean up all blocks
        for _, block in ipairs(execution_order) do
            block:cleanup()
        end
    else
        self._pids = {}

        -- Fork and run blocks
        for _, block in ipairs(execution_order) do
            local pid = ffi.C.fork()
            if pid < 0 then
                error("fork(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end

            if pid == 0 then
                -- Create a set of pipe inputs and outputs to save
                local pipes_save = {}
                for i = 1, #block.inputs do
                    pipes_save[block.inputs[i]] = true
                end
                for i = 1, #block.outputs do
                    pipes_save[block.outputs[i]] = true
                end

                -- Close all other pipe inputs and outputs
                for pipe_input, pipe_output in pairs(all_connections) do
                    if not pipes_save[pipe_input] then
                        pipe_input:close()
                    end
                    if not pipes_save[pipe_output] then
                        pipe_output:close()
                    end
                end

                -- Run the block
                block:run()

                -- Exit
                os.exit(0)
            else
                self._pids[block] = pid
            end
        end

        -- Close all pipe inputs and outputs in the top-level process
        for pipe_input, pipe_output in pairs(all_connections) do
            pipe_input:close()
            pipe_output:close()
        end

        -- Mark ourselves as running
        self._running = true
    end

    return self
end

function CompositeBlock:stop()
    if self._running and self._pids then
        -- Kill source blocks
        for block, pid in pairs(self._pids) do
            if #block.inputs == 0 then
                ffi.C.kill(pid, ffi.C.SIGTERM)
            end
        end

        -- Wait for all children
        for _, pid in pairs(self._pids) do
            if ffi.C.waitpid(pid, nil, 0) == -1 then
                error("waitpid(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
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

            if ffi.C.sigpending(sigset) ~= 0 then
                error("sigpending(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end

            if ffi.C.sigismember(sigset, ffi.C.SIGINT) == 1 then
                debug.print("[CompositeBlock] Received SIGINT. Shutting down...")
                break
            elseif ffi.C.sigismember(sigset, ffi.C.SIGCHLD) == 1 then
                debug.print("[CompositeBlock] Child exited. Shutting down...")
                break
            end
        end

        -- Kill remaining children
        self:stop()
    end
end

return {CompositeBlock = CompositeBlock, _crawl_connections = crawl_connections, _build_dependency_graph = build_dependency_graph, _build_reverse_dependency_graph = build_reverse_dependency_graph, _build_execution_order = build_execution_order, _build_skip_set = build_skip_set}
