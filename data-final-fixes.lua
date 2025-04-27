local common = require("__quality-lib__.common")
local quality_lib = require('__quality-lib__.module')

local success, response

function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

local function get_qualities()

    local qualities = table.deepcopy(data.raw["quality"])

    local quality_array = {}
    for k, v in pairs(qualities) do
        table.insert(quality_array, {key = k, value = v})
    end

    table.sort(quality_array, function(a, b)
        return a.value.level < b.value.level
    end)

    local sorted_qualities = {}
    for _, item in ipairs(quality_array) do
        sorted_qualities[item.key] = item.value
    end

    return sorted_qualities
end

---@param parent_table table
---@param prototype_value table
---@param quality_value table
---@return table
local function alter_stats(parent_table, prototype_value, quality_value)
    for stat_key, stat_value in pairs(prototype_value) do
        local energy_unit
        local original_stat = parent_table[stat_key]
        if type(original_stat) == "string" then
            original_stat, energy_unit = common.split_power_string(original_stat)
        end
        if common.is_dictionary(stat_value) then
            alter_stats(original_stat, stat_value, quality_value)
        else
            if stat_value.delta_constant then
                stat_value = original_stat + (stat_value.delta_constant * quality_value.level)
            elseif stat_value.delta_additive then
                stat_value = original_stat * (1 + (stat_value.delta_additive * quality_value.level))
            elseif stat_value.delta_multiplicative then
                stat_value = original_stat * (stat_value.delta_multiplicative ^ quality_value.level)
            else
                if stat_value[quality_value.level] then
                    stat_value = stat_value[quality_value.level]
                else
                    stat_value = stat_value[#stat_value]
                end
            end
            if energy_unit then
                parent_table[stat_key] = tostring(stat_value) .. energy_unit
            else
                parent_table[stat_key] = stat_value
            end
        end
    end
    return parent_table
end

---@param qualities table
---@param parent_name string
---@param prototype_name string
---@param prototype_value table
---@return table
local function generate_quality_prototypes(
    qualities,
    parent_name,
    prototype_name,
    prototype_value
)
    local new_prototypes = {}
    for quality_name, quality_value in pairs(qualities) do
        if quality_value.level > 0 then
            local prefix = common.mod_prefix .. quality_name .. "-"
            log(prefix .. prototype_name)

            local new_items = {}

            local new_entity = table.deepcopy(data.raw[parent_name][prototype_name])
            new_entity.localised_name = {"entity-name." .. new_entity.name}
            new_entity.localised_description = {"entity-description." .. new_entity.name}
            new_entity.name = prefix .. new_entity.name
            table.insert(new_items, new_entity.name)
            if new_entity.placeable_by then
                new_entity.placeable_by.item = prefix .. new_entity.placeable_by.item
                if new_entity.placeable_by.item ~= new_entity.name then
                    table.insert(new_items, new_entity.placeable_by.item)
                end
            end
            if new_entity.minable then
                new_entity.minable.result = prefix .. new_entity.minable.result
                if new_entity.minable.result ~= new_entity.name then
                    table.insert(new_items, new_entity.minable.result)
                end
            end
            if new_entity.related_underground_belt then
                new_entity.related_underground_belt = common.mod_prefix .. quality_name .. "-" .. new_entity.related_underground_belt
            end
            new_entity = alter_stats(new_entity, prototype_value, quality_value)

            for item_name in new_items do
                local new_item = nil
                for item_prototype, _ in pairs(data.raw) do
                    if item_prototype:startswith("item") and data.raw[item_prototype][item_name] then
                        new_item = table.deepcopy(data.raw[item_prototype][item_name])
                        goto next
                    end
                end
                ::next::
                if new_item then
                    new_item.name = prefix .. new_item.name
                    new_item.place_result = prefix .. new_item.place_result
                    new_item.subgroup = nil
                    table.insert(new_prototypes, new_item)
                end
            end
        end
    end
    return new_prototypes
end

local qualities = get_qualities()

local prototype_table = {}

for parent_name, parent_value in pairs(quality_lib.get_changes()) do
    if parent_value["@all"] then
        for data_prototype_name, _ in pairs(data.raw[parent_name]) do
            success, response = pcall(
                generate_quality_prototypes,
                qualities,
                parent_name,
                data_prototype_name,
                parent_value["@all"]
            )
            if not success and response then common.error_handler(
                response,
                "generate_quality_prototypes() Prototype: [@all-" .. parent_name .. "]-[" .. data_prototype_name .. "]")
            else
                local new_prototypes = response
                for _, prototype in pairs(new_prototypes) do
                    table.insert(prototype_table, prototype)
                end
            end
        end
        goto continue
    end
    for prototype_name, prototype_value in pairs(parent_value) do
        success, response = pcall(
        generate_quality_prototypes,
        qualities,
            parent_name,
            prototype_name,
            prototype_value
        )
        if not success and response then common.error_handler(
            response,
            "generate_quality_prototypes() Prototype: [" .. parent_name .. "]-[" .. prototype_name .. "]")
        else
            local new_prototypes = response
            for _, prototype in pairs(new_prototypes) do
                table.insert(prototype_table, prototype)
            end
        end
    end
    ::continue::
end

if next(prototype_table) then
    data:extend(prototype_table)
end