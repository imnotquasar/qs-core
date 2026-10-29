local hashCat = {}
for _, w in pairs(WeaponsConfig.Weapons) do
    hashCat[joaat(w.weapon)] = w.cat
end

RegisterNetEvent('qs-coreweapons:client:useAmmo', function(item, cat, amount)
    local ped = PlayerPedId()
    local target

    local selected = GetSelectedPedWeapon(ped)
    if hashCat[selected] == cat then
        target = selected
    else
        for _, w in pairs(WeaponsConfig.Weapons) do
            if w.cat == cat then
                local h = joaat(w.weapon)
                if HasPedGotWeapon(ped, h, false) then
                    target = h
                    break
                end
            end
        end
    end

    if not target then
        exports['qs-core']:Notify(T('no_weapon'), 'error', 3000)
        return
    end

    AddAmmoToPed(ped, target, amount)
    TriggerServerEvent('qs-coreweapons:server:consumeAmmo', item)
    exports['qs-core']:Notify(T('loaded', amount), 'success', 2500)
end)

local hashItem = {}
for name, w in pairs(WeaponsConfig.Weapons) do
    hashItem[joaat(w.weapon)] = name
end

local fromInventory = {}
local throwAmmo = {}

local function itemCounts(items)
    local counts = {}
    for _, it in pairs(items or {}) do
        if type(it) == 'table' and it.name then
            counts[it.name] = (counts[it.name] or 0) + (it.count or 0)
        end
    end
    return counts
end

local function syncPed(counts)
    local ped = PlayerPedId()
    for hash in pairs(fromInventory) do
        local name = hashItem[hash]
        local count = counts[name] or 0
        if count <= 0 then
            if HasPedGotWeapon(ped, hash, false) then RemoveWeaponFromPed(ped, hash) end
            fromInventory[hash] = nil
            throwAmmo[hash] = nil
        elseif hashCat[hash] == 'throwable' and HasPedGotWeapon(ped, hash, false) then
            SetPedAmmo(ped, hash, count)
            throwAmmo[hash] = count
        end
    end
end

RegisterNetEvent('qs-inv:client:set', function(data)
    if data then syncPed(itemCounts(data.items)) end
end)

RegisterNetEvent('qs-inv:client:equip', function(weapon)
    local hash = joaat(weapon)
    local name = hashItem[hash]
    if not name then return end
    fromInventory[hash] = true
    if hashCat[hash] ~= 'throwable' then return end
    SetTimeout(100, function()
        local ped = PlayerPedId()
        if not HasPedGotWeapon(ped, hash, false) then return end
        local count = exports['qs-core']:GetItemCount(name)
        SetPedAmmo(ped, hash, count)
        throwAmmo[hash] = count
    end)
end)

CreateThread(function()
    while true do
        local hash = GetSelectedPedWeapon(PlayerPedId())
        if hashCat[hash] == 'throwable' and throwAmmo[hash] then
            local ammo = GetAmmoInPedWeapon(PlayerPedId(), hash)
            if ammo < throwAmmo[hash] then
                TriggerServerEvent('qs-coreweapons:server:thrown', hashItem[hash], throwAmmo[hash] - ammo)
                throwAmmo[hash] = ammo
            end
            Wait(150)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        SetPedDropsWeaponsWhenDead(PlayerPedId(), false)
        for _, ped in ipairs(GetGamePool('CPed')) do
            if not IsPedAPlayer(ped) then
                SetPedDropsWeaponsWhenDead(ped, false)
                SetPedMoney(ped, 0)
            end
        end
    end
end)

local weaponPickups = {}
for _, w in pairs(WeaponsConfig.Weapons) do
    local pickup = GetPickupHashFromWeapon(joaat(w.weapon))
    if pickup ~= 0 then weaponPickups[#weaponPickups + 1] = pickup end
end

local function blockWeaponPickups()
    local pid = PlayerId()
    for i = 1, #weaponPickups do ToggleUsePickupsForPlayer(pid, weaponPickups[i], false) end
end

AddEventHandler('qs:client:onPlayerLoaded', blockWeaponPickups)
AddEventHandler('qs:client:onRevive', blockWeaponPickups)
CreateThread(function()
    Wait(1000)
    blockWeaponPickups()
end)

AddEventHandler('qs:client:onDeath', function()
    SetTimeout(3000, function()
        for i = 1, #weaponPickups do RemoveAllPickupsOfType(weaponPickups[i]) end
    end)
end)

CreateThread(function()
    local since = nil
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, true) then
            local now = GetGameTimer()
            since = since or now
            if now - since < 5000 then
                DisablePlayerVehicleRewards(PlayerId())
                Wait(0)
            else
                Wait(250)
            end
        else
            since = nil
            Wait(250)
        end
    end
end)
