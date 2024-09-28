AddCSLuaFile()

ix.command.Add("CharInventory", {
	alias = "inventory",
	bContextMenu = true,
	description = "View & edit a character's inventory",
	superAdminOnly = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		if (!target:GetCharacter() or !target:GetCharacter():GetInventory()) then
			return false
		end

		local name = hook.Run("GetDisplayedName", target) or target:Name()
		local inventory = target:GetCharacter():GetInventory()

		ix.storage.Open(client, inventory, {
			entity = target,
			name = name
		})

		return true
	end
})
