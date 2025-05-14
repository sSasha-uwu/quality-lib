local common = require("__quality-lib__.common")
local quality_lib = require('__quality-lib__.module')

local entity_gui_open = false

local controlled_entities = {}
for prototype_name, prototype_value in pairs(quality_lib.get_changes()) do
    for entity_name, entity_value in pairs(prototype_value) do
        controlled_entities[entity_name] = true
    end
end

local controlled_items = {}
for prototype_name, prototype_value in pairs(prototypes.entity) do
    if common.startswith(prototype_name, common.mod_prefix) then
        controlled_items[prototype_name] = true
    end
end

local rarities = {}

for rarity_name, _ in pairs(prototypes.quality) do
    table.insert(rarities, rarity_name)
end

local function check_entity(entity_name)
    if controlled_entities[entity_name] then
        return true
    end
    return false
end

local on_built = function(data)
    local entity = data.entity
    if entity.quality.level == 0 then return end
    if not check_entity(entity.name) then return end

    local surface = entity.surface
    local info = {
        name = common.mod_prefix .. entity.quality.name .. "-" .. entity.name,
        position = entity.position,
        direction = entity.direction,
        quality = entity.quality,
        force = entity.force,
        fast_replace = true,
        player = entity.last_user,
        spill = false,
    }
    local belt_to_ground_type = nil
    if entity.type == "underground-belt" then
        belt_to_ground_type = entity.belt_to_ground_type
        info.belt_to_ground = belt_to_ground_type
        if belt_to_ground_type == "output" then
            if info.direction == defines.direction.north then
                info.direction = defines.direction.south
            elseif info.direction == defines.direction.south then
                info.direction = defines.direction.north
            elseif info.direction == defines.direction.east then
                info.direction = defines.direction.west
            elseif info.direction == defines.direction.west then
                info.direction = defines.direction.east
            end
        end
    end
    if entity.type == "splitter" then
        info.splitter_filter = entity.splitter_filter
        info.splitter_input_priority = entity.splitter_input_priority
        info.splitter_output_priority = entity.splitter_output_priority
    end
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
    local created_entity = surface.create_entity(info)
    if has_recipe then
        created_entity.set_recipe(recipe, qual)
    end
    if has_modules then
        for _, module in pairs(modules) do
            created_entity.get_module_inventory().insert({
                name = module.name,
                count = module.count,
                quality = module
                    .quality
            })
        end
    end
    if created_entity.type == "underground-belt" and created_entity.belt_to_ground_type ~= belt_to_ground_type then
        created_entity.rotate()
    end
end

local on_inventory_changed = function(event)
    local inventory = game.get_player(event.player_index).get_main_inventory()
    if not inventory then return end
    for i = 1, #inventory do
        if entity_gui_open then goto continue end
        local stack = inventory[i]
        if not stack.valid_for_read then goto continue end
        if not stack then goto continue end
        if stack.quality.level == 0 then goto continue end
        if not check_entity(stack.name) then goto continue end
        local info = {
            name = common.mod_prefix .. stack.quality.name .. "-" .. stack.name,
            quality = stack.quality.name,
            count = stack.count
        }
        stack.set_stack(info)
        ::continue::
    end
end

local function on_player_dropped_item(event)
    if controlled_items[event.entity.stack.name] then
        event.entity.stack.set_stack({
            name = common.strip_rarity_prefix(string.sub(event.entity.stack.name, #common.mod_prefix + 1), rarities),
            count = event.entity.stack.count,
            quality = event.entity.stack.quality,
        })
    end
end

---@param event EventData.on_gui_opened
local function on_gui_opened(event)
    if event.gui_type ~= 1 then return end
    entity_gui_open = true
    local inventory = game.get_player(event.player_index).get_main_inventory()
    if not inventory then return end
    for i = 1, #inventory do
        local stack = inventory[i]
        if not stack.valid_for_read then goto continue end
        if not stack then goto continue end
        if stack.quality.level == 0 then goto continue end
        if not controlled_items[stack.name] then goto continue end
        local info = {
            name = common.strip_rarity_prefix(string.sub(stack.name, #common.mod_prefix + 1), rarities),
            quality = stack.quality.name,
            count = stack.count
        }
        stack.set_stack(info)
        ::continue::
    end
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    if event.gui_type ~= 1 then return end
    entity_gui_open = false
    local inventory = game.get_player(event.player_index).get_main_inventory()
    if not inventory then return end
    for i = 1, #inventory do
        local stack = inventory[i]
        if not stack.valid_for_read then goto continue end
        if not stack then goto continue end
        if stack.quality.level == 0 then goto continue end
        if not check_entity(stack.name) then goto continue end
        local info = {
            name = common.mod_prefix .. stack.quality.name .. "-" .. stack.name,
            quality = stack.quality.name,
            count = stack.count
        }
        stack.set_stack(info)
        ::continue::
    end
end

---@param event EventData.on_player_fast_transferred
local function on_ctrl_click_transfer(event)
    for _, inventory_type in pairs(defines.inventory) do
        local inventory = event.entity.get_inventory(inventory_type)
        if not inventory then goto next end
        for i = 1, #inventory do
            local stack = inventory[i]
            if not stack.valid_for_read then goto continue end
            if not stack then goto continue end
            if stack.quality.level == 0 then goto continue end
            if not controlled_items[stack.name] then goto continue end
            local info = {
                name = common.strip_rarity_prefix(string.sub(stack.name, #common.mod_prefix + 1), rarities),
                quality = stack.quality.name,
                count = stack.count
            }
            stack.set_stack(info)
            ::continue::
        end
        ::next::
    end
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)
script.on_event(defines.events.script_raised_revive, on_built)
if common.config("enable-quality-items").value then
    script.on_event(defines.events.on_player_main_inventory_changed, on_inventory_changed)
    script.on_event(defines.events.on_player_dropped_item, on_player_dropped_item)
    script.on_event(defines.events.on_gui_opened, on_gui_opened)
    script.on_event(defines.events.on_gui_closed, on_gui_closed)
    script.on_event(defines.events.on_player_fast_transferred, on_ctrl_click_transfer)
end
