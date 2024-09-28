AddCSLuaFile()

ix.command.Add("CharListBoosts", {
	description = "Lists a character's boost",
	privilege = "Manage Character Attributes",
	adminOnly = true,
	arguments = {
		ix.type.character
	},
	OnRun = function(self, client, target)
		local boosts = target:GetVar("boosts", {})

		for k, v in pairs(boosts) do
			local t = {}
			for k2, v2 in pairs(v) do
				table.insert(t, k2 .. " = " .. v2)
			end
			client:PrintMessage(HUD_PRINTTALK, string.format("%s: %s", k, table.concat(t, '; ')))
		end
	end
})
