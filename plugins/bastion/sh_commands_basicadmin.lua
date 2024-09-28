local ix = ix
local bit = bit
local IsValid = IsValid
local net = net
local ipairs = ipairs
local L = L
local player = player
local pairs = pairs
local string = string
local type = type
local Vector = Vector
local math = math
local CAMI = CAMI
local file = file
local timer = timer
local RunConsoleCommand = RunConsoleCommand
local ents = ents
local table = table
local netstream = netstream
local print = print
local Entity = Entity
local game = game
local BroadcastLua = BroadcastLua
local RunString = RunString

ix.command.Add("Admin", {
	alias = {"a"},
	description = "Sends a message to other admins",
	arguments = ix.type.text,
	adminOnly = true,
	OnRun = function(self, client, text)
		ix.chat.Send(client, "admin", text)
	end
})

ix.command.Add("AdminAnnounce", {
	description = "@cmdAnnounce",
	arguments = {
		ix.type.text
	},
	privilege = "Basic Admin Commands",
	OnRun = function(self, client, event)
		ix.chat.Send(client, "announcement", event)
	end,
	indicator = "chatTyping"
})

ix.command.Add("PlyGetInfo", {
	description = "Get someone's basic information and copy their SteamID.",
	arguments = {
		bit.bor(ix.type.player, ix.type.optional)
	},
	alias = "PGI",
	privilege = "Basic Admin Commands",
	OnRun = function(self, client, target)
		if (!target) then
			target = client:GetEyeTraceNoCursor().Entity
		end

		if (!IsValid(target) or !target:IsPlayer()) then
			client:NotifyLocalized("bastionPGIInvalidTarget")
			return
		end

		net.Start("ixPlayerInfo")
			net.WriteEntity(target)
		net.Send(client)
	end,
	bNoIndicator = true
})

