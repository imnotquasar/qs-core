local triggerEventHooks = require 'modules.hooks'

local maxJobsPerPlayer = GetConvarInt('qbx:max_jobs_per_player', 1)
local maxGangsPerPlayer = GetConvarInt('qbx:max_gangs_per_player', 1)
local setJobReplaces = GetConvar('qbx:setjob_replaces', 'true') == 'true'
local setGangReplaces = GetConvar('qbx:setgang_replaces', 'true') == 'true'

local function extraOf(citizenid)
    QBX.Extra[citizenid] = QBX.Extra[citizenid] or { fields = {} }
    return QBX.Extra[citizenid]
end

function PushPlayerData(src)
    local data = OnlinePlayerData(src)
    if not data then return nil end
    local player = QBX.Players[src]
    if player then player.PlayerData = data end
    TriggerEvent('QBCore:Player:SetPlayerData', data)
    TriggerClientEvent('QBCore:Player:SetPlayerData', src, data)
    return data
end

local function emitGroupUpdate(src, name, grade)
    if not src then return end
    TriggerEvent('qbx_core:server:onGroupUpdate', src, name, grade)
    TriggerClientEvent('qbx_core:client:onGroupUpdate', src, name, grade)
end

local function saveGroup(citizenid, kind, name, grade)
    local groups = GroupsOf(citizenid)
    groups[kind][name] = grade
    MySQL.prepare('INSERT INTO `qbx_player_groups` (`citizenid`, `group`, `type`, `grade`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `grade` = VALUES(`grade`)', { citizenid, name, kind, grade })
end

local function deleteGroup(citizenid, kind, name)
    local groups = GroupsOf(citizenid)
    groups[kind][name] = nil
    MySQL.prepare('DELETE FROM `qbx_player_groups` WHERE `citizenid` = ? AND `type` = ? AND `group` = ?', { citizenid, kind, name })
end

function SyncPrimaryGroup(citizenid, kind, name, grade)
    local empty = kind == 'job' and 'unemployed' or 'none'
    if name == empty then return end
    local groups = GroupsOf(citizenid)
    if groups[kind][name] ~= grade then saveGroup(citizenid, kind, name, grade) end
end

local function countGroups(map, empty)
    local n = 0
    for name in pairs(map) do
        if name ~= empty then n = n + 1 end
    end
    return n
end

local function currentPrimary(src, citizenid, kind)
    local data = src and OnlinePlayerData(src) or OfflinePlayerData(citizenid)
    if not data then return nil end
    return data[kind], data
end

local function SetPlayerPrimaryJob(citizenid, jobName)
    local src = ResolveIdentifier(citizenid)
    local data = src and OnlinePlayerData(src) or OfflinePlayerData(citizenid)
    if not data then return ErrorResult('player_not_found', ('player not found with citizenid %s'):format(citizenid)) end
    local grade = jobName == 'unemployed' and 0 or data.jobs[jobName]
    if grade == nil then return ErrorResult('player_not_in_job', ('player %s does not have job %s'):format(citizenid, jobName)) end
    local ok, code = JobExists(jobName, grade)
    if not ok then return ErrorResult(code) end
    local def = QsJobs()[jobName]
    local onduty = def ~= nil and def.defaultDuty ~= false
    if src then
        if not WithInternalChange(src, function() return core:SetJob(src, jobName, grade) end) then return ErrorResult('job_not_set') end
        WithInternalChange(src, function() core:SetJobDuty(src, onduty) end)
        PushPlayerData(src)
    else
        local row = core:GetOfflinePlayerByCitizenId(citizenid)
        local metadata = row and row.metadata or {}
        metadata.onduty = onduty
        core:SaveOfflinePlayer(citizenid, { job = BuildQsJob(jobName, grade, onduty), metadata = metadata })
    end
    return true
end

