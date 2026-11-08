-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from QBCore (https://github.com/qbcore-framework/qb-core)
-- Copyright (C) QBCore Framework and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

fx_version 'cerulean'
game 'gta5'

name 'qb-core'
author 'qscore'
description 'qscore | QBCore Compatibility Bridge'
version '1.2.0'
lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/main.lua',
    'shared/functions.lua',
    'shared/locale.lua',
    'shared/items.lua',
    'shared/jobs.lua',
    'shared/gangs.lua',
    'shared/vehicles.lua',
    'shared/weapons.lua',
}

server_scripts {
    'server/sync.lua',
    'server/main.lua',
    'server/bridge/inventory/qsinventory.lua',
    'server/exports.lua',
    'server/vehicles.lua',
}

client_scripts {
    'client/functions.lua',
    'client/main.lua',
}

server_exports {
    'GetCoreObject',
    'GetShared',
    'SetMethod',
    'SetField',
    'AddJob',
    'AddJobs',
    'RemoveJob',
    'UpdateJob',
    'AddItem',
    'UpdateItem',
    'AddItems',
    'RemoveItem',
    'AddGang',
    'AddGangs',
    'RemoveGang',
    'UpdateGang',
    'GetCoreVersion',
    'ExploitBan',
    'SpawnVehicle',
}

client_exports {
    'GetCoreObject',
    'GetShared',
}

dependencies {
    'qs-core',
}
