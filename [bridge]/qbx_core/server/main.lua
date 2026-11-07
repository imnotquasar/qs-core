core = exports['qs-core']

QBX = QBX or {}
QBX.Players = {}
QBX.UsableItems = {}
QBX.Player_Buckets = {}
QBX.Entity_Buckets = {}
QBX.Shared = require 'shared.main'
QBX.Config = {
    server = require 'config.server',
    shared = require 'config.shared',
}
QBX.Version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.23.0'
QBX.Extra = {}
QBX.Groups = {}
QBX.InternalChange = {}
QBX.UserIds = {}
QBX.LastNeeds = {}

function WithInternalChange(src, fn, ...)
    QBX.InternalChange[src] = true
    local ok, result = pcall(fn, ...)
    QBX.InternalChange[src] = nil
    if not ok then error(result) end
    return result
end

GlobalState.PlayerCount = 0
GlobalState.MaxPlayers = GetConvarInt('sv_maxclients', 48)
GlobalState.PVPEnabled = QBX.Config.server.server.pvp

JOB_TYPES = { police = 'leo', bcso = 'leo', sasp = 'leo', ambulance = 'ems', mechanic = 'mechanic' }

MONEY_TYPES = { cash = true, bank = true, crypto = true }

DEFAULT_GANG = { name = 'none', label = 'No Gang', isboss = false, bankAuth = false, grade = { name = 'Unaffiliated', level = 0 } }

function ErrorResult(code, message)
    return false, { code = code, message = message or code }
end

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `qbx_player_groups` (
            `citizenid` VARCHAR(50) NOT NULL,
            `group`     VARCHAR(50) NOT NULL,
            `type`      VARCHAR(4)  NOT NULL,
            `grade`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`citizenid`, `type`, `group`),
            KEY `idx_qbx_groups_group` (`group`, `type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `qbx_users` (
            `userId`   INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `username` VARCHAR(255) DEFAULT NULL,
            `license`  VARCHAR(60)  DEFAULT NULL,
            `license2` VARCHAR(60)  DEFAULT NULL,
            `fivem`    VARCHAR(60)  DEFAULT NULL,
            `discord`  VARCHAR(60)  DEFAULT NULL,
            PRIMARY KEY (`userId`),
            UNIQUE KEY `uniq_qbx_users_license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    QBX.DatabaseReady = true
end)

function WaitDatabase()
    local deadline = GetGameTimer() + 15000
    while not QBX.DatabaseReady and GetGameTimer() < deadline do Wait(50) end
    return QBX.DatabaseReady == true
end

local catalog = { jobs = nil, gangs = nil, at = 0 }

local function refreshCatalog()
    if catalog.jobs and GetGameTimer() - catalog.at < 1000 then return end
    catalog.jobs = core:GetJobs() or {}
    catalog.gangs = core:GetGangs() or {}
    catalog.at = GetGameTimer()
end

function InvalidateCatalog()
    catalog.at = 0
end

function QsJobs()
    refreshCatalog()
    return catalog.jobs
end

function QsGangs()
    refreshCatalog()
    return catalog.gangs
end

local function gradeOf(grades, level)
    if not grades then return nil end
    return grades[level] or grades[tonumber(level)] or grades[tostring(level)]
end

function QbxJobFromQs(name, def)
    local grades = {}
    for lvl, g in pairs(def.grades or {}) do
        grades[tonumber(lvl) or 0] = {
            name = g.label or g.name,
            payment = g.salary or 0,
            isboss = g.isBoss or nil,
            bankAuth = g.bankAuth or g.isBoss or nil,
        }
    end
    return {
        label = def.label or name,
        type = def.type or JOB_TYPES[name],
        defaultDuty = def.defaultDuty ~= false,
        offDutyPay = def.offDutyPay or false,
        grades = grades,
    }
end

function QsJobFromQbx(name, job)
    local grades = {}
    for lvl, g in pairs(job.grades or {}) do
        local level = tonumber(lvl) or 0
        local label = g.name or ('Grade ' .. level)
        grades[level] = {
            name = tostring(label):lower(),
            label = label,
            salary = tonumber(g.payment) or 0,
            isBoss = g.isboss or false,
            bankAuth = g.bankAuth,
        }
    end
    if not next(grades) then grades[0] = { name = 'employee', label = 'Employee', salary = 0 } end
    return {
        label = job.label or name,
        type = job.type,
        defaultDuty = job.defaultDuty ~= false,
        offDutyPay = job.offDutyPay or false,
        grades = grades,
    }
