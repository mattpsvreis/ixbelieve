local timer = timer
local pairs = pairs
local CurTime = CurTime
local player = player
local ipairs = ipairs
local ix = ix
local IsValid = IsValid

local PLUGIN = PLUGIN

PLUGIN.takeCounter = {}
timer.Create("ixBastionAntiTakeSpam", 1, 0, function()
	for client, amount in pairs(PLUGIN.takeCounter) do
		if (amount < 10) then continue end
		if (!IsValid(client)) then continue end

		for _, admin in ipairs(player.GetAll()) do
			if (admin:IsSuperAdmin()) then
				admin:NotifyLocalized("bastionItemTakeKick", client:Name())
			end
		end

		client:Kick("Item take spam")
	end

	PLUGIN.takeCounter = {}
end)

function PLUGIN:CanPlayerInteractItem(client, action, item, data)
	if (action == "take") then
		if (self.takeCounter[client] and self.takeCounter[client] >= 5) then
			if (self.takeCounter[client] == 5) then
				for _, v in ipairs(player.GetAll()) do
					if (v:IsSuperAdmin()) then
						v:NotifyLocalized("bastionItemTakeWarn", client:Name())
					end
				end
				client:NotifyLocalized("bastionTakingItemsTooQuickly")
			end

			self.takeCounter[client] = self.takeCounter[client] + 1
			return false
		end
	elseif (action == "drop" and client.ixAntiItemSpam and client.ixAntiItemSpam > CurTime()) then
		return false
	end
end
function PLUGIN:PlayerInteractItem(client, action, item)
	if (action == "take") then
		self.takeCounter[client] = (self.takeCounter[client] or 0) + 1
	end
end

PLUGIN.itemSpawns = {}
function PLUGIN:OnItemSpawned(entity)
	if (!entity.ixItemID) then return end
	if (IsValid(self.itemSpawns[entity.ixItemID])) then
		if (self.itemSpawns[entity.ixItemID].ixItemID != entity.ixItemID) then
			return -- just in case
		end

		--Now we are trying to spawn an item which already has an entity!
		--Check if it is the same person, in case of weird behaviour
		if (entity.ixSteamID == self.itemSpawns[entity.ixItemID]) then
			local client = player.GetBySteamID(entity.ixSteamID)
			if ((client.ixAntiItemSpam or 0) > CurTime()) then
				for _, v in ipairs(player.GetAll()) do
					if (v:IsSuperAdmin()) then
						v:NotifyLocalized("bastionItemDropSpamKick", client:Name())
					end
				end

				client:Kick("Item drop spam")
			else
				client.ixAntiItemSpam = CurTime() + 10

				for _, v in ipairs(player.GetAll()) do
					if (v:IsSuperAdmin()) then
						v:NotifyLocalized("bastionItemDropSpamWarn", client:Name())
					end
				end

				client:NotifyLocalized("bastionItemDropTooQuick")
			end
		end

		self.itemSpawns[entity.ixItemID]:Remove()
		self.itemSpawns[entity.ixItemID] = entity
	else
		self.itemSpawns[entity.ixItemID] = entity
	end
end

function PLUGIN:CanPlayerCreateCharacter(client)
	if (client.ixNextCharCreate and (client.ixNextCharCreate + ix.config.Get("charCreateInterval") * 60) > CurTime()) then
		return false, "charCreateTooFast", ix.config.Get("charCreateInterval")
	end
end

function PLUGIN:OnCharacterCreated(client)
	if (!CAMI.PlayerHasAccess(client, "Helix - Bypass Char Create")) then
		client.ixNextCharCreate = CurTime()
	end
end

function PLUGIN:PlayerSpawnedProp(client, model, entity)
	ix.log.Add(client, "spawnProp", model)
	entity.ownerCharacter = client:GetName()
	entity.ownerName = client:SteamName()
	entity.ownerSteamID = client:SteamID()
end

PLUGIN.PlayerSpawnedEffect = PLUGIN.PlayerSpawnedProp
PLUGIN.PlayerSpawnedRagdoll = PLUGIN.PlayerSpawnedProp

function PLUGIN:PlayerSpawnedNPC(client, entity)
	ix.log.Add(client, "spawnEntity", entity)
end

PLUGIN.PlayerSpawnedSWEP = PLUGIN.PlayerSpawnedNPC
PLUGIN.PlayerSpawnedSENT = PLUGIN.PlayerSpawnedNPC
PLUGIN.PlayerSpawnedVehicle = PLUGIN.PlayerSpawnedNPC

function PLUGIN:OnPhysgunPickup(client, entity)
	if (IsValid(entity)) then
		ix.log.Add(client, "physgunPickup", entity:IsPlayer() and entity:Name() or entity:GetClass(), entity:GetModel())
	end
end

function PLUGIN:CanTool(client, trace, tool)
	ix.log.Add(client, "useTool", tool, IsValid(trace.Entity) and trace.Entity:GetClass() or nil, IsValid(trace.Entity) and trace.Entity:GetModel() or nil)
end

-- doing this via a hook as it is used elsewhere too and we want this to be late in the call order
hook.Add("CanProperty", "ixBastionCanProperty", function(client, property, ent)
	ix.log.Add(client, "useProperty", property, IsValid(ent) and ent:GetClass() or nil, IsValid(ent) and ent:GetModel() or nil)
end)

function PLUGIN:PlayerInitialSpawn(client)
	local receivers

	if (!ix.config.Get("showConnectMessages", true)) then
		receivers = {}

		for _, ply in ipairs(player.GetAll()) do
			if (CAMI.PlayerHasAccess("Helix - Admin")) then
				receivers[#receivers + 1] = ply
			end
		end
	end

	-- Give some time for the player's data to be loaded, just in case.
	timer.Simple(1, function()
		ix.chat.Send(nil, "new_connect", client:SteamName(), false, receivers)
	end)
end

function PLUGIN:PlayerDisconnected(client)
	local receivers
	if (!ix.config.Get("showDisconnectMessages", true)) then
		receivers = {}

		for _, ply in ipairs(player.GetAll()) do
			if (CAMI.PlayerHasAccess("Helix - Admin")) then
				receivers[#receivers + 1] = ply
			end
		end
	end

	ix.chat.Send(nil, "new_disconnect", client:SteamName(), false, receivers)
end


function PLUGIN:PlayerDeath(client, inflictor, attacker)
	if (!client:GetCharacter()) then return end

	local text = string.format("%s (%s) has died%s.", client:GetCharacter():GetName(), client:SteamName(), (client.ixArea and client.ixArea != "" and " at "..client.ixArea) or "")
	ix.chat.Send(client, "bastionPlayerDeath", text)
end