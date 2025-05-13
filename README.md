# Quality Lib
Provides a library for modders to easily interface with Quality and add quality stats to any item/entity.

## Basics

Adding an item yourself is easy. First, import the mod in the data stage, ideally the `data.lua` file.

```lua
local quality_lib = require('__quality-lib__.module')
```

Then use the `add` method to add your items to the library.

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

The structure expected for the add function is as follows:

```lua
{
    ["PROTOTYPE_TYPE"]={
        ["PROTOTYPE_NAME"]={
            ["PROTOTYPE_FIELD"]={UNCOMMON_VALUE, RARE_VALUE, EPIC_VALUE, UNUSED_VALUE, LEGENDARY_VALUE}
        }
    }
}
```

You may have noticed that the structure is slightly different from the example. This is because the mod supports a infinite levels of field depth for stats that are nested. In the example, this allows you to edit the `volume` field within the `fluid_box` field without having to overwrite the entire `fluid_box` field with every quality step.

The values within the final table are the values for each level of quality. Notably, quality level four does not exist in vanilla Factorio, but if you have a mod that adds that quality, this will handle that just fine.

This will create a set of entities and items with the following names that will be automatically swapped in-game based on the quality level of the original item, allowing for as seamless of an experience as possible.

```lua
"sSasha__betterquality__uncommon-storage-tank"
"sSasha__betterquality__epic-storage-tank"
"sSasha__betterquality__rare-storage-tank"
"sSasha__betterquality__legendary-storage-tank"
```

## Delta Values

Instead of hardcoding each Quality level yourself, it is much easier to set a delta value within the final table that will automatically increment itself for each Quality level. This  also means your mod will automatically adjust for higher levels of Quality if someone else adds a mod that adds them.

There are three valid delta fields you can set, each one functioning slightly differently.

`delta_constant` This field increments the stat value by a constant value each Quality level.

`delta_additive` This field multiplies the base stat value by an increasing, additive multiplier each Quality level.

`delta_multiplicative` This field multiplies each Quality level by a multiplier, thus increasing the stat exponentially.

Example using a Cargo Wagon's inventory size (Base value = 40):

```lua
quality_lib.add(
    {
        ["cargo-wagon"]={
            ["cargo-wagon"]={
                ["inventory_size"]={delta_constant = 8}
            }
        }
    }
)
```

This will increase the stat by 8 for each level.

    Uncommon:  48
    Rare:      56
    Epic:      64
    Quality 4: 72
    Legendary: 80
    Quality 6: 88
    Quality 7: 96
    etc...

```lua
quality_lib.add(
    {
        ["cargo-wagon"]={
            ["cargo-wagon"]={
                ["inventory_size"]={delta_additive = 0.2}
            }
        }
    }
)
```

This will increase the multiplier by 0.2x each level, starting at 1.0x

    Uncommon:  48 (1.2x)
    Rare:      56 (1.4x)
    Epic:      64 (1.6x)
    Quality 4: 72 (1.8x)
    Legendary: 80 (2.0x)
    Quality 6: 88 (2.2x)
    Quality 7: 96 (2.4x)
    etc...

```lua
quality_lib.add(
    {
        ["cargo-wagon"]={
            ["cargo-wagon"]={
                ["inventory_size"]={delta_multiplicative = 1.2}
            }
        }
    }
)
```

This will multiply every level by the given multiplier, thus resulting in an exponential increase.

    Uncommon:  48
    Rare:      57.6
    Epic:      69.12
    Quality 4: 82.944
    Legendary: 99.5328
    Quality 6: 119.43936
    Quality 7: 143.327232
    etc...

## @all Special Key

Instead of having to specify Quality stat values for every single variant of of an entity, you can instead use the `["@all"]` special key as the `PROTOTYPE_NAME` key. This will iterate through all prototypes within the parent prototype and apply your quality changes to each of them, including modded prototypes..

You can use this key within a prototype type instead of having to specify every single individual prototype yourself. This will also cover modded prototypes for you.

Example using Transport Belts:

```lua
quality_lib.add(
    {
        ["transport-belt"]={
            ["@all"]={
                ["speed"]={delta_additive = 1.2}
            }
        },
    }
)
```

This will apply Quality scaling to all Transport Belts in the game, resulting in all Transport Belts having twice their speed at Legendary.

For more, see my Better Quality mod (https://github.com/sSasha-uwu/better-quality) which uses this library to make a number of quality entities and items.