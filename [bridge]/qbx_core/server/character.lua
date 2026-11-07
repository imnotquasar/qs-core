local function playerLicenses(src)
    local out = {}
    for _, kind in ipairs({ 'license', 'license2' }) do
        local id = GetPlayerIdentifierByType(src, kind)
        if id then out[id] = true end
    end
    return out
end

function CreateCharacterFromQbx(src, data)
    local charinfo = data.charinfo or data
    local created = core:CreateCharacter(src, {
        firstname = charinfo.firstname,
        lastname = charinfo.lastname,
        dob = charinfo.birthdate,
        sex = tonumber(charinfo.gender) == 1 and 'female' or 'male',
        nationality = charinfo.nationality,
        backstory = charinfo.backstory,
    }, nil, data.cid or charinfo.cid)
    return created
end

local function giveStarterItems(src)
    for _, item in ipairs(QBX.Config.shared.starterItems or {}) do
        local metadata = item.metadata
        if type(metadata) == 'function' then
            local ok, result = pcall(metadata, src)
            metadata = ok and result or nil
        end
        core:AddItem(src, item.name, item.amount or 1, nil, metadata)
    end
end

lib.callback.register('qbx_core:server:getCharacters', function(source)
    PrepareConnectingPlayer(source)
    local characters = {}
    for _, row in ipairs(core:GetCharacters(source) or {}) do
        local citizenid = row.citizenid
        local data = citizenid and OfflinePlayerData(citizenid)
        if data then
            characters[#characters + 1] = {
                citizenid = data.citizenid,
                charinfo = data.charinfo,
                money = data.money,
                job = data.job,
                gang = data.gang,
                position = data.position,
                metadata = data.metadata,
                cid = data.cid,
                lastLoggedOut = data.lastLoggedOut,
            }
        end
    end
    local license2 = GetPlayerIdentifierByType(source, 'license2')
    local license = GetPlayerIdentifierByType(source, 'license')
    local limits = QBX.Config.server.characters
    local allowed = (license2 and limits.playersNumberOfCharacters[license2])
        or (license and limits.playersNumberOfCharacters[license])
        or limits.defaultNumberOfCharacters
    return characters, allowed
end)

lib.callback.register('qbx_core:server:getPreviewPedData', function(_, citizenid)
    local row = core:GetOfflinePlayerByCitizenId(citizenid)
    if not row then return nil end
    local sex = row.charinfo and row.charinfo.sex
    local female = sex == 'female' or sex == 'f' or sex == 1
    local model = female and `mp_f_freemode_01` or `mp_m_freemode_01`
    local skin = type(row.skin) == 'table' and next(row.skin) ~= nil and json.encode(row.skin) or nil
    return skin, model
end)

lib.callback.register('qbx_core:server:loadCharacter', function(source, citizenid)
    local ok = core:LoadCharacter(source, citizenid)
    return ok and true or false
end)

lib.callback.register('qbx_core:server:createCharacter', function(source, data)
    local created = CreateCharacterFromQbx(source, data or {})
    if not created then return nil end
    if not core:LoadCharacter(source, created.citizenid, true) then return nil end
    giveStarterItems(source)
    return OnlinePlayerData(source)
end)

local function deleteOwnCharacter(source, citizenid)
    local row = core:GetOfflinePlayerByCitizenId(citizenid)
    if not row or not playerLicenses(source)[row.license] then return false end
    exports.qbx_core:DeleteCharacter(citizenid)
    return true
end

lib.callback.register('qbx_core:server:deleteCharacter', deleteOwnCharacter)

RegisterNetEvent('qbx_core:server:deleteCharacter', function(citizenid)
    deleteOwnCharacter(source, citizenid)
end)
