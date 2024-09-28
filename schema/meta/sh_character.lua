
local ix = ix
local Schema = Schema

local CHAR = ix.meta.character

function CHAR:GetFactionVar(variable, default)
	local faction = ix.faction.Get(self:GetFaction())
	if (!faction) then return end

	return faction[variable] or default
end