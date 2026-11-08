if IsDuplicityVersion() then return end

QBX = {} -- luacheck: ignore
QBX.PlayerData = exports.qbx_core:GetPlayerData() or {}

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ---@diagnostic disable-next-line: missing-fields
    QBX.PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(value)
    if type(value) == 'table' and value.jobs then QBX.PlayerData = value end
end)

AddEventHandler('qbx_core:client:playerDataUpdated', function(value)
    QBX.PlayerData = value
end)
