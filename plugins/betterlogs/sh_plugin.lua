local ix = ix
local CAMI = CAMI
local LocalPlayer = LocalPlayer

local PLUGIN = PLUGIN

PLUGIN.name = "Better Logs"
PLUGIN.author = "AleXXX_007"
PLUGIN.description = "Saves logs in a database and allows permitted staff to look them up."

ix.util.Include("cl_hooks.lua")
ix.util.Include("sv_hooks.lua")

CAMI.RegisterPrivilege({
	Name = "Helix - Manage Logs",
	MinAccess = "admin",
	Description = "Access to the in-game log tool."
})

CAMI.RegisterPrivilege({
	Name = "Helix - Tp",
	MinAccess = "admin",
	Description = "Access to teleport to a log's location."
})

ix.lang.AddTable("english", {
	optLogDefaultTime = "Default Log Search Time",
	optdLogDefaultTime = "The default amount of time to search back for in the log search tool."
})

ix.lang.AddTable("spanish", {
	optdLogDefaultTime = "La cantidad de tiempo por defecto para buscar en la herramienta de búsqueda de registros.",
	optLogDefaultTime = "Tiempo de búsqueda de registros por defecto"
})

ix.option.Add("logDefaultTime", ix.type.string, "1d", {
	bNetworked = true,
	category = "administration",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Manage Logs", nil)
	end
})
