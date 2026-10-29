fx_version 'cerulean'
game 'gta5'

name 'qs-intro'
author 'qscore'
description 'qscore | Intro'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'config.lua',
}
client_script 'client.lua'

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**',
}

dependencies {
    'qs-core',
}
