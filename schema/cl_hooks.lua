local ix = ix
local Schema = Schema

function Schema:HUDPaint()
  local w, h = ScrW(), ScrH()
  if (BRANCH != "x86-64") then
		draw.SimpleText("You're using an incompatible version of Garry's Mod.","HUD_Oxanium", ScrW()-10,ScrH()-27,Color(255,128,128,255),TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
		draw.SimpleText("See https://steamcommunity.com/sharedfiles/filedetails/?id=2725447709 for information on how to fix this.","HUD_Oxanium", ScrW()-10,ScrH()-10,Color(192,128,128,255),TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
	end
end

function Schema:PostProcessPermitted(class)
	return true
end

function Schema:PrePlayerDraw(client, flags)
	if (client:GetNetVar("cloakEnabled")) then
		render.MaterialOverride(ix.util.GetMaterial("overlay/cloak"))
		client:DrawModel()
		render.MaterialOverride(nil)
		return true
	end
end

function Schema:PopulateCharacterInfo(client, character, container)
	-- overwrite helix description to show the full description instead
  local roleText = character:GetRole()


  if (roleText != nil and roleText != "") then
    local role = container:AddRow("role")
    role:SetText(roleText)
    role:SetTextColor(Color(128, 128, 192, 255))
    role:SizeToContents()
  end
	local descriptionText = character:GetDescription()
	if (descriptionText != "") then
		local description = container:AddRow("description")
		description:SetText(descriptionText)
		description:SizeToContents()
	end
	return true
end

function Schema:InitializedPlugins()
	local hp_bar = ix.bar.Get("health")
	hp_bar.color = Color(200, 50, 40)
	hp_bar.backcolor = Color(255, 0, 0)
	hp_bar.priority = -2

	local ap_bar = ix.bar.Get("armor")
	ap_bar.color = Color(30, 180, 30)
	ap_bar.priority = -1
end