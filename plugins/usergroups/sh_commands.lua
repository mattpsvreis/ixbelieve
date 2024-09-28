
ix.command.Add("ToggleAdmin", {
    description = "Toggle your admin on and off. Can also toggle other users their admin off.",
    arguments = {
        bit.bor(ix.type.optional, ix.type.player),
    },
	OnCheckAccess = function(self, client) return client:HasToggleAdminGroup() end,
	OnRun = function(self, client, target)
        if (IsValid(target) and target != client) then
            if (!CAMI.PlayerHasAccess(client, "Helix - ToggleAdmin Other")) then
                return "You do not have access to toggle others their admin."
            elseif (CAMI.PlayerHasAccess(target, "Helix - ToggleAdmin Immune")) then
                return target:Name().." is immune to admin toggle from others."
            elseif (!target:IsAdminActive()) then
                return target:Name().." does not have their admin active."
            end
        else
            target = client
        end

        target:ToggleAdminActive()
        target:SetLocalVar("toggleAdminManual", CurTime() + 60)
        ix.util.NotifyCami(string.format("%s has toggled %s admin %s.", client:Name(), (client == target and "their") or (target:Name().."'s"), (target:IsAdminActive() and "ON") or "OFF"), "Helix - Admin", target)
    end,
})

ix.command.Add("ListAdmins", {
    alias = {"PrintStaffList", "PSL"},
	description = "List all ingame admins",
    OnCheckAccess = function(self, client) return true end,
	OnRun = function(self, client)
        local groups = {}
		for _, v in ipairs(player.GetAll()) do
            local highest, priority = nil, -1
			for _, group in ipairs(v:GetPermissionGroups()) do
                if (CAMI.GetUsergroup(group).List and CAMI.GetUsergroup(group).Priority > priority) then
                    highest = group
                    priority = CAMI.GetUsergroup(group).Priority
                end
            end

            if (highest) then
                groups[highest] = groups[highest] or {}
                groups[highest][#groups[highest] + 1] = v
            end
		end

        local toSend = {}
        for group, players in pairs(groups) do
            local name = CAMI.GetUsergroup(group).NiceName
            toSend[#toSend + 1] = {priority = CAMI.GetUsergroup(group).Priority, name = name, players = players}
        end
        table.SortByMember(toSend, "name", true)
        table.SortByMember(toSend, "priority", true)

        if (#toSend > 0) then
			net.Start("ixStaffList")
				net.WriteUInt(#toSend, 8)
				for _, v in ipairs(toSend) do
					net.WriteString(v.name)
					net.WriteUInt(#v.players, 8)
					for i = 1, #v.players do
						net.WriteEntity(v.players[i])
					end
				end
			net.Send(client)
		else
			client:Notify("There are no staff online currently.")
		end
	end
})

--[[
ix.command.Add("PrivilegesEdit", {
	description = "Edit the user group privileges.",
    privilege = "Manage Privileges",
	OnRun = function(self, client)
        net.Start("ixUpdateUserGroupPrivilege")
        net.Send(client)
	end
})
--]]

ix.command.Add("PrivilegesPrune", {
	description = "Change all possible privileges to 'inherit' or 'default' (instead of allow/deny/never) if this has no effect on their value.",
    privilege = "Manage Privileges",
	OnRun = function(self, client)
        ix.userGroups:PrunePrivileges()
        return "Privileges will be pruned!"
	end
})

ix.command.Add("PrivilegesClean", {
	description = "Remove unused privileges from the database.",
    privilege = "Manage Privileges",
	OnRun = function(self, client)
        ix.userGroups:CleanStalePrivileges()
        return "Unused permissions will be removed from the database!"
	end
})

ix.command.Add("PrivilegesReload", {
	description = "Reload all privilege values from the database.",
    privilege = "Manage Privileges",
	OnRun = function(self, client)
        ix.userGroups:ReloadPrivileges()
        return "Privileges will get reloaded from the database!"
	end
})