local core = exports['qs-core']

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `users` (
            `identifier`  VARCHAR(60)  NOT NULL,
            `accounts`    LONGTEXT     DEFAULT NULL,
            `group`       VARCHAR(50)  NOT NULL DEFAULT 'user',
            `inventory`   LONGTEXT     DEFAULT NULL,
            `job`         VARCHAR(50)  NOT NULL DEFAULT 'unemployed',
            `job_grade`   INT          NOT NULL DEFAULT 0,
            `loadout`     LONGTEXT     DEFAULT NULL,
            `position`    LONGTEXT     DEFAULT NULL,
            `firstname`   VARCHAR(255) DEFAULT NULL,
            `lastname`    VARCHAR(255) DEFAULT NULL,
            `dateofbirth` VARCHAR(25)  DEFAULT NULL,
            `sex`         VARCHAR(10)  DEFAULT NULL,
            `skin`        LONGTEXT     DEFAULT NULL,
            `metadata`    LONGTEXT     DEFAULT NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function syncUser(pd)
    if not pd or not pd.citizenid then return end
    local ci = pd.charinfo or {}
    local job = pd.job or {}
    local money = pd.money or {}
    local accounts = json.encode({
        money = money.cash or 0,
        bank = money.bank or 0,
        black_money = money.black_money or 0,
    })
    MySQL.query([[
        INSERT INTO `users`
            (identifier, accounts, `group`, inventory, job, job_grade, position,
             firstname, lastname, dateofbirth, sex, skin, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            accounts = VALUES(accounts), `group` = VALUES(`group`), inventory = VALUES(inventory),
            job = VALUES(job), job_grade = VALUES(job_grade), position = VALUES(position),
            firstname = VALUES(firstname), lastname = VALUES(lastname), dateofbirth = VALUES(dateofbirth),
            sex = VALUES(sex), skin = VALUES(skin), metadata = VALUES(metadata)
    ]], {
        pd.citizenid,
        accounts,
        (pd.metadata and pd.metadata.group) or 'user',
        json.encode(pd.inventory or {}),
        job.name or 'unemployed',
        tonumber(job.grade) or 0,
        json.encode(pd.position or {}),
        ci.firstname,
        ci.lastname,
        ci.dob or ci.birthdate,
        ci.sex,
        json.encode(pd.skin or {}),
        json.encode(pd.metadata or {}),
    })
end

AddEventHandler('qs:server:playerSaved', function(_, pd) syncUser(pd) end)

AddEventHandler('qs:server:playerLoaded', function(src)
    local snap = core:GetPlayer(src)
    if snap and snap.PlayerData then syncUser(snap.PlayerData) end
end)
