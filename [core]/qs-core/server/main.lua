QS.DatabaseReady = false

CreateThread(function()
    MySQL.ready(function()
        Database.EnsureCidColumn()
        QS.DatabaseReady = true
        Utils.Info('Database connection established.')
    end)
end)

function QS.GetPlayer(source)
    return QS.Players[source]
end

function QS.GetPlayerByCitizenId(citizenid)
    for _, player in pairs(QS.Players) do
        if player.citizenid == citizenid then
            return player
        end
    end
    return nil
end

function QS.GetPlayers()
    local list = {}
    for _, player in pairs(QS.Players) do
        list[#list + 1] = player
    end
    return list
end

exports('GetPlayer', function(source)
    return QS.ExportPlayer(source)
end)
exports('GetPlayerByCitizenId', function(citizenid)
    local player = QS.GetPlayerByCitizenId(citizenid)
    return player and QS.ExportPlayer(player.source) or nil
end)
exports('GetPlayers', function()
    local list = {}
    for _, player in pairs(QS.GetPlayers()) do
        list[#list + 1] = QS.ExportPlayer(player.source)
    end
    return list
end)

local function getLicense(source)
    local n = GetNumPlayerIdentifiers(source)
    for i = 0, n - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:sub(1, #Config.Identifier + 1) == (Config.Identifier .. ':') then
            return id
        end
    end
    return nil
end

local function uniqueCitizenId()
    local id
    repeat
        id = Utils.RandomCitizenId()
    until not Database.CitizenIdExists(id)
    return id
end

function QS.CreateCharacter(source, charinfo, skin, cid)
    local license = getLicense(source)
    if not license then return nil, 'no_license' end

    if Database.CountCharacters(license) >= Config.MaxCharacters then
        return nil, 'max_characters'
    end

    if cid ~= nil then
        cid = tonumber(cid)
        if Database.SlotTaken(license, cid) then
            return nil, 'slot_taken'
        end
    end

    charinfo = charinfo or {}

    local data = {
        citizenid = uniqueCitizenId(),
        license = license,
        name = GetPlayerName(source),
        charinfo = charinfo,
        cid = cid,
        money = Utils.Clone(Config.Accounts),
        job = Utils.BuildJob(Config.DefaultJob, Config.DefaultJobGrade),
        inventory = {},
        metadata = { hunger = 100, thirst = 100, gang = QS.BuildGang('none', 0), onduty = true },
        position = { x = Config.DefaultSpawn.x, y = Config.DefaultSpawn.y, z = Config.DefaultSpawn.z, w = Config.DefaultSpawn.w },
        skin = (type(skin) == 'table' and next(skin) ~= nil) and skin or nil,
    }

    Database.InsertCharacter(data)
    Utils.Info(('Created character %s for %s'):format(data.citizenid, license))
    return data
end

function QS.LoadCharacter(source, citizenid, isNew)
    local license = getLicense(source)
    if not license then return false, 'no_license' end

    local data = Database.LoadCharacter(citizenid)
    if not data then return false, 'not_found' end
    if data.license ~= license then return false, 'not_owner' end

    if not data.metadata then data.metadata = {} end
    if data.metadata.onduty == nil and data.job then
        local def = Jobs[data.job.name]
        data.metadata.onduty = def and def.defaultDuty ~= false
    end
    if not data.metadata.gang then
        data.metadata.gang = QS.BuildGang('none', 0)
    end

    local player = CreatePlayer(source, data)
    isNew = isNew or false

    TriggerEvent('qs:server:playerLoaded', source, player)

    TriggerEvent('qs:server:characterLoaded', source, {
        citizenid = player.citizenid,
        charinfo = player.PlayerData.charinfo,
        isNew = isNew,
    })

    Player(source).state:set('dead', player.PlayerData.is_dead == true, true)

    player:emit('qs:client:playerLoaded', {
        source = source,
        citizenid = player.citizenid,
        license = player.PlayerData.license,
        name = player.PlayerData.name,
        charinfo = player.PlayerData.charinfo,
        money = player.PlayerData.money,
        job = player.PlayerData.job,
        metadata = player.PlayerData.metadata,
        gang = player:getGang(),
        onduty = player.PlayerData.job and player.PlayerData.job.onduty,
        position = player.PlayerData.position,
        skin = player.PlayerData.skin,
        is_dead = player.PlayerData.is_dead == true,
        isNew = isNew,
    })

    Utils.Info(('Loaded character %s (src %s)'):format(citizenid, source))
    return true
end

function QS.Logout(source)
    local player = QS.Players[source]
    if not player then return false end

    local citizenid = player.citizenid
    player:save(true)
    player:destroy()

    TriggerEvent('qs:server:playerUnloaded', source, citizenid)
    TriggerClientEvent('qs:client:playerUnloaded', source)
    Utils.Info(('Logged out character %s (src %s)'):format(citizenid, source))
    return true
end

exports('CreateCharacter', QS.CreateCharacter)
exports('LoadCharacter', QS.LoadCharacter)
exports('Logout', QS.Logout)
exports('GetCharacters', function(source)
    local license = getLicense(source)
    if not license then return {} end
    return Database.GetCharacters(license)
end)
exports('DeleteCharacter', function(citizenid)
    Database.DeleteCharacter(citizenid)
end)

exports('GetInventory', function(source)
    local player = QS.Players[source]
    return player and player:getInventory() or {}
end)

exports('SetInventory', function(source, list)
    local player = QS.Players[source]
    if not player then return false end
    player:setInventory(list)
    return true
end)

exports('GetSkin', function(source)
    local player = QS.Players[source]
    return player and player:getSkin() or nil
end)

exports('SetSkin', function(source, skin)
    local player = QS.Players[source]
    if not player then return false end
    player:setSkin(skin)
    return true
end)

exports('GetMetadata', function(source, key)
    local player = QS.Players[source]
    return player and player:getMetadata(key) or nil
end)

exports('SetMetadata', function(source, key, value)
    local player = QS.Players[source]
    if not player then return false end
    player:setMetadata(key, value)
    return true
end)

exports('GetMoney', function(source, account)
    local player = QS.Players[source]
    return player and player:getMoney(account) or 0
end)

exports('AddMoney', function(source, account, amount, reason)
    local player = QS.Players[source]
    if not player then return false end
    return player:addMoney(account, amount, reason)
end)

exports('RemoveMoney', function(source, account, amount, reason)
    local player = QS.Players[source]
    if not player then return false end
    return player:removeMoney(account, amount, reason)
end)

exports('SetMoney', function(source, account, amount)
    local player = QS.Players[source]
    if not player then return false end
    return player:setMoney(account, amount)
end)

exports('SetJob', function(source, name, grade)
    local player = QS.Players[source]
    if not player then return false end
    return player:setJob(name, tonumber(grade) or 0)
end)

exports('AddItem', function(src, name, count, slot, info)
    return Inventory.AddItem(src, name, count, slot, info)
end)
exports('RemoveItem', function(src, name, count, slot, info)
    return Inventory.RemoveItem(src, name, count, slot, info)
end)
exports('HasItem', function(src, name, count)
    return Inventory.HasItem(src, name, count)
end)
exports('CanCarryItem', function(src, name, count)
    return Inventory.CanCarryItem(src, name, count)
end)
exports('GetItemCount', function(src, name)
    return Inventory.GetItemCount(src, name)
end)
exports('GetSlotView', function(src)
    return Inventory.GetSlotView(src)
end)
exports('GetItemBySlot', function(src, slot)
    return Inventory.GetItemBySlot(src, slot)
end)
exports('SetItemInfo', function(src, slot, info)
    return Inventory.SetItemInfo(src, slot, info)
end)
exports('SetBusy', function(src, ms)
    Inventory.SetBusy(src, ms)
end)
exports('RegisterUsableItem', function(item, cb)
    return Inventory.RegisterUsableItem(item, cb)
end)
exports('RegisterStash', function(id, label, slots, maxWeight, columns)
    return Inventory.RegisterStash(id, label, slots, maxWeight, columns)
end)

local function registerJob(name, def)
    if type(name) ~= 'string' or type(def) ~= 'table' then return false end
    def.label = def.label or name
    def.grades = def.grades or { [0] = { name = 'employee', label = 'Employee', salary = 0 } }
    Jobs[name] = def
    return true
end

local function updateJob(name, def)
    if not Jobs[name] then return false end
    return registerJob(name, def)
end

local function removeJob(name)
    if not Jobs[name] then return false end
    Jobs[name] = nil
    return true
end

exports('RegisterJob', registerJob)

exports('RegisterJobs', function(tbl)
    if type(tbl) ~= 'table' then return false end
    for name, def in pairs(tbl) do
        registerJob(name, def)
    end
    return true
end)

exports('UpdateJob', updateJob)
exports('RemoveJob', removeJob)

exports('GetJobs', function()
    return Jobs
end)

CreateThread(function()
    Wait(500)
    TriggerEvent('qs:server:catalogReady')
end)

AddEventHandler('playerDropped', function()
    local source = source
    local player = QS.Players[source]
    if not player then return end

    player:save(true)
    player:destroy()
    Utils.Debug(('Saved + released %s on drop'):format(source))
end)

CreateThread(function()
    while true do
        Wait(Config.SaveInterval)
        local count = 0
        for _, player in pairs(QS.Players) do
            player:save(false)
            count = count + 1
        end
        if count > 0 then
            Utils.Debug(('Autosaved %d player(s)'):format(count))
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, player in pairs(QS.Players) do
        player:save(true)
    end
    Utils.Info('Flushed all players on shutdown.')
end)
