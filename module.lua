local common = require("__quality-lib__.common")

local quality_lib = {}

if not _G.quality_lib_changes then
    _G.quality_lib_changes = {}
    if prototypes then
        for entity_name, entity_value in pairs(prototypes.entity) do
            if common.startswith(entity_name, common.mod_prefix) then
                local entity_prototype = entity_value.type
                local original_entity_name = entity_name:match("^[^%-]+%-[^%-]+%-(.+)$")
                if not _G.quality_lib_changes[entity_prototype] then
                    _G.quality_lib_changes[entity_prototype] = {}
                end
                _G.quality_lib_changes[entity_prototype][original_entity_name] = {}
            end
        end
    end
end

--- @return table
function quality_lib.get_changes()
    return _G.quality_lib_changes
end

---@param new table
function quality_lib.add(new)
    ---@param current table
    ---@param target table
    local function add_recursive(current, target)
        for k, v in pairs(current) do
            if type(v) == "table" then
                if not target[k] then
                    target[k] = {}
                end
                add_recursive(v, target[k])
            else
                if target[k] then
                    log("[WARNING] Key: " .. k .. " is already present. Overwriting.")
                end
                target[k] = v
            end
        end
    end
    add_recursive(new, _G.quality_lib_changes)
end

return quality_lib