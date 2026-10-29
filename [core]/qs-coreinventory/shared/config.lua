Config = {}

Config.MaxWeight = 50000 -- grams (50kg)

Config.Slots = 30
Config.Columns = 5

-- trunk
Config.TrunkSlots = 10
Config.TrunkColumns = 5
Config.TrunkMaxWeight = 100000
Config.TrunkReach = 1.8         -- m to the boot
Config.TrunkCloseDistance = 5.0 -- closes past this

-- glovebox
Config.GloveboxSlots = 5
Config.GloveboxColumns = 5
Config.GloveboxMaxWeight = 15000

-- also via RegisterStash / OpenStash
Config.Stashes = {
    -- { id = 'town_locker', label = 'Town Locker', slots = 50, maxWeight = 200000, columns = 5 },
}

Config.DefaultStack = 64 -- unless the item overrides it

Config.OpenKey = 'F1'

Config.RadialKey = 'TAB'
Config.RadialSlots = 5

-- new characters spawn with these
Config.StartingItems = {
    { name = 'water',   count = 2 },
    { name = 'bread',   count = 2 },
    { name = 'phone',   count = 1 },
    { name = 'id_card', count = 1 },
}
