Config = {}

-- character slots per player
Config.MaxCharacters = 5

-- server name
Config.Brand = 'Quasar Roleplay'

-- file in locales/
Config.Locale = 'en'

-- enable /logout
Config.EnableLogout = true
Config.LogoutCommand = 'logout'

-- preview ped + camera
Config.Preview = {
    coords       = vec4(1024.03, -3112.15, -39.00, 353.68),
    camDist      = 1.8,
    camHeight    = 0.70,
    targetHeight = 0.5,
    camSide      = 0.0,
    fov          = 25.0, -- lower = closer

    dof          = true, -- background blur
    dofNear      = 0.6,
    dofFar       = 2.4,
    dofStrength  = 1.0,

    -- creator camera
    creatorSide   = 0.12,
    creatorInterp = 1200, -- ms
    creatorSections = {
        face        = { dist = 1.85, height = 0.66, target = 0.63, fov = 18.0 },
        upper       = { dist = 2.45, height = 0.50, target = 0.25, fov = 24.0 },
        lower       = { dist = 2.45, height = 0.10, target = -0.35, fov = 30.0 },
        accessories = { dist = 2.60, height = 0.30, target = 0.15, fov = 35.0 },
    },
}

-- idle anims
Config.Poses = {
    { dict = 'anim@heists@heist_corona@team_idles@male_a', clip = 'idle' },
    { dict = 'anim@heists@heist_corona@team_idles@male_b', clip = 'idle' },
    { dict = 'anim@heists@heist_corona@team_idles@male_c', clip = 'idle' },
    { dict = 'anim@heists@heist_corona@team_idles@male_d', clip = 'idle' },
}
