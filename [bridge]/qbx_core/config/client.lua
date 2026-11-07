return {
    statusIntervalSeconds = 5,
    loadingModelsTimeout = 30000,

    pauseMapText = 'Powered by Qbox',

    characters = {
        useExternalCharacters = false,
        enableDeleteButton = true,
        startingApartment = true,

        dateFormat = 'YYYY-MM-DD',
        dateMin = '1900-01-01',
        dateMax = '2006-12-31',

        limitNationalities = true,

        profanityWords = {
            ['bad word'] = true
        },

        locations = {
            {
                pedCoords = vec4(969.25, 72.61, 116.18, 276.55),
                camCoords = vec4(972.2, 72.9, 116.68, 97.27),
            },
            {
                pedCoords = vec4(1104.49, 195.9, -49.44, 44.22),
                camCoords = vec4(1102.29, 198.14, -48.86, 225.07),
            },
            {
                pedCoords = vec4(-2163.87, 1134.51, -24.37, 310.05),
                camCoords = vec4(-2161.7, 1136.4, -23.77, 131.52),
            },
            {
                pedCoords = vec4(-996.71, -68.07, -99.0, 57.61),
                camCoords = vec4(-999.90, -66.30, -98.45, 241.68),
            },
            {
                pedCoords = vec4(-1023.45, -418.42, 67.66, 205.69),
                camCoords = vec4(-1021.8, -421.7, 68.14, 27.11),
            },
            {
                pedCoords = vec4(2265.27, 2925.02, -84.8, 267.77),
                camCoords = vec4(2268.24, 2925.02, -84.36, 90.88),
            },
            {
                pedCoords = vec4(-1004.5, -478.51, 50.03, 28.19),
                camCoords = vec4(-1006.36, -476.19, 50.50, 210.38),
            }
        },
    },

    discord = {
        enabled = true,

        richPresence = 'Players {currentPlayers}/{maxPlayers}',

        updateInterval = 15000,

        appId = '1024981890798731345',

        largeIcon = {
            icon = 'duck',
            text = 'Qbox Ducky',
        },

        smallIcon = {
            icon = 'logo_name',
            text = 'This is a small icon with text',
        },

        firstButton = {
            text = 'Qbox Discord',
            link = 'https://discord.gg/Z6Whda5hHA',
        },

        secondButton = {
            text = 'Main Website',
            link = 'https://www.qbox.re/',
        }
    },

    hasKeys = function(plate, vehicle)
        return GetResourceState('qbx_vehiclekeys') ~= 'started' or exports.qbx_vehiclekeys:HasKeys(vehicle)
    end,

    teleport = {
        fadeDuration = 650,
        groundSearchMaxZ = 850.0,
        groundSearchStartZ = 950.0,
        groundSearchStep = -25.0,
        loadSceneRadius = 50.0,
        timeout = 1000,
    },

    getVehiclesInRadius = {
        defaultRadius = 5,
    },

    meCommand = {
        distance = 25,
        displayTime = 5000,
    },

    setVehicleProperties = {
        timeout = 1000,
        waitInterval = 50,
    },

    initVehicle = {
        seats = {-1, 0},
    },
}
