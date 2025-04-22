# Quality Lib
Provides a library for modders to easily interface with Quality and add quality stats to any item/entity.

Adding an item yourself is easy. First, import the mod in the file you wish to use:

```lua
local quality_lib = require('__quality-lib__.module')
```

Then use the `add` method to add your items to the library. Do this in the data stage, ideally the `data.lua` file.

```lua
quality_lib.add(
    {
        ["storage-tank"]={
            ["storage-tank"]={
                ["fluid_box"]={
                    ["volume"]={30000, 35000, 40000, 45000, 50000}
                }
            }
        },
    }
)
```

The values within the final table are the values for each level of quality. Notably, quality level four does not exist in vanilla Factorio, but if you have a mod that adds that quality, this will handle that just fine.

This will create a set of entities and items with the following names:

```lua
"sSasha__betterquality__common-storage-tank"
"sSasha__betterquality__uncommon-storage-tank"
"sSasha__betterquality__epic-storage-tank"
"sSasha__betterquality__rare-storage-tank"
"sSasha__betterquality__legendary-storage-tank"
```

The library currently only supports hardcoded values for quality levels, but I am planning on adding support for additive/multiplicative multipliers as well as constantly increasing values.

For more, see my Better Quality (https://github.com/sSasha-uwu/better-quality) mod which uses this library to make a number of quality entities and items.