local function AddPlayerToJob(citizenid, jobName, grade)
    jobName = tostring(jobName or ''):lower()
    grade = tonumber(grade) or 0
    if jobName == 'unemployed' then return ErrorResult('unemployed', 'cannot add player to unemployed job') end
    local ok, code = JobExists(jobName, grade)
    if not ok then return ErrorResult(code, ('%s: %s grade %s'):format(code, jobName, grade)) end
    local src = ResolveIdentifier(citizenid)
    local primary, data = currentPrimary(src, citizenid, 'job')
    if not data then return ErrorResult('player_not_found', ('player not found with citizenid %s'):format(citizenid)) end
    if data.jobs[jobName] == grade then return true end
    if data.jobs[jobName] == nil and countGroups(data.jobs, 'unemployed') >= maxJobsPerPlayer then
        return ErrorResult('max_jobs', 'player already has maximum amount of jobs allowed')
    end
    saveGroup(citizenid, 'job', jobName, grade)
    if src then
        emitGroupUpdate(src, jobName, grade)
        if primary.name == jobName then
            WithInternalChange(src, function() core:SetJob(src, jobName, grade) end)
        end
        PushPlayerData(src)
    elseif primary.name == jobName then
        core:SaveOfflinePlayer(citizenid, { job = BuildQsJob(jobName, grade, primary.onduty) })
    end
    return true
end

local function RemovePlayerFromJob(citizenid, jobName)
    jobName = tostring(jobName or ''):lower()
    if jobName == 'unemployed' then return ErrorResult('unemployed', 'cannot remove player from unemployed job') end
    if not QsJobs()[jobName] then return ErrorResult('job_not_found', ('job not found: %s'):format(jobName)) end
    local src = ResolveIdentifier(citizenid)
    local primary, data = currentPrimary(src, citizenid, 'job')
    if not data then return ErrorResult('player_not_found', ('player not found with citizenid %s'):format(citizenid)) end
    if data.jobs[jobName] == nil then return true end
    deleteGroup(citizenid, 'job', jobName)
    if primary.name == jobName then
        if src then
            WithInternalChange(src, function() core:SetJob(src, 'unemployed', 0) end)
        else
            core:SaveOfflinePlayer(citizenid, { job = BuildQsJob('unemployed', 0) })
        end
    end
    if src then
        emitGroupUpdate(src, jobName)
        PushPlayerData(src)
    end
    return true
end

local function SetJob(identifier, jobName, grade)
    jobName = tostring(jobName or ''):lower()
    grade = tonumber(grade) or 0
    local ok, code = JobExists(jobName, grade)
    if not ok then return ErrorResult(code, ('%s: %s grade %s'):format(code, jobName, grade)) end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return ErrorResult('player_not_found', ('player not found with identifier %s'):format(tostring(identifier))) end
    local primary = currentPrimary(src, citizenid, 'job')
    if not primary then return ErrorResult('player_not_found') end
    if setJobReplaces and primary.name ~= 'unemployed' and primary.name ~= jobName then
        local removed, err = RemovePlayerFromJob(citizenid, primary.name)
        if not removed then return false, err end
    end
    if jobName ~= 'unemployed' then
        local added, err = AddPlayerToJob(citizenid, jobName, grade)
        if not added then return false, err end
    end
    return SetPlayerPrimaryJob(citizenid, jobName)
end

local function SetJobDuty(identifier, onDuty)
    local src = ResolveIdentifier(identifier)
    onDuty = onDuty and true or false
    if src then
        core:SetJobDuty(src, onDuty)
        TriggerEvent('QBCore:Server:SetDuty', src, onDuty)
        PushPlayerData(src)
    elseif type(identifier) == 'string' then
        local row = core:GetOfflinePlayerByCitizenId(identifier)
        if not row then return end
        local job = row.job or {}
        local metadata = row.metadata or {}
        metadata.onduty = onDuty
        core:SaveOfflinePlayer(identifier, { job = BuildQsJob(job.name or 'unemployed', job.grade or 0, onDuty), metadata = metadata })
    end
end

local function SetPlayerPrimaryGang(citizenid, gangName)
    local src = ResolveIdentifier(citizenid)
    local data = src and OnlinePlayerData(src) or OfflinePlayerData(citizenid)
    if not data then return ErrorResult('player_not_found', ('player not found with citizenid %s'):format(citizenid)) end
    local grade = gangName == 'none' and 0 or data.gangs[gangName]
    if grade == nil then return ErrorResult('player_not_in_gang', ('player %s does not have gang %s'):format(citizenid, gangName)) end
    local ok, code = GangExists(gangName, grade)
    if not ok then return ErrorResult(code) end
    if src then
        WithInternalChange(src, function() core:SetGang(src, gangName, grade) end)
        PushPlayerData(src)
    else
        local row = core:GetOfflinePlayerByCitizenId(citizenid)
        local metadata = row and row.metadata or {}
        metadata.gang = BuildQbGang(gangName, grade)
        core:SaveOfflinePlayer(citizenid, { metadata = metadata })
    end
    return true
