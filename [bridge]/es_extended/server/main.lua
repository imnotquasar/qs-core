-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from ESX Legacy (https://github.com/esx-framework/esx_core)
-- Copyright (C) 2022-2026 ESX Framework
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

local core = exports['qs-core']
local useOx = Config.CustomInventory == 'ox'
local useQs = Config.CustomInventory == 'qs'
local useCustomInventory = useOx or useQs
local inv = (not useCustomInventory and GetResourceState('qs-core') == 'started') and exports['qs-core'] or nil

local xPlayers = {}
ESX.Players = xPlayers
local lastJobs = {}
local serverCallbacks = {}
local usableItems = {}

local ACCOUNT_LABELS = { money = 'Cash', bank = 'Bank', black_money = 'Black Money' }
local MAX_WEIGHT = Config.MaxWeight * 1000

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
        skin_male = {},
        skin_female = {},
    }
end

local function mapAccount(name)
    name = tostring(name or ''):lower()
    if name == 'money' or name == 'cash' then return 'cash' end
    if name == 'bank' then return 'bank' end
    return nil
end

local function getVirtual(src, account)
    local extra = core:GetMetadata(src, 'accounts_extra') or {}
    return tonumber(extra[account]) or 0
end

local function setVirtual(src, account, amount)
    local extra = core:GetMetadata(src, 'accounts_extra') or {}
    extra[account] = math.max(0, math.floor(tonumber(amount) or 0))
    core:SetMetadata(src, 'accounts_extra', extra)
end

local function buildAccountsArray(src)
    local accounts = {}
    local defs = {
        { name = 'money',       mapped = 'cash',      label = 'Cash' },
        { name = 'bank',        mapped = 'bank',      label = 'Bank' },
        { name = 'black_money', label = 'Black Money' },
    }
    for i, def in ipairs(defs) do
        local amount
        if def.mapped then
            amount = core:GetMoney(src, def.mapped)
        else
            amount = getVirtual(src, def.name)
        end
        accounts[i] = {
            name = def.name,
            money = amount,
            label = def.label,
            round = Config.Accounts[def.name] and Config.Accounts[def.name].round or true,
            index = i,
        }
    end
    return accounts
end

