local block = require('radio.core.block')
local class = require('radio.core.class')
local types = require('radio.types')

local AddConstantBlock = block.factory("AddConstantBlock")

function AddConstantBlock:instantiate(constant)
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
        self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)}, self.process_real_by_real)
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, self.process_complex_by_real)
    end
end

function AddConstantBlock:process_complex_by_complex(x)
    local out = types.ComplexFloat32.vector(x.length)

    for i = 0, x.length - 1 do
        out.data[i] = x.data[i] + self.constant
    end

    return out
end

function AddConstantBlock:process_real_by_real(x)
    local out = types.Float32.vector(x.length)

    for i = 0, x.length - 1 do
        out.data[i] = x.data[i] + self.constant
    end

    return out
end

function AddConstantBlock:process_complex_by_real(x)
    local out = types.ComplexFloat32.vector(x.length)

    for i = 0, x.length - 1 do
        out.data[i] = types.ComplexFloat32(x.data[i].real + self.constant.value, x.data[i].imag)
    end

    return out
end

return AddConstantBlock
