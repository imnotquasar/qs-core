local core = exports['qs-core']

local garageIds = {}
for _, g in ipairs(Config.Garages) do garageIds[g.id] = true end

local function citizenOf(src)
    local player = core:GetPlayer(src)
    if not player then return nil end
    return player.citizenid or (player.PlayerData and player.PlayerData.citizenid)
end

local function trim(s) return s and (s:gsub('%s+$', '')) or s end

core:RegisterCallback('qs-garage:list', function(src, garage)
    if not garageIds[garage] then return {} end
    local cid = citizenOf(src)
    if not cid then return {} end

    local rows = core:GetGarageVehicles(cid, garage) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = {
            plate = r.plate,
            model = r.model,
            state = r.state,
            fuel = r.fuel,
            engine = r.engine,
            body = r.body,
            props = r.props,
        }
    end
    return out
end)

core:RegisterCallback('qs-garage:takeout', function(src, garage, plate)
    if not garageIds[garage] then return { ok = false } end
    if not core:RateLimit(('garage-out:%d'):format(src), 1, 1200) then return { ok = false } end
    plate = trim(tostring(plate or ''))
    local cid = citizenOf(src)
    if not cid then return { ok = false } end

    local veh = core:GetVehicleByPlate(plate)
    if not veh or veh.citizenid ~= cid or veh.garage ~= garage then return { ok = false, msg = 'not_yours' } end

    core:SetVehicleState(plate, 0)
    return {
        ok = true,
        model = veh.model,
        plate = veh.plate,
        fuel = veh.fuel,
        engine = veh.engine,
        body = veh.body,
        props = veh.props,
    }
end)

core:RegisterCallback('qs-garage:store', function(src, garage, plate, fuel, engine, body, props)
    if not garageIds[garage] then return { ok = false } end
    if not core:RateLimit(('garage-in:%d'):format(src), 1, 1200) then return { ok = false } end
    plate = trim(tostring(plate or ''))
    local cid = citizenOf(src)
    if not cid then return { ok = false } end

    local veh = core:GetVehicleByPlate(plate)
    if not veh or veh.citizenid ~= cid then return { ok = false, msg = 'not_yours' } end

    core:UpdateOwnedVehicle(plate, {
        garage = garage,
        state = 1,
        fuel = math.max(0, math.min(100, math.floor(tonumber(fuel) or 100))),
        engine = tonumber(engine) or 1000.0,
        body = tonumber(body) or 1000.0,
        props = type(props) == 'table' and props or {},
    })
    return { ok = true }
end)
