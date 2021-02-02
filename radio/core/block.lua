---
-- Support classes for creating blocks.
--
-- @module radio.block

local ffi = require('ffi')

local class = require('radio.core.class')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')
local debug = require('radio.core.debug')

---
-- Block input port descriptor. This contains the name and data type of a block
-- input port.
--
-- @class Input
-- @tparam string name Name
-- @tparam type|function data_type Data type, e.g. `radio.types.ComplexFloat32`, or a function predicate
-- @usage
-- local inputs = {radio.block.Input("in1", radio.types.ComplexFloat32),
--                 radio.block.Input("in2", radio.types.ComplexFloat32)}
-- local outputs = {...}
-- ...
-- self:add_type_signature(inputs, outputs)
local Input = class.factory()

function Input.new(name, data_type)
    local self = setmetatable({}, Input)
    self.name = name
    self.data_type = data_type
    return self
end

function Input:__tostring()
    local data_type_str = type(self.data_type) == "function" and "function" or self.data_type.type_name or self.data_type
    return string.format("%s [%s]", self.name, data_type_str)
end

---
-- Block output port descriptor. This contains the name and data type of
-- a block output port.
--
-- @class Output
-- @tparam string name Name
-- @tparam type|str data_type Data type, e.g. `radio.types.ComplexFloat32`, or "copy" to copy input data type
-- @usage
-- local inputs = {...}
-- local outputs = {radio.block.Output("out", radio.types.ComplexFloat32)}
-- ...
-- self:add_type_signature(inputs, outputs)
local Output = class.factory()

function Output.new(name, data_type)
    local self = setmetatable({}, Output)
    self.name = name
    self.data_type = data_type
    return self
end

function Output:__tostring()
    local data_type_str = self.data_type == "copy" and "copy" or self.data_type.type_name or self.data_type
    return string.format("%s [%s]", self.name, data_type_str)
end

---
-- Input port of a block. These are created in Block's add_type_signature().
--
-- @internal
-- @class
-- @tparam Block owner Block owner
-- @tparam string name Input name
local InputPort = class.factory()

function InputPort.new(owner, name)
    local self = setmetatable({}, InputPort)
    self.owner = owner
    self.name = name
    self.data_type = nil
    self.pipe = nil
    return self
end

function InputPort:__tostring()
    local data_type_str = self.data_type == nil and "n/a" or self.data_type.type_name or self.data_type
    if self.pipe then
        return string.format(".%-5s [%s] <- {%s.%s}", self.name, data_type_str, self.pipe.output.owner.name, self.pipe.output.name)
    else
        return string.format(".%-5s [%s] <- unconnected", self.name, data_type_str)
    end
end

---
-- Close input end of associated pipe.
--
-- @internal
-- @function InputPort:close
function InputPort:close()
    self.pipe:close_input()
end

---
-- Get input file descriptors of associated pipe.
--
-- @internal
-- @function InputPort:filenos
-- @treturn array Array of file descriptors
function InputPort:filenos()
    return {self.pipe:fileno_input()}
end

---
-- Output port of a block. These are created in Block's add_type_signature().
--
-- @internal
-- @class
-- @tparam Block owner Block owner
-- @tparam string name Output name
local OutputPort = class.factory()

function OutputPort.new(owner, name)
    local self = setmetatable({}, OutputPort)
    self.owner = owner
    self.name = name
    self.data_type = nil
    self.pipes = {}
    return self
end

