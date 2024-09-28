AddCSLuaFile()

ix.command.Add("entinfo", {
	description = "Get details about an entity",
	adminOnly = true,
	arguments = {},
	OnRun = function(self, ply)

		local trace = ply:GetEyeTrace()
		local targ = trace.Entity

		if IsValid( targ ) then

			ply:PrintMessage(HUD_PRINTTALK, string.format("Class: %s:\nTargetname: %s\nMap creation ID: %s", targ:GetClass(), targ:GetName() or 'n/a', targ:MapCreationID() ~= -1 and tostring(targ:MapCreationID()) or 'n/a'))
			return

		end

		ix.util.Notify("Invalid target specified", ply)
	end
})

ix.command.Add("settargetname", {
	description = "Set the target name of an entity",
	adminOnly = true,
	arguments = {ix.type.string},
	OnRun = function(self, ply, targetname)

		local trace = ply:GetEyeTrace()
		local targ = trace.Entity

		if IsValid( targ ) then

			target:SetName(targetname)
			return

		end

		ix.util.Notify("Invalid target specified", ply)
	end
})
