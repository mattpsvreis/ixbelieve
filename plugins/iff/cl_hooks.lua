local ix = ix
local Color = Color
local LocalPlayer = LocalPlayer
local coroutine = coroutine
local string = string
local ipairs = ipairs
local player = player
local IsValid = IsValid
local team = team
local FrameNumber = FrameNumber
local Vector = Vector
local math = math
local surface = surface
local ColorAlpha = ColorAlpha
local table = table
local draw = draw

local PLUGIN = PLUGIN
PLUGIN.coroutine = nil


ix.lang.AddTable("english", {
	optShowIFF = "Show IFF",
	optdShowIFF = "Show the IFF markers above people.",
	optShowIFFRank = "Show IFF Rank",
	optdShowIFFRank = "Show the IFF rank image in people's IFF."
})

ix.option.Add("showIFF", ix.type.bool, true, {
	category = "general",
})

ix.option.Add("showIFFRank", ix.type.bool, true, {
	category = "general",
})

local color_white, color_black = Color(255, 255, 255), Color(0, 0, 0)

function PLUGIN:HUDPaint()
	local myPos = LocalPlayer():GetPos()
	local zoom = LocalPlayer():KeyDown(IN_ZOOM)

	PLUGIN.coroutine = PLUGIN.coroutine and coroutine.status(PLUGIN.coroutine) != "dead" and PLUGIN.coroutine or coroutine.create(function ()
		while (true) do
			for _, target in ipairs(player.GetAll()) do
				local mySquad = string.lower(LocalPlayer():GetNetVar("iffSquadName", ""))
				if (target == LocalPlayer()) then
					coroutine.yield()
					continue
				end

				--if not v.HUDBeacon or FrameNumber() % 60 == 0 then
				if (!IsValid(target)) then
					coroutine.yield()
					continue
				end

				local faction = ix.faction.Get(target:Team())
				local character = target:GetCharacter()
				if (!faction or !character or target:GetFactionVar("noIFF")) then
					target.ixHUDBeaconColor = nil
					coroutine.yield()
					continue
				end

				local color = target:GetFactionVar("hudColor") or target:GetFactionVar("color")
				if (!color) then
					target.ixHUDBeaconColor = nil
					coroutine.yield()
					continue
				end

				target.TeamColor = team.GetColor(target:Team())
				target.ixHUDBeaconColor = color
				target.ixSquad = string.lower(target:GetNetVar("iffSquadName", ""))
				target.ixSquadFT = target:GetNetVar("iffFireTeam")
				target.ixSquadRole = target:GetNetVar("iffRole")
				target.ixSameSquad = (mySquad != "" and target.ixSquad == mySquad)
				target.ixIFF = target:GetNetVar("iffMode")

				target.HUDInitials = character:GetInitials()
				local img = character:GetRankImage()
				if (!target.HUDBeacon or target.HUDBeaconImg != img) then
					target.HUDBeaconImg = img
					target.HUDBeacon = ix.util.GetMaterial(img)
				end
				--end
				coroutine.yield()
			end
		end
	end)

	if (FrameNumber() % 5 == 0) then
		local succ, err = coroutine.resume(PLUGIN.coroutine)
		if (!succ) then
			ErrorNoHalt(err)
		end
	end

	local senserPos = LocalPlayer():GetNetVar("SenserViewPos")
	if (ix.option.Get("showIFF")) then
		-- Player sight
		for k, target in ipairs(player.GetAll()) do
			if (!IsValid(target) or target == LocalPlayer() or target:GetMoveType() == MOVETYPE_NOCLIP or !target:Alive() or !target.ixHUDBeaconColor) then continue end

			-- If they have their IFF turned off
			if (target.ixIFF == 3) then continue end

			-- If they have their IFF set to squad only mode
			if (target.ixIFF == 2 and !target.ixSameSquad) then continue end


			local targetPos = target:GetPos()
			local dist = targetPos:Distance(senserPos or myPos)
			local zPos = targetPos + Vector(0, 0, math.Clamp(dist/30, 0, 114) + 70)

			if (!target.ixSameSquad and !LocalPlayer():IsLineOfSightClear(zPos) and
				(!senserPos or !target:IsLineOfSightClear(senserPos))) then
				continue
			end

			surface.SetDrawColor(ColorAlpha(target.ixHUDBeaconColor, target.ixSameSquad and 180 or 100))
			surface.SetMaterial(target.HUDBeacon)

			sz = math.Clamp(32 - (32 * (dist/16000)), zoom and w24 or 16, 32)
			if (zoom) then
				sz = sz * 2
			end

			if (target.ixSameSquad) then
				sz = sz * 2
			end

			local zPos2D = zPos:ToScreen()
			local color
			if (ix.option.Get("showIFFRank")) then
				color = color_white
				surface.DrawTexturedRect(zPos2D.x - sz/2, zPos2D.y - sz/2, sz, sz)
			else
				if (target.ixSameSquad) then
					color = target.ixHUDBeaconColor
				else
					color = color_white
				end
				sz = 0
			end

			if (target.ixSquad and target.ixSquad != "") then
				local text = table.concat({target.HUDInitials, "\n", "[", PLUGIN.GetIFFText(target.ixSquad, target.ixSquadFT, target.ixSquadRole), "]"}, "")
				draw.DrawText(text, "HUD_Oxanium", zPos2D.x + 1, zPos2D.y + 1 - sz - 16, ColorAlpha(color_black, target.ixSameSquad and 220 or 140), TEXT_ALIGN_CENTER)
				draw.DrawText(text, "HUD_Oxanium", zPos2D.x, zPos2D.y - sz - 16, ColorAlpha(color, target.ixSameSquad and 220 or 100), TEXT_ALIGN_CENTER)
			else
				draw.DrawText(target.HUDInitials, "HUD_Oxanium", zPos2D.x + 1, zPos2D.y + 1 - sz - 8, ColorAlpha(color_black, target.ixSameSquad and 220 or 140), TEXT_ALIGN_CENTER)
				draw.DrawText(target.HUDInitials, "HUD_Oxanium", zPos2D.x, zPos2D.y - sz -8, ColorAlpha(color, target.ixSameSquad and 220 or 100), TEXT_ALIGN_CENTER)
			end
		end
	end
end
