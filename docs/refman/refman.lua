local template = require("resty.template")
template.print = function(s) return s end

-- Blocks = {
--   <category> = {
--      type = "block" | "type",
--      info = { -- block
--          category = <category>,
--          name = <name>,
--          description = <description>,
--          params = {
--              {
--                  name = <name>,
--                  desc = <desc>,
--                  type = <type>,
--                  opt = <opt> or nil,
--              }, ...
--          }
--      }, ...
--   }, ...
-- }
local Blocks = {}

-- Modules = {
--   <module name> = {
--     {
--         type = "class" | "function" | "field",
--         info = { ... },
--     }, ...
--   }, ...
-- }
local Modules = {}

local function fix_whitespace(s)
    -- Trim beginning and ending whitespace
    s = string.gsub(s, "^%s*(.-)%s*$", "%1")
    -- Add leading newline to code fences (which gets mangled in the summary /
    -- description split by LDoc)
    s = string.gsub(s, "([^\n]) ```", "%1\n\n```")
    -- Trim first column of spaces after docstring comment
    s = string.gsub(s, "\n ", "\n")
    -- Add additional newline separate display mathjax
    s = string.gsub(s, "%$%$\n%$%$", "$$\n\n$$")

    return s
end

local function format_args_string(params)
    local required_args = {}
    local optional_args = {}

    for _, param in ipairs(params) do
        if param.opt == nil then
            required_args[#required_args + 1] = param.name
        elseif param.opt == true then
            optional_args[#optional_args + 1] = param.name
        else
            optional_args[#optional_args + 1] = param.name .. "=" .. tostring(param.opt)
        end
    end

    required_args = table.concat(required_args, ", ")
    optional_args = table.concat(optional_args, ", ")

    if #required_args > 0 and #optional_args > 0 then
        return required_args .. "[, " .. optional_args .. "]"
    elseif #required_args > 0 and #optional_args == 0 then
        return required_args
    elseif #optional_args > 0 and #required_args == 0 then
        return "[" .. optional_args .. "]"
    end

    return ""
end

local function extract_constructor(params, modifiers)
    local params_info = {}

    for i, param in ipairs(params or {}) do
        local name, desc = string.match(param, "([^%s]+)%s(.*)")
        local info = {
            name = name,
            desc = string.gsub(desc, "%s+%* ", "\n    * "),
            type = modifiers[i].type,
            opt = modifiers[i].opt,
        }
        params_info[#params_info + 1] = info
    end

    return params_info
end

local function extract_function(method, class_name)
    class_name = class_name or ""

    -- Extract arguments
    local method_args = {}
    for i, param in ipairs(method.params) do
        if method.modifiers.param[param] == nil then
            break
        end
        local info = {
            name = param,
            desc = fix_whitespace(method.params.map[param]),
            type = (method.modifiers.param[i] or {}).type,
            opt = (method.modifiers.param[i] or {}).opt,
        }
        method_args[#method_args + 1] = info
    end

    -- Extract returns
    local method_returns = {}
    for i, param in ipairs(method.ret or {}) do
        local info = {
            desc = param,
            type = method.modifiers['return'][i].type,
        }
        method_returns[#method_returns + 1] = info
    end

    -- Method info
    local info = {
        name = string.gsub(method.name, "[^%s]+([:.].*)", class_name .. "%1"),
        desc = fix_whitespace(method.summary .. method.description),
        args = method_args,
        args_string = format_args_string(method_args),
        returns = method_returns,
        raises = type(method.raise) == "string" and {method.raise} or method.raise,
        example = method.usage and fix_whitespace(method.usage[1]) or nil,
    }
    return info
end

local function extract_fields(table)
    -- Extract fields
    local fields_info = {}
    for _, param in ipairs(table.params) do
        local info = {
            name = param,
            desc = fix_whitespace(table.params.map[param]),
            type = table.modifiers.field[param].type,
        }
        fields_info[#fields_info + 1] = info
    end

    for subparam, _ in pairs(table.subparams) do
        for _, param in ipairs(table.subparams[subparam]) do
            local info = {
                name = param,
                desc = fix_whitespace(table.params.map[param]),
                type = table.modifiers.field[param].type,
            }
            fields_info[#fields_info + 1] = info
        end
    end

    return fields_info
end

local function lookup(module, type, name)
    for _, item in ipairs(Modules[module]) do
        if item.type == type and item.info.name == name then
            return item.info
        end
    end
end

local function format(t)
    for _, v in ipairs(t) do
        if v.tags.block then
            -- Extract constructor arguments
            local constructor_args = extract_constructor(v.tags.param, v.modifiers.param)

            -- Extract signature
            local signatures = {}
            for i, sig in ipairs(v.tags.signature) do
                signatures[i] = {inputs = {}, outputs = {}}
                local inputs, outputs = string.match(sig, "([^>]*)>([^>]*)")
                for name, type in string.gmatch(inputs, "([^:%s,]*):([^:%s,]*)") do
                    signatures[i].inputs[#signatures[i].inputs + 1] = {name = name, type = type}
                end
                for name, type in string.gmatch(outputs, "([^:%s,]*):([^:%s,]*)") do
                    signatures[i].outputs[#signatures[i].outputs + 1] = {name = name, type = type}
                end
            end

            -- Block info
            local info = {
                category = v.tags.category[1],
                name = v.tags.block[1],
                description = fix_whitespace(v.summary .. v.description),
                args = constructor_args,
                args_string = format_args_string(constructor_args),
                signatures = signatures,
                example = fix_whitespace(v.usage[1]),
            }

            -- Add it to our Blocks table
            Blocks[info.category] = Blocks[info.category] or {}
            Blocks[info.category][#Blocks[info.category] + 1] = {type = "block", info = info}

            -- If this block has an associated data type
            if #v.sections > 0 and v.sections[1].tags.datatype then
                v = v.sections[1]

                -- Extract constructor arguments
                local constructor_args = extract_constructor(v.tags.param, v.modifiers.param)

                -- Datatype info
                local type_info = {
                    name = v.tags.datatype[1],
                    description = fix_whitespace(v.summary .. v.description),
                    args = constructor_args,
                    args_string = format_args_string(constructor_args),
                    methods = {},
                }

                -- Add it to our Blocks table
                Blocks[info.category] = Blocks[info.category] or {}
                Blocks[info.category][#Blocks[info.category] + 1] = {type = "type", info = type_info}
            end
        elseif v.tags.datatype then
            -- Datatype methods
            local methods_info = {}
            for _, method in pairs(v.items) do
                methods_info[#methods_info + 1] = extract_function(method, v.tags.datatype[1])
            end

            -- Extract constructor arguments
            local constructor_args = extract_constructor(v.tags.param, v.modifiers.param)

            -- Datatype info
            local info = {
                name = v.tags.datatype[1],
                description = fix_whitespace(v.summary .. v.description),
                args = constructor_args,
                args_string = format_args_string(constructor_args),
                methods = methods_info,
                example = v.usage and fix_whitespace(v.usage[1]) or nil
            }

            -- Add it to our modules table
            Modules['radio.types'] = Modules['radio.types'] or {}
            Modules['radio.types'][#Modules['radio.types'] + 1] = {type = "class", info = info}
        else
            local module_name = string.gsub(v.name, ".core", "")

            -- Collect class types
            local classes_info = {}
            for _, item in ipairs(v.sections) do
                if item.type == "type" then
                    -- Extract constructor arguments
                    local constructor_args = extract_constructor(item.tags.param, item.modifiers.param)

                    -- Class info
                    local info = {
                        name = item.name,
                        description = fix_whitespace(item.summary .. item.description),
                        args = constructor_args,
                        args_string = format_args_string(constructor_args),
                        methods = {},
                        example = item.usage and fix_whitespace(item.usage[1]) or nil
                    }
                    classes_info[#classes_info + 1] = info
                end
            end

            -- Collect methods for classes
            for _, class_info in ipairs(classes_info) do
                for _, item in ipairs(v.items) do
                    if item.type == "function" and item.name:match("(.*):.*") == class_info.name then
                        class_info.methods[#class_info.methods + 1] = extract_function(item, class_info.name)
                    end
                end
            end

            -- Collect function types
            local functions_info = {}
            for _, item in ipairs(v.items) do
                if item.type == "function" and not item.name:find("[:.]") then
                    functions_info[#functions_info + 1] = extract_function(item)
                end
            end

            -- Collect field types
            local fields_info = {}
            for _, item in ipairs(v.items) do
                if item.type == "table" then
                    fields_info = extract_fields(item)
                end
            end

            -- Add it to our modules table
            Modules[module_name] = Modules[module_name] or {description = fix_whitespace(v.summary .. v.description)}
            for _, info in ipairs(classes_info) do
                Modules[module_name][#Modules[module_name] + 1] = {type = "class", info = info}
            end
            for _, info in ipairs(functions_info) do
                Modules[module_name][#Modules[module_name] + 1] = {type = "function", info = info}
            end
            for _, info in ipairs(fields_info) do
                Modules[module_name][#Modules[module_name] + 1] = {type = "field", info = info}
            end
        end
    end
    local s = template.render("refman.template.md", {Blocks = Blocks, Modules = Modules, lookup = lookup})
    print(s)
end

return {filter = format}