end

local function AddPlayerToGang(citizenid, gangName, grade)
    gangName = tostring(gangName or ''):lower()
    grade = tonumber(grade) or 0
    if gangName == 'none' then return ErrorResult('none', 'cannot add player to gang none') end
    local ok, code = GangExists(gangName, grade)
    if not ok then return ErrorResult(code, ('%s: %s grade %s'):format(code, gangName, grade)) end
    local src = ResolveIdentifier(citizenid)
    local primary, data = currentPrimary(src, citizenid, 'gang')
    if not data then return ErrorResult('player_not_found', ('player not found with citizenid %s'):format(citizenid)) end
    if data.gangs[gangName] == grade then return true end
    if data.gangs[gangName] == nil and countGroups(data.gangs, 'none') >= maxGangsPerPlayer then
        return ErrorResult('max_gangs', 'player already has maximum amount of gangs allowed')
    end
    saveGroup(citizenid, 'gang', gangName, grade)
    if primary.name == gangName then SetPlayerPrimaryGang(citizenid, gangName) end
    if src then
        emitGroupUpdate(src, gangName, grade)
        PushPlayerData(src)
    end
    return true
end

local function RemovePlayerFromGang(citizenid, gangName)
    gangName = tostring(gangName or ''):lower()
    if gangName == 'none' then return ErrorResult('none', 'cannot remove player from gang none') end
    if not QsGangs()[gangName] then return ErrorResult('gang_not_found', ('gang not found: %s'):format(gangName)) end
    local src = ResolveIdentifier(citizenid)
    local primary, data = currentPrimary(src, citizenid, 'gang')
    if not data then return ErrorResult('player_not_found', ('player not found with citizenid %s'):format(citizenid)) end
    if data.gangs[gangName] == nil then return true end
    deleteGroup(citizenid, 'gang', gangName)
    if primary.name == gangName then SetPlayerPrimaryGang(citizenid, 'none') end
    if src then
        emitGroupUpdate(src, gangName)
        PushPlayerData(src)
    end
    return true
end

local function SetGang(identifier, gangName, grade)
    gangName = tostring(gangName or ''):lower()
    grade = tonumber(grade) or 0
    local ok, code = GangExists(gangName, grade)
    if not ok then return ErrorResult(code, ('%s: %s grade %s'):format(code, gangName, grade)) end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return ErrorResult('player_not_found', ('player not found with identifier %s'):format(tostring(identifier))) end
    local primary = currentPrimary(src, citizenid, 'gang')
    if not primary then return ErrorResult('player_not_found') end
    if setGangReplaces and primary.name ~= 'none' and primary.name ~= gangName then
        local removed, err = RemovePlayerFromGang(citizenid, primary.name)
        if not removed then return false, err end
    end
    if gangName ~= 'none' then
        local added, err = AddPlayerToGang(citizenid, gangName, grade)
        if not added then return false, err end
    end
    return SetPlayerPrimaryGang(citizenid, gangName)
end

local function Save(source)
    local snap = core:GetPlayer(source)
    if snap and snap.save then snap:save(false) end
end

local function SaveOffline(playerData)
    if type(playerData) ~= 'table' or not playerData.citizenid then return end
    core:SaveOfflinePlayer(playerData.citizenid, QsPatchFromQbx(playerData))
end

local function UpdatePlayerData(identifier)
    local src = ResolveIdentifier(identifier)
    if src then PushPlayerData(src) end
end

local function splitKey(key)
    local root, child = tostring(key):match('^([^%.]+)%.(.+)$')
    return root or key, child
end

local NEEDS = { hunger = true, thirst = true, stress = true }

