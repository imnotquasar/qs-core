-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from ESX Legacy (https://github.com/esx-framework/esx_core)
-- Copyright (C) 2022-2026 ESX Framework
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

ESX = exports['es_extended']:getSharedObject()

if not IsDuplicityVersion() then

    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        ESX.PlayerData = xPlayer
        ESX.PlayerLoaded = true
    end)

    RegisterNetEvent('esx:setJob', function(job)
        if ESX.PlayerData then ESX.PlayerData.job = job end
    end)

    RegisterNetEvent('esx:setAccountMoney', function(account)
        if not (ESX.PlayerData and ESX.PlayerData.accounts and account) then return end
        for i, acc in ipairs(ESX.PlayerData.accounts) do
            if acc.name == account.name then
                ESX.PlayerData.accounts[i] = account
                return
            end
        end
        ESX.PlayerData.accounts[#ESX.PlayerData.accounts + 1] = account
    end)
end
