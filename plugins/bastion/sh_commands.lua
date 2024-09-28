local bit = bit
local IsValid = IsValid
local pairs = pairs
local math = math
local Vector = Vector
local game = game
local RunConsoleCommand = RunConsoleCommand
local net = net
local player = player
local ipairs = ipairs
local string = string
local timer = timer
local ix = ix

local PLUGIN = PLUGIN

ix.command.Add("Discord", {
	description = "Get a link to the Discord Server",
	privilege = "Basic Commands",
	OnRun = function(self, client)
		net.Start("ixOpenURL")
			net.WriteString(ix.config.Get("DiscordLink"))
		net.Send(client)
	end,
	bNoIndicator = true
})

ix.command.Add("Content", {
	description = "Get a link to theWorkshop Content Pack",
	privilege = "Basic Commands",
	OnRun = function(self, client)
		net.Start("ixOpenURL")
			net.WriteString(ix.config.Get("ContentLink"))
		net.Send(client)
	end
})

ix.command.Add("Forum", {
	description = "Get a link to the Forums",
	privilege = "Basic Commands",
	OnRun = function(self, client)
		net.Start("ixOpenURL")
			net.WriteString(ix.config.Get("ForumLink"))
		net.Send(client)
	end,
	bNoIndicator = true
})


ix.command.Add("Report", {
	description = "Sends a message to the admin team.",
	privilege = "Basic Commands",
	arguments = ix.type.text,
	OnRun = function(self, client, text)
		ix.chat.Send(client, "report", text)

		for k, v in pairs(player.GetAll()) do
			if (CAMI.PlayerHasAccess(v, "Helix - Admin")) then
				v.ixLastPM = client
			end
		end
	end
})

ix.command.Add("Reply", {
	description = "@cmdReply",
	privilege = "Basic Commands",
	alias = "rep",
	arguments = ix.type.text,
	OnRun = function(self, client, message)
		local target = client.ixLastPM

		if (IsValid(target) and (client.ixNextPM or 0) < CurTime()) then
			ix.chat.Send(client, "pm", message, false, {client, target}, {target = target})
			client.ixNextPM = CurTime() + 0.5
		end
	end
})

ix.command.Add("Achievement", {
	description = "Someone has earned a special achievement!",
	arguments = {
		ix.type.player,
		ix.type.text
	},
	privilege = "Fun Stuff",
	OnRun = function(self, client, target, text)
		ix.chat.Send(client, "achievement_get", text, false, nil,
		{target, "ambient/water/drip" .. math.random( 1, 4 ) .. ".wav"})
	end,
	indicator = "chatTyping"
})

ix.command.Add("DarwinAward", {
	description = "Someone has earned an achievement: he has made the ultimate sacrifice to increase humanity's average IQ.",
	arguments = {
		ix.type.player
	},
	privilege = "Fun Stuff",
	OnRun = function(self, client, target)
		if (!target:Alive()) then
			local pos = target:GetPos()
			target:Spawn()

			target:SetPos(pos)
		end
		target:SetMoveType(MOVETYPE_WALK)
		target:SetVelocity(Vector(0, 0, 4000))

		timer.Simple(1, function() PLUGIN:Explode(target) end)
		ix.chat.Send(client, "achievement_get", "DARWIN AWARD", false, nil,
		{target, "ambient/alarms/razortrain_horn1.wav"})
	end,
	indicator = "chatTyping"
})

ix.command.Add("PlyRocket", {
	description = "To infinity, and beyond!.",
	arguments = {
		ix.type.player
	},
	privilege = "Fun Stuff",
	OnRun = function(self, client, target)
		if (!target:Alive()) then
			local pos = target:GetPos()
			target:Spawn()

			target:SetPos(pos)
		end
		target:SetMoveType(MOVETYPE_WALK)
		target:SetVelocity(Vector(0, 0, 4000))

		timer.Simple(1, function() PLUGIN:Explode(target) end)
	end,
	bNoIndicator = true
})

ix.command.Add("SetTimeScale", {
	description = "@cmdTimeScale",
	arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	},
	privilege = "Fun Stuff",
	OnRun = function(self, client, number)
		local scale = math.Clamp(number or 1, 0.001, 5)
		local cheats = GetConVar("sv_cheats")
		if (cheats) then
			if (scale == 1 and cheats:GetBool()) then
				cheats:SetInt(0)
			elseif (scale != 1 and !cheats:GetBool()) then
				cheats:SetInt(1)
			end
		end
		game.SetTimeScale(scale)

		for _, v in ipairs(player.GetAll()) do
			if (self:OnCheckAccess(v)) then
				v:NotifyLocalized("bastionTimeScale", client:Name(), scale)
			end
		end
	end,
	bNoIndicator = true
})

ix.command.Add("SetGravity", {
	description = "@cmdGravity",
	arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	},
	privilege = "Fun Stuff",
	OnRun = function(self, client, number)
		RunConsoleCommand("sv_gravity", number)

		for _, v in ipairs(player.GetAll()) do
			if (self:OnCheckAccess(v)) then
				v:NotifyLocalized("bastionGravity", client:Name(), number)
			end
		end
	end,
	bNoIndicator = true
})

-- lookup commands
ix.command.Add("LookupSteamID", {
	description = "Lookup a SteamID in the Bastion user database",
	arguments = {
		ix.type.text
	},
	privilege = "Bastion Lookup",
	OnRun = function(self, client, target)
		if (string.find(target, "^STEAM_%d+:%d+:%d+$")) then
			PLUGIN:LookupSteamID(client, target)
			return
		elseif (string.len(target) == 17 and string.find(target, "^%d+$")) then
			PLUGIN:LookupSteamID(client, target)
			return
		end

		target = ix.util.FindPlayer(target, false)
		client:NotifyLocalized("bastionTargetSelected", target:Name())

		PLUGIN:LookupSteamID(client, target:SteamID64())
	end,
	bNoIndicator = true
})

ix.command.Add("LookupIPUsers", {
	description = "Lookup a SteamID in the Bastion IP database",
	arguments = {
		ix.type.text
	},
	privilege = "Bastion Lookup",
	OnRun = function(self, client, target)
		if (string.find(target, "^STEAM_%d+:%d+:%d+$")) then
			PLUGIN:LookupIPUsers(client, target)
			return
		elseif (string.len(target) == 17 and string.find(target, "^%d+$")) then
			PLUGIN:LookupIPUsers(client, target)
			return
		end

		target = ix.util.FindPlayer(target, false)
		client:NotifyLocalized("bastionTargetSelected", target:Name())

		PLUGIN:LookupIPUsers(client, target:SteamID64())
	end,
	bNoIndicator = true
})

ix.command.Add("PlyGetCharacters", {
	description = "Get a list of a player's characters.",
	arguments = {
		ix.type.player
	},
	adminOnly = true,
	bContextMenu = true,
	OnRun = function(self, client, target)
		client:ChatNotify(target:SteamName() .. "'s characters:")
		client:ChatNotify("====================")

		for _, character in pairs(target.ixCharList) do
			client:ChatNotify(ix.char.loaded[character].vars.name)
		end
	end
})
