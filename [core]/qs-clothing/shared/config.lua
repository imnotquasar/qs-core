Config = {}

-- edit on new character
Config.EditOnNewCharacter = true

-- editor camera
Config.Cam = {
    side = -0.08, -- shift ped left
    sections = {
        face        = { dist = 1.85, height = 0.66, target = 0.63, fov = 18.0 },
        upper       = { dist = 2.45, height = 0.50, target = 0.25, fov = 24.0 },
        lower        = { dist = 2.45, height = 0.10, target = -0.35, fov = 30.0 },
        accessories = { dist = 2.60, height = 0.30, target = 0.15, fov = 35.0 },
        tattoos     = { dist = 2.55, height = 0.35, target = 0.20, fov = 32.0 },
    },
}

Config.StoreTypes = {
    clothing = { enabled = { 'upper', 'lower', 'accessories' }, blip = { sprite = 73, color = 3,  size = 0.6,  label = 'Clothing Store' } },
    barber   = { enabled = { 'face' },                          blip = { sprite = 71, color = 25, size = 0.6,  label = 'Barber' } },
    tattoo   = { enabled = { 'tattoos' },                       blip = { sprite = 75, color = 1,  size = 0.6, label = 'Tattoo Parlor' } },
}

Config.Stores = {
    -- clothing (Ponsonbys / Suburban)
    { type = 'clothing', coords = vector3(72.3, -1399.1, 28.4) },
    { type = 'clothing', coords = vector3(-703.8, -152.3, 36.4) },
    { type = 'clothing', coords = vector3(-167.9, -299.0, 38.7) },
    { type = 'clothing', coords = vector3(428.7, -800.1, 28.5) },
    { type = 'clothing', coords = vector3(-829.4, -1073.7, 10.3) },
    { type = 'clothing', coords = vector3(-1447.8, -242.5, 48.8) },
    { type = 'clothing', coords = vector3(11.6, 6514.2, 30.9) },
    { type = 'clothing', coords = vector3(123.6, -219.4, 53.6) },
    { type = 'clothing', coords = vector3(1696.3, 4829.3, 41.1) },
    { type = 'clothing', coords = vector3(618.1, 2759.6, 41.1) },
    { type = 'clothing', coords = vector3(1190.6, 2713.4, 37.2) },
    { type = 'clothing', coords = vector3(-1193.4, -772.3, 16.3) },
    { type = 'clothing', coords = vector3(-3172.5, 1048.1, 19.9) },
    { type = 'clothing', coords = vector3(-1108.4, 2708.9, 18.1) },
    -- barber
    { type = 'barber',   coords = vector3(-814.308, -183.823, 36.568) },
    { type = 'barber',   coords = vector3(136.826, -1708.373, 28.291) },
    { type = 'barber',   coords = vector3(-1282.604, -1116.757, 5.990) },
    { type = 'barber',   coords = vector3(1931.513, 3729.671, 31.844) },
    { type = 'barber',   coords = vector3(1212.840, -472.921, 62.208) },
    { type = 'barber',   coords = vector3(-32.885, -152.319, 56.076) },
    { type = 'barber',   coords = vector3(-278.077, 6228.463, 30.695) },
    -- tattoo
    { type = 'tattoo',   coords = vector3(1322.6, -1651.9, 51.2) },
    { type = 'tattoo',   coords = vector3(-1153.6, -1425.6, 4.9) },
    { type = 'tattoo',   coords = vector3(322.1, 180.4, 103.5) },
    { type = 'tattoo',   coords = vector3(-3170.0, 1075.0, 20.8) },
    { type = 'tattoo',   coords = vector3(1864.6, 3747.7, 33.0) },
    { type = 'tattoo',   coords = vector3(-293.7, 6200.0, 31.4) },
}

Config.StoreKey = 38          -- E
Config.StoreDistance = 3.0    -- prompt radius (m)
