AddCSLuaFile()

ix.command.Add("ToggleGravity", {
	description = "Toggle another player's gravity.",
	adminOnly = true,
	arguments = {
		ix.type.player,
		bit.bor(ix.type.bool, ix.type.optional)
	},
	OnRun = function(self, client, target, toggle)
		target = target or client

		local state = target:GetMoveType() == MOVETYPE_FLY
		toggle = toggle or !state

		if (toggle) then
			target:SetMoveType(MOVETYPE_FLY)
			ix.util.NotifyCami(string.format("%s disabled gravity for %s.", client:Name(), target:Name()), "Helix - ToggleGravity", target)
		else
			target:SetMoveType(MOVETYPE_WALK)
			ix.util.NotifyCami(string.format("%s enabled gravity for %s.", client:Name(), target:Name()), "Helix - ToggleGravity", target)
		end

	end
})
