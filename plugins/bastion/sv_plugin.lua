local util = util
local timer = timer
local ipairs = ipairs
local player = player
local CAMI = CAMI
local string = string
local ents = ents
local IsValid = IsValid
local ix = ix

local PLUGIN = PLUGIN

util.AddNetworkString("ixOpenURL")
util.AddNetworkString("ixPlayerInfo")
util.AddNetworkString("ixStaffList")
util.AddNetworkString("ixPlaySound")

function PLUGIN:InitializedConfig()
	ix.config.Set("EdictWarningLimit", 512)
end

ix.util.Include("modules/sv_banlist.lua")
--ix.util.Include("modules/sv_netsizelog.lua")
--ix.util.Include("modules/sv_netmonitor.lua") --high performance impact!

ix.log.AddType("bastionCheckInfo", function(client, target)
	return string.format("%s has checked %s's info.", client:GetName(), target:GetName())
end)
ix.log.AddType("bastionSetHealth", function(client, target)
	return string.format("%s has set %s's health to %d.", client:GetName(), target:GetName(), target:Health())
end)
ix.log.AddType("bastionSetArmor", function(client, target)
	return string.format("%s has set %s's armor to %d.", client:GetName(), target:GetName(), target:Armor())
end)
ix.log.AddType("bastionSetName", function(client, target, oldName)
	return string.format("%s has set %s's name to %s.", client:GetName(), oldName, target:GetName())
end)
ix.log.AddType("bastionSetDesc", function(client, target)
	return string.format("%s has set %s's description to %s.", client:GetName(), target:GetName(), target:GetDescription())
end)
ix.log.AddType("bastionSlay", function(client, target)
	return string.format("%s has slayed %s.", client:GetName(), target:GetName())
end, FLAG_DANGER)
ix.log.AddType("bastionInvSearch", function(client, name)
	return string.format("%s is admin-searching %s.", client:GetName(), name)
end)
ix.log.AddType("bastionInvClose", function(client, name)
	return string.format("%s has closed %s.", client:GetName(), name)
end)
ix.log.AddType("containerAOpen", function(client, name, invID)
	return string.format("%s admin-searched the '%s' #%d container.", client:Name(), name, invID)
end)
ix.log.AddType("containerAClose", function(client, name, invID)
	return string.format("%s admin-closed the '%s' #%d container.", client:Name(), name, invID)
end)
ix.log.AddType("containerSpawned", function(client, name)
	return string.format("%s created a '%s' container.", client:Name(), name)
end, FLAG_NORMAL)
ix.log.AddType("spawnProp", function(client, ...)
	local arg = {...}
	return string.format("%s has spawned '%s'.", client:Name(), arg[1])
end)
ix.log.AddType("spawnEntity", function(client, ...)
	local arg = {...}
	return string.format("%s has spawned a '%s'.", client:Name(), arg[1])
end)
ix.log.AddType("useTool", function(client, tool, entity, model)
	return string.format("%s used the '%s' tool%s.", client:Name(), tool, (entity and string.format(" on a '%s' (%s)", entity, model)) or "")
end)
ix.log.AddType("useProperty", function(client, tool, entity, model)
	return string.format("%s used the '%s' property%s.", client:Name(), tool, (entity and string.format(" on a '%s' (%s)", entity, model)) or "")
end)
ix.log.AddType("physgunPickup", function(client, entity, model)
	return string.format("%s phys-gunned a '%s' (%s).", client:Name(), entity, model)
end)

timer.Create("ixBastionEdictCheck", 60, 0, function()
	local edictsCount = ents.GetEdictCount()
	local edictsLeft = 8192 - edictsCount
	if (edictsLeft < ix.config.Get("EdictWarningLimit")) then
		for _, v in ipairs(player.GetAll()) do
			if (CAMI.PlayerHasAccess(v, "Helix - Basic Admin Commands")) then
				v:NotifyLocalized("edictWarning", edictsLeft, edictsCount)
			end
		end
	end
end)

function PLUGIN:Explode(target)
	local explosive = ents.Create("env_explosion")
	explosive:SetPos(target:GetPos())
	explosive:SetOwner(target)
	explosive:Spawn()
	explosive:SetKeyValue("iMagnitude", "1")
	explosive:Fire("Explode", 0, 0)
	explosive:EmitSound("ambient/explosions/explode_4.wav", 500, 500)

	target:StopParticles()
	target:Kill()
end

function PLUGIN:OpenInventory(client, target)
	if (!IsValid(client) or !IsValid(target)) then return end
	if (!target:IsPlayer()) then return end

	local character = target:GetCharacter()
	if (!character) then return end

	local inventory = character:GetInventory()
	if (inventory) then
		local name = target:Name().."'s inventory"

		ix.storage.Open(client, inventory, {
			entity = target,
			name = name,
			OnPlayerClose = function()
				ix.log.Add(client, "bastionInvClose", name)
			end
		})

		ix.log.Add(client, "bastionInvSearch", name)
	end
end
