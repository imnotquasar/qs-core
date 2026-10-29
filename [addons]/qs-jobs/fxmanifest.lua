fx_version 'cerulean'
game 'gta5'

name 'qs-jobs'
author 'qscore'
description 'qscore | Jobs (delivery, miner, lumberjack, fisher)'
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
