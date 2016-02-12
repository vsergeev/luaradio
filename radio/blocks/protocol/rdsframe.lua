local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local BitType = require('radio.types.bit').BitType
local CStructType = require('radio.types.cstruct').CStructType
local bits_to_number = require('radio.types.bit').bits_to_number

-- RDS Related constants

local RDS_FRAME_LEN = 104
local RDS_BLOCK_LEN = 26

local RDS_CODE_MATRIX = {
    [15] = 0x2000077, [14] = 0x10002e7, [13] = 0x08003af, [12] = 0x040030b,
    [11] = 0x0200359, [10] = 0x0100370, [ 9] = 0x00801b8, [ 8] = 0x00400dc,
    [ 7] = 0x002006e, [ 6] = 0x0010037, [ 5] = 0x00082c7, [ 4] = 0x00043bf,
    [ 3] = 0x0002303, [ 2] = 0x000135d, [ 1] = 0x0000b72, [ 0] = 0x00005b9,
}

local RDS_CORRECT_MESSAGE = {
    [0x077] = 0x2000000, [0x2e7] = 0x1000000, [0x3af] = 0x0800000, [0x30b] = 0x0400000,
    [0x359] = 0x0200000, [0x370] = 0x0100000, [0x1b8] = 0x0080000, [0x0dc] = 0x0040000,
    [0x06e] = 0x0020000, [0x037] = 0x0010000, [0x2c7] = 0x0008000, [0x3bf] = 0x0004000,
    [0x303] = 0x0002000, [0x35d] = 0x0001000, [0x372] = 0x0000800, [0x1b9] = 0x0000400,
}

local RDS_CORRECT_CODE_WORD = {
    [0x001] = true, [0x002] = true, [0x004] = true, [0x008] = true,
    [0x010] = true, [0x020] = true, [0x040] = true, [0x080] = true,
    [0x100] = true, [0x200] = true,
}

local RDS_OFFSET_WORDS = {
    A = 0x0fc, B = 0x198, C = 0x168, Cp = 0x350, D = 0x1b4,
}

-- RDS Frame Type

ffi.cdef[[
    typedef struct {
        uint16_t blocks[4];
    } rds_frame_t;
]]

local rds_frame_type_mt = {
    __tostring = function (self)
        return string.format("RDSFrame<0x%04x, 0x%04x, 0x%04x, 0x%04x>", self.blocks[0], self.blocks[1], self.blocks[2], self.blocks[3])
    end,
}

local RDSFrameType = CStructType.factory("rds_frame_t", rds_frame_type_mt)

-- RDS Frame Block

local RDSFrameBlock = block.factory("RDSFrameBlock")

function RDSFrameBlock:instantiate()
    self.rds_frame = BitType.vector(RDS_FRAME_LEN)
    self.rds_frame_length = 0
    self.synchronized = false

    self:add_type_signature({block.Input("in", BitType)}, {block.Output("out", RDSFrameType)})
end

-- RDS Block Validation

local function validate_block(block_bits, offset)
    -- Block bits layout:
    -- MMMM MMMM MMMM MMMM CC CCCC CCCC
    -- 26-bits = 16-bits message + 10-bits code word

    -- Reconstruct block bits from received message bits and code matrix
    local block_bits_expected = 0

    for i=0,15 do
        -- If message bit i is set
        if bit.band(block_bits, bit.lshift(1, 10+i)) ~= 0 then
            -- Add in the code matrix row corresponding to this message bit
            block_bits_expected = bit.bxor(block_bits_expected, RDS_CODE_MATRIX[i])
        end
    end

    -- Add offset word
    block_bits_expected = bit.bxor(block_bits_expected, offset)

    -- Compute CRC error
    local crc_error = bit.bxor(bit.band(block_bits_expected, 0x3ff), bit.band(block_bits, 0x3ff))

    -- If there is no error, return the original block bits
    if crc_error == 0 then
        return block_bits
    end

    -- If there is a single bit error in the message, correct it and return the
    -- corrected bits
    if RDS_CORRECT_MESSAGE[crc_error] then
        -- Correct message bit
        block_bits_expected = bit.bxor(block_bits_expected, RDS_CORRECT_MESSAGE[crc_error])
        -- Correct code word
        block_bits_expected = bit.bxor(block_bits_expected, crc_error)

        return block_bits_expected
    end

    -- If there is a single bit error in the code word, correct it and return
    -- the corrected bits
    if RDS_CORRECT_CODE_WORD[crc_error] then
        -- Return block bits expected with the corrected code word
        return block_bits_expected
    end

    -- If the block is erroneous and uncorrectable, return false
    return false
