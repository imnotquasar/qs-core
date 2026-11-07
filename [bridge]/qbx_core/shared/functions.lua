function HasPlayerGotGroup(filter, playerData, primary)
    local groups = not primary and GetPlayerGroups(playerData)
    if not filter then return false end
    local _type = type(filter)

    if _type == 'string' then
        local job = playerData.job.name == filter
        local gang = playerData.gang.name == filter
        local group = groups and groups[filter]
        local citizenId = playerData.citizenid == filter

        if job or gang or group or citizenId then
            return true
        end
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            for name, grade in pairs(filter) do
                local job = playerData.job.name == name
                local gang = playerData.gang.name == name
                local group = groups and groups[name]
                local citizenId = playerData.citizenid == name

                if job and grade <= playerData.job.grade.level or gang and grade <= playerData.gang.grade.level or group and grade <= group or citizenId then
                    return true
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local name = filter[i]
                local job = playerData.job.name == name
                local gang = playerData.gang.name == name
                local group = groups and groups[name]
                local citizenId = playerData.citizenid == name

                if job or gang or group or citizenId then
                    return true
                end
            end
        end
    end
    return false
end

function GetPlayerGroups(playerData)
    local groups = {}
    for job, data in pairs(playerData.jobs) do
        if not groups[job] then
            groups[job] = data
        end
    end
    for gang, data in pairs(playerData.gangs) do
        if not groups[gang] then
            groups[gang] = data
        else
            lib.print.warn(('Duplicate group name %s found in player_groups table, check job and gang shared lua.'):format(gang))
        end
    end
    return groups
end