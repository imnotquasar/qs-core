local core = exports['qs-core']

local catalogue = {}
for cat, list in pairs(Config.Vehicles) do
    for _, v in ipairs(list) do
        catalogue[v.model:lower()] = { price = v.price, label = v.label, category = cat }
    end
end

local function nearAny(src, dist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, loc in ipairs(Config.Locations) do
        if #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z)) < dist then return true end
    end
    return false
end

local CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
local function randomPlate()
    for _ = 1, 40 do
        local p = 'QS'
        for _ = 1, 5 do
            local i = math.random(#CHARS)
            p = p .. CHARS:sub(i, i)
        end
        if not core:PlateExists(p) then return p end
    end
    return nil
end

core:RegisterCallback('qs-vehicleshop:buy', function(src, model)
    model = tostring(model or ''):lower()
    local entry = catalogue[model]
    if not entry then return { ok = false, msg = 'invalid' } end
    if not core:RateLimit(('vshop:%d'):format(src), 1, 1500) then return { ok = false } end
    if not nearAny(src, Config.InteractDistance + 10.0) then return { ok = false, msg = 'far' } end

    local player = core:GetPlayer(src)
    if not player then return { ok = false } end
    local citizenid = player.citizenid or (player.PlayerData and player.PlayerData.citizenid)
    if not citizenid then return { ok = false } end

    local account
    for _, acc in ipairs(Config.PayAccounts) do
        if core:GetMoney(src, acc) >= entry.price then
            account = acc
            break
        end
    end
    if not account then return { ok = false, msg = 'money', price = entry.price } end

    local plate = randomPlate()
    if not plate then return { ok = false, msg = 'plate' } end

    if not core:RemoveMoney(src, account, entry.price, 'vehicleshop:' .. model) then
        return { ok = false, msg = 'money', price = entry.price }
    end

    core:CreateOwnedVehicle({
        citizenid = citizenid,
        license = GetPlayerIdentifierByType(src, 'license'),
        plate = plate,
        model = model,
        garage = Config.DefaultGarage,
        state = 0,
        fuel = 100,
        engine = 1000.0,
        body = 1000.0,
        props = {},
    })

    return { ok = true, plate = plate, model = model, account = account, price = entry.price }
end)
