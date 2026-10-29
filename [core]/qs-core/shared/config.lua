Config = {}

-- don't change this on a live server
Config.Identifier = 'license'
Config.MaxCharacters = 5

-- default spawn
Config.DefaultSpawn = vec4(-268.4842, -957.7139, 31.2231, 205.8032)

-- starting balances
Config.Accounts = {
    cash = 500,
    bank = 5000,
    black_money = 0,
}

Config.SaveInterval = 5 * 60 * 1000 -- ms
Config.Debug = true

-- ui palette
Config.Theme = {
    name         = 'blue',
    text         = '#eaf2ff',
    muted        = '#8ea6cc',
    primary      = '#3b82f6',
    primaryDim   = '#2563eb',
    accent       = '#5cbaf0',
    gradientFrom = 'rgba(59, 146, 246, 0.60)',
    gradientTo   = 'rgba(37, 99, 235, 0.30)',
    glow         = 'rgba(59, 130, 246, 0.45)',
    border       = 'rgba(96, 165, 250, 0.45)',
    panel        = 'rgba(20, 40, 78, 0.32)',
    -- status bars
    health       = '#5cf07c',
    armor        = '#3b82f6',
    hunger       = '#f0a83a',
    thirst       = '#24c8d8',
}

-- allow /colors
Config.AllowColorChange = true
Config.ColorCommand = 'colors'

-- must exist in shared/jobs.lua
Config.DefaultJob = 'unemployed'
Config.DefaultJobGrade = 0

Config.Locale = 'en' -- file in locales/

-- paycheck
Config.Paycheck = {
    enabled  = true,
    interval = 30 * 60 * 1000,
}

Config.Death = {
    respawnTime = 20,                                                         -- respawn delay (s)
    loseCashOnDeath = false,
    emsCooldown = 30000,                                                      -- EMS call cooldown (ms)
    anim = { dict = 'mini@cpr@char_b@cpr_def', clip = 'cpr_pumpchest_idle' }, -- downed lying anim
    hospitals = {                                                             -- nearest one is picked
        vec4(298.6, -584.6, 43.26, 65.0),
        vec4(-247.6, 6331.4, 32.4, 200.0),
    },
}

-- disable wanted/dispatch
Config.DisableWanted = true
Config.DisableDispatch = true

-- enable PvP
Config.EnablePvP = true

-- keep the weather dry
Config.DisableRain = true

-- thin out the world
Config.DisablePeds = false    -- ambient pedestrians
Config.DisableTraffic = false -- npc / parked cars

-- '' = off
Config.Webhooks = {
    money       = '',
    admin       = '',
    connections = '',
}

Config.EnableBans = true

-- inventory backend: 'auto' | 'basic' | 'advanced'
-- auto: qs-inventory = advanced, qs-coreinventory = basic
Config.Inventory = 'auto'
