local properties = properties
local IsValid = IsValid
local Derma_StringRequest = Derma_StringRequest
local CAMI = CAMI
local hook = hook
local SetClipboardText = SetClipboardText
local LocalPlayer = LocalPlayer
local net = net
local ix = ix

local PLUGIN = PLUGIN

properties.Add("ixCopyCharName", {
	MenuLabel = "#Copy Character Name",
	Order = 0,
	MenuIcon = "icon16/user.png",

	Filter = function(self, target)
        return target:IsPlayer()
            and CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands")
            and hook.Run("CanProperty", LocalPlayer(), "ixCopyCharName", target) != false
	end,

    Action = function(self, target)
        SetClipboardText(target:Name())
		LocalPlayer():NotifyLocalized("bastionCopiedCharName")
	end,
})

properties.Add("ixCopySteamName", {
	MenuLabel = "#Copy Steam Name",
	Order = 1,
	MenuIcon = "icon16/user.png",

	Filter = function(self, target)
        return target:IsPlayer()
            and CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands")
            and hook.Run("CanProperty", LocalPlayer(), "ixCopySteamName", target) != false
	end,

    Action = function(self, target)
        SetClipboardText(target:SteamName())
		LocalPlayer():NotifyLocalized("bastionCopiedSteamName")
	end,
})

properties.Add("ixCopySteamID", {
	MenuLabel = "#Copy Steam ID",
	Order = 2,
	MenuIcon = "icon16/user.png",

	Filter = function(self, target)
        return target:IsPlayer()
            and CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands")
            and hook.Run("CanProperty", LocalPlayer(), "ixCopySteamID", target) != false
	end,

    Action = function(self, target)
        SetClipboardText(target:SteamID())
		LocalPlayer():NotifyLocalized("bastionCopiedSteamID")
	end,
})

properties.Add("ixCopySteamID64", {
	MenuLabel = "#Copy Steam ID64",
	Order = 3,
	MenuIcon = "icon16/user.png",

	Filter = function(self, target)
        return target:IsPlayer()
            and CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands")
            and hook.Run("CanProperty", LocalPlayer(), "ixCopySteamID64", target) != false
	end,

    Action = function(self, target)
        SetClipboardText(target:SteamID64())
		LocalPlayer():NotifyLocalized("bastionCopiedSteamID")
	end,
})

properties.Add("ixViewInventory", {
	MenuLabel = "#View Inventory",
	Order = 10,
	MenuIcon = "icon16/eye.png",
	PrependSpacer = true,

	Filter = function(self, target, client)
		client = client or LocalPlayer()
		return target:IsPlayer()
            and CAMI.PlayerHasAccess(client, "Helix - View Inventory")
            and hook.Run("CanProperty", client, "ixViewInventory", target) != false
	end,

	Action = function(self, target)
		self:MsgStart()
			net.WriteEntity(target)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local target = net.ReadEntity()

		if (!IsValid(target)) then return end
		if (!self:Filter(target, client)) then return end

		PLUGIN:OpenInventory(client, target)
	end
})

properties.Add("ixSetHealth", {
	MenuLabel = "#Health",
	Order = 100,
	PrependSpacer = true,
	MenuIcon = "icon16/heart.png",

	Filter = function(self, target, client)
		client = client or LocalPlayer()
		return target:IsPlayer()
			and (CAMI.PlayerHasAccess(client, "Helix - Basic Admin Commands") or CAMI.PlayerHasAccess(client, "Helix - Slay"))
			and hook.Run("CanProperty", client, "ixSetHealth", target) != false
	end,

	MenuOpen = function(self, option, target)
		local submenu = option:AddSubMenu()
		local maxHealth = target:GetMaxHealth()
		local step = maxHealth > 100 and -50 or -25

		for i = maxHealth, 1, step do
			submenu:AddOption(i, function() self:SetHealth(target, i) end)
		end

		submenu:AddOption("1", function() self:SetHealth(target, 1) end)
		submenu:AddOption("Kill", function() self:SetHealth(target, 0) end)
	end,

	SetHealth = function(self, target, health)
		self:MsgStart()
			net.WriteEntity(target)
			net.WriteUInt(health, 16)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local target = net.ReadEntity()
		local health = net.ReadUInt(16)

		if (!IsValid(target)) then return end
		if (!self:Filter(target, client)) then return end

		if (health > 0) then
			target:SetHealth(health)
			ix.log.Add(client, "bastionSetHealth", target)
		else
			target:Kill()
			ix.log.Add(client, "bastionSlay", target)
		end
	end
})

properties.Add("ixSetArmor", {
	MenuLabel = "#Armor",
	Order = 110,
	MenuIcon = "icon16/heart.png",

	Filter = function(self, target, client)
		client = client or LocalPlayer()
		return target:IsPlayer()
			and CAMI.PlayerHasAccess(client, "Helix - Basic Admin Commands")
			and hook.Run("CanProperty", client, "ixSetArmor", target) != false
	end,

	MenuOpen = function(self, option, target)
		local submenu = option:AddSubMenu()
		local maxArmor = 100
		local step = maxArmor > 100 and -50 or -10

		for i = maxArmor, 1, step do
			submenu:AddOption(i, function() self:SetArmor(target, i) end)
		end

		submenu:AddOption("Remove", function() self:SetArmor(target, 0) end)
	end,

	SetArmor = function(self, target, armor)
		self:MsgStart()
			net.WriteEntity(target)
			net.WriteUInt(armor, 16)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local target = net.ReadEntity()
		local armor = net.ReadUInt(16)

		if (!IsValid(target)) then return end
		if (!self:Filter(target, client)) then return end

		target:SetArmor(armor)
		ix.log.Add(client, "bastionSetArmor", target)
	end
})

