local bit = require('bit')

local block = require('radio.core.block')
local types = require('radio.types')

local POCSAGFrameType = require('radio.blocks.protocol.pocsagframe').POCSAGFrameType

-- POCSAG Related Constants

local POCSAG_NUMERIC_BCD_TABLE = {
    [0x0] = "0",    [0x1] = "1",    [0x2] = "2",    [0x3] = "3",
    [0x4] = "4",    [0x5] = "5",    [0x6] = "6",    [0x7] = "7",
    [0x8] = "8",    [0x9] = "9",    [0xA] = "R",    [0xB] = "U",
    [0xC] = " ",    [0xD] = "-",    [0xE] = "(",    [0xF] = ")",
}

-- POCSAG Message Type

local POCSAGMessageType = types.ObjectType.factory()

function POCSAGMessageType.new(address, func, alphanumeric, numeric)
    local self = setmetatable({}, POCSAGMessageType)
    self.address = address
    self.func = func
    self.alphanumeric = alphanumeric
    self.numeric = numeric
    return self
end

-- POCSAG Decode Block

local POCSAGDecodeBlock = block.factory("POCSAGDecodeBlock")

function POCSAGDecodeBlock:instantiate(mode)
    -- Default decode mode to alphanumeric
    self.mode = mode or "alphanumeric"

    assert(self.mode == "alphanumeric" or self.mode == "numeric" or self.mode == "both", "Decode mode should be \"alphanumeric\", \"numeric\", or \"both\".")

    self:add_type_signature({block.Input("in", POCSAGFrameType)}, {block.Output("out", POCSAGMessageType)})
end

POCSAGDecodeBlock.POCSAGMessageType = POCSAGMessageType

local function pocsag_decode_alphanumeric(data)
    local text = ""
    local char, count = 0, 0

    if #data == 0 then
        return nil
    end

    for _, word in ipairs(data) do
        for i=19, 0, -1 do
            -- Take the next MSB of 20-bit data word
            local msb = bit.band(bit.rshift(word, i), 0x1)

            -- Shift it into the next LSB of 7-bit char
            char = bit.bor(char, bit.lshift(msb, count))
            count = count + 1

            -- When bit count hits 7, extract character
            if count == 7 then
                if char == 0x17 then
                    goto eot
                end
                text = text .. string.char(char)
                char, count = 0, 0
            end
        end
    end

    ::eot::
    return text
end

local function pocsag_decode_numeric(data)
    local text = ""

    if #data == 0 then
        return nil
    end

    for _, word in ipairs(data) do
        for i=4, 0, -1 do
            -- Take the next nibble
            local nibble = bit.band(bit.rshift(word, 4*i), 0xf)

            -- Convert it and add it to our text
            text = text .. POCSAG_NUMERIC_BCD_TABLE[nibble]
        end
    end

    return text
end

function POCSAGDecodeBlock:process(x)
    local out = POCSAGMessageType.vector()

    for i = 0, x.length-1 do
        local alphanumeric, numeric = nil

        if self.mode == "alphanumeric" or self.mode == "both" then
            alphanumeric = pocsag_decode_alphanumeric(x.data[i].data)
        end
        if self.mode == "numeric" or self.mode == "both" then
            numeric = pocsag_decode_numeric(x.data[i].data)
        end

        out:append(POCSAGMessageType(x.data[i].address, x.data[i].func, alphanumeric, numeric))
    end

    return out
end

return POCSAGDecodeBlock
