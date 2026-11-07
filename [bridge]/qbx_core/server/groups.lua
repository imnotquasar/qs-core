local qbCore = exports['qb-core']

local function GetJobs()
    local out = {}
    for name, def in pairs(QsJobs()) do out[name] = QbxJobFromQs(name, def) end
    return out
end

local function GetGangs()
    local out = {}
    for name, def in pairs(QsGangs()) do out[name] = QbxGangFromQs(name, def) end
    return out
end

local function GetJob(name)
    local def = QsJobs()[name]
    return def and QbxJobFromQs(name, def) or nil
end

local function GetGang(name)
    local def = QsGangs()[name]
    return def and QbxGangFromQs(name, def) or nil
end

local function PublishCatalog()
    InvalidateCatalog()
    GlobalState.qbxJobs = GetJobs()
    GlobalState.qbxGangs = GetGangs()
end

local batching = false

local function runBatch(fn)
    batching = true
    local ok, err = pcall(fn)
    batching = false
    PublishCatalog()
    if not ok then error(err, 0) end
end

local function jobChanged(name, job)
    if not batching then PublishCatalog() end
    TriggerEvent('qbx_core:server:onJobUpdate', name, job)
    TriggerClientEvent('qbx_core:client:onJobUpdate', -1, name, job)
end

local function gangChanged(name, gang)
    if not batching then PublishCatalog() end
    TriggerEvent('qbx_core:server:onGangUpdate', name, gang)
    TriggerClientEvent('qbx_core:client:onGangUpdate', -1, name, gang)
end

local function writeJob(name, job)
    local qb = QbJobFromQbx(job)
    local ok = qbCore:AddJob(name, qb)
    if not ok then qbCore:UpdateJob(name, qb) end
    core:RegisterJob(name, QsJobFromQbx(name, job))
    jobChanged(name, GetJob(name))
end

local function writeGang(name, gang)
    local qb = QbGangFromQbx(gang)
    local ok = qbCore:AddGang(name, qb)
    if not ok then qbCore:UpdateGang(name, qb) end
    core:RegisterGang(name, QsGangFromQbx(name, gang))
    gangChanged(name, GetGang(name))
end

local function CreateJob(name, job)
    if type(name) ~= 'string' then return false, 'invalid_job_name' end
    name = name:lower()
    if type(job) ~= 'table' then return false, 'invalid_job_data' end
    writeJob(name, job)
    return true, 'success'
end

local function CreateJobs(jobs)
    if type(jobs) ~= 'table' then return false, 'invalid_jobs' end
    runBatch(function()
        for name, job in pairs(jobs) do
            if type(name) == 'string' and type(job) == 'table' then writeJob(name:lower(), job) end
        end
    end)
    return true, 'success'
end

local function RemoveJob(name)
    if type(name) ~= 'string' then return false, 'invalid_job_name' end
    name = name:lower()
    if not QsJobs()[name] then return false, 'job_not_exists' end
    qbCore:RemoveJob(name)
    core:RemoveJob(name)
    jobChanged(name, nil)
    return true, 'success'
end

local function CreateGangs(gangs)
    if type(gangs) ~= 'table' then return false, 'invalid_gangs' end
    runBatch(function()
        for name, gang in pairs(gangs) do
            if type(name) == 'string' and type(gang) == 'table' then writeGang(name:lower(), gang) end
        end
    end)
    return true, 'success'
end

local function RemoveGang(name)
    if type(name) ~= 'string' then return false, 'invalid_gang_name' end
    name = name:lower()
    if name == 'none' then return false, 'invalid_gang_name' end
    if not QsGangs()[name] then return false, 'gang_not_exists' end
    qbCore:RemoveGang(name)
    core:RemoveGang(name)
    gangChanged(name, nil)
    return true, 'success'
end

local function UpsertJobData(name, data)
    if type(name) ~= 'string' or type(data) ~= 'table' then return end
    name = name:lower()
    local job = GetJob(name) or { label = name, defaultDuty = true, offDutyPay = false, grades = { [0] = { name = 'Employee', payment = 0 } } }
    if data.label ~= nil then job.label = data.label end
    if data.defaultDuty ~= nil then job.defaultDuty = data.defaultDuty end
    if data.offDutyPay ~= nil then job.offDutyPay = data.offDutyPay end
    if data.type ~= nil then job.type = data.type end
    writeJob(name, job)
