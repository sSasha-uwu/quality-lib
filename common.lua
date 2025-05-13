local common = {}

common.mod_prefix = "sSasha__quality-lib__"

common.blacklisted_prototypes = {
    ["storage-tank"] = {

        -- Factorissimo 3
        
        "factory-1",
        "factory-2",
        "factory-3",
        "factory-connection-indicator-belt-d0",
        "factory-connection-indicator-chest-d0",
        "factory-connection-indicator-chest-d0",
        "factory-connection-indicator-chest-d10",
        "factory-connection-indicator-chest-d20",
        "factory-connection-indicator-chest-d60",
        "factory-connection-indicator-chest-d180",
        "factory-connection-indicator-chest-d600",
        "factory-connection-indicator-chest-b0",
        "factory-connection-indicator-chest-b10",
        "factory-connection-indicator-chest-b20",
        "factory-connection-indicator-chest-b60",
        "factory-connection-indicator-chest-b180",
        "factory-connection-indicator-chest-b600",
        "factory-connection-indicator-fluid-d0",
        "factory-connection-indicator-heat-b0",
        "factory-connection-indicator-heat-b5",
        "factory-connection-indicator-heat-b10",
        "factory-connection-indicator-heat-b30",
        "factory-connection-indicator-heat-b120",
        "factory-connection-indicator-circuit-b0",
    },
}

---@param name string
function common.config(name)
    return settings.startup[common.mod_prefix .. name]
end

---@param t table
function common.is_dictionary(t)
    for _, i in pairs(t) do
        if type(i) == "table" then
            return true
        end
    end
    return false
end

---@param entity table
function common.has_recipe(entity)
    if entity.prototype.type == "assembling-machine" or entity.prototype.type == "furnace" or entity.prototype.type == "rocket-silo" then
        return true
    end
    return false
end

---@param entity table
function common.has_modules(entity)
    if type(entity.get_module_inventory()) == "nil" or entity.get_module_inventory().get_contents() == "nil" then
        return false
    end
    return true
end

---@param String string
---@param Start integer
function common.startswith(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

---@param s string
function common.split_power_string(s)
    local number, unit = s:match("^(%d+%.?%d*)(%a*%u)$")
    if number and unit then
        return tonumber(number), unit
    else
        return nil, nil
    end
end

---@param item_name string
---@param rarities any
---@return string
function common.strip_rarity_prefix(item_name, rarities)
    for _, rarity in ipairs(rarities) do
        local prefix = rarity .. "-"
        if item_name:sub(1, #prefix) == prefix then
            return item_name:sub(#prefix + 1)
        end
    end
    return item_name
end

---@param err string
---@param source string
function common.error_handler(err, source)
    log("[ERROR] An error occurred in " .. source .. "\n" .. err)
end

return common