ix.command.Add("PrintFactionList", {
	alias = "PFL",
	description = "Print a list of members of a faction currently online (including on another character).",
	arguments = {
		ix.type.string
	},
	privilege = "Basic Admin Commands",
	OnRun = function(self, client, name)
		if (name == "") then
			return "@invalidArg", 2
		end

		local faction = ix.faction.teams[name]

		if (!faction) then
			for _, v in ipairs(ix.faction.indices) do
				if (ix.util.StringMatches(L(v.name, client), name) or ix.util.StringMatches(v.uniqueID, name)) then
					faction = v

					break
				end
			end
		end

		if (faction) then
			local players = {}
			for _, v in ipairs(player.GetAll()) do
				if (v:HasWhitelist(faction.index)) then
					players[#players + 1] = v
				end
			end
			net.Start("ixStaffList")
				net.WriteUInt(1, 8)
				net.WriteString(faction.name)
				net.WriteUInt(#players, 8)
				for i = 1, #players do
					net.WriteEntity(players[i])
				end
			net.Send(client)
		else
			return "@invalidFaction"
		end
	end,
	bNoIndicator = true
})


ix.command.Add("Ammo", {
	description = "Give ammo to a player",
	privilege = "Basic Admin Commands",
	arguments = {
		ix.type.player,
		ix.type.number
	},
	OnRun = function(self, client, target, amount)
		for _, weapon in pairs(target:GetWeapons()) do
			target:GiveAmmo(amount, weapon:GetPrimaryAmmoType())
			target:GiveAmmo(amount, weapon:GetSecondaryAmmoType())
		end
		ix.util.NotifyCami(string.format("%s gave %s %i rounds of ammo", client:Name(), target:Name(), amount), "Helix - Basic Admin Commands", target)
	end
})

ix.command.Add("Armor", {
	alias = "armour",
	description = "Set a player's armour",
	privilege = "Basic Admin Commands",
	arguments = {
		ix.type.player,
		ix.type.number
	},
	OnRun = function(self, client, target, amount)
		target:SetArmor(amount)
		ix.util.NotifyCami(string.format("%s set %s's armor to %i", client:Name(), target:Name(), amount), "Helix - Basic Admin Commands", target)
	end
})

ix.command.Add("HP", {
	description = "Set a player's health",
	privilege = "Basic Admin Commands",
	arguments = {
		ix.type.player,
		bit.bor(ix.type.number, ix.type.optional),
	},
	OnRun = function(self, client, target, amount)
		if (!amount) then
			amount = target:GetMaxHealth()
		end

		if (amount == target:Health()) then
			return target:Name().." is already at max health."
		end

		target:SetHealth(amount)
		ix.util.NotifyCami(string.format("%s set %s's health to %i", client:Name(), target:Name(), amount), "Helix - Basic Admin Commands", target)
	end
})

ix.command.Add("Kick", {
	description = "Kick a player",
	adminOnly = true,
	arguments = {
		ix.type.player,
		bit.bor(ix.type.optional, ix.type.text)
	},
	OnRun = function(self, client, target, reason)
		target:Kick(reason)
		ix.util.NotifyCami(string.format("%s kicked %s (%s).", client:Name(), target:Name(), reason or "No reason specified"), "Helix - Kick")
	end
})

ix.command.Add("Bring", {
	description = "Bring a player",
	privilege = "Basic Admin Commands",
	acceptMulti = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		if type(target) == "table" then
			local text = string.format("%s brought multiple people to themself.", client:Name())
			local myPos = client:GetPos()

			local i = 0
			for k, tgt in pairs(target) do
				if tgt == client then continue end

				local pos = Vector(
					math.cos(math.rad(45 * (i-1))) * ((1 + math.floor(i/8)) * 64),
					math.sin(math.rad(45 * (i-1))) * ((1 + math.floor(i/8)) * 64),
					20
				)

				tgt.lastPos = tgt:GetPos()
				tgt:SetPos(myPos + pos)

				i = i + 1

				if (not CAMI.PlayerHasAccess(tgt, "Helix - Basic Admin Commands")) then
					ix.util.Notify(text, tgt)
				end
			end
			ix.util.NotifyCami(text, "Helix - Basic Admin Commands")
		else
			target.lastPos = target:GetPos()
			target:SetPos(client:GetPos() + (client:GetForward() * 64) + Vector(0, 0, 10))
			ix.util.NotifyCami(string.format("%s brought %s to themself.", client:Name(), target:Name()), "Helix - Basic Admin Commands", target)
		end
	end
})

ix.command.Add("SendTo", {
	description = "Send a player to another player",
	privilege = "Basic Admin Commands",
	acceptMulti = true,
	arguments = {
		ix.type.player,
		ix.type.player
	},
	OnRun = function(self, client, target, sendTo)
		if type(target) == "table" then
			local text = string.format("%s sent multiple people to %s.", client:Name(), sendTo:Name())
			local myPos = sendTo:GetPos()
			local i = 0
			for k, tgt in pairs(target) do
				if tgt == sendTo then continue end

				local pos = Vector(
					math.cos(math.rad(45 * (i-1))) * ((1 + math.floor(i/8)) * 64),
					math.sin(math.rad(45 * (i-1))) * ((1 + math.floor(i/8)) * 64),
					20
				)

				tgt.lastPos = tgt:GetPos()
				tgt:SetPos(myPos + pos)

				i = i + 1

				if (not CAMI.PlayerHasAccess(tgt, "Helix - Basic Admin Commands")) then
					ix.util.Notify(text, tgt)
				end
			end
			ix.util.NotifyCami(text, "Helix - Basic Admin Commands")
		else
			target.lastPos = target:GetPos()
			target:SetPos(sendTo:GetPos() + (sendTo:GetForward() * 64) + Vector(0, 0, 10))
			ix.util.NotifyCami(string.format("%s sent %s to %s.", client:Name(), target:Name(), sendTo:Name()), "Helix - Basic Admin Commands", target)
		end
	end
})


ix.command.Add("Return", {
	description = "Return a player to where they were before their last teleport",
	privilege = "Basic Admin Commands",
	acceptMulti = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		if type(target) == "table" then
			local text = string.format("%s returned multiple people where they were previously.", client:Name())
			for k, v in pairs(target) do
				if not v.lastPos then continue end
				v:SetPos(v.lastPos)
				v.lastPos = nil

				if (not CAMI.PlayerHasAccess(v, "Helix - Basic Admin Commands")) then
					ix.util.Notify(text, v)
				end
			end
			ix.util.NotifyCami(text, "Helix - Basic Admin Commands")
		else
			if not target.lastPos then
				ix.util.Notify("That player hasn't been teleported.", client)
				return
			end
			target:SetPos(target.lastPos)
			target.lastPos = nil
			ix.util.NotifyCami(string.format("%s returned %s to where they were previously.", client:Name(), target:Name()), "Helix - Basic Admin Commands", target)
		end
	end
})

ix.command.Add("Goto", {
	description = "Go to a player",
	privilege = "Basic Admin Commands",
	noMulti = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		client.lastPos = client:GetPos()

		client:SetPos(target:GetPos() - (target:GetForward() * 64))
		ix.util.NotifyCami(string.format("%s teleported to %s.", client:Name(), target:Name()), "Helix - Basic Admin Commands", target)
	end
})

ix.command.Add("Respawn", {
	description = "Respawn a player",
	privilege = "Basic Admin Commands",
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		target:Spawn()
		ix.util.NotifyCami(string.format("%s respawned %s.", client:Name(), target:Name()), "Helix - Basic Admin Commands", target)
	end
})

ix.command.Add("Slay", {
	description = "Slay a player",
	adminOnly = true,
	bContextMenu = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		target:Kill()
		ix.util.NotifyCami(string.format("%s slayed %s.", client:Name(), target:Name()), "Helix - Slay", target)
	end
})

ix.command.Add("Freeze", {
	description = "Freeze a player",
	privilege = "Basic Admin Commands",
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		target:Freeze(true)
		ix.util.NotifyCami(string.format("%s froze %s.", client:Name(), target:Name()), "Helix - Basic Admin Commands", target)
	end
})

ix.command.Add("UnFreeze", {
	description = "Unfreeze a player",
	privilege = "Basic Admin Commands",
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		target:Freeze(false)

		if (target:GetMoveType() == MOVETYPE_NONE) then
			target:SetMoveType(MOVETYPE_WALK)
		end

		ix.util.NotifyCami(string.format("%s unfroze %s.", client:Name(), target:Name()), "Helix - Basic Admin Commands", target)
	end
})

ix.command.Add("PlaySound", {
	description = "Play a sound for all players (when no range is given) or those near you.",
	arguments = {
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	},
	privilege = "Basic Admin Commands",
	OnRun = function(self, client, sound, range)
		local targets = range and {} or player.GetAll()
		if (range) then
			range = range * range
			local clientPos = client:EyePos()
			for _, target in ipairs(player.GetAll()) do
				if (target:EyePos():DistToSqr(clientPos) < range) then
					targets[#targets + 1] = target
				end
			end
		end

		net.Start("ixPlaySound")
			net.WriteString(PLUGIN.soundAlias[sound] or sound)
		net.Send(targets)
	end,
	indicator = "chatPerforming"
})

ix.command.Add("PlaySoundGlobal", {
	description = "Play a sound for all players.",
	arguments = {
		ix.type.string,
	},
	privilege = "Basic Admin Commands",
	OnRun = function(self, client, sound)
		net.Start("ixPlaySound")
			net.WriteString(PLUGIN.soundAlias[sound] or sound)
			net.WriteBool(true)
		net.Send(player.GetAll())
	end,
	indicator = "chatPerforming"
})

ix.command.Add("Map", {
	description = "Change the map",
	adminOnly = true,
	arguments = {
		ix.type.string
	},
	OnRun = function(self, client, map)
		map = string.lower(map)
		if (file.Exists("maps/" .. map .. ".bsp", "GAME")) then
			ix.util.Notify(string.format("%s is changing the map to %s", client:Name(), map))
			client:PrintMessage(HUD_PRINTTALK, "REMEMBER TO LOG THE MISSION IN THE MISSION LOG.")
			client:PrintMessage(HUD_PRINTTALK, "REMEMBER TO LOG THE MISSION IN THE MISSION LOG.")
			client:PrintMessage(HUD_PRINTTALK, "REMEMBER TO LOG THE MISSION IN THE MISSION LOG.")
			client:PrintMessage(HUD_PRINTTALK, "REMEMBER TO LOG THE MISSION IN THE MISSION LOG.")
			client:PrintMessage(HUD_PRINTTALK, "REMEMBER TO LOG THE MISSION IN THE MISSION LOG.")
			timer.Simple(3.0, function () RunConsoleCommand("changelevel", map) end)
		else
			ix.util.Notify("Map not found.", client)
		end
	end
})

ix.command.Add("MapList", {
	alias = "ListMaps",
	description = "List all the maps on the server",
	privilege = "Basic Admin Commands",
	arguments = {
		bit.bor(ix.type.string, ix.type.optional)
	},
	OnRun = function(self, client, map)
		map = map or ""
		local files = file.Find("maps/*.bsp", "GAME", "nameasc")
		for k, v in pairs(files) do
			if string.find(v, map, nil, true) then
				client:PrintMessage(HUD_PRINTTALK, string.Replace(v, ".bsp"))
			end
		end
	end
})

ix.command.Add("ShowEdicts", {
	description = "Returns the amount of networked entities currently on the server.",
	privilege = "Basic Admin Commands",
	OnRun = function(self, client)
		local edictsCount = ents.GetEdictCount()
		local edictsLeft = 8192 - edictsCount

		return string.format("There are currently %s edicts on the server. You can have up to %s more.", edictsCount, edictsLeft)
	end,
	bNoIndicator = true
})

ix.command.Add("ShowEntsInRadius", {
	description = "Shows a list of entities within a given radius.",
	privilege = "Basic Admin Commands",
	arguments = {ix.type.number},
	OnRun = function(self, client, radius)
		local entities = {}
		local pos = client:GetPos()
		for _, v in pairs(ents.FindInSphere(pos, radius)) do
			if (!IsValid(v)) then continue end
			entities[#entities + 1] = table.concat({v:EntIndex(), v:GetClass(), v:GetModel() or "no model", v:GetPos():Distance(pos), v:MapCreationID()}, ", ")
		end
		netstream.Start(client, "ixShowEntsInRadius", table.concat(entities,"\n"))
		client:NotifyLocalized("entsPrintedInConsole")
	end,
	bNoIndicator = true,
})

if (CLIENT) then
	netstream.Hook("ixShowEntsInRadius", function(text)
		print(text)
	end)
end

ix.command.Add("EntGetName", {
	description = "Gets the entity you are looking at's targetname",
	privilege = "Basic Admin Commands",
	arguments = {},
	OnRun = function(self, client)
		local tr = client:GetEyeTrace()
		if not tr.Hit or not tr.Entity then
			return "You're not looking at an entity."
		end
		client:PrintMessage(HUD_PRINTTALK, string.format("%s [%i]", tr.Entity:GetName() or "null", tr.Entity:MapCreationID()))
	end
})

ix.command.Add("RemoveEntityByID", {
	description = "Shows a list of entities within a given radius.",
	superAdminOnly = true,
	arguments = {ix.type.number},
	OnRun = function(self, client, number)
		local entity = Entity(number)
		if (IsValid(entity)) then
			client:NotifyLocalized("entityRemoved", number, entity:GetClass())
			entity:Remove()
		else
			client:NotifyLocalized("entityNotFound", number)
		end
	end,
	bNoIndicator = true,
})

ix.command.Add("RCon", {
	description = "Allows admins to run RCON commands",
	adminOnly = true,
	arguments =
	{
		ix.type.text
	},
	OnRun = function(self, client, cmd)
		game.ConsoleCommand(cmd .. "\n")
		ix.util.NotifyCami(string.format("%s ran RCON command: %s", client:Name(), cmd), "Helix - RCon")
	end
})

ix.command.Add("ClearRagdolls", {
	description = "Clears all ragdolls on the map.",
	privilege = "Basic Admin Commands",
	arguments = {},
	OnRun = function(self, client)
		BroadcastLua([[game.RemoveRagdolls()]])
		ix.util.NotifyCami(string.format("%s cleared all clientside ragdolls", client:Name()), "Helix - Basic Admin Commands")
	end
})

ix.command.Add("ClearDecals", {
	description = "Clears all ragdolls on the map.",
	privilege = "Basic Admin Commands",
	arguments = {},
	OnRun = function(self, client)
		client:ConCommand("r_cleardecals")
		ix.util.NotifyCami(string.format("%s cleared all decals", client:Name()), "Helix - Basic Admin Commands")
	end
})

ix.command.Add("GetPos", {
	description = "Prints your current position and rotation.",
	privilege = "Basic Admin Commands",
	arguments = {},
	OnRun = function(self, client)
		client:PrintMessage(HUD_PRINTTALK, string.format("(%f, %f, %f)\t\t%s", client:GetPos().x,  client:GetPos().y, client:GetPos().z, client:GetAngles()))
	end
})

ix.command.Add("Lua", {
	description = "Runs Lua on all players.",
	privilege = "Run Lua",
	arguments = {ix.type.text},
	OnRun = function(self, client, lua)
		BroadcastLua(lua)
		ix.util.NotifyCami(string.format("%s ran Lua on all clients: %s", client:Name(), lua), "Helix - Run Lua")
	end
})

ix.command.Add("SLua", {
	description = "Runs Lua on the server.",
	privilege = "Run Lua",
	arguments = {ix.type.text},
	OnRun = function(self, client, lua)
		local msg = RunString(
		[[
			me = Entity(]] .. client:EntIndex() .. [[)
		]] .. lua, "slua", false)

		client:PrintMessage(HUD_PRINTTALK, msg or "Lua executed")

		ix.util.NotifyCami(string.format("%s ran Lua on the server: %s", client:Name(), lua), "Helix - Run Lua")
	end
})

ix.command.Add("MP3", {
	description = "Plays a URL MP3.",
	adminOnly = true,
	arguments = {ix.type.text},
	OnRun = function(self, client, url)
		BroadcastLua([[sound.PlayURL("]] .. url .. [[", "", function () end)]], "mp3", false)
		ix.util.NotifyCami(string.format("%s played %s", client:Name(), url), "Helix - MP3")
	end
})
