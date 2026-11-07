local NEEDS = { 'hunger', 'thirst', 'stress' }
local primaryJob, primaryGang = {}, {}
local serverClosed, closedReason = QBX.Config.server.server.closed, QBX.Config.server.server.closedReason

local function setupPlayer(src)
    local snap = core:GetPlayer(src)
    if not snap or not snap.PlayerData then return end
    local citizenid = snap.citizenid or snap.PlayerData.citizenid
    QBX.Extra[citizenid] = QBX.Extra[citizenid] or { fields = {} }
    QBX.Extra[citizenid].userId = QBX.UserIds[src]

    local data = OnlinePlayerData(src)
    if not data then return end
    SyncPrimaryGroup(citizenid, 'job', data.job.name, data.job.grade.level)
    SyncPrimaryGroup(citizenid, 'gang', data.gang.name, data.gang.grade.level)
    primaryJob[src], primaryGang[src] = data.job.name, data.gang.name

    local state = Player(src).state
    state:set('isLoggedIn', true, true)
    state:set('loadInventory', true, true)
    for _, key in ipairs(NEEDS) do state:set(key, data.metadata[key], true) end
    state:set('canUseWeapons', not (data.metadata.isdead or data.metadata.inlaststand), true)

    GetOnlinePlayerObject(src)
    GlobalState.PlayerCount = (GlobalState.PlayerCount or 0) + 1
    PushPlayerData(src)
    if not QBX.Extra[citizenid].userId then
        CreateThread(function()
            QBX.UserIds[src] = EnsureUserId(src)
            QBX.Extra[citizenid].userId = QBX.UserIds[src]
            PushPlayerData(src)
        end)
    end
end

local function licensesOf(src)
    local out = {}
    for _, kind in ipairs({ 'license', 'license2' }) do
        local id = GetPlayerIdentifierByType(src, kind)
        if id then out[#out + 1] = id end
    end
    return out
end

function PrepareConnectingPlayer(src)
    PreloadGroups(licensesOf(src))
    QBX.UserIds[src] = QBX.UserIds[src] or EnsureUserId(src)
end

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function() PrepareConnectingPlayer(src) end)
end)

local function cleanupPlayer(src)
    local player = QBX.Players[src]
    if player then
        local citizenid = player.PlayerData.citizenid
        if citizenid then QBX.Groups[citizenid] = nil end
        GlobalState.PlayerCount = math.max(0, (GlobalState.PlayerCount or 1) - 1)
    end
    QBX.Players[src] = nil
    QBX.Player_Buckets[src] = nil
    QBX.LastNeeds[src] = nil
    primaryJob[src], primaryGang[src] = nil, nil
end

AddEventHandler('qs:server:characterLoaded', function(src)
    setupPlayer(src)
end)

