
local PLUGIN = PLUGIN

util.AddNetworkString("ixSyncUserGroups")
util.AddNetworkString("ixUpdateUserGroupPrivilege")

ix.log.AddType("privilegeEdit", function(client, userGroup, privilege, value)
	return string.format("%s changed the '%s' privilege for the '%s' user group to %d", client:Name(), privilege.Name, userGroup.Name, value)
end, FLAG_WARNING)

function PLUGIN:DatabaseConnected()
    local query = mysql:Create("ix_privileges")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("group", "VARCHAR(50) NOT NULL")
        query:Create("privilege", "VARCHAR(100) NOT NULL")
        query:Create("value", "INT UNSIGNED NOT NULL")
        query:Create("default", "INT UNSIGNED NOT NULL")
        query:Create("actual", "INT UNSIGNED")
        query:Create("actual_from", "VARCHAR(50)")
        query:PrimaryKey("id")
        query:Callback(function()
            ix.userGroups.DB_READY = true
            ix.userGroups:ReloadPrivileges()
        end)
    query:Execute()
end

function PLUGIN:PlayerInitialSpawn(client)
    if (!ix.option.Get(client, "AdminActiveByDefault")) then return end

    client:SetAdminActive(true)
end

function PLUGIN:PlayerLoadedCharacter(client, character)
    if (client.ixDefaultAdminChecked) then return end
    client.ixDefaultAdminChecked = true

    local groups = {}
	hook.Run("GetPlayerPermissionGroups", client, groups)

    for group in pairs(groups) do
		local userGroup = CAMI.GetUsergroup(group)
        if (userGroup and userGroup.ActiveByDefault) then
            return
        end
    end

    client:SetAdminActive(false)
end

net.Receive("ixSyncUserGroups", function(len, client)
    if (client.ixUserGroupsSynced) then return end

    client.ixUserGroupsSynced = true

    ix.userGroups:SyncUserGroups(client)
end)

net.Receive("ixUpdateUserGroupPrivilege", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Helix - Manage Privileges")) then return end

    local userGroup = CAMI.GetUsergroup(net.ReadString())
    if (!userGroup) then return end

    local privilege = CAMI.GetPrivilege(net.ReadString())
    if (privilege) then return end

    local value = math.floor(net.ReadUInt(3))
    if (value < 0 or value > 4) then return end

    ix.userGroups:SetUserGroupPrivilege(userGroup, privilege, value)
    ix.log.Add(client, "privilegeEdit", userGroup, privilege, value)
end)