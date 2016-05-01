local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local class = require('radio.core.class')
local vector = require('radio.core.vector')
local types = require('radio.types')

local FIRFilterBlock = block.factory("FIRFilterBlock")

function FIRFilterBlock:instantiate(taps)
    if class.isinstanceof(taps, vector.Vector) and taps.type == types.Float32 then
        self.taps = taps
    elseif class.isinstanceof(taps, vector.Vector) and taps.type == types.ComplexFloat32 then
        self.taps = taps
    else
        self.taps = types.Float32.vector_from_array(taps)
    end

    if self.taps.type == types.ComplexFloat32 then
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
        self.data_type = self:get_input_types()[1]
        self.state = self.data_type.vector(self.taps.length)

        -- Reverse taps
        local reversed_taps = self.taps.type.vector(self.taps.length)
        for i = 0, self.taps.length-1 do
            reversed_taps.data[i] = self.taps.data[self.taps.length-1-i]
        end
        self.taps = reversed_taps
    end

    ffi.cdef[[
    void (*volk_32fc_x2_dot_prod_32fc)(complex_float32_t* result, const complex_float32_t* input, const complex_float32_t* taps, unsigned int num_points);
    void (*volk_32fc_32f_dot_prod_32fc)(complex_float32_t* result, const complex_float32_t* input, const float32_t* taps, unsigned int num_points);
    void (*volk_32f_x2_dot_prod_32f)(float32_t* result, const float32_t* input, const float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function FIRFilterBlock:process_complex_input_complex_taps(x)
        local out = types.ComplexFloat32.vector(x.length)

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
        local out = types.ComplexFloat32.vector(x.length)

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
        local out = types.Float32.vector(x.length)

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
        local data_type = self:get_input_types()[1]

        if data_type == types.ComplexFloat32 and self.taps.type == types.Float32 then
            self.filter = ffi.gc(libliquid.firfilt_crcf_create(self.taps.data, self.taps.length), libliquid.firfilt_crcf_destroy)
        elseif data_type == types.Float32 and self.taps.type == types.Float32 then
            self.filter = ffi.gc(libliquid.firfilt_rrrf_create(self.taps.data, self.taps.length), libliquid.firfilt_rrrf_destroy)
        elseif data_type == types.ComplexFloat32 and self.taps.type == types.ComplexFloat32 then
            self.filter = ffi.gc(libliquid.firfilt_cccf_create(self.taps.data, self.taps.length), libliquid.firfilt_cccf_destroy)
        end

        if self.filter == nil then
            error("Creating liquid firfilt object.")
        end
    end

    function FIRFilterBlock:process_complex_input_real_taps(x)
        local out = types.ComplexFloat32.vector(x.length)

        libliquid.firfilt_crcf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

    function FIRFilterBlock:process_real_input_real_taps(x)
        local out = types.Float32.vector(x.length)

        libliquid.firfilt_rrrf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

    function FIRFilterBlock:process_complex_input_complex_taps(x)
        local out = types.ComplexFloat32.vector(x.length)

        libliquid.firfilt_cccf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

else

    function FIRFilterBlock:initialize()
        self.data_type = self:get_input_types()[1]
        self.state = self.data_type.vector(self.taps.length)

        -- Reverse taps
        local reversed_taps = self.taps.type.vector(self.taps.length)
        for i = 0, self.taps.length-1 do
            reversed_taps.data[i] = self.taps.data[self.taps.length-1-i]
        end
        self.taps = reversed_taps
    end

    function FIRFilterBlock:process_complex_input_complex_taps(x)
        local out = types.ComplexFloat32.vector(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            for j = 0, self.taps.length-1 do
                out.data[i] = out.data[i] + self.state.data[i+j] * self.taps.data[j]
            end
        end

        return out
    end

    function FIRFilterBlock:process_complex_input_real_taps(x)
        local out = types.ComplexFloat32.vector(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            for j = 0, self.taps.length-1 do
                out.data[i] = out.data[i] + self.state.data[i+j]:scalar_mul(self.taps.data[j].value)
            end
        end

        return out
    end

    function FIRFilterBlock:process_real_input_real_taps(x)
        local out = types.Float32.vector(x.length)

        -- Shift last taps_length-1 state samples to the beginning of state
        ffi.C.memmove(self.state.data, self.state.data[self.state.length - (self.taps.length - 1)], (self.taps.length-1)*ffi.sizeof(self.state.data[0]))
        -- Adjust state vector length for the input
        self.state:resize(self.taps.length - 1 + x.length)
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.taps.length-1], x.data, x.length*ffi.sizeof(self.state.data[0]))

        for i = 0, x.length-1 do
            -- Inner product of state and taps
            for j = 0, self.taps.length-1 do
                out.data[i].value = out.data[i].value + self.state.data[i+j].value * self.taps.data[j].value
            end
        end

        return out
    end

end

return FIRFilterBlock
