---
-- Filter a complex or real valued signal with an IIR filter.
--
-- $$ y[n] = (x * h)[n] $$
--
-- $$ \begin{align} y[n] = &\frac{1}{a_0}(b_0 x[n] + b_1 x[n-1] + ... + b_N x[n-N] \\ - &a_1 y[n-1] - a_2 y[n-2] - ... - a_M x[n-M])\end{align} $$
--
-- @category Filtering
-- @block IIRFilterBlock
-- @tparam array|vector b_taps Real-valued feedforward taps specified with a
--                             number array or a Float32 vector
-- @tparam array|vector a_taps Real-valued feedback taps specified with a
--                             number array or a Float32 vector, must be at
--                             least length 1
--
-- @signature in:Float32 > out:Float32
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- 2nd order Butterworth IIR filter, Wn=0.1
-- local filter = radio.IIRFilterBlock({0.02008337,  0.04016673,  0.02008337},
--                                     {1, -1.56101808,  0.64135154})
--
-- -- 2nd order Butterworth IIR filter, Wn=0.1
-- local b_taps = radio.types.Float32.vector_from_array({0.02008337,  0.04016673,  0.02008337})
-- local a_taps = radio.types.Float32.vector_from_array({1, -1.56101808,  0.64135154})
-- local filter = radio.IIRFilterBlock(b_taps, a_taps)

local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local class = require('radio.core.class')
local types = require('radio.types')
local vector = require('radio.core.vector')

local IIRFilterBlock = block.factory("IIRFilterBlock")

function IIRFilterBlock:instantiate(b_taps, a_taps)
    assert(b_taps, "Missing argument #1 (b_taps)")
    if class.isinstanceof(b_taps, vector.Vector) and b_taps.data_type == types.Float32 then
        self.b_taps = b_taps
    elseif class.isinstanceof(b_taps, "table") then
        self.b_taps = types.Float32.vector_from_array(b_taps)
    else
        error("Unsupported b_taps type")
    end

    assert(a_taps, "Missing argument #2 (a_taps)")
    if class.isinstanceof(a_taps, vector.Vector) and a_taps.data_type == types.Float32 then
        self.a_taps = a_taps
    elseif class.isinstanceof(a_taps, "table") then
        self.a_taps = types.Float32.vector_from_array(a_taps)
    else
        error("Unsupported a_taps type")
    end
    assert(self.a_taps.length >= 1, "Feedback taps must be at least length 1")

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, IIRFilterBlock.process_complex)
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)}, IIRFilterBlock.process_real)
end

if platform.features.liquid then

    ffi.cdef[[
    typedef struct iirfilt_crcf_s * iirfilt_crcf;
    iirfilt_crcf iirfilt_crcf_create(float32_t *_b, unsigned int _nb, float32_t *_a, unsigned int _na);
    void iirfilt_crcf_destroy(iirfilt_crcf _q);

    typedef struct iirfilt_rrrf_s * iirfilt_rrrf;
    iirfilt_rrrf iirfilt_rrrf_create(float32_t *_b, unsigned int _nb, float32_t *_a, unsigned int _na);
    void iirfilt_rrrf_destroy(iirfilt_rrrf _q);

    void iirfilt_crcf_execute_block(iirfilt_crcf _q, const complex_float32_t *_x, unsigned int _n, complex_float32_t *_y);
    void iirfilt_rrrf_execute_block(iirfilt_rrrf _q, const float32_t *_x, unsigned int _n, float32_t *_y);
    ]]
    local libliquid = platform.libs.liquid

    function IIRFilterBlock:initialize()
        local data_type = self:get_input_type()

        if data_type == types.ComplexFloat32 then
            self.filter = ffi.gc(libliquid.iirfilt_crcf_create(self.b_taps.data, self.b_taps.length, self.a_taps.data, self.a_taps.length), libliquid.iirfilt_crcf_destroy)
        elseif data_type == types.Float32 then
            self.filter = ffi.gc(libliquid.iirfilt_rrrf_create(self.b_taps.data, self.b_taps.length, self.a_taps.data, self.a_taps.length), libliquid.iirfilt_rrrf_destroy)
        end

        if self.filter == nil then
            error("Creating liquid iirfilt object.")
        end

        self.out = data_type.vector()
    end

    function IIRFilterBlock:process_complex(x)
        local out = self.out:resize(x.length)

        libliquid.iirfilt_crcf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

    function IIRFilterBlock:process_real(x)
        local out = self.out:resize(x.length)

        libliquid.iirfilt_rrrf_execute_block(self.filter, x.data, x.length, out.data)

        return out
    end

else

    ffi.cdef[[
    void *memmove(void *dest, const void *src, size_t n);
    ]]

    function IIRFilterBlock:initialize()
        local data_type = self:get_input_type()

        self.input_state = data_type.vector(self.b_taps.length)
        self.output_state = data_type.vector(self.a_taps.length-1)
        self.out = data_type.vector()
    end

    function IIRFilterBlock:process_complex(x)
        local out = self.out:resize(x.length)

        for i = 0, x.length-1 do
            -- Shift the input state samples down
            ffi.C.memmove(self.input_state.data[1], self.input_state.data[0], (self.input_state.length-1)*ffi.sizeof(self.input_state.data[0]))
            -- Insert input sample into input state
            self.input_state.data[0] = x.data[i]

            out.data[i] = types.ComplexFloat32()
            -- Inner product of input state and b taps
            for j = 0, self.input_state.length-1 do
                out.data[i] = out.data[i] + self.input_state.data[j]:scalar_mul(self.b_taps.data[j].value)
            end
            -- Inner product of output state and a taps (skipping a[0])
            for j = 0, self.output_state.length-1 do
                out.data[i] = out.data[i] - self.output_state.data[j]:scalar_mul(self.a_taps.data[j+1].value)
            end
            -- Apply a[0] tap
            out.data[i] = out.data[i]:scalar_div(self.a_taps.data[0].value)

            -- Shift the output state samples down
            ffi.C.memmove(self.output_state.data[1], self.output_state.data[0], (self.output_state.length-1)*ffi.sizeof(self.output_state.data[0]))
            -- Insert output sample into output state
            self.output_state.data[0] = out.data[i]
        end

        return out
    end

    function IIRFilterBlock:process_real(x)
        local out = self.out:resize(x.length)

        for i = 0, x.length-1 do
            -- Shift the input state samples down
            ffi.C.memmove(self.input_state.data[1], self.input_state.data[0], (self.input_state.length-1)*ffi.sizeof(self.input_state.data[0]))
            -- Insert input sample into input state
            self.input_state.data[0] = x.data[i]

            out.data[i] = types.Float32()
            -- Inner product of input state and b taps
            for j = 0, self.input_state.length-1 do
                out.data[i] = out.data[i] + self.input_state.data[j] * self.b_taps.data[j]
            end
            -- Inner product of output state and a taps (skipping a[0])
            for j = 0, self.output_state.length-1 do
                out.data[i] = out.data[i] - self.output_state.data[j] * self.a_taps.data[j+1]
            end
            -- Apply a[0] tap
            out.data[i] = out.data[i] / self.a_taps.data[0]

            -- Shift the output state samples down
            ffi.C.memmove(self.output_state.data[1], self.output_state.data[0], (self.output_state.length-1)*ffi.sizeof(self.output_state.data[0]))
            -- Insert output sample into output state
            self.output_state.data[0] = out.data[i]
        end

        return out
    end

end

return IIRFilterBlock
