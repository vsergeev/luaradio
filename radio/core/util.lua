local function table_length(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function table_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

local function array_exists(array, elem)
    for _, v in pairs(array) do
        if v == elem then
            return true
        end
    end
    return false
end

local function array_search(array, match_func)
    for _, v in pairs(array) do
        if match_func(v) then
            return v
        end
    end
    return nil
end

return {table_length = table_length, table_copy = table_copy, array_exists = array_exists, array_search = array_search}
