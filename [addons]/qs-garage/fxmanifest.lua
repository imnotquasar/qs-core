fx_version 'cerulean'
game 'gta5'

name 'qs-garage'
author 'qscore'
description 'qscore | Player Garage'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'config.lua',
    'garages.lua',
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