end

function RDSFrameBlock:process(x)
    local out = RDSFrameType.vector()
    local i = 0

    while i < x.length do
        -- Advance our frame buffer
        if self.rds_frame_length < RDS_FRAME_LEN then
            -- Calculate the maximum number of bits we can shift
            local n = math.min(RDS_FRAME_LEN - self.rds_frame_length, x.length-i)

            -- Shift in as many bits as possible from x
            ffi.C.memcpy(self.rds_frame.data[self.rds_frame_length], x.data[i], n*ffi.sizeof(self.rds_frame.data[0]))
            i, self.rds_frame_length = i + n, self.rds_frame_length + n
        elseif self.rds_frame_length == RDS_FRAME_LEN then
            -- Shift state down by 1 bit
            ffi.C.memmove(self.rds_frame.data[0], self.rds_frame.data[1], (RDS_FRAME_LEN-1)*ffi.sizeof(self.rds_frame.data[0]))

            -- Shift in 1 bit from x
            self.rds_frame.data[RDS_FRAME_LEN-1] = x.data[i]
            i = i + 1
        end

        -- Try to validate the frame
        if self.rds_frame_length == RDS_FRAME_LEN then
            -- Extract blocks as numbers
            local block_a = bits_to_number(self.rds_frame.data, RDS_BLOCK_LEN*0, RDS_BLOCK_LEN)
            local block_b = bits_to_number(self.rds_frame.data, RDS_BLOCK_LEN*1, RDS_BLOCK_LEN)
            local block_c = bits_to_number(self.rds_frame.data, RDS_BLOCK_LEN*2, RDS_BLOCK_LEN)
            local block_d = bits_to_number(self.rds_frame.data, RDS_BLOCK_LEN*3, RDS_BLOCK_LEN)

            -- Validate and correct the blocks
            correct_block_a = validate_block(block_a, RDS_OFFSET_WORDS.A)
            correct_block_b = validate_block(block_b, RDS_OFFSET_WORDS.B)
            correct_block_c = validate_block(block_c, RDS_OFFSET_WORDS.C) or validate_block(block_c, RDS_OFFSET_WORDS.Cp)
            correct_block_d = validate_block(block_d, RDS_OFFSET_WORDS.D)

            if correct_block_a and correct_block_b and correct_block_c and correct_block_d then
                -- Add the frame to our output buffer
                local frame = RDSFrameType({{
                                    bit.rshift(correct_block_a, 10),
                                    bit.rshift(correct_block_b, 10),
                                    bit.rshift(correct_block_c, 10),
                                    bit.rshift(correct_block_d, 10)
                              }})
                out:append(frame)

                -- Set synchronized and reset frame length
                self.synchronized = true
                self.rds_frame_length = 0
            else
                -- If we were synchronized just now
                if self.synchronized then
                    io.stderr:write(string.format("[RDSFrameBlock] Lost sync!     [ 0x%07x ] [ 0x%07x ] [ 0x%07x ] [ 0x%07x ]\n", block_a, block_b, block_c, block_d))
                    local function tobool(x) return x and true or false end
                    io.stderr:write(string.format("[RDSFrameBlock]                [ %-9s ] [ %-9s ] [ %-9s ] [ %-9s ]\n", tobool(correct_block_a), tobool(correct_block_b), tobool(correct_block_c), tobool(correct_block_d)))

                    self.synchronized = false
                end
            end
        end
    end

    return out
end

return {RDSFrameType = RDSFrameType, RDSFrameBlock = RDSFrameBlock}
