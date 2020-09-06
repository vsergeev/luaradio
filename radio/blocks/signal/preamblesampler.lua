---
-- Sample a real valued signal into a fixed number of samples, by detecting a
-- preamble bit sequence at the specified baudrate. The sampling position is
-- optimized by maximizing the energy of the detected preamble.
--
-- This block assumes a zero threshold when slicing samples into bits for
-- comparison to the preamble.
--
-- $$ y[n] = \text{PreambleSampler}(x[m], \text{baudrate}, \text{preamble}, \text{num_samples}) $$
--
-- @category Digital
-- @block PreambleSamplerBlock
-- @tparam number baudrate Baudrate in symbols per second
-- @tparam Vector preamble Preamble Bit vector
-- @tparam number num_samples Number of samples per frame, including preamble
--
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Sample a 16384 baudrate data signal with the 16-bit preamble 0x16a3 into 128 samples
-- local preamble = radio.types.Bit.vector_from_array({0,0,0,1,0,1,1,0,1,0,1,0,0,0,1,1})
-- local sampler = radio.PreambleSamplerBlock(16384, preamble, 128)
-- local slicer = radio.SlicerBlock()
-- top:connect(src, sampler, slicer)

local ffi = require('ffi')

local block = require('radio.core.block')
local class = require('radio.core.class')
local vector = require('radio.core.vector')
local types = require('radio.types')
local math_utils = require('radio.utilities.math_utils')

local PreambleSamplerBlock = block.factory("PreambleSamplerBlock")

local PreambleSamplerState = {SEARCHING = 1, OPTIMIZING = 2, SAMPLING = 3}

function PreambleSamplerBlock:instantiate(baudrate, preamble, num_samples)
    self.baudrate = assert(baudrate, "Missing argument #1 (baudrate)")
    self.preamble = assert(preamble, "Missing argument #2 (preamble)")
    self.num_samples = assert(num_samples, "Missing argument #3 (frame length)")

    assert(class.isinstanceof(self.preamble, vector.Vector) and self.preamble.data_type == types.Bit,
            "Unsupported data type for argument #2 (preamble), must be a Bit vector")

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
end

function PreambleSamplerBlock:initialize()
    self.symbol_period = math.floor(self:get_rate() / self.baudrate)

    self.preamble_buffer = types.Float32.vector(2 ^ math_utils.ceil_log2(self.symbol_period * self.preamble.length + 1))
    self.preamble_buffer_index = 0
    self.preamble_buffer_index_mask = self.preamble_buffer.length - 1

    self.preamble_energy = 0
    self.state = PreambleSamplerState.SEARCHING
    self.sample_offset = 0
    self.bit_count = 0

    self.out = types.Float32.vector()
end

function PreambleSamplerBlock:compute_energy()
    local energy = 0

    for i = 0, self.preamble.length - 1 do
        local offset = bit.band(self.preamble_buffer_index + i * self.symbol_period + 1, self.preamble_buffer_index_mask)
        local value = self.preamble_buffer.data[offset].value

        local bit = value > 0 and 1 or 0
        if bit ~= self.preamble.data[i].value then
            return nil
        end

        energy = energy + math.abs(value)
    end

    return energy
end

function PreambleSamplerBlock:process(x)
    local out = self.out:resize(0)

    for i = 0, x.length-1 do
        -- Shift sample into circular buffer
        self.preamble_buffer.data[self.preamble_buffer_index].value = x.data[i].value
        self.preamble_buffer_index = bit.band(self.preamble_buffer_index + 1, self.preamble_buffer_index_mask)

        if self.state == PreambleSamplerState.SEARCHING then
            -- Compute preamble energy
            local energy = self:compute_energy()

            -- If preamble is valid
            if energy ~= nil then
                -- Switch to optimizing state
                self.state = PreambleSamplerState.OPTIMIZING
                self.preamble_energy = energy
            end
        elseif self.state == PreambleSamplerState.OPTIMIZING then
            -- Compute preamble energy
            local energy = self:compute_energy()

            -- If latest energy degraded, start sampling
            if energy == nil or energy < self.preamble_energy then
                -- Switch to sampling state
                self.state = PreambleSamplerState.SAMPLING
                self.sample_offset = self.symbol_period - 1
                self.bit_count = 1

                out:append(self.preamble_buffer.data[self.preamble_buffer_index])
            else
                -- Save preamble energy
                self.preamble_energy = energy
            end
        elseif self.state == PreambleSamplerState.SAMPLING then
            -- Decrement sample offset
            self.sample_offset = self.sample_offset - 1

            -- If sample offset reached zero
            if self.sample_offset == 0 then
                -- Reset sample offset, increment bit count
                self.sample_offset = self.symbol_period
                self.bit_count = self.bit_count + 1

                out:append(self.preamble_buffer.data[bit.band(self.preamble_buffer_index + 1, self.preamble_buffer_index_mask)])

                -- Check if we've clocked out a whole frame
                if self.bit_count == self.num_samples then
                    -- Switch back to searching state
                    self.state = PreambleSamplerState.SEARCHING
                end
            end
        end
    end

    return out
end

return PreambleSamplerBlock
