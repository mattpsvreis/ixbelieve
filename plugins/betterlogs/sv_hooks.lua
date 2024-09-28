local table = table
local IsValid = IsValid
local game = game
local os = os
local math = math
local ix = ix
local file = file
local netstream = netstream
local CAMI = CAMI
local CurTime = CurTime
local pairs = pairs

ix.log.AddType("containerRemoved", function(entity, id, chips, name, model, text)
	return string.format("Container '%s' removed (inv #%d; model: %s) with %d chips and %s", name, id, model, chips, text)
end, FLAG_WARNING)

do
	local HANDLER = {}

	function HANDLER.Load()
		local query = mysql:Create("ix_logs")
			query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
			query:Create("steamid", "VARCHAR(20) DEFAULT NULL")
			query:Create("char_id", "INT(11) DEFAULT NULL")
			query:Create("log_type", "TEXT DEFAULT NULL")
			query:Create("pos_x", "FLOAT(17) DEFAULT NULL")
			query:Create("pos_y", "FLOAT(17) DEFAULT NULL")
			query:Create("pos_z", "FLOAT(17) DEFAULT NULL")
			query:Create("map", "TEXT DEFAULT NULL")
			query:Create("datetime", "INT(11) UNSIGNED DEFAULT NULL")
			query:Create("text", "TEXT DEFAULT NULL")
			query:Create("lookup1", "TEXT DEFAULT NULL")
			query:Create("lookup2", "TEXT DEFAULT NULL")
			query:Create("lookup3", "TEXT DEFAULT NULL")
			query:PrimaryKey("id")
		query:Execute()
	end

	function HANDLER.Write(entity, message, flag, logType, args)
		local query = mysql:Insert("ix_logs")
			query:Insert("log_type", logType or "raw")
			query:Insert("map", game.GetMap())
			query:Insert("datetime", os.time())
			query:Insert("text", message)

			if (IsValid(entity)) then
				local pos = entity:GetPos()
				query:Insert("pos_x", pos.x)
				query:Insert("pos_y", pos.y)
				query:Insert("pos_z", pos.z)

				if (entity:IsPlayer()) then
					query:Insert("steamid", entity:SteamID64())
					if (entity:GetCharacter()) then
						query:Insert("char_id", entity:GetCharacter():GetID())
					end
				end
			end

			local count = args and table.Count(args) or 0
			if (count > 0) then
				for i = 1, math.min(3, count) do
					query:Insert("lookup"..i, args[i])
				end
			end
		query:Execute()
	end

	ix.log.RegisterHandler("Database", HANDLER)
end

do
	local HANDLER = {}

	function HANDLER.Load()
		file.CreateDir("helix/logs")
	end

	function HANDLER.Write(client, message)
		file.Append("helix/logs/"..os.date("%Y-%m-%d")..".txt", os.date("[%X\t]")..message.."\r\n")
	end

	ix.log.RegisterHandler("File", HANDLER)
end

netstream.Hook("ixRequestLogTypes", function(client)
	if (!CAMI.PlayerHasAccess(client, "Helix - Manage Logs")) then return end
	netstream.Start(client, "ixSendLogTypes", table.GetKeys(ix.log.types))
end)

netstream.Hook("ixRequestLogs", function(client, data)
	if (!CAMI.PlayerHasAccess(client, "Helix - Manage Logs")) then return end

	local curTime = CurTime()

	if (data) then
		local currentPage = data.currentPage or 1
		local logsPerPage = math.min(data.logsPerPage or 25, 25)
		local query = mysql:Select("ix_logs")
			query:Limit(logsPerPage)
			query:Offset((currentPage - 1) * logsPerPage)
			if (data.steamid and data.steamid != "") then
				if (string.find(data.steamid, ",", 1, true)) then
					local ids = string.Explode(",", string.gsub(data.steamid, "%s", ""), false)
					for k, v in ipairs(ids) do
						if (string.find(v, "^STEAM")) then
							ids[k] = util.SteamIDTo64(v)
						end
					end
					query:WhereIn("steamid", ids)
				else
					query:Where("steamid", string.find(data.steamid, "^STEAM") and util.SteamIDTo64(data.steamid) or data.steamid)
				end
			end

			if (data.logType and data.logType != "" and data.logType != "all" and ix.log.types[data.logType]) then
				query:Where("log_type", data.logType)
			end

			if (data.distance and data.distance != 0) then
				local pos = client:GetPos()
				local x, y, z = pos.x, pos.y, pos.z
				local dist = data.distance * 0.5

				query:Where("map", game.GetMap())
				query:WhereGTE("pos_x", x - dist)
				query:WhereGTE("pos_y", y - dist)
				query:WhereGTE("pos_z", z - dist)

				query:WhereLTE("pos_x", x + dist)
				query:WhereLTE("pos_y", y + dist)
				query:WhereLTE("pos_z", z + dist)
			elseif (data.map != "") then
				query:Where("map", data.map)
			end

			if (data.before and data.before != 0) then
				query:WhereLTE("datetime", os.time() - data.before)
			end

			if (data.after and data.after != 0) then
				query:WhereGTE("datetime", os.time() - data.after)
			end

			if (data.text and data.text != "") then
				query:WhereLike("text", data.text:utf8lower())
			end

			if (data.desc) then
				query:OrderByDesc("datetime")
			else
				query:OrderByAsc("datetime")
			end

			query:Callback(function(result)
				if (result and table.Count(result) > 0) then
					netstream.Start(client, "ixSendLogs", result)
				else
					netstream.Start(client, "ixSendLogs", false)
				end
			end)
		query:Execute()

		client.nextQuery = curTime + 5
	end
end)

netstream.Hook("ixLogTeleport", function(client, pos)
	if (CAMI.PlayerHasAccess(client, "Helix - Tp", nil)) then
		client:SetPos(pos)
	else
		client:NotifyLocalized("notAllowed")
	end
end)

function PLUGIN:ContainerRemoved(container, inventory)
	local name, model, id, chips, itemText = "unknown", "error", 0, 0, "no items"
	local bShouldLog = false
	if (IsValid(container) and container:GetClass() == "ix_container") then
		name = container:GetDisplayName()
		model = container:GetModel()
		id = inventory:GetID()
		chips = container:GetMoney()
		if (chips > 0) then
			bShouldLog = true
		end
	end

	local items = inventory:GetItems()
	if (table.Count(items) > 0) then
		itemText = "items: "
		for _, v in pairs(items) do
			if (!v.maxStackSize or v.maxStackSize == 1) then
				itemText = itemText.." "..v:GetName().." (#"..v:GetID()..");"
			else
				itemText = itemText.." "..v:GetStackSize().."x "..v:GetName().." (#"..v:GetID()..");"
			end
		end

		bShouldLog = true
	end

	if (bShouldLog) then
		ix.log.Add(container, "containerRemoved", id, chips, name, model, itemText)
	end
end