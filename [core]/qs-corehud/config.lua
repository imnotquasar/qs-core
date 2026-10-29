Config = {}

Config.UpdateInterval = 250 -- ms

-- extra bars
Config.Show = {
    stamina = true,
    voice   = true, -- needs pma-voice
}

-- hide vanilla map popups
Config.HideGameText = true

Config.MinimapOnlyInVehicle = true

Config.Vehicle = {
    unit     = 'kmh', -- kmh / mph
    interval = 90,    -- ms while driving
    seatbelt = true,
    beltKey  = 'B',

    -- fuel export (or native)
    fuelResource = 'LegacyFuel', -- ps-fuel, cdn-fuel, ox_fuel...
    fuelExport   = 'GetFuel',
}
