Accounts = {}

local PRIMARY = { cash = true, bank = true, money = true }

local function normalizeAccount(account)
    account = tostring(account or 'cash'):lower()
    if account == 'money' then account = 'cash' end
    return account
end

function Accounts.Get(source, account)
    account = normalizeAccount(account)
    if PRIMARY[account] then
        local player = QS.GetPlayer(source)
        return player and player:getMoney(account) or 0
    end

    local player = QS.GetPlayer(source)
    if not player then return 0 end
    local extra = player:getMetadata('accounts_extra') or {}
    return tonumber(extra[account]) or 0
end

function Accounts.Add(source, account, amount, reason)
    account = normalizeAccount(account)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end

    if PRIMARY[account] then
        local player = QS.GetPlayer(source)
        return player and player:addMoney(account, amount, reason) or false
    end

    local player = QS.GetPlayer(source)
    if not player then return false end
    local extra = player:getMetadata('accounts_extra') or {}
    extra[account] = (tonumber(extra[account]) or 0) + amount
    player:setMetadata('accounts_extra', extra)
    TriggerClientEvent('hud:client:OnMoneyChange', source, account, amount, false)
    TriggerEvent('qs:server:moneyChange', source, account, 'add', amount, reason or '')
    return true
end

function Accounts.Remove(source, account, amount, reason)
    account = normalizeAccount(account)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end

    if PRIMARY[account] then
        local player = QS.GetPlayer(source)
        return player and player:removeMoney(account, amount, reason) or false
    end

    local player = QS.GetPlayer(source)
    if not player then return false end
    local extra = player:getMetadata('accounts_extra') or {}
    local cur = tonumber(extra[account]) or 0
    if cur < amount then return false end
    extra[account] = cur - amount
    player:setMetadata('accounts_extra', extra)
    TriggerClientEvent('hud:client:OnMoneyChange', source, account, amount, true)
    TriggerEvent('qs:server:moneyChange', source, account, 'remove', amount, reason or '')
    return true
end

function Accounts.Set(source, account, amount)
    account = normalizeAccount(account)
    amount = tonumber(amount)
    if amount == nil or amount < 0 then return false end

    if PRIMARY[account] then
        local player = QS.GetPlayer(source)
        return player and player:setMoney(account, amount) or false
    end

    local player = QS.GetPlayer(source)
    if not player then return false end
    local extra = player:getMetadata('accounts_extra') or {}
    extra[account] = amount
    player:setMetadata('accounts_extra', extra)
    TriggerClientEvent('hud:client:OnMoneyChange', source, account, amount, false)
    TriggerEvent('qs:server:moneyChange', source, account, 'set', amount, '')
    return true
end

exports('GetAccountMoney', Accounts.Get)
exports('AddAccountMoney', Accounts.Add)
exports('RemoveAccountMoney', Accounts.Remove)
exports('SetAccountMoney', Accounts.Set)
