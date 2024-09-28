AddCSLuaFile()

ix.command.Add("CharGiveItem", {
	description = "@cmdCharGiveItem",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, item, amount)
		amount = amount or 1
		local uniqueID = item:lower()

		if (!ix.item.list[uniqueID]) then
			for k, v in SortedPairs(ix.item.list) do
				if (ix.util.StringMatches(v.name, uniqueID)) then
					uniqueID = k

					break
				end
			end
		end

		if (!ix.item.list[uniqueID]) then
			return "That item does not exist!"
		end

		local bSuccess,error = target:GetInventory():Add(uniqueID, amount)

		if (bSuccess) then
			ix.util.NotifyCami(string.format("%s spawned %ix %s for %s", client:Name(), amount, uniqueID,  target:GetPlayer():Name()), "Helix - CharGiveItem", target:GetPlayer())
		else
			return "@" .. tostring(error)
		end
	end
})

ix.command.Add("CharSetItem", {
	description = "Ensure a character has the given amount of a certain item",
	privilege = "CharGiveItem",
	bContextMenu = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, item, amount)
		amount = amount or 1
		local uniqueID = item:lower()

		if (!ix.item.list[uniqueID]) then
			for k, v in SortedPairs(ix.item.list) do
				if (ix.util.StringMatches(v.name, uniqueID)) then
					uniqueID = k

					break
				end
			end
		end

		if (!ix.item.list[uniqueID]) then
			return "That item does not exist!"
		end

		local currAmount = target:GetInventory():GetItemCount(uniqueID)
		if (amount - currAmount <= 0) then
			return target:GetName().." already has (more than) "..amount.." of '"..ix.item.list[uniqueID].name.."'."
		end

		local bSuccess,error = target:GetInventory():Add(uniqueID, amount - currAmount)

		if (bSuccess) then
			ix.util.NotifyCami(string.format("%s spawned %ix %s for %s", client:Name(), amount - currAmount, uniqueID,  target:GetPlayer():Name()), "Helix - CharGiveItem", target:GetPlayer())
		else
			return "@" .. tostring(error)
		end
	end
})

ix.command.Add("CharTakeItem", {
	description = "Takes an item from a player.",
	alias = "takeitem",
	bContextMenu = true,
	privilege = "CharGiveItem",
	arguments = {
		ix.type.character,
		ix.type.string
	},
	OnRun = function(self, client, target, item)
		local itemName
		local uniqueID = item:lower()

		if (!ix.item.list[uniqueID]) then
			for k, v in SortedPairs(ix.item.list) do
				if (ix.util.StringMatches(v.name, uniqueID)) then
					itemName = v.name
					uniqueID = k

					break
				end
			end
		else
			itemName = ix.item.list[uniqueID].name
		end

		if itemName == nil then
			ix.util.Notify("No item by that name was found.", client)
			return
		end

		local count = 0
		local inv = target:GetInventory():GetItems()
		for k, v in pairs(inv) do
			if v.uniqueID == uniqueID then
				v:Remove()
				count = count + 1
			end
		end

		if (count == 0) then
			ix.util.Notify(string.format("%s has no %s's.", target:GetPlayer():GetName(), itemName), client)
			return
		end

		ix.util.NotifyCami(string.format("%s removed %i %s's from %s's inventory.", client:GetName(), count, itemName, target:GetPlayer():GetName()), "Helix - CharGiveItem", target:GetPlayer())

	end
})