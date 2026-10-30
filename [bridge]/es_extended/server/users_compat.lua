local core = exports['qs-core']
local schemaReady = false

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `users` (
            `identifier`   VARCHAR(60)  NOT NULL,
            `accounts`     LONGTEXT     DEFAULT NULL,
            `group`        VARCHAR(50)  NOT NULL DEFAULT 'user',
            `inventory`    LONGTEXT     DEFAULT NULL,
            `job`          VARCHAR(50)  NOT NULL DEFAULT 'unemployed',
            `job_grade`    INT          NOT NULL DEFAULT 0,
            `loadout`      LONGTEXT     DEFAULT NULL,
            `position`     LONGTEXT     DEFAULT NULL,
            `firstname`    VARCHAR(255) DEFAULT NULL,
            `lastname`     VARCHAR(255) DEFAULT NULL,
            `dateofbirth`  VARCHAR(25)  DEFAULT NULL,
            `sex`          VARCHAR(10)  DEFAULT NULL,
            `skin`         LONGTEXT     DEFAULT NULL,
            `metadata`     LONGTEXT     DEFAULT NULL,
            `phone_number` VARCHAR(20)  DEFAULT NULL,
            `updated_at`   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
            `qs_synced_at` DATETIME(3)  NULL DEFAULT NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local have = {}
    local rows = MySQL.query.await([[
        SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
          AND COLUMN_NAME IN ('phone_number', 'updated_at', 'qs_synced_at')
    ]])
    for _, row in ipairs(rows or {}) do have[row.name] = true end

    if not have.phone_number then
        MySQL.query.await('ALTER TABLE `users` ADD COLUMN `phone_number` VARCHAR(20) DEFAULT NULL')
    end

    if not have.updated_at then
        MySQL.query.await('ALTER TABLE `users` ADD COLUMN `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)')
    end
    if not have.qs_synced_at then
        MySQL.query.await('ALTER TABLE `users` ADD COLUMN `qs_synced_at` DATETIME(3) NULL DEFAULT NULL')
        MySQL.update.await('UPDATE `users` SET qs_synced_at = updated_at, updated_at = updated_at')
    end

    schemaReady = true
end)

local function waitSchema()
    local deadline = GetGameTimer() + 15000
    while not schemaReady and GetGameTimer() < deadline do Wait(50) end
    return schemaReady
end

local function blackMoney(pd)
    local extra = pd.metadata and pd.metadata.accounts_extra
    if type(extra) == 'table' and extra.black_money ~= nil then
        return tonumber(extra.black_money) or 0
    end
    return (pd.money or {}).black_money or 0
end

local function buildRow(pd)
    local ci = pd.charinfo or {}
    local job = pd.job or {}
    local money = pd.money or {}
    return {
        accounts = json.encode({
            money = money.cash or 0,
            bank = money.bank or 0,
            black_money = blackMoney(pd),
        }),
        group = (pd.metadata and pd.metadata.group) or 'user',
        inventory = json.encode(pd.inventory or {}),
        job = job.name or 'unemployed',
        job_grade = tonumber(job.grade) or 0,
        position = json.encode(pd.position or {}),
        firstname = ci.firstname,
        lastname = ci.lastname,
        dateofbirth = ci.dob or ci.birthdate,
        sex = ci.sex,
        skin = json.encode(pd.skin or {}),
        metadata = json.encode(pd.metadata or {}),
    }
end

local function syncUser(pd)
    if not pd or not pd.citizenid then return end
    if not waitSchema() then return end
    local row = buildRow(pd)
    MySQL.query([[
        INSERT INTO `users`
            (identifier, accounts, `group`, inventory, job, job_grade, position,
             firstname, lastname, dateofbirth, sex, skin, metadata, updated_at, qs_synced_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(3), NOW(3))
        ON DUPLICATE KEY UPDATE
            accounts = VALUES(accounts), `group` = VALUES(`group`), inventory = VALUES(inventory),
            job = VALUES(job), job_grade = VALUES(job_grade), position = VALUES(position),
            firstname = VALUES(firstname), lastname = VALUES(lastname), dateofbirth = VALUES(dateofbirth),
            sex = VALUES(sex), skin = VALUES(skin), metadata = VALUES(metadata),
            updated_at = NOW(3), qs_synced_at = NOW(3)
    ]], {
        pd.citizenid,
        row.accounts,
        row.group,
        row.inventory,
        row.job,
        row.job_grade,
        row.position,
        row.firstname,
        row.lastname,
        row.dateofbirth,
        row.sex,
        row.skin,
        row.metadata,
    })
end

AddEventHandler('qs:server:playerSaved', function(_, pd) syncUser(pd) end)

AddEventHandler('qs:server:playerLoaded', function(src)
    local snap = core:GetPlayer(src)
    if snap and snap.PlayerData then syncUser(snap.PlayerData) end
end)

