-- Quality values here are level 1-5 inclusive.
-- Base game quality levels are as follows: common = 0, uncommon = 1, rare = 2, epic = 3, legendary = 5
-- This means that the fourth value is unused by default, but if you have a mod that adds a quality for that value, then it will work.
-- If you have a mod that adds qualities beyond legendary, you will need to add those here.
-- In the future, there will be an option to have these values increment by a fixed/multiplicative value instead of having to define the entire array manually.
-- Currently supports stats that are a maximum of two indentations deep (the storage tank is an example of max stat depth). Not sure if adding more is necessary, but will if needed.

local common = require("__quality-lib__.common")

local quality_lib = {}

if not _G.quality_lib_changes then
    _G.quality_lib_changes = {}
    if prototypes then
        for entity_name, entity_value in pairs(prototypes.entity) do
            if entity_name:startswith(common.mod_prefix) then
                local entity_prototype = entity_value.type
                local original_entity_name = entity_name:match("^[^%-]+%-[^%-]+%-(.+)$")
                log(entity_name .. " " .. entity_prototype)
                if not _G.quality_lib_changes[entity_prototype] then
                    _G.quality_lib_changes[entity_prototype] = {}
                end
                _G.quality_lib_changes[entity_prototype][original_entity_name] = {}
            end
        end
    end
end

function quality_lib.get_changes()
    return _G.quality_lib_changes
end

function quality_lib.add(new)
    for k, v in pairs(new) do
        _G.quality_lib_changes[k] = v
    end
end

return quality_lib