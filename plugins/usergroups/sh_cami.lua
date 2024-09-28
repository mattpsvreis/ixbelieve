
-- This file uses local functions as they shouldn't be called direclty.
-- Use the respective CAMI function instead

local function setupPrivilege(userGroup, privilege, bLoad)
    userGroup.Defaults[privilege.LowerName] = (privilege.MinAccess == userGroup.Name and ix.userGroups.ALLOW) or ix.userGroups.INHERIT
    if (!userGroup.Privileges[privilege.LowerName]) then
        userGroup.Privileges[privilege.LowerName] = ix.userGroups.DEFAULT
    end

    if (SERVER and bLoad) then
        ix.userGroups:LoadUserGroupPrivilege(userGroup, privilege)
    end
end

hook.Add("CAMI.OnPrivilegeRegistered", "ix.CAMI.OnPrivilegeRegistered", function(privilege)
    privilege.LowerName = string.lower(privilege.Name)
    for _, userGroup in pairs(CAMI.GetUsergroups()) do
        setupPrivilege(userGroup, privilege, true)
    end
end)

for _, privilege in pairs(CAMI.GetPrivileges()) do
    privilege.LowerName = string.lower(privilege.Name) -- Setup the privileges that were already created
end

local function registerUserGroup(userGroup)
    userGroup.NiceName = userGroup.Name:gsub("_", " "):gsub(" %l", string.upper):gsub("^%l", string.upper)
    userGroup.Defaults = {}
    userGroup.Privileges = {}

    for _, privilege in pairs(CAMI.GetPrivileges()) do
        setupPrivilege(userGroup, privilege, true)
    end
end

hook.Add("CAMI.OnUsergroupRegistered", "ix.CAMI.OnUsergroupRegistered", registerUserGroup)

for k, v in pairs(CAMI.GetUsergroups()) do
    registerUserGroup(v) -- Register groups that were already created
end

if (SERVER) then
    hook.Add("CAMI.OnusergroupUnregistered", "ix.CAMI.OnusergroupUnregistered", function(userGroup)
        ix.userGroups:DeleteUserGroup(userGroup)
    end)
end

hook.Add("CAMI.OnPrivilegeUnregistered", "ix.CAMI.OnPrivilegeUnregistered", function(privilege)
    for _, userGroup in pairs(CAMI.GetUsergroups()) do
        userGroup.Defaults[privilege.LowerName] = nil
        userGroup.Privileges[privilege.LowerName] = nil
    end

    if (SERVER) then
        ix.userGroups:DeletePrivilege(privilege)
    end
end)

hook.Add("CAMI.PlayerHasAccess", "ix.CAMI.PlayerHasAccess", function(client, privName, callback, target, info)
	if (!IsValid(client) or !client:IsPlayer()) then return end

    if (privName == "Helix - ToggleAdmin") then
        callback(client:HasToggleAdminGroup())
        return true
    end

    local groups = client:GetPermissionGroups()
    local bHasPermission = false
    for _, name in ipairs(groups) do
        local value = ix.userGroups:HasPermissionRaw(CAMI.GetUsergroup(name), privName)
        if (value == ix.userGroups.NEVER) then
            callback(false)
            return true
        elseif (value == ix.userGroups.ALLOW) then
            bHasPermission = true
        end
    end

    callback(bHasPermission)
    return true
end)