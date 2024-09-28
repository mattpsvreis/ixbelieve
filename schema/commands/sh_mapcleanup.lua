AddCSLuaFile()

ix.command.Add("MapCleanup", {
	description = "Resets the map.",
	superAdminOnly = true,
	OnRun = function(self, client)

		game.CleanUpMap()
		ix.util.NotifyCami(string.format("%s cleared the map.", client:Name()), "Helix - MapCleanup")

	end,
})
