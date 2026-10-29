Gangs = Gangs or {}

Gangs['none'] = {
    label = 'No Gang',
    grades = {
        [0] = { name = 'Unaffiliated', label = 'Unaffiliated', isBoss = false },
    },
}

function QS.RegisterGang(name, data)
    if type(name) ~= 'string' or type(data) ~= 'table' then return false end
    data.label = data.label or name
    data.grades = data.grades or { [0] = { name = 'member', label = 'Member', isBoss = false } }
    Gangs[name] = data
    return true
end

function QS.RegisterGangs(tbl)
    if type(tbl) ~= 'table' then return false end
    for name, data in pairs(tbl) do
        QS.RegisterGang(name, data)
    end
    return true
end

function QS.GetGang(name)
    return Gangs[name]
end

function QS.GetGangs()
    return Gangs
end

function QS.RemoveGang(name)
    if name == 'none' then return false end
    Gangs[name] = nil
    return true
end

function QS.BuildGang(name, grade)
    name = tostring(name or 'none'):lower()
    grade = tonumber(grade) or 0
    local def = Gangs[name] or Gangs['none']
    local gradeDef = def.grades and (def.grades[grade] or def.grades[tostring(grade)])
    if not gradeDef and def.grades then
        for lvl, g in pairs(def.grades) do
            local n = tonumber(lvl) or 0
            if not gradeDef or n < grade then
                grade = n
                gradeDef = g
            end
        end
    end
    return {
        name = name,
        label = def.label or name,
        isboss = (gradeDef and gradeDef.isBoss) or false,
        grade = {
            name = (gradeDef and (gradeDef.name or gradeDef.label)) or 'Unaffiliated',
            level = grade,
        },
    }
end

exports('RegisterGang', QS.RegisterGang)
exports('RegisterGangs', QS.RegisterGangs)
exports('GetGang', QS.GetGang)
exports('GetGangs', QS.GetGangs)
exports('RemoveGang', QS.RemoveGang)
