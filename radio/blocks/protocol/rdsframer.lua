local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local types = require('radio.types')

-- RDS Related constants

local RDS_FRAME_LEN = 104
local RDS_BLOCK_LEN = 26

-- Non-linear offset words, used to distinguish blocks
local RDS_OFFSET_WORDS = {
    A = 0x0fc, B = 0x198, C = 0x168, Cp = 0x350, D = 0x1b4,
}

-- Parity check matrix H transpose
--   (26x10) H^T = | P |  (16 x 10)
--                 | I |  (10 x 10)
local RDS_PARITY_CHECK_MATRIX = {
    [0x0000000] = 0x000,
    [0x2000000] = 0x077, [0x1000000] = 0x2e7, [0x0800000] = 0x3af, [0x0400000] = 0x30b,
    [0x0200000] = 0x359, [0x0100000] = 0x370, [0x0080000] = 0x1b8, [0x0040000] = 0x0dc,
    [0x0020000] = 0x06e, [0x0010000] = 0x037, [0x0008000] = 0x2c7, [0x0004000] = 0x3bf,
    [0x0002000] = 0x303, [0x0001000] = 0x35d, [0x0000800] = 0x372, [0x0000400] = 0x1b9,
    [0x0000200] = 0x200, [0x0000100] = 0x100, [0x0000080] = 0x080, [0x0000040] = 0x040,
    [0x0000020] = 0x020, [0x0000010] = 0x010, [0x0000008] = 0x008, [0x0000004] = 0x004,
    [0x0000002] = 0x002, [0x0000001] = 0x001,
}