end

local function UpsertGangData(name, data)
    if type(name) ~= 'string' or type(data) ~= 'table' then return end
    name = name:lower()
    local gang = GetGang(name) or { label = name, grades = { [0] = { name = 'Member' } } }
    if data.label ~= nil then gang.label = data.label end
    writeGang(name, gang)
end

local function UpsertJobGrade(name, grade, data)
    local job = GetJob(name)
    if not job or type(data) ~= 'table' then return end
    job.grades[tonumber(grade) or 0] = data
    writeJob(name, job)
end

local function UpsertGangGrade(name, grade, data)
    local gang = GetGang(name)
    if not gang or type(data) ~= 'table' then return end
    gang.grades[tonumber(grade) or 0] = data
    writeGang(name, gang)
end

local function RemoveJobGrade(name, grade)
    local job = GetJob(name)
    if not job then return end
    job.grades[tonumber(grade) or 0] = nil
    writeJob(name, job)
end

local function RemoveGangGrade(name, grade)
    local gang = GetGang(name)
    if not gang then return end
    gang.grades[tonumber(grade) or 0] = nil
    writeGang(name, gang)
end

function IsGradeBoss(group, grade)
    local level = tonumber(grade) or 0
    local job = GetJob(group)
    if job then
        local g = job.grades[level]
        return g and g.isboss or false
    end
    local gang = GetGang(group)
    if gang then
        local g = gang.grades[level]
        return g and g.isboss or false
    end
    return nil
end

local function GetGroupMembers(group, groupType)
    if type(group) ~= 'string' or (groupType ~= 'job' and groupType ~= 'gang') then return {} end
    local members, seen = {}, {}
    local rows = MySQL.query.await('SELECT `citizenid`, `grade` FROM `qbx_player_groups` WHERE `group` = ? AND `type` = ?', { group, groupType }) or {}
    for _, row in ipairs(rows) do
        seen[row.citizenid] = true
        members[#members + 1] = { citizenid = row.citizenid, grade = tonumber(row.grade) or 0 }
    end
    local query = groupType == 'job'
        and "SELECT `citizenid`, JSON_UNQUOTE(JSON_EXTRACT(`job`, '$.grade')) AS grade FROM `players` WHERE JSON_UNQUOTE(JSON_EXTRACT(`job`, '$.name')) = ?"
        or "SELECT `citizenid`, JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.gang.grade.level')) AS grade FROM `players` WHERE JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.gang.name')) = ?"
    for _, row in ipairs(MySQL.query.await(query, { group }) or {}) do
        if not seen[row.citizenid] then
            members[#members + 1] = { citizenid = row.citizenid, grade = tonumber(row.grade) or 0 }
        end
    end
    return members
end

AddEventHandler('QBCore:Server:UpdateObject', function() SetTimeout(0, PublishCatalog) end)
AddEventHandler('qs:server:catalogReady', function() SetTimeout(0, PublishCatalog) end)
CreateThread(PublishCatalog)

lib.callback.register('qbx_core:server:getGroups', function()
    return { jobs = GetJobs(), gangs = GetGangs() }
end)

exports('GetJobs', GetJobs)
exports('GetGangs', GetGangs)
exports('GetJob', GetJob)
exports('GetGang', GetGang)
exports('CreateJob', CreateJob)
exports('CreateJobs', CreateJobs)
exports('RemoveJob', RemoveJob)
exports('CreateGangs', CreateGangs)
exports('RemoveGang', RemoveGang)
exports('UpsertJobData', UpsertJobData)
exports('UpsertGangData', UpsertGangData)
exports('UpsertJobGrade', UpsertJobGrade)
exports('UpsertGangGrade', UpsertGangGrade)
exports('RemoveJobGrade', RemoveJobGrade)
exports('RemoveGangGrade', RemoveGangGrade)
exports('IsGradeBoss', IsGradeBoss)
exports('GetGroupMembers', GetGroupMembers)
