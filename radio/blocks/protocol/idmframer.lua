---
-- Validate and extract IDM frames from a bit stream.
--
-- @category Protocol
-- @block IDMFramerBlock
--
-- @signature in:Bit > out:IDMFrameType
--
-- @usage
-- local framer = radio.IDMFramerBlock()

---
-- IDM frame type, a Lua object with properties:
--
-- ``` text
-- {
--   type = "idm",
--   application_version = <8-bit integer>,
--   ert_type = <8-bit integer>,
--   ert_id = <32-bit integer>,
--   consumption_interval_count = <8-bit integer>,
--   module_programming_state = <8-bit integer>,
--   tamper_count = <6-byte string>,
--   async_count = <2-byte string>,
--   power_outage_flags = <6-byte string>,
--   last_consumption_count = <32-bit integer>,
--   differential_consumption_intervals = <53-byte string>,
--   transmit_time_offset = <16-bit integer>,
--   serial_crc = <16-bit integer>,
--   packet_crc = <16-bit integer>,
-- }
-- ```
--
-- @datatype IDMFramerBlock.IDMFrameType
-- @tparam string type Protocol type, constant "idm"
-- @tparam int application_version Application version field, 8-bits wide
-- @tparam int ert_type ERT Type field, 8-bits wide
-- @tparam int ert_id ERT ID field, 32-bits wide
-- @tparam int consumption_interval_count Consumption interval count field, 8-bits wide
-- @tparam int module_programming_state Module programming state field, 8-bits wide
-- @tparam string tamper_count Tamper count bytes, 6 bytes long
-- @tparam string async_count Async count bytes, 2 bytes long
-- @tparam string power_outage_flags Power outage bytes, 6 bytes long
-- @tparam int last_consumption_count Last consumption count field, 32-bits wide
-- @tparam string differential_consumption_intervals Differential consumption intevals string, 53 bytes long
-- @tparam int transmit_time_offset Transmit time offset field, 16-bits wide
-- @tparam int serial_crc Serial CRC field, 16-bits wide
-- @tparam int packet_crc Packet CRC field, 16-bits wide

local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local types = require('radio.types')

-- IDM Related Constants

local IDM_PREAMBLE = types.Bit.vector_from_array({0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1})
local IDM_FRAME_LEN = 736
local IDM_CODEWORD_LEN = 704
local IDM_CHECKSUM_LEN = 16

-- Parity check matrix
-- Mapping of bit position to syndrome
local IDM_CHECK_SYNDROMES = {} -- initialized in idm_initialize_crc()

-- Syndrome correction table (for single bit correction)
-- Mapping of syndrome to bit position
local IDM_CORRECT_SYNDROMES = {} -- initialized in idm_initialize_crc()

-- IDM Frame Type

local IDMFrameType = types.ObjectType.factory()

function IDMFrameType.new(application_version, ert_type, ert_id, consumption_interval_count, module_programming_state, tamper_count,
                          async_count, power_outage_flags, last_consumption_count, differential_consumption_intervals, transmit_time_offset,
                          serial_crc, packet_crc)
    local self = setmetatable({}, IDMFrameType)
    self.type = "idm"
    self.application_version = application_version
    self.ert_type = ert_type
    self.ert_id = ert_id
    self.consumption_interval_count = consumption_interval_count
    self.module_programming_state = module_programming_state
    self.tamper_count = tamper_count
    self.async_count = async_count
    self.power_outage_flags = power_outage_flags
    self.last_consumption_count = last_consumption_count
    self.differential_consumption_intervals = differential_consumption_intervals
    self.transmit_time_offset = transmit_time_offset
    self.serial_crc = serial_crc
    self.packet_crc = packet_crc
    return self
end

function IDMFrameType:__tostring()
    return string.format("IDMFrame<application_version=0x%02x, ert_type=0x%02x, ert_id=%u, consumption_interval_count=%u, module_programming_state=%u, last_consumption_count=%u, transmit_time_offset=%u, serial_crc=0x%04x, packet_crc=0x%04x>", self.application_version, self.ert_type, self.ert_id, self.consumption_interval_count, self.module_programming_state, self.last_consumption_count, self.transmit_time_offset, self.serial_crc, self.packet_crc)
end

-- IDM Framer Block

local IDMFramerBlock = block.factory("IDMFramerBlock")

IDMFramerBlock.IDM_PREAMBLE = IDM_PREAMBLE
IDMFramerBlock.IDM_FRAME_LEN = IDM_FRAME_LEN
IDMFramerBlock.IDMFrameType = IDMFrameType

function IDMFramerBlock:instantiate()
    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", IDMFrameType)})
end

local function idm_correct_codeword(bits, offset)
    -- 704-bit codeword = 688-bits message + 16-bits error correcting code

    -- Compute syndrome
    local syndrome = 0x866b
    for i = 0, IDM_CODEWORD_LEN-1 do
        if bits.data[offset + i].value == 1 then
            syndrome = bit.bxor(syndrome, IDM_CHECK_SYNDROMES[i])
        end
    end

    -- If the syndrome is zero, there is no error and return true
    if syndrome == 0 then
        return true
    end

    -- If there is a single correctable bit error, correct it and return true
    local error_index = IDM_CORRECT_SYNDROMES[syndrome]
    if error_index then
        bits.data[offset + error_index] = bits.data[offset + error_index]:bnot()
        return true
    end

    -- If the codeword is uncorrectable, return false
    return false
