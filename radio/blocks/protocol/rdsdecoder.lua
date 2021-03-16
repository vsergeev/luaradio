---
-- Decode RDS frames into RDS packets with a header and data payload. The
-- supported data payloads are basic tuning, radiotext, and datetime.
--
-- @category Protocol
-- @block RDSDecoderBlock
--
-- @signature in:RDSFrameType > out:RDSPacketType
--
-- @usage
-- local decoder = radio.RDSDecoderBlock()

---
-- RDS packet type, a Lua object with properties:
--
-- ``` text
-- {
--   header = {
--     pi_code = <16-bit integer>
--     group_code = <4-bit integer>
--     group_version = <1-bit integer>,
--     tp_code = <1-bit integer>,
--     pty_code = <5-bit integer>,
--   },
--   data = <payload object>,
-- }
-- ```
--
-- The payload object can be one of the four below.
--
-- Basic tuning data payload:
--
-- ``` text
-- {
--   type = "basictuning",
--   ta_code = <1-bit integer>,
--   ms_code = <1-bit integer>,
--   di_position = <2-bit integer>,
--   di_value = <1-bit integer>,
--   af_code = {<8-bit integer>, <8-bit integer>} or nil,
--   text_address = <2-bit integer>,
--   text_data = <string, length 2>,
-- }
-- ```
--
-- Radio text data payload:
--
-- ``` text
-- {
--   type = "radiotext",
--   ab_flag = <1-bit integer>,
--   text_address = <4-bit integer>,
--   text_data = <string, length 4 or 2>,
-- }
-- ```
--
-- Datetime data payload:
--
-- ``` text
-- {
--   type = "datetime",
--   date = {year = <integer>, month = <integer>, day = <integer>},
--   time = {hour = <integer>, minute = <integer>, offset = <integer>},
-- }
-- ```
--
-- Raw data payload (for unsupported group/version codes):
--
-- ``` text
-- {
--   type = "raw",
--   frame = {<16-bit integer>, <16-bit integer>, <16-bit integer>, <16-bit integer>},
-- }
-- ```
--
-- @datatype RDSDecoderBlock.RDSPacketType
-- @tparam table header Header table, as outlined above
-- @tparam table data Data payload table, as outlined above

local bit = require('bit')
local json = require('radio.thirdparty.json')

local block = require('radio.core.block')
local types = require('radio.types')

local RDSFrameType = require('radio.blocks.protocol.rdsframer').RDSFrameType

-- RDS Packet Type

local RDSPacketType = types.ObjectType.factory()

function RDSPacketType.new(header, data)
    local self = setmetatable({}, RDSPacketType)
    self.header = header
    self.data = data
    return self
end

function RDSPacketType:__tostring()
    return string.format("RDSPacket<pi_code=0x%04x, group_code=%u, group_version=%u, tp_code=%u, pty_code=%u, payload=%s>",
                         self.header.pi_code, self.header.group_code, self.header.group_version, self.header.tp_code, self.header.pty_code,
                         json.encode(self.data))
end

-- RDS Frame Decoders

local function rds_decode_header(frame)
    -- See RDS Standard 2.2, pg. 13

    -- Program Identification code = blocks[0][15:0]
    local pi_code = frame.blocks[0]
    -- Group code = blocks[1][15:12]
    local group_code = bit.rshift(frame.blocks[1], 12)
    -- Group version = blocks[1][11]
    local group_version = bit.band(bit.rshift(frame.blocks[1], 11), 0x1)
    -- Traffic program code = blocks[1][10]
    local tp_code = bit.band(bit.rshift(frame.blocks[1], 10), 0x1)
    -- Program type code = blocks[1][9:5]
    local pty_code = bit.band(bit.rshift(frame.blocks[1], 5), 0x1f)

    return {
        pi_code = pi_code,
        group_code = group_code,
        group_version = group_version,
        tp_code = tp_code,
        pty_code = pty_code,
    }
end

local function rds_decode_basic_tuning(header, frame)
    -- See RDS Standard 3.1.5.1, pg. 21

    -- Traffic announce code = blocks[1][4]
    local ta_code = bit.band(bit.rshift(frame.blocks[1], 4), 0x1)
    -- Music/speech switch code = blocks[1][3]
    local ms_code = bit.band(bit.rshift(frame.blocks[1], 3), 0x1)
    -- Text address = blocks[1][1:0]
    local text_address = bit.band(frame.blocks[1], 0x3)
    -- Decoder identification position = ~text address
    local di_position = 3-text_address
    -- Decoder identification bit value = blocks[1][2]
    local di_value = bit.band(bit.rshift(frame.blocks[1], 2), 0x1)
    -- Alternative frequencies code = blocks[2][15:8], blocks[2][7:0] (present in version 0 only)
    local af_code = (header.group_version == 0) and {bit.rshift(frame.blocks[2], 8), bit.band(frame.blocks[2], 0xff)} or nil
    -- Text = blocks[3][15:8], blocks[3][7:0]
    local text_data = string.char(bit.rshift(frame.blocks[3], 8), bit.band(frame.blocks[3], 0xff))

    return {
        type = 'basictuning',
        ta_code = ta_code,
        ms_code = ms_code,
        di_position = di_position,
        di_value = di_value,
        af_code = af_code,
        text_address = text_address,
        text_data = text_data,
    }
