local qbCore = exports['qb-core']

function GetSource(identifier)
    if type(identifier) ~= 'string' then return 0 end
    local snap = core:GetPlayerByCitizenId(identifier)
    if snap and snap.source then return snap.source end
    for _, sid in ipairs(GetPlayers()) do
        for _, id in ipairs(GetPlayerIdentifiers(sid)) do
            if id == identifier then return tonumber(sid) end
        end
    end
    for citizenid, extra in pairs(QBX.Extra) do
        if tostring(extra.userId) == identifier then
            local s = core:GetPlayerByCitizenId(citizenid)
            if s then return s.source end
        end
    end
    return 0
end

function EnsureUserId(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    local license2 = GetPlayerIdentifierByType(src, 'license2')
    if not license and not license2 then return nil end
    if not WaitDatabase() then return nil end
    local key = license or license2
    local row = MySQL.single.await('SELECT `userId` FROM `qbx_users` WHERE `license` = ? OR `license2` = ? LIMIT 1', { key, license2 or key })
    if row then return row.userId end
    return MySQL.insert.await('INSERT INTO `qbx_users` (`username`, `license`, `license2`, `fivem`, `discord`) VALUES (?, ?, ?, ?, ?)', {
        GetPlayerName(src), license, license2,
        GetPlayerIdentifierByType(src, 'fivem'), GetPlayerIdentifierByType(src, 'discord'),
    })
end

local function GetUserId(identifier)
    local src = tonumber(identifier) or GetSource(identifier)
    if not src or src == 0 then return 0 end
    local player = GetOnlinePlayerObject(src)
    if player and player.PlayerData.userId then return player.PlayerData.userId end
    return EnsureUserId(src) or 0
end

local function GetPlayer(source)
    if type(source) == 'number' then return GetOnlinePlayerObject(source) end
    local src = GetSource(source)
    if src and src > 0 then return GetOnlinePlayerObject(src) end
    return nil
end

local function GetPlayerByCitizenId(citizenid)
    local snap = core:GetPlayerByCitizenId(citizenid)
    if not snap or not snap.source then return nil end
    return GetOnlinePlayerObject(snap.source)
end

local function GetPlayerByUserId(userId)
    for citizenid, extra in pairs(QBX.Extra) do
        if extra.userId == userId then return GetPlayerByCitizenId(citizenid) end
    end
    return nil
end

local function GetPlayerByPhone(number)
    for _, snap in pairs(core:GetPlayers() or {}) do
        local ci = snap.PlayerData and snap.PlayerData.charinfo
        if ci and tostring(ci.phone) == tostring(number) then return GetOnlinePlayerObject(snap.source) end
    end
    return nil
end

local function GetQBPlayers()
    local out = {}
    for _, snap in pairs(core:GetPlayers() or {}) do
        local player = GetOnlinePlayerObject(snap.source)
        if player then out[snap.source] = player end
    end
    return out
end

local function GetPlayersData()
    local out = {}
    for _, snap in pairs(core:GetPlayers() or {}) do
        local data = OnlinePlayerData(snap.source)
        if data then out[#out + 1] = data end
    end
    return out
end

local function GetDutyCountJob(job)
    local sources = {}
    for _, data in ipairs(GetPlayersData()) do
        if data.job.name == job and data.job.onduty then sources[#sources + 1] = data.source end
    end
    return #sources, sources
end

local function GetDutyCountType(jobType)
    local sources = {}
    for _, data in ipairs(GetPlayersData()) do
        if data.job.type == jobType and data.job.onduty then sources[#sources + 1] = data.source end
    end
    return #sources, sources
end

local function GetBucketObjects()
    return QBX.Player_Buckets, QBX.Entity_Buckets
end

local function SetPlayerBucket(source, bucket)
    if not source or not bucket then return false end
    Player(source).state:set('instance', bucket, true)
    SetPlayerRoutingBucket(source, bucket)
    QBX.Player_Buckets[source] = bucket
    return true
end

local function SetEntityBucket(entity, bucket)
    if not entity or not bucket then return false end
    SetEntityRoutingBucket(entity, bucket)
    QBX.Entity_Buckets[entity] = bucket
    return true
end

local function GetPlayersInBucket(bucket)
    local out = {}
    for src, b in pairs(QBX.Player_Buckets) do
        if b == bucket then out[#out + 1] = src end
    end
    return #out > 0 and out or false
end

local function GetEntitiesInBucket(bucket)
    local out = {}
    for ent, b in pairs(QBX.Entity_Buckets) do
        if b == bucket then out[#out + 1] = ent end
    end
    return #out > 0 and out or false
end

local function CreateUseableItem(item, cb)
    if type(item) ~= 'string' or not cb then return end
    QBX.UsableItems[item] = cb
    qbCore:GetCoreObject({ 'Functions' }).Functions.CreateUseableItem(item, function(src, data)
        if type(data) == 'table' then
            data.count = data.count or data.amount
            data.metadata = data.metadata or data.info
        end
        cb(src, data)
    end)
end

local function CanUseItem(item)
    return QBX.UsableItems[item]
end

local function IsWhitelisted(source)
    local cfg = QBX.Config.server.server
    if not cfg.whitelist then return true end
    return IsPlayerAceAllowed(source, cfg.whitelistPermission) and true or false
end

local function AddPermission(source, permission)
    local ok = core:AddPermission(source, permission)
    TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
    TriggerEvent('QBCore:Server:OnPermissionUpdate', source)
    return ok
end

local function RemovePermission(source, permission)
    local ok = core:RemovePermission(source, permission)
    TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
    TriggerEvent('QBCore:Server:OnPermissionUpdate', source)
    return ok
end

local function HasPermission(source, permission)
    return core:HasPermission(source, permission) and true or false
end

local function GetPermission(source)
    local perms = {}
    for _, perm in ipairs(QBX.Config.server.server.permissions or {}) do
        if HasPermission(source, perm) then perms[perm] = true end
    end
    local current = core:GetPermission(source)
    if type(current) == 'string' then perms[current] = true end
    return perms
end

local function IsOptin(source)
    if not QBX.Config.server.server.requireOptIn then return true end
    local player = GetOnlinePlayerObject(source)
    if not player then return false end
    if not HasPermission(source, 'admin') then return false end
    return player.PlayerData.metadata.optin ~= false
end

local function ToggleOptin(source)
    local player = GetOnlinePlayerObject(source)
    if not player then return end
    exports.qbx_core:SetMetadata(source, 'optin', not player.PlayerData.metadata.optin)
end

local function IsPlayerBanned(source)
    local banned, message = core:IsPlayerBanned(source)
    if banned then return true, message end
    return false
end

local NOTIFY_TYPES = { inform = 'info', info = 'info', primary = 'primary', success = 'success', error = 'error', warning = 'warning', warn = 'warning' }

function Notify(source, text, notifyType, duration, subTitle, position, style, icon, iconColor)
    local title, description
    if type(text) == 'table' then
        title = text.text or 'Placeholder'
        description = text.caption or nil
    elseif subTitle then
        title = text
        description = subTitle
    else
        description = text
    end
    TriggerClientEvent('qbx_core:client:notify', source, {
        title = title, description = description, type = NOTIFY_TYPES[notifyType or 'inform'] or 'info',
        duration = duration, position = position, style = style, icon = icon, iconColor = iconColor,
    })
end

local function GetCoreVersion()
    return QBX.Version
end

local function ExploitBan(source, origin)
    core:ExploitBan(source, origin)
end

local function HasPrimaryGroup(source, filter)
    local data = OnlinePlayerData(source)
    if not data then return false end
    return HasPlayerGotGroup(filter, data, true)
end

local function HasGroup(source, filter)
    local data = OnlinePlayerData(source)
    if not data then return false end
    return HasPlayerGotGroup(filter, data)
end

local function GetGroups(source)
    local data = OnlinePlayerData(source)
    if not data then return {} end
    return GetPlayerGroups(data)
end

local function matches(filter, value)
    if type(filter) ~= 'table' then return filter == value end
    if type(value) ~= 'table' then return false end
    for k, v in pairs(filter) do
        if k ~= 'strict' and not matches(v, value[k]) then return false end
    end
    return true
end

local function playerMatches(data, filters)
    if filters.license and data.license ~= filters.license then return false end
    if filters.job and data.job.name ~= filters.job then return false end
    if filters.gang and data.gang.name ~= filters.gang then return false end
    if filters.charinfo and not matches(filters.charinfo, data.charinfo) then return false end
    if filters.metadata and not matches(filters.metadata, data.metadata) then return false end
    return true
end

local function SearchPlayers(filters)
    filters = filters or {}
    local out, online = {}, {}
    for _, data in ipairs(GetPlayersData()) do
        online[data.citizenid] = true
        if playerMatches(data, filters) then out[#out + 1] = GetOnlinePlayerObject(data.source) end
    end
    local where, params = {}, {}
    if filters.license then where[#where + 1] = '`license` = ?'; params[#params + 1] = filters.license end
    if filters.job then where[#where + 1] = "JSON_UNQUOTE(JSON_EXTRACT(`job`, '$.name')) = ?"; params[#params + 1] = filters.job end
    if filters.gang then where[#where + 1] = "JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.gang.name')) = ?"; params[#params + 1] = filters.gang end
    local query = 'SELECT `citizenid` FROM `players`' .. (#where > 0 and (' WHERE ' .. table.concat(where, ' AND ')) or '')
    for _, row in ipairs(MySQL.query.await(query, params) or {}) do
        if not online[row.citizenid] then
            local player = exports.qbx_core:GetOfflinePlayer(row.citizenid)
            if player and playerMatches(player.PlayerData, filters) then out[#out + 1] = player end
        end
    end
    return out
end

local function DeleteVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    Entity(vehicle).state:set('persisted', nil, true)
    DeleteEntity(vehicle)
end

local function HasItem(source, items, amount)
    amount = amount or 1
    if type(items) == 'table' then
        if items[1] ~= nil then
            for _, name in ipairs(items) do
                if not core:HasItem(source, name, amount) then return false end
            end
        else
            for name, count in pairs(items) do
                if not core:HasItem(source, name, count) then return false end
            end
        end
        return true
    end
    return core:HasItem(source, items, amount) and true or false
end

local sessionId = 0

local function CreateSessionId(entity)
    if not entity then return end
    sessionId = sessionId + 1
    Entity(entity).state:set('sessionId', sessionId, true)
    return sessionId
end

local vehicleClasses

local function GetVehicleClass(model)
    if not vehicleClasses then
        local players = GetPlayers()
        if #players == 0 then return nil end
        vehicleClasses = lib.callback.await('qbx_core:client:getVehicleClasses', players[math.random(1, #players)])
    end
    return vehicleClasses and vehicleClasses[model] or nil
end

local function GetVehiclesByName(key)
    return key and QBX.Shared.Vehicles[key] or QBX.Shared.Vehicles
end

local function GetVehiclesByHash(key)
    return key and QBX.Shared.VehicleHashes[key] or QBX.Shared.VehicleHashes
end

local function GetVehiclesByCategory()
    return qbx.table.mapBySubfield(QBX.Shared.Vehicles, 'category')
end

local function GetWeapons(key)
    return key and QBX.Shared.Weapons[key] or QBX.Shared.Weapons
end

local function GetLocations()
    return QBX.Shared.Locations
end

local function EnablePersistence(vehicle)
    Entity(vehicle).state:set('persisted', true, true)
end

local function DisablePersistence(vehicle)
    Entity(vehicle).state:set('persisted', nil, true)
end

local function SetField(fieldName, data)
    if type(fieldName) ~= 'string' then return false, 'invalid_field_name' end
    QBX[fieldName] = data
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

exports('GetSource', GetSource)
exports('GetUserId', GetUserId)
exports('GetPlayer', GetPlayer)
exports('GetPlayerByCitizenId', GetPlayerByCitizenId)
exports('GetPlayerByUserId', GetPlayerByUserId)
exports('GetPlayerByPhone', GetPlayerByPhone)
exports('GetQBPlayers', GetQBPlayers)
exports('GetPlayersData', GetPlayersData)
exports('GetDutyCountJob', GetDutyCountJob)
exports('GetDutyCountType', GetDutyCountType)
exports('GetBucketObjects', GetBucketObjects)
exports('SetPlayerBucket', SetPlayerBucket)
exports('SetEntityBucket', SetEntityBucket)
exports('GetPlayersInBucket', GetPlayersInBucket)
exports('GetEntitiesInBucket', GetEntitiesInBucket)
exports('CreateUseableItem', CreateUseableItem)
exports('CanUseItem', CanUseItem)
exports('IsWhitelisted', IsWhitelisted)
exports('AddPermission', AddPermission)
exports('RemovePermission', RemovePermission)
exports('HasPermission', HasPermission)
exports('GetPermission', GetPermission)
exports('IsOptin', IsOptin)
exports('ToggleOptin', ToggleOptin)
exports('IsPlayerBanned', IsPlayerBanned)
exports('Notify', Notify)
exports('GetCoreVersion', GetCoreVersion)
exports('ExploitBan', ExploitBan)
exports('HasPrimaryGroup', HasPrimaryGroup)
exports('HasGroup', HasGroup)
exports('GetGroups', GetGroups)
exports('SearchPlayers', SearchPlayers)
exports('DeleteVehicle', DeleteVehicle)
exports('HasItem', HasItem)
exports('CreateSessionId', CreateSessionId)
exports('GetVehicleClass', GetVehicleClass)
exports('GetVehiclesByName', GetVehiclesByName)
exports('GetVehiclesByHash', GetVehiclesByHash)
exports('GetVehiclesByCategory', GetVehiclesByCategory)
exports('GetWeapons', GetWeapons)
exports('GetLocations', GetLocations)
exports('EnablePersistence', EnablePersistence)
exports('DisablePersistence', DisablePersistence)
exports('SetField', SetField)
