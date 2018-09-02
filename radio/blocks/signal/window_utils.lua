---
-- Window generation function.
--
-- @module radio.blocks.signal.window_utils

local math = require('math')

-- Window functions.
-- See https://en.wikipedia.org/wiki/Window_function#A_list_of_window_functions

local window_functions = {
    rectangular = function (n, M)
        return 1.0
    end,
    hamming = function (n, M)
        return 0.54 - 0.46*math.cos((2*math.pi*n)/(M-1))
    end,
    hanning = function (n, M)
        return 0.5 - 0.5*math.cos((2*math.pi*n)/(M-1))
    end,
    bartlett = function (n, M)
        return (2/(M-1))*((M-1)/2 - math.abs(n - (M-1)/2))
    end,
    blackman = function (n, M)
        return 0.42 - 0.5*math.cos((2*math.pi*n)/(M-1)) + 0.08*math.cos((4*math.pi*n)/(M-1))
    end
}

---
-- Generate a window.
--
-- @internal
-- @function window
-- @tparam int M Window length
-- @tparam string window_type Window function, choice of "rectangular",
--                            "hamming", "hanning", "bartlett", "blackman".
-- @tparam[opt=false] bool periodic Periodic window for spectral analysis
-- @treturn array Window values
local function window(M, window_type, periodic)
    if not window_functions[window_type] then
        error("Unsupported window \"" .. tostring(window_type) .. "\".")
    end

    local w = {}
    for n = 0, M-1 do
        w[n+1] = window_functions[window_type](n, periodic and (M+1) or M)
    end

    return w
end

return {window = window}
