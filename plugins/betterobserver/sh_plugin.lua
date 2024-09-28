local ix = ix
local CAMI = CAMI
local LocalPlayer = LocalPlayer

local PLUGIN = PLUGIN

PLUGIN.name = "Better Observer"
PLUGIN.author = "Chessnut & Gr4Ss & Dark"
PLUGIN.description = "Adds on to the no-clip mode to prevent intrusion. Edited for WN by Gr4Ss. Edited for Halo: Believe by Dark"

ix.plugin.SetUnloaded("observer", true)

CAMI.RegisterPrivilege({
	Name = "Helix - Observer",
	MinAccess = "admin",
	Description = "Allows using observer"
})

CAMI.RegisterPrivilege({
	Name = "Helix - Observer ESP",
	MinAccess = "admin",
	Description = "Allows using the Player Observer ESP while in observer (and a limited ESP outside of observer)"
})

CAMI.RegisterPrivilege({
	Name = "Helix - Observer Entity ESP",
	MinAccess = "superadmin",
	Description = "Allows using the Entity Observer ESP while in observer"
})

ix.option.Add("observerTeleportBack", ix.type.bool, true, {
	bNetworked = true,
	category = "observer",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer", nil)
	end
})
ix.option.Add("observerESP", ix.type.bool, true, {
	category = "observer",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer ESP", nil)
	end
})
ix.option.Add("observerESPOnlyInNoclip", ix.type.bool, false, {
	category = "observer",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer ESP", nil)
	end
})
ix.option.Add("playerInfoESP", ix.type.bool, true, {
	category = "observer",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer ESP", nil)
	end
})
ix.option.Add("alwaysObserverLight", ix.type.bool, true, {
    category = "observer",
    hidden = function()
        return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer")
    end,
	bNetworked = true
})
ix.option.Add("observerFullBright", ix.type.bool, false, {
    category = "observer",
    hidden = function()
        return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer")
    end,
	bNetworked = true
})

ix.util.Include("cl_hooks.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	optPlayerInfoESP = "Show Admin ESP Extra Info",
	optdPlayerInfoESP = "Shows extra player info in the ESP, such as their HP/Armor, steam name and other data.",
	optAlwaysObserverLight = "Always Turn On Observer Light",
    optdAlwaysObserverLight = "Turn on your observer light automatically when entering observer. Otherwise it will follow your flashlight. Can still be turned off manually.",
	optObserverFullBright = "Observer Light Full Bright",
    optdObserverFullBright = "Light up the entire map when enabling the Observer Light.",
	optObserverESPOnlyInNoclip = "Observer ESP Only In Noclip",
	optdObserverESPOnlyInNoclip = "Show the admin ESP only in noclip. Otherwise people's IC name is always shown when not in observer."
})

ix.lang.AddTable("spanish", {
	optdSteamESP = "Muestra el SteamID de un jugador, su salud/armadura en el admin ESP",
	optdAlwaysObserverLight = "Enciende la luz del observer automáticamente al entrar en él. De lo contrario seguirá tu linterna. Se puede apagar manualmente.",
	optAlwaysObserverLight = "Encender siempre la luz del observer",
	optSteamESP = "Muestra la información extra del Admin ESP",
	optdMapscenesESP = "Mostrar las localizaciones de Escenarios del Mapa en el Admin-ESP.",
	optMapscenesESP = "Mostrar el ESP del Escenario"
})

function PLUGIN:CanPlayerEnterObserver(client)
	if (CAMI.PlayerHasAccess(client, "Helix - Observer", nil)) then
		return true
	else
		return false
	end
end