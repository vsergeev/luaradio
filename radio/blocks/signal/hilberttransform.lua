---
-- Hilbert transform a real-valued signal into a complex-valued signal with a
-- windowed FIR approximation of the IIR Hilbert transform filter.
--
-- $$ y[n] = x[n-N/2] + j \, (x * h_{hilb})[n] $$
--
-- @category Spectrum Manipulation
-- @block HilbertTransformBlock
-- @tparam number num_taps Number of FIR taps, must be odd
-- @tparam[opt='hamming'] string window Window type
--
-- @signature in:Float32 > out:ComplexFloat32
--
-- @usage
-- -- Hilbert transform with 129 taps
-- local ht = radio.HilbertTransformBlock(129)

local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.utilities.filter_utils')

local HilbertTransformBlock = block.factory("HilbertTransformBlock")

function HilbertTransformBlock:instantiate(num_taps, window)
    assert(num_taps, "Missing argument #1 (num_taps)")
    assert((num_taps % 2) == 1, "Number of taps must be odd")
    window = window or "hamming"

    -- Generate Hilbert transform taps
    local taps = filter_utils.fir_hilbert_transform(num_taps, window)
    self.hilbert_taps = types.Float32.vector_from_array(taps)

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

if platform.features.liquid then

    ffi.cdef[[
    typedef struct dotprod_rrrf_s * dotprod_rrrf;
    dotprod_rrrf dotprod_rrrf_create(float32_t *_v, unsigned int _n);
    void dotprod_rrrf_destroy(dotprod_rrrf _q);

    void dotprod_rrrf_execute(dotprod_rrrf _q, float32_t *_x, float32_t *_y);
    ]]
    local libliquid = platform.libs.liquid

    function HilbertTransformBlock:initialize()
        -- Reverse taps
        local reversed_taps = self.hilbert_taps.data_type.vector(self.hilbert_taps.length)
        for i = 0, self.hilbert_taps.length-1 do
            reversed_taps.data[i] = self.hilbert_taps.data[self.hilbert_taps.length-1-i]
        end
        self.hilbert_taps = reversed_taps

        self.dotprod = ffi.gc(libliquid.dotprod_rrrf_create(self.hilbert_taps.data, self.hilbert_taps.length), libliquid.dotprod_rrrf_destroy)
        if self.dotprod == nil then
            error("Creating liquid dotprod object.")
        end

        self.state = types.Float32.vector(self.hilbert_taps.length)
        self.out = types.ComplexFloat32.vector()
    end

    function HilbertTransformBlock:process(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.hilbert_taps.length - 1)], (self.hilbert_taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.hilbert_taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.hilbert_taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        -- Compute output
        for i = 0, x.length-1 do
            -- Delayed input
            out.data[i].real = self.state.data[(self.hilbert_taps.length-1)/2 + i].value

            -- Inner product of state and taps
            libliquid.dotprod_rrrf_execute(self.dotprod, self.state.data[i], ffi.cast("float32_t *", out.data[i]) + 1)
        end

        return out
    end

elseif platform.features.volk then

    function HilbertTransformBlock:initialize()
        -- Reverse taps
        local reversed_taps = self.hilbert_taps.data_type.vector(self.hilbert_taps.length)
        for i = 0, self.hilbert_taps.length-1 do
            reversed_taps.data[i] = self.hilbert_taps.data[self.hilbert_taps.length-1-i]
        end
        self.hilbert_taps = reversed_taps

        self.state = types.Float32.vector(self.hilbert_taps.length)
        self.out = types.ComplexFloat32.vector()
    end

    ffi.cdef[[
    void (*volk_32f_x2_dot_prod_32f)(float32_t* result, const float32_t* input, const float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function HilbertTransformBlock:process(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.hilbert_taps.length - 1)], (self.hilbert_taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.hilbert_taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.hilbert_taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        -- Compute output
        for i = 0, x.length-1 do
            -- Delayed input
            out.data[i].real = self.state.data[(self.hilbert_taps.length-1)/2 + i].value

            -- Inner product of state and taps
            libvolk.volk_32f_x2_dot_prod_32f(ffi.cast("float32_t *", out.data[i]) + 1, self.state.data[i], self.hilbert_taps.data, self.hilbert_taps.length)
        end

        return out
    end

else

    function HilbertTransformBlock:initialize()
        -- Reverse taps
        local reversed_taps = self.hilbert_taps.data_type.vector(self.hilbert_taps.length)
        for i = 0, self.hilbert_taps.length-1 do
            reversed_taps.data[i] = self.hilbert_taps.data[self.hilbert_taps.length-1-i]
        end
        self.hilbert_taps = reversed_taps

        self.state = types.Float32.vector(self.hilbert_taps.length)
        self.out = types.ComplexFloat32.vector()
    end

    function HilbertTransformBlock:process(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.hilbert_taps.length - 1)], (self.hilbert_taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.hilbert_taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.hilbert_taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        -- Compute output
        for i = 0, x.length-1 do
            -- Delayed input
            out.data[i].real = self.state.data[(self.hilbert_taps.length-1)/2 + i].value

            -- Inner product of state and taps
            out.data[i].imag = 0.0
            for j = 0, self.hilbert_taps.length-1 do
                out.data[i].imag = out.data[i].imag + self.state.data[i + j].value*self.hilbert_taps.data[j].value
            end
        end

        return out
    end

end

return HilbertTransformBlock
