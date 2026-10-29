Config = {}

-- false = skip the intro
Config.Enabled = true

Config.Dof = true -- camera blur

-- camera
Config.Cam = {
    pos  = vec3(1000.46, -3108.20, -38.80),
    look = vec3(997.54, -3108.59, -38.80),
    fov  = 25.0, -- lower = closer
}

-- actor
Config.Ped = {
    model  = 'mp_m_freemode_01',
    start  = vec4(997.92, -3112.22, -39.00, 7.86), -- x,y,z,heading
    finish = vec3(997.76, -3107.55, -39.00),
    speed  = 1.0, -- 1 walk, 2 run
    pose   = { dict = 'anim@heists@heist_corona@single_team', anim = 'single_team_loop_boss' },

    -- grab yours with /introoutfit
    components = {
        { id = 1, drawable = 3, texture = 0 },
        { id = 3, drawable = 4, texture = 0 },
        { id = 4, drawable = 4, texture = 0 },
        { id = 5, drawable = 0, texture = 0 },
        { id = 6, drawable = 10, texture = 0 },
        { id = 7, drawable = 0, texture = 0 },
        { id = 8, drawable = 4, texture = 0 },
        { id = 9, drawable = 0, texture = 0 },
        { id = 10, drawable = 0, texture = 0 },
        { id = 11, drawable = 70, texture = 5 },
    },
    props = {
        { id = 0, drawable = -1, texture = -1 },
        { id = 1, drawable = -1, texture = -1 },
        { id = 2, drawable = -1, texture = -1 },
        { id = 6, drawable = -1, texture = -1 },
        { id = 7, drawable = -1, texture = -1 },
    },
}

-- hide spot
Config.Scene = {
    hide = vec3(1001.46, -3108.20, -39.00),
}
