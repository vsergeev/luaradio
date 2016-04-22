---
-- Multiply a complex or real valued signal by a real-valued constant, or
-- multiply a complex-valued signal by a complex-valued constant.
--
-- $$ y[n] = C \; x[n] $$
--
-- @category Math Operations
-- @block MultiplyConstantBlock
-- @tparam number|Float32|ComplexFloat32 constant Constant
--
-- @signature in:Float32 > out:Float32
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- Multiply by number (Float32) constant
-- local gain = radio.MultiplyConstantBlock(5.0)
--
-- -- Multiply by Float32 constant
-- local gain = radio.MultiplyConstantBlock(radio.types.Float32(5.0))
--
-- -- Complex rotation by 45 degrees
-- local rotator = radio.MultiplyConstantBlock(radio.types.ComplexFloat32(math.cos(math.pi/4), math.sin(math.pi/4)))

local block = require('radio.core.block')
local class = require('radio.core.class')
local types = require('radio.types')

local MultiplyConstantBlock = block.factory("MultiplyConstantBlock")

function MultiplyConstantBlock:instantiate(constant)
    assert(constant, "Missing argument #1 (constant)")
    -- Convert constant to Float32 or ComplexFloat32
    if class.isinstanceof(constant, "number") then
        self.constant = types.Float32(constant)
    elseif class.isinstanceof(constant, types.Float32) then
        self.constant = constant
    elseif class.isinstanceof(constant, types.ComplexFloat32) then
        self.constant = constant
    else
        error("Unsupported constant type")
    end

    if class.isinstanceof(constant, types.ComplexFloat32) then
        -- Only allow complex inputs for a complex constant
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    else
        self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, self.process_complex_by_real)
    end
end

function MultiplyConstantBlock:initialize()
    self.out = self:get_output_type().vector()
end

function MultiplyConstantBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length - 1 do
        out.data[i] = x.data[i] * self.constant
    end

    return out
end

function MultiplyConstantBlock:process_complex_by_real(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length - 1 do
        out.data[i] = x.data[i]:scalar_mul(self.constant.value)
    end

    return out
end

return MultiplyConstantBlock