local function GetMetadata(identifier, key)
    local src, citizenid = ResolveIdentifier(identifier)
    local data = src and OnlinePlayerData(src) or (citizenid and OfflinePlayerData(citizenid))
    if not data then return nil end
    if key == nil then return data.metadata end
    local root, child = splitKey(key)
    local value = data.metadata[root]
    if child then
        if type(value) ~= 'table' then return nil end
        return value[child]
    end
    return value
end

local function SetMetadata(identifier, key, value)
    if type(key) ~= 'string' then return end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return end
    local root, child = splitKey(key)
    if NEEDS[root] and not child then
        value = tonumber(value)
        if not value or not qbx.math.isFinite(value) then return end
        value = lib.math.clamp(value, 0, 100)
    end
    local old = GetMetadata(identifier, root)
    local newValue = value
    if child then
        newValue = {}
        if type(old) == 'table' then
            for k, v in pairs(old) do newValue[k] = v end
        end
        newValue[child] = value
    end
    if src then
        if root == 'isdead' then
            core:SetPlayerDead(src, newValue == true)
        else
            core:SetMetadata(src, root, newValue)
        end
        TriggerClientEvent('qbx_core:client:onSetMetaData', src, root, old, newValue)
        TriggerEvent('qbx_core:server:onSetMetaData', root, old, newValue, src)
        PushPlayerData(src)
    else
        local row = core:GetOfflinePlayerByCitizenId(citizenid)
        if not row then return end
        if root == 'isdead' then
            core:SaveOfflinePlayer(citizenid, { is_dead = newValue == true })
            return
        end
        local metadata = row.metadata or {}
        metadata[root] = newValue
        core:SaveOfflinePlayer(citizenid, { metadata = metadata })
    end
end

local function SetCharInfo(identifier, key, value)
    if type(key) ~= 'string' then return end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return end
    local qsKey, qsValue = key, value
    if key == 'birthdate' then qsKey = 'dob' end
    if key == 'gender' then qsKey, qsValue = 'sex', (tonumber(value) == 1 and 'female' or 'male') end
    if src then
        local snap = core:GetPlayer(src)
        if snap and snap.setCharInfo then snap:setCharInfo(qsKey, qsValue) end
        PushPlayerData(src)
    else
        local row = core:GetOfflinePlayerByCitizenId(citizenid)
        if not row then return end
        local charinfo = row.charinfo or {}
        charinfo[qsKey] = qsValue
        core:SaveOfflinePlayer(citizenid, { charinfo = charinfo })
    end
end

local function SetPlayerData(identifier, key, value)
    if type(key) ~= 'string' then return end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return end
    if key == 'job' and type(value) == 'table' then
        return SetJob(identifier, value.name, value.grade and value.grade.level or 0)
    elseif key == 'gang' and type(value) == 'table' then
        return SetGang(identifier, value.name, value.grade and value.grade.level or 0)
    elseif key == 'metadata' and type(value) == 'table' then
        for k, v in pairs(value) do SetMetadata(identifier, k, v) end
        return
    elseif key == 'charinfo' and type(value) == 'table' then
        for k, v in pairs(value) do SetCharInfo(identifier, k, v) end
        return
    elseif key == 'money' and type(value) == 'table' then
        for account, amount in pairs(value) do SetMoney(identifier, account, amount, 'set player data') end
        return
    elseif key == 'jobs' or key == 'gangs' or key == 'items' or key == 'citizenid' or key == 'source' then
        if src then PushPlayerData(src) end
        return
    end
    extraOf(citizenid).fields[key] = value
    if src then PushPlayerData(src) end
end

local function normalizeMoneyType(moneyType)
    moneyType = tostring(moneyType or ''):lower()
    if moneyType == 'money' then moneyType = 'cash' end
    return moneyType
end

local function validAmount(amount)
    amount = tonumber(amount)
    if not amount or not qbx.math.isFinite(amount) then return nil end
    amount = qbx.math.round(amount)
    if amount < 0 then return nil end
    return amount
end

