
local PLUGIN = PLUGIN

PLUGIN.INDEFINITE_BAN_TEXT = [[You were indefinitely banned by %s for: %s

Appeal your ban at https://halobelieve.boards.net]]
PLUGIN.BAN_TEXT = [[You were banned by %s for: %s

Your ban expires in: %s

Appeal your ban at https://halobelieve.boards.net]]

PLUGIN.INDEFINITE_BAN_NOTIFY = "%s was indefinitely banned by %s for '%s'!"
PLUGIN.BAN_NOTIFY = "%s was banned for %s by %s for '%s'!"
PLUGIN.EXTEND_BAN_NOTIFY = "%s had their %s by %s for '%s'!"

function PLUGIN:GetBanReason(ban)
    if (ban.indefinite) then
        return string.format(self.INDEFINITE_BAN_TEXT, ban.bannedBy, ban.reason)
    else
        return string.format(self.BAN_TEXT, ban.bannedBy, ban.reason, string.NiceTime(ban.banEnd - os.time()))
    end
end

function PLUGIN:CreateBan(steamID, duration, bannedBy, reason, bIndefinite, client, name, text)
    if (!client or !name) then
        for k, v in ipairs(player.GetAll()) do
            if (v:SteamID64() == steamID) then
                name = v:SteamName()
                client = v
            end
        end
    end

    local ban = {
        steamID = steamID,
        banStart = os.time(),
        banEnd = (bIndefinite and self.INDEF_BAN_END) or os.time() + duration,
        reason = reason,
        bannedBy = IsValid(bannedBy) and bannedBy:Name() or "Console",
        indefinite = bIndefinite,
        name = name
    }
    self.activeBans[steamID] = ban

    if (client) then
        client:Kick(self:GetBanReason(ban))
    end

    local insertQuery = mysql:Insert("ix_bans")
        insertQuery:Insert("steamid", ban.steamID)
        insertQuery:Insert("ban_start", ban.banStart)
        insertQuery:Insert("ban_end", ban.banEnd)
        insertQuery:Insert("end_reason", "Ban Expired")
        insertQuery:Insert("reason", ban.reason)
        insertQuery:Insert("banned_by", string.sub(ban.bannedBy, 1, math.min(string.len(ban.bannedBy), 50)))
        if (name) then
            insertQuery:Insert("name", string.sub(name, 1, math.min(string.len(name), 50)))
        end
        insertQuery:Callback(function(result, status, lastID)
            self.activeBans[steamID].id = lastID
        end)
    insertQuery:Execute()

    if (text) then
        text = string.format(self.EXTEND_BAN_NOTIFY, name or steamid, string.lower(text), IsValid(bannedBy) and bannedBy:Name() or "Console", reason)
    elseif (bIndefinite) then
        text = string.format(self.INDEFINITE_BAN_NOTIFY, name or steamid, IsValid(bannedBy) and bannedBy:Name() or "Console", reason)
    else
        text = string.format(self.BAN_NOTIFY, name or steamid, string.NiceTime(duration), IsValid(bannedBy) and bannedBy:Name() or "Console", reason)
    end

    for k, v in ipairs(player.GetAll()) do
        if (CAMI.PlayerHasAccess(v, "Helix - Bans")) then
            v:ChatNotify(text)
        end
    end

    return ban
end

function PLUGIN:BanPlayer(client, duration, bannedBy, reason, bIndefinite)
    if (duration < 0) then
        return "Invalid duration"
    end

    local steamID = client:SteamID64()
    if (self.activeBans[steamID] and self.activeBans[steamID].banEnd > os.time()) then
        ErrorNoHalt("[BANS] Tried to ban player "..client:SteamName().." who is already banned but still on the server.\n")
        return self:BanPlayerBySteamID(client:SteamID64(), duration, bannedBy, reason, bIndefinite)
    end

    local name = client:SteamName()
    self:CreateBan(steamID, duration, bannedBy, reason, bIndefinite, client, name)
end

function PLUGIN:BanPlayerBySteamID(steamID, duration, bannedBy, reason, bIndefinite)
    if (duration < 0) then
        return "Invalid duration"
    end

    if (!self.activeBans[steamID] and (!reason or reason == "")) then
        return steamID.." is not banned yet, a reason must be given!"
    end

    local text, name
    if (self.activeBans[steamID] and self.activeBans[steamID].banEnd > os.time()) then
        name = self.activeBans[steamID].name

        if (!reason or reason == "") then
            reason = self.activeBans[steamID].reason
        end

        local newEnd = os.time() + duration
        local banExtended, diff
        if (bIndefinite) then -- changing to indefinite ban
            if (self.activeBans[steamID].indefinite) then
                return steamID.." is already indefinitely banned!"
            end

            newEnd = self.INDEF_BAN_END
            banExtended = true
            diff = "Indefinitely"
        elseif (self.activeBans[steamID].indefinite) then -- shortening indefinite ban
            banExtended = false
            diff = "to "..string.NiceTime(duration)
        else -- changing ban length
            banExtended = newEnd > self.activeBans[steamID].banEnd -- is it longer or shorter?
            diff = "by "..string.NiceTime(math.abs(newEnd - self.activeBans[steamID].banEnd))
        end

        text = (banExtended and "Remaining Ban Extended " or "Remaining Ban Reduced ")..diff
        local updateQuery = mysql:Update("ix_bans")
            updateQuery:Where("id", self.activeBans[steamID].id)
            updateQuery:Update("ban_end", os.time())
            updateQuery:Update("end_reason", text)
        updateQuery:Execute()
    end

    self:CreateBan(steamID, duration, bannedBy, reason, bIndefinite, nil, name, text)
end

function PLUGIN:UnbanSteamID(steamID, unbannedBy)
    if (!self.activeBans[steamID] or self.activeBans[steamID].banEnd < os.time()) then
        return steamID.." is not banned!"
    end

    local updateQuery = mysql:Update("ix_bans")
        updateQuery:Where("id", self.activeBans[steamID].id)
        updateQuery:Update("ban_end", os.time())
        updateQuery:Update("end_reason", "Unbanned by "..(IsValid(unbannedBy) and unbannedBy:Name() or "Console"))
    updateQuery:Execute()

    local name = self.activeBans[steamID].name
    self.activeBans[steamID] = nil

    for k, v in ipairs(player.GetAll()) do
        if (CAMI.PlayerHasAccess(v, "Helix - Bans")) then
            v:ChatNotify(steamID.." was unbanned by "..(IsValid(unbannedBy) and unbannedBy:Name() or "Console").."!")
        end
    end
end


concommand.Add("ix_reloadpermabans", function(ply)
    if (IsValid(ply)) then return end

    local bans = {
        --[["STEAM_0:0:128271068",
        "STEAM_0:0:102099568",
        "STEAM_0:1:8310486",
        "STEAM_0:1:603176945",
        "STEAM_0:1:515610422",
        "STEAM_0:1:17693550",
        "STEAM_0:1:2353771",
        "STEAM_0:1:159891738",
        "STEAM_0:1:207293168",
        "STEAM_0:1:512912373",
        "STEAM_0:0:96315651",
        "STEAM_0:0:158347468",
        "STEAM_0:0:547272710",
        "STEAM_0:0:100211129",
        "STEAM_0:1:226358281",
        "STEAM_0:1:53881268",
        "STEAM_0:1:104846168",
        "STEAM_0:0:97372012",
        "STEAM_0:0:151277388",
        "STEAM_0:1:123231623",
        "STEAM_0:1:581640801",
        "STEAM_0:0:588067884",
        "STEAM_0:0:244194329",
        "STEAM_0:1:55371442",
        "STEAM_0:1:174273266",
        "STEAM_0:1:43270455",
        "STEAM_0:1:50024339",
        "STEAM_0:0:218854364",
        "STEAM_0:1:111888425",
        "STEAM_0:1:43085888",
        "STEAM_0:1:163451117",
        "STEAM_0:1:511990954",
        "STEAM_0:0:46113379",
        "STEAM_0:1:151885836",
        "STEAM_0:0:52007838",
        "STEAM_0:0:219000907",
        "STEAM_0:0:89441122",
        "STEAM_0:1:70490195",--]]
    }

    for k, v in ipairs(bans) do
        v = util.SteamIDTo64(v)
        local selectQuery = mysql:Select("ix_bans")
            selectQuery:Where("steamid", v)
            selectQuery:Callback(function(result)
                if (result and result[1]) then return end
                local ban = {
                    steamID = v,
                    banStart = os.time(),
                    banEnd = PLUGIN.INDEF_BAN_END,
                    reason = "Indefinitely banned due to being a malicious player.",
                    bannedBy = "Dark",
                    indefinite = true,
                }
                PLUGIN.activeBans[v] = ban
                local insertQuery = mysql:Insert("ix_bans")
                    insertQuery:Insert("steamid", v)
                    insertQuery:Insert("ban_start", os.time())
                    insertQuery:Insert("ban_end", PLUGIN.INDEF_BAN_END)
                    insertQuery:Insert("end_reason", "Ban Expired")
                    insertQuery:Insert("reason", "Indefinitely banned due to being a malicious player.")
                    insertQuery:Insert("banned_by", "Dark")
                    insertQuery:Callback(function(_, _, lastID)
                        PLUGIN.activeBans[v].id = lastID
                    end)
                insertQuery:Execute()
            end)
        selectQuery:Execute()
    end
end)