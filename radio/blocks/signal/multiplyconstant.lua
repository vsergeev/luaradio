local block = require('radio.core.block')
local class = require('radio.core.class')
local types = require('radio.types')

local MultiplyConstantBlock = block.factory("MultiplyConstantBlock")

function MultiplyConstantBlock:instantiate(constant)
    -- Convert constant to Float32 or ComplexFloat32
    if class.isinstanceof(constant, "number") then
        self.constant = types.Float32(constant)
    elseif class.isinstanceof(constant, types.Float32) then
        self.constant = constant
    elseif class.isinstanceof(constant, types.ComplexFloat32) then
        self.constant = constant
    else
        error("Unsupported constant type.")
    end

    if class.isinstanceof(constant, types.ComplexFloat32) then
        -- Only allow complex inputs for a complex constant
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, self.process_complex_by_complex)
    else
        self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)}, self.process_float_by_float)
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, self.process_complex_by_float)
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
