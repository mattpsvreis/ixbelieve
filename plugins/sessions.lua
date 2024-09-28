PLUGIN.name = "Sessions"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Records when players join and leave"

SERVER_ROUND = SERVER_ROUND or 0

local function EndSession(client, character)
	if not SERVER then
		return
	end

	local query = mysql:Update("ix_sessions")
		query:Where("session_id", character.session_id)
		query:Update("end_time", os.time())
		query:Update("admin", client:IsAdmin() and client:GetUserGroup() or "user")
	query:Execute()
end

function PLUGIN:DatabaseConnected()
	local query = mysql:Create("ix_sessions")
		query:Create("session_id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:Create("name", "VARCHAR(256) NOT NULL")
		query:Create("character_id", "INT(11) UNSIGNED NOT NULL")
		query:Create("player_id", "VARCHAR(20) DEFAULT NULL")
		query:Create("server_round", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("start_time", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("end_time", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("map", "VARCHAR(255) DEFAULT NULL")
		query:Create("admin", "VARCHAR(255) DEFAULT NULL")
		query:Create("faction", "VARCHAR(255) DEFAULT NULL")

		query:Create("ip", "VARCHAR(128) DEFAULT NULL")
		query:Create("proxy", "VARCHAR(256) DEFAULT NULL")
		query:Create("city", "VARCHAR(128) DEFAULT NULL")
		query:Create("country", "VARCHAR(128) DEFAULT NULL")
		query:Create("country_code", "VARCHAR(4) DEFAULT NULL")
		query:Create("timezone", "VARCHAR(128) DEFAULT NULL")
		query:Create("lat", "FLOAT(10, 6) DEFAULT 0.0")
		query:Create("long", "FLOAT(10, 6) DEFAULT 0.0")

		query:Create("avg_fps", "FLOAT(10, 3) DEFAULT NULL")
		query:Create("min_fps", "FLOAT(10, 3) DEFAULT NULL")
		query:Create("max_fps", "FLOAT(10, 3) DEFAULT NULL")

		query:Create("messagesSent", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("messagesReceived", "INT(11) UNSIGNED DEFAULT NULL")

		query:Create("dmgReceived", "FLOAT(10, 3) DEFAULT 0")
		query:Create("dmgGiven", "FLOAT(10, 3) DEFAULT 0")
		query:Create("ffReceived", "FLOAT(10, 3) DEFAULT 0")
		query:Create("ffGiven", "FLOAT(10, 3) DEFAULT 0")

		query:PrimaryKey("session_id")
		query:Callback(function()
			mysql:RawQuery("SELECT MAX(server_round) AS round FROM ix_sessions", function (result)
				local r = result[1]["round"]
				if r then
					SERVER_ROUND = tonumber(r) + 1
					print("SERVER ROUND is " .. SERVER_ROUND)
				end
			end)

			mysql:RawQuery("UPDATE ix_sessions SET end_time = " .. os.time() - 60 .. " WHERE ISNULL(end_time)")


		end)
	query:Execute()
end

function PLUGIN:PlayerLoadedCharacter(client, character, lastChar)

	if lastChar then
		EndSession(client, lastChar)
	end

	local query = mysql:Insert("ix_sessions")
		query:Insert("name", character:GetName())
		query:Insert("character_id", character:GetID())
		query:Insert("player_id", client:SteamID64())
		query:Insert("server_round", SERVER_ROUND)
		query:Insert("start_time", os.time())
		query:Insert("map", game.GetMap())
		query:Insert("admin", client:IsAdmin() and client:GetUserGroup() or "user")
		query:Insert("faction", team.GetName(client:GetCharacter():GetFaction()))

		query:Insert("ip", client:IPAddress())
		if client.proxycheck then
			query:Insert("proxy", client.proxycheck.proxy == "yes" and (client.proxycheck.type .. " - " .. client.proxycheck.provider) or nil)
			query:Insert("city", client.proxycheck.city)
			query:Insert("country", client.proxycheck.country)
			query:Insert("country_code", client.proxycheck.isocode)
			query:Insert("timezone", client.proxycheck.timezone)
			query:Insert("lat", client.proxycheck.latitude)
			query:Insert("long", client.proxycheck.longitude)
		end

		query:Callback(function(result, status, lastID)
			character.session_id = lastID
		end)
	query:Execute()
end

function PLUGIN:OnCharacterDisconnect(client, character)
	EndSession(client, character)
end

hook.Add("PlayerInitialSpawn", "VPN_Check", function (ply)
	if (ply:IsBot()) then return end
	local ip = string.Split(ply:IPAddress(), ":")[1]
	http.Fetch("https://proxycheck.io/v2/" .. ip .. "?key=98a85m-f1h3g6-421672-488760&vpn=1&asn=1",
	function (body, sz, headers, code)
		local data = util.JSONToTable(body)

		data = data[ip]

		if data.proxy == "yes" then
			ix.util.NotifyCami(string.format("%s is probably using a proxy (%s - %s - %s)", ply:Name(), ip, data.type, data.provider), "Helix - Admin")
			ErrorNoHalt(string.format("[PROXY-DETECT] %s (%s) is using a proxy (%s - %s - %s)", ply:Name(), ply:SteamID(), ip, data.type, data.provider))
			--ply:Kick("STEAM client authentication invalid for session")
		end

		ply.proxycheck = data
	end,
	function (err)
		ix.util.NotifyCami(string.format("Failed to check %s's IP address (%s)", ply:Name(), err), "Helix - Admin")
	end)
end)

hook.Add("ShutDown", "session_shutdown", function ()
	for k, v in pairs(player.GetAll()) do
		if v:GetCharacter() ~= nil then
			EndSession(v, v:GetCharacter())
		end
	end
end)


if CLIENT then
	local time = 0
	local focused = 0
	local sumFPS = 0
	local samples = 0
	local minFPS = math.huge
	local maxFPS = 0

	hook.Add("Think", "NStatistics_GetFrameTime", function()
		local ft = RealFrameTime()
		time = time + ft
		if system.HasFocus() then
			focused = focused + ft
			sumFPS = sumFPS + ft
			minFPS = math.min(1 / ft, minFPS)
			maxFPS = math.max(1 / ft, maxFPS)
			samples = samples + 1
		end
	end)

	timer.Create("believe_stats", 10, 0, function ()
		net.Start("believe_stats")
			net.WriteDouble(time)
			net.WriteDouble(focused)
			net.WriteDouble(samples/sumFPS)
			net.WriteDouble(minFPS)
			net.WriteDouble(maxFPS)
		net.SendToServer()

		focusedTime = 0
		sumFPS = 0
		minFPS = math.huge
		maxFPS = 0
		samples = 0
	end)
end

function PLUGIN:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
	if (!IsValid(speaker)) then return end
	local chr = speaker:GetCharacter()
	if not chr then
		return
	end

	chr.messagesSent = (chr.messagesSent or 0) + 1

	receivers = istable(receivers) and receivers or { receivers }
	for k, v in pairs(receivers) do
		if v == speaker then
			continue
		end

		local chr2 = v:GetCharacter()
		if not chr2 then
			continue
		end

		chr2.messagesReceived = (chr2.messagesReceived or 0) + 1
	end
end

hook.Add("PostEntityTakeDamage", "believe_stats", function (ent, dmg, took)
	if not took then
		return
	end

	local attacker = dmg:GetAttacker()

	if ent:IsPlayer() then
		local chr = ent:GetCharacter()
		if not chr then
			return
		end

		chr.dmgReceived = (chr.dmgReceived or 0) + dmg:GetDamage()

		if IsValid(attacker) and attacker:IsPlayer() then
			chr.ffReceived = (chr.ffReceived or 0) + dmg:GetDamage()
		end
	end

	if IsValid(attacker) and attacker:IsPlayer() then
		local chr = attacker:GetCharacter()
		if not chr then
			return
		end

		chr.dmgGiven = (chr.dmgGiven or 0) + dmg:GetDamage()

		if ent:IsPlayer() then
			chr.ffGiven = (chr.ffGiven or 0) + dmg:GetDamage()
		end
	end
end)

hook.Add("PlayerTakeDamage", "believe_stats", function (ent, dmgamount, dmg)
	local attacker = dmg:GetAttacker()
	do
		local chr = ent:GetCharacter()
		if not chr then
			return
		end

		chr.dmgReceived = (chr.dmgReceived or 0) + dmgamount

		if IsValid(attacker) and attacker:IsPlayer() then
			chr.ffReceived = (chr.ffReceived or 0) + dmgamount
		end
	end

	if IsValid(attacker) and attacker:IsPlayer() then
		local chr = attacker:GetCharacter()
		if not chr then
			return
		end

		chr.dmgGiven = (chr.dmgGiven or 0) + dmgamount

		if ent:IsPlayer() then
			chr.ffGiven = (chr.ffGiven or 0) + dmgamount
		end
	end
end)

function PLUGIN:CharacterPostSave(character)
	local client = character:GetPlayer()
	if not client then
		return
	end

	local stats = character.stats

	local query = mysql:Update("ix_sessions")
		query:Where("session_id", character.session_id)

		if stats then
			query:Update("avg_fps", stats.fps)
			query:Update("min_fps", stats.minfps)
			query:Update("max_fps", stats.maxfps)
		end

		query:Insert("admin", client:IsAdmin() and client:GetUserGroup() or "user")
		query:Update("messagesSent", character.messagesSent or 0)
		query:Update("messagesReceived", character.messagesReceived or 0)
		query:Update("dmgReceived", character.dmgReceived or 0)
		query:Update("dmgGiven", character.dmgGiven or 0)
		query:Update("ffGiven", character.ffGiven or 0)
		query:Update("ffReceived", character.ffReceived or 0)
	query:Execute()
end

if SERVER then
	util.AddNetworkString("believe_stats")
	util.AddNetworkString("believe_stats_first")

	net.Receive("believe_stats_first", function (len, client)

	end)

	net.Receive("believe_stats", function (len, client)

		local chr = client:GetCharacter()
		if not chr then
			return
		end


		local time = net.ReadDouble()
		local focusedTime = net.ReadDouble()

		if focusedTime > 0 then
			local fps = math.Clamp(net.ReadDouble(), 0, 300)
			local minfps = math.Clamp(net.ReadDouble(), 0, 300)
			local maxfps = math.Clamp(net.ReadDouble(), 0, 300)

			local stats = chr.stats or {
				focusedTime = 0,
				fps = 0,
				minfps = math.huge,
				maxfps = 0,
				samples = 0
			}
			stats.focusedTime = stats.focusedTime + focusedTime

			if stats.samples > 0 then
				stats.fps = (stats.fps/stats.samples) + fps
			else
				stats.fps = fps
			end
			client:SetNWFloat("fps", fps)
			stats.minfps = math.min(minfps, stats.minfps)
			stats.maxfps = math.max(maxfps, stats.maxfps)

			stats.samples = stats.samples + 1

			chr.stats = stats
		else
			client:SetNWFloat("fps", -1)
		end
	end)
end

ix.command.Add("createaar", {
	description = "Create an AAR",
	OnCheckAccess = function(self, client)
		local character = client:GetCharacter()
		if (!character) then return false end

		return client:IsAdmin() or character:IsNCO(true)
	end,
	arguments = {
		bit.bor(ix.type.optional, ix.type.number),
		bit.bor(ix.type.optional, ix.type.text),
	},
	OnRun = function(self, client, sessionId, title)
		sessionId = sessionId or (SERVER_ROUND - 1)

		if title == "" then
			title = nil
		end

		print(sessionId, SERVER_ROUND)

		-- Create a wiki page
		local query = mysql:Select("ix_sessions")
			query:WhereIn("server_round", sessionId)
			mysql:RawQuery(
			[[SELECT
			ix_sessions.character_id AS character_id,
			ix_sessions.name AS `name`,
			ix_characters.wikipage AS wikipage,
			ix_sessions.map AS map,
			ix_sessions.faction AS faction,
			ix_sessions.server_round AS ROUND,
			ix_sessions.start_time AS start_time
			FROM ix_sessions
			LEFT JOIN ix_characters ON
			character_id = id
			WHERE server_round = ]] .. sessionId .. [[
			AND wikipage IS NOT NULL
			GROUP BY character_id
			ORDER BY wikipage
			]], function(result)
			if not result or table.Count(result) < 0 then
				client:PrintMessage(HUD_PRINTTALK, "Could not find session.")
				return
			end

			local round = result[1].server_round
			local map = result[1].map
			local start = result[1].start_time

			believe.wiki.login(function (succ)
				if not succ then
					client:PrintMessage(HUD_PRINTTALK, "Failed to login to wiki")
					return
				end

				believe.wiki.get("Meta:Event", function (succ, txt)
					if not succ then
						client:PrintMessage(HUD_PRINTTALK, "Failed to fetch Meta:Event")
						return
					end

					local playerTemplate = [[{{EventAttendee|ID=$CHARID|Name=$NAME|Page=$PAGE|Role=$ROLE}}]]

					txt = string.Replace(txt, "$ID", round)
					txt = string.Replace(txt, "$MAP", map)
					txt = string.Replace(txt, "$DATE", os.date("%Y/%m/%d", start))

					local attendees = {}
					for k, v in pairs(result) do
						local s = string.Replace(playerTemplate, "$NAME", v.name)
						s = string.Replace(s, "$ROLE", v.faction or "Infantryman")
						s = string.Replace(s, "$CHARID", v.character_id)
						s = string.Replace(s, "$PAGE", v.wikipage)
						table.insert(attendees, s)
					end

					txt = string.Replace(txt, "$ATTENDEES", table.concat(attendees, ""))

					title = title or ("AAR" .. round .. " (" .. map .. ")")
					believe.wiki.edit(title, txt, nil, "text", nil, function ()
						client:SendLua([[ix.OpenLoreURL("http://wiki.believe.net/index.php/]] .. title .. [[?action=formedit")]])
					end)
				end)
			end)
		end)
	end
})

ix.command.Add("sessions", {
	description = "List all of the sessions over the last 30 days",
	arguments = {
		bit.bor(ix.type.optional, ix.type.number),
	},
	OnRun = function(self, client, includeHomeMap)
		includeHomeMap = (includeHomeMap or 0) > 0

		mysql:RawQuery("SELECT server_round AS ROUND, map, FROM_UNIXTIME(MIN(start_time)) AS start_time, COUNT(DISTINCT Name) AS players FROM ix_sessions WHERE start_time < (NOW() - INTERVAL 30 DAY) GROUP BY server_round, map ORDER BY start_time ASC", function (result)
			for k, v in pairs(result) do
				if includeHomeMap or v.map ~= "believe_hiroo_onoda" then
					local msg = string.format("%i: %s on %s [%i players]", v.ROUND, v.start_time, v.map, v.players)
					client:PrintMessage(HUD_PRINTTALK, msg)
				end
			end
		end)
	end
})
