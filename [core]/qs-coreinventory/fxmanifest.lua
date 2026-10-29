fx_version 'cerulean'
game 'gta5'

name 'qs-coreinventory'
author 'qscore'
description 'qscore | Inventory'
version '0.4.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
    'web/images/*.png',
    'web/images/*.svg',
}

dependencies {
    'qs-core',
    'oxmysql',
}
