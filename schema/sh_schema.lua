
-- The shared init file. You'll want to fill out the info for your schema and include any other files that you need.

-- Schema info
Schema.name = "Halo: Believe"
Schema.author = "Dark"
Schema.description = "Halo: Believe is a schema for Halo Marines based on the Helix framework."

ix.util.Include("cl_fonts.lua")
ix.util.Include("cl_schema.lua")
ix.util.Include("sv_schema.lua")

ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sv_hooks.lua")

ix.util.Include("sh_classes.lua")

ix.util.Include("meta/sh_character.lua")
ix.util.Include("meta/sh_player.lua")

ix.util.IncludeDir("commands")

ix.currency.symbol = "£"
ix.currency.singular = "Credit"
ix.currency.plural = "Credits"

ix.config.Add("DeleteNPCWeaponOnDeath", true, "Whether or not NPC weapons should be deleted on death (instead of dropped on the ground).", nil, {category = "Halo: Believe"})
ix.config.Add("HomeMap", "gm_flatgrass", "The 'home' map that we use for passive RP.", nil, {
	category = "Game"
})

ix.char.RegisterVar("npcKills", {
	field = "npc_kills",
	fieldType = ix.type.number,
	default = 0,
	bNoDisplay = true,
    isLocal = true
})

ix.char.vars["lastJoinTime"].bNoNetworking = false

CAMI.RegisterPrivilege({
	Name = "Helix - Give Admin Weapons",
	MinAccess = "admin",
	Description = "Gives the 'Godhand' and 'Kanye West' admin SWEPs"
})
CAMI.RegisterPrivilege({
	Name = "SSTRP - Change Addons",
	MinAccess = "admin",
	Description = "Allow to mount/unmount addons."
})


ix.config.Add("timescale", 1, "The timescale to run the server at.", function(oldValue, newValue)
		if (!SERVER) then return end

		local cheats = GetConVar("sv_cheats")
		if (cheats) then
			if (newValue == 1 and cheats:GetBool()) then
				cheats:SetInt(0)
			elseif (newValue != 1 and !cheats:GetBool()) then
				cheats:SetInt(1)
			end
		end
		game.SetTimeScale(newValue)
	end, {
	data = {min = 0.001, max = 5},
	category = "Game"
})

hook.Add("EntityEmitSound", "Believe_TimeScale", function (t)
	local p = t.Pitch

	if ( game.GetTimeScale() ~= 1 ) then
		p = p * game.GetTimeScale()
		return true
	end
end)

ix.command.Add("GetSequences", {
	description = "Get a list of sequences for the entity you are looking at",
	superAdminOnly = true,
	arguments = {
		bit.bor(ix.type.string),
		bit.bor(ix.type.number, ix.type.optional),
	},
	OnRun = function(self, client, text, seq)
		local x = ents.Create("prop_dynamic")
		x:SetModel(text)

		client:PrintMessage(HUD_PRINTCONSOLE, x:GetModel())
		if not seq then
			local t = {}
			for k, v in pairs(x:GetSequenceList()) do
				local info = x:GetSequenceInfo(k)
				info.id = k
				info.seq = v
				table.insert(t, info)
			end
			table.SortByMember(t, "activity", true)

			for k, v in pairs(t) do
				client:PrintMessage(HUD_PRINTCONSOLE, string.format("%i: %s [%s]", v.id, v.seq, v.activityname or v.activity))
			end

			client:PrintMessage(HUD_PRINTCONSOLE, "")
			client:PrintMessage(HUD_PRINTCONSOLE, "POSE PARAMETERS -")
			for i=0, x:GetNumPoseParameters(), 1 do
				client:PrintMessage(HUD_PRINTCONSOLE, string.format("%i: %s <%.2f-%.2f>", i, x:GetPoseParameterName(i), x:GetPoseParameterRange(i)))
			end

		else

			client:PrintMessage(HUD_PRINTCONSOLE, x:GetModel() .. " [" .. seq .. "]")
			for k, v in pairs(x:GetSequenceInfo(seq)) do
				if k == "anims" then
					local t = {}
					for k2, v2 in pairs(v) do
						local t2 = {}
						for k3, v3 in pairs(x:GetAnimInfo(v2)) do
							t2[k3] = k3 .. " => " .. tostring(v3)
						end
						t[k2] = x:GetAnimInfo(v2).label .. " [" .. tostring(v2) .. "] {" .. table.concat(t2, ", ") .. "}"
					end

					client:PrintMessage(HUD_PRINTCONSOLE, k .. ": {" .. table.concat(t, ", ") .. "}")
				elseif type(v) == "table" then
					local t = {}
					for k2, v2 in pairs(v) do
						t[k2] = tostring(v2)
					end

					client:PrintMessage(HUD_PRINTCONSOLE, k .. ": {" .. table.concat(t, ", ") .. "}")
				else
					client:PrintMessage(HUD_PRINTCONSOLE, k .. ": " .. tostring(v))
				end
			end

		end


		x:Remove()
	end
})
