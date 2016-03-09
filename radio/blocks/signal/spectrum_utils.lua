local ffi = require('ffi')
local math = require('math')

local platform = require('radio.core.platform')
local object = require('radio.core.object')
local types = require('radio.types')
local window_utils = require('radio.blocks.signal.window_utils')

local DFT = object.class_factory()

function DFT.new(num_samples, data_type, window_type, sample_rate)
    local self = setmetatable({}, DFT)

    if data_type ~= types.ComplexFloat32Type and data_type ~= types.Float32Type then
        error("Unsupported data type.")
    end

    self.num_samples = num_samples
    self.data_type = data_type
    self.window_type = window_type or "hamming"
    self.sample_rate = sample_rate or 2

    self:initialize()

    return self
end

function DFT:initialize()
    -- Generate window
    self.window = types.Float32Type.vector_from_array(window_utils.window(self.num_samples, self.window_type, true))

    -- Calculate the window energy
    self.window_energy = 0
    for i = 0, self.num_samples-1 do
        self.window_energy = self.window_energy + self.window.data[i].value*self.window.data[i].value
    end

    -- Pick complex or real DFT
    if self.data_type == types.ComplexFloat32Type then
        self.dft = self.dft_complex
    else
        self.dft = self.dft_real
    end

    -- Generate unwrapped fft indices
    self.fftshift_indices = {}
    for k = 0, self.num_samples-1 do
        self.fftshift_indices[k] = (k < (self.num_samples/2)) and (k + (self.num_samples/2)) or (k - (self.num_samples/2))
    end

    -- Create sample buffers
    self.windowed_samples = types.ComplexFloat32Type.vector(self.num_samples)
    self.dft_samples = types.ComplexFloat32Type.vector(self.num_samples)
    self.psd_samples = types.Float32Type.vector(self.num_samples)

    -- Initialize the DFT
    self:initialize_dft()
end

--------------------------------------------------------------------------------
-- Window implementations
--------------------------------------------------------------------------------

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_32f_multiply_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const float32_t* bVector, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function DFT:_window(samples)
        -- Window samples (product of complex samples and real window)
        libvolk.volk_32fc_32f_multiply_32fc_a(self.windowed_samples.data, samples.data, self.window.data, self.num_samples)
    end

else

    function DFT:_window(samples)
        -- Window samples (product of complex samples and real window)
        for i = 0, self.num_samples-1 do
            self.windowed_samples.data[i] = samples.data[i]:scalar_mul(self.window.data[i].value)
        end
    end

end

--------------------------------------------------------------------------------
-- DFT implementations
--------------------------------------------------------------------------------

if platform.features.fftw3f then

    ffi.cdef[[
    typedef void * fftwf_plan;
    typedef complex_float32_t fftwf_complex;

    fftwf_plan fftwf_plan_dft_1d(int n, fftwf_complex *in, fftwf_complex *out, int sign, unsigned flags);
    void fftwf_execute(const fftwf_plan plan);
    void fftwf_destroy_plan(fftwf_plan plan);

    enum { FFTW_FORWARD = -1, FFTW_BACKWARD = 1 };
    enum { FFTW_MEASURE = 0, FFTW_ESTIMATE = (1 << 6) };
    ]]
    local libfftw3f = platform.libs.fftw3f

    function DFT:initialize_dft()
        -- Create FFTW plan
        local plan = libfftw3f.fftwf_plan_dft_1d(self.num_samples, self.windowed_samples.data, self.dft_samples.data, ffi.C.FFTW_FORWARD, ffi.C.FFTW_MEASURE)
        if plan == nil then
            error("Creating FFTW plan.")
        end

        -- Create garbage collect wrapper for FFTW plan
        self.plan = ffi.gc(plan, libfftw3f.fftwf_destroy_plan)
    end

    function DFT:dft_complex(samples)
        -- Window samples
        self:_window(samples)

        -- Execute FFTW plan
        libfftw3f.fftwf_execute(self.plan)

        -- Swap indices
        for k = 0, (self.num_samples/2)-1 do
            self.dft_samples.data[self.fftshift_indices[k]].real, self.dft_samples.data[k].real = self.dft_samples.data[k].real, self.dft_samples.data[self.fftshift_indices[k]].real
            self.dft_samples.data[self.fftshift_indices[k]].imag, self.dft_samples.data[k].imag = self.dft_samples.data[k].imag, self.dft_samples.data[self.fftshift_indices[k]].imag
        end

        return self.dft_samples
    end

