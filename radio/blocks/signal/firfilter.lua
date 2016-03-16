local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local object = require('radio.core.object')
local vector = require('radio.core.vector')
local types = require('radio.types')

local FIRFilterBlock = block.factory("FIRFilterBlock")

function FIRFilterBlock:instantiate(taps)
    if object.isinstanceof(taps, vector.Vector) and taps.type == types.Float32Type then
        self.taps = taps
    elseif object.isinstanceof(taps, vector.Vector) and taps.type == types.ComplexFloat32Type then
        self.taps = taps
    else
        self.taps = types.Float32Type.vector_from_array(taps)
    end

    if self.taps.type == types.ComplexFloat32Type then
        self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)}, FIRFilterBlock.process_complex_complex)
        self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.ComplexFloat32Type)}, FIRFilterBlock.process_real_complex)
    else
        self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)}, FIRFilterBlock.process_complex_real)
        self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)}, FIRFilterBlock.process_real_real)
    end
end

function FIRFilterBlock:initialize()
    self.data_type = self.signature.inputs[1].data_type
    self.state = self.data_type.vector(self.taps.length)
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_x2_dot_prod_32fc_a)(complex_float32_t* result, const complex_float32_t* input, const complex_float32_t* taps, unsigned int num_points);
    void (*volk_32fc_32f_dot_prod_32fc_a)(complex_float32_t* result, const complex_float32_t* input, const float32_t* taps, unsigned int num_points);
    void (*volk_32f_x2_dot_prod_32f_a)(float32_t* result, const float32_t* input, const float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function FIRFilterBlock:process_complex_complex(x)
        local out = types.ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            libvolk.volk_32fc_x2_dot_prod_32fc_a(out.data[i], self.state.data, self.taps.data, self.taps.length)
        end

        return out
    end

    function FIRFilterBlock:process_real_complex(x)
        local out = types.ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            libvolk.volk_32fc_32f_dot_prod_32fc_a(out.data[i], self.taps.data, self.state.data, self.taps.length)
        end

        return out
    end

    function FIRFilterBlock:process_complex_real(x)
        local out = types.ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            libvolk.volk_32fc_32f_dot_prod_32fc_a(out.data[i], self.state.data, self.taps.data, self.taps.length)
        end

        return out
    end

    function FIRFilterBlock:process_real_real(x)
        local out = types.Float32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            libvolk.volk_32f_x2_dot_prod_32f_a(out.data[i], self.state.data, self.taps.data, self.taps.length)
        end

        return out
    end

else

    function FIRFilterBlock:process_complex_complex(x)
        local out = types.ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            for j = 0, self.state.length-1 do
                out.data[i] = out.data[i] + self.state.data[j] * self.taps.data[j]
            end
        end

        return out
    end

    function FIRFilterBlock:process_real_complex(x)
        local out = types.ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            for j = 0, self.state.length-1 do
                out.data[i] = out.data[i] + self.taps.data[j]:scalar_mul(self.state.data[j].value)
            end
        end

        return out
    end

    function FIRFilterBlock:process_complex_real(x)
        local out = types.ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            for j = 0, self.state.length-1 do
                out.data[i] = out.data[i] + self.state.data[j]:scalar_mul(self.taps.data[j].value)
            end
        end

        return out
    end

    function FIRFilterBlock:process_real_real(x)
        local out = types.Float32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps
            for j = 0, self.state.length-1 do
                out.data[i].value = out.data[i].value + self.state.data[j].value * self.taps.data[j].value
            end
        end

        return out
    end

end

return {FIRFilterBlock = FIRFilterBlock}
