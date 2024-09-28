
local ix = ix

CreateConVar("believe_voice", "Amy", FCVAR_REPLICATED)

do
	function ix.util.NotifyCami(message, camiPrivilege, client)
		local recipients = {}
		for _, v in ipairs(player.GetAll()) do
			if (CAMI.PlayerHasAccess(v, camiPrivilege) or v == client) then
				recipients[#recipients + 1] = v
			end
		end

		if (#recipients > 0) then
			ix.util.Notify(message, recipients)
		end
	end

	-- Sends a translated notification.
	function ix.util.NotifyLocalizedCami(message, camiPrivilege, client, ...)
		local recipients = {}
		for _, v in ipairs(player.GetAll()) do
			if (CAMI.PlayerHasAccess(v, camiPrivilege) or v == client) then
				recipients[#recipients + 1] = v
			end
		end

		if (#recipients > 0) then
			ix.util.NotifyLocalized(message, recipients, ...)
		end
	end
end

concommand.Add("ix_buy_attribute", function (client, cmd, args)
	local stat = args[1]
	assert(stat)

	local chr = client:GetCharacter()
	assert(chr)

	local spendableAttributePoints = chr:GetData("spendableAttributePoints", 0)
	if spendableAttributePoints <= 0 then return end

	local attr = chr:GetAttributes()[stat]
	assert(attr)

	chr:UpdateAttrib(stat, 1)
	chr:SetData("spendableAttributePoints", spendableAttributePoints - 1)
end)

local HL2_Weapons =
{
	["weapon_ar2"] = true,
	["weapon_shotgun"] = true,
	["weapon_stunstick"] = true,
	["weapon_pistol"] = true,
	["weapon_smg1"] = true,
	["weapon_rpg"] = true,
	["weapon_357"] = true,
	["weapon_grenade"] = true,
	["item_ammo_ar2_altfire"] = true,
	["item_healthvial"] = true
}

timer.Create("Delete_HL2_Weapons", 1, 0, function ()
	for k, v in pairs(ents.GetAll()) do
		if HL2_Weapons[v:GetClass()] and not IsValid(v:GetOwner()) then
			v:Remove()
		end
	end
end)
