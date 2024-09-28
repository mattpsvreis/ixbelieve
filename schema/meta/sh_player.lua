
local ix = ix
local Schema = Schema

local PLAYER = FindMetaTable("Player")

function PLAYER:GetFactionVar(variable, default)
	if (!self:GetCharacter()) then return end

	local faction = ix.faction.Get(self:Team())
	if (!faction) then return end

	return faction[variable] or default
end

local defaultVec = Vector(-1, -1, -1)
function PLAYER:GetNametagColor()
	local value = self:GetNetVar("BELIEVE_NAMETAG_COLOR", defaultVec)
	if (value != defaultVec) then
		return Color(value.x, value.y, value.z)
	end
end

function PLAYER:SetTeamColor(color)
	if color == nil then
		self:SetNetVar("BELIEVE_NAMETAG_COLOR", defaultVec)
		return
	end

	local vec = Vector(color.r, color.g, color.b)
	self:SetNetVar("BELIEVE_NAMETAG_COLOR", vec)
end
