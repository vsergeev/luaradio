local ffi = require('ffi')
local math = require('math')

local platform = require('radio.core.platform')
local class = require('radio.core.class')
local types = require('radio.types')
local window_utils = require('radio.blocks.signal.window_utils')

---
-- Discrete Fourier Transform helper class.
--
-- @local
-- @type DFT
-- @tparam int num_samples Number of samples in transform
-- @tparam data_type data_type Data type of samples, choice of ComplexFloat32
--                             or Float32.
-- @tparam[opt='hamming'] string window_type Window type
-- @tparam number sample_rate Sample rate in Hz
local DFT = class.factory()

function DFT.new(num_samples, data_type, window_type, sample_rate)
    local self = setmetatable({}, DFT)

    if data_type ~= types.ComplexFloat32 and data_type ~= types.Float32 then
        error("Unsupported data type.")
    elseif (num_samples % 2) ~= 0 then
        error("DFT length must be even.")
    end

    self.num_samples = num_samples
    self.data_type = data_type
    self.window_type = window_type or "hamming"
    self.sample_rate = sample_rate or 2

    self:initialize()

    return self
end

---
-- Initialize DFT.
--
-- @local
function DFT:initialize()
    -- Generate window
    self.window = types.Float32.vector_from_array(window_utils.window(self.num_samples, self.window_type, true))

    -- Calculate the window energy
    self.window_energy = 0
    for i = 0, self.num_samples-1 do
        self.window_energy = self.window_energy + self.window.data[i].value*self.window.data[i].value
    end

    -- Pick complex or real DFT
    if self.data_type == types.ComplexFloat32 then
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
    self.windowed_samples = self.data_type.vector(self.num_samples)
    self.dft_samples = types.ComplexFloat32.vector(self.num_samples)
    self.psd_samples = types.Float32.vector(self.num_samples)

    -- Initialize the DFT
    self:initialize_dft()
end

---
-- Compute the discrete fourier transform.
--
-- @local
-- @function DFT:dft
-- @tparam Vector samples Vector of samples
-- @treturn Vector ComplexFloat32 vector of complex-valued coefficients

---
-- Compute the power spectral density.
--
-- @local
-- @function DFT:psd
-- @tparam Vector samples Vector of samples
-- @tparam bool logarithmic Scale power logarithmically, with `10*log10()`
-- @treturn Vector Float32 vector of power values

