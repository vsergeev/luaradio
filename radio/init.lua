local M = {
    -- Core modules
    platform = require('radio.core.platform'),
    object = require('radio.core.object'),
    block = require('radio.core.block'),
    util = require('radio.core.util'),
    -- Types
    types = require('radio.types'),
    -- Blocks
    blocks = require('radio.blocks'),
    -- Composites
    composites = require('radio.composites'),
}

-- Expose all types in top namespace
for k,v in pairs(M.types) do
    M[k] = v
end

-- Expose all blocks in top namespace
for k,v in pairs(M.blocks) do
    M[k] = v
end

-- Expose all composites in top namespace
for k,v in pairs(M.composites) do
    M[k] = v
end

return M
