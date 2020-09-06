---
-- Validate and extract SCM+ frames from a bit stream.
--
-- @category Protocol
-- @block SCMPlusFramerBlock
--
-- @signature in:Bit > out:SCMPlusFrameType
--
-- @usage
-- local framer = radio.SCMPlusFramerBlock()

---
-- SCM+ frame type, a Lua object with properties:
--
-- ``` text
-- {
--   type = "scm+",
--   protocol_id = <8-bit integer>,
--   ert_type = <8-bit integer>,
--   ert_id = <32-bit integer>,
--   consumption = <32-bit integer>,
--   tamper = <16-bit integer>,
--   crc = <16-bit integer>,
-- }
-- ```
--
-- @datatype SCMPlusFramerBlock.SCMPlusFrameType
-- @tparam string type Protocol type, constant "scm+"
-- @tparam int protocol_id Protocol ID field, 8-bits wide
-- @tparam int ert_type ERT Type field, 8-bits wide
-- @tparam int ert_id ERT ID field, 32-bits wide
-- @tparam int consumption Consumption field, 32-bits wide
-- @tparam int tamper Tamper field, 16-bits wide
-- @tparam int crc CRC field, 16-bits wide

local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local types = require('radio.types')

-- SCM+ Related Constants

local SCM_PLUS_PREAMBLE = types.Bit.vector_from_array({0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1})
local SCM_PLUS_FRAME_LEN = 128
local SCM_PLUS_CODEWORD_LEN = 112

-- Parity check matrix
-- Mapping of bit position to syndrome
local SCM_PLUS_CHECK_SYNDROMES = {
    [0] = 0xaaa1, [1] = 0xdd40, [2] = 0x6ea0, [3] = 0x3750,
    [4] = 0x1ba8, [5] = 0x0dd4, [6] = 0x06ea, [7] = 0x0375,
    [8] = 0x89aa, [9] = 0x44d5, [10] = 0xaa7a, [11] = 0x553d,
    [12] = 0xa28e, [13] = 0x5147, [14] = 0xa0b3, [15] = 0xd849,
    [16] = 0xe434, [17] = 0x721a, [18] = 0x390d, [19] = 0x9496,
    [20] = 0x4a4b, [21] = 0xad35, [22] = 0xde8a, [23] = 0x6f45,
    [24] = 0xbfb2, [25] = 0x5fd9, [26] = 0xa7fc, [27] = 0x53fe,
    [28] = 0x29ff, [29] = 0x9cef, [30] = 0xc667, [31] = 0xeb23,
    [32] = 0xfd81, [33] = 0xf6d0, [34] = 0x7b68, [35] = 0x3db4,
    [36] = 0x1eda, [37] = 0x0f6d, [38] = 0x8fa6, [39] = 0x47d3,
    [40] = 0xabf9, [41] = 0xddec, [42] = 0x6ef6, [43] = 0x377b,
    [44] = 0x93ad, [45] = 0xc1c6, [46] = 0x60e3, [47] = 0xb861,
    [48] = 0xd420, [49] = 0x6a10, [50] = 0x3508, [51] = 0x1a84,
    [52] = 0x0d42, [53] = 0x06a1, [54] = 0x8b40, [55] = 0x45a0,
    [56] = 0x22d0, [57] = 0x1168, [58] = 0x08b4, [59] = 0x045a,
    [60] = 0x022d, [61] = 0x8906, [62] = 0x4483, [63] = 0xaa51,
    [64] = 0xdd38, [65] = 0x6e9c, [66] = 0x374e, [67] = 0x1ba7,
    [68] = 0x85c3, [69] = 0xcaf1, [70] = 0xed68, [71] = 0x76b4,
    [72] = 0x3b5a, [73] = 0x1dad, [74] = 0x86c6, [75] = 0x4363,
    [76] = 0xa9a1, [77] = 0xdcc0, [78] = 0x6e60, [79] = 0x3730,
    [80] = 0x1b98, [81] = 0x0dcc, [82] = 0x06e6, [83] = 0x0373,
    [84] = 0x89a9, [85] = 0xccc4, [86] = 0x6662, [87] = 0x3331,
    [88] = 0x9188, [89] = 0x48c4, [90] = 0x2462, [91] = 0x1231,
    [92] = 0x8108, [93] = 0x4084, [94] = 0x2042, [95] = 0x1021,
    [96] = 0x8000, [97] = 0x4000, [98] = 0x2000, [99] = 0x1000,
    [100] = 0x0800, [101] = 0x0400, [102] = 0x0200, [103] = 0x0100,
    [104] = 0x0080, [105] = 0x0040, [106] = 0x0020, [107] = 0x0010,
    [108] = 0x0008, [109] = 0x0004, [110] = 0x0002, [111] = 0x0001,
}

