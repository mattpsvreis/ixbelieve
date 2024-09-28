
local PLUGIN = PLUGIN

PLUGIN.name = "Screen Notifications"
PLUGIN.author = "Gr4Ss"
PLUGIN.description = "Adds center-screen notifications that are really hard to miss."

if (SERVER) then return end

PLUGIN.notices = PLUGIN.notices or {}

function PLUGIN:AddNotif(text, color)
	local panel = vgui.Create("ScreenNoticePanel")
	panel.StartTime = SysTime()
	panel.Length = 5
	panel.VelX = -10
	panel.VelY = 0
	panel.fx = ScrW()
	panel.fy = ScrH() / 2
	panel:SetAlpha(255)
	local newText, length = {}, 0
	for k, v in ipairs(string.Explode(" ", text)) do
		local newLength = string.utf8len(v)
		if (length + newLength > 100) then
			if (length < 60) then
				newText[k] = string.sub(v, 1, 100 - 3 - length)
			end

			newText[#newText] = newText[#newText].."..."
			break
		end
		newText[k] = v
		length = length + newLength
	end
	panel:SetText(table.concat(newText, " "), color)
	panel:SetPos(panel.fx, panel.fy)

	table.insert(self.notices, panel)
end

function ix.util.ScreenNotify(text, color)
	PLUGIN:AddNotif(text, color)
end

-- This is ugly because it's ripped straight from the old notice system
local function UpdateNotice(panel, totalHeight)
	if (!IsValid(panel)) then
		return totalHeight
	end

	local x = panel.fx
	local y = panel.fy

	local w = panel:GetWide() + 16
	local h = panel:GetTall() + 4

	local panelIdealY = ScrH() / 4 - h + totalHeight
	local panelIdealX = ScrW() / 2 - w / 2

	local timeleft = panel.StartTime - (SysTime() - panel.Length)
	if (panel.Length < 0) then timeleft = 1 end

	-- Cartoon style about to go thing
	if (timeleft < 0.7) then
		panelIdealY = panelIdealY - 50
	end

	-- Gone!
	if (timeleft < 0.2) then
		panelIdealY = 0 - h * 2
	end

	local spd = RealFrameTime() * 15

	y = y + panel.VelY * spd
	x = x + panel.VelX * spd

	local dist = panelIdealY - y
	panel.VelY = panel.VelY + dist * spd * 1
	if (math.abs(dist) < 2 && math.abs(panel.VelY) < 0.1) then panel.VelY = 0 end

	dist = panelIdealX - x
	panel.VelX = panel.VelX + dist * spd * 1
	if (math.abs(dist) < 2 && math.abs(panel.VelX) < 0.1) then panel.VelX = 0 end

	-- Friction.. kind of FPS independant.
	panel.VelX = panel.VelX * (0.95 - RealFrameTime() * 8)
	panel.VelY = panel.VelY * (0.95 - RealFrameTime() * 8)

	panel.fx = x
	panel.fy = y

	-- If the panel is too high up (out of screen), do not update its position. This lags a lot when there are lot of panels outside of the screen
	if (panelIdealY > -ScrH()) then
		panel:SetPos(panel.fx, panel.fy)
	end

	return totalHeight + h
end

function PLUGIN:Think()
	if (!self.notices) then return end

	local h = 0
	for _, panel in ipairs(self.notices) do
		h = UpdateNotice(panel, h)
	end

	for i = #self.notices, 1, -1 do
		local panel = self.notices[i]
		if (!IsValid(panel) or panel:KillSelf()) then
            table.remove(self.notices, i)
        end
	end
end

local PANEL = {}
function PANEL:Init()
	self:DockPadding(3, 3, 3, 3)

	self.Label = vgui.Create("DLabel", self)
	self.Label:Dock(FILL)
	self.Label:SetFont("DermaLarge")
	self.Label:SetTextColor(color_white)
	self.Label:SetExpensiveShadow(1, Color(0, 0, 0, 200))
	self.Label:SetContentAlignment(5)

	self:SetBackgroundColor(Color(20, 20, 20, 255 * 0.6))
end

function PANEL:SetText(txt, color)
	self.Label:SetText(txt)
	self.Label:SetTextColor(color or color_white)
	self:SizeToContents()
end

function PANEL:SizeToContents()
	self.Label:SizeToContents()

	local width, tall = self.Label:GetSize()
	tall = math.max(tall, 32) + 6
	width = width + 20

	self:SetSize(width, tall)
	self:InvalidateLayout()
end

function PANEL:KillSelf()
	-- Infinite length
	if (self.StartTime + self.Length < SysTime()) then
		self:Remove()
		return true
	end

	return false
end

vgui.Register("ScreenNoticePanel", PANEL, "DPanel")