end

local function rds_decode_radiotext(header, frame)
    -- See RDS Standard 3.1.5.3, pg. 25

    -- A/B flag = blocks[1][4]
    local ab_flag = bit.band(bit.rshift(frame.blocks[1], 4), 0x1)
    -- Text address = blocks[1][3:0]
    local text_address = bit.band(frame.blocks[1], 0x0f)
    -- Text data = 4 characters for version 0, 2 characters for version 1
    local text_data
    if header.group_version == 0 then
        text_data = string.char(bit.rshift(frame.blocks[2], 8), bit.band(frame.blocks[2], 0xff), bit.rshift(frame.blocks[3], 8), bit.band(frame.blocks[3], 0xff))
    else
        text_data = string.char(bit.rshift(frame.blocks[3], 8), bit.band(frame.blocks[3], 0xff))
    end

    return {
        type = 'radiotext',
        ab_flag = ab_flag,
        text_address = text_address,
        text_data = text_data
    }
end

local function rds_decode_datetime(header, frame)
    -- See RDS Standard 3.1.5.6, pg. 28

    -- Modified Julian Day code = blocks[1][1:0], blocks[2][15:1]
    local mjd = bit.bor(bit.lshift(bit.band(frame.blocks[1], 0x3), 15), bit.rshift(bit.band(frame.blocks[2], 0xfffe), 1))
    -- Hour = blocks[2][0], blocks[3][15:12]
    local hour = bit.bor(bit.lshift(bit.band(frame.blocks[2], 0x1), 4), bit.rshift(bit.band(frame.blocks[3], 0xf000), 12))
    -- Minute = blocks[3][11:6]
    local minute = bit.band(bit.rshift(frame.blocks[3], 6), 0x3f)
    -- Offset = blocks[3][5:0]
    local offset = bit.band(frame.blocks[3], 0x3f)

    -- Convert offset to signed hours
    offset = (bit.band(offset, 0x20) ~= 0) and -bit.band(offset, 0x1f) or bit.band(offset, 0x1f)
    offset = offset * 0.5

    -- Convert MJD to year, month, day (RDS Standard Annex G, pg. 81)
    local yp = math.floor((mjd - 15078.2)/365.25)
    local mp = math.floor((mjd - 14956.1 - math.floor(yp * 365.25)) / 30.6001)
    local k = (mp == 14 or mp == 15) and 1 or 0
    local day = mjd - 14956 - math.floor(yp * 365.25) - math.floor(mp * 30.6001)
    local month = mp - 1 - k * 12
    local year = yp + k + 1900

    return {
        type = 'datetime',
        date = {year = year, month = month, day = day},
        time = {hour = hour, minute = minute, offset = offset}
    }
end

local function rds_decode_raw(header, frame)
    return {
        type = 'raw',
        frame = {frame.blocks[0], frame.blocks[1], frame.blocks[2], frame.blocks[3]}
    }
end

-- RDS Decode Block

local RDSDecoderBlock = block.factory("RDSDecoderBlock")

function RDSDecoderBlock:instantiate()
    self:add_type_signature({block.Input("in", RDSFrameType)}, {block.Output("out", RDSPacketType)})
end

RDSDecoderBlock.RDSPacketType = RDSPacketType

function RDSDecoderBlock:process(x)
    local out = RDSPacketType.vector()

    for i = 0, x.length-1 do
        -- Decode header
        local header = rds_decode_header(x.data[i])

        -- Decode data
        local data
        if header.group_code == 0x0 then
            data = rds_decode_basic_tuning(header, x.data[i])
        elseif header.group_code == 0x2 then
            data = rds_decode_radiotext(header, x.data[i])
        elseif header.group_code == 0x4 and header.group_version == 0 then
            data = rds_decode_datetime(header, x.data[i])
        else
            data = rds_decode_raw(header, x.data[i])
        end

        -- Emit the decoded frame
        out:append(RDSPacketType(header, data))
    end

    return out
end

return RDSDecoderBlock
