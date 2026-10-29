Database = {}

local function decodeRow(row)
    row.charinfo = row.charinfo and json.decode(row.charinfo) or {}
    row.money = row.money and json.decode(row.money) or {}
    row.job = row.job and json.decode(row.job) or nil
    row.skin = row.skin and json.decode(row.skin) or nil
    row.position = row.position and json.decode(row.position) or nil
    return row
end

function Database.EnsureCidColumn()
    local col = MySQL.scalar.await([[
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'players' AND COLUMN_NAME = 'cid'
    ]])
    if tonumber(col) == 0 then
        MySQL.query.await('ALTER TABLE `players` ADD COLUMN `cid` INT DEFAULT NULL')
        MySQL.query.await('CREATE INDEX `idx_players_license_cid` ON `players` (`license`, `cid`)')
        Utils.Info('Added players.cid column for multicharacter slot support.')
    end
end

function Database.EnsureCharacterSlots(license)
    if not license then return end

    local rows = MySQL.query.await(
        'SELECT `citizenid`, `cid` FROM `players` WHERE `license` = ? ORDER BY `last_updated` ASC',
        { license }
    ) or {}

    local usedSlots = {}
    local pending = {}

    for _, row in ipairs(rows) do
        local cid = row.cid ~= nil and tonumber(row.cid) or nil
        if cid ~= nil then
            usedSlots[cid] = true
        else
            pending[#pending + 1] = row.citizenid
        end
    end

    if #pending == 0 then return end

    local nextSlot = 0
    for _, citizenid in ipairs(pending) do
        while usedSlots[nextSlot] do
            nextSlot = nextSlot + 1
        end
        MySQL.update.await('UPDATE `players` SET `cid` = ? WHERE `citizenid` = ?', { nextSlot, citizenid })
        usedSlots[nextSlot] = true
        nextSlot = nextSlot + 1
    end
end

function Database.GetCharacters(license)
    Database.EnsureCharacterSlots(license)

    local rows = MySQL.query.await(
        'SELECT `citizenid`, `cid`, `name`, `charinfo`, `money`, `job`, `skin`, `position` FROM `players` WHERE `license` = ? ORDER BY `cid` ASC',
        { license }
    ) or {}

    for _, row in ipairs(rows) do
        decodeRow(row)
    end

    return rows
end

function Database.CountCharacters(license)
    local result = MySQL.scalar.await(
        'SELECT COUNT(*) FROM `players` WHERE `license` = ?',
        { license }
    )
    return result or 0
end

function Database.SlotTaken(license, cid)
    if license == nil or cid == nil then return false end
    local result = MySQL.scalar.await(
        'SELECT 1 FROM `players` WHERE `license` = ? AND `cid` = ? LIMIT 1',
        { license, cid }
    )
    return result ~= nil
end

function Database.CitizenIdExists(citizenid)
    local result = MySQL.scalar.await(
        'SELECT 1 FROM `players` WHERE `citizenid` = ?',
        { citizenid }
    )
    return result ~= nil
end

function Database.LoadCharacter(citizenid)
    local row = MySQL.single.await(
        'SELECT * FROM `players` WHERE `citizenid` = ?',
        { citizenid }
    )
    if not row then return nil end

    return {
        citizenid = row.citizenid,
        cid = row.cid ~= nil and tonumber(row.cid) or nil,
        license = row.license,
        name = row.name,
        charinfo = row.charinfo and json.decode(row.charinfo) or {},
        money = row.money and json.decode(row.money) or {},
        job = row.job and json.decode(row.job) or nil,
        inventory = row.inventory and json.decode(row.inventory) or {},
        metadata = row.metadata and json.decode(row.metadata) or {},
        position = row.position and json.decode(row.position) or nil,
        skin = row.skin and json.decode(row.skin) or nil,
        is_dead = tonumber(row.is_dead) == 1,
    }
end

function Database.InsertCharacter(data)
    MySQL.insert.await('INSERT INTO `players` (citizenid, license, name, charinfo, money, job, inventory, metadata, position, skin, is_dead, cid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        data.citizenid,
        data.license,
        data.name,
        json.encode(data.charinfo or {}),
        json.encode(data.money or {}),
        json.encode(data.job or {}),
        json.encode(data.inventory or {}),
        json.encode(data.metadata or {}),
        data.position and json.encode(data.position) or nil,
        data.skin and json.encode(data.skin) or nil,
        data.is_dead and 1 or 0,
        data.cid,
    })
end

function Database.SaveCharacter(data, awaitSave)
    local query = 'UPDATE `players` SET `name` = ?, `charinfo` = ?, `money` = ?, `job` = ?, `inventory` = ?, `metadata` = ?, `position` = ?, `skin` = ?, `is_dead` = ?, `cid` = ? WHERE `citizenid` = ?'
    local params = {
        data.name,
        json.encode(data.charinfo or {}),
        json.encode(data.money or {}),
        json.encode(data.job or {}),
        json.encode(data.inventory or {}),
        json.encode(data.metadata or {}),
        data.position and json.encode(data.position) or nil,
        data.skin and json.encode(data.skin) or nil,
        data.is_dead and 1 or 0,
        data.cid,
        data.citizenid,
    }

    if awaitSave then
        MySQL.update.await(query, params)
    else
        MySQL.update(query, params)
    end
end

function Database.DeleteCharacter(citizenid)
    MySQL.update.await('DELETE FROM `players` WHERE `citizenid` = ?', { citizenid })
end
