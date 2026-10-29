fx_version 'cerulean'
game 'gta5'

name 'esx_society'
author 'qscore'
description 'qscore | esx_society-compatible society accounts'
version '1.0.0'
lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

dependencies {
    'es_extended',
}
