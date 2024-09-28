
local ix = ix
local Schema = Schema

function Schema:InitializedConfig()
	ix.config.SetDefault("vignette", false)
	ix.config.Set("vignette", false)
end

function Schema:PlayerSwitchFlashlight(ply, enabled)
	return true
end

function Schema:CanPlayerSuicide(player)
	return true
end

function Schema:PlayerSpray(client)
	return false
end

function Schema:AllowPlayerPickup(client, entity)
	return true
end

function Schema:OnNPCKilled(npc, attacker, inflictor)
    if (IsValid(attacker) and attacker:IsPlayer()) then
        local character = attacker:GetCharacter()
        if (character) then
            character:SetNpcKills(character:GetNpcKills() + 1)
        end
    end

    if (!ix.config.Get("DeleteNPCWeaponOnDeath")) then return end

    if (!npc.GetActiveWeapon) then return end

    local weapon = npc:GetActiveWeapon()
    if (IsValid(weapon)) then
        weapon:Remove()
    end
end

function Schema:OnEntityCreated(entity)
	if (entity:IsNPC() and entity:GetClass() == "npc_citizen") then
		entity:AddRelationship("player D_HT 99")
	end
end

function Schema:EntityTakeDamage(entity, damageInfo)
    if (IsValid(entity) and entity:GetClass() == "barbar"and damageInfo:IsDamageType(DMG_BULLET)) then
        damageInfo:SetDamage(0)
        return true
    end
end

function Schema:PlayerUse(client, ent)
	if (client.isPickingUpEmplacement) then return end

	local itemID = ent:GetNetVar("ixPlacerItemID")
	if (!itemID) then return end

	local item = ix.item.instances[itemID]
	if (item and client:KeyDown(IN_SPEED)) then
		local data = {}
		if (item.PickupEmplacement) then
			data = item.PickupEmplacement(client, ent)
			if data == false then
				return
			end
		end

		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		if (!inventory:FindEmptySlot(item.width, item.height)) then
			ix.util.Notify("Not enough space in your inventory.", client)
			return
		end

		client.isPickingUpEmplacement = true
		client:SetAction("Picking up " .. item:GetName() .. "...", item.PickupTime or 2.5, function ()
			client.isPickingUpEmplacement = false


			local x, y, bagInv = inventory:FindEmptySlot(item.width, item.height)
			if (x and y) then
				for k, v in pairs(data) do
					item:SetData(k, v)
				end

				local id = bagInv and bagInv:GetID() or inventory:GetID()
				if (item:Transfer(id, x, y)) then
					ent:SetNetVar("ixPlacerItemID", nil)
					ent:Remove()
					ix.log.Add(client, "entityPlacer", false, item.uniqueID, ent:GetClass())
				end
			else
				ix.util.Notify("Not enough space in your inventory.", client)
			end
		end)
		return false
	end
end

function Schema:EntityRemoved(entity)
	local itemID = entity:GetNetVar("ixPlacerItemID")
	if (itemID and ix.item.instances[itemID]) then
		ix.item.instances[itemID]:Remove()
	end
end