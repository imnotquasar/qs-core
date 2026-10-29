Offline = {}

function Offline.GetByCitizenId(citizenid)
    local data = Database.LoadCharacter(citizenid)
    if not data then return nil end
    return {
        Offline = true,
        citizenid = data.citizenid,
        license = data.license,
        name = data.name,
        charinfo = data.charinfo,
        money = data.money,
        job = data.job,
        inventory = data.inventory,
        metadata = data.metadata,
        position = data.position,
        skin = data.skin,
        is_dead = data.is_dead,
        cid = data.cid,
    }
end

function Offline.Save(citizenid, patch)
    if type(patch) ~= 'table' then return false end
    local data = Database.LoadCharacter(citizenid)
    if not data then return false end

    if patch.name ~= nil then data.name = patch.name end
    if patch.charinfo ~= nil then data.charinfo = patch.charinfo end
    if patch.money ~= nil then data.money = patch.money end
    if patch.job ~= nil then data.job = patch.job end
    if patch.inventory ~= nil then data.inventory = patch.inventory end
    if patch.metadata ~= nil then data.metadata = patch.metadata end
    if patch.position ~= nil then data.position = patch.position end
    if patch.skin ~= nil then data.skin = patch.skin end
    if patch.is_dead ~= nil then data.is_dead = patch.is_dead end
    if patch.cid ~= nil then data.cid = patch.cid end

    Database.SaveCharacter(data, true)
    return true
end

exports('GetOfflinePlayerByCitizenId', Offline.GetByCitizenId)
exports('SaveOfflinePlayer', Offline.Save)
