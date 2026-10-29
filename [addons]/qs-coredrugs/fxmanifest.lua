fx_version 'cerulean'
game 'gta5'

name 'qs-coredrugs'
author 'qscore'
description 'qscore | Drugs (weed, cocaine, meth)'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'config.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
}

dependencies {
    'qs-core',
}
