
PLUGIN.name = "Admin"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Adds a simple admin system to Helix."

local PLUGIN = PLUGIN


function PLUGIN:ContextMenuOpened()
	if (IsValid(self.contextmenu)) then
		self.contextmenu:Remove()
	end

	if (!CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands")) then
		return
	end

	local players = player.GetAll()
	table.sort(players, function (a, b)
		return a:Name() < b:Name()
	end)

	local commands = {}
	local set = {}
	for k, v in pairs(ix.command.list) do
		if (!v.arguments or #v.arguments == 0) then continue end
		if (set[v.name]) then continue end
		if (v.privilege != "Basic Admin Commands" and !v.bContextMenu) then continue end
		if (!v:OnCheckAccess(LocalPlayer())) then continue end

		local arg1 = v.arguments[1]
		if (bit.band(arg1, ix.type.character) == ix.type.character or bit.band(arg1, ix.type.player) == ix.type.player) then
			commands[#commands + 1] = v
			set[v.name] = true
		end
	end

	table.SortByMember(commands, "name", true)

	local menu = vgui.Create("DMenu")
	for k, client in ipairs(players) do
		local name = client.SteamName and string.format("%s (%s)", client:Name(), client:SteamName()) or client:Name()
		local subMenu = menu:AddSubMenu(name, function ()
			LocalPlayer():ConCommand([[say /goto "]] .. client:Name() .. [["]])
		end)

		for _, cmd in ipairs(commands) do
			subMenu:AddOption(cmd.name, function ()
				if (#cmd.arguments > 1) then
					if (!IsValid(ix.gui.chat)) then return end
					local chatbox = ix.gui.chat

					local txt = string.format("/%s \"%s\" ", cmd.name, client:Name())
					chatbox.entry:SetText(txt)
					chatbox.entry:SetCaretPos(string.len(txt))
					chatbox.entry:OnValueChange(txt)
					chatbox:SetActive(true)
				else
					LocalPlayer():ConCommand([[say /]]..cmd.name..[["]] .. client:Name() .. [["]])
				end
			end)
		end
	end

	menu:Open(ScrW() * 0.1, ScrH() * 0.5 - menu:GetTall()/2)
	self.contextmenu = menu
end