---
-- Add a real-valued constant to a complex or real valued signal, or a
-- complex-valued constant to a complex-valued signal.
--
-- $$ y[n] = x[n] + C $$
--
-- @category Math Operations
-- @block AddConstantBlock
-- @tparam number|Float32|ComplexFloat32 constant Constant
--
-- @signature in:Float32 > out:Float32
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- Add a number (Float32) constant
-- local addconstant = radio.AddConstantBlock(1.0)
--
-- -- Add a Float32 constant
-- local addconstant = radio.AddConstantBlock(radio.types.Float32(1.0))
--
-- -- Add a ComplexFloat32 constant
-- local addconstant = radio.AddConstantBlock(radio.types.ComplexFloat32(1.0))

local block = require('radio.core.block')
local class = require('radio.core.class')
local types = require('radio.types')

local AddConstantBlock = block.factory("AddConstantBlock")

function AddConstantBlock:instantiate(constant)
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

function AddConstantBlock:initialize()
    self.out = self:get_output_type().vector()
end

function AddConstantBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length - 1 do
        out.data[i] = x.data[i] + self.constant
    end

    return out
end

function AddConstantBlock:process_complex_by_real(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length - 1 do
        out.data[i] = types.ComplexFloat32(x.data[i].real + self.constant.value, x.data[i].imag)
    end

    return out
end

return AddConstantBlock
