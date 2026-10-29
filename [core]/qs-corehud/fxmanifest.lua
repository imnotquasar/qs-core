fx_version 'cerulean'
game 'gta5'

name 'qs-corehud'
author 'qscore'
description 'qscore | HUD'
version '0.5.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
}

client_scripts {
    'config.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
}

dependencies {
    'qs-core',
}
