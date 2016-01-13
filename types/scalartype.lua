require('types.helpers')
local AnyType = require('types.anytype').AnyType

local ScalarType = class_factory(AnyType)

function ScalarType:__add(other)
    return self.new(self.value + other.value)
end

function ScalarType:__sub(other)
    return self.new(self.value - other.value)
end

function ScalarType:__mul(other)
    return self.new(self.value * other.value)
end

function ScalarType:__div(other)
    return self.new(self.value / other.value)
end

function ScalarType:__eq(other)
    return self.value == other.value
end

return {ScalarType = ScalarType}