end

function QbxGangFromQs(name, def)
    local grades = {}
    for lvl, g in pairs(def.grades or {}) do
        grades[tonumber(lvl) or 0] = {
            name = g.label or g.name,
            isboss = g.isBoss or nil,
            bankAuth = g.bankAuth or g.isBoss or nil,
        }
    end
    return { label = def.label or name, grades = grades }
end

function QsGangFromQbx(name, gang)
    local grades = {}
    for lvl, g in pairs(gang.grades or {}) do
        local level = tonumber(lvl) or 0
        local label = g.name or ('Grade ' .. level)
        grades[level] = { name = tostring(label):lower(), label = label, isBoss = g.isboss or false, bankAuth = g.bankAuth }
    end
    if not next(grades) then grades[0] = { name = 'member', label = 'Member', isBoss = false } end
    return { label = gang.label or name, grades = grades }
end

function QbJobFromQbx(job)
    local grades = {}
    for lvl, g in pairs(job.grades or {}) do
        grades[tostring(lvl)] = { name = g.name, payment = g.payment or 0, isboss = g.isboss or nil, bankAuth = g.bankAuth }
    end
    return { label = job.label, type = job.type, defaultDuty = job.defaultDuty ~= false, offDutyPay = job.offDutyPay or false, grades = grades }
end

function QbGangFromQbx(gang)
    local grades = {}
    for lvl, g in pairs(gang.grades or {}) do
        grades[tostring(lvl)] = { name = g.name, isboss = g.isboss or nil, bankAuth = g.bankAuth }
    end
    return { label = gang.label, grades = grades }
end

function BuildQsJob(name, grade, onduty)
    local def = QsJobs()[name]
    if not def then return nil end
    local level = tonumber(grade) or 0
    local g = gradeOf(def.grades, level)
    if not g then return nil end
    if onduty == nil then onduty = def.defaultDuty ~= false end
    return {
        name = name,
        label = def.label,
        grade = level,
        gradeName = g.name,
        gradeLabel = g.label,
        salary = g.salary,
        isBoss = g.isBoss or false,
        onduty = onduty and true or false,
    }
end

function BuildQbGang(name, grade)
    local def = QsGangs()[name] or QsGangs()['none']
    if not def then return DEFAULT_GANG end
    local level = tonumber(grade) or 0
    local g = gradeOf(def.grades, level) or gradeOf(def.grades, 0) or {}
    return {
        name = name,
        label = def.label or name,
        isboss = g.isBoss or false,
        grade = { name = g.label or g.name or 'Unaffiliated', level = level },
    }
end

function JobExists(name, grade)
    local def = QsJobs()[name]
    if not def then return false, 'job_not_found' end
    if grade ~= nil and not gradeOf(def.grades, grade) then return false, 'job_missing_grade' end
    return true
end

function GangExists(name, grade)
    local def = QsGangs()[name]
    if not def then return false, 'gang_not_found' end
    if grade ~= nil and not gradeOf(def.grades, grade) then return false, 'gang_missing_grade' end
    return true
end

local function isFemale(sex)
    return sex == 'female' or sex == 'f' or sex == 'F' or sex == 1 or sex == '1'
end

local DEFAULT_METADATA = {
    health = 200, hunger = 100, thirst = 100, stress = 0, isdead = false, inlaststand = false,
    armor = 0, ishandcuffed = false, tracker = false, injail = 0, jailitems = {}, status = {},
    phone = {}, dealerrep = 0, craftingrep = 0, attachmentcraftingrep = 0, currentapartment = nil,
    jobrep = { tow = 0, trucker = 0, taxi = 0, hotdog = 0 }, callsign = 'NO CALLSIGN',
    bloodtype = 'A+', fingerprint = 'QS-000000000000', walletid = 'QB-00000000',
    criminalrecord = { hasRecord = false }, licences = { id = true, driver = true, weapon = false },
    inside = { house = nil, apartment = {} }, phonedata = { SerialNumber = 0, InstalledApps = {} },
    optin = false,
}

local function copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end

