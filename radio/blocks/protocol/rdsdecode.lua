local bit = require('bit')

local object = require('radio.core.object')
local block = require('radio.core.block')
local RDSFrameType = require('radio.blocks.protocol.rdsframe').RDSFrameType

-- RDS Packet Type

local RDSPacketType = object.class_factory()

function RDSPacketType.new(frame, header, data)
    local self = setmetatable({}, RDSPacketType)
    self.frame = frame
    self.header = header
    self.data = data
    return self
end

-- RDS Frame Decoders

local function rds_decode_basic_tuning(version, frame)
    -- Traffic announce flag = block2[4]
    local traffic_announce_flag = bit.band(frame[2], 0x10) ~= 0 and true or false
    -- Music/speech switch flag = block2[3]
    local music_speech_flag = bit.band(frame[2], 0x08) ~= 0 and true or false
    -- Text address = block2[1:0]
    local text_address = bit.band(frame[2], 0x03)
    -- Decoder identification bit = block2[2]
    local decoder_identification = {position = 3-text_address, value = bit.band(frame[2], 0x04) ~= 0 and true or false}
    -- Alternative frequencies (present in version 0) = block3[15:8], block3[7:0]
    local alternate_frequencies = (version == 0) and {bit.rshift(frame[3], 8), bit.band(frame[3], 0xff)} or nil
    -- Text = block4[15:8], block4[7:0]
    local text_data = string.char(bit.rshift(frame[4], 8), bit.band(frame[4], 0xff))

    return {
        type = 'basictuning',
        traffic_announce_flag = traffic_announce_flag,
        music_speech_flag = music_speech_flag,
        decoder_identification = decoder_identification,
        alternate_frequencies = alternate_frequencies,
        text_address = text_address,
        text_data = text_data
    }
end

local function rds_decode_radiotext(version, frame)
    -- A/B flag = block2[4]
    local ab_flag = bit.band(frame[2], 0x10) ~= 0 and true or false
    -- Text address = block2[3:0]
    local text_address = bit.band(frame[2], 0x0f)
    -- Text (4 characters for version 0, 2 characters for version 1)
    local text_data = (version == 0) and
                   string.char(bit.rshift(frame[3], 8), bit.band(frame[3], 0xff), bit.rshift(frame[4], 8), bit.band(frame[4], 0xff))
                   or string.char(bit.rshift(frame[4], 8), bit.band(frame[4], 0xff))

    return {
        type = 'radiotext',
        ab_flag = ab_flag,
        text_address = text_address,
        text_data = text_data
    }
end

local function rds_decode_datetime(version, frame)
    -- See RDS Standard 3.1.5.6, pg. 28
    -- Modified Julian Day code = block2[1:0], block3[15:1]
    local mjd = bit.bor(bit.lshift(bit.band(frame[2], 0x3), 15), bit.rshift(bit.band(frame[3], 0xfffe), 1))
    -- Hour = frame3[0], frame4[15:12]
    local hour = bit.bor(bit.lshift(bit.band(frame[3], 0x1), 4), bit.rshift(bit.band(frame[4], 0xf000), 12))
    -- Minute = frame4[11:6]
    local minute = bit.band(bit.rshift(frame[4], 6), 0x3f)
    -- Offset = frame4[5:0]
    local offset = bit.band(frame[4], 0x3f)

    -- Convert offset to signed hours
    offset = (bit.band(offset, 0x20) ~= 0) and -bit.band(offset, 0x1f) or bit.band(offset, 0x1f)
    offset = offset * 0.5

    -- See RDS Standard Annex G, pg. 81
    -- Convert MJD to year, month, day
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

-- RDS Frame Decoder table

local function rds_decoder_index(group, version)
    return group*2 + version
end

local rds_decoder_table = {
    [rds_decoder_index(0x0, 0)] = rds_decode_basic_tuning,
    [rds_decoder_index(0x0, 1)] = rds_decode_basic_tuning,
    [rds_decoder_index(0x2, 0)] = rds_decode_radiotext,
    [rds_decoder_index(0x2, 1)] = rds_decode_radiotext,
    [rds_decoder_index(0x4, 0)] = rds_decode_datetime,
}

-- RDS Program Type Table

-- See RDS Standard Annex F, pg. 95
local RDS_PTY_TABLE = {
    [0] = "None", [1] = "News", [2] = "Information", [3] = "Sports",
    [4] = "Talk", [5] = "Rock", [6] = "Classic Rock", [7] = "Adult Hits",
    [8] = "Soft Rock", [9] = "Top 40", [10] = "Country", [11] = "Oldies",
    [12] = "Soft", [13] = "Nostalgia", [14] = "Jazz", [15] = "Classical",
    [16] = "Rhythm and Blues", [17] = "Soft Rhythm and Blues", [18] = "Foreign Language",
    [19] = "Religious Music", [20] = "Religious Talk", [21] = "Personality", [22] = "Public",
    [23] = "College", [24] = "Unassigned", [25] = "Unassigned", [26] = "Unassigned",
    [27] = "Unassigned", [28] = "Unassigned", [29] = "Weather", [30] = "Emergency Test",
}

-- RDS Decode Block

local RDSDecodeBlock = block.factory("RDSDecodeBlock")

function RDSDecodeBlock:instantiate()
    self:add_type_signature({block.Input("in", RDSFrameType)}, {})
end

function RDSDecodeBlock:process(x)
    for i = 0, x.length-1 do
        -- Extract frame blocks
        local frame = {x.data[i].blocks[0], x.data[i].blocks[1], x.data[i].blocks[2], x.data[i].blocks[3]}
        print(x.data[i])

        -- Extract header
        local header = {
            -- Program Identification Code = block1[15:0]
            pi = frame[1],
            -- Group type code = block2[15:12]
            group = bit.rshift(frame[2], 12),
            -- Version code = block2[11]
            version = bit.band(bit.rshift(frame[2], 11), 0x1),
            -- Traffic program code = block2[10]
            tp = bit.band(frame[2], 0x400) ~= 0 and true or false,
            -- Program type code = block2[9:5]
            pty_code = bit.band(bit.rshift(frame[2], 5), 0x1f),
        }
        -- Look up the program type
        header.pty = RDS_PTY_TABLE[header.pty_code]

        -- Decode data
        local index = rds_decoder_index(header.group, header.version)
        local data = rds_decoder_table[index] and rds_decoder_table[index](header.version, frame) or nil

        -- Assemble packet
        local packet = RDSPacketType(frame, header, data)

        -- FIXME emit the packet
        local s = string.format("RDSPacket<\n") ..
                  string.format("  pi = 0x%04x\n", header.pi) ..
                  string.format("  group = %d\n", header.group) ..
                  string.format("  version = %d\n", header.version) ..
                  string.format("  tp = %s\n", header.tp) ..
                  string.format("  pty_code = %d\n", header.pty_code) ..
                  string.format("  pty = \"%s\"\n", header.pty)
        if data then
            s = s .. string.format("  data = {\n", header.pty)
            for k,v in pairs(data) do
                if type(v) == "string" then
                    s = s .. string.format("    %s = \"%s\"\n", tostring(k), tostring(v))
                else
                    s = s .. string.format("    %s = %s\n", tostring(k), tostring(v))
                end
            end
            s = s .. "  }\n"
        end
        s = s .. ">"
        --print(s)
    end
end

return {RDSDecodeBlock = RDSDecodeBlock}
