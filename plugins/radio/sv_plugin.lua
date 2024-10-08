
local ipairs = ipairs
local IsValid = IsValid
local table = table

util.AddNetworkString("ixRadioChannels")

function ix.radio:SayOnRadio(speaker, text, radioType, channelID)
    if (!speaker:Alive() or speaker:IsRestricted() or !speaker:GetCharacter()) then
        speaker:NotifyLocalized("notNow")
        return
    end

	local entity = speaker:GetEyeTraceNoCursor().Entity
	local data = {radioType = radioType, channel = channelID}

	if (!channelID and IsValid(entity) and entity:GetClass() == "ix_item") then
		local item = ix.item.instances[entity.ixItemID]
		if (item and item.isRadio) then
			if (!item:GetData("enabled")) then
				speaker:NotifyLocalized("radioNotOn")
				return
			end

			local range = radioType == self.types.whisper and math.pow(ix.config.Get("chatRange", 280) * 0.25, 2) or 10000
			if (entity:GetPos():DistToSqr(speaker:EyePos()) < range) then
				data.channel = item:GetChannel()
				data.stationary = true
			else
				speaker:NotifyLocalized("radioTooFar")
				return
			end
		end
	end

	if (!data.channel) then
		data.channel = speaker:GetCharacter():GetRadioChannel()
	end

    local result, reason = hook.Run("CanPlayerSayRadio", speaker, text, data)
    if (result != nil) then
        if (reason) then
            speaker:Notify(reason)
        end

        return result
    end

	local channel = self:FindByID(data.channel)
	if (!channel) then
		speaker:Notify("radioInvalidChannel")
		return
	end

	if (radioType == self.types.yell) then
		local filtered = string.gsub(text, "[^%a]", "")
		local length = string.len(filtered)
		local capsLength = string.len(string.gsub(filtered, "[^%u]", ""))

		if (capsLength / length > 0.9 and length >= 15) then
			radioType = self.types.scream
			data.radioType = radioType
		end
	end

	local range = ix.config.Get("chatRange", 280)
	if (radioType == self.types.whisper) then
		range = range * 0.5
	elseif (radioType >= self.types.yell) then
		range = range * 2
	end
	range = range * range

	local bStationaries = #channel.stationaries > 0
	local listeners = bStationaries and table.Copy(channel.listeners) or channel.listeners
	local eavesdrop = speaker:GetMoveType() != MOVETYPE_NOCLIP and {}
	local yellEavesDrop = radioType >= self.types.yell and {}

	local speakerEyePos = speaker:EyePos()
	for _, client in ipairs(player.GetAll()) do
		if (!client:Alive()) then
			continue
		end

		if (channel.listenersByKeys[client]) then
			continue
		end

		local clientEyePos = client:EyePos()
		if (bStationaries) then
			local bFound = false
			for i = #channel.stationaries, 1, -1 do
				local stationary = channel.stationaries[i]
				if (!IsValid(stationary)) then
					table.remove(channel.stationaries, i)
					continue
				end

				if (stationary:GetPos():DistToSqr(clientEyePos) <= range) then
					bFound = true
					listeners[#listeners + 1] = client
					break
				end
			end

			if (bFound) then continue end
		end

		if (eavesdrop and speakerEyePos:DistToSqr(clientEyePos) <= range) then
			eavesdrop[#eavesdrop + 1] = client
			continue
		end

		if (eavesdrop and client:GetNetVar("SenserViewPos") and speakerEyePos:DistToSqr(client:GetNetVar("SenserViewPos")) <= range) then
			eavesdrop[#eavesdrop + 1] = client
			continue
		end

		if (yellEavesDrop) then
			for _, listener in ipairs(channel.listeners) do
				if (listener:GetMoveType() == MOVETYPE_NOCLIP and !listener:InVehicle()) then continue end

				if (clientEyePos:DistToSqr(listener:EyePos()) <= range / 8) then
					yellEavesDrop[#yellEavesDrop + 1] = client
					continue
				end
			end
		end
	end

	ix.chat.Send(speaker, "radio", text, false, listeners, data)

	if (eavesdrop and #eavesdrop > 0) then
		ix.chat.Send(speaker, "radio_eavesdrop", text, false, eavesdrop, data)
	end

	if (yellEavesDrop and #yellEavesDrop > 0) then
		ix.chat.Send(speaker, "radio_eavesdrop_yell", text, false, yellEavesDrop, data)
	end
end

function ix.radio:AddListenerToChannel(client, channelID)
	local channel = self:FindByID(channelID)
	if (channel and !channel.listenersByKeys[client] and self:CharacterHasChannel(client:GetCharacter(), channelID)) then
		channel.listeners[#channel.listeners + 1] = client
		channel.listenersByKeys[client] = #channel.listeners

		local clientChannels = client:GetLocalVar("radioChannels", {})
		clientChannels[channel.uniqueID] = true
		client:SetLocalVar("radioChannels", clientChannels)

		if (!self:FindByID(client:GetCharacter():GetRadioChannel())) then
			client:GetCharacter():SetRadioChannel(channelID)
		end
	end
end

function ix.radio:RemoveListenerFromChannel(client, channelID)
	local channel = self:FindByID(channelID)
	if (channel and channel.listenersByKeys[client] and !self:CharacterHasChannel(client:GetCharacter(), channel.uniqueID)) then
		-- Move last listeners into client's slot, overwrite client to remove
		local key = channel.listenersByKeys[client]
		channel.listeners[key] = channel.listeners[#channel.listeners]
		-- Update key of moved client
		channel.listenersByKeys[channel.listeners[key]] = key

		-- Remove last listeners
		channel.listeners[#channel.listeners] = nil
		-- Clear client key
		channel.listenersByKeys[client] = nil

		local clientChannels = client:GetLocalVar("radioChannels", {})
		clientChannels[channel.uniqueID] = nil
		client:SetLocalVar("radioChannels", clientChannels)

		-- Reset transmit channel if client doesn't have this channel anymore
		if (client:GetCharacter():GetRadioChannel() == channel.uniqueID) then
			local channels = self:GetAllChannelsFromChar(client:GetCharacter())
			client:GetCharacter():SetRadioChannel(channels and channels[1] or "")
		end
	end
end

function ix.radio:AddStationaryToChannel(channelID, entity)
	local channel = self:FindByID(channelID)
	if (channel and IsValid(entity)) then
		table.insert(channel.stationaries, entity)
	end
end

function ix.radio:RemoveStationaryFromChannel(channelID, entity)
	local channel = self:FindByID(channelID)
	if (channel and IsValid(entity)) then
		for k, v in ipairs(channel.stationaries) do
			if (v == entity) then
				table.remove(channel.stationaries, k)
				return
			end
		end
	end
end

function ix.radio:CleanStationariesFromChannel(channelID)
	local channel = self:FindByID(channelID)
	if (channel) then
		for i = #channel.stationaries, 1, -1 do
			if (!IsValid(channel.stationaries[i])) then
				table.remove(channel.stationaries, i)
			end
		end
	end
end

function ix.radio:AddPlayerChannelSubscription(client, channelID)
	local channel = self:FindByID(channelID)
	if (channel) then
		local character = client:GetCharacter()

		character:SetRadioChannels(channel.uniqueID)
		self:AddListenerToChannel(client, channel.uniqueID)
	end
end

function ix.radio:RemovePlayerChannelSubscription(client, channelID)
	local channel = self:FindByID(channelID)
	if (channel) then
		local character = client:GetCharacter()
		character:SetRadioChannels(channel.uniqueID, true)
		self:RemoveListenerFromChannel(character, channelID)
	end
end
