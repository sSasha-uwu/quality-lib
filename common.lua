local common = {}

common.mod_prefix = "sSasha__quality-lib__"

function common.is_dictionary(t)
    for _,i in pairs(t) do
        if type(i) == "table" then
            return true
        end
    end
    return false
end

function common.has_recipe(entity)
    if entity.prototype.type == "assembling-machine" or entity.prototype.type == "furnace" or entity.prototype.type == "rocket-silo" then
        return true
    end
    return false
end

function common.has_modules(entity)
    if type(entity.get_module_inventory()) == "nil" or entity.get_module_inventory().get_contents() == "nil" then
        return false
    end
    return true
end

function string.startswith(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

return common