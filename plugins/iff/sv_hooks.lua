
local PLUGIN = PLUGIN

function PLUGIN:OnItemTransferred(item, oldInv, newInv)
	if (!item.isIFF) then return end
	local oldID, newID = oldInv:GetID(), newInv:GetID()
	if (oldID == newID) then return end

	local oldOwner = oldInv.GetOwner and oldInv:GetOwner()
	if (oldOwner and IsValid(oldOwner)) then
		oldOwner:UpdateIFFInfo()
	end

	local newOwner = newInv.GetOwner and newInv:GetOwner()
	if (newOwner and IsValid(newOwner)) then
		newOwner:UpdateIFFInfo()
	end
end

function PLUGIN:PlayerLoadedCharacter(client, character, lastChar)
	if (Schema:IsHomeServer()) then
		for k, v in pairs(character:GetInventory():GetItems()) do
			if (!v.isIFF) then continue end

			v:SetData("iff", 1)
			v:SetData("squad", "NONE")
			v:SetData("fireTeam", nil)
			v:SetData("role", nil)
		end
	end
	client:UpdateIFFInfo()
end

function PLUGIN:InventoryItemAdded(oldInv, newInv, item)
	if (oldInv or !item.isIFF) then return end

	local newID = newInv:GetID()
	if (newID == 0) then return end

	local newOwner = newInv:GetOwner()
	if (IsValid(newOwner)) then
		newOwner:UpdateIFFInfo()
	end
end