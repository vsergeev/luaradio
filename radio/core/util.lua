---
-- Get the length of a table.
--
-- @local
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
-- Make a shallow clone of a table.
--
-- @local
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
-- Test if elem exists in array.
--
-- @local
-- @tparam array array Array
-- @tparam object elem Element
-- @treturn bool Result
local function array_exists(array, elem)
    for _, v in pairs(array) do
        if v == elem then
            return true
        end
    end
    return false
end

---
-- Find first element in array that satisfies predicate or return nil.
--
-- @local
-- @tparam array array Array
-- @tparam function predicate Predicate function
-- @return Element or nil
local function array_search(array, predicate)
    for _, v in pairs(array) do
        if predicate(v) then
            return v
        end
    end
    return nil
end

---
-- Test if all elements in array satisfy predicate.
--
-- @local
-- @tparam array array Array
-- @tparam function predicate Predicate function
-- @treturn bool Result
local function array_all(array, predicate)
    for _, v in pairs(array) do
        if not predicate(v) then
            return false
        end
    end
    return true
end

---
-- Test if two arrays are equal in length and element equality.
--
-- @local
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
-- @local
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

return {table_length = table_length, table_copy = table_copy, array_exists = array_exists, array_search = array_search, array_all = array_all, array_equals = array_equals, array_find = array_find}
