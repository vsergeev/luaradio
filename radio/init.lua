---
-- LuaRadio package.
--
-- @module radio
-- @tfield string _VERSION Package version as a string, e.g. "1.0.0".
-- @tfield string version Package version as a string, e.g. "1.0.0".
-- @tfield int version_number Package version as a number, encoded in decimal as xxyyzz, e.g. v1.2.15 would be 10215.
-- @tfield table version_info Package version as a table, with keys `major`, `minor`, `patch` and integer values.
-- @tfield module types Types module.
-- @tfield module block Block module.
-- @tfield module debug Debug module.
-- @tfield module platform Platform module.

assert(pcall(require, 'ffi') and pcall(require, 'jit'), 'Error: LuaRadio requires LuaJIT.')

local radio = {
    -- Version
    _VERSION = "0.8.0",
    version = "0.8.0",
    version_number = 000800,
    version_info = {major = 0, minor = 8, patch = 0},

    -- Core modules
    platform = require('radio.core.platform'),
    class = require('radio.core.class'),
    block = require('radio.core.block'),
    vector = require('radio.core.vector'),
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
