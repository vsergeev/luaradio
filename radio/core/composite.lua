---
-- Hierarchical and top-level block composition.
--
-- @module radio.core.composite

local ffi = require('ffi')
local string = require('string')
local io = require('io')

local class = require('radio.core.class')
local block = require('radio.core.block')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')

---
-- Create a block to hold a flow graph composition, for either top-level or
-- hierarchical purposes. Top-level blocks may be run with the `run()` method.
--
-- @class CompositeBlock
local CompositeBlock = block.factory("CompositeBlock")

function CompositeBlock:instantiate()
    self._running = false
    self._connections = {}
end

-- Connection logic

-- Overridden implementation of Block's add_type_signature().
function CompositeBlock:add_type_signature(inputs, outputs)
    block.Block.add_type_signature(self, inputs, outputs)

    -- Replace InputPort's with AliasedInputPort's
    for i = 1, #self.inputs do
        if class.isinstanceof(self.inputs[i], pipe.InputPort) then
            self.inputs[i] = pipe.AliasedInputPort(self, self.inputs[i].name)
        end
    end

    -- Replace OutputPort's with AliasedOutputPort's
    for i = 1, #self.outputs do
        if class.isinstanceof(self.outputs[i], pipe.OutputPort) then
            self.outputs[i] = pipe.AliasedOutputPort(self, self.outputs[i].name)
        end
    end
end

