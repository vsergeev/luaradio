local table = require('table')

local callable_mt = {__call = function(self, ...) return self.new(...) end}

-- PipeInput class
local PipeInput = setmetatable({}, callable_mt)
PipeInput.__index = PipeInput

function PipeInput.new(name, data_type)
    local self = setmetatable({}, PipeInput)
    self.name = name
    self.data_type = data_type
    self.pipe = nil
    return self
end

-- PipeOutput class
local PipeOutput = setmetatable({}, callable_mt)
PipeOutput.__index = PipeOutput

function PipeOutput.new(name, data_type, rate)
    local self = setmetatable({}, PipeOutput)
    self.name = name
    self.data_type = data_type
    self.pipes = {}
    self._rate = rate
    return self
end

function PipeOutput:get_rate()
    if type(self._rate) == "function" then
        return self._rate()
    end
    return self._rate
end

-- InternalPipe class
local InternalPipe = setmetatable({}, callable_mt)
InternalPipe.__index = InternalPipe

function InternalPipe.new(src, dst)
    local self = setmetatable({}, InternalPipe)
    self.src = src
    self.dst = dst
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
