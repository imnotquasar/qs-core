local function ensureVehicleCatalog()
    local deadline = GetGameTimer() + 30000
    while not exports['qs-core']:IsDatabaseReady() and GetGameTimer() < deadline do Wait(100) end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `vehicles` (
            `name`     VARCHAR(60) NOT NULL,
            `model`    VARCHAR(60) NOT NULL,
            `price`    INT         NOT NULL,
            `category` VARCHAR(60) DEFAULT NULL,
            PRIMARY KEY (`model`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local hasColumns = (tonumber(MySQL.scalar.await([[
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'vehicles' AND COLUMN_NAME IN ('name', 'price', 'category')
    ]])) or 0) == 3
    if not hasColumns then
        print('^3[es_extended bridge]^7 The vehicles table does not have the ESX columns, the vehicle catalog was not added')
        return
    end
    if (tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM `vehicles`')) or 0) > 0 then return end

    local catalog = BridgeVehicleCatalog
    for first = 1, #catalog, 100 do
        local rows, params = {}, {}
        for i = first, math.min(first + 99, #catalog) do
            rows[#rows + 1] = '(?, ?, ?, ?)'
            local vehicle = catalog[i]
            params[#params + 1] = vehicle[1]
            params[#params + 1] = vehicle[2]
            params[#params + 1] = vehicle[3]
            params[#params + 1] = vehicle[4]
        end
        MySQL.query.await('INSERT IGNORE INTO `vehicles` (`name`, `model`, `price`, `category`) VALUES ' .. table.concat(rows, ', '), params)
    end
end

MySQL.ready(function()
    ensureVehicleCatalog()
end)

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `owned_vehicles` (
            `owner`    VARCHAR(60) DEFAULT NULL,
            `plate`    VARCHAR(12) NOT NULL,
            `vehicle`  LONGTEXT DEFAULT NULL,
            `type`     VARCHAR(20) NOT NULL DEFAULT 'car',
            `job`      VARCHAR(20) DEFAULT NULL,
            `stored`   TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
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
