AddCSLuaFile()

ix.command.Add("RestartServer", {
	description = "Restarts the server",
	adminOnly = true,
	alias = "ServerRestart",
	OnRun = function(self, client)

		ix.util.Notify(string.format("%s restarted the server.", client:Name()))
		sstrp.workshop.forceRestart()

		for k, v in ipairs(player.GetAll()) do
			if (!v:IsConnected()) then
				v:Kick("The server is restarting - please reconnect in 30 seconds!")
			end
		end
	end
})