local function qbxJob(job, meta)
    job = job or {}
    local name = job.name or 'unemployed'
    local def = QsJobs()[name] or {}
    local level = tonumber(job.grade) or 0
    local g = gradeOf(def.grades, level) or {}
    local onduty = job.onduty
    if onduty == nil and meta then onduty = meta.onduty end
    if onduty == nil then onduty = def.defaultDuty ~= false end
    local isboss = job.isBoss or g.isBoss or false
    return {
        name = name,
        label = job.label or def.label or 'Civilian',
        payment = job.salary or g.salary or 0,
        type = def.type or JOB_TYPES[name],
        onduty = onduty and true or false,
        isboss = isboss,
        bankAuth = g.bankAuth or isboss,
        grade = { name = job.gradeLabel or g.label or job.gradeName or 'Freelancer', level = level },
    }
end

local function qbxGang(gang)
    gang = gang or DEFAULT_GANG
    local name = gang.name or 'none'
    local def = QsGangs()[name] or {}
    local level = tonumber(gang.grade and gang.grade.level) or 0
    local g = gradeOf(def.grades, level) or {}
    local isboss = gang.isboss or g.isBoss or false
    return {
        name = name,
        label = gang.label or def.label or 'No Gang',
        isboss = isboss,
        bankAuth = g.bankAuth or isboss,
        grade = { name = (gang.grade and gang.grade.name) or g.label or g.name or 'Unaffiliated', level = level },
    }
end

local function qbxItems(src)
    local view = core:GetSlotView(src) or {}
    local items = {}
    for slot, it in pairs(view) do
        if type(it) == 'table' and it.name then
            local s = tonumber(slot) or it.slot
            items[s] = {
                name = it.name,
                label = it.label or it.name,
                count = it.count,
                amount = it.count,
                weight = it.weight or 0,
                slot = s,
                metadata = it.info or {},
                info = it.info or {},
            }
        end
    end
    return items
end

local function storeGroupRows(rows)
    for _, row in ipairs(rows or {}) do
        local groups = QBX.Groups[row.citizenid]
        if not groups then
            groups = { job = {}, gang = {} }
            QBX.Groups[row.citizenid] = groups
        end
        if groups[row.type] then groups[row.type][row.group] = tonumber(row.grade) or 0 end
    end
end

