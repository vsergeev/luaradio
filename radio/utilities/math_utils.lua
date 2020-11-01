---
-- Math utility functions.
--
-- @module radio.utilities.math_utils

local math = require('math')
local bit = require('bit')

---
-- Calculate the log2 ceiling.
--
-- @internal
-- @function ceil_log2
-- @tparam number x Value
local function ceil_log2(x)
    return math.ceil(math.log(x, 2))
end

---
-- Test if a number is a power of two.
--
-- @internal
-- @function is_pow2
-- @tparam number x Value
local function is_pow2(x)
    return x > 0 and bit.band(x, x - 1) == 0
end

return {ceil_log2 = ceil_log2, is_pow2 = is_pow2}
