local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local types = require('radio.types')

-- AX25 Related Constants

local AX25_RAW_FRAME_MAXLEN = 3184
local AX25_FRAME_MINLEN = 136
local AX25_FLAG_FIELD = 0x7e

local AX25FramerState = {IDLE = 1, FRAME = 2}

-- AX25 Frame Type

local AX25FrameType = types.ObjectType.factory()

function AX25FrameType.new(addresses, control, pid, payload)
    local self = setmetatable({}, AX25FrameType)
    self.addresses = addresses
    self.control = control
    self.pid = pid
    self.payload = payload
    return self
end

-- AX25 Framer Block

local AX25FramerBlock = block.factory("AX25FramerBlock")

function AX25FramerBlock:instantiate()
    self.state = AX25FramerState.IDLE
    self.byte_buffer = types.Bit.vector(8)
    self.byte_buffer_length = 0

    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", AX25FrameType)})
end

AX25FramerBlock.AX25FrameType = AX25FrameType

-- AX25 Frame Validation

local function ax25_compute_crc(bits, length)
    -- CRC-16-CCITT, reversed polynomial
    local crc

    crc = 0xffff

    for i = 0, length-1 do
        if bit.bxor(bit.band(crc, 0x1), bits.data[i].value) == 1 then
            crc = bit.bxor(bit.rshift(crc, 1), 0x8408)
        else
            crc = bit.rshift(crc, 1)
        end
    end

    crc = bit.band(bit.bnot(crc), 0xffff)

    return crc
end

local function ax25_unstuff_frame(raw_frame)
    local frame = types.Bit.vector()
    local ones_count = 0

    for i = 0, raw_frame.length-1 do
        if ones_count == 5 and raw_frame.data[i].value == 0 then
            -- Skip this stuffed bit
        else
            -- Copy this bit
            frame:append(raw_frame.data[i])
        end

        -- Update our ones count
        ones_count = (raw_frame.data[i].value == 1) and (ones_count + 1) or 0
    end

    return frame
end

local function ax25_validate_frame(frame)
    -- Check that the frame length is modulo 8
    if (frame.length % 8) ~= 0 then
        return false
    end

    -- Check that the frame length is sufficient
    if (frame.length + 16) < AX25_FRAME_MINLEN then
        return false
    end

    -- Check frame check sequence
    local computed_crc = ax25_compute_crc(frame, frame.length-16)
    local expected_crc = types.Bit.tonumber(frame, frame.length-16, 16, "lsb")
    if computed_crc ~= expected_crc then
        return false
    end

    return true
end

local function ax25_extract_frame(frame)
    local byte, bit_index = 0, 0

    -- Extract addresses
    local addresses = {}
    while true do
        local address = {callsign = "", ssid = 0}

        -- Extract callsign (6 bytes)
        for j = 1, 6 do
            if bit_index >= (frame.length - 16) then
                return nil
            end
            byte, bit_index = types.Bit.tonumber(frame, bit_index, 8, "lsb"), bit_index + 8
            address.callsign = address.callsign .. string.char(bit.rshift(byte, 1))
        end

        -- Extract ssid byte
        if bit_index >= (frame.length - 16) then
            return nil
        end
        byte, bit_index = types.Bit.tonumber(frame, bit_index, 8, "lsb"), bit_index + 8
        address.ssid = bit.rshift(byte, 1)

        -- Add the address to our address list
        addresses[#addresses + 1] = address

        -- If this is the last address, break
        if bit.band(byte, 0x1) == 1 then
            break
        end
    end

    -- Extract control byte
    local control
    if bit_index >= (frame.length - 16) then
        return nil
    end
    control, bit_index = types.Bit.tonumber(frame, bit_index, 8, "lsb"), bit_index + 8

    local pid = nil
    local payload = nil

    -- If there are additional bytes, extract PID and payload
    if bit_index < (frame.length - 16) then
        -- Extract PID byte
        if bit_index >= (frame.length-16) then
            return nil
        end
        pid, bit_index = types.Bit.tonumber(frame, bit_index, 8, "lsb"), bit_index + 8

        -- Extract payload
        payload = ""
        while bit_index < (frame.length-16) do
            byte, bit_index = types.Bit.tonumber(frame, bit_index, 8, "lsb"), bit_index + 8
            payload = payload .. string.char(byte)
        end
    end

    return AX25FrameType(addresses, control, pid, payload)
end

function AX25FramerBlock:process(x)
    local out = AX25FrameType.vector()
    local i = 0

    while i < x.length do
        -- Shift in as many bits as we can into the byte buffer
        if self.byte_buffer_length < 8 then
            local n = math.min(8 - self.byte_buffer_length, x.length - i)

            ffi.C.memcpy(self.byte_buffer.data[self.byte_buffer_length], x.data[i], n*ffi.sizeof(self.byte_buffer.data[0]))
            i, self.byte_buffer_length = i + n, self.byte_buffer_length + n
        end

        if self.state == AX25FramerState.IDLE and self.byte_buffer_length == 8 then
            if types.Bit.tonumber(self.byte_buffer, 0, 8, "lsb") == AX25_FLAG_FIELD then
                -- If we encounter the start flag

                -- Create a raw frame buffer and switch to FRAME
                self.raw_frame = types.Bit.vector()
                self.byte_buffer_length = 0
                self.state = AX25FramerState.FRAME
            else
                -- Shift state down by 1 bit
                ffi.C.memmove(self.byte_buffer.data[0], self.byte_buffer.data[1], (8-1)*ffi.sizeof(self.byte_buffer.data[0]))
                self.byte_buffer_length = self.byte_buffer_length - 1
            end
        elseif self.state == AX25FramerState.FRAME and self.byte_buffer_length == 8 then
            if types.Bit.tonumber(self.byte_buffer, 0, 8, "lsb") == AX25_FLAG_FIELD then
                -- If we encounter the end flag

                -- Unstuff the frame
                local unstuffed_frame = ax25_unstuff_frame(self.raw_frame)

                -- Validate and extract the frame
                local frame = ax25_validate_frame(unstuffed_frame) and ax25_extract_frame(unstuffed_frame)

                if frame then
                    debug.printf('[AX25FramerBlock] Valid frame detected, length %d bytes\n', unstuffed_frame.length/8 - 4)

                    -- Emit the frame
                    out:append(frame)

                    -- Switch back to idle
                    self.byte_buffer_length = 0
                    self.state = AX25FramerState.IDLE
                else
                    -- Reset the frame buffer and stay in FRAME,
                    -- since the flag sequence may be the start flag
                    self.byte_buffer_length = 0
                    self.raw_frame = types.Bit.vector()
                end
            elseif self.raw_frame.length > AX25_RAW_FRAME_MAXLEN then
                -- If our raw frame got too large, abandon it and switch to IDLE
                self.raw_frame = nil
                self.state = AX25FramerState.IDLE
            else
                -- Copy next bit over to raw frame buffer
                self.raw_frame:append(self.byte_buffer.data[0])

                -- Shift state down by 1 bit
                ffi.C.memmove(self.byte_buffer.data[0], self.byte_buffer.data[1], (8-1)*ffi.sizeof(self.byte_buffer.data[0]))
                self.byte_buffer_length = self.byte_buffer_length - 1
            end
        end
    end

    return out
end

return AX25FramerBlock
