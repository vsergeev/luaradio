local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local types = require('radio.types')

-- POCSAG Related constants

local POCSAGFramerState = { FRAME_SYNC = 1, BATCH = 2 }

local POCSAG_PREAMBLE_LENGTH = 576
local POCSAG_BATCH_LENGTH = 544
local POCSAG_CODEWORD_LENGTH = 32
local POCSAG_WORD_TYPE_MASK = 0x80000000
local POCSAG_IDLE_CODEWORD = 0x7a89c197
local POCSAG_FRAME_SYNC_CODEWORD = 0x7cd215d8
local POCSAG_FRAME_SYNC_CODEWORD_BITS = types.BitType.vector_from_array(
    {0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0}
)

-- Parity check matrix H transpose
--   (32x11) H^T = | P |  (21 x 11)
--                 | I |  (11 x 11)
local POCSAG_PARITY_CHECK_MATRIX = {
    [0x00000000] = 0x000,
    [bit.tobit(0x80000000)] = 0x769, [0x40000000] = 0x3b5, [0x20000000] = 0x1db, [0x10000000] = 0x784,
    [0x08000000] = 0x3c2, [0x04000000] = 0x689, [0x02000000] = 0x345, [0x01000000] = 0x1a3,
    [0x00800000] = 0x7b8, [0x00400000] = 0x3dc, [0x00200000] = 0x1ee, [0x00100000] = 0x79f,
    [0x00080000] = 0x4a6, [0x00040000] = 0x53b, [0x00020000] = 0x5f4, [0x00010000] = 0x2fa,
    [0x00008000] = 0x615, [0x00004000] = 0x30b, [0x00002000] = 0x6ec, [0x00001000] = 0x376,
    [0x00000800] = 0x6d3, [0x00000400] = 0x400, [0x00000200] = 0x200, [0x00000100] = 0x100,
    [0x00000080] = 0x080, [0x00000040] = 0x040, [0x00000020] = 0x020, [0x00000010] = 0x010,
    [0x00000008] = 0x008, [0x00000004] = 0x004, [0x00000002] = 0x002, [0x00000001] = 0x001,
}

-- Correction matrix for single bit correction
-- Mapping of syndrome to bit error position
local POCSAG_CORRECT_MATRIX = {
    [0x000] = 0x00000000,
    [0x769] = 0x80000000, [0x3b5] = 0x40000000, [0x1db] = 0x20000000, [0x784] = 0x10000000,
    [0x3c2] = 0x08000000, [0x689] = 0x04000000, [0x345] = 0x02000000, [0x1a3] = 0x01000000,
    [0x7b8] = 0x00800000, [0x3dc] = 0x00400000, [0x1ee] = 0x00200000, [0x79f] = 0x00100000,
    [0x4a6] = 0x00080000, [0x53b] = 0x00040000, [0x5f4] = 0x00020000, [0x2fa] = 0x00010000,
    [0x615] = 0x00008000, [0x30b] = 0x00004000, [0x6ec] = 0x00002000, [0x376] = 0x00001000,
    [0x6d3] = 0x00000800, [0x400] = 0x00000400, [0x200] = 0x00000200, [0x100] = 0x00000100,
    [0x080] = 0x00000080, [0x040] = 0x00000040, [0x020] = 0x00000020, [0x010] = 0x00000010,
    [0x008] = 0x00000008, [0x004] = 0x00000004, [0x002] = 0x00000002, [0x001] = 0x00000001,
}

-- POCSAG Frame Type

local POCSAGFrameType = types.ObjectType.factory()

function POCSAGFrameType.new(address, func, data)
    local self = setmetatable({}, POCSAGFrameType)
    self.address = address
    self.func = func
    self.data = data or {}
    return self
end

