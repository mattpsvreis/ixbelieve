AddCSLuaFile()

ix.command.Add("CharSetBoost", {
	description = "Set a character's boost",
	privilege = "Manage Character Attributes",
	arguments = {
		ix.type.character,
		ix.type.string,
		ix.type.string,
		ix.type.number
	},
	OnRun = function(self, client, target, attributeName, boostName, level)
		for k, v in pairs(ix.attributes.list) do
			if (ix.util.StringMatches(L(v.name, client), attributeName) or ix.util.StringMatches(k, attributeName)) then
				if level ~= 0 then
					target:AddBoost(boostName, k, level)
				else
					target:RemoveBoost(boostName, k)
				end
				ix.util.NotifyCami(string.format("%s set %s's %s boost to %.3f", client:Name(), target:GetPlayer():Name(), k, level), "Helix - Manage Character Attributes", target:GetPlayer())
				return true
			end
		end

		return "@attributeNotFound"
	end
})
