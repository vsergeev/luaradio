local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local HilbertTransformBlock = block.factory("HilbertTransformBlock")

function HilbertTransformBlock:instantiate(num_taps, window_type)
    assert((num_taps % 2) == 1, "Hilbert taps must be odd.")

    -- Default to hamming window
    window_type = (window_type == nil) and "hamming" or window_type

    -- Generate Hilbert transform taps
    local h = filter_utils.fir_hilbert_transform(num_taps, window_type)
    self.hilbert_taps = types.Float32Type.vector(num_taps)
    for i = 0, num_taps-1 do
        self.hilbert_taps.data[i].value = h[i+1]
    end

    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.ComplexFloat32Type)})
end

function HilbertTransformBlock:initialize()
    self.state = types.Float32Type.vector(self.hilbert_taps.length)

    -- Reverse taps
    local reversed_taps = self.hilbert_taps.type.vector(self.hilbert_taps.length)
    for i = 0, self.hilbert_taps.length-1 do
        reversed_taps.data[i] = self.hilbert_taps.data[self.hilbert_taps.length-1-i]
    end
    self.hilbert_taps = reversed_taps
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32f_x2_dot_prod_32f)(float32_t* result, const float32_t* input, const float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function HilbertTransformBlock:process(x)
        local out = types.ComplexFloat32Type.vector(x.length)

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

  function HilbertTransformBlock:process(x)
        local out = types.ComplexFloat32Type.vector(x.length)

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
            for j = 0, self.hilbert_taps.length-1 do
                out.data[i].imag = out.data[i].imag + self.state.data[i + j].value*self.hilbert_taps.data[j].value
            end
        end

        return out
    end

end

return HilbertTransformBlock
