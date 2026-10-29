local core = exports['qs-core']

local function plateless(n) return tostring(n):gsub('%s+', '') end

local function newAccountNumber()
    for _ = 1, 40 do
        local n = 'QS'
        for _ = 1, 9 do n = n .. tostring(math.random(0, 9)) end
        if not MySQL.scalar.await('SELECT 1 FROM bank_accounts WHERE account_number = ?', { n }) then
            return n
        end
    end
    return 'QS' .. tostring(os.time())
end

local function ensureAccount(citizenid)
    local acc = MySQL.scalar.await('SELECT account_number FROM bank_accounts WHERE citizenid = ?', { citizenid })
    if acc then return acc end
    acc = newAccountNumber()
    MySQL.insert.await('INSERT INTO bank_accounts (citizenid, account_number) VALUES (?, ?)', { citizenid, acc })
    return acc
end

local function cidByAccount(account)
    return MySQL.scalar.await('SELECT citizenid FROM bank_accounts WHERE account_number = ?', { plateless(account) })
end

local function log(citizenid, ttype, amount, balance, label)
    MySQL.insert('INSERT INTO bank_transactions (citizenid, type, amount, balance, label) VALUES (?, ?, ?, ?, ?)',
        { citizenid, ttype, amount, balance, label })
end

local function history(citizenid)
    local rows = MySQL.query.await(
        'SELECT type, amount, balance, label, created FROM bank_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT ?',
        { citizenid, Config.HistoryLimit }) or {}
    for _, r in ipairs(rows) do r.created = tostring(r.created) end
    return rows
end

local function creditOfflineBank(citizenid, amount)
    local row = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', { citizenid })
    if not row then return false end
    local money = row.money and json.decode(row.money) or {}
    money.bank = (money.bank or 0) + amount
    MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(money), citizenid })
    return true
end

local function pushData(src, cid)
    TriggerClientEvent('qs-banking:client:update', src, {
        cash = core:GetMoney(src, 'cash'),
        bank = core:GetMoney(src, 'bank'),
        history = history(cid),
    })
end

core:RegisterCallback('qs-banking:data', function(src)
    local player = core:GetPlayer(src)
    if not player then return {} end
    local cid = player.citizenid
    return {
        cash = core:GetMoney(src, 'cash'),
        bank = core:GetMoney(src, 'bank'),
        account = ensureAccount(cid),
        history = history(cid),
    }
end)

local function amountOk(a) a = math.floor(tonumber(a) or 0) return a > 0 and a end

RegisterNetEvent('qs-banking:server:deposit', function(amount)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    amount = amountOk(amount)
    if not amount then return end
    if not core:RateLimit(('bank-dep:%d'):format(src), 1, 600) then return end
    if core:GetMoney(src, 'cash') < amount then
        TriggerClientEvent('qs:client:notify', src, T('no_cash'), 'error')
        return
    end
    if not core:RemoveMoney(src, 'cash', amount, 'bank-deposit') then return end
    core:AddMoney(src, 'bank', amount, 'bank-deposit')
    log(player.citizenid, 'deposit', amount, core:GetMoney(src, 'bank'), T('log_deposit'))
    TriggerClientEvent('qs:client:notify', src, T('deposited', amount), 'success')
    pushData(src, player.citizenid)
end)

RegisterNetEvent('qs-banking:server:withdraw', function(amount)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    amount = amountOk(amount)
    if not amount then return end
    if not core:RateLimit(('bank-wd:%d'):format(src), 1, 600) then return end
    if core:GetMoney(src, 'bank') < amount then
        TriggerClientEvent('qs:client:notify', src, T('no_funds'), 'error')
        return
    end
    if not core:RemoveMoney(src, 'bank', amount, 'bank-withdraw') then return end
    core:AddMoney(src, 'cash', amount, 'bank-withdraw')
    log(player.citizenid, 'withdraw', amount, core:GetMoney(src, 'bank'), T('log_withdraw'))
    TriggerClientEvent('qs:client:notify', src, T('withdrew', amount), 'success')
    pushData(src, player.citizenid)
end)

RegisterNetEvent('qs-banking:server:transfer', function(account, amount)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    amount = amountOk(amount)
    if not amount or not account then return end
    if not core:RateLimit(('bank-tr:%d'):format(src), 1, 1200) then return end

    local targetCid = cidByAccount(account)
    if not targetCid then
        TriggerClientEvent('qs:client:notify', src, T('bad_account'), 'error')
        return
    end
    if targetCid == player.citizenid then
        TriggerClientEvent('qs:client:notify', src, T('self_transfer'), 'error')
        return
    end

    local fee = math.floor(amount * (Config.TransferFee or 0.0))
    local total = amount + fee
    if core:GetMoney(src, 'bank') < total then
        TriggerClientEvent('qs:client:notify', src, T('no_funds'), 'error')
        return
    end
    if not core:RemoveMoney(src, 'bank', total, 'bank-transfer') then return end

    local targetPlayer = core:GetPlayerByCitizenId(targetCid)
    if targetPlayer then
        core:AddMoney(targetPlayer.source, 'bank', amount, 'bank-transfer')
        log(targetCid, 'transfer_in', amount, core:GetMoney(targetPlayer.source, 'bank'), T('log_from', player.citizenid))
        TriggerClientEvent('qs:client:notify', targetPlayer.source, T('received', amount), 'success')
        pushData(targetPlayer.source, targetCid)
    else
        creditOfflineBank(targetCid, amount)
        log(targetCid, 'transfer_in', amount, 0, T('log_from', player.citizenid))
    end

    log(player.citizenid, 'transfer_out', amount, core:GetMoney(src, 'bank'), T('log_to', account))
    TriggerClientEvent('qs:client:notify', src, T('transferred', amount), 'success')
    pushData(src, player.citizenid)
end)
