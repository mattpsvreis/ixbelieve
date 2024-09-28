
local PLUGIN = PLUGIN

PLUGIN.name = "UserGroups"
PLUGIN.author = "Gr4Ss"
PLUGIN.description = "Implements a multi-rank usergroup permission system through CAMI, with toggleable admin ranks."

ix.util.Include("meta/sh_player.lua")

ix.util.Include("cl_plugin.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("sh_cami.lua")
ix.util.Include("sv_hooks.lua")

--TODO: add in some client-side display that admin is active

ix.lang.AddTable("english", {
    optAdminActiveByDefault = "Admin Active by Default",
    optdAdminActiveByDefault = "Automatically enable admin upon joining the server if you have an admin rank which allows this.",
})

ix.option.Add("AdminActiveByDefault", ix.type.bool, true, {
	bNetworked = true,
	category = "Admininistration",
	hidden = function()
        local groups = {}
        hook.Run("GetPlayerPermissionGroups", LocalPlayer(), groups)

        for group in pairs(groups) do
            local userGroup = CAMI.GetUsergroup(group)
            if (userGroup and userGroup.ActiveByDefault) then
                return false
            end
        end

        return true
	end
})

CAMI.RegisterPrivilege({
    Name = "Helix - ToggleAdmin Other",
    MinAccess = "admin",
    Description = "Allows the user to toggle the admin of other players off."
})

CAMI.RegisterPrivilege({
    Name = "Helix - ToggleAdmin Immune",
    MinAccess = "superadmin",
    Description = "Makes the user immune to have other players toggle their admin off."
})

CAMI.RegisterPrivilege({
    Name = "Helix - Manage Privileges",
    MinAccess = "superadmin",
    Description = "Makes the user immune to have other players toggle their admin off."
})