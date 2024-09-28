
local PLUGIN = PLUGIN

PLUGIN.name = "Chatbox"
PLUGIN.author = "`impulse & Xalphox & Dark"
PLUGIN.description = "Replaces the chatbox to enable customization, autocomplete, and useful info. Added droppables. Edited for Halo: Believe by Dark."

if (CLIENT) then
	ix.chat.history = ix.chat.history or {} -- array of strings the player has entered into the chatbox
	ix.chat.currentCommand = ""
	ix.chat.currentArguments = {}

	ix.option.Add("chatNotices", ix.type.bool, false, {
		category = "chat"
	})

	ix.option.Add("chatTimestamps", ix.type.bool, false, {
		category = "chat"
	})

	ix.option.Add("chatFontScale", ix.type.number, 1, {
		category = "chat", min = 0.1, max = 2, decimals = 2,
		OnChanged = function()
			hook.Run("LoadFonts", ix.config.Get("font"), ix.config.Get("genericFont"))
			PLUGIN:CreateChat()
		end
	})

	ix.option.Add("chatOutline", ix.type.bool, false, {
		category = "chat"
	})

	-- tabs and their respective filters
	ix.option.Add("chatTabs", ix.type.string, "", {
		category = "chat",
		hidden = function()
			return true
		end
	})

	-- tabs and their respective filters
	ix.option.Add("additionalChatTabs", ix.type.string, "", {
		category = "chat",
		hidden = function()
			return true
		end
	})

	-- chatbox size and position
	ix.option.Add("chatPosition", ix.type.string, "", {
		category = "chat",
		hidden = function()
			return true
		end
	})

	-- chatbox size and position
	ix.option.Add("additionalChatPosition", ix.type.string, "", {
		category = "chat",
		hidden = function()
			return true
		end
	})

	function PLUGIN:CreateChat()
		if (IsValid(self.panel)) then
			self.panel:Remove()
		end

		self.panel = vgui.Create("ixChatbox")
		self.panel:SetupTabs(util.JSONToTable(ix.option.Get("chatTabs", "")))
		self.panel:SetupPosition(util.JSONToTable(ix.option.Get("chatPosition", "")))

		ix.gui.chat = self.panel

		hook.Run("ChatboxCreated")

		local additionalPanels = util.JSONToTable(ix.option.Get("additionalChatPosition", "")) or {}
		local additionalPanelsTabs = util.JSONToTable(ix.option.Get("additionalChatTabs", "")) or {}
		for k, v in pairs(additionalPanels) do
			if IsValid(self.additionalPanels[k]) then
				self.additionalPanels[k]:Remove()
			end

			if not additionalPanelsTabs[k] then
				continue
			end

			self:CreateExtraChat(k, v, additionalPanelsTabs[k])
		end
	end

	PLUGIN.additionalPanels = PLUGIN.additionalPanels or {}
	function PLUGIN:CreateExtraChat(name, position, tabs)
		if (IsValid(self.additionalPanels[name])) then
			self.additionalPanels[name]:Remove()
		end

		local pan = vgui.Create("ixChatbox")
		pan.name = name
		pan:SetupTabs(tabs)

		pan:SetupPosition(position)
		pan.entry:Remove()
		pan:SizeToContents()
		self.additionalPanels[name] = pan

		hook.Run("ChatboxCreated", name, pan, tabs, position)

		return pan
	end

	function PLUGIN:TabExists(id, panel)
		panel = panel or self.panel
		if (!IsValid(panel)) then
			return false
		end

		return panel.tabs:GetTabs()[id] != nil
	end

	function PLUGIN:SaveTabs()
		do
			local tabs = {}
			for id, panel in pairs(self.panel.tabs:GetTabs()) do
				tabs[id] = panel:GetFilter()
			end
			ix.option.Set("chatTabs", util.TableToJSON(tabs))
		end


		local additional = {}
		for k, v in pairs(self.additionalPanels) do
			local tabs = {}

			for id, panel in pairs(v.tabs:GetTabs()) do
				tabs[id] = panel:GetFilter()
			end

			additional[k] = tabs
		end
		ix.option.Set("additionalChatTabs", util.TableToJSON(additional))
	end

	function PLUGIN:SavePosition(panel)

		if panel == self.panel then
			local x, y = self.panel:GetPos()
			local width, height = self.panel:GetSize()

			ix.option.Set("chatPosition", util.TableToJSON({x, y, width, height}))
		else
			local additional = ix.option.Get("additionalChatPosition")
			additional = additional and util.JSONToTable(additional) or {}

			local x, y = panel:GetPos()
			local width, height = panel:GetSize()
			additional[panel.name] = {x, y, width, height}
			ix.option.Set("additionalChatPosition", util.TableToJSON(additional))
		end
	end

	function PLUGIN:InitPostEntity()
		self:CreateChat()
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		bind = bind:lower()

		if (bind:find("messagemode") and pressed) then
			for k, v in pairs(self.additionalPanels) do
				if IsValid(v) then
					v:SetActive(true)
				end
			end

			self.panel:SetActive(true)


			return true
		end
	end

	function PLUGIN:HUDShouldDraw(element)
		if (element == "CHudChat") then
			return false
		end
	end

	function PLUGIN:ScreenResolutionChanged(oldWidth, oldHeight)
		self:CreateChat()
	end

	function PLUGIN:ChatText(index, name, text, messageType)
		if (messageType == "none" and IsValid(self.panel)) then
			self.panel:AddMessage(text)

			for k, v in pairs(self.additionalPanels) do
				v:AddMessage(text)
			end
		end
	end

	-- luacheck: globals chat
	chat.ixAddText = chat.ixAddText or chat.AddText

	function chat.AddText(...)
		if (IsValid(PLUGIN.panel)) then
			PLUGIN.panel:AddMessage(...)
		end

		for k, v in pairs(PLUGIN.additionalPanels) do
			v:AddMessage(...)
		end

		-- log chat message to console
		local text = {}

		for _, v in ipairs({...}) do
			if (istable(v) or isstring(v)) then
				text[#text + 1] = v
			elseif (isentity(v) and v:IsPlayer()) then
				text[#text + 1] = team.GetColor(v:Team())
				text[#text + 1] = v:Name()
			elseif (type(v) != "IMaterial") then
				text[#text + 1] = tostring(v)
			end
		end

		text[#text + 1] = "\n"
		MsgC(unpack(text))
	end
else
	util.AddNetworkString("ixChatMessage")

	net.Receive("ixChatMessage", function(length, client)
		local text = net.ReadString()

		if ((client.ixNextChat or 0) < CurTime() and isstring(text) and text:find("%S")) then
			hook.Run("PlayerSay", client, text)
			client.ixNextChat = CurTime() + 0.5
		end
	end)
end
