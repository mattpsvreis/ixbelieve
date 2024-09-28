
-- Remake the connect & disconnect chat classes to stop the default ones.
function PLUGIN:InitializedChatClasses()
	ix.chat.classes["connect"] = nil
	ix.chat.classes["disconnect"] = nil

	ix.chat.Register("new_connect", {
		CanSay = function(_, speaker, text)
			return !IsValid(speaker)
		end,
		OnChatAdd = function(_, speaker, text)
			local icon = ix.util.GetMaterial("icon16/add.png")

			chat.AddText(icon, Color(151, 153, 152), L("playerConnected", text))
		end,
		noSpaceAfter = true
	})

	ix.chat.Register("new_disconnect", {
		CanSay = function(_, speaker, text)
			return !IsValid(speaker)
		end,
		OnChatAdd = function(_, speaker, text)
			local icon = ix.util.GetMaterial("icon16/delete.png")

			chat.AddText(icon, Color(151, 153, 152), L("playerDisconnected", text))
		end,
		noSpaceAfter = true
	})

	ix.chat.Register("bastionPlayerDeath", {
		CanSay = function(_, speaker, text)
			return true
		end,
		OnChatAdd = function(_, speaker, text)
			local icon = ix.util.GetMaterial("icon16/cross.png")

			chat.AddText(icon, Color(255, 0, 0), text)
		end,
		CanHear = function(_, speaker, listener)
			return CAMI.PlayerHasAccess(listener, "Helix - Admin") and ix.option.Get(listener, "playerDeathNotification")
		end
	})
end

function PLUGIN:GetMaxPlayerCharacter(client)
    if (CAMI.PlayerHasAccess(client, "Helix - Increase Character Limit")) then
        return ix.config.Get("maxCharactersIncreased", 8)
    end
end

function PLUGIN:CanProperty(client, property, entity)
    if (property == "container_setpassword" and !CAMI.PlayerHasAccess(client, "Helix - Container Password")) then
        return false
    end
end

function PLUGIN:CanPlayerSpawnContainer()
	if (!ix.config.Get("AllowContainerSpawn")) then
		return false
	end
end

function PLUGIN:CanPlayerAccessDoor(client)
	if (client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) then return true end

	if (ix.faction.Get(client:Team()).lockAllDoors) then return true end
end

--[[
-- Anti bunny hop, we don't need this
function PLUGIN:OnPlayerHitGround(client, inWater, onFloater, speed)
	local currentVelocity = client:GetVelocity()

	client:SetVelocity(-Vector(currentVelocity.x, currentVelocity.y, 0))
end
--]]