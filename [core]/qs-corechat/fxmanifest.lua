fx_version 'cerulean'
game 'gta5'

name 'qs-corechat'
author 'qscore'
description 'qscore | Chat'
version '0.1.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
}

dependencies {
    'qs-core',
}
