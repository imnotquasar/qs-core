Vehicles = {}

local function decodeRow(row)
    row.props = row.props and json.decode(row.props) or {}
    row.state = tonumber(row.state) or 1
    row.fuel = tonumber(row.fuel) or 100
    return row
end

function Vehicles.GetByCitizen(citizenid)
    local rows = MySQL.query.await('SELECT * FROM `vehicles` WHERE `citizenid` = ?', { citizenid }) or {}
    for _, r in ipairs(rows) do decodeRow(r) end
    return rows
end

function Vehicles.GetByGarage(citizenid, garage)
    local rows = MySQL.query.await('SELECT * FROM `vehicles` WHERE `citizenid` = ? AND `garage` = ?', { citizenid, garage }) or {}
    for _, r in ipairs(rows) do decodeRow(r) end
    return rows
end

function Vehicles.GetByPlate(plate)
    local row = MySQL.single.await('SELECT * FROM `vehicles` WHERE `plate` = ?', { plate })
    return row and decodeRow(row) or nil
end

function Vehicles.PlateExists(plate)
    return MySQL.scalar.await('SELECT 1 FROM `vehicles` WHERE `plate` = ?', { plate }) ~= nil
end

function Vehicles.Create(data)
    return MySQL.insert.await(
        'INSERT INTO `vehicles` (`citizenid`, `license`, `plate`, `model`, `garage`, `state`, `fuel`, `engine`, `body`, `props`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            data.citizenid, data.license, data.plate, data.model,
            data.garage or 'legion', data.state == nil and 1 or data.state,
            data.fuel or 100, data.engine or 1000.0, data.body or 1000.0,
            json.encode(data.props or {}),
        }
    )
end

function Vehicles.Update(plate, data)
    MySQL.update.await(
        'UPDATE `vehicles` SET `garage` = ?, `state` = ?, `fuel` = ?, `engine` = ?, `body` = ?, `props` = ? WHERE `plate` = ?',
        {
            data.garage, data.state, data.fuel or 100, data.engine or 1000.0,
            data.body or 1000.0, json.encode(data.props or {}), plate,
        }
    )
end

function Vehicles.SetState(plate, state, garage)
    if garage then
        MySQL.update.await('UPDATE `vehicles` SET `state` = ?, `garage` = ? WHERE `plate` = ?', { state, garage, plate })
    else
        MySQL.update.await('UPDATE `vehicles` SET `state` = ? WHERE `plate` = ?', { state, plate })
    end
end

function Vehicles.Spawn(source, model, coords, warp)
    local ped = GetPlayerPed(source)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then
        local c = GetEntityCoords(ped)
        coords = { x = c.x, y = c.y, z = c.z, w = GetEntityHeading(ped) }
    end
    local heading = type(coords) == 'vector4' and coords.w or (coords.w or 0.0)

    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)
    local timeout = GetGameTimer() + 5000
    while not DoesEntityExist(veh) and GetGameTimer() < timeout do Wait(0) end
    if not DoesEntityExist(veh) then return nil end

    if warp and ped ~= 0 then
        local wt = GetGameTimer() + 5000
        while GetVehiclePedIsIn(ped, false) ~= veh and GetGameTimer() < wt do
            TaskWarpPedIntoVehicle(ped, veh, -1)
            Wait(0)
        end
    end
    return NetworkGetNetworkIdFromEntity(veh)
end

function Vehicles.GetQBShape(citizenid)
    local rows = Vehicles.GetByCitizen(citizenid)
    local out = {}
    for _, row in ipairs(rows) do
        out[#out + 1] = {
            citizenid = row.citizenid,
            license = row.license,
            vehicle = row.model,
            hash = row.model and joaat(row.model) or nil,
            mods = row.props,
            plate = row.plate,
            garage = row.garage,
            fuel = row.fuel,
            engine = row.engine,
            body = row.body,
            state = row.state,
        }
    end
    return out
end

exports('GetOwnedVehicles', Vehicles.GetByCitizen)
exports('GetGarageVehicles', Vehicles.GetByGarage)
exports('GetVehicleByPlate', Vehicles.GetByPlate)
exports('PlateExists', Vehicles.PlateExists)
exports('CreateOwnedVehicle', Vehicles.Create)
exports('UpdateOwnedVehicle', Vehicles.Update)
exports('SetVehicleState', Vehicles.SetState)
exports('SpawnVehicle', Vehicles.Spawn)
exports('GetPlayerVehiclesQBShape', Vehicles.GetQBShape)
