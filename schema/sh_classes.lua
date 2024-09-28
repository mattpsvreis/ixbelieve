ix.chat.Register("event", {
	CanSay = function () return true end,
	CanHear = function () return true end,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 150, 0), text)
	end,
	indicator = "chatPerforming"
})

ix.chat.Register("localevent", {
	CanHear = ix.config.Get("chatRange", 280) * 2,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 200, 0), text)
	end,
	indicator = "chatPerforming"
})

ix.chat.Register("privateevent", {
	CanSay = function () return true end,
	CanHear = function () return true end, -- handled by the cmd
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 100, 170), text)
	end,
	indicator = "chatPerforming"
})

-- Private messages between players.
ix.chat.Register("pda", {
	format = "[PDA] %s: %s",
	color = Color(0, 150, 150, 255),

	OnChatAdd = function(self, speaker, text, bAnonymous, data)
		chat.AddText(self.color, string.format(self.format, speaker:GetName(), text))

		if (LocalPlayer() != speaker) then
			surface.PlaySound("hl1/fvox/bell.wav")
		end
	end
})