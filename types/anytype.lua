local object = require('object')

local AnyType = object.class_factory()

function AnyType.new()
    error('Type is abstract and cannot be constructed.')
end

function AnyType:isabstract()
    return self.new == AnyType.new
end

function AnyType:isconcrete()
    return not self:isabstract()
end

function AnyType:__tostring()
    error('tostring not implemented.')
end

return {AnyType = AnyType}
