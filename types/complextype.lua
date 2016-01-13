local math = require('math')

require('types.helpers')
local AnyType = require('types.anytype').AnyType

local ComplexType = class_factory(AnyType)

function ComplexType:__add(other)
    return self.new(self.real + other.real, self.imag + other.imag)
end

function ComplexType:__sub(other)
    return self.new(self.real - other.real, self.imag - other.imag)
end

function ComplexType:__mul(other)
    return self.new(self.real * other.value, self.imag * other.value)
end

function ComplexType:__div(other)
    local real = (self.real * other.real + self.imag * other.imag) / (other.real * other.real + other.imag * other.imag)
    local imag = (self.imag * other.real - self.real * other.imag) / (other.real * other.real + other.imag * other.imag)
    return self.new(real, imag)
end

function ComplexType:__eq(other)
    return self.real == other.real and self.imag == other.imag
end

function ComplexType:scalar_mul(other)
    return self.new(self.real * other, self.imag * other)
end

function ComplexType:scalar_div(other)
    return self.new(self.real / value, self.imag / value)
end

function ComplexType:arg()
    return math.atan2(self.imag, self.real)
end

function ComplexType:abs()
    return math.sqrt(self.real*self.real + self.imag*self.imag)
end

function ComplexType:conj()
    return self.new(self.real, -self.imag)
end

return {ComplexType = ComplexType}
