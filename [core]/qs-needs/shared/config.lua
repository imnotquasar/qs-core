NeedsConfig = {}

-- drained per interval
NeedsConfig.DecayInterval = 60000 -- 1 min
NeedsConfig.DecayHunger = 1.0
NeedsConfig.DecayThirst = 1.4

-- at 0, lose this hp per interval
NeedsConfig.StarveInterval = 10000
NeedsConfig.StarveDamage = 5

-- eat/drink anim + prop
NeedsConfig.Anim = {
    eat = {
        dict     = 'mp_player_inteat@burger',
        anim     = 'mp_player_int_eat_burger',
        prop     = 'prop_cs_burger_01',
        duration = 3500,
        bone     = 18905, -- right hand
        pos      = vec3(0.13, 0.05, 0.02),
        rot      = vec3(-50.0, 16.0, 60.0),
    },
    drink = {
        dict     = 'mp_player_intdrink',
        anim     = 'loop_bottle',
        prop     = 'prop_ld_flow_bottle',
        duration = 3000,
        bone     = 18905,
        pos      = vec3(0.12, 0.028, 0.001),
        rot      = vec3(10.0, 175.0, 0.0),
    },
}

-- item effects
NeedsConfig.Consumables = {
    water        = { thirst = 30, verb = 'drink' },
    bread        = { hunger = 25, verb = 'eat' },
    burger       = { hunger = 45, verb = 'eat' },
    sandwich     = { hunger = 30, verb = 'eat' },
    cola         = { thirst = 25, hunger = 5, verb = 'drink' },
    coffee       = { thirst = 15, verb = 'drink' },
    energy_drink = { thirst = 35, verb = 'drink' },
}
