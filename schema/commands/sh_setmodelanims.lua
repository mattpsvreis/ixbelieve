AddCSLuaFile()

ix.command.Add("SetModelAnims", {
	description = "Sets a model's animation set.",
	adminOnly = true,
	arguments = {
		ix.type.string,
		bit.bor(ix.type.string, ix.type.optional)
	},
	OnRun = function(self, client, model, class)

		local anims = table.GetKeys(ix.anim)
		table.RemoveByValue(anims, "GetModelClass")
		table.RemoveByValue(anims, "SetModelClass")

		if class == nil or ix.anim[class] == nil then
			local keys = table.concat(anims, ", ")
			client:PrintMessage(HUD_PRINTTALK, "Valid classes: " .. keys)
			return
		end

		ix.anim.SetModelClass(model, class)
		ix.util.NotifyCami(string.format("%s set the model class for '%s' to %s.", client:Name(), model, class), "Helix - SetModelAnims")
	end
})