-- Syndrome correction table (for single bit correction)
-- Mapping of syndrome to bit position
local SCM_PLUS_CORRECT_SYNDROMES = {
    [0xaaa1] = 0, [0xdd40] = 1, [0x6ea0] = 2, [0x3750] = 3,
    [0x1ba8] = 4, [0x0dd4] = 5, [0x06ea] = 6, [0x0375] = 7,
    [0x89aa] = 8, [0x44d5] = 9, [0xaa7a] = 10, [0x553d] = 11,
    [0xa28e] = 12, [0x5147] = 13, [0xa0b3] = 14, [0xd849] = 15,
    [0xe434] = 16, [0x721a] = 17, [0x390d] = 18, [0x9496] = 19,
    [0x4a4b] = 20, [0xad35] = 21, [0xde8a] = 22, [0x6f45] = 23,
    [0xbfb2] = 24, [0x5fd9] = 25, [0xa7fc] = 26, [0x53fe] = 27,
    [0x29ff] = 28, [0x9cef] = 29, [0xc667] = 30, [0xeb23] = 31,
    [0xfd81] = 32, [0xf6d0] = 33, [0x7b68] = 34, [0x3db4] = 35,
    [0x1eda] = 36, [0x0f6d] = 37, [0x8fa6] = 38, [0x47d3] = 39,
    [0xabf9] = 40, [0xddec] = 41, [0x6ef6] = 42, [0x377b] = 43,
    [0x93ad] = 44, [0xc1c6] = 45, [0x60e3] = 46, [0xb861] = 47,
    [0xd420] = 48, [0x6a10] = 49, [0x3508] = 50, [0x1a84] = 51,
    [0x0d42] = 52, [0x06a1] = 53, [0x8b40] = 54, [0x45a0] = 55,
    [0x22d0] = 56, [0x1168] = 57, [0x08b4] = 58, [0x045a] = 59,
    [0x022d] = 60, [0x8906] = 61, [0x4483] = 62, [0xaa51] = 63,
    [0xdd38] = 64, [0x6e9c] = 65, [0x374e] = 66, [0x1ba7] = 67,
    [0x85c3] = 68, [0xcaf1] = 69, [0xed68] = 70, [0x76b4] = 71,
    [0x3b5a] = 72, [0x1dad] = 73, [0x86c6] = 74, [0x4363] = 75,
    [0xa9a1] = 76, [0xdcc0] = 77, [0x6e60] = 78, [0x3730] = 79,
    [0x1b98] = 80, [0x0dcc] = 81, [0x06e6] = 82, [0x0373] = 83,
    [0x89a9] = 84, [0xccc4] = 85, [0x6662] = 86, [0x3331] = 87,
    [0x9188] = 88, [0x48c4] = 89, [0x2462] = 90, [0x1231] = 91,
    [0x8108] = 92, [0x4084] = 93, [0x2042] = 94, [0x1021] = 95,
    [0x8000] = 96, [0x4000] = 97, [0x2000] = 98, [0x1000] = 99,
    [0x0800] = 100, [0x0400] = 101, [0x0200] = 102, [0x0100] = 103,
    [0x0080] = 104, [0x0040] = 105, [0x0020] = 106, [0x0010] = 107,
    [0x0008] = 108, [0x0004] = 109, [0x0002] = 110, [0x0001] = 111,
}

-- SCM+ Frame Type

local SCMPlusFrameType = types.ObjectType.factory()

function SCMPlusFrameType.new(protocol_id, ert_type, ert_id, consumption, tamper, crc)
    local self = setmetatable({}, SCMPlusFrameType)
    self.type = "scm+"
    self.protocol_id = protocol_id
    self.ert_type = ert_type
    self.ert_id = ert_id
    self.consumption = consumption
    self.tamper = tamper
    self.crc = crc
    return self
end