local function offlineMoney(citizenid, moneyType, apply)
    local row = core:GetOfflinePlayerByCitizenId(citizenid)
    if not row then return false end
    if moneyType == 'crypto' then
        local metadata = row.metadata or {}
        metadata.accounts_extra = metadata.accounts_extra or {}
        local value = apply(tonumber(metadata.accounts_extra.crypto) or 0)
        if not value then return false end
        metadata.accounts_extra.crypto = value
        core:SaveOfflinePlayer(citizenid, { metadata = metadata })
    else
        local money = row.money or {}
        local value = apply(tonumber(money[moneyType]) or 0)
        if not value then return false end
        money[moneyType] = value
        core:SaveOfflinePlayer(citizenid, { money = money })
    end
    return true
end

local dontAllowMinus = {}
for _, name in ipairs(QBX.Config.server.money.dontAllowMinus or {}) do dontAllowMinus[name] = true end

function AddMoney(identifier, moneyType, amount, reason)
    moneyType = normalizeMoneyType(moneyType)
    amount = validAmount(amount)
    if not amount or not MONEY_TYPES[moneyType] then return false end
    if amount == 0 then return true end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return false end
    if not triggerEventHooks('addMoney', { source = src, moneyType = moneyType, amount = amount }) then return false end
    if src then
        return core:AddAccountMoney(src, moneyType, amount, reason or 'unknown') and true or false
    end
    return offlineMoney(citizenid, moneyType, function(current) return current + amount end)
end

function RemoveMoney(identifier, moneyType, amount, reason)
    moneyType = normalizeMoneyType(moneyType)
    amount = validAmount(amount)
    if not amount or not MONEY_TYPES[moneyType] then return false end
    if amount == 0 then return true end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return false end
    if not triggerEventHooks('removeMoney', { source = src, moneyType = moneyType, amount = amount }) then return false end
    if src then
        if dontAllowMinus[moneyType] and (core:GetAccountMoney(src, moneyType) or 0) - amount < 0 then return false end
        local ok = core:RemoveAccountMoney(src, moneyType, amount, reason or 'unknown')
        if ok and moneyType == 'bank' then TriggerClientEvent('qb-phone:client:RemoveBankMoney', src, amount) end
        return ok and true or false
    end
    return offlineMoney(citizenid, moneyType, function(current)
        if dontAllowMinus[moneyType] and current - amount < 0 then return nil end
        return current - amount
    end)
end

function SetMoney(identifier, moneyType, amount, reason)
    moneyType = normalizeMoneyType(moneyType)
    amount = validAmount(amount)
    if not amount or not MONEY_TYPES[moneyType] then return false end
    local src, citizenid = ResolveIdentifier(identifier)
    if not citizenid then return false end
    if not triggerEventHooks('setMoney', { source = src, moneyType = moneyType, amount = amount }) then return false end
    if src then
        if not core:SetAccountMoney(src, moneyType, amount) then return false end
        if moneyType ~= 'crypto' then
            TriggerEvent('QBCore:Server:OnMoneyChange', src, moneyType, amount, 'set', reason or 'unknown')
            TriggerClientEvent('QBCore:Client:OnMoneyChange', src, moneyType, amount, 'set', reason or 'unknown')
            TriggerClientEvent('hud:client:OnMoneyChange', src, moneyType, amount, false, reason)
            PushPlayerData(src)
        end
        return true
    end
    return offlineMoney(citizenid, moneyType, function() return amount end)
end

local function GetMoney(identifier, moneyType)
    moneyType = normalizeMoneyType(moneyType)
    if not MONEY_TYPES[moneyType] then return false end
    local src, citizenid = ResolveIdentifier(identifier)
    if src then return core:GetAccountMoney(src, moneyType) or 0 end
    local data = citizenid and OfflinePlayerData(citizenid)
    if not data then return false end
    return data.money[moneyType] or 0
end

local function AddItemToPlayer(src, item, amount, slot, metadata)
    return core:AddItem(src, item, amount or 1, slot, metadata)
end

