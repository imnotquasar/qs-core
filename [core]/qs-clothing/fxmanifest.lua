fx_version 'cerulean'
game 'gta5'

name 'qs-clothing'
author 'qscore'
description 'qscore | Clothing'
version '0.2.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'shared/config.lua',
    'shared/clothing.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
}

dependencies {
    'qs-core',
}