function SCMPlusFrameType:__tostring()
    return string.format("SCMPlusFrame<protocol_id=0x%02x, ert_type=0x%02x, ert_id=%u, consumption=%u, tamper=0x%04x, crc=0x%04x>", self.protocol_id, self.ert_type, self.ert_id, self.consumption, self.tamper, self.crc)
end

-- SCM+ Framer Block

local SCMPlusFramerBlock = block.factory("SCMPlusFramerBlock")

SCMPlusFramerBlock.SCM_PLUS_PREAMBLE = SCM_PLUS_PREAMBLE
SCMPlusFramerBlock.SCM_PLUS_FRAME_LEN = SCM_PLUS_FRAME_LEN
SCMPlusFramerBlock.SCMPlusFrameType = SCMPlusFrameType

function SCMPlusFramerBlock:instantiate()
    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", SCMPlusFrameType)})
end

function SCMPlusFramerBlock:initialize()
    self.scm_plus_frame = types.Bit.vector(SCM_PLUS_FRAME_LEN)
    self.scm_plus_frame_length = 0

    self.out = SCMPlusFrameType.vector()
end

local function scm_plus_correct_codeword(bits, offset)
    -- 112-bit codeword = 96-bits message + 16-bits error correcting code

    -- Compute syndrome
    local syndrome = 0x7b06
    for i = 0, SCM_PLUS_CODEWORD_LEN-1 do
        if bits.data[offset + i].value == 1 then
            syndrome = bit.bxor(syndrome, SCM_PLUS_CHECK_SYNDROMES[i])
        end
    end

    -- If the syndrome is zero, there is no error and return true
    if syndrome == 0 then
        return true
    end

    -- If there is a single correctable bit error, correct it and return true
    local error_index = SCM_PLUS_CORRECT_SYNDROMES[syndrome]
    if error_index then
        bits.data[offset + error_index] = bits.data[offset + error_index]:bnot()
        return true
    end

    -- If the codeword is uncorrectable, return false
    return false
end

function SCMPlusFramerBlock:process(x)
    local out = self.out:resize(0)

    local i = 0
    while i < x.length do
        -- Shift in as many bits as we can into the frame buffer
        if self.scm_plus_frame_length < SCM_PLUS_FRAME_LEN then
            -- Calculate the maximum number of bits we can shift from x
            local n = math.min(SCM_PLUS_FRAME_LEN - self.scm_plus_frame_length, x.length-i)

            ffi.copy(self.scm_plus_frame.data[self.scm_plus_frame_length], x.data[i], n*ffi.sizeof(self.scm_plus_frame.data[0]))
            i, self.scm_plus_frame_length = i + n, self.scm_plus_frame_length + n
        elseif self.scm_plus_frame_length == SCM_PLUS_FRAME_LEN then
            -- Shift frame buffer down by one bit
            ffi.C.memmove(self.scm_plus_frame.data[0], self.scm_plus_frame.data[1], (SCM_PLUS_FRAME_LEN-1)*ffi.sizeof(self.scm_plus_frame.data[0]))

            -- Shift in one bit from x
            self.scm_plus_frame.data[SCM_PLUS_FRAME_LEN-1] = x.data[i]
            i = i + 1
        end

        -- Try to validate the frame
        if self.scm_plus_frame_length == SCM_PLUS_FRAME_LEN then
            local frame_sync = types.Bit.tonumber(self.scm_plus_frame, 0, 16)

            if frame_sync == 0x16a3 and scm_plus_correct_codeword(self.scm_plus_frame, 16) then
                local protocol_id = types.Bit.tonumber(self.scm_plus_frame, 16, 8)

                if protocol_id == 0x1e then
                    local ert_type = types.Bit.tonumber(self.scm_plus_frame, 24, 8)
                    local ert_id = types.Bit.tonumber(self.scm_plus_frame, 32, 32)
                    local consumption = types.Bit.tonumber(self.scm_plus_frame, 64, 32)
                    local tamper = types.Bit.tonumber(self.scm_plus_frame, 96, 16)
                    local crc = types.Bit.tonumber(self.scm_plus_frame, 112, 16)

                    out:append(SCMPlusFrameType(protocol_id, ert_type, ert_id, consumption, tamper, crc))

                    self.scm_plus_frame_length = 0
                end
            end
        end
    end

    return out
end

return SCMPlusFramerBlock