-- Correction matrix for single bit correction
-- Mapping of syndrome to bit error position
local RDS_CORRECT_MATRIX = {
    [0x000] = 0x0000000,
    [0x077] = 0x2000000, [0x2e7] = 0x1000000, [0x3af] = 0x0800000, [0x30b] = 0x0400000,
    [0x359] = 0x0200000, [0x370] = 0x0100000, [0x1b8] = 0x0080000, [0x0dc] = 0x0040000,
    [0x06e] = 0x0020000, [0x037] = 0x0010000, [0x2c7] = 0x0008000, [0x3bf] = 0x0004000,
    [0x303] = 0x0002000, [0x35d] = 0x0001000, [0x372] = 0x0000800, [0x1b9] = 0x0000400,
    [0x200] = 0x0000200, [0x100] = 0x0000100, [0x080] = 0x0000080, [0x040] = 0x0000040,
    [0x020] = 0x0000020, [0x010] = 0x0000010, [0x008] = 0x0000008, [0x004] = 0x0000004,
    [0x002] = 0x0000002, [0x001] = 0x0000001,
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

local RDSFrameType = types.CStructType.factory("rds_frame_t", rds_frame_type_mt)

-- RDS Frame Block

local RDSFramerBlock = block.factory("RDSFramerBlock")

function RDSFramerBlock:instantiate()
    self.rds_frame = types.Bit.vector(RDS_FRAME_LEN)
    self.rds_frame_length = 0
    self.synchronized = false

    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", RDSFrameType)})
end

RDSFramerBlock.RDSFrameType = RDSFrameType

-- RDS Block Correction

local function rds_correct_block(block_bits, offset_word)
    -- Block bits layout:
    --  MMMM MMMM MMMM MMMM CC CCCC CCCC
    -- 26-bits block = 16-bits message + 10-bits error correcting code

    -- Subtract offset word
    local block_bits_received = bit.bxor(block_bits, offset_word)

    -- Compute syndrome (transpose)
    --  s^T = (H x)^T = x^T H^T
    local syndrome = 0
    for i = 25, 0, -1 do
        local mask = bit.band(block_bits_received, bit.lshift(1, i))
        syndrome = bit.bxor(syndrome, RDS_PARITY_CHECK_MATRIX[mask])
    end

    -- If the syndrome is zero, there is no error and return the original block
    -- bits
    if syndrome == 0 then
        return block_bits
    end

    -- If there is a single correctable bit error, correct it and return the
    -- corrected bits
    if RDS_CORRECT_MATRIX[syndrome] then
        return bit.bxor(block_bits, RDS_CORRECT_MATRIX[syndrome])
    end

    -- FIXME implement >1 bit error correction

    -- If the block is uncorrectable, return false
    return false
end

function RDSFramerBlock:process(x)
    local out = RDSFrameType.vector()
    local i = 0

    while i < x.length do
        -- Shift in as many bits as we can into the frame buffer
        if self.rds_frame_length < RDS_FRAME_LEN then
            -- Calculate the maximum number of bits we can shift from x
            local n = math.min(RDS_FRAME_LEN - self.rds_frame_length, x.length-i)

            ffi.C.memcpy(self.rds_frame.data[self.rds_frame_length], x.data[i], n*ffi.sizeof(self.rds_frame.data[0]))
            i, self.rds_frame_length = i + n, self.rds_frame_length + n
        elseif self.rds_frame_length == RDS_FRAME_LEN then
            -- Shift frame buffer down by one bit
            ffi.C.memmove(self.rds_frame.data[0], self.rds_frame.data[1], (RDS_FRAME_LEN-1)*ffi.sizeof(self.rds_frame.data[0]))

            -- Shift in one bit from x
            self.rds_frame.data[RDS_FRAME_LEN-1] = x.data[i]
            i = i + 1
        end

        -- Try to validate the frame
        if self.rds_frame_length == RDS_FRAME_LEN then
            -- Convert block bits to numbers
            local block_a = types.Bit.tonumber(self.rds_frame, RDS_BLOCK_LEN*0, RDS_BLOCK_LEN)
            local block_b = types.Bit.tonumber(self.rds_frame, RDS_BLOCK_LEN*1, RDS_BLOCK_LEN)
            local block_c = types.Bit.tonumber(self.rds_frame, RDS_BLOCK_LEN*2, RDS_BLOCK_LEN)
            local block_d = types.Bit.tonumber(self.rds_frame, RDS_BLOCK_LEN*3, RDS_BLOCK_LEN)

            -- Validate and correct the blocks
            correct_block_a = rds_correct_block(block_a, RDS_OFFSET_WORDS.A)
            correct_block_b = rds_correct_block(block_b, RDS_OFFSET_WORDS.B)
            correct_block_c = rds_correct_block(block_c, RDS_OFFSET_WORDS.C) or rds_correct_block(block_c, RDS_OFFSET_WORDS.Cp)
            correct_block_d = rds_correct_block(block_d, RDS_OFFSET_WORDS.D)

            -- If we have a correct RDS frame
            if correct_block_a and correct_block_b and correct_block_c and correct_block_d then
                -- Extract the 16 data bits from each block
                local data_a = bit.rshift(correct_block_a, 10)
                local data_b = bit.rshift(correct_block_b, 10)
                local data_c = bit.rshift(correct_block_c, 10)
                local data_d = bit.rshift(correct_block_d, 10)

                -- Add the frame to our output buffer
                local frame = RDSFrameType({{data_a, data_b, data_c, data_d}})
                out:append(frame)

                -- Set synchronized and reset frame buffer
                self.synchronized = true
                self.rds_frame_length = 0
            else
                -- If we lost synchronization
                if self.synchronized then
                    debug.printf("[RDSFramerBlock] Lost sync!     [ 0x%07x ] [ 0x%07x ] [ 0x%07x ] [ 0x%07x ]\n", block_a, block_b, block_c, block_d)
                    debug.printf("[RDSFramerBlock]                [ %-9s ] [ %-9s ] [ %-9s ] [ %-9s ]\n", correct_block_a ~= false, correct_block_b ~= false, correct_block_c ~= false, correct_block_d ~= false)
                    self.synchronized = false
                end
            end
        end
    end

    return out
end

return RDSFramerBlock