elseif platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_s32fc_x2_rotator_32fc)(complex_float32_t* outVector, const complex_float32_t* inVector, const complex_float32_t phase_inc, complex_float32_t* phase, unsigned int num_points);
    void (*volk_32fc_32f_multiply_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const float32_t* bVector, unsigned int num_points);
    void (*volk_32fc_x2_dot_prod_32fc_a)(complex_float32_t* result, const complex_float32_t* input, const complex_float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function DFT:initialize_dft()
        -- Generate a DC vector
        local dc_vec = types.ComplexFloat32Type.vector(self.num_samples)
        for i = 0, self.num_samples-1 do
            dc_vec.data[i] = types.ComplexFloat32Type(1, 0)
        end

        -- Generate complex exponentials
        self.exponentials = {}
        for k = 0, self.num_samples-1 do
            self.exponentials[k] = types.ComplexFloat32Type.vector(self.num_samples)
            local omega = (-2*math.pi*k)/self.num_samples
            local rotator = types.ComplexFloat32Type(math.cos(omega), math.sin(omega))
            local phase = types.ComplexFloat32Type(1, 0)
            libvolk.volk_32fc_s32fc_x2_rotator_32fc(self.exponentials[k].data, dc_vec.data, rotator, phase, self.num_samples)
        end

    end

    function DFT:dft_complex(samples)
        -- Window samples
        self:_window(samples)

        -- Compute DFT of windowed samples (dot product of each complex exponential with the windowed samples)
        for k = 0, self.num_samples-1 do
            libvolk.volk_32fc_x2_dot_prod_32fc_a(self.dft_samples.data[self.fftshift_indices[k]], self.windowed_samples.data, self.exponentials[k].data, self.num_samples)
        end

        return self.dft_samples
    end

else

    function DFT:initialize_dft()
        -- Generate complex exponentials
        self.exponentials = {}
        for k = 0, self.num_samples-1 do
            self.exponentials[k] = types.ComplexFloat32Type.vector(self.num_samples)
            local omega = (-2*math.pi*k)/self.num_samples
            for n = 0, self.num_samples-1 do
                self.exponentials[k].data[n] = types.ComplexFloat32Type(math.cos(omega*n), math.sin(omega*n))
            end
        end
    end

    function DFT:dft_complex(samples)
        -- Window samples
        self:_window(samples)

        -- Compute DFT of windowed samples (dot product of each complex exponential with the windowed samples)
        ffi.fill(self.dft_samples.data, self.dft_samples.size)
        for k = 0, self.num_samples-1 do
            local k_shifted = self.fftshift_indices[k]
            for n = 0, self.num_samples-1 do
                self.dft_samples.data[k_shifted] = self.dft_samples.data[k_shifted] + self.exponentials[k].data[n]*self.windowed_samples.data[n]
            end
        end

        return self.dft_samples
    end

end

--------------------------------------------------------------------------------
-- PSD implementations
--------------------------------------------------------------------------------

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_s32f_x2_power_spectral_density_32f_a)(float32_t* logPowerOutput, const complex_float32_t* complexFFTInput, const float normalizationFactor, const float rbw, unsigned int num_points);
    void (*volk_32fc_magnitude_squared_32f_a)(float32_t* magnitudeVector, const complex_float32_t* complexVector, unsigned int num_points);
    void (*volk_32f_s32f_normalize_a)(float32_t* vecBuffer, const float scalar, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function DFT:psd(samples, logarithmic)
        -- Compute DFT
        local dft_samples = self:dft(samples)

        -- Scaling factor
        local scale = self.sample_rate * self.window_energy

        if logarithmic then
            -- Compute 10*log10((X_k)^2 / Scale)
            libvolk.volk_32fc_s32f_x2_power_spectral_density_32f_a(self.psd_samples.data, dft_samples.data, 1.0, scale, self.num_samples)
        else
            -- Compute (X_k)^2 / Scale
            libvolk.volk_32fc_magnitude_squared_32f_a(self.psd_samples.data, dft_samples.data, self.num_samples)
            libvolk.volk_32f_s32f_normalize_a(self.psd_samples.data, scale, self.num_samples)
        end

        return self.psd_samples
    end

else

    function DFT:psd(samples, logarithmic)
        -- Compute DFT
        local dft_samples = self:dft(samples)

        -- Scaling factor
        local scale = self.sample_rate * self.window_energy

        if logarithmic then
            -- Compute 10*log10((X_k)^2 / Scale)
            for i = 0, self.num_samples-1 do
                self.psd_samples.data[i].value = 10*math.log10(dft_samples.data[i]:abs_squared() / scale)
            end
        else
            -- Compute (X_k)^2 / Scale
            for i = 0, self.num_samples-1 do
                self.psd_samples.data[i].value = dft_samples.data[i]:abs_squared() / scale
            end
        end

        return self.psd_samples
    end

end

--------------------------------------------------------------------------------
-- Wrapper for real samples
--------------------------------------------------------------------------------

function DFT:dft_real(samples)
    -- Convert real samples to complex samples
    local complex_samples = types.ComplexFloat32Type.vector(self.num_samples)
    for i = 0, self.num_samples-1 do
        complex_samples.data[i].real = samples.data[i].value
    end

    return self:dft_complex(complex_samples)
end

return {DFT = DFT}