function POCSAGFrameType:__tostring()
    local data_strs = {}
    for i=1, #self.data do
        data_strs[#data_strs + 1] = string.format("0x%05x", self.data[i])
    end
    return string.format("POCSAGFrame<address = 0x%05x, func = %d, data = [%s]>", self.address, self.func, table.concat(data_strs, ", "))
end

-- POCSAG Frame Block

local POCSAGFrameBlock = block.factory("POCSAGFrameBlock")

function POCSAGFrameBlock:instantiate()
    -- Raw frame buffer
    self.buffer = types.BitType.vector(POCSAG_BATCH_LENGTH)
    self.buffer_length = 0
    self.state = POCSAGFramerState.FRAME_SYNC

    -- Current frame
    self.frame = nil

    self:add_type_signature({block.Input("in", types.BitType)}, {block.Output("out", POCSAGFrameType)})
end

POCSAGFrameBlock.POCSAGFrameType = POCSAGFrameType

-- POCSAG Codeword Correction

local function pocsag_correct_codeword(codeword)
    -- Codeword bits layout:
    --  MMMMMMMM MMMMMMMM MMMMMCCC CCCCCCCP
    -- 32-bit codeword = 21-bits message + 10-bits error correcting code + 1-bit parity

    -- Compute syndrome (transpose)
    --  s^T = (H x)^T = x^T H^T
    local syndrome = 0
    for i = 31, 0, -1 do
        local mask = bit.band(codeword, bit.lshift(1, i))
        syndrome = bit.bxor(syndrome, POCSAG_PARITY_CHECK_MATRIX[mask])
    end

    -- If the syndrome is zero, there is no error and return the original
    -- codeword
    if syndrome == 0 then
        return codeword
    end

    -- If there is a single correctable bit error, correct it and return the
    -- corrected bits
    if POCSAG_CORRECT_MATRIX[syndrome] then
        return bit.bxor(codeword, POCSAG_CORRECT_MATRIX[syndrome])
    end

    -- FIXME implement >1 bit error correction

    -- If the codeword is uncorrectable, return false
    return false
end

function POCSAGFrameBlock:process(x)
    local out = POCSAGFrameType.vector()
    local i = 0

    while i < x.length do
        -- Shift in as many bits as we can into the frame buffer
        if self.buffer_length < POCSAG_BATCH_LENGTH then
            -- Calculate the maximum number of bits we can shift
            local n = math.min(POCSAG_BATCH_LENGTH - self.buffer_length, x.length-i)

            ffi.C.memcpy(self.buffer.data[self.buffer_length], x.data[i], n*ffi.sizeof(self.buffer.data[0]))
            i, self.buffer_length = i + n, self.buffer_length + n
        end

        if self.state == POCSAGFramerState.FRAME_SYNC and self.buffer_length >= POCSAG_CODEWORD_LENGTH then
            -- Compute the correlation of frame buffer with frame sync codeword
            local corr = 0
            for i = 0, 32-1 do
                corr = corr + (2*POCSAG_FRAME_SYNC_CODEWORD_BITS.data[i].value - 1) * (2*self.buffer.data[i].value - 1)
            end

            -- If correlation is over 28 / 32, frame sync codeword is detected
            -- This allows for up to 2 bit errors.
            if corr >= 28 then
                io.stderr:write(string.format('[POCSAGFrameBlock] Frame sync codeword detected with correlation %d/32\n', corr))
                -- Switch to batch state
                self.state = POCSAGFramerState.BATCH
            else
                -- Shift frame buffer down by one bit
                ffi.C.memmove(self.buffer.data, self.buffer.data[1], self.buffer_length - 1)
                self.buffer_length = self.buffer_length - 1
            end
        elseif self.state == POCSAGFramerState.BATCH and self.buffer_length >= POCSAG_BATCH_LENGTH then
            -- Check for frame sync codeword
            local codeword = types.BitType.tonumber(self.buffer, 0, 32)
            local fs_codeword = pocsag_correct_codeword(codeword)

            -- If the codeword does not match the frame sync codeword
            if not fs_codeword or fs_codeword ~= POCSAG_FRAME_SYNC_CODEWORD then
                -- Emit the current frame
                if self.frame then
                    out:append(self.frame)
                    self.frame = nil
                end

                -- Switch back to frame sync state
                io.stderr:write(string.format('[POCSAGFrameBlock] End of frame (invalid frame sync codeword %s)\n', bit.tohex(codeword)))
                self.state = POCSAGFramerState.FRAME_SYNC
                goto continue
            end

            io.stderr:write('[POCSAGFrameBlock] Frame sync codeword found!\n')

            -- Extract and correct the 16 codewords of the batch
            local invalid_codeword_count = 0
            for j = 1, 16 do
                local codeword = pocsag_correct_codeword(types.BitType.tonumber(self.buffer, j*32, 32))
                invalid_codeword_count = (codeword == false) and (invalid_codeword_count+1) or 0

                if codeword == false then
                    -- Invalid codeword

                    -- Emit the current frame
                    if self.frame then
                        out:append(self.frame)
                        self.frame = nil
                    end

                    -- If we saw two invalid codewords in a row
                    if invalid_codeword_count == 2 then
                        -- This likely means the clock has slipped, so switch back
                        -- to frame sync state to catch the next batch.

                        -- Shift out batch bits processed thus far
                        ffi.C.memmove(self.buffer.data, self.buffer.data[(j+1)*32], self.buffer_length - (j+1)*32)
                        self.buffer_length = self.buffer_length - (j+1)*32

                        -- Switch back to frame sync state
                        io.stderr:write('[POCSAGFrameBlock] Two invalid codewords detected, going to frame sync\n')
                        self.state = POCSAGFramerState.FRAME_SYNC
                        goto continue
                    end
                elseif codeword == POCSAG_IDLE_CODEWORD then
                    -- Idle codeword

                    -- Emit the current frame
                    if self.frame then
                        out:append(self.frame)
                        self.frame = nil
                    end
                elseif bit.band(codeword, POCSAG_WORD_TYPE_MASK) == 0 then
                    -- Address codeword

                    -- Emit the current frame
                    if self.frame then
                        out:append(self.frame)
                        self.frame = nil
                    end

                    -- Create a new frame
                    self.frame = POCSAGFrameType()
                    -- Extract 18-bit address and concatenate it with 3-bit batch position LSB
                    self.frame.address = bit.bor(bit.band(bit.rshift(codeword, 10), 0x1ffff8), bit.rshift((j-1), 1))
                    -- Extract frame function bits
                    self.frame.func = bit.band(bit.rshift(codeword, 11), 0x3)
                elseif self.frame then
                    -- Data codeword (and we're inside a frame)

                    -- Extract 20-bit message bits
                    self.frame.data[#self.frame.data + 1] = bit.band(bit.rshift(codeword, 11), 0xfffff)
                end
            end

            -- Shift the batch bits out of our frame buffer
            ffi.C.memmove(self.buffer.data, self.buffer.data[POCSAG_BATCH_LENGTH], self.buffer_length - POCSAG_BATCH_LENGTH)
            self.buffer_length = self.buffer_length - POCSAG_BATCH_LENGTH
        end

        ::continue::
    end

    return out
end

return {POCSAGFrameType = POCSAGFrameType, POCSAGFrameBlock = POCSAGFrameBlock}
