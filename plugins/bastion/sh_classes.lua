local ix = ix
local Color = Color
local chat = chat
local IsValid = IsValid
local surface = surface
local team = team

ix.chat.Register("announcement", {
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(254, 238, 60), "[ADMIN] ", text)
	end,
	CanSay = function(self, speaker, text)
		return true
	end
})


do
	local CLASS = {}
	CLASS.color = Color(225, 225, 128)
	CLASS.format = "[ADMIN] %s: %s"

	function CLASS:CanHear(speaker, listener)
		return CAMI.PlayerHasAccess(listener, "Helix - Admin")
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("admin", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(225, 128, 128)
	CLASS.format = "[REPORT] %s: %s"

	function CLASS:CanHear(speaker, listener)
		return CAMI.PlayerHasAccess(listener, "Helix - Hear Reports") or speaker == listener
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("report", CLASS)
end

-- ACHIEVEMENT
do
	local CLASS = {}

	if (CLIENT) then
		function CLASS:OnChatAdd(speaker, text, anonymous, data)
			if (!IsValid(data[1])) then return end

			if (data[2]) then
				surface.PlaySound(data[2])
			end

			local target = data[1]
			chat.AddText(team.GetColor(target:Team()), target:SteamName(), Color(255, 255, 255), " earned the achievement ",
			Color( 255, 201, 0, 255 ), text)
		end
	end

	ix.chat.Register("achievement_get", CLASS)
end
