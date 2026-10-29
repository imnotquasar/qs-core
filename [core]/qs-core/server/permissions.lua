Permissions = {}

local DEFAULT_GROUP = 'user'
local QB_PERMISSIONS = { 'god', 'admin', 'mod' }

function Permissions.LicenseOf(source)
    if not source or source == 0 then return nil end
    return GetPlayerIdentifierByType(source, 'license')
end

function Permissions.Has(source, permission)
    if not source or source == 0 then return true end
    if not permission then return true end

    if type(permission) == 'table' then
        for _, p in ipairs(permission) do
            if Permissions.Has(source, p) then return true end
        end
        return false
    end

    permission = tostring(permission):lower()
    if permission == 'user' then return true end
    if IsPlayerAceAllowed(source, permission) then return true end
    if IsPlayerAceAllowed(source, 'qbcore.' .. permission) then return true end
    if IsPlayerAceAllowed(source, 'group.' .. permission) then return true end
    if (permission == 'admin' or permission == 'god' or permission == 'mod')
        and (IsPlayerAceAllowed(source, 'group.admin') or IsPlayerAceAllowed(source, 'command')) then
        return true
    end
    return false
end

function Permissions.Add(source, permission)
    local lic = Permissions.LicenseOf(source)
    if not lic or not permission then return false end
    permission = tostring(permission):lower()
    ExecuteCommand(('add_ace identifier.%s qbcore.%s allow'):format(lic, permission))
    ExecuteCommand(('add_ace identifier.%s group.%s allow'):format(lic, permission))
    return true
end

function Permissions.Remove(source, permission)
    local lic = Permissions.LicenseOf(source)
    if not lic or not permission then return false end
    permission = tostring(permission):lower()
    ExecuteCommand(('remove_ace identifier.%s qbcore.%s allow'):format(lic, permission))
    ExecuteCommand(('remove_ace identifier.%s group.%s allow'):format(lic, permission))
    return true
end

function Permissions.Get(source)
    local perms = {}
    for _, p in ipairs(QB_PERMISSIONS) do
        if Permissions.Has(source, p) then perms[p] = true end
    end
    return perms
end

function Permissions.ApplyPrincipal(license, group)
    if not license or not group or group == '' or group == DEFAULT_GROUP then return end
    ExecuteCommand(('add_principal identifier.%s group.%s'):format(license, group))
end

exports('HasPermission', Permissions.Has)
exports('AddPermission', Permissions.Add)
exports('RemovePermission', Permissions.Remove)
exports('GetPermission', Permissions.Get)
