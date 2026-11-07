local core = exports['qs-core']

function QBCore.Functions.SpawnVehicle(source, model, coords, warp)
    return core:SpawnVehicle(source, model, coords, warp)
end

exports('SpawnVehicle', function(source, model, coords, warp)
    return QBCore.Functions.SpawnVehicle(source, model, coords, warp)
end)

local PLAYER_VEHICLES_VIEW = [[
    SELECT
        `id`,
        `license`,
        `citizenid`,
        `model` AS `vehicle`,
        NULL AS `hash`,
        `props` AS `mods`,
        `plate`,
        NULL AS `fakeplate`,
        `garage`,
        `fuel`,
        `engine`,
        `body`,
        `state`,
        0 AS `depotprice`,
        0 AS `drivingdistance`,
        NULL AS `status`,
        0 AS `balance`,
        0 AS `paymentamount`,
        0 AS `paymentsleft`,
        0 AS `financetime`
    FROM `vehicles`
]]

local function tableType(name)
    return MySQL.scalar.await(
        'SELECT `TABLE_TYPE` FROM information_schema.TABLES WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = ?',
        { name }
    )
end

local function ensurePlayerVehiclesView()
    if not tableType('vehicles') then
        print('^3[qb-core bridge]^7 table `vehicles` not found, import qs-core/sql/qscore.sql so player_vehicles can be linked to qs-core vehicles')
        return
    end
    if tableType('player_vehicles') == 'BASE TABLE' then
        local rows = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM `player_vehicles`')) or 0
        if rows > 0 then
            print('^3[qb-core bridge]^7 player_vehicles is a real table with data, so it was left untouched; scripts that read it will not see qs-core vehicles')
            return
        end
        MySQL.query.await('DROP TABLE `player_vehicles`')
    end
    MySQL.query.await('CREATE OR REPLACE VIEW `player_vehicles` AS ' .. PLAYER_VEHICLES_VIEW)
end

MySQL.ready(function()
    local ok, err = pcall(ensurePlayerVehiclesView)
    if not ok then
        print(('^1[qb-core bridge]^7 could not create the player_vehicles view: %s'):format(err))
    end
end)