function CreatePlayerObject(data, offline)
    local self = { Offline = offline and true or false, PlayerData = data, Functions = {} }
    local id = offline and data.citizenid or data.source

    function self.Functions.UpdatePlayerData() UpdatePlayerData(id) end
    function self.Functions.SetJob(job, grade) return SetJob(id, job, grade) end
    function self.Functions.SetGang(gang, grade) return SetGang(id, gang, grade) end
    function self.Functions.SetJobDuty(onDuty) SetJobDuty(id, onDuty) end
    function self.Functions.SetPlayerData(key, val) SetPlayerData(id, key, val) end
    function self.Functions.SetMetaData(key, val) SetMetadata(id, key, val) end
    function self.Functions.GetMetaData(key) return GetMetadata(id, key) end
    function self.Functions.AddJobReputation(amount)
        local rep = GetMetadata(id, 'jobrep') or {}
        local job = self.PlayerData.job.name
        rep[job] = (tonumber(rep[job]) or 0) + (tonumber(amount) or 0)
        SetMetadata(id, 'jobrep', rep)
    end
    function self.Functions.AddMoney(moneytype, amount, reason) return AddMoney(id, moneytype, amount, reason) end
    function self.Functions.RemoveMoney(moneytype, amount, reason) return RemoveMoney(id, moneytype, amount, reason) end
    function self.Functions.SetMoney(moneytype, amount, reason) return SetMoney(id, moneytype, amount, reason) end
    function self.Functions.GetMoney(moneytype) return GetMoney(id, moneytype) end
    function self.Functions.SetCreditCard(cardNumber) SetCharInfo(id, 'card', cardNumber) end
    function self.Functions.Save()
        if self.Offline then SaveOffline(self.PlayerData) else Save(id) end
    end
    function self.Functions.Logout()
        assert(not self.Offline, 'unsupported for offline players')
        Logout(id)
    end
    function self.Functions.AddItem(item, amount, slot, metadata)
        assert(not self.Offline, 'unsupported for offline players')
        return AddItemToPlayer(id, item, amount, slot, metadata)
    end
    function self.Functions.RemoveItem(item, amount, slot)
        assert(not self.Offline, 'unsupported for offline players')
        return core:RemoveItem(id, item, amount or 1, slot)
    end
    function self.Functions.GetItemBySlot(slot)
        assert(not self.Offline, 'unsupported for offline players')
        local it = core:GetItemBySlot(id, slot)
        if not it then return nil end
        it.amount = it.count
        it.metadata = it.info
        return it
    end
    function self.Functions.GetItemByName(itemName)
        assert(not self.Offline, 'unsupported for offline players')
        local data = OnlinePlayerData(id)
        for _, it in pairs(data and data.items or {}) do
            if it.name == itemName then return it end
        end
        return nil
    end
    function self.Functions.GetItemsByName(itemName)
        assert(not self.Offline, 'unsupported for offline players')
        local out = {}
        local data = OnlinePlayerData(id)
        for _, it in pairs(data and data.items or {}) do
            if it.name == itemName then out[#out + 1] = it end
        end
        return out
    end
    function self.Functions.ClearInventory()
        assert(not self.Offline, 'unsupported for offline players')
        core:SetInventory(id, {})
    end
    function self.Functions.SetInventory()
        error('Player.Functions.SetInventory is unsupported for qs-core. Try ClearInventory, then add the desired items.')
    end
    function self.Functions.GetCardSlot() error('Player.Functions.GetCardSlot is unsupported') end
    function self.Functions.AddField() error('Player.Functions.AddField is unsupported') end
    function self.Functions.AddMethod() error('Player.Functions.AddMethod is unsupported') end

    return self
end

function GetOnlinePlayerObject(src)
    local data = OnlinePlayerData(src)
    if not data then
        QBX.Players[src] = nil
        return nil
    end
    local player = QBX.Players[src]
    if not player then
        player = CreatePlayerObject(data, false)
        QBX.Players[src] = player
    else
        player.PlayerData = data
    end
    return player
end

local function GetOfflinePlayer(citizenid)
    if type(citizenid) ~= 'string' then return nil end
    local data = OfflinePlayerData(citizenid)
    if not data then return nil end
    return CreatePlayerObject(data, true)
end

local function CreatePlayer(playerData, offline)
    if offline or not playerData.source then
        return CreatePlayerObject(BuildPlayerData({
            citizenid = playerData.citizenid, license = playerData.license, name = playerData.name,
            charinfo = {}, money = playerData.money, metadata = playerData.metadata, position = playerData.position,
        }, nil), true)
    end
    return GetOnlinePlayerObject(playerData.source)
end

function Logout(source)
    local src = tonumber(source)
    if not src then return end
    local state = Player(src).state
    for key in pairs(NEEDS) do
        if state[key] ~= nil then SetMetadata(src, key, state[key]) end
    end
    SetMetadata(src, 'lastLoggedOut', os.time())
    core:Logout(src)
end

local function Login(source, citizenid, newData)
    local src = tonumber(source)
    if not src then return false end
    if citizenid then
        local ok = core:LoadCharacter(src, citizenid)
        return ok and true or false
    end
    if type(newData) ~= 'table' then return false end
    local created = CreateCharacterFromQbx(src, newData)
    if not created then return false end
    return core:LoadCharacter(src, created.citizenid, true) and true or false
end

local function DeleteCharacter(citizenid)
    if type(citizenid) ~= 'string' then return end
    local src = ResolveIdentifier(citizenid)
    if src then DropPlayer(tostring(src), 'Your character was deleted') end
    CreateThread(function()
        core:DeleteCharacter(citizenid)
        MySQL.prepare('DELETE FROM `qbx_player_groups` WHERE `citizenid` = ?', { citizenid })
        QBX.Groups[citizenid] = nil
        QBX.Extra[citizenid] = nil
    end)
end

local identifierChecks = {
    citizenid = "SELECT COUNT(*) AS count FROM `players` WHERE `citizenid` = ?",
    AccountNumber = "SELECT COUNT(*) AS count FROM `players` WHERE JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.account')) = ?",
    PhoneNumber = "SELECT COUNT(*) AS count FROM `players` WHERE JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.phone')) = ?",
    FingerId = "SELECT COUNT(*) AS count FROM `players` WHERE JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.fingerprint')) = ?",
    WalletId = "SELECT COUNT(*) AS count FROM `players` WHERE JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.walletid')) = ?",
    SerialNumber = "SELECT COUNT(*) AS count FROM `players` WHERE JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.phonedata.SerialNumber')) = ?",
}

local identifierGenerators = {
    citizenid = function() return tostring(lib.string.random('A.......')):upper() end,
    AccountNumber = function() return 'US0' .. math.random(1, 9) .. 'QBX' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99) end,
    PhoneNumber = function() return math.random(100, 999) .. math.random(1000000, 9999999) end,
    FingerId = function() return tostring(lib.string.random('...............')):upper() end,
    WalletId = function() return 'QB-' .. math.random(11111111, 99999999) end,
    SerialNumber = function() return math.random(11111111, 99999999) end,
}

