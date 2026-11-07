-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from Qbox (https://github.com/Qbox-project/qbx_core)
-- Copyright (C) Qbox Project and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

fx_version 'cerulean'
game 'gta5'

name 'qbx_core'
author 'qscore'
description 'qscore | Qbox Compatibility Bridge'
version '1.23.0'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'modules/lib.lua',
    'shared/locale.lua',
    'shared/functions.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/groups.lua',
    'server/player.lua',
    'server/functions.lua',
    'server/character.lua',
    'server/events.lua',
    'server/commands.lua',
}

files {
    'modules/*.lua',
    'data/*.lua',
    'shared/gangs.lua',
    'shared/items.lua',
    'shared/jobs.lua',
    'shared/locations.lua',
    'shared/main.lua',
    'shared/vehicles.lua',
    'shared/weapons.lua',
    'config/client.lua',
    'config/shared.lua',
    'locales/*.json',
}

dependencies {
    'qs-core',
    'qb-core',
    'ox_lib',
    'oxmysql',
}
