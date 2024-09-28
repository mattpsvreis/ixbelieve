
local PLUGIN = PLUGIN

ix.config.Add("radioChatColour", Color(255, 255, 255), "Default chat color for this type of chat.", nil, {category = "chat"})
ix.config.Add("lrrChatColour", Color(255, 255, 255), "Default chat color for this type of chat.", nil, {category = "chat"})
ix.config.Add("broadcastChatColour", Color(255, 255, 255), "Default chat color for this type of chat.", nil, {category = "chat"})

do
	local CLASS = {}
	CLASS.format = "[BROADCAST] %s: %s"

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(ix.config.Get("broadcastChatColour", Color(255, 255, 255)), string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("broadcast", CLASS)
end

do
	local CLASS = {}

	function CLASS:CanSay(speaker, text)
		return true
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(ix.config.Get("lrrChatColour", Color(255, 255, 255)), text)
	end

	ix.chat.Register("LRR", CLASS)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text
	COMMAND.alias = {"mc", "mob"}
	COMMAND.adminOnly = true

	function COMMAND:OnRun(client, message)
	local listeners = {client}
	for k, v in ipairs(player.GetAll()) do
		if (v == client or !v:GetCharacter()) then continue end
		if (ix.radio:CharacterHasChannel(v:GetCharacter(), "lrr")) then
			listeners[#listeners + 1] = v
		end
	end

	if (#listeners == 1) then
		return "Nobody is listening to LRR!"
	end

		ix.chat.Send(client, "lrr", "[LRR] MOBCOM: \"" .. message.."\"", true, listeners)
	end

	ix.command.Add("MobCom", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text
	COMMAND.alias = {"hiroo", "basilone", "basi"}
	COMMAND.adminOnly = true

	function COMMAND:OnRun(client, message)
		local listeners = {client}
		for k, v in ipairs(player.GetAll()) do
			if (v == client or !v:GetCharacter()) then continue end
			if (ix.radio:CharacterHasChannel(v:GetCharacter(), "lrr")) then
				listeners[#listeners + 1] = v
			end
		end

		if (#listeners == 1) then
			return "Nobody is listening to LRR!"
		end

		ix.chat.Send(client, "lrr", "[LRR] ONODA: \"" .. message.."\"", true, listeners)
	end

	ix.command.Add("Onoda", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments =	{
		ix.type.string,
		ix.type.text
	}
	COMMAND.adminOnly = true

	function COMMAND:OnRun(client, name, message)
		local listeners = {client}
		for k, v in ipairs(player.GetAll()) do
			if (v == client or !v:GetCharacter()) then continue end
			if (ix.radio:CharacterHasChannel(v:GetCharacter(), "lrr")) then
				listeners[#listeners + 1] = v
			end
		end

		if (#listeners == 1) then
			return "Nobody is listening to LRR!"
		end

		ix.chat.Send(client, "lrr", "[LRR] "..name..": \"" .. message.."\"", true, listeners)
	end

	ix.command.Add("LRA", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text
	COMMAND.alias = "bc"

	function COMMAND:OnRun(client, message)
		if (!client:GetNetVar("restricted")) then
			local listeners = {client}
			for k, v in ipairs(player.GetAll()) do
				if (v == client or !v:GetCharacter()) then continue end
				if (v:GetCharacter():GetInventory():HasItemOfBase("base_radio_iff", {enabled = true})) then
					listeners[#listeners + 1] = v
				end
			end

			if (#listeners == 1) then
				return "Nobody has their radio turned on!"
			end

			ix.chat.Send(client, "broadcast", message, false, listeners)
		else
			return "@notNow"
		end
	end

	ix.command.Add("Broadcast", COMMAND)
end

if (SERVER) then
	concommand.Add("lra", function (ply, cmd, args)
		assert(ply == NULL)

		local listeners = {}
		for k, v in ipairs(player.GetAll()) do
			if (v == ply or !v:GetCharacter()) then continue end
			if (ix.radio:CharacterHasChannel(v:GetCharacter(), "lrr")) then
				listeners[#listeners + 1] = v
			end
		end

		if (#listeners == 0) then
			return
		end

		local name = args[1]
		table.remove(args, 1)
		ix.chat.Send(nil, "lrr", "[LRR] "..name..": \""..table.concat(args, " ").."\"", false, listeners)
	end)

	function PLUGIN:OnPlayerObserve(client, state)
		if (state) then
			ix.radio:AddListenerToChannel(client, "lrr")
		else
			ix.radio:RemoveListenerFromChannel(client, "lrr")
		end
	end
end

function PLUGIN:AdjustCharacterRadioChannels(character, channels)
	channels[#channels + 1] = "lrr"
end

function PLUGIN:HasCharacterRadioChannel(character, channelID)
	if (channelID != "lrr") then return end

	return true
end

if (SERVER) then
	function PLUGIN:CanPlayerSayRadio(speaker, text, data)
		if (data.channel != "lrr") then return end
		if (speaker:GetFactionVar("hasLRR") or (speaker:GetMoveType() == MOVETYPE_NOCLIP and !speaker:InVehicle())) then return end

		local character = speaker:GetCharacter()
		local inventory = character:GetInventory()
		if (!inventory:HasItem("lrr", {enabled = true})) then
			return false, "You need to have an LRR to speak on the LRR-channel!"
		end
	end
end