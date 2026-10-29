local core = exports['qs-core']

AddEventHandler('esx:playerLogout', function(src)
    src = tonumber(src)
    if not src or src <= 0 then return end
    core:Logout(src)
end)

local function mapIdentityToCharinfo(data)
    data = data or {}
    local sex = data.sex
    if sex == 'm' or sex == 0 or sex == '0' then
        sex = 'male'
    elseif sex == 'f' or sex == 1 or sex == '1' then
        sex = 'female'
    else
        sex = 'male'
    end
    return {
        firstname = tostring(data.firstname or ''):sub(1, 30),
        lastname = tostring(data.lastname or ''):sub(1, 30),
        dob = tostring(data.dateofbirth or data.dob or ''):sub(1, 10),
        sex = sex,
        nationality = data.nationality and tostring(data.nationality):sub(1, 40) or nil,
    }
end

ESX.RegisterServerCallback('esx_identity:registerIdentity', function(src, cb, data)
    if type(data) ~= 'table' then
        cb(false)
        return
    end

    local charinfo = mapIdentityToCharinfo(data)
    if #charinfo.firstname == 0 or #charinfo.lastname == 0 then
        cb(false)
        return
    end

    local created, err = core:CreateCharacter(src, charinfo, nil)
    if not created then
        print(('^3[es_extended bridge]^7 esx_identity:registerIdentity failed (%s)'):format(tostring(err)))
        cb(false)
        return
    end

    local ok, loadErr = core:LoadCharacter(src, created.citizenid, true)
    if not ok then
        print(('^3[es_extended bridge]^7 esx_identity load failed (%s)'):format(tostring(loadErr)))
        cb(false)
        return
    end

    TriggerEvent('esx_identity:completedRegistration', src, {
        firstname = charinfo.firstname,
        lastname = charinfo.lastname,
        dateofbirth = charinfo.dob,
        sex = charinfo.sex == 'female' and 'f' or 'm',
        height = tonumber(data.height) or 180,
        nationality = charinfo.nationality,
    })

    cb(true)
end)
