local table = require('table')

require('oo')

-- PipeInput class
local PipeInput = class_factory()

function PipeInput.new(name, data_type)
    local self = setmetatable({}, PipeInput)
    self.name = name
    self.data_type = data_type
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

function InternalPipe.new(producer, consumer)
    local self = setmetatable({}, InternalPipe)
    self.producer = producer
    self.consumer = consumer
    self._data = {}
    return self
end

function InternalPipe:read()
    return table.remove(self._data, 1)
end

function InternalPipe:write(obj)
    table.insert(self._data, obj)
end

function InternalPipe:has_data()
    return #self._data > 0
end

-- Exported module
return {PipeInput = PipeInput, PipeOutput = PipeOutput, InternalPipe = InternalPipe}
