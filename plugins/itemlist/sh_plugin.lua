local PLUGIN = PLUGIN

PLUGIN.name = "Itemlist"
PLUGIN.author = "Zombine, ported by Fruity"
PLUGIN.description = "Adds a spawn-menu tab with all registered items listed by category."

CAMI.RegisterPrivilege({
	Name = "Helix - Item Menu",
	MinAccess = "superadmin",
	Description = "Allows using the Item Menu to spawn and give items."
})

if (SERVER) then
	netstream.Hook("MenuItemSpawn", function(client, uniqueID)
		if (!IsValid(client)) then return end
		if (!CAMI.PlayerHasAccess(client, "Helix - Item Menu")) then return end

		local pos = client:GetEyeTraceNoCursor().HitPos

		ix.item.Spawn(uniqueID, pos + Vector( 0, 0, 10 ))
		ix.log.Add(client, "itemListSpawnedItem", uniqueID)

		hook.Run("PlayerSpawnedItem", client, pos, uniqueID)
	end)

	netstream.Hook("MenuItemGive", function(client, uniqueID)
		if (!IsValid(client)) then return end
		if (!CAMI.PlayerHasAccess(client, "Helix - Item Menu")) then return end

		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		inventory:Add(uniqueID, 1)
		ix.log.Add(client, "itemListGiveItem", uniqueID)

		hook.Run("PlayerGaveItem", client, client:GetCharacter(), uniqueID, 1)
	end)

	function PLUGIN:PlayerLoadedCharacter(client)
		netstream.Start(client, "CheckForItemTab")
	end

	ix.log.AddType("itemListSpawnedItem", function(client, name)
		return string.format("%s has spawned a %s.", client:GetName(), name)
	end)
	ix.log.AddType("itemListGiveItem", function(client, name)
		return string.format("%s has given himself a %s.", client:GetName(), name)
	end)
else
	local icons = {
		["Attachment"] = "attach",
		["Drink"] = "cake",
		["Drugs"] = "rainbow",
		["Emplacement"] = "gun",
		["Food"] = "cake",
		["JMOD"] = "wrench",
		["Magazines"] = "box",
		["NVG"] = "lightbulb",
		["Radio"] = "transmit",
		["Storage"] = "package",
		["Weapons"] = "gun",
		["Other"] = "brick",
	}

	spawnmenu.AddContentType("ixItem", function(container, data)
		if (!data.name) then return end

		local icon = vgui.Create("ContentIcon", container)

		icon:SetContentType("ixItem")
		icon:SetSpawnName(data.uniqueID)
		icon:SetName(L(data.name))

		icon.model = vgui.Create("ModelImage", icon)
		icon.model:SetMouseInputEnabled(false)
		icon.model:SetKeyboardInputEnabled(false)
		icon.model:StretchToParent(16, 16, 16, 16)
		icon.model:SetModel(data:GetModel(), data:GetSkin(), "000000000")
		icon.model:MoveToBefore(icon.Image)

		function icon:DoClick()
			netstream.Start("MenuItemSpawn", data.uniqueID)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		function icon:OpenMenu()
			local menu = DermaMenu()
			menu:AddOption("Copy Item ID to Clipboard", function()
				SetClipboardText(data.uniqueID)
			end)

			menu:AddOption("Give to Self", function()
				netstream.Start("MenuItemGive", data.uniqueID)
			end)

			if (data.customItem) then
				menu:AddOption("Delete Item", function()
					net.Start("ixDeleteCustomItem")
						net.WriteString(data.uniqueID)
					net.SendToServer()
				end)
			end

			menu:Open()

			for _, v in pairs(menu:GetChildren()[1]:GetChildren()) do
				if v:GetClassName() == "Label" then
					v:SetFont("MenuFontNoClamp")
				end
			end
		end

		if (IsValid(container)) then
			container:Add(icon)
		end
	end)

	local function CreateItemsPanel()
		local base = vgui.Create("SpawnmenuContentPanel")
		local tree = base.ContentNavBar.Tree
		local categories = {}

		vgui.Create("ItemSearch", base.ContentNavBar)

		for _, v in SortedPairsByMemberValue(ix.item.list, "category") do
			if (!categories[v.category] and not string.match( v.name, "Base" )) then
				categories[v.category] = true

				local category = tree:AddNode(v.category, icons[v.category] and ("icon16/" .. icons[v.category] .. ".png") or "icon16/brick.png")

				function category:DoPopulate()
					if (self.Container) then return end

					self.Container = vgui.Create("ContentContainer", base)
					self.Container:SetVisible(false)
					self.Container:SetTriggerSpawnlistChange(false)


					for _, itemTable in SortedPairsByMemberValue(ix.item.list, "name") do
						if (itemTable.category == v.category and not string.match( itemTable.name, "Base" )) then
							spawnmenu.CreateContentIcon("ixItem", self.Container, itemTable)
						end
					end
				end

				function category:DoClick()
					self:DoPopulate()
					base:SwitchPanel(self.Container)
				end
			end
		end

		local FirstNode = tree:Root():GetChildNode(0)

		if (IsValid(FirstNode)) then
			FirstNode:InternalDoClick()
		end

		PLUGIN:PopulateContent(base, tree, nil)

		local refresh = base.ContentNavBar:Add("DButton")
		refresh:Dock(BOTTOM)
		refresh:DockMargin(0, 10, 0, 0)
		refresh:SetText("Refresh")
		refresh.Paint = function(this, width, height)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, width, height)
		end
		refresh.DoClick = function()
			LocalPlayer():ConCommand("spawnmenu_reload")
		end

		return base
	end

	spawnmenu.AddCreationTab("Items", CreateItemsPanel, "icon16/script_key.png")

	netstream.Hook("CheckForItemTab", function()
		if !LocalPlayer():GetNWBool("spawnmenu_reloaded") then
			LocalPlayer():ConCommand( "spawnmenu_reload" )

			LocalPlayer():SetNWBool("spawnmenu_reloaded", true)
		end
	end)
end
