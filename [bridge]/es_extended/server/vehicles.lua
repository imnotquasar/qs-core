local OWNED_VEHICLES_VIEW = [[
    SELECT
        `citizenid` AS `owner`,
        `plate`,
        `props` AS `vehicle`,
        'car' AS `type`,
        NULL AS `job`,
        `state` AS `stored`,
        `garage` AS `parking`,
        NULL AS `pound`
    FROM `vehicles`
]]

local function tableType(name)
    return MySQL.scalar.await(
        'SELECT `TABLE_TYPE` FROM information_schema.TABLES WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = ?',
        { name }
    )
end

local function ensureOwnedVehiclesView()
    if not tableType('vehicles') then
        print('^3[es_extended bridge]^7 table `vehicles` not found, import qs-core/sql/qscore.sql so owned_vehicles can be linked to qs-core vehicles')
        return
    end
    if tableType('owned_vehicles') == 'BASE TABLE' then
        local rows = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM `owned_vehicles`')) or 0
        if rows > 0 then
            print('^3[es_extended bridge]^7 owned_vehicles is a real table with data, so it was left untouched; scripts that read it will not see qs-core vehicles')
            return
        end
        MySQL.query.await('DROP TABLE `owned_vehicles`')
    end
    MySQL.query.await('CREATE OR REPLACE VIEW `owned_vehicles` AS ' .. OWNED_VEHICLES_VIEW)
end

MySQL.ready(function()
    local ok, err = pcall(ensureOwnedVehiclesView)
    if not ok then
        print(('^1[es_extended bridge]^7 could not create the owned_vehicles view: %s'):format(err))
    end
end)

function ESX.GetVehicleType(modelName, _player, cb)
    local t = 'automobile'
    if type(modelName) == 'string' then
        local m = modelName:lower()
        if m:find('bike') or m:find('bmx') or m:find('scooter') then t = 'bike'
        elseif m:find('heli') or m:find('drone') then t = 'heli'
        elseif m:find('plane') or m:find('jet') or m:find('luxor') or m:find('shamal') then t = 'plane'
        elseif m:find('boat') or m:find('dinghy') or m:find('seashark') or m:find('marquis') then t = 'boat'
        elseif m:find('trailer') then t = 'trailer'
        end
    end
    if cb then cb(t) end
    return t
end

ESX.OneSync = ESX.OneSync or {}

function ESX.OneSync.SpawnVehicle(model, coords, heading, properties, cb)
    model = type(model) == 'string' and joaat(model) or model
    coords = coords or vector3(0.0, 0.0, 0.0)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading or 0.0, true, true)
    local timeout = GetGameTimer() + 5000
    while not DoesEntityExist(veh) and GetGameTimer() < timeout do Wait(0) end
    if not DoesEntityExist(veh) then
        if cb then cb(nil) end
        return nil
    end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if properties then
        Entity(veh).state:set('VehicleProperties', properties, true)
    end
    if cb then cb(netId) end
    return netId
end

function ESX.OneSync.DeleteVehicle(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh and DoesEntityExist(veh) then DeleteEntity(veh) end
end

exports('SpawnVehicle', function(model, coords, heading, properties, cb)
    return ESX.OneSync.SpawnVehicle(model, coords, heading, properties, cb)
end)
