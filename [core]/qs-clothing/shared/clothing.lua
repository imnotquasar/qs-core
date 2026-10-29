Clothing = {}

Clothing.Models = {
    male = 'mp_m_freemode_01',
    female = 'mp_f_freemode_01',
}

Clothing.Sections = {
    { key = 'face',        label = 'Face & Hair' },
    { key = 'upper',       label = 'Upper Body' },
    { key = 'lower',       label = 'Lower Body' },
    { key = 'accessories', label = 'Accessories' },
    { key = 'tattoos',     label = 'Tattoos' },
}

Clothing.Categories = {
    { key = 'hair',       label = 'Hair',       kind = 'component', id = 2,  max = 80,  section = 'face' },
    { key = 'beard',      label = 'Beard',      kind = 'overlay',   id = 1,  max = 28,  section = 'face' },
    { key = 'undershirt', label = 'Undershirt', kind = 'component', id = 8,  max = 200, section = 'upper' },
    { key = 'torso',      label = 'Arms',       kind = 'component', id = 3,  max = 180, section = 'upper' },
    { key = 'top',        label = 'Top',        kind = 'component', id = 11, max = 400, section = 'upper' },
    { key = 'legs',       label = 'Legs',       kind = 'component', id = 4,  max = 150, section = 'lower' },
    { key = 'shoes',      label = 'Shoes',      kind = 'component', id = 6,  max = 100, section = 'lower' },
    { key = 'mask',       label = 'Mask',       kind = 'component', id = 1,  max = 200, section = 'accessories' },
    { key = 'bag',        label = 'Bag',        kind = 'component', id = 5,  max = 100, section = 'accessories' },
    { key = 'hat',        label = 'Hat',        kind = 'prop',      id = 0,  max = 150, section = 'accessories' },
    { key = 'glasses',    label = 'Glasses',    kind = 'prop',      id = 1,  max = 40,  section = 'accessories' },

    { key = 'tat_business',   label = 'Business',      kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_hipster',    label = 'Hipster',       kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_biker',      label = 'Biker',         kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_airraces',   label = 'Air Races',     kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_beach',      label = 'Beach',         kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_festive',    label = 'Festive',       kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_gunrunning', label = 'Gunrunning',    kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_ie',         label = 'Import/Export', kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_lowrider2',  label = 'Lowrider II',   kind = 'tattoo', section = 'tattoos' },
    { key = 'tat_lowrider',   label = 'Lowrider',      kind = 'tattoo', section = 'tattoos' },
}

local function seqNames(prefix, from, to, suffix)
    local out = {}
    for n = from, to do out[#out + 1] = ('%s%03d%s'):format(prefix, n, suffix or '') end
    return out
end
local function idxNames(prefix, indices, suffix)
    local out = {}
    for _, n in ipairs(indices) do out[#out + 1] = ('%s%03d%s'):format(prefix, n, suffix or '') end
    return out
end

Clothing.Tattoos = {
    tat_business = {
        collection = 'mpbusiness_overlays',
        names = {
            'MP_Buis_M_Neck_000', 'MP_Buis_M_Neck_001', 'MP_Buis_M_Neck_002', 'MP_Buis_M_Neck_003',
            'MP_Buis_M_LeftArm_000', 'MP_Buis_M_LeftArm_001', 'MP_Buis_M_RightArm_000', 'MP_Buis_M_RightArm_001',
            'MP_Buis_M_Stomach_000', 'MP_Buis_M_Chest_000', 'MP_Buis_M_Chest_001', 'MP_Buis_M_Back_000',
            'MP_Buis_F_Chest_000', 'MP_Buis_F_Chest_001', 'MP_Buis_F_Chest_002', 'MP_Buis_F_Stom_000',
            'MP_Buis_F_Stom_001', 'MP_Buis_F_Stom_002', 'MP_Buis_F_Back_000', 'MP_Buis_F_Back_001',
            'MP_Buis_F_Neck_000', 'MP_Buis_F_Neck_001', 'MP_Buis_F_RArm_000', 'MP_Buis_F_LArm_000',
            'MP_Buis_F_LLeg_000', 'MP_Buis_F_RLeg_000',
        },
    },
    tat_hipster    = { collection = 'mphipster_overlays',    names = seqNames('FM_Hip_M_Tat_', 0, 48) },
    tat_biker      = { collection = 'mpbiker_overlays',      names = seqNames('MP_MP_Biker_Tat_', 0, 60, '_M') },
    tat_airraces   = { collection = 'mpairraces_overlays',   names = seqNames('MP_Airraces_Tattoo_', 0, 7, '_M') },
    tat_beach = {
        collection = 'mpbeach_overlays',
        names = {
            'MP_Bea_M_Back_000', 'MP_Bea_M_Chest_000', 'MP_Bea_M_Chest_001', 'MP_Bea_M_Head_000',
            'MP_Bea_M_Head_001', 'MP_Bea_M_Head_002', 'MP_Bea_M_Lleg_000', 'MP_Bea_M_Rleg_000',
            'MP_Bea_M_RArm_000', 'MP_Bea_M_LArm_000', 'MP_Bea_M_LArm_001', 'MP_Bea_M_Neck_000',
            'MP_Bea_M_Neck_001', 'MP_Bea_M_RArm_001', 'MP_Bea_M_Stom_000', 'MP_Bea_M_Stom_001',
        },
    },
    tat_festive    = { collection = 'mpchristmas2_overlays', names = idxNames('MP_Xmas2_M_Tat_', { 0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26, 27, 28, 29 }) },
    tat_gunrunning = { collection = 'mpgunrunning_overlays', names = seqNames('MP_Gunrunning_Tattoo_', 0, 30, '_M') },
    tat_ie         = { collection = 'mpimportexport_overlays', names = seqNames('MP_MP_ImportExport_Tat_', 0, 11, '_M') },
    tat_lowrider2  = { collection = 'mplowrider2_overlays',  names = idxNames('MP_LR_Tat_', { 0, 3, 6, 8, 11, 12, 16, 18, 19, 22, 28, 29, 30, 31, 32, 35 }, '_M') },
    tat_lowrider   = { collection = 'mplowrider_overlays',   names = idxNames('MP_LR_Tat_', { 1, 2, 4, 5, 7, 9, 10, 13, 14, 15, 17, 20, 21, 23, 26, 27, 33 }, '_M') },
}

function Clothing.TattooCount(key)
    local t = Clothing.Tattoos[key]
    return t and #t.names or 0
end

for _, cat in ipairs(Clothing.Categories) do
    if cat.kind == 'tattoo' then cat.max = Clothing.TattooCount(cat.key) end
end

function Clothing.DefaultSkin(sex)
    local skin = { sex = (sex == 'female') and 'female' or 'male' }
    for _, cat in ipairs(Clothing.Categories) do
        if cat.kind == 'tattoo' then
            skin[cat.key] = { drawable = 0, texture = 0 }
        else
            skin[cat.key] = { drawable = (cat.kind == 'prop' or cat.kind == 'overlay') and -1 or 0, texture = 0 }
        end
    end
    return skin
end
