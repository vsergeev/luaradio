assert(pcall(require, 'ffi') and pcall(require, 'jit'), 'Error: LuaRadio requires LuaJIT.')

local radio = {
    -- Version
    _VERSION = "0.0.17",
    version = "0.0.17",
    version_number = 000017,
    version_info = {major = 0, minor = 0, patch = 17},

    -- Core modules
    platform = require('radio.core.platform'),
    class = require('radio.core.class'),
    block = require('radio.core.block'),
    util = require('radio.core.util'),
    debug = require('radio.core.debug'),

    -- Types
    types = require('radio.types'),

    -- Blocks
    blocks = require('radio.blocks'),

    -- Composites
    composites = require('radio.composites'),
}

-- Expose all blocks in top namespace
for k,v in pairs(radio.blocks) do
    radio[k] = v
end

-- Expose all composites in top namespace
for k,v in pairs(radio.composites) do
    radio[k] = v
end

return radio
