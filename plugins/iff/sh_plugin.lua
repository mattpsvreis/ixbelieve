local PLUGIN = PLUGIN

PLUGIN.name = "IFF"
PLUGIN.author = "Xalphox & Gr4Ss & Dark"
PLUGIN.description = "Adds IFF items. Edited for Halo: Believe by Dark."

ix.util.Include("meta/sv_player.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sv_hooks.lua")

function PLUGIN.GetIFFText(squad, FT, role)
    local text = squad and string.upper(squad) or "NONE"
    if (FT) then
        text = text.."-"..FT
    end

    if (role) then
        text = text.." "..string.upper(role)
    end

    return text
end

believe = believe or {}
believe.GetIFFText = PLUGIN.GetIFFText
