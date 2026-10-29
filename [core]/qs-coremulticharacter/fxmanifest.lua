fx_version 'cerulean'
game 'gta5'

name 'qs-coremulticharacter'
author 'qscore'
description 'qscore | Multicharacter'
version '0.2.0'
lua54 'yes'

shared_scripts {
    'config.lua',
    'locales/*.lua',
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