properties.Add("ixSetCharName", {
	MenuLabel = "#Set Name",
	Order = 120,
	MenuIcon = "icon16/book_edit.png",
	PrependSpacer = true,

	Filter = function(self, entity, client)
		return CAMI.PlayerHasAccess(client, "Helix - CharSetName", nil) and entity:IsPlayer() and entity:GetCharacter()
	end,

	Action = function(self, entity)
		Derma_StringRequest("Set Name", "Set the character's name", entity:Name(), function(text)
			if (text == "") then return end

			self:MsgStart()
				net.WriteEntity(entity)
				net.WriteString(text)
			self:MsgEnd()
		end)

	end,

	Receive = function(self, length, client)
		if (CAMI.PlayerHasAccess(client, "Helix - CharSetName", nil)) then
			local entity = net.ReadEntity()
			local text = net.ReadString()

			if (IsValid(entity) and entity:IsPlayer() and entity:GetCharacter()) then
				local oldName = entity:GetCharacter():GetName()
				entity:GetCharacter():SetName(text)

				ix.log.Add(client, "bastionSetName", entity:GetCharacter(), oldName)
			end
		end
	end
})

properties.Add("ixSetCharDescription", {
	MenuLabel = "#Set Description",
	Order = 121,
	MenuIcon = "icon16/book_edit.png",

	Filter = function(self, entity, client)
		return CAMI.PlayerHasAccess(client, "Helix - Basic Admin Commands", nil) and entity:IsPlayer() and entity:GetCharacter()
	end,

	Action = function(self, entity)
		Derma_StringRequest("Set Description", "Set the character's description", entity:GetCharacter():GetDescription(), function(text)
			if (text == "") then return end

			self:MsgStart()
				net.WriteEntity(entity)
				net.WriteString(text)
			self:MsgEnd()
		end)

	end,

	Receive = function(self, length, client)
		if (CAMI.PlayerHasAccess(client, "Helix - Basic Admin Commands", nil)) then
			local entity = net.ReadEntity()
			local text = net.ReadString()

			if (IsValid(entity) and entity:IsPlayer() and entity:GetCharacter()) then
				entity:GetCharacter():SetDescription(text)

				ix.log.Add(client, "bastionSetDesc", entity:GetCharacter())
			end
		end
	end
})

properties.Add("ixViewContainer", {
	MenuLabel = "#View Container",
	Order = 11,
	MenuIcon = "icon16/eye.png",

	Filter = function(self, target, client)
		return target:GetClass() == "ix_container"
            and CAMI.PlayerHasAccess(client or LocalPlayer(), "Helix - View Inventory")
            and hook.Run("CanProperty", client or LocalPlayer(), "ixViewContainer", target) != false
	end,

	Action = function(self, target)
		self:MsgStart()
			net.WriteEntity(target)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local target = net.ReadEntity()

		if (!IsValid(target)) then return end
		if (!self:Filter(target, client)) then return end

		local inventory = target:GetInventory()
		if (inventory) then
			local name = target:GetDisplayName()

			ix.storage.Open(client, inventory, {
				name = name,
				entity = target,
				bMultipleUsers = true,
				searchTime = 0,
				data = {money = target:GetMoney()},
				OnPlayerClose = function()
					ix.log.Add(client, "containerAClose", name, inventory:GetID())
				end
			})

			ix.log.Add(client, "containerAOpen", name, inventory:GetID())
		end
	end
})

properties.Add("ixContainerCreate", {
	MenuLabel = "Make Container",
	Order = 401,
	MenuIcon = "icon16/tag_blue_edit.png",

	Filter = function(self, entity, client)
		if (ix.config.Get("AllowContainerSpawn")) then return false end
		if (entity:GetClass() != "prop_physics") then return false end
		if (!gamemode.Call("CanProperty", client, "ixContainerCreate", entity)) then return false end
		local model = string.lower(entity:GetModel())
		if (!ix.container.stored[model]) then return false end

		return true
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		local model = string.lower(entity:GetModel())
		local data = ix.container.stored[model]

		local container = ents.Create("ix_container")
		container:SetPos(entity:GetPos())
		container:SetAngles(entity:GetAngles())
		container:SetModel(model)
		container:Spawn()

		ix.inventory.New(0, "container:" .. model, function(inventory)
			-- we'll technically call this a bag since we don't want other bags to go inside
			inventory.vars.isBag = true
			inventory.vars.isContainer = true

			if (IsValid(container)) then
				container:SetInventory(inventory)
				if (ix.saveEnts) then
					ix.saveEnts:SaveEntity(container)
				end
			end
		end)

		entity:Remove()

		ix.log.Add(client, "containerSpawned", data.name)
	end
})

properties.Add("ixPropViewOwner", {
	MenuLabel = "View Owner",
	Order = 405,
	MenuIcon = "icon16/magnifier.png",

	Filter = function(self, entity, client)
		if (entity:GetClass() == "prop_physics" and CAMI.PlayerHasAccess(client, "Helix - Basic Admin Commands", nil)) then return true end
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		local ownerCharacter = entity.ownerCharacter
		local ownerName = entity.ownerName
		local ownerSteamID = entity.ownerSteamID

		if (ownerCharacter and ownerName and ownerSteamID) then
			client:ChatNotifyLocalized("bastionPropOwnerInformation", ownerCharacter, ownerName, ownerSteamID)
		else
			client:ChatNotifyLocalized("bastionPropOwnerUnknown")
		end
	end
})