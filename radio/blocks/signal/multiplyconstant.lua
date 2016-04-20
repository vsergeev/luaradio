local block = require('radio.core.block')
local object = require('radio.core.object')
local types = require('radio.types')

local MultiplyConstantBlock = block.factory("MultiplyConstantBlock")

function MultiplyConstantBlock:instantiate(constant)
    -- Convert constant to Float32Type or ComplexFloat32Type
    if object.isinstanceof(constant, "number") then
        self.constant = types.Float32Type(constant)
    elseif object.isinstanceof(constant, types.Float32Type) then
        self.constant = constant
    elseif object.isinstanceof(constant, types.ComplexFloat32Type) then
        self.constant = constant
    else
        error("Unsupported constant type.")
    end

    if object.isinstanceof(constant, types.ComplexFloat32Type) then
        -- Only allow complex inputs for a complex constant
        self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)}, self.process_complex_by_complex)
    else
        self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)}, self.process_float_by_float)
        self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)}, self.process_complex_by_float)
    end
end

function MultiplyConstantBlock:initialize()
    self.data_type = self:get_input_types()[1]
end

function MultiplyConstantBlock:process_complex_by_complex(x)
    local out = self.data_type.vector(x.length)
    for i = 0, x.length - 1 do
        out.data[i] = x.data[i] * self.constant
    end
    return out
end

function MultiplyConstantBlock:process_float_by_float(x)
    local out = self.data_type.vector(x.length)
    for i = 0, x.length - 1 do
        out.data[i] = x.data[i] * self.constant
    end
    return out
end

function MultiplyConstantBlock:process_complex_by_float(x)
    local out = self.data_type.vector(x.length)
    for i = 0, x.length - 1 do
        out.data[i] = x.data[i]:scalar_mul(self.constant.value)
    end
    return out
end

return MultiplyConstantBlock
