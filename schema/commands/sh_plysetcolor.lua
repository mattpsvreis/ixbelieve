ix.command.Add("PlySetColor", {
	alias = { "setcolor", "color", "plysetcolour", "colour" },
	description = "Sets a player's colour",
	adminOnly = true,
	arguments = {
		ix.type.player,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, tgt, r, g, b)
		if r and g and b then
			tgt:SetTeamColor(Color(r, g, b))
			ix.util.NotifyCami(string.format("%s changed %s's color to [%i, %i, %i]", client:Name(), tgt:Name(), r, g, b), "Helix - PlySetColor", tgt)
		else
			tgt:SetTeamColor(nil)
			ix.util.NotifyCami(string.format("%s reset %s's color", client:Name(), tgt:Name()), "Helix - PlySetColor", tgt)
		end
	end
})