--------------------------------------------------------------------------------
-- Window implementations
--------------------------------------------------------------------------------

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_32f_multiply_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const float32_t* bVector, unsigned int num_points);
    void (*volk_32f_x2_multiply_32f_a)(float32_t* cVector, const float32_t* aVector, const float32_t* bVector, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function DFT:_window_complex(samples)
        -- Window samples (product of complex samples and real window)
        libvolk.volk_32fc_32f_multiply_32fc_a(self.windowed_samples.data, samples.data, self.window.data, self.num_samples)
    end

    function DFT:_window_real(samples)
        -- Window samples (product of real samples and real window)
        libvolk.volk_32f_x2_multiply_32f_a(self.windowed_samples.data, samples.data, self.window.data, self.num_samples)
    end

else

    function DFT:_window_complex(samples)
        -- Window samples (product of complex samples and real window)
        for i = 0, self.num_samples-1 do
            self.windowed_samples.data[i] = samples.data[i]:scalar_mul(self.window.data[i].value)
        end
    end

    function DFT:_window_real(samples)
        -- Window samples (product of real samples and real window)
        for i = 0, self.num_samples-1 do
            self.windowed_samples.data[i].value = samples.data[i].value*self.window.data[i].value
        end
    end

end

--------------------------------------------------------------------------------
-- DFT implementations
--------------------------------------------------------------------------------

if platform.features.fftw3f then

    ffi.cdef[[
    typedef struct fftwf_plan_s *fftwf_plan;
    typedef float32_t fftwf_real;
    typedef complex_float32_t fftwf_complex;

    fftwf_plan fftwf_plan_dft_1d(int n, fftwf_complex *in, fftwf_complex *out, int sign, unsigned flags);
    fftwf_plan fftwf_plan_dft_r2c_1d(int n0, fftwf_real *in, fftwf_complex *out, unsigned flags);
    void fftwf_execute(const fftwf_plan plan);
    void fftwf_destroy_plan(fftwf_plan plan);

    enum { FFTW_FORWARD = -1, FFTW_BACKWARD = 1 };
    enum { FFTW_MEASURE = 0, FFTW_ESTIMATE = (1 << 6) };
    ]]
    local libfftw3f = platform.libs.fftw3f

    function DFT:initialize_dft()
        -- Create plan
        if self.data_type == types.ComplexFloat32 then
            self.plan = ffi.gc(libfftw3f.fftwf_plan_dft_1d(self.num_samples, self.windowed_samples.data, self.dft_samples.data, ffi.C.FFTW_FORWARD, ffi.C.FFTW_MEASURE), libfftw3f.fftwf_destroy_plan)
        else
            self.plan = ffi.gc(libfftw3f.fftwf_plan_dft_r2c_1d(self.num_samples, self.windowed_samples.data, self.dft_samples.data, ffi.C.FFTW_MEASURE), libfftw3f.fftwf_destroy_plan)
        end

        if self.plan == nil then
            error("Creating FFTW plan.")
        end
    end

    function DFT:dft_complex(samples)
        -- Window samples
        self:_window_complex(samples)

        -- Execute FFTW plan
        libfftw3f.fftwf_execute(self.plan)

        -- Swap indices
        for k = 0, (self.num_samples/2)-1 do
            self.dft_samples.data[self.fftshift_indices[k]].real, self.dft_samples.data[k].real = self.dft_samples.data[k].real, self.dft_samples.data[self.fftshift_indices[k]].real
            self.dft_samples.data[self.fftshift_indices[k]].imag, self.dft_samples.data[k].imag = self.dft_samples.data[k].imag, self.dft_samples.data[self.fftshift_indices[k]].imag
        end

        return self.dft_samples
    end

    function DFT:dft_real(samples)
        -- Window samples
        self:_window_real(samples)

        -- Execute FFTW plan
        libfftw3f.fftwf_execute(self.plan)

        -- Populate negative frequencies
        for k = math.floor(self.num_samples/2)+1, self.num_samples-1 do
            self.dft_samples.data[k].real = self.dft_samples.data[self.num_samples-k].real
            self.dft_samples.data[k].imag = -self.dft_samples.data[self.num_samples-k].imag
        end

        -- Swap indices
        for k = 0, (self.num_samples/2)-1 do
            self.dft_samples.data[self.fftshift_indices[k]].real, self.dft_samples.data[k].real = self.dft_samples.data[k].real, self.dft_samples.data[self.fftshift_indices[k]].real
            self.dft_samples.data[self.fftshift_indices[k]].imag, self.dft_samples.data[k].imag = self.dft_samples.data[k].imag, self.dft_samples.data[self.fftshift_indices[k]].imag
        end

        return self.dft_samples
    end

elseif platform.features.liquid then

    ffi.cdef[[
    typedef struct fftplan_s * fftplan;
    fftplan fft_create_plan(unsigned int _n, complex_float32_t *_x, complex_float32_t *_y, int _dir, int _flags);
    void fft_destroy_plan(fftplan _p);

    void fft_execute(fftplan _p);
    void fft_shift(complex_float32_t *_x, unsigned int _n);

    enum { LIQUID_FFT_FORWARD = +1, LIQUID_FFT_BACKWARD = -1 };
    ]]
    local libliquid = platform.libs.liquid

    function DFT:initialize_dft()
        -- Create plan
        if self.data_type == types.ComplexFloat32 then
            self.plan = ffi.gc(libliquid.fft_create_plan(self.num_samples, self.windowed_samples.data, self.dft_samples.data, ffi.C.LIQUID_FFT_FORWARD, 0), libliquid.fft_destroy_plan)
        else
            -- Create complex samples buffer for dft_real()
            self._samples = types.ComplexFloat32.vector(self.num_samples)

            self.plan = ffi.gc(libliquid.fft_create_plan(self.num_samples, self._samples.data, self.dft_samples.data, ffi.C.LIQUID_FFT_FORWARD, 0), libliquid.fft_destroy_plan)
        end

        if self.plan == nil then
            error("Creating liquid fftplan object.")
        end
    end

    function DFT:dft_complex(samples)
        -- Window samples
        self:_window_complex(samples)

        -- Execute FFTW plan
        libliquid.fft_execute(self.plan)

        -- Swap indices
        libliquid.fft_shift(self.dft_samples.data, self.dft_samples.length)

        return self.dft_samples
    end

    function DFT:dft_real(samples)
        -- liquid-dsp doesn't provide a r2c DFT, so we copy real samples into a
        -- complex sample buffer and use the c2c DFT.

        -- Window samples
        self:_window_real(samples)

        -- Copy real samples to complex samples
        for i = 0, self.num_samples-1 do
            self._samples.data[i].real = self.windowed_samples.data[i].value
        end

        -- Execute FFTW plan
        libliquid.fft_execute(self.plan)

        -- Swap indices
        libliquid.fft_shift(self.dft_samples.data, self.dft_samples.length)

        return self.dft_samples
    end

elseif platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_s32fc_x2_rotator_32fc_a)(complex_float32_t* outVector, const complex_float32_t* inVector, const complex_float32_t phase_inc, complex_float32_t* phase, unsigned int num_points);
    void (*volk_32fc_32f_multiply_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const float32_t* bVector, unsigned int num_points);
    void (*volk_32fc_x2_dot_prod_32fc_a)(complex_float32_t* result, const complex_float32_t* input, const complex_float32_t* taps, unsigned int num_points);
    void (*volk_32fc_32f_dot_prod_32fc_a)(complex_float32_t* result, const complex_float32_t* input, const float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function DFT:initialize_dft()
        -- Generate a DC vector
        local dc_vec = types.ComplexFloat32.vector(self.num_samples)
        for i = 0, self.num_samples-1 do
            dc_vec.data[i] = types.ComplexFloat32(1, 0)
        end

        -- Generate complex exponentials
        self.exponentials = {}
        for k = 0, self.num_samples-1 do
            self.exponentials[k] = types.ComplexFloat32.vector(self.num_samples)
            local omega = (-2*math.pi*k)/self.num_samples
            local rotator = types.ComplexFloat32(math.cos(omega), math.sin(omega))
            local phase = types.ComplexFloat32(1, 0)
            libvolk.volk_32fc_s32fc_x2_rotator_32fc_a(self.exponentials[k].data, dc_vec.data, rotator, phase, self.num_samples)
        end
    end

    function DFT:dft_complex(samples)
        -- Window samples
        self:_window_complex(samples)

        -- Compute DFT of windowed samples (dot product of each complex exponential with the windowed samples)
        for k = 0, self.num_samples-1 do
            libvolk.volk_32fc_x2_dot_prod_32fc_a(self.dft_samples.data[self.fftshift_indices[k]], self.windowed_samples.data, self.exponentials[k].data, self.num_samples)
        end

        return self.dft_samples
    end

    function DFT:dft_real(samples)
        --Window samples
        self:_window_real(samples)

        -- Compute DFT of windowed samples (dot product of each complex exponential with the windowed samples)
        for k = 0, self.num_samples/2 do
            libvolk.volk_32fc_32f_dot_prod_32fc_a(self.dft_samples.data[self.fftshift_indices[k]], self.exponentials[k].data, self.windowed_samples.data, self.num_samples)
        end

        -- Populate negative frequencies
        for k = math.floor(self.num_samples/2)+1, self.num_samples-1 do
            self.dft_samples.data[self.fftshift_indices[k]].real = self.dft_samples.data[self.num_samples-self.fftshift_indices[k]].real
            self.dft_samples.data[self.fftshift_indices[k]].imag = -self.dft_samples.data[self.num_samples-self.fftshift_indices[k]].imag
        end

        return self.dft_samples
    end

else

    function DFT:initialize_dft()
        -- Generate complex exponentials
        self.exponentials = {}
        for k = 0, self.num_samples-1 do
            self.exponentials[k] = types.ComplexFloat32.vector(self.num_samples)
            local omega = (-2*math.pi*k)/self.num_samples
            for n = 0, self.num_samples-1 do
                self.exponentials[k].data[n] = types.ComplexFloat32(math.cos(omega*n), math.sin(omega*n))
            end
        end
    end

    function DFT:dft_complex(samples)
        -- Window samples
        self:_window_complex(samples)

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

    function DFT:dft_real(samples)
        -- Window samples
        self:_window_real(samples)

        -- Zero DFT samples
        ffi.fill(self.dft_samples.data, self.dft_samples.size)

        -- Compute DFT of windowed samples (dot product of each complex exponential with the windowed samples)
        for k = 0, self.num_samples/2 do
            local k_shifted = self.fftshift_indices[k]
            for n = 0, self.num_samples-1 do
                self.dft_samples.data[k_shifted] = self.dft_samples.data[k_shifted] + self.exponentials[k].data[n]:scalar_mul(self.windowed_samples.data[n].value)
            end
        end

        -- Populate negative frequencies
        for k = math.floor(self.num_samples/2)+1, self.num_samples-1 do
            self.dft_samples.data[self.fftshift_indices[k]].real = self.dft_samples.data[self.num_samples-self.fftshift_indices[k]].real
            self.dft_samples.data[self.fftshift_indices[k]].imag = -self.dft_samples.data[self.num_samples-self.fftshift_indices[k]].imag
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

return {DFT = DFT}
