---
-- Support classes for creating blocks.
--
-- @module radio.block

local class = require('radio.core.class')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

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

---
-- Block output port descriptor. This contains the name and data type of
-- a block output port.
--
-- @class Output
-- @tparam string name Name
-- @tparam type data_type|str Data type, e.g. `radio.types.ComplexFloat32`, or "copy" to copy input data type
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
        -- Create inputs with a PipeInput for each input
        self.inputs = {}
        for i = 1, #inputs do
            self.inputs[i] = pipe.PipeInput(self, inputs[i].name)
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
        -- Create outputs with a PipeOutput for each output
        self.outputs = {}
        for i = 1, #outputs do
            self.outputs[i] = pipe.PipeOutput(self, outputs[i].name)
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
    -- tostring() on class
    if self.inputs == nil or self.outputs == nil then
        return self.name
    end

    -- tostring() on class instance
    local s = self.signature and string.format("%s [%.0f Hz]", self.name, self:get_rate()) or self.name

    local strs = {}

    for i=1, #self.inputs do
        if self.inputs[i].pipe then
            local pipe = self.inputs[i].pipe or self.inputs[i].real_input.pipe
            if pipe then
                strs[#strs + 1] = string.format("    .%-5s [%s] <- {%s.%s}", self.inputs[i].name, self.inputs[i].data_type and self.inputs[i].data_type.type_name or "Unknown Type", pipe.pipe_output.owner.name, pipe.pipe_output.name)
            else
                strs[#strs + 1] = string.format("    .%-5s <- unconnected", self.inputs[i].name)
            end
        end
    end

    for i=1, #self.outputs do
        local pipes = self.outputs[i].pipes or self.outputs[i].real_output.pipes
        if #pipes > 0 then
            local connections = {}
            for i=1, #pipes do
                connections[i] = string.format("%s.%s", pipes[i].pipe_input.owner.name, pipes[i].pipe_input.name)
            end
            strs[#strs + 1] = string.format("    .%-5s [%s] -> {%s}", self.outputs[i].name, self.outputs[i].data_type and self.outputs[i].data_type.type_name or "Unknown Type", table.concat(connections, ", "))
        else
            strs[#strs + 1] = string.format("    .%-5s -> unconnected", self.outputs[i].name)
        end
    end

    s = s .. "\n" .. table.concat(strs, "\n")

    return s
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
-- Run block once.
--
-- @internal
-- @function Block:run_once
-- @treturn bool New samples produced
function Block:run_once()
    local data_out

    -- Process inputs into outputs
    if #self.inputs == 0 then
        -- No inputs (source)

        -- Process
        data_out = {self:process()}

        -- Check for EOF
        if #data_out == 0 then
            return nil
        end
    elseif #self.inputs == 1 then
        -- One input

        -- Read input
        local data_in = self.inputs[1].pipe:read()

        -- Check for EOF
        if data_in == nil then
            return nil
        end

        -- Process
        data_out = {self:process(data_in)}
    else
        -- Multiple inputs

        -- Gather input pipes
        local pipes = {}
        for i=1, #self.inputs do
            pipes[i] = self.inputs[i].pipe
        end

        -- Synchronous read across all inputs
        local data_in = pipe.read_synchronous(pipes)
        -- Check for EOF
        if data_in == nil then
            return nil
        end

        -- Process
        data_out = {self:process(unpack(data_in))}
    end

    -- Write outputs to pipes
    local new_samples = false
    for i=1, #self.outputs do
        new_samples = new_samples or data_out[i].length > 0
        for j=1, #self.outputs[i].pipes do
            self.outputs[i].pipes[j]:write(data_out[i])
        end
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
    if #self.inputs == 0 then
        -- No inputs (source)

        while true do
            -- Process
            data_out = {self:process()}

            -- Check for EOF
            if #data_out == 0 then
                break
            end

            -- Write outputs to pipes
            for i=1, #self.outputs do
                for j=1, #self.outputs[i].pipes do
                    self.outputs[i].pipes[j]:write(data_out[i])
                end
            end
        end
    elseif #self.inputs == 1 then
        -- One input

        while true do
            -- Read input
            local data_in = self.inputs[1].pipe:read()

            -- Check for EOF
            if data_in == nil then
                break
            end

            -- Process
            data_out = {self:process(data_in)}

            -- Write outputs to pipes
            for i=1, #self.outputs do
                for j=1, #self.outputs[i].pipes do
                    self.outputs[i].pipes[j]:write(data_out[i])
                end
            end
        end
    else
        -- Multiple inputs

        -- Gather input pipes
        local input_pipes = {}
        for i=1, #self.inputs do
            input_pipes[i] = self.inputs[i].pipe
        end

        while true do
            -- Synchronous read across all inputs
            local data_in = pipe.read_synchronous(input_pipes)

            -- Check for EOF
            if data_in == nil then
                break
            end

            -- Process
            data_out = {self:process(unpack(data_in))}

            -- Write outputs to pipes
            for i=1, #self.outputs do
                for j=1, #self.outputs[i].pipes do
                    self.outputs[i].pipes[j]:write(data_out[i])
                end
            end
        end
    end

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
return {Input = Input, Output = Output, Block = Block, factory = factory}
