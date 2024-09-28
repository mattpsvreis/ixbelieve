
local PLAYER = FindMetaTable("Player")

function PLAYER:GetPermissionGroupsRaw()
	if (self.ixPermissionsGroupCache and self.ixPermissionsGroupCache.expire > CurTime()) then
		return self.ixPermissionsGroupCache.groups
	end

	local groups = {}
	hook.Run("GetPlayerPermissionGroups", self, groups)

	if (!self.ixPermissionsGroupCache) then
		self.ixPermissionsGroupCache = {
			expire = CurTime() + 60,
			groups = groups
		}
	else
		self.ixPermissionsGroupCache.time = CurTime() + 60
		self.ixPermissionsGroupCache.groups = groups
	end

	return groups
end

if (SERVER) then
	util.AddNetworkString("ixPermissionsGroupCacheReset")
else
	net.Receive("ixPermissionsGroupCacheReset", function()
		LocalPlayer().ixPermissionsGroupCache = nil
	end)
end

function PLAYER:ResetPermissionGroupsCache()
	self.ixPermissionsGroupCache = nil
	if (SERVER) then
		net.Start("ixPermissionsGroupCacheReset")
		net.Send(self)
	end
end

function PLAYER:GetPermissionGroups()
	local groups = self:GetPermissionGroupsRaw()

	local result = {"user"} -- everyone is always at least a user
	for group in pairs(groups) do
		local userGroup = CAMI.GetUsergroup(group)
		if (userGroup and (!userGroup.CanToggle or self:GetNetVar("AdminActive"))) then
			result[#result + 1] = group
		end
	end

	return result
end

function PLAYER:IsAdminActive()
    return self:HasToggleAdminGroup() and self:GetNetVar("AdminActive")
end

function PLAYER:SetAdminActive(bActive)
	self:SetNetVar("AdminActive", bActive)
end

function PLAYER:ToggleAdminActive()
	self:SetAdminActive(!self:IsAdminActive())
end


function PLAYER:HasToggleAdminGroup()
    local groups = self:GetPermissionGroupsRaw()

    for group in pairs(groups) do
		local userGroup = CAMI.GetUsergroup(group)
        if (userGroup and userGroup.CanToggle) then
            return true
        end
    end

    return false
end

function PLAYER:IsAdmin()
	return self:CheckGroup("admin")
end

function PLAYER:IsSuperAdmin()
	return self:CheckGroup("superadmin")
end

-- Check all the players their group if they inherit from the requested group
function PLAYER:CheckGroup(ancestor)
	for _, group in ipairs(self:GetPermissionGroups()) do
		if (CAMI.UsergroupInherits(group, ancestor)) then
			return true
		end
	end

	return false
end

-- A player's user group is always their highest immunity group
local defaultImmunity = {
	["user"] = 0,
	["admin"] = 50,
	["superadmin"] = 99
}
function PLAYER:GetUserGroup()
	local group, immunity = "user", 0
	for _, name in ipairs(self:GetPermissionGroups()) do
		local userGroup = CAMI.GetUsergroup(name)
		if (userGroup and (userGroup.Priority or defaultImmunity[userGroup.Name] or -1) > immunity) then
			group = name
			immunity = userGroup.Priority or defaultImmunity[userGroup.Name]
		end
	end

	return group
end