---
-- Math utility functions.
--
-- @module radio.utilities.math_utils

local math = require('math')

---
-- Calculate the log2 ceiling.
--
-- @internal
-- @function ceil_log2
-- @tparam number x Value
local function ceil_log2(x)
    return math.ceil(math.log(x, 2))
end

return {ceil_log2 = ceil_log2}
