local os = require('os')
local io = require('io')

local function getenv_flag(name)
    local value = string.lower(os.getenv(name) or "")
    return (value == "1" or value == "y" or value == "true" or value == "yes")
end

local debug = {
    enabled = getenv_flag('LUARADIO_DEBUG') or false
}

function debug.print(s)
    if debug.enabled then
        io.stderr:write(s .. '\n')
    end
end

function debug.printf(...)
    if debug.enabled then
        io.stderr:write(string.format(...))
    end
end

return debug
