local math = require('math')

local window_utils = require('radio.blocks.signal.window_utils')

-- FIR window method filter design.
-- See http://www.labbookpages.co.uk/audio/firWindowing.html for derivations.

local function firwin_lowpass(num_taps, cutoff, window_type)
    -- Default to hamming window
    window_type = (window_type == nil) and "hamming" or window_type

    -- Generate filter coefficients
    local h = {}
    for n = 0, num_taps-1 do
        if n == (num_taps-1)/2 then
            h[n+1] = cutoff
        else
            h[n+1] = math.sin(math.pi*cutoff*(n - (num_taps-1)/2))/(math.pi*(n - (num_taps-1)/2))
        end
    end

    -- Apply window
    local w = window_utils.window(num_taps, window_type)
    for n=1, #h do
        h[n] = h[n] * w[n]
    end

    -- Scale by DC gain
    scale = 0
    for n=0, num_taps-1 do
        scale = scale + h[n+1]
    end
    for n=1, #h do
        h[n] = h[n] / scale
    end

    return h
end

local function firwin_highpass(num_taps, cutoff, window_type)
    -- Default to hamming window
    window_type = (window_type == nil) and "hamming" or window_type

    assert((num_taps % 2) == 1, "Number of taps must be odd.")

    -- Generate filter coefficients
    local h = {}
    for n = 0, num_taps-1 do
        if n == (num_taps-1)/2 then
            h[n+1] = 1 - cutoff
        else
            h[n+1] = -math.sin(math.pi*cutoff*(n - (num_taps-1)/2))/(math.pi*(n - (num_taps-1)/2))
        end
    end

    -- Apply window
    local w = window_utils.window(num_taps, window_type)
    for n=1, #h do
        h[n] = h[n] * w[n]
    end

    -- Scale by Nyquist gain
    scale = 0
    for n=0, num_taps-1 do
        scale = scale + h[n+1]*math.cos(math.pi*(n - (num_taps-1)/2))
    end
    for n=1, #h do
        h[n] = h[n] / scale
    end

    return h
end

local function firwin_bandpass(num_taps, cutoffs, window_type)
    -- Default to hamming window
    window_type = (window_type == nil) and "hamming" or window_type

    assert((num_taps % 2) == 1, "Number of taps must be odd.")
    assert(#cutoffs == 2, "Cutoffs should be a length two array.")

    -- Generate filter coefficients
    local h = {}
    for n = 0, num_taps-1 do
        if n == (num_taps-1)/2 then
            h[n+1] = (cutoffs[2] - cutoffs[1])
        else
            h[n+1] = math.sin(math.pi*cutoffs[2]*(n - (num_taps-1)/2))/(math.pi*(n - (num_taps-1)/2)) - math.sin(math.pi*cutoffs[1]*(n - (num_taps-1)/2))/(math.pi*(n - (num_taps-1)/2))
        end
    end

    -- Apply window
    local w = window_utils.window(num_taps, window_type)
    for n=1, #h do
        h[n] = h[n] * w[n]
    end

    -- Scale by passband gain
    local center_frequency = (cutoffs[1] + cutoffs[2])/2
    local scale = 0
    for n=0, num_taps-1 do
        scale = scale + h[n+1]*math.cos(math.pi*(n - (num_taps-1)/2)*center_frequency)
    end
    for n=1, #h do
        h[n] = h[n] / scale
    end

    return h
end

local function firwin_bandstop(num_taps, cutoffs, window_type)
    -- Default to hamming window
    window_type = (window_type == nil) and "hamming" or window_type

    assert((num_taps % 2) == 1, "Number of taps must be odd.")
    assert(#cutoffs == 2, "Cutoffs should be a length two array.")

    -- Generate filter coefficients
    local h = {}
    for n = 0, num_taps-1 do
        if n == (num_taps-1)/2 then
            h[n+1] = 1 - (cutoffs[2] - cutoffs[1])
        else
            h[n+1] = math.sin(math.pi*cutoffs[1]*(n - (num_taps-1)/2))/(math.pi*(n - (num_taps-1)/2)) - math.sin(math.pi*cutoffs[2]*(n - (num_taps-1)/2))/(math.pi*(n - (num_taps-1)/2))
        end
    end

    -- Apply window
    local w = window_utils.window(num_taps, window_type)
    for n=1, #h do
        h[n] = h[n] * w[n]
    end

    -- Scale by DC gain
    scale = 0
    for n=0, num_taps-1 do
        scale = scale + h[n+1]
    end
    for n=1, #h do
        h[n] = h[n] / scale
    end

    return h
end

-- FIR Root Raised Cosine Filter
-- See https://en.wikipedia.org/wiki/Root-raised-cosine_filter

local function fir_root_raised_cosine(num_taps, sample_rate, beta, symbol_period)
    local h = {}

    if (num_taps % 2) == 0 then
        error("Number of taps must be odd.")
    end

    local function approx_equal(a, b)
        return math.abs(a-b) < 1e-5
    end

    -- Generate filter coefficients
    for n = 0, num_taps-1 do
        local t = (n - (num_taps-1)/2)/sample_rate

        if t == 0 then
            h[n+1] = (1/(math.sqrt(symbol_period)))*(1-beta+4*beta/math.pi)
        elseif approx_equal(t, -symbol_period/(4*beta)) or approx_equal(t, symbol_period/(4*beta)) then
            h[n+1] = (beta/math.sqrt(2*symbol_period))*((1+2/math.pi)*math.sin(math.pi/(4*beta))+(1-2/math.pi)*math.cos(math.pi/(4*beta)))
        else
            local num = math.cos((1 + beta)*math.pi*t/symbol_period) + math.sin((1 - beta)*math.pi*t/symbol_period)/(4*beta*t/symbol_period)
            local denom = (1 - (4*beta*t/symbol_period)*(4*beta*t/symbol_period))
            h[n+1] = ((4*beta)/(math.pi*math.sqrt(symbol_period)))*num/denom
        end
    end

    -- Scale by DC gain
    local scale = 0
    for n=0, num_taps-1 do
        scale = scale + h[n+1]
    end
    for n = 0, num_taps-1 do
        h[n+1] = h[n+1] / scale
    end

    return h
end

-- FIR Hilbert Transform Filter
-- See https://en.wikipedia.org/wiki/Hilbert_transform#Discrete_Hilbert_transform

local function fir_hilbert_transform(num_taps, window_type)
    -- Default to hamming window
    window_type = (window_type == nil) and "hamming" or window_type

    if (num_taps % 2) == 0 then
        error("Number of taps must be odd.")
    end

    -- Generate filter coefficients
    local h = {}
    for n = 0, num_taps-1 do
        local n_shifted = (n - (num_taps-1)/2)
        if (n_shifted % 2) == 0 then
            h[n+1] = 0
        else
            h[n+1] = 2/(n_shifted*math.pi)
        end
    end

    -- Apply window
    local w = window_utils.window(num_taps, window_type)
    for n = 0, num_taps-1 do
        h[n+1] = h[n+1] * w[n+1]
    end

    return h
end

return {firwin_lowpass = firwin_lowpass, firwin_highpass = firwin_highpass, firwin_bandpass = firwin_bandpass, firwin_bandstop = firwin_bandstop, fir_root_raised_cosine = fir_root_raised_cosine, fir_hilbert_transform = fir_hilbert_transform}
