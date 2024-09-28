AddCSLuaFile()

CAMI.RegisterPrivilege({
	Name = "Helix - Shake",
	MinAccess = "admin",
	Description = "Allows to start and stop client-side screenshake."
})
ix.command.Add("Shake", {
	description = "Shakes the screen of players.",
	privilege = "Shake",
	arguments = {
		ix.type.number,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
	},
	OnRun = function(self, ply, amplitude, duration, frequency, radius)
		frequency = frequency or 5
		radius = radius or 999999999
		local pos = ply:GetPos()

		if timer.Exists("Believe_ShakeTimer") then
			timer.Remove("Believe_ShakeTimer")
		end

		util.ScreenShake( pos, amplitude, frequency, 5, radius )

		if duration == nil then
			timer.Create("Believe_ShakeTimer", 1, 0, function () util.ScreenShake( pos, amplitude, frequency, 5, radius ) end)
		else
			duration = duration - 1

			if (duration > 0) then
				timer.Create("Believe_ShakeTimer", 1, 0, function () util.ScreenShake( pos, amplitude, frequency, 5, radius ) end)
			end
		end

		ix.util.NotifyCami(string.format("%s set a tremor [amp: %i, freq: %i, radius: %i]", ply:Name(), amplitude, frequency, radius), "Helix - Shake")
	end
})

ix.command.Add("StopShake", {
	description = "Stops shaking the screen of players.",
	privilege = "Shake",
	arguments = {},
	OnRun = function(self, ply)
		if timer.Exists("Believe_ShakeTimer") then
			timer.Remove("Believe_ShakeTimer")
		end

		ix.util.NotifyCami(string.format("%s disabled off the tremor", ply:Name()), "Helix - Shake")
	end
})
