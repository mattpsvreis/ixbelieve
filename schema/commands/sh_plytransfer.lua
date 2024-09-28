AddCSLuaFile()

ix.command.Add("PlyTransfer", {
	alias = "transfer",
	description = "@cmdPlyTransfer",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.text
	},
	OnRun = function(self, client, target, name)
		local faction = ix.faction.teams[name]

		if (!faction) then
			for _, v in pairs(ix.faction.indices) do
				if (ix.util.StringMatches(L(v.name, client), name)) then
					faction = v

					break
				end
			end
		end

		if (faction) then
			local _, oldRankInfo = target:GetRank()

			target.vars.faction = faction.uniqueID
			target:SetFaction(faction.index)
			target:GetPlayer():SetWhitelisted(faction.index, true)

			if (faction.OnTransferred) then
				faction:OnTransferred(target)
			end

			local _, newRankInfo = target:GetRank()
			if (oldRankInfo and !newRankInfo and faction.defaultRank) then
				local charName = string.Explode(" ", target:GetName())
				if (string.lower(charName[1]) == oldRankInfo.lowerName) then
					charName[1] = faction.defaultRank
					target:SetName(table.concat(charName, " "))
				end
			end

			for _, v in ipairs(player.GetAll()) do
				v:NotifyLocalized("cChangeFaction", client:GetName(), target:GetName(), L(faction.name, v))
			end

			DiscordNotify(client, target, faction.name)
		else
			return "@invalidFaction"
		end
	end
})
