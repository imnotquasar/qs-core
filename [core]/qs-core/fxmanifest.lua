fx_version 'cerulean'
game 'gta5'

name 'qs-core'
author 'qscore'
description 'qscore | Framework Core'
version '0.4.0'
lua54 'yes'

shared_scripts {
    'shared/config.lua',
    'shared/jobs.lua',
    'shared/utils.lua',
    'locales/*.lua',
    'shared/locales.lua',
    'shared/main.lua',
    'shared/gangs.lua',
    'shared/items.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/permissions.lua',
    'server/inventory.lua',
    'server/player.lua',
    'server/accounts.lua',
    'server/offline.lua',
    'server/gangs.lua',
    'server/main.lua',
    'server/callbacks.lua',
    'server/bans.lua',
    'server/paycheck.lua',
    'server/death.lua',
    'server/commands.lua',
    'server/colors.lua',
    'server/groups.lua',
    'server/vehicles.lua',
}

client_scripts {
    'client/main.lua',
    'client/inventory.lua',
    'client/callbacks.lua',
    'client/disable.lua',
    'client/death.lua',
    'client/admin.lua',
    'client/noclip.lua',
    'client/teleport.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
}

dependencies {
    'oxmysql',
}
