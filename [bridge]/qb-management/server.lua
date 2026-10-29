local funds = {}

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `management_funds` (
            `id`       INT NOT NULL AUTO_INCREMENT,
            `job_name` VARCHAR(50) NOT NULL,
            `amount`   INT NOT NULL DEFAULT 0,
            `type`     VARCHAR(50) NOT NULL DEFAULT 'job',
            PRIMARY KEY (`id`),
            UNIQUE KEY `uniq_job_type` (`job_name`, `type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    Wait(500)
    local rows = MySQL.query.await('SELECT job_name, amount, type FROM management_funds') or {}
    for _, r in ipairs(rows) do
        funds[(r.type or 'job') .. ':' .. r.job_name] = tonumber(r.amount) or 0
    end
end)

local function save(account, atype)
    MySQL.query(
        'INSERT INTO management_funds (job_name, amount, type) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE amount = VALUES(amount)',
        { account, funds[atype .. ':' .. account] or 0, atype }
    )
end

local function get(account, atype)
    return funds[atype .. ':' .. account] or 0
end

local function add(account, amount, atype)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    funds[atype .. ':' .. account] = get(account, atype) + amount
    save(account, atype)
    return true
end

local function remove(account, amount, atype)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local cur = get(account, atype)
    if cur < amount then return false end
    funds[atype .. ':' .. account] = cur - amount
    save(account, atype)
    return true
end

exports('GetAccount', function(account) return get(account, 'job') end)
exports('AddMoney', function(account, amount) return add(account, amount, 'job') end)
exports('RemoveMoney', function(account, amount) return remove(account, amount, 'job') end)

exports('GetGangAccount', function(account) return get(account, 'gang') end)
exports('AddGangMoney', function(account, amount) return add(account, amount, 'gang') end)
exports('RemoveGangMoney', function(account, amount) return remove(account, amount, 'gang') end)