local function esxInventory(src)
    local view = inv:GetSlotView(src) or {}
    local byName, order = {}, {}
    for slot = 1, #view do
        local it = view[slot]
        if it and type(it) == 'table' then
            if byName[it.name] then
                byName[it.name].count = byName[it.name].count + it.count
            else
                byName[it.name] = {
                    name = it.name,
                    label = it.label or it.name,
                    count = it.count,
                    weight = it.weight or 0,
                    usable = it.useable or false,
                    rare = false,
                    canRemove = true,
                }
                order[#order + 1] = it.name
            end
        end
    end
    local out = {}
    for _, name in ipairs(order) do out[#out + 1] = byName[name] end
    return out
end

local function ensureJobRegistered(name)
    if not name then return end
    local jobs = core:GetJobs() or {}
    if jobs[name] then return end
    core:RegisterJob(name, {
        label = name:gsub('^%l', string.upper),
        grades = {
            [0] = { name = 'employee', label = 'Employee', salary = 0 },
            [1] = { name = 'experienced', label = 'Experienced', salary = 0 },
            [2] = { name = 'advanced', label = 'Advanced', salary = 0 },
            [3] = { name = 'boss', label = 'Boss', salary = 0, isBoss = true },
        },
    })
end

local function ensureItemUseable(name)
    local def = core:GetItem(name)
    if def and def.useable then return end
    local merged = def and {
        label = def.label,
        weight = def.weight,
        description = def.description,
        unique = def.unique,
        image = def.image,
        weapon = def.weapon,
        ammo = def.ammo,
        stack = def.stack,
    } or { label = name, weight = 100 }
    merged.useable = true
    core:RegisterItem(name, merged)
end

local function CreateExtendedPlayer(src)
    local snap = core:GetPlayer(src)
    if not snap or not snap.PlayerData then return nil end
    local pd = snap.PlayerData
    local ci = pd.charinfo or {}

    local self = {}
    self.source = src
    self.playerId = src
    self.identifier = pd.citizenid
    self.citizenid = pd.citizenid
    self.license = pd.license
    self.name = ('%s %s'):format(ci.firstname or 'John', ci.lastname or 'Doe')
    self.job = esxJob(pd.job)
    self.group = 'user'
    self.variables = pd.metadata and pd.metadata.esx_vars or {}
    self.coords = pd.position or { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 }
    self.maxWeight = MAX_WEIGHT
    self.metadata = pd.metadata or {}
    self.inventory = pd.inventory or {}
    self.weight = 0
    self.accounts = buildAccountsArray(src)
    self.spawned = true
    self.sex = (ci.sex == 'female' or ci.sex == 'f') and 'f' or 'm'
    self.dateofbirth = ci.dob or '2000-01-01'

    local function refreshJob()
        local s = core:GetPlayer(src)
        if s and s.PlayerData then self.job = esxJob(s.PlayerData.job) end
    end

    function self.triggerEvent(eventName, ...)
        TriggerClientEvent(eventName, src, ...)
    end

    function self.kick(reason)
        DropPlayer(src, reason or 'Kicked')
    end

    function self.getName()
        return self.name
    end

    function self.setName(_newName) end

    function self.getIdentifier()
        return self.identifier
    end

    function self.getGroup()
        if IsPlayerAceAllowed(src, 'group.admin') or IsPlayerAceAllowed(src, 'command') then return 'admin' end
        if IsPlayerAceAllowed(src, 'group.mod') then return 'mod' end
        return 'user'
    end

    function self.setGroup(group)
        local lic = GetPlayerIdentifierByType(src, 'license')
        if lic then ExecuteCommand(('add_principal identifier.%s group.%s'):format(lic, group)) end
    end

    function self.getCoords(vector)
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        if vector then return coords end
        return { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) }
    end

    function self.setCoords(coords)
        local ped = GetPlayerPed(src)
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        if coords.heading then SetEntityHeading(ped, coords.heading) end
    end

    function self.getPed()
        return GetPlayerPed(src)
    end

    function self.set(k, v)
        self.variables[k] = v
        local vars = core:GetMetadata(src, 'esx_vars') or {}
        vars[k] = v
        core:SetMetadata(src, 'esx_vars', vars)
    end

    function self.get(k)
        if self.variables[k] ~= nil then return self.variables[k] end
        local vars = core:GetMetadata(src, 'esx_vars') or {}
        return vars[k]
    end

    function self.getMeta(key)
        if key then return core:GetMetadata(src, key) end
        return core:GetMetadata(src)
    end

    function self.setMeta(key, value)
        core:SetMetadata(src, key, value)
    end

    function self.clearMeta(key)
        core:SetMetadata(src, key, nil)
    end

    function self.getMoney()
        return core:GetMoney(src, 'cash')
    end

    function self.addMoney(amount, reason)
        return core:AddMoney(src, 'cash', math.floor(tonumber(amount) or 0), reason)
    end

    function self.removeMoney(amount, reason)
        return core:RemoveMoney(src, 'cash', math.floor(tonumber(amount) or 0), reason)
    end

    function self.setMoney(amount)
        return core:SetMoney(src, 'cash', math.floor(tonumber(amount) or 0))
    end

    function self.getAccount(account)
        if not useCustomInventory then self.accounts = buildAccountsArray(src) end
        account = string.lower(account)
        for i = 1, #self.accounts do
            if string.lower(self.accounts[i].name) == account then
                return self.accounts[i]
            end
        end
        return nil
    end

    function self.getAccounts(minimal)
        if not useCustomInventory then self.accounts = buildAccountsArray(src) end
        if minimal then
            local minimalAccounts = {}
            for i = 1, #self.accounts do
                minimalAccounts[self.accounts[i].name] = self.accounts[i].money
            end
            return minimalAccounts
        end
        return self.accounts
    end

    if not useCustomInventory then
        function self.addAccountMoney(account, amount, reason)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then return end
            local mapped = mapAccount(account)
            if mapped then
                core:AddMoney(src, mapped, amount, reason)
            else
                setVirtual(src, account, getVirtual(src, account) + amount)
            end
        end

        function self.removeAccountMoney(account, amount, reason)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then return end
            local mapped = mapAccount(account)
            if mapped then
                core:RemoveMoney(src, mapped, amount, reason)
            else
                setVirtual(src, account, getVirtual(src, account) - amount)
            end
        end

        function self.setAccountMoney(account, amount, reason)
            amount = math.floor(tonumber(amount) or 0)
            if amount < 0 then return end
            local mapped = mapAccount(account)
            if mapped then
                core:SetMoney(src, mapped, amount)
            else
                setVirtual(src, account, amount)
            end
            local _ = reason
        end

        function self.getInventory(_minimal)
            return esxInventory(src)
        end

        function self.getInventoryItem(name)
            local def = core:GetItem(name)
            if not def then return nil end
            return {
                name = name,
                label = def.label or name,
                count = inv:GetItemCount(src, name),
                weight = def.weight or 0,
                usable = def.useable or false,
                rare = false,
                canRemove = true,
            }
        end

        function self.addInventoryItem(name, count)
            count = math.floor(tonumber(count) or 1)
            local ok = inv:AddItem(src, name, count)
            if ok then
                TriggerClientEvent('esx:addInventoryItem', src, name, inv:GetItemCount(src, name))
            end
            return ok
        end

        function self.removeInventoryItem(name, count)
            count = math.floor(tonumber(count) or 1)
            local ok = inv:RemoveItem(src, name, count)
            if ok then
                TriggerClientEvent('esx:removeInventoryItem', src, name, inv:GetItemCount(src, name))
            end
            return ok
        end

        function self.setInventoryItem(name, count)
            count = math.floor(tonumber(count) or 0)
            local current = inv:GetItemCount(src, name)
            if count > current then
                return self.addInventoryItem(name, count - current)
            elseif count < current then
                return self.removeInventoryItem(name, current - count)
            end
            return true
        end

        function self.canCarryItem(name, count)
            return inv:CanCarryItem(src, name, count or 1)
        end

        function self.canSwapItem(firstItem, firstCount, testItem, testCount)
            local _ = firstItem
            local _ = firstCount
            return inv:CanCarryItem(src, testItem, testCount or 1)
        end

        function self.hasItem(name, count)
            return inv:HasItem(src, name, count or 1)
        end

        function self.getWeight()
            local total = 0
            local view = inv:GetSlotView(src) or {}
            for i = 1, #view do
                local it = view[i]
                if it and type(it) == 'table' then
                    total = total + (it.weight or 0) * (it.count or 0)
                end
            end
            return total
        end

        function self.getMaxWeight()
            return self.maxWeight
        end

        function self.setMaxWeight(w)
            self.maxWeight = w
        end
    else
        function self.getWeight()
            return self.weight or 0
        end

        function self.getMaxWeight()
            return self.maxWeight
        end
    end

    function self.getJob()
        refreshJob()
        return self.job
    end

    function self.setJob(jobName, grade)
        grade = tonumber(grade) or 0
        ensureJobRegistered(jobName)
        local ok = core:SetJob(src, jobName, grade)
        if ok then refreshJob() end
        return ok
    end

    function self.getLoadout(_minimal)
        return {}
    end

    function self.addWeapon(weaponName, ammo)
        TriggerClientEvent('esx_bridge:addWeapon', src, weaponName, ammo or 0)
    end

    function self.removeWeapon(weaponName)
        TriggerClientEvent('esx_bridge:removeWeapon', src, weaponName)
    end

    function self.addWeaponAmmo(weaponName, ammoCount)
        TriggerClientEvent('esx_bridge:addAmmo', src, weaponName, ammoCount)
    end

    function self.removeWeaponAmmo(weaponName, ammoCount)
        TriggerClientEvent('esx_bridge:addAmmo', src, weaponName, -(ammoCount or 0))
    end

    function self.hasWeapon(_weaponName)
        return false
    end

    function self.getWeapon(_weaponName)
        return nil
    end

    function self.addWeaponComponent(_w, _c) end

    function self.removeWeaponComponent(_w, _c) end

    function self.showNotification(msg, ntype, length)
        TriggerClientEvent('esx:showNotification', src, msg, ntype, length)
    end

    function self.showAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
        TriggerClientEvent('esx:showAdvancedNotification', src, sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    end

    function self.showHelpNotification(msg, thisFrame, beep, duration)
        TriggerClientEvent('esx:showHelpNotification', src, msg, thisFrame, beep, duration)
    end

    if useCustomInventory then
        for _, funcs in pairs(Core.PlayerFunctionOverrides) do
            for fnName, fn in pairs(funcs) do
                self[fnName] = fn(self)
            end
        end

        local function syncCoreAccount(accountName)
            local mapped = mapAccount(accountName)
            local acc = self.getAccount(accountName)
            if not acc then return end
            if mapped then
                core:SetMoney(src, mapped, acc.money)
            elseif accountName == 'black_money' then
                setVirtual(src, 'black_money', acc.money)
            end
        end

        if useOx then
            local baseSync = self.syncInventory
            function self.syncInventory(weight, maxWeight, items, money)
                baseSync(weight, maxWeight, items, money)
                core:SetInventory(src, self.getInventory(true))
                if money then
                    for accountName, amount in pairs(money) do
                        local mapped = mapAccount(accountName)
                        if mapped then
                            core:SetMoney(src, mapped, amount)
                        elseif accountName == 'black_money' then
                            setVirtual(src, 'black_money', amount)
                        end
                    end
                end
            end
        end

        for _, method in ipairs({ 'setAccountMoney', 'addAccountMoney', 'removeAccountMoney' }) do
            local original = self[method]
            self[method] = function(account, amount, reason)
                original(account, amount, reason)
                syncCoreAccount(account)
            end
        end
    end

    return self
end

function ESX.GetPlayerFromId(source)
    local src = tonumber(source)
    if not src then return nil end
    local p = xPlayers[src]
    if p then return p end
    p = CreateExtendedPlayer(src)
    if p then xPlayers[src] = p end
    return p
end

function ESX.GetPlayerFromIdentifier(identifier)
    local snap = core:GetPlayerByCitizenId(identifier)
    if snap and snap.source then return ESX.GetPlayerFromId(snap.source) end

    for _, sid in ipairs(GetPlayers()) do
        local src = tonumber(sid)
        local s = core:GetPlayer(src)
        if s and s.PlayerData and s.PlayerData.license == identifier then
            return ESX.GetPlayerFromId(src)
        end
    end
    return nil
end

function ESX.GetPlayers()
    local out = {}
    for _, sid in ipairs(GetPlayers()) do
        out[#out + 1] = tonumber(sid)
    end
    return out
end

function ESX.GetExtendedPlayers(key, value)
    local out = {}
    for _, sid in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(tonumber(sid))
        if xPlayer then
            if not key then
                out[#out + 1] = xPlayer
            elseif key == 'job' and xPlayer.getJob().name == value then
                out[#out + 1] = xPlayer
            elseif xPlayer[key] == value then
                out[#out + 1] = xPlayer
            end
        end
    end
    return out
end

function ESX.GetNumPlayers()
    return #GetPlayers()
end

function ESX.RegisterServerCallback(name, cb)
    serverCallbacks[name] = cb
end

RegisterNetEvent('esx:triggerServerCallback', function(name, requestId, _invoker, ...)
    local src = source
    local cb = serverCallbacks[name]
    if not cb then
        print(('^3[es_extended bridge]^7 unknown server callback: %s'):format(name))
        return
    end
    cb(src, function(...)
        TriggerClientEvent('esx:serverCallback', src, requestId, ...)
    end, ...)
end)

function ESX.RegisterUsableItem(item, cb)
    if useQs then return end
    usableItems[item] = cb
    Core.UsableItemsCallbacks[item] = cb
    if not useOx then
        ensureItemUseable(item)
    end
end

function ESX.UseItem(source, item, ...)
    if useQs then return end
    local cb = usableItems[item]
    if cb then cb(source, item, ...) end
end

AddEventHandler('qs:server:usedItem', function(src, name)
    if useCustomInventory then return end
    local cb = usableItems[name]
    if cb then cb(src, name) end
end)

function ESX.GetItems()
    if useCustomInventory then
        return ESX.Items or {}
    end
    return core:GetItems() or {}
end

function ESX.GetItemLabel(item)
    if useCustomInventory then return item end
    local def = core:GetItem(item)
    return def and def.label or item
end

function ESX.GetJobs()
    local out = {}
    for name, j in pairs(core:GetJobs() or {}) do
        local grades = {}
        for lvl, g in pairs(j.grades or {}) do
            grades[tostring(lvl)] = {
                job_name = name,
                grade = lvl,
                name = g.name,
                label = g.label,
                salary = g.salary or 0,
                skin_male = '{}',
                skin_female = '{}',
            }
        end
        out[name] = { label = j.label or name, grades = grades }
    end
    return out
end

function ESX.DoesJobExist(job, grade)
    local jobs = core:GetJobs() or {}
    local j = jobs[job]
    if not j then return false end
    if grade ~= nil then return j.grades[tonumber(grade) or -1] ~= nil end
    return true
end

ESX.Jobs = ESX.GetJobs()
ESX.Items = ESX.Items or {}
if not useCustomInventory then
    for name, def in pairs(core:GetItems() or {}) do
        ESX.Items[name] = { label = def.label or name, weight = def.weight or 0, rare = false, canRemove = true }
    end
end

function ESX.SavePlayer(xPlayer, cb)
    if xPlayer and useOx then
        local snap = core:GetPlayer(xPlayer.source)
        if snap then
            snap.PlayerData.inventory = xPlayer.getInventory(true)
            snap:save()
        end
    end
    if cb then cb() end
end

function ESX.SavePlayers(cb)
    if cb then cb() end
end

function ESX.CreatePickup(_type, name, count, _label, _playerId)
    print(('^3[es_extended bridge]^7 CreatePickup ignored (%sx %s) — world pickups are not emulated'):format(count, name))
end

function ESX.RegisterCommand(name, group, cb, allowConsole, suggestion)
    if type(name) == 'table' then
        for _, n in ipairs(name) do
            ESX.RegisterCommand(n, group, cb, allowConsole, suggestion)
        end
        return
    end

    group = group or 'user'

    RegisterCommand(name, function(source, rawArgs, _raw)
        if source == 0 and not allowConsole then
            print(('^1[es_extended bridge]^7 /%s cannot be run from console'):format(name))
            return
        end

        if source > 0 and group ~= 'user' then
            local allowed = IsPlayerAceAllowed(source, 'group.' .. group)
                or IsPlayerAceAllowed(source, 'group.admin')
                or IsPlayerAceAllowed(source, 'command')
            if not allowed then
                TriggerClientEvent('esx:showNotification', source, 'You do not have permission', 'error')
                return
            end
        end

        local xPlayer = source > 0 and ESX.GetPlayerFromId(source) or nil
        local showError = function(msg)
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('esx:showNotification', source, msg, 'error')
            end
        end

        local args = {}
        if suggestion and suggestion.arguments then
            for i, argDef in ipairs(suggestion.arguments) do
                local raw = rawArgs[i]
                local val = raw
                if argDef.type == 'number' then
                    val = tonumber(raw)
                    if suggestion.validate and val == nil then
                        return showError(('Invalid argument #%d (number expected)'):format(i))
                    end
                elseif argDef.type == 'player' or argDef.type == 'playerId' then
                    local id = tonumber(raw)
                    if raw == 'me' then id = source end
                    val = id and ESX.GetPlayerFromId(id) or nil
                    if suggestion.validate and val == nil then
                        return showError(('Invalid argument #%d (player expected)'):format(i))
                    end
                elseif argDef.type == 'string' or argDef.type == 'any' then
                    val = raw
                elseif argDef.type == 'weapon' then
                    val = raw and raw:upper() or nil
                end
                args[argDef.name] = val
            end
        else
            args = rawArgs
        end

        cb(xPlayer, args, showError)
    end, false)

    if suggestion then
        TriggerClientEvent('chat:addSuggestion', -1, '/' .. name, suggestion.help or '', suggestion.arguments or {})
    end
end

do
    local reg = {}
    for name, it in pairs(BridgeItems or {}) do
        if not core:GetItem(name) then
            reg[name] = {
                label = it.label or name,
                weight = tonumber(it.weight) or 0,
                useable = it.useable or false,
                description = it.description,
                unique = it.unique,
                image = it.image,
            }
        end
    end
    if next(reg) then core:RegisterItems(reg) end
end

AddEventHandler('qs:server:characterLoaded', function(src, data)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    lastJobs[src] = xPlayer.getJob()
    TriggerEvent('esx:playerLoaded', src, xPlayer, data and data.isNew)
    if useOx and setPlayerInventory then
        local snap = core:GetPlayer(src)
        local inventory = snap and snap.PlayerData and snap.PlayerData.inventory or xPlayer.inventory
        setPlayerInventory(src, xPlayer, inventory, data and data.isNew)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if xPlayers[src] then
        if useOx then
            ESX.SavePlayer(xPlayers[src])
        end
        TriggerEvent('esx:playerDropped', src, reason)
        xPlayers[src] = nil
        lastJobs[src] = nil
    end
end)

AddEventHandler('qs:server:playerUnloaded', function(src)
    if xPlayers[src] then
        TriggerEvent('esx:playerLogout', src)
        xPlayers[src] = nil
        lastJobs[src] = nil
    end
end)

AddEventHandler('qs:server:jobChange', function(src, job)
    local newJob = esxJob(job)
    local lastJob = lastJobs[src] or newJob
    lastJobs[src] = newJob
    if xPlayers[src] then xPlayers[src].job = newJob end
    TriggerEvent('esx:setJob', src, newJob, lastJob)
end)
