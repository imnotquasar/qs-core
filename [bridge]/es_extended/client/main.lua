-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from ESX Legacy (https://github.com/esx-framework/esx_core)
-- Copyright (C) 2022-2026 ESX Framework
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

local serverCallbacks = {}
local requestId = 0
local inventoryMirror = {}
local useOx = Config.CustomInventory == 'ox'
local useQs = Config.CustomInventory == 'qs'
local useCustomInventory = useOx or useQs

local function esxJob(job)
    job = job or {}
    return {
        id = 1,
        name = job.name or 'unemployed',
        label = job.label or 'Civilian',
        grade = job.grade or 0,
        grade_name = job.gradeName or 'freelancer',
        grade_label = job.gradeLabel or 'Freelancer',
        grade_salary = job.salary or 0,
    }
end

local function buildAccounts(money, metadata)
    money = money or {}
    local extra = (metadata or {}).accounts_extra or {}
    return {
        { name = 'money', money = money.cash or 0, label = 'Cash' },
        { name = 'bank', money = money.bank or 0, label = 'Bank' },
        { name = 'black_money', money = tonumber(extra.black_money) or 0, label = 'Black Money' },
    }
end

local function setAccount(name, amount)
    for _, acc in ipairs(ESX.PlayerData.accounts or {}) do
        if acc.name == name then
            acc.money = amount
            TriggerEvent('esx:setAccountMoney', acc)
            return
        end
    end
end

AddEventHandler('qs:client:onPlayerLoaded', function(d)
    if not d then return end
    local ci = d.charinfo or {}
    ESX.PlayerData = {
        identifier = d.citizenid,
        citizenid = d.citizenid,
        source = GetPlayerServerId(PlayerId()),
        job = esxJob(d.job),
        accounts = buildAccounts(d.money, d.metadata),
        inventory = useCustomInventory and {} or inventoryMirror,
        loadout = {},
        maxWeight = Config.MaxWeight * 1000,
        money = (d.money and d.money.cash) or 0,
        metadata = d.metadata or {},
        firstName = ci.firstname or 'John',
        lastName = ci.lastname or 'Doe',
        dateofbirth = ci.dob or '2000-01-01',
        sex = (ci.sex == 'female' or ci.sex == 'f') and 'f' or 'm',
        height = 180,
    }
    ESX.PlayerLoaded = true
    TriggerEvent('esx:playerLoaded', ESX.PlayerData, d.isNew == true, d.skin)
end)

RegisterNetEvent('qs:client:playerUnloaded', function()
    if not ESX.PlayerLoaded then return end
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
    inventoryMirror = {}
    TriggerEvent('esx:onPlayerLogout')
end)

RegisterNetEvent('qs:job:set', function(job)
    if not ESX.PlayerLoaded then return end
    local last = ESX.PlayerData.job
    ESX.PlayerData.job = esxJob(job)
    if useCustomInventory then
        ESX.SetPlayerData('job', ESX.PlayerData.job)
    end
    TriggerEvent('esx:setJob', ESX.PlayerData.job, last)
end)

RegisterNetEvent('qs:money:add', function(account, amount)
    if not ESX.PlayerLoaded then return end
    local name = account == 'cash' and 'money' or account
    for _, acc in ipairs(ESX.PlayerData.accounts or {}) do
        if acc.name == name then
            setAccount(name, acc.money + (amount or 0))
            if name == 'money' then ESX.PlayerData.money = acc.money end
            return
        end
    end
end)

RegisterNetEvent('qs:money:remove', function(account, amount)
    if not ESX.PlayerLoaded then return end
    local name = account == 'cash' and 'money' or account
    for _, acc in ipairs(ESX.PlayerData.accounts or {}) do
        if acc.name == name then
            setAccount(name, math.max(0, acc.money - (amount or 0)))
            if name == 'money' then ESX.PlayerData.money = acc.money end
            return
        end
    end
end)

RegisterNetEvent('qs:money:set', function(account, amount)
    if not ESX.PlayerLoaded then return end
    local name = account == 'cash' and 'money' or account
    setAccount(name, amount or 0)
    if name == 'money' then ESX.PlayerData.money = amount or 0 end
end)

RegisterNetEvent('qs:metadata:set', function(key, value)
    if not ESX.PlayerLoaded then return end
    ESX.PlayerData.metadata = ESX.PlayerData.metadata or {}
    ESX.PlayerData.metadata[key] = value
    if key == 'accounts_extra' then
        local extra = value or {}
        setAccount('black_money', tonumber(extra.black_money) or 0)
    end
end)

RegisterNetEvent('qs-inv:client:set', function(data)
    if useCustomInventory or not data or not data.items then return end

    local old = {}
    for _, it in ipairs(inventoryMirror) do old[it.name] = it.count end

    local byName, order = {}, {}
    for slot = 1, (data.slots or #data.items) do
        local it = data.items[slot]
        if it and type(it) == 'table' then
            if byName[it.name] then
                byName[it.name].count = byName[it.name].count + it.count
            else
                byName[it.name] = {
                    name = it.name, label = it.label or it.name, count = it.count,
                    weight = it.weight or 0, usable = it.useable or false,
                    rare = false, canRemove = true,
                }
                order[#order + 1] = it.name
            end
        end
    end

    local fresh = {}
    for _, name in ipairs(order) do fresh[#fresh + 1] = byName[name] end
    inventoryMirror = fresh

    if ESX.PlayerLoaded then
        ESX.PlayerData.inventory = inventoryMirror

        for _, it in ipairs(fresh) do
            local prev = old[it.name] or 0
            if it.count > prev then
                TriggerEvent('esx:addInventoryItem', it.name, it.count)
            elseif it.count < prev then
                TriggerEvent('esx:removeInventoryItem', it.name, it.count)
            end
            old[it.name] = nil
        end
        for name in pairs(old) do
            TriggerEvent('esx:removeInventoryItem', name, 0)
        end
    end
end)

function ESX.IsPlayerLoaded()
    return ESX.PlayerLoaded
end

function ESX.GetPlayerData()
    if useQs then
        ESX.PlayerData.inventory = LocalPlayer.state.inventory or {}
    end
    return ESX.PlayerData
end

function ESX.SetPlayerData(key, val)
    ESX.PlayerData[key] = val
    TriggerEvent('esx:setPlayerData', key, val)
end

function ESX.TriggerServerCallback(name, cb, ...)
    requestId = requestId + 1
    serverCallbacks[requestId] = cb
    TriggerServerEvent('esx:triggerServerCallback', name, requestId, GetCurrentResourceName(), ...)
end

RegisterNetEvent('esx:serverCallback', function(reqId, ...)
    if serverCallbacks[reqId] then
        serverCallbacks[reqId](...)
        serverCallbacks[reqId] = nil
    end
end)

local NOTIFY_MAP = { info = 'info', success = 'success', error = 'error' }

function ESX.ShowNotification(message, ntype, length)

    if type(ntype) ~= 'string' then ntype = 'info' end
    exports['qs-core']:Notify(message, NOTIFY_MAP[ntype] or 'info', length or 4000)
end

function ESX.ShowAdvancedNotification(sender, subject, msg, _textureDict, _iconType, _flash, _saveToBrief, _hudColorIndex)
    exports['qs-core']:Notify(msg or subject or sender, 'info', 5000)
end

function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    if thisFrame then
        AddTextEntry('esxBridgeHelp', msg)
        DisplayHelpTextThisFrame('esxBridgeHelp', false)
        return
    end
    CreateThread(function()
        AddTextEntry('esxBridgeHelp', msg)
        BeginTextCommandDisplayHelp('esxBridgeHelp')
        EndTextCommandDisplayHelp(0, false, beep == nil or beep, duration or -1)
    end)
end

function ESX.ShowFloatingHelpNotification(msg, coords)
    AddTextEntry('esxBridgeFloat', msg)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('esxBridgeFloat')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

RegisterNetEvent('esx:showNotification', function(msg, ntype, length)
    ESX.ShowNotification(msg, ntype, length)
end)

RegisterNetEvent('esx:showAdvancedNotification', function(...)
    ESX.ShowAdvancedNotification(...)
end)

RegisterNetEvent('esx:showHelpNotification', function(msg, thisFrame, beep, duration)
    ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
end)

RegisterNetEvent('esx_bridge:addWeapon', function(weaponName, ammo)
    GiveWeaponToPed(PlayerPedId(), joaat(weaponName), ammo or 0, false, true)
end)

RegisterNetEvent('esx_bridge:removeWeapon', function(weaponName)
    RemoveWeaponFromPed(PlayerPedId(), joaat(weaponName))
end)

RegisterNetEvent('esx_bridge:addAmmo', function(weaponName, amount)
    local ped = PlayerPedId()
    local hash = joaat(weaponName)
    local _, current = GetAmmoInClip(ped, hash)
    SetPedAmmo(ped, hash, math.max(0, (GetAmmoInPedWeapon(ped, hash) or current or 0) + (amount or 0)))
end)

function ESX.Progressbar(message, length, options)
    options = options or {}
    CreateThread(function()
        local ok = exports['qs-core']:Progress({
            duration = length or 3000,
            label = message or '',
            canCancel = options.allowCancel,
            disableMovement = options.FreezePlayer,
        })
        if ok then
            if options.onFinish then options.onFinish() end
        else
            if options.onCancel then options.onCancel() end
        end
    end)
end

ESX.UI.Menu = ESX.UI.Menu or {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

function ESX.UI.Menu.RegisterType(menuType, open, close)
    ESX.UI.Menu.RegisteredTypes[menuType] = { open = open, close = close }
end

function ESX.UI.Menu.Open(menuType, namespace, name, data, submit, cancel, change, close)
    local impl = ESX.UI.Menu.RegisteredTypes[menuType]
    if not impl then
        print(('^3[es_extended bridge]^7 no menu resource registered for type "%s" — install esx_menu_%s'):format(menuType, menuType))
        return
    end

    local menu = {}
    menu.type = menuType
    menu.namespace = namespace
    menu.name = name
    menu.data = data
    menu.submit = submit
    menu.cancel = cancel
    menu.change = change

    menu.close = function()
        impl.close(namespace, name)
        for i = 1, #ESX.UI.Menu.Opened do
            if ESX.UI.Menu.Opened[i] == menu then
                table.remove(ESX.UI.Menu.Opened, i)
                break
            end
        end
        if close then close() end
    end

    menu.update = function(query, newData)
        for _, element in ipairs(menu.data.elements or {}) do
            local match = true
            for k, v in pairs(query) do
                if element[k] ~= v then match = false break end
            end
            if match then
                for k, v in pairs(newData) do element[k] = v end
            end
        end
    end

    menu.refresh = function()
        impl.open(namespace, name, menu.data)
    end

    menu.setElement = function(i, key, val)
        if menu.data.elements and menu.data.elements[i] then
            menu.data.elements[i][key] = val
        end
    end

    menu.setElements = function(newElements)
        menu.data.elements = newElements
    end

    menu.setTitle = function(val)
        menu.data.title = val
    end

    menu.removeElement = function(query)
        for i, element in ipairs(menu.data.elements or {}) do
            for k, v in pairs(query) do
                if element[k] == v then
                    table.remove(menu.data.elements, i)
                    return
                end
            end
        end
    end

    ESX.UI.Menu.Opened[#ESX.UI.Menu.Opened + 1] = menu
    impl.open(namespace, name, data)
    return menu
end

function ESX.UI.Menu.Close(menuType, namespace, name)
    for _, menu in ipairs(ESX.UI.Menu.Opened) do
        if menu.type == menuType and menu.namespace == namespace and menu.name == name then
            menu.close()
            return
        end
    end
end

function ESX.UI.Menu.CloseAll()
    for i = #ESX.UI.Menu.Opened, 1, -1 do
        ESX.UI.Menu.Opened[i].close()
    end
end

function ESX.UI.Menu.GetOpened(menuType, namespace, name)
    for _, menu in ipairs(ESX.UI.Menu.Opened) do
        if menu.type == menuType and menu.namespace == namespace and menu.name == name then
            return menu
        end
    end
end

function ESX.UI.Menu.GetOpenedMenus()
    return ESX.UI.Menu.Opened
end

function ESX.UI.Menu.IsOpen(menuType, namespace, name)
    return ESX.UI.Menu.GetOpened(menuType, namespace, name) ~= nil
end

ESX.UI.HUD = {
    SetDisplay = function() end,
    RegisterElement = function() end,
    RemoveElement = function() end,
    Reset = function() end,
    UpdateElement = function() end,
}

AddEventHandler('qs:client:onDeath', function()
    if not ESX.PlayerLoaded then return end
    local ped = PlayerPedId()
    local killer = GetPedSourceOfDeath(ped)
    TriggerEvent('esx:onPlayerDeath', {
        victimCoords = GetEntityCoords(ped),
        killedByPlayer = killer ~= ped and IsPedAPlayer(killer),
        deathCause = GetPedCauseOfDeath(ped),
    })
end)

AddEventHandler('qs:client:onRevive', function()
    if ESX.PlayerLoaded then TriggerEvent('esx:onPlayerSpawn') end
end)