end

local function idm_compute_crc(bits, offset, length)
    local crc = 0xffff

    for i = 0, length-1 do
        if bit.bxor(bit.band(crc, 0x8000), bit.lshift(bits.data[i + offset].value, 15)) == 0x8000 then
            crc = bit.bxor(bit.lshift(crc, 1), 0x1021)
        else
            crc = bit.lshift(crc, 1)
        end
    end

    crc = bit.band(bit.bxor(crc, 0xffff), 0xffff)

    return crc
end

local function idm_initialize_crc()
    vec = types.Bit.vector(IDM_CODEWORD_LEN - IDM_CHECKSUM_LEN)

    -- Populate message bit syndromes
    for i = 0, vec.length-1 do
        vec.data[i].value = 1

        local syndrome = bit.bxor(idm_compute_crc(vec, 0, vec.length), 0x866b)
        IDM_CHECK_SYNDROMES[i] = syndrome
        IDM_CORRECT_SYNDROMES[syndrome] = i

        vec.data[i].value = 0
    end

    -- Populate checksum bit syndromes
    for i = 0, IDM_CHECKSUM_LEN-1 do
        local syndrome = bit.lshift(1, 15 - i)
        IDM_CHECK_SYNDROMES[vec.length + i] = syndrome
        IDM_CORRECT_SYNDROMES[syndrome] = vec.length + i
    end
end

function IDMFramerBlock:initialize()
    self.idm_frame = types.Bit.vector(IDM_FRAME_LEN)
    self.idm_frame_length = 0

    self.out = IDMFrameType.vector()

    idm_initialize_crc()
end

function IDMFramerBlock:process(x)
    local out = self.out:resize(0)

    local i = 0
    while i < x.length do
        -- Shift in as many bits as we can into the frame buffer
        if self.idm_frame_length < IDM_FRAME_LEN then
            -- Calculate the maximum number of bits we can shift from x
            local n = math.min(IDM_FRAME_LEN - self.idm_frame_length, x.length-i)

            ffi.copy(self.idm_frame.data[self.idm_frame_length], x.data[i], n*ffi.sizeof(self.idm_frame.data[0]))
            i, self.idm_frame_length = i + n, self.idm_frame_length + n
        elseif self.idm_frame_length == IDM_FRAME_LEN then
            -- Shift frame buffer down by one bit
            ffi.C.memmove(self.idm_frame.data[0], self.idm_frame.data[1], (IDM_FRAME_LEN-1)*ffi.sizeof(self.idm_frame.data[0]))

            -- Shift in one bit from x
            self.idm_frame.data[IDM_FRAME_LEN-1] = x.data[i]
            i = i + 1
        end

        -- Try to validate the frame
        if self.idm_frame_length == IDM_FRAME_LEN then
            local preamble = types.Bit.tonumber(self.idm_frame, 0, 16)
            local frame_sync = types.Bit.tonumber(self.idm_frame, 16, 16)

            if preamble == 0x5555 and frame_sync == 0x16a3 and idm_correct_codeword(self.idm_frame, 32) then
                local packet_type = types.Bit.tonumber(self.idm_frame, 32, 8)
                local packet_length = types.Bit.tonumber(self.idm_frame, 40, 16)
                local serial_crc = types.Bit.tonumber(self.idm_frame, 704, 16)

                if packet_type == 0x1c and packet_length == 0x5cc6 and serial_crc == idm_compute_crc(self.idm_frame, 72, 32) then
                    local application_version = types.Bit.tonumber(self.idm_frame, 56, 8)
                    local ert_type = types.Bit.tonumber(self.idm_frame, 64, 8)
                    local ert_id = types.Bit.tonumber(self.idm_frame, 72, 32)
                    local consumption_interval_count = types.Bit.tonumber(self.idm_frame, 104, 8)
                    local module_programming_state = types.Bit.tonumber(self.idm_frame, 112, 8)
                    local tamper_count = types.Bit.tobytes(self.idm_frame, 120, 48)
                    local async_count = types.Bit.tobytes(self.idm_frame, 168, 16)
                    local power_outage_flags = types.Bit.tobytes(self.idm_frame, 184, 48)
                    local last_consumption_count = types.Bit.tonumber(self.idm_frame, 232, 32)
                    local differential_consumption_intervals = types.Bit.tobytes(self.idm_frame, 264, 424)
                    local transmit_time_offset = types.Bit.tonumber(self.idm_frame, 688, 16)
                    local packet_crc = types.Bit.tonumber(self.idm_frame, 720, 16)

                    out:append(IDMFrameType(application_version, ert_type, ert_id, consumption_interval_count, module_programming_state, tamper_count,
                                            async_count, power_outage_flags, last_consumption_count, differential_consumption_intervals, transmit_time_offset,
                                            serial_crc, packet_crc))

                    self.idm_frame_length = 0
                end
            end
        end
    end

    return out
end

return IDMFramerBlock
