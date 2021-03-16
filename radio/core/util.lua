---
-- Table and array utility functions.
--
-- @module radio.core.util

---
-- Get the length of a table.
--
-- @internal
-- @function table_length
-- @tparam table table Table
-- @treturn int Length
local function table_length(table)
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end

---
-- Get the keys of a table.
--
-- @internal
-- @function table_keys
-- @tparam table table Table
-- @treturn array Keys of table
local function table_keys(table)
    local keys = {}
    for k, _ in pairs(table) do
        keys[#keys + 1] = k
    end
    return keys
end

---
-- Make a shallow clone of a table.
--
-- @internal
-- @function table_copy
-- @tparam table table Table
-- @treturn table Cloned table
local function table_copy(table)
    local copy = {}
    for k, v in pairs(table) do
        copy[k] = v
    end
    return copy
end

---
-- Extend a table with another table.
--
-- @internal
-- @function table_extend
-- @tparam table table1 Table 1
-- @tparam table table2 Table 2
-- @treturn table Extended table
local function table_extend(table1, table2)
    local extended = table_copy(table1)
    for k, v in pairs(table2) do
        extended[k] = v
    end
    return extended
end

---
-- Concatenate two arrays.
--
-- @internal
-- @function array_concat
-- @tparam array arr1 Array 1
-- @tparam array arr2 Array 2
-- @treturn array Concatenated array
local function array_concat(arr1, arr2)
    local concat = {}
    for _, v in ipairs(arr1) do
        concat[#concat + 1] = v
    end
    for _, v in ipairs(arr2) do
        concat[#concat + 1] = v
    end
    return concat
end

---
-- Flatten an array.
--
-- @internal
-- @function array_flatten
-- @tparam array array Array
-- @tparam int|nil depth Depth to flatten or nil for no limit
-- @treturn array Flattened array
local function array_flatten(array, depth)
    if depth and depth == 0 then
        return array
    end

    local flattened = {}
    for _, v in ipairs(array) do
        if type(v) == "table" then
            for _, w in ipairs(array_flatten(v, depth and depth - 1)) do
                flattened[#flattened + 1] = w
            end
        else
            flattened[#flattened + 1] = v
        end
    end
    return flattened
end

---
-- Apply a function to an array.
--
-- @internal
-- @function array_map
-- @tparam array array Array
-- @tparam function func Function
-- @treturn array Mapped array
local function array_map(array, func)
    local mapped = {}
    for i, v in ipairs(array) do
        mapped[i] = func(v)
    end
    return mapped
end

---
-- Test if elem exists in array.
--
-- @internal
-- @function array_exists
-- @tparam array array Array
-- @tparam object elem Element
-- @treturn bool Result
local function array_exists(array, elem)
    for _, v in ipairs(array) do
        if v == elem then
            return true
        end
    end
    return false
end

---
-- Find first element in array that satisfies predicate or return nil.
--
-- @internal
-- @function array_search
-- @tparam array array Array
-- @tparam function predicate Predicate function
-- @return Element or nil
local function array_search(array, predicate)
    for _, v in ipairs(array) do
        if predicate(v) then
            return v
        end
    end
    return nil
end

---
-- Test if all elements in array satisfy predicate.
--
-- @internal
-- @function array_all
-- @tparam array array Array
-- @tparam function predicate Predicate function
-- @treturn bool Result
local function array_all(array, predicate)
    for _, v in ipairs(array) do
        if not predicate(v) then
            return false
        end
    end
    return true
end

---
-- Test if two arrays are equal in length and element equality.
--
-- @internal
-- @function array_equals
-- @tparam array a Array
-- @tparam array b Array
-- @treturn bool Result
local function array_equals(a, b)
    if #a ~= #b then
        return false
    end

    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end

    return true
end

---
-- Find elem in array or return nil.
--
-- @internal
-- @function array_find
-- @tparam array array Array
-- @tparam object elem Element
-- @treturn bool Result
local function array_find(array, elem)
    for i = 1, #array do
        if array[i] == elem then
            return i
        end
    end

    return nil
end

---
-- Parse command-line options from arguments.
--
-- Options specification format:
-- {
--     {<long name (string)>, <optional short name (string)>, <has argument (bool)>, <description (string)>},
--     ...
-- }
--
-- @internal
-- @function parse_args
-- @tparam array args Array of arguments
-- @tparam table options Option specifications
-- @treturn table Parsed options
local function parse_args(args, options)
    local parsed_options = {}

    local i = 1
    while i <= #args do
        if string.sub(args[i], 1, 1) == "-" and #args[i] > 1 then
            -- Option is a long option
            local opt_is_long = string.sub(args[i], 1, 2) == "--"
            -- Extract option name
            local opt_name = string.sub(args[i], opt_is_long and 3 or 2)

            -- Search for option specification
            local spec = array_search(options, function (opt) return opt[opt_is_long and 1 or 2] == opt_name end)
            if not spec then
                -- Treat unknown option as start of positional arguments
               break
            end

            -- If the option has an argument
            if spec[3] then
                if i == #args then
                    error({msg = string.format("Missing argument for option %s.", spec[1])})
                end

                -- Extract argument for parsed option
                parsed_options[spec[1]] = args[i + 1]
                i = i + 2
            else
                -- Store true for parsed option
                parsed_options[spec[1]] = true
                i = i + 1
            end
        else
            -- Positional
            break
        end
    end

    -- Absorb remaining arguments as positionals
    for j=0, #args - i do
        parsed_options[j + 1] = args[i + j]
    end

    return parsed_options
end

---
-- Format command-line options.
--
-- @internal
-- @function format_options
-- @tparam table options Option specifications
-- @treturn string Formatted options
local function format_options(options)
    local lines = {}
    for _, opt in ipairs(options) do
        if opt[2] then
            lines[#lines + 1] = string.format("%-24s%s", string.format("  -%s, --%s", opt[2], opt[1]), opt[4])
        else
            lines[#lines + 1] = string.format("%-24s%s", string.format("  --%s", opt[1]), opt[4])
        end
    end

    return table.concat(lines, "\n")
end

return {table_length = table_length, table_keys = table_keys, table_copy = table_copy, table_extend = table_extend, array_concat = array_concat, array_flatten = array_flatten, array_map = array_map, array_exists = array_exists, array_search = array_search, array_all = array_all, array_equals = array_equals, array_find = array_find, parse_args = parse_args, format_options = format_options}
