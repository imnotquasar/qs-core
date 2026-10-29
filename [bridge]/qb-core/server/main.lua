-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from QBCore (https://github.com/qbcore-framework/qb-core)
-- Copyright (C) QBCore Framework and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

local core = exports['qs-core']
local inv = exports['qs-core']

local JOB_TYPES = { police = 'leo', ambulance = 'ems', mechanic = 'mechanic' }

local function qbJob(job, meta)
    job = job or {}
    local onduty = true
    if meta and meta.onduty ~= nil then onduty = meta.onduty and true or false end
    return {
        name = job.name or 'unemployed',
        label = job.label or 'Civilian',
        payment = job.salary or 0,
        type = JOB_TYPES[job.name],
        onduty = onduty,
        isboss = job.isBoss or false,
        grade = {
            name = job.gradeLabel or job.gradeName or 'Freelancer',
            level = job.grade or 0,
        },
    }
end

local DEFAULT_GANG = { name = 'none', label = 'No Gang', isboss = false, grade = { name = 'Unaffiliated', level = 0 } }

local function ensureJobRegistered(name)
    if not name then return end
    local jobs = core:GetJobs() or {}
    if jobs[name] then return end
    local def
    if QBCore.Shared.Jobs[name] then
        def = BridgeQsJobFromQB(name, QBCore.Shared.Jobs[name])
    else
        def = {
            label = QBCore.Shared.FirstToUpper(name) or name,
            grades = {
                [0] = { name = 'employee', label = 'Employee', salary = 0 },
                [1] = { name = 'experienced', label = 'Experienced', salary = 0 },
                [2] = { name = 'advanced', label = 'Advanced', salary = 0 },
                [3] = { name = 'manager', label = 'Manager', salary = 0 },
                [4] = { name = 'boss', label = 'Boss', salary = 0, isBoss = true },
            },
        }
    end
    core:RegisterJob(name, def)
end

local function ensureItemUseable(name)
    local def = core:GetItem(name)
    if def and def.useable then return end
    local qb = QBCore.Shared.Items[name]
    local merged = def and {
        label = def.label, weight = def.weight, useable = true, description = def.description,
        unique = def.unique, image = def.image, weapon = def.weapon, ammo = def.ammo, stack = def.stack,
    } or (qb and BridgeQsItemFromQB(name, qb)) or { label = name, weight = 100 }
    merged.useable = true
    core:RegisterItem(name, merged)
    if not QBCore.Shared.Items[name] then QBCore.Shared.Items[name] = BridgeQbItemFromDef(name, merged) end
end

local DEFAULT_METADATA = {
    hunger = 100, thirst = 100, stress = 0, isdead = false, inlaststand = false,
    armor = 0, ishandcuffed = false, tracker = false, injail = 0, jailitems = {},
    status = {}, phone = {}, fitbit = {}, commandbinds = {}, bloodtype = 'A+',
    dealerrep = 0, craftingrep = 0, attachmentcraftingrep = 0, currentapartment = nil,
    jobrep = { tow = 0, trucker = 0, taxi = 0, hotdog = 0 }, callsign = 'NO CALLSIGN',
    fingerprint = 'QS-00000000', walletid = 'QS-00000000',
    criminalrecord = { hasRecord = false },
    licences = { driver = true, business = false, weapon = false },
    inside = { house = nil, apartment = {} },
    phonedata = { SerialNumber = '', InstalledApps = {} },
}

local function mergedMetadata(meta)
    local out = {}
    for k, v in pairs(DEFAULT_METADATA) do out[k] = v end
    for k, v in pairs(meta or {}) do out[k] = v end
    return out
end

local function qbItems(src)
    local view = inv:GetSlotView(src) or {}
    local items = {}
    for slot = 1, #view do
        local it = view[slot]
        if it and type(it) == 'table' then
            items[slot] = {
                name = it.name,
                label = it.label or it.name,
                amount = it.count,
                count = it.count,
                weight = it.weight or 0,
                slot = slot,
                info = it.info or {},
                type = 'item',
                useable = it.useable or false,
                unique = (it.max or 64) <= 1,
                image = it.image or (it.name .. '.png'),
                shouldClose = true,
                description = it.description or '',
            }
        end
    end
    return items
end

local function buildPlayerData(src)
    local snap = core:GetPlayer(src)
    if not snap or not snap.PlayerData then return nil end
    local pd = snap.PlayerData
    local ci = pd.charinfo or {}
    local meta = pd.metadata or {}
    local extra = meta.accounts_extra or {}
    local sex = ci.sex or 'male'
    local pos = pd.position or {}

    return {
        source = src,
        citizenid = pd.citizenid,
        cid = 1,
        license = pd.license,
        name = pd.name,
        money = {
            cash = (pd.money and pd.money.cash) or 0,
            bank = (pd.money and pd.money.bank) or 0,
            crypto = tonumber(extra.crypto) or 0,
        },
        charinfo = {
            firstname = ci.firstname or 'John',
            lastname = ci.lastname or 'Doe',
            birthdate = ci.dob or '2000-01-01',
            gender = (sex == 'female' or sex == 'f' or sex == 1) and 1 or 0,
            nationality = ci.nationality or 'USA',
            phone = ci.phone or '0000000000',
            account = 'US0' .. (pd.citizenid or '00000000'),
        },
        job = qbJob(pd.job, meta),
        gang = core:GetGangForPlayer(src) or meta.gang or DEFAULT_GANG,
        metadata = mergedMetadata(meta),
        position = vector4(pos.x or 0.0, pos.y or 0.0, pos.z or 0.0, pos.w or 0.0),
        items = qbItems(src),
        optin = true,
        LoggedIn = true,
    }
end

local function CreatePlayer(src)
    local self = {}
    self.PlayerData = buildPlayerData(src)
    if not self.PlayerData then return nil end
    self.Offline = false
    self.Functions = {}

    local function refresh()
        self.PlayerData = buildPlayerData(src) or self.PlayerData
    end

    function self.Functions.UpdatePlayerData()
        refresh()
        TriggerClientEvent('QBCore:Player:SetPlayerData', src, self.PlayerData)
    end

    function self.Functions.SetPlayerData(key, val)
        if key == 'job' and type(val) == 'table' then
            self.Functions.SetJob(val.name, val.grade and val.grade.level or 0)
            return
        end
        if key == 'gang' and type(val) == 'table' then
            core:SetMetadata(src, 'gang', val)
        elseif key == 'metadata' and type(val) == 'table' then
            for k, v in pairs(val) do core:SetMetadata(src, k, v) end
        end
        self.PlayerData[key] = val
        TriggerClientEvent('QBCore:Player:SetPlayerData', src, self.PlayerData)
    end

    function self.Functions.AddMoney(moneytype, amount, reason)
        local ok = core:AddAccountMoney(src, moneytype, amount, reason)
        if ok then refresh() end
        return ok
    end

    function self.Functions.RemoveMoney(moneytype, amount, reason)
        local ok = core:RemoveAccountMoney(src, moneytype, amount, reason)
        if ok then refresh() end
        return ok
    end

    function self.Functions.SetMoney(moneytype, amount, reason)
        local ok = core:SetAccountMoney(src, moneytype, amount)
        if ok then refresh() end
        return ok
    end

    function self.Functions.GetMoney(moneytype)
        return core:GetAccountMoney(src, moneytype)
    end

    function self.Functions.AddItem(item, amount, slot, info)
        local ok = inv:AddItem(src, item, amount or 1, slot, info)
        if ok then self.PlayerData.items = qbItems(src) end
        return ok
    end

    function self.Functions.RemoveItem(item, amount, slot)
        local ok = inv:RemoveItem(src, item, amount or 1, slot)
        if ok then self.PlayerData.items = qbItems(src) end
        return ok
    end

    function self.Functions.SetItemData(slot, key, val)
        local it = inv:GetItemBySlot(src, slot)
        if not it then return false end
        local info = it.info or {}
        info[key] = val
        return inv:SetItemInfo(src, slot, info)
    end

    function self.Functions.GetItemByName(item)
        self.PlayerData.items = qbItems(src)
        for _, it in pairs(self.PlayerData.items) do
            if it.name == item then return it end
        end
        return nil
    end

    function self.Functions.GetItemsByName(item)
        self.PlayerData.items = qbItems(src)
        local out = {}
        for _, it in pairs(self.PlayerData.items) do
            if it.name == item then out[#out + 1] = it end
        end
        return out
    end

    function self.Functions.GetItemBySlot(slot)
        self.PlayerData.items = qbItems(src)
        return self.PlayerData.items[tonumber(slot) or 0]
    end

    function self.Functions.ClearInventory()
        core:SetInventory(src, {})
        self.PlayerData.items = {}
    end

    function self.Functions.SetMetaData(key, val)
        core:SetMetadata(src, key, val)
        self.PlayerData.metadata[key] = val
        TriggerClientEvent('QBCore:Player:SetPlayerData', src, self.PlayerData)
    end

    function self.Functions.GetMetaData(key)
        if key then return core:GetMetadata(src, key) end
        return core:GetMetadata(src)
    end

    function self.Functions.SetJob(jobName, grade)
        if type(grade) == 'table' then grade = grade.level end
        grade = tonumber(grade) or 0
        ensureJobRegistered(jobName)
        local ok = core:SetJob(src, jobName, grade)
        if ok then refresh() end
        return ok
    end

    function self.Functions.SetGang(gangName, grade)
        grade = tonumber(grade) or 0
        local ok = core:SetGang(src, gangName, grade)
        if ok then
            refresh()
            local gang = self.PlayerData.gang
            TriggerEvent('QBCore:Server:OnGangUpdate', src, gang)
            TriggerClientEvent('QBCore:Client:OnGangUpdate', src, gang)
        end
        return ok
    end

    function self.Functions.SetJobDuty(onDuty)
        local ok = core:SetJobDuty(src, onDuty)
        if ok then refresh() end
        TriggerClientEvent('QBCore:Client:SetDuty', src, onDuty and true or false)
        return ok
    end

    function self.Functions.Save()
        local snap = core:GetPlayer(src)
        if snap and snap.save then snap:save() end
        return true
    end

    function self.Functions.Notify(text, ntype, length)
        TriggerClientEvent('QBCore:Notify', src, text, ntype, length)
    end

    function self.Functions.AddJobReputation(amount)
        local rep = core:GetMetadata(src, 'jobrep') or {}
        local job = self.PlayerData.job.name
        rep[job] = (tonumber(rep[job]) or 0) + (tonumber(amount) or 0)
        core:SetMetadata(src, 'jobrep', rep)
    end

    function self.Functions.AddMethod(methodName, handler)
        if type(methodName) ~= 'string' or type(handler) ~= 'function' then return false end
        self.Functions[methodName] = handler
        return true
    end

    function self.Functions.AddField(fieldName, data)
        if type(fieldName) ~= 'string' then return false end
        self[fieldName] = data
        return true
    end

    return self
end

function QBCore.Functions.AddPlayerMethod(ids, methodName, handler)
    if type(methodName) ~= 'string' or type(handler) ~= 'function' then return end

    local idType = type(ids)
    if idType == 'number' then
        if ids == -1 then
            for _, player in pairs(QBCore.Players) do
                player.Functions.AddMethod(methodName, handler)
            end
            return
        end
        local player = QBCore.Players[ids]
        if not player then return end
        player.Functions.AddMethod(methodName, handler)
    elseif idType == 'table' then
        for i = 1, #ids do
            QBCore.Functions.AddPlayerMethod(ids[i], methodName, handler)
        end
    end
end

function QBCore.Functions.AddPlayerField(ids, fieldName, data)
    if type(fieldName) ~= 'string' then return end

    local idType = type(ids)
    if idType == 'number' then
        if ids == -1 then
            for _, player in pairs(QBCore.Players) do
                player.Functions.AddField(fieldName, data)
            end
            return
        end
        local player = QBCore.Players[ids]
        if not player then return end
        player.Functions.AddField(fieldName, data)
    elseif idType == 'table' then
        for i = 1, #ids do
            QBCore.Functions.AddPlayerField(ids[i], fieldName, data)
        end
    end
end

function QBCore.Functions.GetPlayer(source)
    local src = tonumber(source)
    if not src then return nil end
    local p = QBCore.Players[src]
    if p then
        p.PlayerData = buildPlayerData(src) or p.PlayerData
        return p
    end
    p = CreatePlayer(src)
    if p then
        QBCore.Players[src] = p
        if p.PlayerData.citizenid then
            QBCore.PlayersByCitizenId[p.PlayerData.citizenid] = p
        end
    end
    return p
end

function QBCore.Functions.GetPlayerByCitizenId(citizenid)
    local cached = QBCore.PlayersByCitizenId[citizenid]
    if cached then
        cached.PlayerData = buildPlayerData(cached.PlayerData.source) or cached.PlayerData
        return cached
    end
    local snap = core:GetPlayerByCitizenId(citizenid)
    if not snap or not snap.source then return nil end
    return QBCore.Functions.GetPlayer(snap.source)
end

function QBCore.Functions.GetPlayerByPhone(number)
    for _, sid in ipairs(GetPlayers()) do
        local src = tonumber(sid)
        local snap = core:GetPlayer(src)
        local phone = snap and snap.PlayerData and snap.PlayerData.charinfo and snap.PlayerData.charinfo.phone
        if phone == number then return QBCore.Functions.GetPlayer(src) end
    end
    return nil
end

function QBCore.Functions.GetPlayers()
    local out = {}
    for _, sid in ipairs(GetPlayers()) do
        out[#out + 1] = tonumber(sid)
    end
    return out
end

function QBCore.Functions.GetQBPlayers()
    local out = {}
    for _, sid in ipairs(GetPlayers()) do
        local src = tonumber(sid)
        local p = QBCore.Functions.GetPlayer(src)
        if p then out[src] = p end
    end
    return out
end

function QBCore.Functions.GetPlayersOnDuty(job)
    return core:GetPlayersOnDuty(job)
end

function QBCore.Functions.GetDutyCount(job)
    local _, count = QBCore.Functions.GetPlayersOnDuty(job)
    return count
end

function QBCore.Functions.GetOfflinePlayerByCitizenId(citizenid)
    local row = core:GetOfflinePlayerByCitizenId(citizenid)
    if not row then return nil end
    local money = row.money or {}
    local meta = row.metadata or {}
    local ci = row.charinfo or {}
    local extra = meta.accounts_extra or {}
    return {
        Offline = true,
        Functions = {
            Save = function()
                return core:SaveOfflinePlayer(citizenid, {
                    money = money,
                    job = row.job,
                    metadata = meta,
                    charinfo = ci,
                    inventory = row.inventory,
                })
            end,
        },
        PlayerData = {
            citizenid = row.citizenid,
            license = row.license,
            name = row.name,
            money = { cash = money.cash or 0, bank = money.bank or 0, crypto = tonumber(extra.crypto) or 0 },
            charinfo = {
                firstname = ci.firstname or 'John', lastname = ci.lastname or 'Doe',
                birthdate = ci.dob or '2000-01-01',
                gender = (ci.sex == 'female' or ci.sex == 'f') and 1 or 0,
                nationality = ci.nationality or 'USA', phone = ci.phone or '0000000000',
            },
            job = qbJob(row.job, meta),
            gang = meta.gang or DEFAULT_GANG,
            metadata = mergedMetadata(meta),
            items = {},
        },
    }
end

QBCore.Player = QBCore.Player or {}
function QBCore.Player.GetOfflinePlayer(citizenid)
    return QBCore.Functions.GetOfflinePlayerByCitizenId(citizenid)
end
function QBCore.Player.SaveOffline()
    return true
end

function QBCore.Functions.CreateCallback(name, cb)
    core:RegisterQBCallback(name, cb)
end

function QBCore.Functions.TriggerClientCallback(name, source, cb, ...)
    QBCore.ClientCallbacks[name] = cb
    TriggerClientEvent('QBCore:Client:TriggerClientCallback', source, name, ...)
end

RegisterNetEvent('QBCore:Server:TriggerClientCallback', function(name, ...)
    if QBCore.ClientCallbacks[name] then
        QBCore.ClientCallbacks[name](...)
        QBCore.ClientCallbacks[name] = nil
    end
end)

local function qbUsableItemData(src, name, slot, info)
    local itemData
    if slot then
        itemData = inv:GetItemBySlot(src, slot)
        if itemData then
            itemData.amount = itemData.count
            itemData.info = itemData.info or info or {}
        end
    end
    if not itemData then
        local p = QBCore.Functions.GetPlayer(src)
        itemData = (p and p.Functions.GetItemByName(name))
            or { name = name, label = name, amount = 1, info = info or {}, slot = slot or 1 }
    end
    return itemData
end

local registeringUsable = {}

local function usesAdvancedInventory()
    return GetResourceState('qs-inventory'):find('start') ~= nil
end

function QBCore.Functions.CreateUseableItem(item, cb)
    if registeringUsable[item] then
        QBCore.UsableItems[item] = cb
        return
    end

    registeringUsable[item] = true
    QBCore.UsableItems[item] = cb
    ensureItemUseable(item)

    if not usesAdvancedInventory() then
        core:RegisterUsableItem(item, function(src)
            cb(src, qbUsableItemData(src, item))
        end)
    end

    registeringUsable[item] = nil
end

function QBCore.Functions.CanUseItem(item)
    return QBCore.UsableItems[item]
end

function QBCore.Functions.UseItem(source, item)
    local name = type(item) == 'table' and item.name or item
    local cb = QBCore.UsableItems[name]
    if not cb then return end
    if type(item) == 'table' then
        cb(source, item)
    else
        cb(source, qbUsableItemData(source, name))
    end
end

function QBCore.Functions.HasItem(source, items, amount)
    amount = amount or 1
    if type(items) == 'table' then
        if items[1] ~= nil then
            for _, name in ipairs(items) do
                if not inv:HasItem(source, name, amount) then return false end
            end
        else
            for name, amt in pairs(items) do
                if not inv:HasItem(source, name, amt) then return false end
            end
        end
        return true
    end
    return inv:HasItem(source, items, amount)
end

function QBCore.Functions.GetIdentifier(source, idtype)
    return GetPlayerIdentifierByType(source, idtype or 'license')
end

function QBCore.Functions.GetSource(identifier)
    for _, sid in ipairs(GetPlayers()) do
        local src = tonumber(sid)
        for _, id in ipairs(GetPlayerIdentifiers(sid)) do
            if id == identifier then return src end
        end
        local snap = core:GetPlayer(src)
        if snap and snap.citizenid == identifier then return src end
    end
    return 0
end

function QBCore.Functions.HasPermission(source, permission)
    return core:HasPermission(source, permission)
end

function QBCore.Functions.AddPermission(source, permission)
    return core:AddPermission(source, permission)
end

function QBCore.Functions.RemovePermission(source, permission)
    return core:RemovePermission(source, permission)
end

function QBCore.Functions.GetPermission(source)
    return core:GetPermission(source)
end

function QBCore.Functions.IsPlayerBanned(source)
    local banned = core:IsPlayerBanned(source)
    return banned == true
end

function QBCore.Functions.IsOptin(_source)
    return true
end

function QBCore.Functions.Kick(source, reason, _setKickReason, _deferrals)
    DropPlayer(source, reason or 'You were kicked from the server')
end

function QBCore.Functions.Notify(source, text, ntype, length)
    TriggerClientEvent('QBCore:Notify', source, text, ntype, length)
end

function QBCore.Functions.GetCoords(entity)
    local coords = GetEntityCoords(entity)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

function QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission)
    permission = tostring(permission or 'user'):lower()
    QBCore.Commands.List[name:lower()] = {
        name = name:lower(),
        permission = permission,
        help = help or '',
        arguments = arguments or {},
        argsrequired = argsrequired or false,
        callback = callback,
    }
    core:RegisterFrameworkCommand(name, help, arguments, argsrequired, callback, permission)
end

function QBCore.Commands.Refresh(source)
    core:RefreshCommands(source)
end

RegisterNetEvent('QBCore:ToggleDuty', function()
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local onduty = not p.PlayerData.job.onduty
    p.Functions.SetJobDuty(onduty)
    TriggerClientEvent('QBCore:Notify', src, onduty and 'You are now on duty!' or 'You are now off duty!', 'primary')
    TriggerEvent('QBCore:Server:SetDuty', src, onduty)
end)

RegisterNetEvent('QBCore:Server:SetMetaData', function(key, value)
    local src = source
    if key ~= 'hunger' and key ~= 'thirst' and key ~= 'stress' then return end
    core:SetMetadata(src, key, value)
end)

AddEventHandler('qs:server:characterLoaded', function(src, _data)
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    QBCore.Commands.Refresh(src)
    TriggerEvent('QBCore:Server:PlayerLoaded', p)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local player = QBCore.Players[src]
    if not player then return end
    if player.PlayerData.citizenid then
        QBCore.PlayersByCitizenId[player.PlayerData.citizenid] = nil
    end
    TriggerEvent('QBCore:Server:OnPlayerUnload', src)
    QBCore.Players[src] = nil
end)

AddEventHandler('qs:server:jobChange', function(src, job)
    local qb = qbJob(job, core:GetMetadata(src))
    if QBCore.Players[src] then QBCore.Players[src].PlayerData.job = qb end
    TriggerEvent('QBCore:Server:OnJobUpdate', src, qb)
end)

AddEventHandler('qs:server:moneyChange', function(src, account, kind, amount, reason)
    TriggerEvent('QBCore:Server:OnMoneyChange', src, account, amount, kind, reason or '')
    TriggerClientEvent('hud:client:OnMoneyChange', src, account, amount, kind == 'remove')
end)

AddEventHandler('qs:server:gangChange', function(src, gang)
    if QBCore.Players[src] then QBCore.Players[src].PlayerData.gang = gang end
    TriggerEvent('QBCore:Server:OnGangUpdate', src, gang)
    TriggerClientEvent('QBCore:Client:OnGangUpdate', src, gang)
end)