local function decode(value)
    if type(value) ~= 'string' or value == '' then return nil end
    local ok, result = pcall(json.decode, value)
    if ok then return result end
    return nil
end

local function same(a, b)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end
    for k, v in pairs(a) do
        if not same(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function sameText(a, b)
    return tostring(a or '') == tostring(b or '')
end

local function buildJob(name, grade, current)
    local def = (core:GetJobs() or {})[name]
    if not def then return nil end
    local grades = def.grades or {}
    local gradeData = grades[grade] or grades[tostring(grade)]
    if not gradeData then return nil end
    local onduty = def.defaultDuty ~= false
    if current and current.name == name and current.onduty ~= nil then
        onduty = current.onduty
    end
    return {
        name = name,
        label = def.label,
        grade = grade,
        gradeName = gradeData.name,
        gradeLabel = gradeData.label,
        salary = gradeData.salary,
        isBoss = gradeData.isBoss or false,
        onduty = onduty,
    }
end

local function importUser(user)
    local pd = core:GetOfflinePlayerByCitizenId(user.identifier)
    if not pd then return end

    local expected = buildRow(pd)
    local patch = {}
    local metadata = pd.metadata or {}
    local metadataChanged = false

    if not same(decode(user.metadata), decode(expected.metadata)) then
        local value = decode(user.metadata)
        if type(value) == 'table' then
            metadata = value
            metadataChanged = true
        end
    end

    if not sameText(user.group, expected.group) and user.group then
        metadata.group = user.group
        metadataChanged = true
    end

    if not same(decode(user.accounts), decode(expected.accounts)) then
        local accounts = decode(user.accounts)
        if type(accounts) == 'table' then
            local money = pd.money or {}
            money.cash = tonumber(accounts.money) or money.cash
            money.bank = tonumber(accounts.bank) or money.bank
            patch.money = money
            if accounts.black_money ~= nil then
                if type(metadata.accounts_extra) ~= 'table' then metadata.accounts_extra = {} end
                metadata.accounts_extra.black_money = math.max(0, math.floor(tonumber(accounts.black_money) or 0))
                metadataChanged = true
            end
        end
    end

    local grade = tonumber(user.job_grade) or 0
    if user.job and (not sameText(user.job, expected.job) or grade ~= expected.job_grade) then
        local job = buildJob(user.job, grade, pd.job)
        if job then patch.job = job end
    end

    if not sameText(user.firstname, expected.firstname) or not sameText(user.lastname, expected.lastname)
        or not sameText(user.dateofbirth, expected.dateofbirth) or not sameText(user.sex, expected.sex) then
        local ci = pd.charinfo or {}
        ci.firstname = user.firstname
        ci.lastname = user.lastname
        if ci.birthdate ~= nil and ci.dob == nil then
            ci.birthdate = user.dateofbirth
        else
            ci.dob = user.dateofbirth
        end
        if type(ci.sex) == 'number' then
            ci.sex = tonumber(user.sex) or ci.sex
        else
            ci.sex = user.sex
        end
        patch.charinfo = ci
    end

    if not same(decode(user.skin), decode(expected.skin)) then
        local skin = decode(user.skin)
        if type(skin) == 'table' then patch.skin = skin end
    end

    if not same(decode(user.position), decode(expected.position)) then
        local pos = decode(user.position)
        if type(pos) == 'table' and pos.x and pos.y and pos.z then
            patch.position = { x = pos.x, y = pos.y, z = pos.z, w = pos.w or pos.heading or 0.0 }
        end
    end

    if metadataChanged then patch.metadata = metadata end

    if next(patch) then
        core:SaveOfflinePlayer(user.identifier, patch)
    end

    MySQL.update.await(
        'UPDATE `users` SET qs_synced_at = updated_at, updated_at = updated_at WHERE identifier = ? AND updated_at = ?',
        { user.identifier, user.stamp }
    )
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    if not identifiers or #identifiers == 0 then return end

    deferrals.defer()
    Wait(0)

    if waitSchema() then
        local ok, err = pcall(function()
            local placeholders = ('?,'):rep(#identifiers):sub(1, -2)
            local users = MySQL.query.await(([[
                SELECT u.identifier, u.accounts, u.`group`, u.job, u.job_grade, u.firstname, u.lastname,
                       u.dateofbirth, u.sex, u.skin, u.position, u.metadata,
                       CAST(u.updated_at AS CHAR) AS stamp
                FROM `users` u
                JOIN `players` p ON p.citizenid = u.identifier
                WHERE p.license IN (%s)
                  AND (u.qs_synced_at IS NULL OR u.updated_at > u.qs_synced_at)
            ]]):format(placeholders), identifiers)
            for _, user in ipairs(users or {}) do
                importUser(user)
            end
        end)
        if not ok then
            print(('^3[es_extended bridge]^7 users import failed for %s: %s'):format(GetPlayerName(src) or src, err))
        end
    end

    deferrals.done()
end)
