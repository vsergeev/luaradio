---
-- Filter a complex or real valued signal with an FIR filter.
--
-- $$ y[n] = (x * h)[n] $$
-- $$ y[n] = b_0 x[n] + b_1 x[n-1] + ... + b_N x[n-N] $$
--
-- @category Filtering
-- @block FIRFilterBlock
-- @tparam array|vector taps Real-valued taps specified with a number array or
--                           a Float32 vector, or complex-valued taps specified
--                           with a ComplexFloat32 vector
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Moving average FIR filter with 5 real taps
-- local filter = radio.FIRFilterBlock({1/5, 1/5, 1/5, 1/5, 1/5})
--
-- -- Moving average FIR filter with 5 real taps
-- local taps = radio.types.Float32.vector({1/5, 1/5, 1/5, 1/5, 1/5})
-- local filter = radio.FIRFilterBlock(taps)
--
-- -- FIR filter with 3 complex taps
-- local taps = radio.types.ComplexFloat32.vector({{1, 1}, {0.5, 0.5}, {0.25, 0.25}})
-- local filter = radio.FIRFilterBlock(taps)

local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local class = require('radio.core.class')
local vector = require('radio.core.vector')
local types = require('radio.types')

local FIRFilterBlock = block.factory("FIRFilterBlock")

function FIRFilterBlock:instantiate(taps)
    assert(taps, "Missing argument #1 (taps)")
    if class.isinstanceof(taps, vector.Vector) and taps.data_type == types.Float32 then
        self.taps = taps
    elseif class.isinstanceof(taps, vector.Vector) and taps.data_type == types.ComplexFloat32 then
        self.taps = taps
    elseif class.isinstanceof(taps, "table") then
        self.taps = types.Float32.vector_from_array(taps)
    else
        error("Unsupported taps type")
    end

    if self.taps.data_type == types.ComplexFloat32 then
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, FIRFilterBlock.process_complex_input_complex_taps)
    else
        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, FIRFilterBlock.process_complex_input_real_taps)
        self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)}, FIRFilterBlock.process_real_input_real_taps)
    end
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
void *memcpy(void *dest, const void *src, size_t n);
]]

