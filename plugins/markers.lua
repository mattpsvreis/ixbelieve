local PLUGIN = PLUGIN
PLUGIN.name = "Markers"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Integrates markers into Helix."

CAMI.RegisterPrivilege({
	Name = "Helix - Manage Markers",
	MinAccess = "admin",
	Description = "Access to add and remove compass markers."
})
ix.command.Add("AddMarker", {
	alias = "Marker",
	privilege = "Manage Markers",
	description = "Adds a compass marker at where or what you are aiming at.",
	arguments = {
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, r, g, b)
		duration = 99999
		r = r or 255
		g = g or 255
		b = b or 255
		a = 128

		local color = Color(r, g, b, a)
		local tr = util.TraceLine( {
			start = client:EyePos(),
			endpos = client:EyePos() + client:EyeAngles():Forward() * 99999,
			filter = client
		} )

		if tr.Entity && !tr.HitWorld then
			id = Adv_Compass_AddMarker( true, tr.Entity, CurTime() + duration, color )
		else
			id = Adv_Compass_AddMarker( false, tr.HitPos, CurTime() + duration, color )
		end

		ix.util.NotifyCami(string.format("%s put down a marker [%i, %i, %i].", client:Name(), r, g, b), "Helix - Manage Markers", client)
	end
})

ix.command.Add("ClearMarkers", {
	description = "Clears all compass markers.",
	privilege = "Manage Markers",
	arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, distance)
		local scandist = 99999
		if distance then
			scandist = distance / 0.01905
		end

		for k, v in pairs(mCompass_MarkerTable) do
			local pos = v[1]
			if IsEntity(pos) then
				pos = pos:GetPos()
			end

			if (pos:Distance(client:GetPos()) < scandist) then
				local markerid = v[4]
				Adv_Compass_RemoveMarker(markerid)
			end
		end

		if (!distance) then
			ix.util.NotifyCami(string.format("%s cleared all markers.", client:Name()), "Helix - Manage Markers", client)
		else
			ix.util.NotifyCami(string.format("%s cleared all markers within %.1fm of them.", client:Name(), distance), "Helix - Manage Markers", client)
		end
	end
})
