fx_version 'cerulean'
game 'gta5'

name 'qs-vehicleshop'
author 'qscore'
description 'qscore | Vehicle Dealership'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'config.lua',
}
client_script 'client.lua'
server_script 'server.lua'

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
}

dependencies {
    'qs-core',
}
