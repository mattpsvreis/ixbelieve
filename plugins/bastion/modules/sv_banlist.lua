local hook = hook
local ix = ix
local util = util

local PLUGIN = PLUGIN

PLUGIN.permaBan = {

}

hook.Add("CheckPassword", "bastionBanList", function(steamid, networkid)
    if (PLUGIN.permaBan[steamid] or PLUGIN.permaBan[util.SteamIDFrom64(steamid)] or PLUGIN.permaBan[networkid]) then
        ix.log.AddRaw("[BANS] "..steamid.." ("..networkid..") tried to connect but is hard-banned.")
        return false
    end
end)