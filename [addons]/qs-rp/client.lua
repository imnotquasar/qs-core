local function rawArg(rawCommand)
    return (tostring(rawCommand or ''):gsub('^%s*%S+%s*', ''):gsub('^%s*(.-)%s*$', '%1'))
end

local function reg(name, event)
    RegisterCommand(name, function(_, _, raw)
        TriggerServerEvent(event, rawArg(raw))
    end, false)
end

reg('me', 'qs-rp:me')
reg('do', 'qs-rp:do')
reg('b', 'qs-rp:b')
reg('ooc', 'qs-rp:ooc')
reg('try', 'qs-rp:try')
reg('ame', 'qs-rp:ame')

RegisterCommand('pm', function(_, args, _)
    local id = table.remove(args, 1)
    local msg = table.concat(args, ' ')
    if not id or msg == '' then return end
    TriggerServerEvent('qs-rp:pm', id, msg)
end, false)

CreateThread(function()
    Wait(800)
    local function sug(name, help, params)
        TriggerEvent('chat:addSuggestion', name, help, params or {})
    end
    sug('/me', T('sug_me'), { { name = T('arg_action') } })
    sug('/do', T('sug_do'), { { name = T('arg_scene') } })
    sug('/ooc', T('sug_ooc'), { { name = T('arg_message') } })
    sug('/b', T('sug_b'), { { name = T('arg_message') } })
    sug('/try', T('sug_try'), { { name = T('arg_action') } })
    sug('/pm', T('sug_pm'), { { name = T('arg_id') }, { name = T('arg_message') } })
    sug('/ame', T('sug_ame'), { { name = T('arg_action') } })
end)

local ame = {}

RegisterNetEvent('qs-rp:client:ame', function(srcId, text)
    ame[srcId] = { text = text, expiry = GetGameTimer() + Config.AmeDuration }
end)

local function draw3d(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    local cam = GetGameplayCamCoord()
    local dist = #(cam - vector3(x, y, z))
    local scale = math.max(0.28, (1.0 / dist) * 3.0 * (100.0 / GetGameplayCamFov()) * 0.12)
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(230, 240, 255, 220)
    SetTextCentre(true)
    SetTextEdge(1, 0, 0, 0, 180)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(sx, sy)
end

CreateThread(function()
    while true do
        local sleep = 500
        if next(ame) then
            local myc = GetEntityCoords(PlayerPedId())
            for srcId, d in pairs(ame) do
                if GetGameTimer() > d.expiry then
                    ame[srcId] = nil
                else
                    local ped = GetPlayerPed(GetPlayerFromServerId(srcId))
                    if ped and ped ~= 0 and DoesEntityExist(ped) then
                        local c = GetEntityCoords(ped)
                        if #(myc - c) <= Config.AmeDistance + 5.0 then
                            sleep = 0
                            draw3d(c.x, c.y, c.z + 1.0, d.text)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