---
-- Connect blocks.
--
-- This method can be used in three ways:
--
-- **Linear block connections.** Connect the first output to the first input of
-- each adjacent block. This usage is convenient for connecting blocks that
-- only have one input port and output port (which is most blocks).
--
-- ``` lua
-- top:connect(b1, b2, b3)
-- ```
--
-- **Explicit block connections.** Connect a particular output of the first
-- block to a particular input of the second block. The output and input ports
-- are specified by name. This invocation is used to connect a block to another
-- block with multiple input ports.
--
-- ``` lua
-- top:connect(b1, 'out', b2, 'in2')
-- ```
--
-- **Alias port connections.** Alias a composite block's input or output port
-- to a concrete block's input or output port. This invocation is used for
-- connecting the boundary inputs and outputs of a hierarchical block.
--
-- ``` lua
-- function MyHierarchicalBlock:instantiate()
--     local b1, b2, b3 = ...
--
--     ...
--
--     self:connect(b1, b2, b3)
--
--     self:connect(self, 'in', b1, 'in')
--     self:connect(self, 'out', b3, 'out')
-- end
-- ```
--
-- @function CompositeBlock:connect
-- @param ... Blocks [and ports] to connect
-- @treturn CompositeBlock self
-- @raise Output port of block not found error.
-- @raise Input port of block not found error.
-- @raise Input port of block already connected error.
-- @raise Unexpected number of output ports in block error.
-- @raise Unexpected number of input ports in block error.
function CompositeBlock:connect(...)
    if util.array_all({...}, function (b) return class.isinstanceof(b, block.Block) end) then
        local blocks = {...}
        local first, second = blocks[1], nil

        for i = 2, #blocks do
            local second = blocks[i]
            assert(#first.outputs == 1, string.format("Unexpected number of output ports in block %d \"%s\": found %d, expected 1.", i-1, first.name, #first.outputs))
            assert(#second.inputs == 1, string.format("Unexpected number of input ports in block %d \"%s\": found %d, expected 1.", i, second.name, #second.inputs))
            self:_connect_by_name(first, first.outputs[1].name, second, second.inputs[1].name)
            first = blocks[i]
        end
    else
        self:_connect_by_name(...)
    end

    return self
end

function CompositeBlock:_connect_by_name(src, src_port_name, dst, dst_port_name)
    -- Look up port objects
    local src_port = util.array_search(src.outputs, function (p) return p.name == src_port_name end) or
                        util.array_search(src.inputs, function (p) return p.name == src_port_name end)
    local dst_port = util.array_search(dst.outputs, function (p) return p.name == dst_port_name end) or
                        util.array_search(dst.inputs, function (p) return p.name == dst_port_name end)
    assert(src_port, string.format("Output port \"%s\" of block \"%s\" not found.", src_port_name, src.name))
    assert(dst_port, string.format("Input port \"%s\" of block \"%s\" not found.", dst_port_name, dst.name))

    -- If this is a block to block connection in a top composite block
    if src ~= self and dst ~= self then
        -- Map aliased outputs and inputs to their real ports
        src_port = class.isinstanceof(src_port, pipe.AliasedOutputPort) and src_port.real_output or src_port
        dst_ports = class.isinstanceof(dst_port, pipe.AliasedInputPort) and dst_port.real_inputs or {dst_port}

        for i = 1, #dst_ports do
            -- Assert input is not already connected
            assert(not self._connections[dst_ports[i]], string.format("Input port \"%s\" of block \"%s\" already connected.", dst_ports[i].name, dst_ports[i].owner.name))

            -- Create a pipe from output to input
            local p = pipe.Pipe(src_port, dst_ports[i])
            -- Link the pipe to the input and output ends
            src_port.pipes[#src_port.pipes+1] = p
            dst_ports[i].pipe = p

            -- Update our connections table
            self._connections[dst_ports[i]] = src_port

            debug.printf("[CompositeBlock] Connected output %s.%s to input %s.%s\n", src.name, src_port.name, dst.name, dst_port.name)
        end
    else
        -- Otherwise, we are aliasing an input or output of a composite block

        -- Map src and dst ports to alias port and target port
        local alias_port = (src == self) and src_port or dst_port
        local target_port = (src == self) and dst_port or src_port

        if class.isinstanceof(alias_port, pipe.AliasedInputPort) and class.isinstanceof(target_port, pipe.InputPort) then
            -- If we are aliasing a composite block input to a concrete block input

            alias_port.real_inputs[#alias_port.real_inputs + 1] = target_port
            debug.printf("[CompositeBlock] Aliased input %s.%s to input %s.%s\n", alias_port.owner.name, alias_port.name, target_port.owner.name, target_port.name)
        elseif class.isinstanceof(alias_port, pipe.AliasedOutputPort) and class.isinstanceof(target_port, pipe.OutputPort) then
            -- If we are aliasing a composite block output to a concrete block output

            assert(not alias_port.real_output, "Aliased output already connected.")
            alias_port.real_output = target_port
            debug.printf("[CompositeBlock] Aliased output %s.%s to output %s.%s\n", alias_port.owner.name, alias_port.name, target_port.owner.name, target_port.name)
        elseif class.isinstanceof(alias_port, pipe.AliasedInputPort) and class.isinstanceof(target_port, pipe.AliasedInputPort) then
            -- If we are aliasing a composite block input to a composite block input

            -- Absorb destination alias real inputs
            for i = 1, #target_port.real_inputs do
                alias_port.real_inputs[#alias_port.real_inputs + 1] = target_port.real_inputs[i]
            end
            debug.printf("[CompositeBlock] Aliased input %s.%s to input %s.%s\n", alias_port.owner.name, alias_port.name, target_port.owner.name, target_port.name)
        elseif class.isinstanceof(alias_port, pipe.AliasedOutputPort) and class.isinstanceof(target_port, pipe.AliasedOutputPort) then
            -- If we are aliasing a composite block output to a composite block output

            assert(not alias_port.real_output, "Aliased output already connected.")
            alias_port.real_output = target_port.real_output
            debug.printf("[CompositeBlock] Aliased output %s.%s to output %s.%s\n", alias_port.owner.name, alias_port.name, target_port.owner.name, target_port.name)
        else
            error("Malformed port connection.")
        end
    end
end

-- Helper functions to manipulate internal data structures

local function crawl_connections(connections)
    local blocks = {}
    local connections_copy = util.table_copy(connections)

    repeat
        local new_blocks_found = false

        for input, output in pairs(connections_copy) do
            local src = output.owner
            local dst = input.owner

            for _, block in ipairs({src, dst}) do
                -- If we haven't seen this block before
                if not blocks[block] then
                    -- Add all of the block's inputs our connections table
                    for i=1, #block.inputs do
                        if block.inputs[i].pipe then
                            connections_copy[block.inputs[i]] = block.inputs[i].pipe.output
                        end
                    end
                    -- Add all of the block's outputs to to our connection table
                    for i=1, #block.outputs do
                        for j=1, #block.outputs[i].pipes do
                            local input = block.outputs[i].pipes[j].input
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
    for input, output in pairs(connections) do
        local src = output.owner
        local dst = input.owner

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
    for input, output in pairs(connections) do
        local src = output.owner
        local dst = input.owner

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

local function build_evaluation_order(dependency_graph)
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
                -- Add block next to the evaluation order
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
    /* File descriptor table size */
    int getdtablesize(void);

    /* File tree walk */
    int ftw(const char *dirpath, int (*fn) (const char *fpath, const struct stat *sb, int typeflag), int nopenfd);
]]

local function listdir(path)
    local entries = {}

    -- Normalize directory path with trailing /
    path = (string.sub(path, -1) == "/") and path or (path .. "/")

    -- Store each file entry in entries
    local function store_entry_fn(fpath, sb, typeflag)
        if typeflag == 0 then
            entries[#entries + 1] = string.sub(ffi.string(fpath), #path+1)
        end
        return 0
    end

    -- File tree walk on directory path
    if ffi.C.ftw(path, store_entry_fn, 1) ~= 0 then
        error("ftw(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    return entries
end

function CompositeBlock:_prepare_to_run()
    -- Crawl our connections to get the full list of blocks and connections
    local blocks, all_connections = crawl_connections(self._connections)

    -- Check all block inputs are connected
    for block, _ in pairs(blocks) do
        for i=1, #block.inputs do
            assert(block.inputs[i].pipe ~= nil, string.format("Block \"%s\" input \"%s\" is unconnected.", block.name, block.inputs[i].name))
        end
    end

    -- Build dependency graph and evaluation order
    local evaluation_order = build_evaluation_order(build_dependency_graph(all_connections))

    -- Differentiate all blocks
    for _, block in ipairs(evaluation_order) do
        -- Gather input data types to this block
        local input_data_types = {}
        for _, input in ipairs(block.inputs) do
            input_data_types[#input_data_types+1] = input.pipe:get_data_type()
        end

        -- Differentiate the block
        block:differentiate(input_data_types)
    end

    -- Check all block input rates match
    for _, block in pairs(evaluation_order) do
        local rate = nil
        for i=1, #block.inputs do
            if not rate then
                rate = block.inputs[i].pipe:get_rate()
            else
                assert(block.inputs[i].pipe:get_rate() == rate, string.format("Block \"%s\" input \"%s\" sample rate mismatch.", block.name, block.inputs[i].name))
            end
        end
    end

    -- Initialize all blocks
    for _, block in ipairs(evaluation_order) do
        block:initialize()
    end

    -- Initialize all pipes
    for input, output in pairs(all_connections) do
        input.pipe:initialize()
    end

    debug.print("[CompositeBlock] Flow graph:")
    for _, k in ipairs(evaluation_order) do
        local s = string.gsub(tostring(k), "\n", "\n[CompositeBlock]\t")
        debug.print("[CompositeBlock]\t" .. s)
    end

    return all_connections, evaluation_order
end

---
-- Run a top-level block. This is equivalent to calling `start()` followed by
-- `wait()` on the top-level block.
--
-- @function CompositeBlock:run
-- @treturn CompositeBlock self
-- @raise Block already running error.
-- @raise Block input port unconnected error.
-- @raise Block input port sample rate mismatch error.
-- @raise No compatible type signatures found for block error.
--
-- @usage
-- -- Run a top-level block
-- top:run()
function CompositeBlock:run(multiprocess)
    self:start(multiprocess)
    self:wait()

    return self
end

---
-- Start a top-level block.
--
-- @function CompositeBlock:start
-- @treturn CompositeBlock self
-- @raise Block already running error.
-- @raise Block input port unconnected error.
-- @raise Block input port sample rate mismatch error.
-- @raise No compatible type signatures found for block error.
--
-- @usage
-- -- Start a top-level block
-- top:start()
function CompositeBlock:start(multiprocess)
    if self._running then
        error("CompositeBlock already running!")
    end

    -- Default to multiprocess
    multiprocess = (multiprocess == nil) and true or multiprocess

    -- Prepare to run
    local all_connections, evaluation_order = self:_prepare_to_run()

    -- If there's no blocks to run, return
    if #evaluation_order == 0 then
        return self
    end

    if multiprocess then
        self._pids = {}

        debug.printf("[CompositeBlock] Parent pid %d\n", ffi.C.getpid())

        -- Block handling of SIGINT and SIGCHLD
        local sigset = ffi.new("sigset_t[1]")
        ffi.C.sigemptyset(sigset)
        ffi.C.sigaddset(sigset, ffi.C.SIGINT)
        ffi.C.sigaddset(sigset, ffi.C.SIGCHLD)
        if ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) ~= 0 then
            error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Install dummy signal handler for SIGCHLD
        self._saved_sigchld_handler = ffi.C.signal(ffi.C.SIGCHLD, function (sig) end)

        -- Fork and run blocks
        for _, block in ipairs(evaluation_order) do
            local pid = ffi.C.fork()
            if pid < 0 then
                error("fork(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end

            if pid == 0 then
                -- Create a set of file descriptors to save
                local save_fds = {}

                -- Ignore SIGPIPE, handle with error from write()
                ffi.C.signal(ffi.C.SIGPIPE, ffi.cast("sighandler_t", ffi.C.SIG_IGN))

                -- Save input pipe fds
                for i = 1, #block.inputs do
                    for _, fd in pairs(block.inputs[i]:filenos()) do
                        save_fds[fd] = true
                    end
                end

                -- Save output pipe fds
                for i = 1, #block.outputs do
                    for _, fd in pairs(block.outputs[i]:filenos()) do
                        save_fds[fd] = true
                    end
                end

                -- Save open file fds
                for file, _ in pairs(block.files) do
                    local fd = (type(file) == "number") and file or ffi.C.fileno(file)
                    save_fds[fd] = true
                end

                -- Close all other file descriptors
                if platform.os == "Linux" then
                    for _, entry in pairs(listdir("/proc/self/fd")) do
                        local fd = tonumber(entry)
                        if fd and not save_fds[fd] then
                            ffi.C.close(fd)
                        end
                    end
                else
                    -- Fall back to the nuclear approach, as FreeBSD and
                    -- Mac OS X may not have fdescfs or procfs mounted
                    for fd = 0, ffi.C.getdtablesize()-1 do
                        if not save_fds[fd] then
                            ffi.C.close(fd)
                        end
                    end
                end

                debug.printf("[CompositeBlock] Block %s pid %d\n", block.name, ffi.C.getpid())

                -- Run the block
                local status, err = xpcall(function () block:run() end, _G.debug.traceback)
                if not status then
                    io.stderr:write(string.format("[%s] Block runtime error: %s\n", block.name, tostring(err)))
                    os.exit(1)
                end

                -- Exit
                os.exit(0)
            else
                self._pids[block] = pid
            end
        end

        -- Close all pipe inputs and outputs in the top-level process
        for input, output in pairs(all_connections) do
            input:close()
            output:close()
        end

        -- Mark ourselves as running
        self._running = true
    else
        -- Build a skip set, containing the set of blocks to skip for each
        -- block, if it produces no new samples.
        local skip_set = build_skip_set(all_connections)

        -- Block handling of SIGINT
        local sigset = ffi.new("sigset_t[1]")
        ffi.C.sigemptyset(sigset)
        ffi.C.sigaddset(sigset, ffi.C.SIGINT)
        if ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) ~= 0 then
            error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Ignore SIGPIPE, handle with error from write()
        ffi.C.signal(ffi.C.SIGPIPE, ffi.cast("sighandler_t", ffi.C.SIG_IGN))

        -- Run blocks in round-robin order
        local running = true
        while running do
            local skip = {}

            for _, block in ipairs(evaluation_order) do
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
        for _, block in ipairs(evaluation_order) do
            block:cleanup()
        end

        -- Unblock handling of SIGINT
        local sigset = ffi.new("sigset_t[1]")
        ffi.C.sigemptyset(sigset)
        ffi.C.sigaddset(sigset, ffi.C.SIGINT)
        if ffi.C.sigprocmask(ffi.C.SIG_UNBLOCK, sigset, nil) ~= 0 then
            error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    return self
end

-- Reap child processes, consume SIGCHLD, and unblock signals
function CompositeBlock:_reap()
    -- Wait for all children to exit
    for _, pid in pairs(self._pids) do
        -- If the process exists
        if ffi.C.kill(pid, 0) == 0 then
            -- Reap the process
            if ffi.C.waitpid(pid, nil, 0) == -1 then
                error("waitpid(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
        end
    end

    -- Check pending signals
    local sigset = ffi.new("sigset_t[1]")
    if ffi.C.sigpending(sigset) ~= 0 then
        error("sigpending(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Consume pending SIGCHLD signal
    if ffi.C.sigismember(sigset, ffi.C.SIGCHLD) == 1 then
        local sig = ffi.new("int[1]")
        ffi.C.sigemptyset(sigset)
        ffi.C.sigaddset(sigset, ffi.C.SIGCHLD)
        if ffi.C.sigwait(sigset, sig) ~= 0 then
            error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Restore SIGCHLD handler
    ffi.C.signal(ffi.C.SIGCHLD, self._saved_sigchld_handler)

    -- Unblock handling of SIGINT and SIGCHLD
    local sigset = ffi.new("sigset_t[1]")
    ffi.C.sigemptyset(sigset)
    ffi.C.sigaddset(sigset, ffi.C.SIGINT)
    ffi.C.sigaddset(sigset, ffi.C.SIGCHLD)
    if ffi.C.sigprocmask(ffi.C.SIG_UNBLOCK, sigset, nil) ~= 0 then
        error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Mark ourselves as not running
    self._running = false
end

---
-- Get the status of a top-level block.
--
-- @function CompositeBlock:status
-- @treturn table Status information with fields: `running` (bool).
-- @usage
-- if top:status().running then
--     print('Still running...')
-- end
function CompositeBlock:status()
    if not self._running then
        return {running = false}
    end

    -- Check if any children are still running
    for _, pid in pairs(self._pids) do
        if ffi.C.waitpid(pid, nil, ffi.C.WNOHANG) == 0 then
            return {running = true}
        end
    end

    -- Reap child processes
    self:_reap()

    return {running = false}
end

---
-- Stop a top-level block and wait until it has finished.
--
-- @function CompositeBlock:stop
-- @usage
-- -- Start a top-level block
-- top:start()
-- -- Stop a top-level block
-- top:stop()
function CompositeBlock:stop()
    if not self._running then
        return
    end

    -- Kill source blocks
    for block, pid in pairs(self._pids) do
        if #block.inputs == 0 then
            ffi.C.kill(pid, ffi.C.SIGTERM)
        end
    end

    -- Reap child processes
    self:_reap()
end

---
-- Wait for a top-level block to finish, either by natural termination or by
-- `SIGINT`.
--
-- @function CompositeBlock:wait
-- @usage
-- -- Start a top-level block
-- top:start()
-- -- Wait for the top-level block to finish
-- top:wait()
function CompositeBlock:wait()
    if not self._running then
        return
    end

    -- Build signal set with SIGINT and SIGCHLD
    local sigset = ffi.new("sigset_t[1]")
    ffi.C.sigemptyset(sigset)
    ffi.C.sigaddset(sigset, ffi.C.SIGINT)
    ffi.C.sigaddset(sigset, ffi.C.SIGCHLD)

    -- Wait for SIGINT or SIGCHLD
    local sig = ffi.new("int[1]")
    if ffi.C.sigwait(sigset, sig) ~= 0 then
        error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    if sig[0] == ffi.C.SIGINT then
        debug.print("[CompositeBlock] Received SIGINT. Shutting down...")

        -- Forcibly stop
        self:stop()
    elseif sig[0] == ffi.C.SIGCHLD then
        debug.print("[CompositeBlock] Child exited. Shutting down...")

        -- Reap child processes
        self:_reap()
    end
end

return {CompositeBlock = CompositeBlock, _crawl_connections = crawl_connections, _build_dependency_graph = build_dependency_graph, _build_reverse_dependency_graph = build_reverse_dependency_graph, _build_evaluation_order = build_evaluation_order, _build_skip_set = build_skip_set}
