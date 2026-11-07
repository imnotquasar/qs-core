return {
    updateInterval = 5,

    money = {
        moneyTypes = { cash = 500, bank = 5000, crypto = 0 },
        dontAllowMinus = { 'cash', 'crypto' },
        paycheckTimeout = 10,
        paycheckSociety = false
    },

    player = {
        hungerRate = 4.2,
        thirstRate = 3.8,

        bloodTypes = {
            'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
        },

        identifierTypes = {
            citizenid = {
                valueFunction = function()
                    return lib.string.random('A.......')
                end,
            },
            AccountNumber = {
                valueFunction = function()
                    return 'US0' .. math.random(1, 9) .. 'QBX' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99)
                end,
            },
            PhoneNumber = {
                valueFunction = function()
                    return math.random(100,999) .. math.random(1000000,9999999)
                end,
            },
            FingerId = {
                valueFunction = function()
                    return lib.string.random('...............')
                end,
            },
            WalletId = {
                valueFunction = function()
                    return 'QB-' .. math.random(11111111, 99999999)
                end,
            },
            SerialNumber = {
                valueFunction = function()
                    return math.random(11111111, 99999999)
                end,
            },
        }
    },

    characterDataTables = {
        {'properties', 'owner'},
        {'bank_accounts_new', 'id'},
        {'playerskins', 'citizenid'},
        {'player_mails', 'citizenid'},
        {'player_outfits', 'citizenid'},
        {'player_vehicles', 'citizenid'},
        {'player_groups', 'citizenid'},
        {'players', 'citizenid'},
        {'npwd_calls', 'identifier'},
        {'npwd_darkchat_channel_members', 'user_identifier'},
        {'npwd_marketplace_listings', 'identifier'},
        {'npwd_messages_participants', 'participant'},
        {'npwd_notes', 'identifier'},
        {'npwd_phone_contacts', 'identifier'},
        {'npwd_phone_gallery', 'identifier'},
        {'npwd_twitter_profiles', 'identifier'},
        {'npwd_match_profiles', 'identifier'},
    },

    server = {
        pvp = true,
        closed = false,
        closedReason = 'Server Closed',
        whitelist = false,
        whitelistPermission = 'admin',
        discord = '',
        checkDuplicateLicense = true,
        requireOptIn = true,
        permissions = { 'god', 'admin', 'mod' },
    },

    characters = {
        playersNumberOfCharacters = {
            ['license2:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = 5,
        },

        defaultNumberOfCharacters = 3,
    },

    logging = {
        webhook = {
            ['default'] = nil,
            ['joinleave'] = nil,
            ['ooc'] = nil,
            ['anticheat'] = nil,
            ['playermoney'] = nil,
        },
        role = {}
    },

    persistence = {
        lockState = 'lock',
    },

    giveVehicleKeys = function(src, plate, vehicle)
        return exports.qbx_vehiclekeys:GiveKeys(src, vehicle)
    end,

    setVehicleLock = function(vehicle, state)
        exports.qbx_vehiclekeys:SetLockState(vehicle, state)
    end,

    getSocietyAccount = function(accountName)
        return exports['Renewed-Banking']:getAccountMoney(accountName)
    end,

    removeSocietyMoney = function(accountName, payment)
        return exports['Renewed-Banking']:removeAccountMoney(accountName, payment)
    end,

    sendPaycheck = function (player, payment)
        player.Functions.AddMoney('bank', payment)
        Notify(player.PlayerData.source, locale('info.received_paycheck', payment))
        TriggerEvent('qbx_core:server:onPaycheck', player.PlayerData.source, payment)
    end,
}
