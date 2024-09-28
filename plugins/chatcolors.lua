
local PLUGIN = PLUGIN

PLUGIN.name = "Chat colour"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Allows admins to adjust chat colours"

ix.config.Add("meChatColour", Color(255, 255, 255), "Default chat color for /me's.", nil, {category = "chat"})
ix.config.Add("itChatColour", Color(255, 255, 255), "Default chat color for /it's.", nil, {category = "chat"})
ix.config.Add("whisperChatColour", Color(255, 255, 255), "Default chat color for this type of chat.", nil, {category = "chat"})
ix.config.Add("yellChatColour", Color(255, 255, 255), "Default chat color for this type of chat.", nil, {category = "chat"})
ix.config.Add("oocChatColour", Color(255, 255, 255), "Default chat color for this type of chat.", nil, {category = "chat"})
ix.config.Add("loocChatColour", Color(255, 255, 255), "Default chat color for this type of chat.", nil, {category = "chat"})

ix.lang.AddTable("english", {
	cmdMeC = "Perform a short-range physical action.",
	cmdMeL = "Perform a long-range physical action.",
	cmdMeD = "Perform a direct physical action. Only the person you are looking at will see this.",
	cmdItC = "Make something around you perform a short-range action.",
	cmdItL = "Make something around you perform a long-range action.",
	cmdItD = "Make something around you perform an action. Only the person you are looking at will see this.",
	globalOOCDisabled = "Global OOC is disabled on this server.",
	optOOCShowSteamName = "Show Steam Names in OOC",
	optdOOCShowSteamName = "Both a player's character name and steam name will be shown in OOC chat when your admin is enabled.",
})

ix.option.Add("OOCShowSteamName", ix.type.bool, true, {
	category = "Chat",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Admin", nil)
	end
})

CAMI.RegisterPrivilege({
	Name = "Helix - Bypass OOC Disable",
	MinAccess = "admin",
	Description = "Allow using OOC regardless even if it is disabled."
})

