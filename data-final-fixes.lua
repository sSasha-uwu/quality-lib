local common = require("__quality-lib__.common")
local quality_lib = require('__quality-lib__.module')

local success, response

---@param parent_table data.EntityPrototype | table
---@param prototype_value table
---@param quality_value data.QualityPrototype
local function alter_stats(parent_table, prototype_value, quality_value)
    if not parent_table or not prototype_value or not quality_value then
        error("Missing required parameters in alter_stats")
    end

    for stat_key, stat_value in pairs(prototype_value) do
        local original_stat = parent_table[stat_key]
        if not original_stat then
            goto continue
        end

        local energy_unit
        if type(original_stat) == "string" then
            original_stat, energy_unit = common.split_power_string(original_stat)
            if not original_stat then
                error(string.format("Invalid power string format for stat %s", stat_key))
            end
        end

        if type(original_stat) == "table" and common.is_dictionary(stat_value) then
            alter_stats(original_stat, stat_value, quality_value)
            goto continue
        end

        local new_stat_value
        if stat_value.delta_constant then
            new_stat_value = original_stat + (stat_value.delta_constant * quality_value.level)
        elseif stat_value.delta_additive then
            new_stat_value = original_stat * (1 + (stat_value.delta_additive * quality_value.level))
        elseif stat_value.delta_multiplicative then
            new_stat_value = original_stat * (stat_value.delta_multiplicative ^ quality_value.level)
        else
            new_stat_value = stat_value[quality_value.level] or stat_value[#stat_value]
            if not new_stat_value then
                error(string.format("No valid stat value found for level %d in stat %s", quality_value.level, stat_key))
            end
        end

        parent_table[stat_key] = energy_unit and tostring(new_stat_value) .. energy_unit or new_stat_value
        ::continue::
    end
end

---@param qualities table<string, data.QualityPrototype>
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
        if quality_value.level ~= 0 then
            --- @type table
            local original_entity = data.raw[parent_name][prototype_name]
            local prefix = common.mod_prefix .. quality_name .. "-"
            --- @type data.EntityPrototype
            local new_entity = table.deepcopy(original_entity)
            new_entity.localised_name = { "entity-name." .. new_entity.name }
            new_entity.localised_description = { "entity-description." .. new_entity.name }
            new_entity.name = prefix .. prototype_name
            --- @type data.ItemPrototype
            local new_item
            for data_name, _ in pairs(data.raw) do
                for _, item_value in pairs(data.raw[data_name]) do
                    if item_value.place_result and item_value.place_result == prototype_name then
                        new_item = table.deepcopy(item_value)
                        goto next
                    end
                end
            end
            ::next::
            if new_item then
                if new_entity.minable and new_entity.minable.result == new_item.name then
                    new_entity.minable.result = tostring(new_entity.name)
                elseif new_entity.placeable_by then
                    new_entity.placeable_by.item = tostring(prefix .. new_item.name)
                else
                    new_entity.placeable_by = { item = tostring(prefix .. new_item.name), count = 1 }
                end
                new_item.name = prefix .. new_item.name
                new_item.place_result = new_item.name
                new_item.subgroup = nil
                table.insert(new_prototypes, new_item)
            else
                error("Could not generate item for " .. prototype_name)
            end
            alter_stats(new_entity, prototype_value, quality_value)
            table.insert(new_prototypes, new_entity)

            local new_recycling_recipe = table.deepcopy(data.raw.recipe[prototype_name .. "-recycling"])
            new_recycling_recipe.name = prefix .. new_recycling_recipe.name
            new_recycling_recipe.ingredients[1].name = tostring(new_entity.name)
            table.insert(new_prototypes, new_recycling_recipe)
        end
    end
    return new_prototypes
end

local qualities = table.deepcopy(data.raw["quality"])

local prototype_table = {}

for parent_name, parent_value in pairs(quality_lib.get_changes()) do
    if parent_value["@all"] then
        for data_prototype_name, _ in pairs(data.raw[parent_name]) do
            if common.blacklisted_prototypes[parent_name] then
                for _, blacklisted_prototype in pairs(common.blacklisted_prototypes[parent_name]) do
                    if data_prototype_name == blacklisted_prototype then goto next end
                end
            end
            success, response = pcall(
                generate_quality_prototypes,
                qualities,
                parent_name,
                data_prototype_name,
                parent_value["@all"]
            )
            if not success and response and type(response) == "string" then
                common.error_handler(
                    response,
                    "generate_quality_prototypes() Prototype: [@all-" ..
                    parent_name .. "]-[" .. data_prototype_name .. "]")
            else
                local new_prototypes = response
                for _, prototype in pairs(new_prototypes) do
                    table.insert(prototype_table, prototype)
                end
            end
            ::next::
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
        if not success and response and type(response) == "string" then
            common.error_handler(
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