AddEventHandler('qs:server:playerUnloaded', function(src)
    cleanupPlayer(src)
    Player(src).state:set('isLoggedIn', false, true)
    TriggerClientEvent('qbx_core:client:playerLoggedOut', src)
    TriggerEvent('qbx_core:server:playerLoggedOut', src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    cleanupPlayer(src)
    QBX.UserIds[src] = nil
    GlobalState.PlayerCount = GetNumPlayerIndices()
end)

AddEventHandler('qs:server:jobChange', function(src, job)
    local player = QBX.Players[src]
    if not player or not job then return end
    local citizenid = player.PlayerData.citizenid
    local previous = primaryJob[src]
    local grade = tonumber(job.grade) or 0
    if previous and previous ~= job.name and previous ~= 'unemployed' and not QBX.InternalChange[src] and GetConvar('qbx:setjob_replaces', 'true') == 'true' then
        local groups = GroupsOf(citizenid)
        if groups.job[previous] then
            groups.job[previous] = nil
            MySQL.prepare('DELETE FROM `qbx_player_groups` WHERE `citizenid` = ? AND `type` = ? AND `group` = ?', { citizenid, 'job', previous })
            TriggerEvent('qbx_core:server:onGroupUpdate', src, previous)
            TriggerClientEvent('qbx_core:client:onGroupUpdate', src, previous)
        end
    end
    local before = GroupsOf(citizenid).job[job.name]
    SyncPrimaryGroup(citizenid, 'job', job.name, grade)
    if job.name ~= 'unemployed' and before ~= grade then
        TriggerEvent('qbx_core:server:onGroupUpdate', src, job.name, grade)
        TriggerClientEvent('qbx_core:client:onGroupUpdate', src, job.name, grade)
    end
    primaryJob[src] = job.name
    PushPlayerData(src)
end)

AddEventHandler('qs:server:gangChange', function(src, gang)
    local player = QBX.Players[src]
    if not player or not gang then return end
    local citizenid = player.PlayerData.citizenid
    local previous = primaryGang[src]
    local grade = tonumber(gang.grade and gang.grade.level) or 0
    if previous and previous ~= gang.name and previous ~= 'none' and not QBX.InternalChange[src] and GetConvar('qbx:setgang_replaces', 'true') == 'true' then
        local groups = GroupsOf(citizenid)
        if groups.gang[previous] then
            groups.gang[previous] = nil
            MySQL.prepare('DELETE FROM `qbx_player_groups` WHERE `citizenid` = ? AND `type` = ? AND `group` = ?', { citizenid, 'gang', previous })
            TriggerEvent('qbx_core:server:onGroupUpdate', src, previous)
            TriggerClientEvent('qbx_core:client:onGroupUpdate', src, previous)
        end
    end
    local before = GroupsOf(citizenid).gang[gang.name]
    SyncPrimaryGroup(citizenid, 'gang', gang.name, grade)
    if gang.name ~= 'none' and before ~= grade then
        TriggerEvent('qbx_core:server:onGroupUpdate', src, gang.name, grade)
        TriggerClientEvent('qbx_core:client:onGroupUpdate', src, gang.name, grade)
    end
    primaryGang[src] = gang.name
    PushPlayerData(src)
end)

AddEventHandler('qs:server:moneyChange', function(src, account, kind, amount, reason)
    if not QBX.Players[src] then return end
    if account == 'money' then account = 'cash' end
    TriggerClientEvent('QBCore:Client:OnMoneyChange', src, account, amount, kind, reason or '')
    PushPlayerData(src)
end)

local NEED_SET = { hunger = true, thirst = true, stress = true }

AddEventHandler('qs:server:metadataChange', function(src, key, value)
    if NEED_SET[key] and QBX.Players[src] then
        QBX.LastNeeds[src] = QBX.LastNeeds[src] or {}
        QBX.LastNeeds[src][key] = value
        Player(src).state:set(key, value, true)
    elseif (key == 'isdead' or key == 'inlaststand') and QBX.Players[src] then
        Player(src).state:set('canUseWeapons', not value, true)
    end
end)

for _, key in ipairs(NEEDS) do
    AddStateBagChangeHandler(key, nil, function(bagName, _, value)
        local src = GetPlayerFromStateBagName(bagName)
        if not src or src == 0 or not QBX.Players[src] then return end
        value = tonumber(value)
        if not value then return end
        local last = QBX.LastNeeds[src] and QBX.LastNeeds[src][key]
        if last == value then return end
        core:SetMetadata(src, key, lib.math.clamp(value, 0, 100))
    end)
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    if QBX.Players[src] then Player(src).state:set('isLoggedIn', true, true) end
end)

RegisterNetEvent('QBCore:Server:CloseServer', function(reason)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin') and not exports.qbx_core:HasPermission(src, 'admin') then return end
    serverClosed, closedReason = true, reason or closedReason
    for _, sid in ipairs(GetPlayers()) do
        if not IsPlayerAceAllowed(sid, QBX.Config.server.server.whitelistPermission) then DropPlayer(sid, closedReason) end
    end
end)

RegisterNetEvent('QBCore:Server:OpenServer', function()
    local src = source
    if not IsPlayerAceAllowed(src, 'admin') and not exports.qbx_core:HasPermission(src, 'admin') then return end
    serverClosed = false
end)

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    local whitelist = QBX.Config.server.server.whitelist
    if not serverClosed and not whitelist then return end
    if IsPlayerAceAllowed(src, QBX.Config.server.server.whitelistPermission) then return end
    deferrals.defer()
    Wait(0)
    deferrals.done(serverClosed and closedReason or 'You are not whitelisted on this server')
end)

CreateThread(function()
    Wait(1000)
    for _, snap in pairs(core:GetPlayers() or {}) do
        if snap.source then setupPlayer(snap.source) end
    end
end)
