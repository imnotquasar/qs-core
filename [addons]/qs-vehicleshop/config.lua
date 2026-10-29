Config = {}

-- E key + reach
Config.OpenKey = 38
Config.InteractDistance = 2.5

-- pay accounts
Config.PayAccounts = { 'bank', 'cash' }

-- delivery garage
Config.DefaultGarage = 'legion'

-- showroom camera
Config.Camera = {
    dist   = 5.2,
    side   = 1.6,
    height = 0.3,
    target = 0.0,
    fov    = 32.0,
    turntable = 12.0,
}

-- dealerships
Config.Locations = {
    {
        ped     = 's_m_m_autoshop_02',
        coords  = vec4(-56.46, -1098.57, 26.42, 41.07),
        preview = vec4(-43.29, -1098.19, 26.42, 67.68),
        spawn   = vec4(-27.90, -1081.97, 26.64, 64.90),
        blip    = { sprite = 326, color = 3, scale = 0.6, label = 'Dealership' },
    },
}

-- vehicle catalogue
Config.Categories = {
    { id = 'compacts', label = 'Compacts' },
    { id = 'sedans',   label = 'Sedans' },
    { id = 'suvs',     label = 'SUVs' },
    { id = 'sports',   label = 'Sports' },
    { id = 'offroad',  label = 'Off-Road' },
    { id = 'motorcycles', label = 'Motorcycles' },
}

Config.Vehicles = {
    compacts = {
        { model = 'blista',  label = 'Dinka Blista',   price = 9000 },
        { model = 'brioso',  label = 'Grotti Brioso',  price = 18000 },
        { model = 'issi2',   label = 'Weeny Issi',     price = 16000 },
        { model = 'panto',   label = 'Benefactor Panto', price = 8500 },
    },
    sedans = {
        { model = 'asea',    label = 'Declasse Asea',  price = 12000 },
        { model = 'premier', label = 'Declasse Premier', price = 15000 },
        { model = 'stanier', label = 'Vapid Stanier',  price = 14000 },
        { model = 'warrener', label = 'Vulcar Warrener', price = 17000 },
    },
    suvs = {
        { model = 'baller',  label = 'Gallivanter Baller', price = 55000 },
        { model = 'granger', label = 'Declasse Granger', price = 38000 },
        { model = 'cavalcade', label = 'Albany Cavalcade', price = 42000 },
    },
    sports = {
        { model = 'sultan',  label = 'Karin Sultan',   price = 45000 },
        { model = 'kuruma',  label = 'Karin Kuruma',   price = 52000 },
        { model = 'elegy2',  label = 'Annis Elegy RH8', price = 60000 },
        { model = 'jester',  label = 'Dinka Jester',   price = 78000 },
    },
    offroad = {
        { model = 'sandking', label = 'Vapid Sandking', price = 40000 },
        { model = 'rebel2',  label = 'Karin Rebel',    price = 22000 },
        { model = 'kalahari', label = 'Canis Kalahari', price = 18000 },
    },
    motorcycles = {
        { model = 'akuma',   label = 'Dinka Akuma',    price = 14000 },
        { model = 'bati',    label = 'Pegassi Bati 801', price = 20000 },
        { model = 'sanchez', label = 'Maibatsu Sanchez', price = 9000 },
    },
}
