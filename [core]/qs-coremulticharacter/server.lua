local core = exports['qs-core']

RegisterNetEvent('qs-coremultichar:server:getCharacters', function()
    local src = source
    local characters = core:GetCharacters(src)
    TriggerClientEvent('qs-coremultichar:client:setCharacters', src, characters, Config.MaxCharacters)
end)

RegisterNetEvent('qs-coremultichar:server:createCharacter', function(charinfo, skin)
    local src = source

    if type(charinfo) ~= 'table'
        or type(charinfo.firstname) ~= 'string' or #charinfo.firstname == 0
        or type(charinfo.lastname) ~= 'string' or #charinfo.lastname == 0 then
        TriggerClientEvent('qs-coremultichar:client:error', src, 'invalid_input')
        return
    end

    local clean = {
        firstname = charinfo.firstname:sub(1, 30),
        lastname = charinfo.lastname:sub(1, 30),
        dob = tostring(charinfo.dob or ''):sub(1, 10),
        sex = (charinfo.sex == 'female') and 'female' or 'male',
        nationality = tostring(charinfo.nationality or ''):sub(1, 40),
    }

    if type(skin) ~= 'table' then skin = nil end
    local data, err = core:CreateCharacter(src, clean, skin)
    if not data then
        TriggerClientEvent('qs-coremultichar:client:error', src, err)
        return
    end

    local ok, loadErr = core:LoadCharacter(src, data.citizenid, true)
    if not ok then
        TriggerClientEvent('qs-coremultichar:client:error', src, loadErr)
    end
end)

RegisterNetEvent('qs-coremultichar:server:selectCharacter', function(citizenid)
    local src = source
    if type(citizenid) ~= 'string' then return end

    local ok, err = core:LoadCharacter(src, citizenid)
    if not ok then
        TriggerClientEvent('qs-coremultichar:client:error', src, err)
    end
end)

RegisterNetEvent('qs-coremultichar:server:deleteCharacter', function(citizenid)
    local src = source
    if type(citizenid) ~= 'string' then return end

    local characters = core:GetCharacters(src)
    local owns = false
    for _, c in ipairs(characters) do
        if c.citizenid == citizenid then owns = true break end
    end
    if not owns then return end

    core:DeleteCharacter(citizenid)
    local refreshed = core:GetCharacters(src)
    TriggerClientEvent('qs-coremultichar:client:setCharacters', src, refreshed, Config.MaxCharacters)
end)

RegisterNetEvent('qs-coremultichar:server:logout', function()
    if not Config.EnableLogout then return end

    core:Logout(source)
end)

RegisterNetEvent('qs-coremultichar:server:quit', function()
    DropPlayer(tostring(source), 'Left the game.')
end)
