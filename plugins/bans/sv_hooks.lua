
local PLUGIN = PLUGIN

PLUGIN.activeBans = PLUGIN.activeBans or {}
PLUGIN.INDEF_BAN_END = 2147483647

function PLUGIN:DatabaseConnected()
    local query = mysql:Create("ix_bans")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("steamid", "VARCHAR(20) NOT NULL")
        query:Create("ban_start", "INT(11) UNSIGNED NOT NULL")
        query:Create("ban_end", "INT(11) UNSIGNED NOT NULL")
        query:Create("end_reason", "VARCHAR(50) NOT NULL")
        query:Create("banned_by", "VARCHAR(50) NOT NULL")
        query:Create("name", "VARCHAR(50)")
        query:Create("reason", "TEXT NOT NULL")
        query:PrimaryKey("id")
        query:Callback(function(_)
            local selectQuery = mysql:Select("ix_bans")
            selectQuery:WhereGT("ban_end", os.time())
            selectQuery:Callback(function(result)
                if (!result) then return end

                for k, v in ipairs(result) do
                    self.activeBans[v.steamid] = {
                        id = v.id,
                        steamID = v.steamid,
                        banStart = v.ban_start,
                        banEnd = v.ban_end,
                        reason = v.reason,
                        bannedBy = v.banned_by,
                        indefinite = v.ban_end == self.INDEF_BAN_END,
                        name = v.name
                    }
                end
            end)
        selectQuery:Execute()
        end)
    query:Execute()
end

function PLUGIN:CheckPassword(steamID, ipAddress, svPassword, clPassword, name)
    local ban = self.activeBans[steamID]
    if (ban and (ban.indefinite or ban.banEnd > os.time())) then
        return false, self:GetBanReason(ban)
    end
end
