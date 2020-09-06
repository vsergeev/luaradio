---
-- Validate and extract SCM frames from a bit stream.
--
-- @category Protocol
-- @block SCMFramerBlock
--
-- @signature in:Bit > out:SCMFrameType
--
-- @usage
-- local framer = radio.SCMFramerBlock()

---
-- SCM frame type, a Lua object with properties:
--
-- ``` text
-- {
--   type = "scm",
--   ert_type = <4-bit integer>,
--   ert_id = <26-bit integer>,
--   consumption = <24-bit integer>,
--   physical_tamper = <2-bit integer>,
--   encoder_tamper = <2-bit integer>,
--   reserved = <1-bit integer>,
--   crc = <16-bit integer>,
-- }
-- ```
--
-- @datatype SCMFramerBlock.SCMFrameType
-- @tparam string type Protocol type, constant "scm"
-- @tparam int ert_type ERT Type field, 4-bits wide
-- @tparam int ert_id ERT ID Field, 26-bits wide
-- @tparam int consumption Consumption field, 24-bits wide
-- @tparam int physical_tamper Physcal tamper field, 2-bits wide
-- @tparam int encoder_tamper Encoder tamper field, 2-bits wide
-- @tparam int reserved Reserved field, 1-bit wide
-- @tparam int crc CRC field, 16-bits wide

local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local types = require('radio.types')

-- SCM Related Constants

local SCM_PREAMBLE = types.Bit.vector_from_array({1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0})
local SCM_FRAME_LEN = 96
local SCM_CODEWORD_LEN = 75

-- Parity check matrix
-- Mapping of bit position to syndrome
local SCM_CHECK_SYNDROMES = {
    [0] = 0x6d9c, [1] = 0x36ce, [2] = 0x1b67, [3] = 0xba02,
    [4] = 0x5d01, [5] = 0x9931, [6] = 0xfb29, [7] = 0xca25,
    [8] = 0xd2a3, [9] = 0xdee0, [10] = 0x6f70, [11] = 0x37b8,
    [12] = 0x1bdc, [13] = 0x0dee, [14] = 0x06f7, [15] = 0xb4ca,
    [16] = 0x5a65, [17] = 0x9a83, [18] = 0xfaf0, [19] = 0x7d78,
    [20] = 0x3ebc, [21] = 0x1f5e, [22] = 0x0faf, [23] = 0xb066,
    [24] = 0x5833, [25] = 0x9ba8, [26] = 0x4dd4, [27] = 0x26ea,
    [28] = 0x1375, [29] = 0xbe0b, [30] = 0xe8b4, [31] = 0x745a,
    [32] = 0x3a2d, [33] = 0xaaa7, [34] = 0xe2e2, [35] = 0x7171,
    [36] = 0x8f09, [37] = 0xf035, [38] = 0xcfab, [39] = 0xd064,
    [40] = 0x6832, [41] = 0x3419, [42] = 0xadbd, [43] = 0xe16f,
    [44] = 0xc706, [45] = 0x6383, [46] = 0x8670, [47] = 0x4338,
    [48] = 0x219c, [49] = 0x10ce, [50] = 0x0867, [51] = 0xb382,
    [52] = 0x59c1, [53] = 0x9b51, [54] = 0xfa19, [55] = 0xcabd,
    [56] = 0xd2ef, [57] = 0xdec6, [58] = 0x6f63, [59] = 0x8000,
    [60] = 0x4000, [61] = 0x2000, [62] = 0x1000, [63] = 0x0800,
    [64] = 0x0400, [65] = 0x0200, [66] = 0x0100, [67] = 0x0080,
    [68] = 0x0040, [69] = 0x0020, [70] = 0x0010, [71] = 0x0008,
    [72] = 0x0004, [73] = 0x0002, [74] = 0x0001,
}

-- Syndrome correction table (for single bit correction)
-- Mapping of syndrome to bit position
local SCM_CORRECT_SYNDROMES = {
    [0x6d9c] = 0, [0x36ce] = 1, [0x1b67] = 2, [0xba02] = 3,
    [0x5d01] = 4, [0x9931] = 5, [0xfb29] = 6, [0xca25] = 7,
    [0xd2a3] = 8, [0xdee0] = 9, [0x6f70] = 10, [0x37b8] = 11,
    [0x1bdc] = 12, [0x0dee] = 13, [0x06f7] = 14, [0xb4ca] = 15,
    [0x5a65] = 16, [0x9a83] = 17, [0xfaf0] = 18, [0x7d78] = 19,
    [0x3ebc] = 20, [0x1f5e] = 21, [0x0faf] = 22, [0xb066] = 23,
    [0x5833] = 24, [0x9ba8] = 25, [0x4dd4] = 26, [0x26ea] = 27,
    [0x1375] = 28, [0xbe0b] = 29, [0xe8b4] = 30, [0x745a] = 31,
    [0x3a2d] = 32, [0xaaa7] = 33, [0xe2e2] = 34, [0x7171] = 35,
    [0x8f09] = 36, [0xf035] = 37, [0xcfab] = 38, [0xd064] = 39,
    [0x6832] = 40, [0x3419] = 41, [0xadbd] = 42, [0xe16f] = 43,
    [0xc706] = 44, [0x6383] = 45, [0x8670] = 46, [0x4338] = 47,
    [0x219c] = 48, [0x10ce] = 49, [0x0867] = 50, [0xb382] = 51,
    [0x59c1] = 52, [0x9b51] = 53, [0xfa19] = 54, [0xcabd] = 55,
    [0xd2ef] = 56, [0xdec6] = 57, [0x6f63] = 58, [0x8000] = 59,
    [0x4000] = 60, [0x2000] = 61, [0x1000] = 62, [0x0800] = 63,
    [0x0400] = 64, [0x0200] = 65, [0x0100] = 66, [0x0080] = 67,
    [0x0040] = 68, [0x0020] = 69, [0x0010] = 70, [0x0008] = 71,
    [0x0004] = 72, [0x0002] = 73, [0x0001] = 74,
}

