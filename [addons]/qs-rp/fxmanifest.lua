fx_version 'cerulean'
game 'gta5'

name 'qs-rp'
author 'qscore'
description 'qscore | Roleplay commands (me, do, ooc, b, try, pm, ame)'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'locales/*.lua',
    'config.lua',
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'qs-core',
    'qs-corechat',
}
