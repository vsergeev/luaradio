---
-- Upsample a complex or real valued signal. This block increases the sample
-- rate for downstream blocks in the flow graph by a factor of L.
--
-- $$ y[n] = \begin{cases} x[n/L] & \text{for integer } n/L \\ 0 & \text{otherwise} \end{cases} $$
--
-- Note: this block performs no scaling or anti-alias filtering. Use the
-- [`InterpolatorBlock`](#interpolatorblock) for signal interpolation with
-- scaling and anti-alias filtering.
--
-- @category Sample Rate Manipulation
-- @block UpsamplerBlock
-- @tparam int factor Upsampling factor L
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Upsample by 5
-- local upsampler = radio.UpsamplerBlock(5)

local block = require('radio.core.block')
local types = require('radio.types')

local UpsamplerBlock = block.factory("UpsamplerBlock")

function UpsamplerBlock:instantiate(factor)
    self.factor = assert(factor, "Missing argument #1 (factor)")

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
end

function UpsamplerBlock:initialize()
    self.out = self:get_output_type().vector()
end

function UpsamplerBlock:get_rate()
    return block.Block.get_rate(self)*self.factor
end

function UpsamplerBlock:process(x)
    local out = self.out:resize(x.length*self.factor)

    for i = 0, x.length-1 do
        out.data[i*self.factor] = x.data[i]
    end

    return out
end

return UpsamplerBlock