-- SCM Frame Type

local SCMFrameType = types.ObjectType.factory()

function SCMFrameType.new(ert_type, ert_id, consumption, physical_tamper, encoder_tamper, reserved, crc)
    local self = setmetatable({}, SCMFrameType)
    self.type = "scm"
    self.ert_type = ert_type
    self.ert_id = ert_id
    self.consumption = consumption
    self.physical_tamper = physical_tamper
    self.encoder_tamper = encoder_tamper
    self.reserved = reserved
    self.crc = crc
    return self
end

function SCMFrameType:__tostring()
    return string.format("SCMFrame<ert_type=%u, ert_id=%u, consumption=%u, physical_tamper=%u, encoder_tamper=%u, reserved=%u, crc=0x%04x>", self.ert_type, self.ert_id, self.consumption, self.physical_tamper, self.encoder_tamper, self.reserved, self.crc)
end

-- SCM Framer Block

local SCMFramerBlock = block.factory("SCMFramerBlock")

SCMFramerBlock.SCM_PREAMBLE = SCM_PREAMBLE
SCMFramerBlock.SCM_FRAME_LEN = SCM_FRAME_LEN
SCMFramerBlock.SCMFrameType = SCMFrameType

function SCMFramerBlock:instantiate()
    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", SCMFrameType)})
end

function SCMFramerBlock:initialize()
    self.scm_frame = types.Bit.vector(SCM_FRAME_LEN)
    self.scm_frame_length = 0

    self.out = SCMFrameType.vector()
end

local function scm_correct_codeword(bits, offset)
    -- 75-bit codeword = 59-bits message + 16-bits error correcting code

    -- Compute syndrome
    local syndrome = 0
    for i = 0, SCM_CODEWORD_LEN-1 do
        if bits.data[offset + i].value == 1 then
            syndrome = bit.bxor(syndrome, SCM_CHECK_SYNDROMES[i])
        end
    end

    -- If the syndrome is zero, there is no error and return true
    if syndrome == 0 then
        return true
    end

    -- If there is a single correctable bit error, correct it and return true
    local error_index = SCM_CORRECT_SYNDROMES[syndrome]
    if error_index then
        bits.data[offset + error_index] = bits.data[offset + error_index]:bnot()
        return true
    end

    -- If the codeword is uncorrectable, return false
    return false
end

function SCMFramerBlock:process(x)
    local out = self.out:resize(0)

    local i = 0
    while i < x.length do
        -- Shift in as many bits as we can into the frame buffer
        if self.scm_frame_length < SCM_FRAME_LEN then
            -- Calculate the maximum number of bits we can shift from x
            local n = math.min(SCM_FRAME_LEN - self.scm_frame_length, x.length-i)

            ffi.copy(self.scm_frame.data[self.scm_frame_length], x.data[i], n*ffi.sizeof(self.scm_frame.data[0]))
            i, self.scm_frame_length = i + n, self.scm_frame_length + n
        elseif self.scm_frame_length == SCM_FRAME_LEN then
            -- Shift frame buffer down by one bit
            ffi.C.memmove(self.scm_frame.data[0], self.scm_frame.data[1], (SCM_FRAME_LEN-1)*ffi.sizeof(self.scm_frame.data[0]))

            -- Shift in one bit from x
            self.scm_frame.data[SCM_FRAME_LEN-1] = x.data[i]
            i = i + 1
        end

        -- Try to validate the frame
        if self.scm_frame_length == SCM_FRAME_LEN then
            local preamble = types.Bit.tonumber(self.scm_frame, 0, 21)

            if preamble == 0x1f2a60 and scm_correct_codeword(self.scm_frame, 21) then
                local ert_id_msb = types.Bit.tonumber(self.scm_frame, 21, 2)
                local reserved = types.Bit.tonumber(self.scm_frame, 23, 1)
                local physical_tamper = types.Bit.tonumber(self.scm_frame, 24, 2)
                local ert_type = types.Bit.tonumber(self.scm_frame, 26, 4)
                local encoder_tamper = types.Bit.tonumber(self.scm_frame, 30, 2)
                local consumption = types.Bit.tonumber(self.scm_frame, 32, 24)
                local ert_id_lsb = types.Bit.tonumber(self.scm_frame, 56, 24)
                local crc = types.Bit.tonumber(self.scm_frame, 80, 16)

                local ert_id = bit.bor(bit.lshift(ert_id_msb, 24), ert_id_lsb)

                out:append(SCMFrameType(ert_type, ert_id, consumption, physical_tamper, encoder_tamper, reserved, crc))

                self.scm_frame_length = 0
            end
        end
    end

    return out
end

return SCMFramerBlock
