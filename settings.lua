local common = require("__quality-lib__.common")

data:extend({
    {
        type = "bool-setting",
        name = common.mod_prefix .. "enable-quality-items",
        setting_type = "startup",
        default_value = true
    }
})