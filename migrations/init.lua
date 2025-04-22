local common = require("__quality-lib__.common")
local quality_lib = require('__quality-lib__.module')

local controlled_entities = {}
for prototype_name, prototype_value in pairs(quality_lib.get_changes()) do
    for entity_name, entity_value in pairs(prototype_value) do
        controlled_entities[entity_name] = true
    end
end

local function check_entity(entity_name)
    if controlled_entities[entity_name] then return true end
    return false
end

for _, surface in pairs(game.surfaces) do
    for prototype_name, prototype_value in pairs(quality_lib.get_changes()) do
        for entity_name, entity_value in pairs(prototype_value) do
            for index, entity in pairs(surface.find_entities_filtered({name=entity_name})) do
                if entity.quality.level ~= 0 and check_entity(entity.name) then
                    local info = {
                        name = common.mod_prefix .. entity.quality.name .. "-" .. entity.name,
                        position = entity.position,
                        direction = entity.direction,
                        quality = entity.quality,
                        force = entity.force,
                        fast_replace = true,
                        player = entity.last_user,
                    }
                    local has_recipe = common.has_recipe(entity)
                    local has_modules = common.has_modules(entity)
                    local recipe, qual, modules
                    if has_recipe then
                        recipe, qual = entity.get_recipe()
                    end
                    if has_modules then
                        modules = entity.get_module_inventory().get_contents()
                    end
                    entity.destroy()
                    local new_entity = surface.create_entity(info)
                    if new_entity ~= nil then
                        if has_recipe then
                            new_entity.set_recipe(recipe, qual)
                        end
                        if has_modules then
                            for _, module in pairs(modules) do
                                new_entity.get_module_inventory().insert({name=module.name, count=module.count, quality=module.quality})
                            end
                        end
                    end
                end
            end
        end
    end
end