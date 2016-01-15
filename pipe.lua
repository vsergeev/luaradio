require('oo')

-- PipeInput class
local PipeInput = class_factory()

function PipeInput.new(name, data_type)
    local self = setmetatable({}, PipeInput)
    self.name = name
    self.data_type = data_type
    self.owner = nil
    self.pipe = nil
    return self
end

function PipeInput:get_data_type()
    error('not implemented')
end

function PipeInput:get_rate()
    error('not implemented')
end

-- PipeOutput class
local PipeOutput = class_factory()

function PipeOutput.new(name, data_type, rate)
    local self = setmetatable({}, PipeOutput)
    self.name = name
    self.data_type = data_type
    self.owner = nil
    self.pipes = {}
    self._rate = rate
    return self
end

function PipeOutput:get_data_type()
    error('not implemented')
end

function PipeOutput:get_rate()
    error('not implemented')
end

-- InternalPipe class
local InternalPipe = class_factory()

function InternalPipe.new(pipe_output, pipe_input)
    local self = setmetatable({}, InternalPipe)
    self.output = pipe_output
    self.input = pipe_input
    self._data = nil

    pipe_output.pipes[#pipe_output.pipes + 1] = self
    pipe_input.pipe = self

    return self
end

function InternalPipe:read()
    local obj = self._data
    self._data = nil
    return obj
end

function InternalPipe:write(obj)
    self._data = obj
end


-- Exported module
return {PipeInput = PipeInput, PipeOutput = PipeOutput, InternalPipe = InternalPipe}