function PLUGIN.InitializedChatClasses()
	ix.chat.Register("ic", {
		indicator = "chatTalking",
		OnChatAdd = function(self,speaker,text)
			if (LocalPlayer():GetEyeTrace().Entity == speaker) then
				chat.AddText(team.GetColor(speaker:Team()),speaker:GetName(),ix.config.Get("chatListenColor")," says \""..text.."\"")
				return
			end

			chat.AddText(team.GetColor(speaker:Team()),speaker:GetName(),ix.config.Get("chatColor")," says \""..text.."\"")
		end,
		CanHear = ix.config.Get("chatRange", 280)
	})

	ix.chat.Register("w", {
		CanHear = ix.config.Get("chatRange", 280) * 0.25,
		prefix = {"/W", "/Whisper"},
		description = "@cmdW",
		indicator = "chatWhispering",
		OnChatAdd = function(self,speaker,text)
			local colorGet = ix.config.Get("whisperChatColour")

			chat.AddText(team.GetColor(speaker:Team()),speaker:GetName(),colorGet," whispers \""..text.."\"")
		end
	})

	ix.chat.Register("y", {
		CanHear = ix.config.Get("chatRange", 280) * 2,
		prefix = {"/Y", "/Yell"},
		description = "@cmdY",
		indicator = "chatYelling",
		OnChatAdd = function(self,speaker,text)
			local colorGet = ix.config.Get("yellChatColour")

			chat.AddText(team.GetColor(speaker:Team()),speaker:GetName(),colorGet," yells \""..text.."\"")
		end
	})

	ix.chat.Register("me", {
		CanHear = ix.config.Get("chatRange", 280) * 2,
		prefix = {"/Me", "/Action"},
		description = "@cmdMe",
		indicator = "chatPerforming",
		deadCanChat = true,
		OnChatAdd = function(self,speaker,text)
			chat.AddText(team.GetColor(speaker:Team()),"*** "..speaker:GetName(),ix.config.Get("meChatColour")," "..text)
		end
	})

	ix.chat.Register("mec", {
		CanHear = ix.config.Get("chatRange", 280) * 0.25,
		prefix = {"/MeC"},
		description = "@cmdMeC",
		indicator = "chatPerforming",
		deadCanChat = true,
		OnChatAdd = function(self,speaker,text)
			chat.AddText(team.GetColor(speaker:Team()),"* "..speaker:GetName(),ix.config.Get("meChatColour")," "..text)
		end
	})

	ix.chat.Register("mel", {
		CanHear = ix.config.Get("chatRange", 280) * 4,
		prefix = {"/MeL"},
		description = "@cmdMeL",
		indicator = "chatPerforming",
		deadCanChat = true,
		OnChatAdd = function(self,speaker,text)
			chat.AddText(team.GetColor(speaker:Team()),"**** "..speaker:GetName(),ix.config.Get("meChatColour")," "..text)
		end
	})

	ix.chat.Register("med", {
		deadCanChat = true,
		OnChatAdd = function(self,speaker,text)
			chat.AddText(team.GetColor(speaker:Team()),"** "..speaker:GetName(),ix.config.Get("meChatColour")," "..text)
		end
	})

	ix.command.Add("MeD", {
		description = "@cmdMeD",
		arguments = ix.type.text,
		OnCheckAccess = function() return true end,
		OnRun = function(self, client, text)
			local trace = client:GetEyeTraceNoCursor()
			if (!IsValid(trace.Entity) or !trace.Entity:IsPlayer()) then return end

			ix.chat.Send(client, "med", text, nil, {client, trace.Entity})
		end
	})

	ix.chat.Register("it", {
		OnChatAdd = function(self, speaker, text)
			chat.AddText(ix.config.Get("itChatColour", Color(255, 255, 255)), "*** "..text)
		end,
		CanHear = ix.config.Get("chatRange", 280) * 2,
		prefix = {"/It"},
		description = "@cmdIt",
		indicator = "chatPerforming",
		deadCanChat = true
	})

	ix.chat.Register("itc", {
		OnChatAdd = function(self, speaker, text)
			chat.AddText(ix.config.Get("itChatColour", Color(255, 255, 255)), "* "..text)
		end,
		CanHear = ix.config.Get("chatRange", 280) * 0.25,
		prefix = {"/ItC"},
		description = "@cmdItC",
		indicator = "chatPerforming",
		deadCanChat = true
	})

	ix.chat.Register("itl", {
		OnChatAdd = function(self, speaker, text)
			chat.AddText(ix.config.Get("itChatColour", Color(255, 255, 255)), "**** "..text)
		end,
		CanHear = ix.config.Get("chatRange", 280) * 4,
		prefix = {"/ItL"},
		description = "@cmdItL",
		indicator = "chatPerforming",
		deadCanChat = true
	})

	ix.chat.Register("itd", {
		deadCanChat = true,
		OnChatAdd = function(self,speaker,text)
			chat.AddText(ix.config.Get("itChatColour", Color(255, 255, 255)), "** "..text)
		end
	})

	ix.command.Add("ItD", {
		description = "@cmdItD",
		arguments = ix.type.text,
		OnCheckAccess = function() return true end,
		OnRun = function(self, client, text)
			local trace = client:GetEyeTraceNoCursor()
			if (!IsValid(trace.Entity) or !trace.Entity:IsPlayer()) then return end

			ix.chat.Send(client, "itd", text, nil, {client, trace.Entity})
		end
	})

	ix.chat.Register("ooc", {
		CanSay = function(self, speaker, text)
			if (!ix.config.Get("allowGlobalOOC")) then
				if (!CAMI.PlayerHasAccess(speaker, "Helix - Bypass OOC Disable")) then
					speaker:NotifyLocalized("globalOOCDisabled")
					return false
				elseif (!speaker.ixLastOOC or speaker.ixLastOOC + 30 < CurTime()) then
					speaker:Notify("OOC is disabled, but you can bypass this. Please don't spam unneeded messages.")
				end
			end
			local delay = ix.config.Get("oocDelay", 10)

			-- Only need to check the time if they have spoken in OOC chat before.
			if (delay > 0 and speaker.ixLastOOC) then
				local lastOOC = CurTime() - speaker.ixLastOOC

				-- Use this method of checking time in case the oocDelay config changes.
				if (lastOOC <= delay and !CAMI.PlayerHasAccess(speaker, "Helix - Bypass OOC Timer", nil)) then
					speaker:NotifyLocalized("oocDelay", delay - math.ceil(lastOOC))

					return false
				end
			end

			-- Save the last time they spoke in OOC.
			speaker.ixLastOOC = CurTime()
		end,
		OnChatAdd = function(self, speaker, text)
			if (!IsValid(speaker)) then
				return
			end

			local userGroup = CAMI.GetUsergroup(speaker:GetUserGroup())
			local icon = (userGroup.Icon or "user")
			icon = ix.util.GetMaterial("icon16/"..(hook.Run("GetPlayerIcon", speaker, icon) or icon)..".png")

			local color = ix.config.Get("oocChatColour", Color(255, 255, 255))
			if (CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Admin") and ix.option.Get("OOCShowSteamName")) then
				chat.AddText(icon, color, "[OOC] ", speaker:GetNametagColor() or team.GetColor(speaker:Team()), speaker:GetName(), " (", speaker:SteamName(), ")", color, ": "..text)
			else
				chat.AddText(icon, color, "[OOC] ", speaker:GetNametagColor() or team.GetColor(speaker:Team()), speaker:GetName(), color, ": "..text)
			end
		end,
		prefix = {"//", "/OOC"},
		description = "@cmdOOC",
		noSpaceAfter = true
	})

	ix.chat.Register("looc", {
		CanSay = function(self, speaker, text)
			local delay = ix.config.Get("loocDelay", 0)

			-- Only need to check the time if they have spoken in OOC chat before.
			if (delay > 0 and speaker.ixLastLOOC) then
				local lastLOOC = CurTime() - speaker.ixLastLOOC

				-- Use this method of checking time in case the oocDelay config changes.
				if (lastLOOC <= delay and !CAMI.PlayerHasAccess(speaker, "Helix - Bypass OOC Timer", nil)) then
					speaker:NotifyLocalized("loocDelay", delay - math.ceil(lastLOOC))

					return false
				end
			end

			-- Save the last time they spoke in OOC.
			speaker.ixLastLOOC = CurTime()
		end,
		OnChatAdd = function(self, speaker, text)
			if (!IsValid(speaker)) then
				return
			end

			local userGroup = CAMI.GetUsergroup(speaker:GetUserGroup())
			local icon = (userGroup.Icon or "user")
			icon = ix.util.GetMaterial("icon16/"..(hook.Run("GetPlayerIcon", speaker, icon) or icon)..".png")

			local color = ix.config.Get("loocChatColour", Color(255, 255, 255))
			chat.AddText(icon, color, "[LOOC] " .. speaker:Name()..": "..text)
		end,
		CanHear = ix.config.Get("chatRange", 280),
		prefix = {".//", "[[", "/LOOC"},
		description = "@cmdLOOC",
		noSpaceAfter = true
	})
end
