QBCore = {}
QBCore.Config = {}

QBCore.Config.MaxPlayers = GetConvarInt('sv_maxclients', 48)
QBCore.Config.DefaultSpawn = vector4(-1035.71, -2731.87, 12.86, 0.0)
QBCore.Config.UpdateInterval = 5
QBCore.Config.StatusInterval = 5000

QBCore.Config.Money = {}
QBCore.Config.Money.MoneyTypes = { cash = 500, bank = 5000, crypto = 0 }
QBCore.Config.Money.DontAllowMinus = { 'cash', 'crypto' }
QBCore.Config.Money.PayCheckTimeOut = 10
QBCore.Config.Money.PayCheckSociety = false

QBCore.Config.Player = {}
QBCore.Config.Player.HungerRate = 4.2
QBCore.Config.Player.ThirstRate = 3.8
QBCore.Config.Player.Bloodtypes = { 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-' }

QBCore.Config.Server = {}
QBCore.Config.Server.Closed = false
QBCore.Config.Server.ClosedReason = 'Server Closed'
QBCore.Config.Server.Uptime = 0
QBCore.Config.Server.Whitelist = false
QBCore.Config.Server.WhitelistPermission = 'admin'
QBCore.Config.Server.PVP = true
QBCore.Config.Server.Discord = ''
QBCore.Config.Server.CheckDuplicateLicense = true
QBCore.Config.Server.PermissionList = {}

QBCore.Config.Notify = {}
QBCore.Config.Notify.NotificationStyling = { group = false, position = 'right', progress = true }
