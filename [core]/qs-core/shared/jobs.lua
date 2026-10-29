Jobs = {
    ['unemployed'] = {
        label = 'Civilian',
        defaultDuty = true,
        grades = {
            [0] = { name = 'freelancer', label = 'Freelancer', salary = 200 },
        },
    },
    ['police'] = {
        label = 'Police',
        defaultDuty = false,
        grades = {
            [0] = { name = 'recruit',  label = 'Recruit',       salary = 500 },
            [1] = { name = 'officer',  label = 'Officer',        salary = 750 },
            [2] = { name = 'sergeant', label = 'Sergeant',       salary = 1000 },
            [3] = { name = 'boss',     label = 'Chief',          salary = 2000, isBoss = true },
        },
    },
    ['ambulance'] = {
        label = 'EMS',
        defaultDuty = false,
        grades = {
            [0] = { name = 'trainee',  label = 'Trainee',   salary = 500 },
            [1] = { name = 'paramedic', label = 'Paramedic', salary = 800 },
            [2] = { name = 'doctor',   label = 'Doctor',    salary = 1200 },
            [3] = { name = 'boss',     label = 'Chief',     salary = 2000, isBoss = true },
        },
    },
    ['hunter'] = {
        label = 'Hunter',
        defaultDuty = true,
        grades = {
            [0] = { name = 'hunter', label = 'Hunter', salary = 200 },
        },
    },
    ['delivery'] = {
        label = 'Delivery Driver',
        defaultDuty = true,
        grades = {
            [0] = { name = 'driver', label = 'Driver', salary = 200 },
        },
    },
    ['miner'] = {
        label = 'Miner',
        defaultDuty = true,
        grades = {
            [0] = { name = 'miner', label = 'Miner', salary = 175 },
        },
    },
    ['lumberjack'] = {
        label = 'Lumberjack',
        defaultDuty = true,
        grades = {
            [0] = { name = 'lumberjack', label = 'Lumberjack', salary = 175 },
        },
    },
    ['fisher'] = {
        label = 'Fisherman',
        defaultDuty = true,
        grades = {
            [0] = { name = 'fisher', label = 'Fisherman', salary = 150 },
        },
    },
}
