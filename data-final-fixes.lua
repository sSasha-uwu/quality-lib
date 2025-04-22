local common = require("__quality-lib__.common")
local quality_lib = require('__quality-lib__.module')

local qualities = table.deepcopy(data.raw["quality"])

local new_entities = {}
local new_items = {}

for prototype_name, prototype_value in pairs(quality_lib.get_changes()) do
    for entity_name, entity_value in pairs(prototype_value) do
        for quality_name, quality_value in pairs(qualities) do
            if quality_value.level > 0 then
                local new_entity = table.deepcopy(data.raw[prototype_name][entity_name])
                new_entity.localised_name = {"entity-name." .. new_entity.name}
                new_entity.localised_description = {"entity-description." .. new_entity.name}
                new_entity.hidden = false
                new_entity.name = common.mod_prefix .. quality_name .. "-" .. new_entity.name
                new_entity.placeable_by = {item=new_entity.name, count=1, quality=quality_value}
                new_entity.minable["result"] = new_entity.name
                if prototype_name == "transport-belt" then
                    new_entity.related_underground_belt = common.mod_prefix .. quality_name .. "-" .. new_entity.related_underground_belt
                end
                for stat_name, stat_value in pairs(entity_value) do
                    if common.is_dictionary(stat_value) then
                        for stat_table_name, stat_table_value in pairs(stat_value) do
                            new_entity[stat_name][stat_table_name] = stat_table_value[quality_value.level]
                        end
                    else
                        new_entity[stat_name] = stat_value[quality_value.level]
                    end
                end
                table.insert(new_entities, new_entity)
                local new_item = table.deepcopy(data.raw["item"][entity_name]) or table.deepcopy(data.raw["item-with-entity-data"][entity_name])
                new_item.name = common.mod_prefix .. quality_name .. "-" .. new_item.name
                new_item.place_result = new_entity.name
                new_item.subgroup = nil
                table.insert(new_items, new_item)
            end
        end
    end
end

if next(new_entities) then
    data.extend(new_entities)
end
if next(new_items) then
    data.extend(new_items)
end