Gangs = Gangs or {}

QS = {
    Players = {},
    PlayerData = {},
    Config = Config,
    Jobs = Jobs,
    Gangs = Gangs,
    Utils = Utils,
}

exports('GetCoreObject', function()
    return QS
end)

exports('GetColors', function()
    return QS.ClientColors or Config.Theme
end)

exports('RateLimit', function(key, max, windowMs)
    return Utils.RateLimit(key, max, windowMs)
end)
