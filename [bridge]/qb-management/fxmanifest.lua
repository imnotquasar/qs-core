fx_version 'cerulean'
game 'gta5'

name 'qb-management'
author 'qscore'
description 'qscore | qb-management-compatible society accounts'
version '1.0.0'
lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

dependencies {
    'qs-core',
}
