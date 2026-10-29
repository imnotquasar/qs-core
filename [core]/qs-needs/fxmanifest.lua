fx_version 'cerulean'
game 'gta5'

name 'qs-needs'
author 'qscore'
description 'qscore | Hunger & Thirst'
version '0.1.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'shared/config.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'qs-core',
}
