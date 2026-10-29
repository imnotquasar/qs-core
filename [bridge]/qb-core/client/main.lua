QBCore = QBCore or {}
QBCore.PlayerData = QBCore.PlayerData or {}
QBCore.IsLoggedIn = false

local itemsMirror = {}

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
        grade = { name = job.gradeLabel or job.gradeName or 'Freelancer', level = job.grade or 0 },
    }
end

local DEFAULT_GANG = { name = 'none', label = 'No Gang', isboss = false, grade = { name = 'Unaffiliated', level = 0 } }

local function syncOut()
    TriggerEvent('QBCore:Player:SetPlayerData', QBCore.PlayerData)
end

AddEventHandler('qs:client:onPlayerLoaded', function(d)
    if not d then return end
    local ci = d.charinfo or {}
    local meta = d.metadata or {}
    local extra = meta.accounts_extra or {}
    local sex = ci.sex or 'male'

    QBCore.PlayerData = {
        source = d.source or GetPlayerServerId(PlayerId()),
        citizenid = d.citizenid,
        cid = 1,
        license = d.license or '',
        name = d.name or ('%s %s'):format(ci.firstname or 'John', ci.lastname or 'Doe'),
        money = {
            cash = (d.money and d.money.cash) or 0,
            bank = (d.money and d.money.bank) or 0,
            crypto = tonumber(extra.crypto) or 0,
        },
        charinfo = {
            firstname = ci.firstname or 'John',
            lastname = ci.lastname or 'Doe',
            birthdate = ci.dob or '2000-01-01',
            gender = (sex == 'female' or sex == 'f') and 1 or 0,
            nationality = ci.nationality or 'USA',
            phone = ci.phone or '0000000000',
            account = 'US0' .. (d.citizenid or ''),
        },
        job = qbJob(d.job, meta),
        gang = d.gang or meta.gang or DEFAULT_GANG,
        metadata = meta,
        position = d.position,
        items = itemsMirror,
        optin = true,
    }
    if d.job and d.job.onduty ~= nil and QBCore.PlayerData.job then
        QBCore.PlayerData.job.onduty = d.job.onduty
    end

    QBCore.IsLoggedIn = true
    LocalPlayer.state:set('isLoggedIn', true, false)
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    syncOut()
end)

RegisterNetEvent('qs:gang:set', function(gang)
    if not QBCore.PlayerData.citizenid then return end
    QBCore.PlayerData.gang = gang or DEFAULT_GANG
    if QBCore.PlayerData.metadata then QBCore.PlayerData.metadata.gang = gang end
    TriggerEvent('QBCore:Client:OnGangUpdate', QBCore.PlayerData.gang)
    syncOut()
end)

RegisterNetEvent('qs:client:setDuty', function(onDuty)
    if not QBCore.PlayerData.citizenid or not QBCore.PlayerData.job then return end
    QBCore.PlayerData.job.onduty = onDuty and true or false
    if QBCore.PlayerData.metadata then QBCore.PlayerData.metadata.onduty = onDuty end
    TriggerEvent('QBCore:Client:SetDuty', QBCore.PlayerData.job.onduty)
    syncOut()
end)

RegisterNetEvent('qs:job:set', function(job)
    if not QBCore.PlayerData.citizenid then return end
    QBCore.PlayerData.job = qbJob(job, QBCore.PlayerData.metadata)
    TriggerEvent('QBCore:Client:OnJobUpdate', QBCore.PlayerData.job)
    syncOut()
end)

local function bumpMoney(account, amount, setAbs)
    if not QBCore.PlayerData.money then return end
    if QBCore.PlayerData.money[account] == nil then return end
    if setAbs then
        QBCore.PlayerData.money[account] = amount
    else
        QBCore.PlayerData.money[account] = QBCore.PlayerData.money[account] + amount
    end
    syncOut()
end

RegisterNetEvent('qs:money:add', function(account, amount) bumpMoney(account, amount or 0, false) end)
RegisterNetEvent('qs:money:remove', function(account, amount) bumpMoney(account, -(amount or 0), false) end)
RegisterNetEvent('qs:money:set', function(account, amount) bumpMoney(account, amount or 0, true) end)

RegisterNetEvent('qs:metadata:set', function(key, value)
    if not QBCore.PlayerData.metadata then return end
    QBCore.PlayerData.metadata[key] = value
    if key == 'gang' then
        QBCore.PlayerData.gang = value or DEFAULT_GANG
        TriggerEvent('QBCore:Client:OnGangUpdate', QBCore.PlayerData.gang)
    elseif key == 'onduty' and QBCore.PlayerData.job then
        QBCore.PlayerData.job.onduty = value and true or false
        TriggerEvent('QBCore:Client:SetDuty', QBCore.PlayerData.job.onduty)
    elseif key == 'accounts_extra' and QBCore.PlayerData.money then
        QBCore.PlayerData.money.crypto = tonumber((value or {}).crypto) or 0
    end
    syncOut()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(pd)
    if type(pd) == 'table' and pd.citizenid then
        pd.items = pd.items or itemsMirror
        QBCore.PlayerData = pd
    end
end)

RegisterNetEvent('qs-inv:client:set', function(data)
    if not data or not data.items then return end
    local items = {}
    for slot = 1, (data.slots or #data.items) do
        local it = data.items[slot]
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
                image = it.image or (it.name .. '.png'),
                shouldClose = true,
                description = it.description or '',
            }
        end
    end
    itemsMirror = items
    if QBCore.PlayerData.citizenid then
        QBCore.PlayerData.items = itemsMirror
        syncOut()
    end
end)

RegisterNetEvent('QBCore:Notify', function(text, ntype, length)
    QBCore.Functions.Notify(text, ntype, length)
end)

RegisterNetEvent('QBCore:Client:Notify', function(text, ntype, length)
    QBCore.Functions.Notify(text, ntype, length)
end)

RegisterNetEvent('hud:client:OnMoneyChange', function() end)

RegisterNetEvent('QBCore:Client:OnSharedUpdate', function(tableName, key, value)
    if QBCore.Shared[tableName] then
        QBCore.Shared[tableName][key] = value
    end
    TriggerEvent('QBCore:Client:UpdateObject')
end)

RegisterNetEvent('QBCore:Client:OnSharedUpdateMultiple', function(tableName, values)
    if QBCore.Shared[tableName] then
        for key, val in pairs(values) do
            QBCore.Shared[tableName][key] = val
        end
    end
    TriggerEvent('QBCore:Client:UpdateObject')
end)

RegisterNetEvent('QBCore:Client:UpdateObject', function()
    local obj = exports['qb-core']:GetCoreObject()
    if type(obj) == 'table' then
        for k, v in pairs(obj) do
            QBCore[k] = v
        end
    end
end)

AddEventHandler('qs-corehud:display', function(state)

    if state == false and QBCore.IsLoggedIn then

    end
end)