local function GenerateUniqueIdentifier(identifierType)
    local generate = identifierGenerators[identifierType]
    local query = identifierChecks[identifierType]
    if not generate then error(('unknown identifier type %s'):format(tostring(identifierType))) end
    for _ = 1, 50 do
        local value = generate()
        local row = MySQL.single.await(query, { tostring(value) })
        if not row or (tonumber(row.count) or 0) == 0 then return value end
    end
    return generate()
end

exports('Login', Login)
exports('GetOfflinePlayer', GetOfflinePlayer)
exports('SetJob', SetJob)
exports('SetJobDuty', SetJobDuty)
exports('SetPlayerPrimaryJob', SetPlayerPrimaryJob)
exports('AddPlayerToJob', AddPlayerToJob)
exports('RemovePlayerFromJob', RemovePlayerFromJob)
exports('SetGang', SetGang)
exports('SetPlayerPrimaryGang', SetPlayerPrimaryGang)
exports('AddPlayerToGang', AddPlayerToGang)
exports('RemovePlayerFromGang', RemovePlayerFromGang)
exports('Logout', Logout)
exports('CreatePlayer', CreatePlayer)
exports('Save', Save)
exports('SaveOffline', SaveOffline)
exports('SetPlayerData', SetPlayerData)
exports('UpdatePlayerData', UpdatePlayerData)
exports('SetMetadata', SetMetadata)
exports('GetMetadata', GetMetadata)
exports('SetCharInfo', SetCharInfo)
exports('AddMoney', AddMoney)
exports('RemoveMoney', RemoveMoney)
exports('SetMoney', SetMoney)
exports('GetMoney', GetMoney)
exports('DeleteCharacter', DeleteCharacter)
exports('GenerateUniqueIdentifier', GenerateUniqueIdentifier)
