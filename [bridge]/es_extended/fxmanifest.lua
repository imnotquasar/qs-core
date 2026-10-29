fx_version 'cerulean'
game 'gta5'

name 'es_extended'
author 'qscore'
description 'qscore | ESX Compatibility Bridge'
version '1.13.4'
lua54 'yes'

shared_scripts {
    'shared/config/main.lua',
    'shared/main.lua',
    'config/items.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/common.lua',
    'server/classes/overrides/*.lua',
    'server/main.lua',
    'server/vehicles.lua',
    'server/users_compat.lua',
    'server/multichar_compat.lua',
    'server/bridge/**/*.lua',
}

client_scripts {
    'client/main.lua',
    'client/game.lua',
}

dependencies {
    'qs-core',
    -- Install one inventory resource and set Config.CustomInventory accordingly:
    -- 'ox_inventory' when Config.CustomInventory = 'ox'
    -- 'qs-inventory' when Config.CustomInventory = 'qs'
}
