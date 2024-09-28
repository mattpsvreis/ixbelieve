
local PLUGIN = PLUGIN

PLUGIN.name = "Bans"
PLUGIN.author = "Gr4Ss"
PLUGIN.description = "Handles player bans. 'nuff said."

ix.util.Include("sv_hooks.lua")
ix.util.Include("sv_plugin.lua")

CAMI.RegisterPrivilege({
    Name = "Helix - Bans",
    MinAccess = "admin",
    Description = "Ability to ban other players",
})

ix.command.Add("PlyBan", {
	description = "Ban the given player. Can use s/m/d/w/mo/y for the duration (default minutes). 0 duration for indefinite.",
	privilege = "Bans",
    arguments = {
        ix.type.player,
        ix.type.string,
        ix.type.text
    },
	OnRun = function(self, client, target, duration, reason)
        local indefinite = false
        if (duration == "0") then
            duration = 0
            indefinite = true
        else
            duration = ix.util.GetStringTime(duration)
        end

        return PLUGIN:BanPlayer(target, duration, client, reason, indefinite)
	end
})

ix.command.Add("PlyBanID", {
	description = "Ban the given player by SteamID. Can use s/m/d/w/mo/y for the duration (default minutes). 0 duration for indefinite.",
	privilege = "Bans",
    arguments = {
        ix.type.string,
        ix.type.string,
        bit.bor(ix.type.text, ix.type.optional)
    },
	OnRun = function(self, client, target, duration, reason)
        local steamID = util.SteamIDTo64(target)
        if (steamID == "0") then
            if (string.len(target) == 17 and string.find(target, "^%d+$")) then
                steamID = target
            else
                return target.." is not a valid SteamID!"
            end
        end

        local indefinite = false
        if (duration == "0") then
            duration = 0
            indefinite = true
        else
            duration = ix.util.GetStringTime(duration)
        end

        return PLUGIN:BanPlayerBySteamID(target, duration, client, reason, indefinite)
	end
})

ix.command.Add("PlyUnban", {
	description = "Unban the given player by their SteamID or SteamID64.",
	privilege = "Bans",
    arguments = {
        ix.type.string,
    },
	OnRun = function(self, client, target)
        local steamID = util.SteamIDTo64(target)
        if (steamID == "0") then
            if (string.len(target) == 17 and string.find(target, "^%d+$")) then
                steamID = target
            else
                return target.." is not a valid SteamID!"
            end
        end

        return PLUGIN:UnbanSteamID(steamID, client)
	end
})