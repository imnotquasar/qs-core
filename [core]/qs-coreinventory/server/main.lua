local core = exports['qs-core']
local usableItems = {}

local SLOTS = Config.Slots
local MAXW = Config.MaxWeight

local KIND_SQL = {
    trunk    = { tbl = 'trunk_inventories',    col = 'plate' },
    glovebox = { tbl = 'glovebox_inventories', col = 'plate' },
    stash    = { tbl = 'stash_inventories',    col = 'stash' },
}
local secCache = {}
local open = {}
local stashDefs = {}

local function catalogue()
    return core:GetItems() or {}
end

local function isEmptyInfo(info)
    return info == nil or (type(info) == 'table' and next(info) == nil)
end

local function deepEquals(a, b)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end
    for k, v in pairs(a) do
        if not deepEquals(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function sameInfo(a, b)
    if isEmptyInfo(a) and isEmptyInfo(b) then return true end
    if isEmptyInfo(a) or isEmptyInfo(b) then return false end
    return deepEquals(a, b)
end

local function cloneInfo(info)
    if isEmptyInfo(info) then return nil end
    local out = {}
    for k, v in pairs(info) do
        out[k] = type(v) == 'table' and cloneInfo(v) or v
    end
    return out
end

local function normalize(list, n)
    local out = {}
    for i = 1, n do
        local e = list and list[i]
        if type(e) == 'table' and e.name and (tonumber(e.count) or 0) > 0 then
            out[i] = {
                name = e.name,
                count = math.floor(e.count),
                info = (type(e.info) == 'table' and next(e.info) ~= nil) and e.info or nil,
            }
        else
            out[i] = false
        end
    end
    return out
end

local function maxStack(def)
    if not def then return 1 end
    if def.stack then return def.stack end
    if def.weapon or def.unique then return 1 end
    return Config.DefaultStack
end

local function weightOf(list, items, n)
    local total = 0
    for i = 1, n do
        local e = list[i]
        if e then
            local def = items[e.name]
            if def then total = total + (def.weight or 0) * e.count end
        end
    end
    return total
end

local function totalCount(list, name, n)
    local c = 0
    for i = 1, n do
        local e = list[i]
        if e and e.name == name then c = c + e.count end
    end
    return c
end

local function capacityFor(list, name, def, n, info)
    local ms = maxStack(def)
    local cap = 0
    for i = 1, n do
        local e = list[i]
        if not e then
            cap = cap + ms
        elseif e.name == name and sameInfo(e.info, info) then
            cap = cap + math.max(0, ms - e.count)
        end
    end
    return cap
end

local function buildView(list, n, items)
    local view = {}
    for i = 1, n do
        local e = list[i]
        local def = e and items[e.name]
        if e and def then
            view[i] = {
                slot = i,
                name = e.name,
                label = def.label,
                count = e.count,
                weight = def.weight or 0,
                useable = def.useable or false,
                description = def.description,
                image = def.image,
                max = maxStack(def),
                info = e.info,
            }
        else
            view[i] = false
        end
    end
    return view
end

local function playerList(src) return normalize(core:GetInventory(src) or {}, SLOTS) end

local function itembox(src, name, count, kind)
    local def = catalogue()[name]
    if not def then return end
    TriggerClientEvent('qs-inv:client:itembox', src, {
        name = name,
        label = def.label or name,
        image = def.image,
        count = count,
        type = kind,
    })
end

local function ensureSecondary(kind, id, slots)
    local key = kind .. ':' .. id
    if secCache[key] == nil then
        local sql = KIND_SQL[kind]
        local raw = sql and MySQL.scalar.await(('SELECT items FROM %s WHERE %s = ?'):format(sql.tbl, sql.col), { id })
        local ok, decoded = pcall(function() return raw and json.decode(raw) end)
        secCache[key] = (ok and decoded) and normalize(decoded, slots) or normalize({}, slots)
    end
    return normalize(secCache[key], slots)
end

local function containerGet(src, container)
    if container == 'secondary' then
        local o = open[src]
        if not o then return nil end
        return ensureSecondary(o.kind, o.id, o.slots), o.slots, o.maxWeight, o
    end
    return playerList(src), SLOTS, MAXW, nil
end

local function containerSave(src, container, list)
    if container == 'secondary' then
        local o = open[src]
        if not o then return end
        secCache[o.kind .. ':' .. o.id] = list
        local sql = KIND_SQL[o.kind]
        if sql then
            MySQL.query(
                ('INSERT INTO %s (%s, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = VALUES(items)'):format(sql.tbl, sql.col),
                { o.id, json.encode(list) }
            )
        end
    else
        core:SetInventory(src, list)
    end
end

local function refresh(src)
    local items = catalogue()
    local pList = playerList(src)
    local data = {
        slots = SLOTS,
        columns = Config.Columns,
        items = buildView(pList, SLOTS, items),
        weight = weightOf(pList, items, SLOTS),
        maxWeight = MAXW,
    }
    local o = open[src]
    if o then
        local sList = ensureSecondary(o.kind, o.id, o.slots)
        data.secondary = {
            slots = o.slots,
            columns = o.columns or 5,
            items = buildView(sList, o.slots, items),
            weight = weightOf(sList, items, o.slots),
            maxWeight = o.maxWeight,
            label = o.label,
            kind = o.kind,
        }
    end
    TriggerClientEvent('qs-inv:client:set', src, data)
end

function AddItem(src, name, count, slot, info)
    count = math.floor(tonumber(count) or 0)
    local items = catalogue()
    local def = items[name]
    if not def or count <= 0 then return false end
    info = cloneInfo(info)

    local list = playerList(src)
    if weightOf(list, items, SLOTS) + (def.weight or 0) * count > MAXW then
        TriggerClientEvent('qs:client:notify', src, T('too_heavy', def.label), 'error')
        return false
    end
    if capacityFor(list, name, def, SLOTS, info) < count then
        TriggerClientEvent('qs:client:notify', src, T('inv_full'), 'error')
        return false
    end

    local ms = maxStack(def)
    local remaining = count

    slot = tonumber(slot)
    if slot and slot >= 1 and slot <= SLOTS then
        local e = list[slot]
        if not e then
            local add = math.min(ms, remaining)
            list[slot] = { name = name, count = add, info = info }
            remaining = remaining - add
        elseif e.name == name and sameInfo(e.info, info) then
            local add = math.min(math.max(0, ms - e.count), remaining)
            e.count = e.count + add
            remaining = remaining - add
        end
    end

    for i = 1, SLOTS do
        if remaining <= 0 then break end
        local e = list[i]
        if e and e.name == name and sameInfo(e.info, info) then
            local room = ms - e.count
            if room > 0 then
                local add = math.min(room, remaining)
                e.count = e.count + add
                remaining = remaining - add
            end
        end
    end

    for i = 1, SLOTS do
        if remaining <= 0 then break end
        if not list[i] then
            local add = math.min(ms, remaining)
            list[i] = { name = name, count = add, info = info }
            remaining = remaining - add
        end
    end

    core:SetInventory(src, list)
    refresh(src)
    itembox(src, name, count, 'add')
    return true
end

function RemoveItem(src, name, count, slot)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return false end

    local list = playerList(src)

    slot = tonumber(slot)
    if slot and slot >= 1 and slot <= SLOTS then
        local e = list[slot]
        if not e or e.name ~= name or e.count < count then return false end
        e.count = e.count - count
        if e.count <= 0 then list[slot] = false end
        core:SetInventory(src, list)
        refresh(src)
        itembox(src, name, count, 'remove')
        return true
    end

    if totalCount(list, name, SLOTS) < count then return false end

    local remaining = count
    for i = SLOTS, 1, -1 do
        if remaining <= 0 then break end
        local e = list[i]
        if e and e.name == name then
            local take = math.min(e.count, remaining)
            e.count = e.count - take
            remaining = remaining - take
            if e.count <= 0 then list[i] = false end
        end
    end

    core:SetInventory(src, list)
    refresh(src)
    itembox(src, name, count, 'remove')
    return true
end

function GetItemCount(src, name)
    return totalCount(playerList(src), name, SLOTS)
end

function HasItem(src, name, count)
    return GetItemCount(src, name) >= (count or 1)
end

function RegisterUsableItem(name, handler)
    usableItems[name] = handler
end

function CanCarryItem(src, name, count, info)
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    local items = catalogue()
    local def = items[name]
    if not def then return false end

    local list = playerList(src)
    if weightOf(list, items, SLOTS) + (def.weight or 0) * count > MAXW then return false end
    return capacityFor(list, name, def, SLOTS, cloneInfo(info)) >= count
end

function GetSlotView(src)
    return buildView(playerList(src), SLOTS, catalogue())
end

function GetItemBySlot(src, slot)
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > SLOTS then return nil end
    local view = GetSlotView(src)
    local it = view[slot]
    if not it or type(it) ~= 'table' then return nil end
    it.slot = slot
    return it
end

function SetItemInfo(src, slot, info)
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > SLOTS then return false end
    local list = playerList(src)
    local e = list[slot]
    if not e then return false end
    e.info = cloneInfo(info)
    core:SetInventory(src, list)
    refresh(src)
    return true
end

exports('AddItem', AddItem)
exports('RemoveItem', RemoveItem)
exports('GetItemCount', GetItemCount)
exports('HasItem', HasItem)
exports('CanCarryItem', CanCarryItem)
exports('GetSlotView', GetSlotView)
exports('GetItemBySlot', GetItemBySlot)
exports('SetItemInfo', SetItemInfo)
exports('GetInventory', function(src) return core:GetInventory(src) end)
exports('RegisterUsableItem', RegisterUsableItem)
exports('createQuest', function(...) return true end)

local function slotMove(items, sList, sN, sMaxW, from, dList, dN, dMaxW, to)
    local a = sList[from]
    if not a then return end
    if to < 1 or to > dN then return end
    local same = sList == dList
    local def = items[a.name]
    local ms = maxStack(def)
    local w = def and def.weight or 0
    local b = dList[to]

    local function fits(n) return same or (weightOf(dList, items, dN) + w * n <= dMaxW) end

    if not b then
        local mv = a.count
        if not same and w > 0 then
            local free = math.floor((dMaxW - weightOf(dList, items, dN)) / w)
            mv = math.min(mv, math.max(free, 0))
        end
        mv = math.min(mv, ms)
        if mv <= 0 then return end
        dList[to] = { name = a.name, count = mv, info = cloneInfo(a.info) }
        a.count = a.count - mv
        if a.count <= 0 then sList[from] = false end
    elseif b.name == a.name and sameInfo(b.info, a.info) then
        local room = ms - b.count
        if room > 0 then
            local mv = math.min(room, a.count)
            if not same and w > 0 then
                mv = math.min(mv, math.max(math.floor((dMaxW - weightOf(dList, items, dN)) / w), 0))
            end
            if mv > 0 then
                b.count = b.count + mv
                a.count = a.count - mv
                if a.count <= 0 then sList[from] = false end
            end
        else
            sList[from], dList[to] = b, a
        end
    else

        if not same then
            local defb = items[b.name]
            local wb = (defb and defb.weight or 0) * b.count
            local wa = w * a.count
            if weightOf(dList, items, dN) - wb + wa > dMaxW then return end
            if weightOf(sList, items, sN) - wa + wb > sMaxW then return end
        end
        sList[from], dList[to] = b, a
    end
    _ = fits
end

local function moveItem(src, fromC, from, toC, to)
    local items = catalogue()
    local sList, sN, sMaxW = containerGet(src, fromC)
    if not sList then return end
    if from < 1 or from > sN then return end

    local dList, dN, dMaxW
    if toC == fromC then
        dList, dN, dMaxW = sList, sN, sMaxW
    else
        dList, dN, dMaxW = containerGet(src, toC)
        if not dList then return end
    end

    slotMove(items, sList, sN, sMaxW, from, dList, dN, dMaxW, to)

    containerSave(src, fromC, sList)
    if toC ~= fromC then containerSave(src, toC, dList) end
    refresh(src)
end

RegisterNetEvent('qs-inv:server:move', function(fromC, from, toC, to)
    moveItem(source, fromC == 'secondary' and 'secondary' or 'player', tonumber(from) or 0,
        toC == 'secondary' and 'secondary' or 'player', tonumber(to) or 0)
end)

RegisterNetEvent('qs-inv:server:split', function(slot, count, container)
    local src = source
    slot = tonumber(slot) or 0
    container = container == 'secondary' and 'secondary' or 'player'
    if container == 'secondary' and not open[src] then return end

    local list, nSlots = containerGet(src, container)
    if not list then return end

    local a = list[slot]
    if not a or a.count < 2 then return end

    local n = tonumber(count)
    n = n and math.floor(n) or math.floor(a.count / 2)
    if n > a.count - 1 then n = a.count - 1 end
    if n < 1 then return end

    local empty
    for i = 1, (nSlots or SLOTS) do
        if not list[i] then empty = i break end
    end
    if not empty then
        TriggerClientEvent('qs:client:notify', src, T('inv_full'), 'error')
        return
    end

    list[empty] = { name = a.name, count = n, info = cloneInfo(a.info) }
    a.count = a.count - n
    containerSave(src, container, list)
    refresh(src)
end)

RegisterNetEvent('qs-inv:server:take', function(slot, count)
    local src = source
    if not open[src] then return end
    slot = tonumber(slot) or 0
    count = tonumber(count)

    local secList = containerGet(src, 'secondary')
    local e = secList and secList[slot]
    if not e then return end

    if count and count >= 1 and count < e.count then
        if not AddItem(src, e.name, count, nil, e.info) then
            TriggerClientEvent('qs:client:notify', src, T('inv_full'), 'error')
            return
        end
        e.count = e.count - count
        containerSave(src, 'secondary', secList)
        refresh(src)
        return
    end

    local pList = playerList(src)
    local free
    for i = 1, SLOTS do
        if not pList[i] then free = i; break end
    end
    if not free then
        TriggerClientEvent('qs:client:notify', src, T('inv_full'), 'error')
        return
    end
    moveItem(src, 'secondary', slot, 'player', free)
end)

local busyUntil = {}

function SetBusy(src, ms)
    src = tonumber(src)
    if not src then return end
    busyUntil[src] = GetGameTimer() + math.max(0, tonumber(ms) or 0)
end
exports('SetBusy', SetBusy)

exports('IsBusy', function(src)
    src = tonumber(src)
    return src ~= nil and (busyUntil[src] or 0) > GetGameTimer()
end)

RegisterNetEvent('qs-inv:server:use', function(slot)
    local src = source
    if not core:RateLimit(('inv-use:%d'):format(src), 10, 3000) then return end
    if (busyUntil[src] or 0) > GetGameTimer() then return end
    slot = tonumber(slot) or 0
    local list = playerList(src)
    local e = list[slot]
    if not e then return end

    local def = core:GetItem(e.name)
    if not def or not def.useable then return end
    if def.weapon then
        TriggerClientEvent('qs-inv:client:equip', src, def.weapon, def.ammo or 0)
        return
    end
    local handler = usableItems[e.name]
    if handler then handler(src, slot, e.info) end

    TriggerEvent('qs-inventory:usedItem', src, e.name, slot, e.info)
end)

RegisterNetEvent('qs-inv:server:drop', function(container, slot, count)
    local src = source
    container = container == 'secondary' and 'secondary' or 'player'
    slot = tonumber(slot) or 0
    count = math.floor(tonumber(count) or 0)

    local list = containerGet(src, container)
    if not list then return end
    local e = list[slot]
    if not e or count <= 0 then return end

    local take = math.min(count, e.count)
    e.count = e.count - take
    if e.count <= 0 then list[slot] = false end
    containerSave(src, container, list)
    refresh(src)
    if container == 'player' then itembox(src, e.name, take, 'remove') end

    local def = core:GetItem(e.name)
    TriggerClientEvent('qs:client:notify', src, T('dropped', take, def and def.label or e.name), 'info')
end)

RegisterNetEvent('qs-inv:server:give', function(target, slot, count)
    local src = source
    target = tonumber(target)
    slot = tonumber(slot) or 0
    count = math.floor(tonumber(count) or 0)
    if not target or target == src or count <= 0 then return end

    local pedA, pedB = GetPlayerPed(src), GetPlayerPed(target)
    if pedA == 0 or pedB == 0 then return end
    if #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) > 5.0 then
        TriggerClientEvent('qs:client:notify', src, T('player_far'), 'error')
        return
    end

    local list = playerList(src)
    local e = list[slot]
    if not e then return end
    count = math.min(count, e.count)
    local name = e.name

    if not AddItem(target, name, count, nil, e.info) then
        TriggerClientEvent('qs:client:notify', src, T('cant_carry_that'), 'error')
        return
    end

    e.count = e.count - count
    if e.count <= 0 then list[slot] = false end
    core:SetInventory(src, list)
    refresh(src)
    itembox(src, name, count, 'remove')

    local def = core:GetItem(name)
    local label = def and def.label or name
    TriggerClientEvent('qs:client:notify', src, T('gave', count, label), 'success')
    TriggerClientEvent('qs:client:notify', target, T('received', count, label), 'success')
end)

local function openSecondary(src, kind, id, slots, columns, maxWeight, label)
    id = tostring(id or ''):gsub('%s+$', '')
    if id == '' then return end
    open[src] = { kind = kind, id = id, slots = slots, columns = columns, maxWeight = maxWeight, label = label }
    ensureSecondary(kind, id, slots)
    refresh(src)
end

RegisterNetEvent('qs-inv:server:openTrunk', function(plate)
    openSecondary(source, 'trunk', plate, Config.TrunkSlots, Config.TrunkColumns, Config.TrunkMaxWeight, T('trunk'))
end)

RegisterNetEvent('qs-inv:server:openGlovebox', function(plate)
    openSecondary(source, 'glovebox', plate, Config.GloveboxSlots, Config.GloveboxColumns, Config.GloveboxMaxWeight, T('glovebox'))
end)

RegisterNetEvent('qs-inv:server:openStash', function(id, opts)
    local src = source
    id = tostring(id or '')
    if id == '' then return end
    local def = stashDefs[id]
    if not def then

        if type(opts) == 'table' and (opts.slots or opts.maxWeight) then
            def = {
                label = opts.label or 'Stash',
                slots = math.floor(tonumber(opts.slots) or 50),
                maxWeight = math.floor(tonumber(opts.maxWeight) or 100000),
                columns = math.floor(tonumber(opts.columns) or 5),
            }
            stashDefs[id] = def
        else
            return
        end
    end
    openSecondary(src, 'stash', id, def.slots, def.columns or 5, def.maxWeight, def.label)
end)

RegisterNetEvent('qs-inv:server:closeSecondary', function()
    open[source] = nil
end)

function RegisterStash(id, label, slots, maxWeight, columns)
    if not id then return false end
    stashDefs[tostring(id)] = {
        label = label or 'Stash',
        slots = math.floor(tonumber(slots) or 50),
        maxWeight = math.floor(tonumber(maxWeight) or 100000),
        columns = math.floor(tonumber(columns) or 5),
    }
    return true
end
exports('RegisterStash', RegisterStash)

CreateThread(function()
    for _, s in ipairs(Config.Stashes or {}) do
        if s.id then RegisterStash(s.id, s.label, s.slots, s.maxWeight, s.columns) end
    end
end)

RegisterNetEvent('qs-inv:server:request', function()
    refresh(source)
end)

AddEventHandler('playerDropped', function()
    open[source] = nil
    busyUntil[source] = nil
end)

AddEventHandler('qs:server:characterLoaded', function(src, data)
    if data and data.isNew then
        for _, entry in ipairs(Config.StartingItems) do
            AddItem(src, entry.name, entry.count)
        end
    end
    refresh(src)
end)

RegisterUsableItem('bandage', function(src)
    RemoveItem(src, 'bandage', 1)
    TriggerClientEvent('qs-inv:client:heal', src, 20)
    TriggerClientEvent('qs:client:notify', src, T('patched'), 'success')
end)

RegisterUsableItem('phone', function(src)
    TriggerClientEvent('qs:client:notify', src, T('phone_ph'), 'primary')
end)

CreateThread(function()
    Wait(200)
    TriggerEvent('qs-inventory:registerUsables')
end)
