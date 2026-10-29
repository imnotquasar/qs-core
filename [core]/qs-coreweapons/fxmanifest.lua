fx_version 'cerulean'
game 'gta5'

name 'qs-coreweapons'
author 'qscore'
description 'qscore | Weapons & Ammo'
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
}
