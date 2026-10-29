local PlayerMethods = {}
PlayerMethods.__index = PlayerMethods

function CreatePlayer(source, data)
    data.money = data.money or {}
    data.metadata = data.metadata or {}

    data.inventory = data.inventory or {}
    data.skin = data.skin or {}
    data.is_dead = data.is_dead or false
    data.job = data.job or Utils.BuildJob(Config.DefaultJob, Config.DefaultJobGrade)

    for account, starting in pairs(Config.Accounts) do
        if data.money[account] == nil then
            data.money[account] = starting
        end
    end

    local self = setmetatable({
        source = source,
        citizenid = data.citizenid,
        PlayerData = data,
    }, PlayerMethods)

    QS.Players[source] = self
    self:syncState()

    return self
end

function PlayerMethods:syncState()
    local state = Player(self.source).state
    state:set('citizenid', self.citizenid, true)
    state:set('job', self.PlayerData.job, true)
    state:set('name', self.PlayerData.name, true)
end

function PlayerMethods:getCitizenId() return self.citizenid end

function PlayerMethods:getSource() return self.source end

function PlayerMethods:getCharInfo() return self.PlayerData.charinfo end

function PlayerMethods:getPed() return GetPlayerPed(self.source) end

function PlayerMethods:getMoney(account)
    return self.PlayerData.money[account] or 0
end

function PlayerMethods:addMoney(account, amount, reason)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end
    if self.PlayerData.money[account] == nil then
        Utils.Error(('addMoney: unknown account "%s" for %s'):format(account, self.citizenid))
        return false
    end

    self.PlayerData.money[account] = self.PlayerData.money[account] + amount

    self:emit('qs:money:add', account, amount, reason or 'unknown')
    TriggerEvent('qs:server:moneyChange', self.source, account, 'add', amount, reason)
    return true
end

function PlayerMethods:removeMoney(account, amount, reason)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end
    local balance = self.PlayerData.money[account]
    if balance == nil then
        Utils.Error(('removeMoney: unknown account "%s" for %s'):format(account, self.citizenid))
        return false
    end
    if balance < amount then return false end

    self.PlayerData.money[account] = balance - amount
    self:emit('qs:money:remove', account, amount, reason or 'unknown')
    TriggerEvent('qs:server:moneyChange', self.source, account, 'remove', amount, reason)
    return true
end

function PlayerMethods:setMoney(account, amount)
    amount = tonumber(amount)
    if not amount or amount < 0 then return false end
    if self.PlayerData.money[account] == nil then return false end

    self.PlayerData.money[account] = amount
    self:emit('qs:money:set', account, amount)
    return true
end

function PlayerMethods:getJob() return self.PlayerData.job end

function PlayerMethods:setJob(name, grade)
    local job = Utils.BuildJob(name, tonumber(grade) or 0)
    if not job then
        Utils.Error(('setJob: invalid job "%s" grade "%s"'):format(name, tostring(grade)))
        return false
    end

    local onduty = self.PlayerData.metadata and self.PlayerData.metadata.onduty
    if onduty == nil then
        local def = Jobs[name]
        onduty = def and def.defaultDuty ~= false
    end
    job.onduty = onduty and true or false

    self.PlayerData.job = job
    Player(self.source).state:set('job', job, true)
    self:emit('qs:job:set', job)
    TriggerEvent('qs:server:jobChange', self.source, job)
    return true
end

function PlayerMethods:setJobDuty(onDuty)
    onDuty = onDuty and true or false
    self:setMetadata('onduty', onDuty)
    if self.PlayerData.job then
        self.PlayerData.job.onduty = onDuty
        Player(self.source).state:set('job', self.PlayerData.job, true)
        self:emit('qs:job:set', self.PlayerData.job)
        TriggerEvent('qs:server:jobChange', self.source, self.PlayerData.job)
    end
    self:emit('qs:client:setDuty', onDuty)
    return true