if platform.features.volk then

    function FIRFilterBlock:initialize()
        local data_type = self:get_input_type()

        -- Reverse taps
        local reversed_taps = self.taps.data_type.vector(self.taps.length)
        for i = 0, self.taps.length-1 do
            reversed_taps.data[i] = self.taps.data[self.taps.length-1-i]
        end
        self.taps = reversed_taps

        self.state = data_type.vector(self.taps.length)
        self.out = data_type.vector()
    end

    ffi.cdef[[
    void (*volk_32fc_x2_dot_prod_32fc)(complex_float32_t* result, const complex_float32_t* input, const complex_float32_t* taps, unsigned int num_points);
    void (*volk_32fc_32f_dot_prod_32fc)(complex_float32_t* result, const complex_float32_t* input, const float32_t* taps, unsigned int num_points);
    void (*volk_32f_x2_dot_prod_32f)(float32_t* result, const float32_t* input, const float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function FIRFilterBlock:process_complex_input_complex_taps(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            libvolk.volk_32fc_x2_dot_prod_32fc(out.data[i], self.state.data[i], self.taps.data, self.taps.length)
        end

        return out
    end

    function FIRFilterBlock:process_complex_input_real_taps(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            libvolk.volk_32fc_32f_dot_prod_32fc(out.data[i], self.state.data[i], self.taps.data, self.taps.length)
        end

        return out
    end

    function FIRFilterBlock:process_real_input_real_taps(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            libvolk.volk_32f_x2_dot_prod_32f(out.data[i], self.state.data[i], self.taps.data, self.taps.length)
        end

        return out
    end

elseif platform.features.liquid then

    ffi.cdef[[
    typedef struct firfilt_crcf_s * firfilt_crcf;
    firfilt_crcf firfilt_crcf_create(float32_t *_h, unsigned int _n);
    void firfilt_crcf_destroy(firfilt_crcf _q);

    typedef struct firfilt_rrrf_s * firfilt_rrrf;
    firfilt_rrrf firfilt_rrrf_create(float32_t *_h, unsigned int _n);
    void firfilt_rrrf_destroy(firfilt_rrrf _q);

    typedef struct firfilt_cccf_s * firfilt_cccf;
    firfilt_cccf firfilt_cccf_create(complex_float32_t *_h, unsigned int _n);
    void firfilt_cccf_destroy(firfilt_cccf _q);

    void firfilt_crcf_execute_block(firfilt_crcf _q, const complex_float32_t *_x, unsigned int _n, complex_float32_t *_y);
    void firfilt_rrrf_execute_block(firfilt_rrrf _q, const float32_t *_x, unsigned int _n, float32_t *_y);
    void firfilt_cccf_execute_block(firfilt_cccf _q, const complex_float32_t *_x, unsigned int _n, complex_float32_t *_y);
    ]]
    local libliquid = platform.libs.liquid

    function FIRFilterBlock:initialize()
        local data_type = self:get_input_type()

        if data_type == types.ComplexFloat32 and self.taps.data_type == types.Float32 then
            self.filter = ffi.gc(libliquid.firfilt_crcf_create(self.taps.data, self.taps.length), libliquid.firfilt_crcf_destroy)
        elseif data_type == types.Float32 and self.taps.data_type == types.Float32 then
            self.filter = ffi.gc(libliquid.firfilt_rrrf_create(self.taps.data, self.taps.length), libliquid.firfilt_rrrf_destroy)
        elseif data_type == types.ComplexFloat32 and self.taps.data_type == types.ComplexFloat32 then
            self.filter = ffi.gc(libliquid.firfilt_cccf_create(self.taps.data, self.taps.length), libliquid.firfilt_cccf_destroy)
        end

        if self.filter == nil then
            error("Creating liquid firfilt object.")
        end

        self.out = data_type.vector()
    end

    function FIRFilterBlock:process_complex_input_real_taps(x)
        local out = self.out:resize(x.length)

        libliquid.firfilt_crcf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

    function FIRFilterBlock:process_real_input_real_taps(x)
        local out = self.out:resize(x.length)

        libliquid.firfilt_rrrf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

    function FIRFilterBlock:process_complex_input_complex_taps(x)
        local out = self.out:resize(x.length)

        libliquid.firfilt_cccf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

else

    function FIRFilterBlock:initialize()
        local data_type = self:get_input_type()

        -- Reverse taps
        local reversed_taps = self.taps.data_type.vector(self.taps.length)
        for i = 0, self.taps.length-1 do
            reversed_taps.data[i] = self.taps.data[self.taps.length-1-i]
        end
        self.taps = reversed_taps

        self.state = data_type.vector(self.taps.length)
        self.out = data_type.vector()
    end

    function FIRFilterBlock:process_complex_input_complex_taps(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            out.data[i] = types.ComplexFloat32()
            for j = 0, self.taps.length-1 do
                out.data[i] = out.data[i] + self.state.data[i+j] * self.taps.data[j]
            end
        end

        return out
    end

    function FIRFilterBlock:process_complex_input_real_taps(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            out.data[i] = types.ComplexFloat32()
            for j = 0, self.taps.length-1 do
                out.data[i] = out.data[i] + self.state.data[i+j]:scalar_mul(self.taps.data[j].value)
            end
        end

        return out
    end

    function FIRFilterBlock:process_real_input_real_taps(x)
        local out = self.out:resize(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            out.data[i] = types.Float32()
            for j = 0, self.taps.length-1 do
                out.data[i] = out.data[i] + self.state.data[i+j] * self.taps.data[j]
            end
        end

        return out
    end

end

return FIRFilterBlock
