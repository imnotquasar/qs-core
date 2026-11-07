local core = exports['qs-core']

local garageIds = {}
local garageById = {}
for _, g in ipairs(Config.Garages) do
    garageIds[g.id] = true
    garageById[g.id] = g
end

local function nearGarage(src, id)
    local g = garageById[id]
    local ped = GetPlayerPed(src)
    if not g or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(g.coords.x, g.coords.y, g.coords.z)) <= Config.MarkerDistance
end

local function citizenOf(src)
    local player = core:GetPlayer(src)
    if not player then return nil end
    return player.citizenid or (player.PlayerData and player.PlayerData.citizenid)
end

local function trim(s) return s and s:match('^%s*(.-)%s*$') or s end

local function plateNear(src, plate, reach)
    local ped = GetPlayerPed(src)
    if ped == 0 or plate == '' then return false end
    local pos = GetEntityCoords(ped)
    for _, v in ipairs(GetAllVehicles()) do
        if DoesEntityExist(v) and trim(GetVehicleNumberPlateText(v)) == plate
            and #(pos - GetEntityCoords(v)) <= reach then
            return v
        end
    end
    return false
end

local function plateInWorld(plate)
    for _, v in ipairs(GetAllVehicles()) do
        if DoesEntityExist(v) and trim(GetVehicleNumberPlateText(v)) == plate then return true end
    end
    return false
end

core:RegisterCallback('qs-garage:list', function(src, garage)
    if not garageIds[garage] then return {} end
    local cid = citizenOf(src)
    if not cid then return {} end

    local rows = core:GetGarageVehicles(cid, garage) or {}
    for _, r in ipairs(core:GetCitizenVehicles(cid) or {}) do
        if not garageIds[r.garage] then rows[#rows + 1] = r end
    end
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = {
            plate = r.plate,
            model = r.model,
            state = r.state,
            fuel = r.fuel,
            engine = 1000.0,
            body = 1000.0,
            props = r.props,
        }
    end
    return out
end)

core:RegisterCallback('qs-garage:takeout', function(src, garage, plate)
    if not garageIds[garage] or not nearGarage(src, garage) then return { ok = false } end
    if not core:RateLimit(('garage-out:%d'):format(src), 1, 1200) then return { ok = false } end
    plate = trim(tostring(plate or ''))
    local cid = citizenOf(src)
    if not cid then return { ok = false } end

    local veh = core:GetVehicleByPlate(plate)
    if not veh or veh.citizenid ~= cid then return { ok = false, msg = 'not_yours' } end
    if veh.garage ~= garage and garageIds[veh.garage] then return { ok = false, msg = 'not_yours' } end
    if veh.state ~= 1 and plateInWorld(plate) then return { ok = false, msg = 'already_out' } end

    core:SetVehicleState(plate, 0)
    return {
        ok = true,
        model = veh.model,
        plate = veh.plate,
        fuel = veh.fuel,
        props = veh.props,
    }
end)

core:RegisterCallback('qs-garage:store', function(src, garage, plate, fuel, props)
    if not garageIds[garage] or not nearGarage(src, garage) then return { ok = false } end
    if not core:RateLimit(('garage-in:%d'):format(src), 1, 1200) then return { ok = false } end
    plate = trim(tostring(plate or ''))
    local stored = plateNear(src, plate, Config.MarkerDistance + 10.0)
    if not stored then return { ok = false } end
    if type(props) == 'table' and #json.encode(props) > 20000 then return { ok = false } end
    local cid = citizenOf(src)
    if not cid then return { ok = false } end

    local veh = core:GetVehicleByPlate(plate)
    if not veh or veh.citizenid ~= cid then return { ok = false, msg = 'not_yours' } end

    core:UpdateOwnedVehicle(plate, {
        garage = garage,
        state = 1,
        fuel = math.max(0, math.min(100, math.floor(tonumber(fuel) or 100))),
        engine = 1000.0,
        body = 1000.0,
        props = type(props) == 'table' and props or {},
    })
    if DoesEntityExist(stored) then DeleteEntity(stored) end
    return { ok = true }
end)
