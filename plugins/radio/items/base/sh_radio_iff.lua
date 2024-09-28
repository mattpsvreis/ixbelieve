
ITEM.name = "IFF-Transponder"
ITEM.description = "A small device that sends out your IFF signal to nearby units."
ITEM.category = "Radio"
ITEM.cost = 50
ITEM.weight = 0.2

ITEM.isRadio = true
ITEM.isIFF = true

ITEM.model = "models/deadbodies/dead_male_civilian_radio.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(0, -2.9635627269745, 198.21003723145),
	ang = Angle(90, 0, -70),
	fov = 4.2276261742374,
}

ITEM.maxFrequencies = 3

local squadText = {"ALPHA", "BRAVO", "CHARLIE", "DELTA", "CMD"}
local iffText = {"ALL", "SQUAD", "OFF"}
local iffExtra = {"\nAll friendly units can see your IFF.", "\nOnly your squad can see your IFF.", "\nYour IFF is off and cannot be seen by anyone."}

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		draw.SimpleText(
			iffText[item:GetData("iff", 0)] or "OFF", "DermaDefault", w - 5, 5,
			color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, color_black
		)

        if (item:GetData("enabled")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end

	local colors = {Color(0, 170, 0), Color(170, 130, 0), Color(170, 0, 0)}
	function ITEM:PopulateTooltip(tooltip)
        if (self:GetData("enabled")) then
			local name = tooltip:GetRow("name")
			name:SetBackgroundColor(derma.GetColor("Success", tooltip))
		end

		local channels = self:GetChannels()
		if (channels) then
			local channelNames = {}
			for k, v in ipairs(channels) do
				if (ix.radio:FindByID(v)) then
					channelNames[#channelNames + 1] = ix.radio:FindByID(v).name
				end
			end

			local chTip = tooltip:AddRowAfter("name", "channel")
			chTip:SetText("Channels: "..table.concat(channelNames, ", "))
			chTip:SizeToContents()
		end

		local iff = self:GetData("iff", 0)
		if (iff != 3) then
			local squad = tooltip:AddRowAfter("name", "squad")
			squad:SetBackgroundColor(Color(100, 255, 255))
			squad:SetText("SQUAD: "..believe.GetIFFText(self:GetData("squad"), self:GetData("fireTeam"), self:GetData("role")))
			squad:SizeToContents()
		end

		local iffMode = tooltip:AddRowAfter(iff == 3 and "name" or "squad", "iffMode")
		iffMode:SetBackgroundColor(colors[iff] or Color(255,255,255))
		iffMode:SetText("IFF MODE: "..(iffText[iff] or "OFF")..(iffExtra[iff] or ""))
		iffMode:SizeToContents()
	end
end

function ITEM:GetChannels(bForce)
    if (bForce or self:GetData("enabled")) then
		return self:GetData("channels", {})
	else
		return {}
	end
end

function ITEM:UpdateOwnerIFF()
	local owner = self:GetOwner()
	if (!IsValid(owner)) then return end
	owner:UpdateIFFInfo()
end

function ITEM:OnRemoved()
	self:SetData("iffMode", 3)
	self:UpdateOwnerIFF()

    self:SetData("enabled", false)
	local owner = self:GetOwner()
	if (owner) then
		for _, v in ipairs(self:GetChannels(true)) do
			ix.radio:RemoveListenerFromChannel(owner, v)
		end
	end
end

function ITEM:OnDestroyed(entity)
	self:SetData("enabled", false)
end

ITEM.functions.setIFF0Mode = {
	name = "Set IFF Mode",
	icon = "icon16/transmit.png",
	isMulti = true,
	multiOptions = function(item, player)
		local options = {}
		for k, v in ipairs(iffText) do
			options[#options + 1] = {name = v, data = {k}}
		end

        return options
	end,
	OnRun = function(item, data)
        local mode = tonumber(data and data[1] or 1)
        if (!mode or !iffText[mode]) then return false end

		item:SetData("iff", mode)
		item:UpdateOwnerIFF()

		return false
	end,
	OnCanRun = function(item)
        if (IsValid(item.entity)) then return false end

		return true
	end
}

ITEM.functions.setIFF1Squad = {
	name = "Set IFF Squad",
	icon = "icon16/font.png",
	isMulti = true,
	multiOptions = function(item, player)
		local options = {{name = "NONE", data = {-1}}}
		for k, v in ipairs(squadText) do
			options[#options + 1] = {name = v, data = {k}}
		end

		options[#options + 1] = {name = "OTHER", data = {0}, OnClick = function(itemTable)
			Derma_StringRequest("Set IFF Squad", "What squad name do you wish to use?", "", function(text)
				if (text == "") then return end

				net.Start("ixInventoryAction")
					net.WriteString("setIFF1Squad")
					net.WriteUInt(itemTable.id, 32)
					net.WriteUInt(itemTable.invID, 32)
					net.WriteTable({0, string.upper(text)})
				net.SendToServer()
			end)

			return false
		end}

        return options
	end,
	OnRun = function(item, data)
		if (data[1] == -1) then
			item:SetData("squad", "NONE")
			item:SetData("fireTeam", nil)
			item:SetData("role", nil)
			item:UpdateOwnerIFF()
			return false
		end
        local squad = data[2] or squadText[tonumber(data and data[1] or 0)]
		if (!squad) then return false end

		item:SetData("squad", squad)
		item:UpdateOwnerIFF()

		return false
	end,
	OnCanRun = function(item)
        if (IsValid(item.entity)) then return false end
		if (item:GetData("iff") == 3) then return false end

		return true
	end
}

local fireTeamText = {"NONE", "ONE", "TWO"}
ITEM.functions.setIFF2FT = {
	name = "Set IFF FireTeam",
	icon = "icon16/group.png",
	isMulti = true,
	multiOptions = function(item, player)
		local options = {}
		for k, v in ipairs(fireTeamText) do
			options[#options + 1] = {name = v, data = {k}}
		end

        return options
	end,
	OnRun = function(item, data)
        local mode = tonumber(data and data[1] or 1)
        if (!mode or !fireTeamText[mode]) then return false end

		if (mode > 1) then
			item:SetData("fireTeam", fireTeamText[mode])
		else
			item:SetData("fireTeam", nil)
		end
		item:UpdateOwnerIFF()

		return false
	end,
	OnCanRun = function(item)
        if (IsValid(item.entity)) then return false end
		if (item:GetData("iff") == 3) then return false end

		return true
	end
}

local roleText = {"NONE", "ACTUAL", "2IC"}
ITEM.functions.setIFF3Role = {
	name = "Set IFF Role",
	icon = "icon16/star.png",
	isMulti = true,
	multiOptions = function(item, player)
		local options = {}
		for k, v in ipairs(roleText) do
			options[#options + 1] = {name = v, data = {k}}
		end

        return options
	end,
	OnRun = function(item, data)
        local mode = tonumber(data and data[1] or 1)
        if (!mode or !roleText[mode]) then return false end

		if (mode > 1) then
			item:SetData("role", roleText[mode])
		else
			item:SetData("role", nil)
		end
		item:UpdateOwnerIFF()

		return false
	end,
	OnCanRun = function(item)
        if (IsValid(item.entity)) then return false end
		if (item:GetData("iff") == 3) then return false end

		return true
	end
}

ITEM.functions.setRadioFrequency = {
    name = "Set Frequency",
    icon = "icon16/transmit.png",
    isMulti = true,
    multiOptions = function(item, player)
        local options = {}
		for i = 1, item.maxFrequencies do
			options[i] = {name = "Freq "..i, OnClick = function(itemTbl)
                local freq = itemTbl:GetData("channels", {})[i]
                local freqText = freq and string.match(freq, "^freq_(%d%d%d)$") or ""
                Derma_StringRequest("Select Frequency", "Please enter the frequency you wish to switch to:", freqText, function(text)
                    local newFreq = tonumber(text)
                    if (string.len(text) == 3 and newFreq and newFreq >= 100) then
                        net.Start("ixInventoryAction")
                            net.WriteString("setRadioFrequency")
                            net.WriteUInt(itemTbl.id, 32)
                            net.WriteUInt(itemTbl.invID, 32)
                            net.WriteTable({i, text})
                        net.SendToServer()
                    else
                        player:Notify("Please enter a frequency between 100 and 999")
                    end
                end, nil, "Set", "Cancel")
                return false
            end}
		end

        return options
    end,
    OnRun = function(item, data)
		if (!data or !data[1]) then return false end
        if (data[1] < 1 or data[1] > item.maxFrequencies) then return false end
        local newFreq = tonumber(data[2])
        if (string.len(data[2]) != 3 or !newFreq or newFreq < 100) then return false end

        local channels = item:GetData("channels", {})
        local oldFreq = channels[data[1]]
        channels[data[1]] = "freq_"..data[2]
        item:SetData("channels", channels)

        if (oldFreq) then
			ix.radio:RemoveListenerFromChannel(item:GetOwner(), oldFreq)
		end
        ix.radio:AddListenerToChannel(item:GetOwner(), channels[data[1]])

		return false
	end,
	OnCanRun = function(item)
        if (IsValid(item.entity)) then return false end

		return true
	end
}

ITEM.functions.setRadioOn = {
	name = "Toggle Radio On",
	icon = "icon16/connect.png",
	OnRun = function(item)
		item:SetData("enabled", true)
		item.player:EmitSound("buttons/lever7.wav", 50, math.random(170, 180), 0.25)

		local owner = item:GetOwner()
		if (owner) then
			for _, v in ipairs(item:GetChannels()) do
				ix.radio:AddListenerToChannel(owner, v)
			end
		end

		return false
	end,
	OnCanRun = function(item)
		return item:GetData("enabled", false) == false
	end
}

ITEM.functions.setRadioOff = {
	name = "Toggle Radio Off",
	icon = "icon16/disconnect.png",
	OnRun = function(item)
		item:SetData("enabled", false)
		item.player:EmitSound("buttons/lever7.wav", 50, math.random(170, 180), 0.25)

		local owner = item:GetOwner()
		if (owner) then
			for _, v in ipairs(item:GetChannels(true)) do
				ix.radio:RemoveListenerFromChannel(owner, v)
			end
		end

		return false
	end,
	OnCanRun = function(item)
		return item:GetData("enabled", false) == true
	end
}

function ITEM:OnInstanced()
	self:SetData("iff", 1)
	self:SetData("squad", "NONE")
	self:SetData("fireTeam", nil)
	self:SetData("role", nil)
	local tbl = {"freq_300"}
	if (self.maxFrequencies > 1) then
		for i = 1, self.maxFrequencies - 1 do
			tbl[#tbl + 1] = "freq_10"..i
		end
	end
    self:SetData("channels", tbl)
end
