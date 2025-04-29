local common = require("__quality-lib__.common")

local quality_lib = {}

if not _G.quality_lib_changes then
    _G.quality_lib_changes = {}
    if prototypes then
        for entity_name, entity_value in pairs(prototypes.entity) do
            if common.startswith(entity_name, common.mod_prefix) then
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
        if not _G.quality_lib_changes[k] then
            _G.quality_lib_changes[k] = {}
        end
        for k2, v2 in pairs(v) do
            if _G.quality_lib_changes[k][k2] then
                log("[WARNING]Key: " .. k2 .. " is already present. Overwriting.")
            end
            _G.quality_lib_changes[k][k2] = v2
        end
    end
end

return quality_lib