end

function PlayerMethods:getGang()
    return self:getMetadata('gang') or QS.BuildGang('none', 0)
end

function PlayerMethods:setGang(name, grade)
    local gang = QS.BuildGang(name, grade)
    self:setMetadata('gang', gang)
    TriggerEvent('qs:server:gangChange', self.source, gang)
    self:emit('qs:gang:set', gang)
    return true
end

function PlayerMethods:isDead() return self.PlayerData.is_dead == true end

function PlayerMethods:setDead(state)
    self.PlayerData.is_dead = state and true or false
    Player(self.source).state:set('dead', self.PlayerData.is_dead, true)
end

function PlayerMethods:getMetadata(key)
    if key == nil then return self.PlayerData.metadata end
    return self.PlayerData.metadata[key]
end

function PlayerMethods:setMetadata(key, value)
    self.PlayerData.metadata[key] = value
    self:emit('qs:metadata:set', key, value)
end

function PlayerMethods:getInventory()
    return self.PlayerData.inventory
end

function PlayerMethods:setInventory(list)
    self.PlayerData.inventory = list or {}
end

function PlayerMethods:getSkin()
    return self.PlayerData.skin
end

function PlayerMethods:setSkin(skin)
    if type(skin) ~= 'table' then return end
    self.PlayerData.skin = skin
    self:emit('qs:clothing:apply', skin)
end

function PlayerMethods:getCoords()
    local ped = self:getPed()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    return vec4(coords.x, coords.y, coords.z, heading)
end

function PlayerMethods:emit(event, ...)
    TriggerClientEvent(event, self.source, ...)
end

function PlayerMethods:save(awaitSave)
    if GetPlayerPed(self.source) ~= 0 then
        local c = self:getCoords()
        self.PlayerData.position = { x = c.x, y = c.y, z = c.z, w = c.w }
    end
    Database.SaveCharacter(self.PlayerData, awaitSave)
    TriggerEvent('qs:server:playerSaved', self.source, self.PlayerData)
end

function PlayerMethods:destroy()
    QS.Players[self.source] = nil
end

function PlayerMethods:addItem(name, count, slot, info)
    return Inventory.AddItem(self.source, name, count, slot, info)
end

function PlayerMethods:removeItem(name, count, slot, info)
    return Inventory.RemoveItem(self.source, name, count, slot, info)
end

function PlayerMethods:hasItem(name, count)
    return Inventory.HasItem(self.source, name, count)
end

function PlayerMethods:canCarryItem(name, count)
    return Inventory.CanCarryItem(self.source, name, count)
end

function PlayerMethods:getItemCount(name)
    return Inventory.GetItemCount(self.source, name)
end

function PlayerMethods:getSlotView()
    return Inventory.GetSlotView(self.source)
end

function PlayerMethods:getItemBySlot(slot)
    return Inventory.GetItemBySlot(self.source, slot)
end

function PlayerMethods:setItemInfo(slot, info)
    return Inventory.SetItemInfo(self.source, slot, info)
end

function PlayerMethods:setBusy(ms)
    Inventory.SetBusy(self.source, ms)
end

local function bindPlayerMethod(player, export, name, fn)
    return function(a, b, c, d, e)
        if a == player or a == export or (type(a) == 'table' and a.source == player.source) then
            return fn(player, b, c, d, e)
        end
        return fn(player, a, b, c, d)
    end
end

-- Cross-resource exports cannot preserve metatables; expose bound method copies instead.
function QS.ExportPlayer(source)
    local player = QS.GetPlayer(source)
    if not player then return nil end

    local export = {
        source = player.source,
        citizenid = player.citizenid,
        PlayerData = player.PlayerData,
    }

    for name, fn in pairs(PlayerMethods) do
        if type(fn) == 'function' and name ~= '__index' then
            export[name] = bindPlayerMethod(player, export, name, fn)
        end
    end

    return export
end
