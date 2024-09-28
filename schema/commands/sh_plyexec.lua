AddCSLuaFile()

ix.command.Add("PlyExec", {
	alias = "exec",
	description = "Force a player to execute a command",
	superAdminOnly = true,
	arguments = {
		ix.type.player,
		ix.type.text
	},
	OnRun = function(self, client, target, command)
		command = string.Replace(command, "'", "\"")
		target:ConCommand(command)

		return true
	end
})

ix.command.Add("PlyExecAll", {
	alias = "execall",
	description = "Force all players to execute a command",
	superAdminOnly = true,
	arguments = {
		ix.type.text
	},
	OnRun = function(self, client, command)
		command = string.Replace(command, "'", "\"")
		for k, target in pairs(player.GetAll()) do
			target:ConCommand(command)
		end
		return true
	end
})
