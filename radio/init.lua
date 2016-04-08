assert(pcall(require, 'ffi') and pcall(require, 'jit'), 'Error: LuaRadio requires LuaJIT.')

local radio = {
    -- Core modules
    platform = require('radio.core.platform'),
    object = require('radio.core.object'),
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

-- Expose all types in top namespace
for k,v in pairs(radio.types) do
    radio[k] = v
end

-- Expose all blocks in top namespace
for k,v in pairs(radio.blocks) do
    radio[k] = v
end

-- Expose all composites in top namespace
for k,v in pairs(radio.composites) do
    radio[k] = v
end

return radio