function PreloadGroups(licenses)
    if not WaitDatabase() or #licenses == 0 then return end
    local placeholders = ('?,'):rep(#licenses):sub(1, -2)
    local citizens = MySQL.query.await(('SELECT `citizenid` FROM `players` WHERE `license` IN (%s)'):format(placeholders), licenses) or {}
    local rows = MySQL.query.await(([[
        SELECT g.`citizenid`, g.`group`, g.`type`, g.`grade` FROM `qbx_player_groups` g
        JOIN `players` p ON p.`citizenid` = g.`citizenid` WHERE p.`license` IN (%s)
    ]]):format(placeholders), licenses)
    for _, row in ipairs(citizens) do QBX.Groups[row.citizenid] = { job = {}, gang = {} } end
    storeGroupRows(rows)
end

function GroupsOf(citizenid)
    local groups = QBX.Groups[citizenid]
    if groups then return groups end
    groups = { job = {}, gang = {} }
    QBX.Groups[citizenid] = groups
    local function load()
        if not WaitDatabase() then return end
        storeGroupRows(MySQL.query.await('SELECT `citizenid`, `group`, `type`, `grade` FROM `qbx_player_groups` WHERE `citizenid` = ?', { citizenid }))
    end
    if coroutine.isyieldable() then
        load()
    else
        CreateThread(function()
            load()
            local snap = core:GetPlayerByCitizenId(citizenid)
            if snap and snap.source and PushPlayerData then PushPlayerData(snap.source) end
        end)
    end
    return QBX.Groups[citizenid]
end

function BuildPlayerData(pd, src)
    if not pd then return nil end
    local ci = pd.charinfo or {}
    local meta = copy(pd.metadata or {})
    local extra = meta.accounts_extra or {}
    local pos = pd.position or {}
    local citizenid = pd.citizenid
    local groups = GroupsOf(citizenid)

    local job = qbxJob(pd.job, meta)
    local gang = qbxGang(src and core:GetGangForPlayer(src) or meta.gang)

    local jobs, gangs = {}, {}
    for name, grade in pairs(groups.job) do jobs[name] = grade end
    for name, grade in pairs(groups.gang) do gangs[name] = grade end
    if job.name ~= 'unemployed' then jobs[job.name] = job.grade.level end
    if gang.name ~= 'none' then gangs[gang.name] = gang.grade.level end

    local metadata = {}
    for k, v in pairs(DEFAULT_METADATA) do metadata[k] = copy(v) end
    for k, v in pairs(meta) do metadata[k] = v end
    metadata.isdead = pd.is_dead == true

    local data = {
        source = src,
        license = pd.license,
        name = pd.name,
        userId = QBX.Extra[citizenid] and QBX.Extra[citizenid].userId or nil,
        citizenid = citizenid,
        cid = pd.cid or ci.cid or 1,
        money = {
            cash = (pd.money and pd.money.cash) or 0,
            bank = (pd.money and pd.money.bank) or 0,
            crypto = tonumber(extra.crypto) or 0,
        },
        charinfo = {
            firstname = ci.firstname or 'Firstname',
            lastname = ci.lastname or 'Lastname',
            birthdate = ci.dob or ci.birthdate or '00-00-0000',
            gender = isFemale(ci.sex or ci.gender) and 1 or 0,
            backstory = ci.backstory or 'placeholder backstory',
            nationality = ci.nationality or 'USA',
            phone = ci.phone or '',
            account = ci.account or ('US0QBX' .. (citizenid or '')),
            cid = pd.cid or ci.cid or 1,
            card = ci.card,
        },
        metadata = metadata,
        job = job,
        jobs = jobs,
        gang = gang,
        gangs = gangs,
        position = vector4(pos.x or 0.0, pos.y or 0.0, pos.z or 0.0, pos.w or pos.heading or 0.0),
        items = src and qbxItems(src) or {},
        lastLoggedOut = meta.lastLoggedOut,
        optin = metadata.optin,
    }

    local custom = QBX.Extra[citizenid] and QBX.Extra[citizenid].fields
    if custom then
        for k, v in pairs(custom) do data[k] = v end
    end
    return data
end

function OnlinePlayerData(src)
    local snap = core:GetPlayer(src)
    if not snap or not snap.PlayerData then return nil end
    return BuildPlayerData(snap.PlayerData, src)
end

function OfflinePlayerData(citizenid)
    local row = core:GetOfflinePlayerByCitizenId(citizenid)
    if not row then return nil end
    return BuildPlayerData(row, nil)
end

function ResolveIdentifier(identifier)
    local src = tonumber(identifier)
    if src and src > 0 and type(identifier) == 'number' then
        local snap = core:GetPlayer(src)
        if snap then return src, snap.citizenid or snap.PlayerData.citizenid end
        return nil, nil
    end
    if type(identifier) ~= 'string' then return nil, nil end
    local snap = core:GetPlayerByCitizenId(identifier)
    if snap then return snap.source, snap.citizenid or snap.PlayerData.citizenid end
    local online = GetSource(identifier)
    if online and online > 0 then
        local s = core:GetPlayer(online)
        if s then return online, s.citizenid or s.PlayerData.citizenid end
    end
    return nil, identifier
end

function QsPatchFromQbx(data)
    local patch = {}
    if data.money then
        patch.money = { cash = tonumber(data.money.cash) or 0, bank = tonumber(data.money.bank) or 0 }
    end
    local metadata = copy(data.metadata or {})
    metadata.accounts_extra = metadata.accounts_extra or {}
    if data.money and data.money.crypto ~= nil then metadata.accounts_extra.crypto = tonumber(data.money.crypto) or 0 end
    if data.gang then metadata.gang = BuildQbGang(data.gang.name or 'none', data.gang.grade and data.gang.grade.level or 0) end
    if data.lastLoggedOut then metadata.lastLoggedOut = data.lastLoggedOut end
    patch.metadata = metadata
    if data.job then
        patch.job = BuildQsJob(data.job.name or 'unemployed', data.job.grade and data.job.grade.level or 0, data.job.onduty)
    end
    if data.charinfo then
        local ci = data.charinfo
        patch.charinfo = {
            firstname = ci.firstname, lastname = ci.lastname, dob = ci.birthdate,
            sex = ci.gender == 1 and 'female' or 'male', nationality = ci.nationality,
            phone = ci.phone, backstory = ci.backstory, account = ci.account, card = ci.card, cid = ci.cid,
        }
    end
    if data.position then
        local p = data.position
        patch.position = { x = p.x, y = p.y, z = p.z, w = p.w or 0.0 }
    end
    return patch
end