function OutputPort:__tostring()
    local data_type_str = self.data_type == nil and "n/a" or self.data_type.type_name or self.data_type
    if #self.pipes > 0 then
        local input_strs = {}
        for _, p in ipairs(self.pipes) do
            input_strs[#input_strs + 1] = string.format("%s.%s", p.input.owner.name, p.input.name)
        end
        return string.format(".%-5s [%s] -> {%s}", self.name, data_type_str, table.concat(input_strs, ", "))
    else
        return string.format(".%-5s [%s] -> unconnected", self.name, data_type_str)
    end
end

---
-- Close output end of associated pipe.
--
-- @internal
-- @function InputPort:close
function OutputPort:close()
    for i=1, #self.pipes do
        self.pipes[i]:close_output()
    end
end

---
-- Get output file descriptors of associated pipe.
--
-- @internal
-- @function InputPort:filenos
-- @treturn array Array of file descriptors
function OutputPort:filenos()
    local fds = {}
    for i = 1, #self.pipes do
        fds[i] = self.pipes[i]:fileno_output()
    end
    return fds
end

---
-- Aliased input port of a block. These alias InputPort objects, and are
-- created in CompositeBlock's add_type_signature().
--
-- @internal
-- @class
-- @tparam Block owner Block owner
-- @tparam string name Output name
local AliasedInputPort = class.factory()

function AliasedInputPort.new(owner, name)
    local self = setmetatable({}, AliasedInputPort)
    self.owner = owner
    self.name = name
    self.data_type = nil
    return self
end

function AliasedInputPort:__tostring()
    local data_type_str = self.data_type == nil and "n/a" or self.data_type.type_name or self.data_type
    return string.format(".%-5s [%s]", self.name, data_type_str)
end

---
-- Aliased output port of a block. These alias OutputPort objects, and are
-- created in CompositeBlock's add_type_signature().
--
-- @internal
-- @class
-- @tparam Block owner Block owner
-- @tparam string name Output name
local AliasedOutputPort = class.factory()

function AliasedOutputPort.new(owner, name)
    local self = setmetatable({}, AliasedOutputPort)
    self.owner = owner
    self.name = name
    self.data_type = nil
    return self
end

function AliasedOutputPort:__tostring()
    local data_type_str = self.data_type == nil and "n/a" or self.data_type.type_name or self.data_type
    return string.format(".%-5s [%s]", self.name, data_type_str)
end

---
-- Block base class.
--
-- @class Block
local Block = class.factory()

---
-- Add a type signature.
--
-- @function Block:add_type_signature
-- @tparam array inputs Input ports, array of `radio.block.Input` instances
-- @tparam array outputs Output ports, array of `radio.block.Output` instances
-- @tparam[opt=nil] function process_func Optional process function for this
--                                        type signature, defaults to
--                                        `process()`
-- @tparam[opt=nil] function initialize_func Optional process initialization
--                                           for this type signature, defaults
--                                           to `initialize()`
-- @raise Invalid input port descriptor error.
-- @raise Invalid output port descriptor error.
-- @raise Invalid type signature, input count mismatch error.
-- @raise Invalid type signature, input name mismatch error.
-- @raise Invalid type signature, output count mismatch error.
-- @raise Invalid type signature, output name mismatch error.
function Block:add_type_signature(inputs, outputs, process_func, initialize_func)
    -- Assert inputs are Inputs
    for i = 1, #inputs do
        assert(class.isinstanceof(inputs[i], Input), string.format("Invalid input port descriptor (index %d).", i))
    end

    if not self.inputs then
        -- Create inputs with a InputPort for each input
        self.inputs = {}
        for i = 1, #inputs do
            self.inputs[i] = InputPort(self, inputs[i].name)
        end
    else
        -- Check input count
        assert(#self.inputs == #inputs, string.format("Invalid type signature, input count mismatch (got %d, expected %d).", #inputs, #self.inputs))

        -- Check input names match
        for i = 1, #inputs do
            assert(self.inputs[i].name == inputs[i].name, string.format("Invalid type signature, input name mismatch (index %d).", i))
        end
    end

    -- Assert outputs are Outputs
    for i = 1, #outputs do
        assert(class.isinstanceof(outputs[i], Output), string.format("Invalid output port descriptor (index %d).", i))
    end

    if not self.outputs then
        -- Create outputs with a OutputPort for each output
        self.outputs = {}
        for i = 1, #outputs do
            self.outputs[i] = OutputPort(self, outputs[i].name)
        end
    else
        -- Check output count
        assert(#self.outputs == #outputs, string.format("Invalid type signature, output count mismatch (got %d, expected %d).", #outputs, #self.outputs))

        -- Check output names match
        for i = 1, #outputs do
            assert(self.outputs[i].name == outputs[i].name, string.format("Invalid type signature, output name mismatch (index %d).", i))
        end
    end

    -- Add the type signature to our signatures list
    self.signatures[#self.signatures+1] = {
        inputs = inputs,
        outputs = outputs,
        initialize_func = initialize_func or self.initialize,
        process_func = process_func or self.process,
    }
end

---
-- Differentiate this block to a type signature.
--
-- @function Block:differentiate
-- @tparam array input_data_types Array of input data types
-- @raise No compatible type signatures found error.
function Block:differentiate(input_data_types)
    -- Eliminate type signature candidates that don't allow the specified input
    -- names and data types
    local signature_candidates = {}
    for _, signature in ipairs(self.signatures) do
        signature_candidates[signature] = true

        -- Compare signature input types with specified input types
        for i = 1, #signature.inputs do
            -- Compare input type with block's type signature input type
            local predicate
            if type(signature.inputs[i].data_type) == "function" then
                predicate = signature.inputs[i].data_type(input_data_types[i])
            else
                predicate = input_data_types[i] == signature.inputs[i].data_type
            end
            -- If they're incompatible, remove the signature candidate
            if not predicate then
                signature_candidates[signature] = nil
                break
            end
        end
    end

    -- If a compatible signature wasn't found
    if util.table_length(signature_candidates) ~= 1 then
        -- Build list of supplied data type at each input port
        local input_descs = {}
        for i = 1, #input_data_types do
            input_descs[i] = string.format("\"%s\": [%s]", self.signatures[1].inputs[i].name, input_data_types[i].type_name or "Unknown Type")
        end

        assert(false, string.format("No compatible type signatures found for block %s with input data types: %s.", self.name, table.concat(input_descs, ", ")))
    end

    -- Differentiate to the type signature
    self.signature, _ = next(signature_candidates)
    self.initialize = self.signature.initialize_func
    self.process = self.signature.process_func
    for i = 1, #input_data_types do
        self.inputs[i].data_type = input_data_types[i]
    end
    for i = 1, #self.signature.outputs do
        if self.signature.outputs[i].data_type == "copy" then
            self.outputs[i].data_type = input_data_types[i]
        else
            self.outputs[i].data_type = self.signature.outputs[i].data_type
        end
    end
end

---
-- Get the differentiated input data type.
--
-- @function Block:get_input_type
-- @tparam[opt=1] int index Index of input, starting at 1
-- @treturn array Array of data types
-- @raise Block not yet differentiated error.
function Block:get_input_type(index)
    assert(self.signature, "Block not yet differentiated.")

    index = index or 1

    return self.inputs[index] and self.inputs[index].data_type
end

---
-- Get the differentiated output data type.
--
-- @function Block:get_output_type
-- @tparam[opt=1] int index Index of output, starting at 1
-- @treturn data_type Data type
-- @raise Block not yet differentiated error.
function Block:get_output_type(index)
    assert(self.signature, "Block not yet differentiated.")

    index = index or 1

    return self.outputs[index] and self.outputs[index].data_type
end

---
-- Get the block rate.
--
-- @function Block:get_rate
-- @treturn number Block rate in samples per second
-- @raise Block not yet differentiated error.
function Block:get_rate()
    assert(self.signature, "Block not yet differentiated.")

    assert(#self.inputs > 0, "get_rate() not implemented for source " .. self.name .. ".")

    -- Default to copying rate from first input
    return self.inputs[1].pipe:get_rate()
end

---
-- Get a string representation with the block name and port connectivity.
--
-- @function Block:__tostring
-- @treturn string String representation
function Block:__tostring()
    if self.inputs == nil or self.outputs == nil then
        -- tostring() on class
        return self.name
    elseif self.signature == nil then
        -- tostring() on undifferentiated instance
        local strs = {}

        strs[1] = string.format("%s (undifferentiated)", self.name)

        for _, input in ipairs(self.inputs) do
            strs[#strs + 1] = "    " .. tostring(input)
        end

        for _, output in ipairs(self.outputs) do
            strs[#strs + 1] = "    " .. tostring(output)
        end

        strs[#strs + 1] = "    Type Signatures Available"

        for _, signature in ipairs(self.signatures) do
            local input_strs = {}
            for _, input in ipairs(signature.inputs) do
                input_strs[#input_strs + 1] = tostring(input)
            end

            local output_strs = {}
            for _, output in ipairs(signature.outputs) do
                output_strs[#output_strs + 1] = tostring(output)
            end

            strs[#strs + 1] = string.format("        {%s} -> {%s}", table.concat(input_strs, ", "), table.concat(output_strs, ", "))
        end

        return table.concat(strs, "\n")
    else
        -- tostring() on differentiated instance
        local strs = {}

        local rate_available, rate = pcall(function () return self:get_rate() end)
        if rate_available then
            strs[1] = string.format("%s [%.0f Hz]", self.name, rate)
        else
            strs[1] = self.name
        end

        for _, input in ipairs(self.inputs) do
            strs[#strs + 1] = "    " .. tostring(input)
        end

        for _, output in ipairs(self.outputs) do
            strs[#strs + 1] = "    " .. tostring(output)
        end

        return table.concat(strs, "\n")
    end
end

---
-- Instantiate hook, default no-op implementation.
--
-- @function Block:instantiate
function Block:instantiate()
    -- No operation
end

---
-- Initialize hook, default no-op implementation.
--
-- @function Block:initialize
function Block:initialize()
    -- No operation
end

---
-- Process hook, default implementation raises a not implemented error.
--
-- @function Block:process
function Block:process(...)
    error("process() not implemented")
end

---
-- Cleanup hook, default no-op implementation.
--
-- @function Block:cleanup
function Block:cleanup()
    -- No operation
end

---
-- Run block once. Currently used for unit testing.
--
-- @internal
-- @function Block:run_once
-- @treturn bool|nil New samples produced or nil on EOF
function Block:run_once()
    -- FIXME input pipes, output pipes, and pipe mux should really only be
    -- built once, but currently this method is only in unit testing.

    -- Gather input pipes
    local input_pipes = {}
    for i=1, #self.inputs do
        input_pipes[i] = self.inputs[i].pipe
    end

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

    -- Read inputs
    local data_in, eof, shutdown = pipe_mux:read()

    -- Check for upstream EOF or control socket shutdown
    if eof or shutdown then
        return nil
    end

    -- Process inputs into outputs
    local data_out = {self:process(unpack(data_in))}

    -- Check for block generated EOF
    if #data_out ~= #self.outputs then
        return nil
    end

    -- Write outputs
    local eof, eof_pipe, shutdown = pipe_mux:write(data_out)

    -- Check for downstream EOF or control socket shutdown
    if shutdown then
        return nil
    elseif eof then
        error(string.format("[%s] Downstream block %s terminated unexpectedly.\n", self.name, eof_pipe.input.owner.name))
    end

    -- Write outputs to pipes
    local new_samples = false
    for i=1, #self.outputs do
        new_samples = new_samples or data_out[i].length > 0
    end

    -- Return true or false if new samples were produced
    return new_samples
end

---
-- Run block until inputs reach EOF, then call cleanup().
--
-- @internal
-- @function Block:run
function Block:run()
    -- Gather input pipes
    local input_pipes = {}
    for i=1, #self.inputs do
        input_pipes[i] = self.inputs[i].pipe
    end

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
        -- Read inputs
        local data_in, eof, shutdown = pipe_mux:read()

        -- Check for upstream EOF or control socket shutdown
        if eof or shutdown then
            break
        end

        -- Process inputs into outputs
        local data_out = {self:process(unpack(data_in))}

        -- Check for block generated EOF
        if #data_out ~= #self.outputs then
            break
        end

        -- Write outputs
        local eof, eof_pipe, shutdown = pipe_mux:write(data_out)

        -- Check for downstream EOF or control socket shutdown
        if shutdown then
            break
        elseif eof then
            io.stderr:write(string.format("[%s] Downstream block %s terminated unexpectedly.\n", self.name, eof_pipe.input.owner.name))
            break
        end
    end

    debug.printf("[%s] Block pid %d terminating...\n", self.name, ffi.C.getpid())

    -- Clean up
    self:cleanup()
end

---
-- Block class factory.
--
-- @function factory
-- @tparam string name Block name
-- @tparam[opt=nil] class parent_class Inherited parent class
--
-- @usage
-- local MyBlock = radio.block.factory("MyBlock")
--
-- function MyBlock:instantiate(a, b)
--     self.param = a + b
--
--     self:add_type_signature({radio.block.Input("in", radio.types.Float32)},
--                             {radio.block.Output("out", radio.types.Float32)})
-- end
--
-- function MyBlock:initialize()
--     -- Differentiated data type and sample rate dependent initialization
-- end
--
-- function MyBlock:process(x)
--     return x
-- end
local function factory(name, parent_class)
    local class = class.factory(parent_class or Block)

    class.name = name

    class.new = function (...)
        local self = setmetatable({}, class)

        -- Pipe inputs and outputs
        self.inputs = nil
        self.outputs = nil

        -- Open files
        self.files = {[io.stdout] = true, [io.stderr] = true}

        -- Type signatures and differentiated signature
        self.signatures = {}
        self.signature = nil

        -- Disable instance call operator
        self.new = function () error("Block instance not callable") end

        self:instantiate(...)

        return self
    end

    return class
end

-- Exported module
return {Input = Input, Output = Output, InputPort = InputPort, OutputPort = OutputPort, AliasedInputPort = AliasedInputPort, AliasedOutputPort = AliasedOutputPort, Block = Block, factory = factory}
