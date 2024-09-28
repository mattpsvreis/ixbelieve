ix = ix or {}
ix.eventCharacters = ix.eventCharacters or {}

local CITIZEN_MODELS = {
	"models/humans/group01/male_01.mdl",
	"models/humans/group01/male_02.mdl",
	"models/humans/group01/male_04.mdl",
	"models/humans/group01/male_05.mdl",
	"models/humans/group01/male_06.mdl",
	"models/humans/group01/male_07.mdl",
	"models/humans/group01/male_08.mdl",
	"models/humans/group01/male_09.mdl",
	"models/humans/group02/male_01.mdl",
	"models/humans/group02/male_03.mdl",
	"models/humans/group02/male_05.mdl",
	"models/humans/group02/male_07.mdl",
	"models/humans/group02/male_09.mdl",
	"models/humans/group01/female_01.mdl",
	"models/humans/group01/female_02.mdl",
	"models/humans/group01/female_03.mdl",
	"models/humans/group01/female_06.mdl",
	"models/humans/group01/female_07.mdl",
	"models/humans/group02/female_01.mdl",
	"models/humans/group02/female_03.mdl",
	"models/humans/group02/female_06.mdl",
	"models/humans/group01/female_04.mdl"
}

local function getFactionModels(faction)
  local out = {}
  local models = ix.faction.teams[faction].models or CITIZEN_MODELS
  for k, v in pairs(models) do
    if type(v) == "string" then
      out[v] =
      {
        v,
        0,
        "000000000"
      }
    else
      out[v[1]] = v
    end
  end
  return out
end

ix.eventCharacters.current = ix.eventCharacters.current or {}
function ix.eventCharacters.drawPanel(parent)

	ix.eventCharacters.panel = parent

	local function bind(itm, t, key)
		if t[key] ~= nil then
			if itm.SetChecked then
				itm:SetChecked(t[key] == true)
			else
				itm:SetValue(t[key])
			end
		end
		itm.OnChange = function (v, bv)
			local value = bv or v:GetValue()
			t[key] = value
		end
		itm.OnValueChanged = function (v, value)
			t[key] = value
		end
		itm.OnSelect = function (v, idx, value, data)
			t[key] = value
		end
		return itm
	end

	function ix.eventCharacters.panel.buildPanel()
		local parent = ix.eventCharacters.panel

		for k, v in ipairs(parent:GetChildren()) do
			if k < 4 then continue end
			v:Remove()
		end

		local CurrentItem = ix.eventCharacters.current
		if CurrentItem == -1 then
			-- we're loading an item
			return
		end

    CurrentItem.characterID = CurrentItem.characterID or nil

    if CurrentItem.characterID then
      e = parent:Help("Database ID:\t" .. (CurrentItem.characterID or "-"))
      function e:DoClick()
        SetClipboardText(CurrentItem.characterID)
        ix.util.Notify("Copied character ID to clipboard.")
      end
    end

		e = bind(parent:TextEntry("Name"), CurrentItem, "name")
		e:SetPlaceholderText("Sgt. John Doe")

    local faction, mdl, mdlinput
    e = bind(parent:ComboBox("Faction"), CurrentItem, "faction")
    for k, v in pairs(ix.faction.teams) do
      e:AddChoice(v.name, k)
    end

    CurrentItem.faction = CurrentItem.faction or "mi"
    e:SetValue(ix.faction.teams[CurrentItem.faction].name, CurrentItem.faction)
    faction = e

    function e:OnSelect(idx, label, value)
      for k, v in pairs(mdl:GetChildren()[1]:GetChildren()) do
        v:Remove()
      end
      mdl:SetModelList(getFactionModels(value), "", true, true)

      for k, v in pairs(mdl:GetChildren()[1]:GetChildren()) do
        function v:DoClick()
          mdlinput:SetValue(v.Model)
          CurrentItem.model = v.Model
        end
      end
      CurrentItem.faction = value
      return true
		end

    local models = getFactionModels(CurrentItem.faction or "mi")
    local keys = table.GetKeys(models)

    e = bind(parent:TextEntry("Model"), CurrentItem, "model")
    CurrentItem.model = CurrentItem.model or keys[1]
    e:SetValue(CurrentItem.model)
    mdlinput = e

    mdl = vgui.Create("DModelSelect")
    mdl:SetModelList(models, "", true, true)
    for k, v in pairs(mdl:GetChildren()[1]:GetChildren()) do
      function v:DoClick()
        mdlinput:SetValue(v.Model)
        CurrentItem.model = v.Model
      end
    end
    mdl:SetHeight(2)
    parent:AddItem(mdl)

    CurrentItem.description = CurrentItem.description or ""
		e = bind(parent:TextEntry("Description"), CurrentItem, "description")
		e:SetTall(50)
		e:SetMultiline(true)
		e:SetPlaceholderText("6\"1, tall, hoarse voice")
		parent:AddItem(e)


		e = bind(parent:TextEntry("Notes"), CurrentItem, "notes")
		e:SetTall(50)
		e:SetMultiline(true)
		e:SetPlaceholderText("Use this to add any notes about how to use the event character")
		parent:AddItem(e)


    local clearButton = parent:Button("Clear")
    function clearButton:DoClick()
      ix.eventCharacters.current = {}
      ix.eventCharacters.panel.buildPanel()
    end

    local applyButton = parent:Button("Apply character to self")
    function applyButton:DoClick()
      local CurrentItem = ix.eventCharacters.current
      net.Start("ix.eventcharacters.apply")
        net.WriteString(CurrentItem.name)
        net.WriteString(CurrentItem.model)
        net.WriteString(CurrentItem.faction)
        net.WriteString(CurrentItem.description)
      net.SendToServer()
    end
	end

	-- Rebuild it if we're called again test
	local function presets()
		local panel = vgui.Create("DPanel")
		panel:SetTall(ScrH() * 0.2)
		panel:SetDrawBackground(false)

		local dtree  = vgui.Create( "DTree", panel )
		dtree:Dock( FILL )

		function dtree:RefreshPresets()
			dtree:Clear()

			believe.serverpresets.list('eventCharacters', function (ply, data)
				local function recurse(t, path, node)
					-- Folders first!
					for k, v in SortedPairs(t) do
						if (type(v) == "table") then
							local itm = node:AddNode(k, "icon16/folder.png")
							itm.itempath = path .. "/" .. k
							itm.empty = table.IsEmpty(v)

							function itm:DoClick()
							end

							function itm:DoRightClick()
								dtree:SetSelectedItem(itm)

								local menu = DermaMenu()


								opt = menu:AddOption("Refresh presets")
								opt:SetIcon("icon16/table_refresh.png")
								function opt:DoClick()
									dtree:RefreshPresets()
								end

								menu:AddSpacer()

								opt = menu:AddOption("Add folder")
								opt:SetIcon("icon16/folder_add.png")
								function opt:DoClick()
									Derma_StringRequest("Enter a folder name", "Please enter a title for the new folder", "", function (x)
										if (x == "") then return end

										if (string.find(x, ":", nil, true) or string.find(x, "/") or string.find(x, "\\") or string.EndsWith(x, ".")) then
											Derma_Message("The preset name must be a valid Windows folder name.", "Error", "OK")
											return
										end

										believe.serverpresets.folder('eventCharacters', itm.itempath .. "/" .. x)
										dtree:RefreshPresets()
									end)
								end

								opt = menu:AddOption("Save item")
								opt:SetIcon("icon16/drive_add.png")
								function opt:DoClick()
									Derma_StringRequest("Enter a file name", "Please enter a title for the new file", string.Replace(ix.eventCharacters.current.name, ".", "") or "", function (x)
										if (x == "") then return end

										if (string.find(x, ".", nil, true) or string.find(x, ":", nil, true) or string.find(x, "/") or string.find(x, "\\") or string.EndsWith(x, ".")) then
											Derma_Message("The preset name must be a valid Windows file name.", "Error", "OK")
											return
										end

                    PrintTable(ix.eventCharacters.current)

										believe.serverpresets.save('eventCharacters', itm.itempath .. "/" .. x, util.TableToJSON(ix.eventCharacters.current))
										dtree:RefreshPresets()
									end)
								end

								opt = menu:AddOption("Delete")
								opt:SetIcon("icon16/delete.png")
								function opt:DoClick()

									if (not itm.empty) then
										Derma_Message("You can only delete empty folders.", "Error", "OK")
										return
									end

									Derma_Query("Are you sure you want to delete '" .. itm.itempath .. "'", "Delete preset", "Yes", function (x)
										believe.serverpresets.delete('eventCharacters', string.TrimLeft(itm.itempath, "/"))
										dtree:RefreshPresets()
									end, "Cancel")
								end

								menu:Open()
							end
							recurse(v, itm.itempath, itm)
						end
					end

					for k, v in SortedPairs(t) do
						if (type(v) == "table") then
							continue
						end

						local ico = "icon16/page.png"
						local itm = node:AddNode(k, ico)
						itm.itempath = path .. "/" .. k

						function itm:DoClick()
							ix.eventCharacters.current = -1
							ix.eventCharacters.panel.buildPanel()

							believe.serverpresets.get('eventCharacters', string.TrimLeft(itm.itempath, "/"), function (ply, data)
								ix.eventCharacters.current = data and util.JSONToTable(data) or {}
								ix.eventCharacters.panel.buildPanel()
							end)
						end

						function itm:DoRightClick()
							dtree:SetSelectedItem(itm)

							local menu = DermaMenu()


							opt = menu:AddOption("Refresh presets")
							opt:SetIcon("icon16/table_refresh.png")
							function opt:DoClick()
								dtree:RefreshPresets()
							end

							menu:AddSpacer()


							opt = menu:AddOption("Open")
							opt:SetIcon("icon16/pencil.png")
							function opt:DoClick()
								ix.eventCharacters.current = -1
								ix.eventCharacters.panel.buildPanel()

								believe.serverpresets.get('eventCharacters', string.TrimLeft(itm.itempath, "/"), function (ply, data)
									ix.eventCharacters.current = data and util.JSONToTable(data) or {}
									ix.eventCharacters.panel.buildPanel()
								end)
							end

							opt = menu:AddOption("Save (overwrite)")
							opt:SetIcon("icon16/drive.png")
							function opt:DoClick()
                PrintTable(ix.eventCharacters.current)
								believe.serverpresets.save('eventCharacters', string.Replace(itm.itempath, ".json"), util.TableToJSON(ix.eventCharacters.current))
								dtree:RefreshPresets()
							end

							opt = menu:AddOption("Delete")
							opt:SetIcon("icon16/delete.png")
							function opt:DoClick()
								Derma_Query("Are you sure you want to delete '" .. itm.itempath .. "'", "Delete preset", "Yes", function (x)
									believe.serverpresets.delete('eventCharacters', string.TrimLeft(itm.itempath, "/"))
									dtree:RefreshPresets()
								end, "Cancel")
							end

							menu:Open()
						end
					end
				end

				local node = dtree:AddNode("Event Characters", "icon16/folder.png")
				node:SetExpanded(true)

				function node:DoClick()
				end

				function node:DoRightClick()
					dtree:SetSelectedItem(self)

					local menu = DermaMenu()


					opt = menu:AddOption("Refresh presets")
					opt:SetIcon("icon16/table_refresh.png")
					function opt:DoClick()
						dtree:RefreshPresets()
					end

					menu:AddSpacer()

					opt = menu:AddOption("Add folder")
					opt:SetIcon("icon16/folder_add.png")
					function opt:DoClick()
						Derma_StringRequest("Enter a folder name", "Please enter a title for the new folder", "", function (x)
							if (x == "") then return end

							if (string.find(x, ":") or string.find(x, "/") or string.find(x, "\\") or string.EndsWith(x, ".")) then
								Derma_Message("The preset name must be a valid Windows folder name.", "Error", "OK")
								return
							end

							believe.serverpresets.folder('eventCharacters', x)
							dtree:RefreshPresets()
						end)
					end

					opt = menu:AddOption("Save item")
					opt:SetIcon("icon16/drive_add.png")
					function opt:DoClick()
						Derma_StringRequest("Enter a file name", "Please enter a title for the new file", ix.eventCharacters.current.name or "", function (x)
							if (x == "") then return end

							if (string.find(x, ":") or string.find(x, "/") or string.find(x, "\\") or string.EndsWith(x, ".")) then
								Derma_Message("The preset name must be a valid Windows file name.", "Error", "OK")
								return
							end

							believe.serverpresets.save('eventCharacters', x, util.TableToJSON(ix.eventCharacters.current))
							dtree:RefreshPresets()
						end)
					end

					menu:Open()
				end


				recurse(data, "", node)
				ix.eventCharacters.presets = data
			end)
		end

		function dtree:OnNodeSelected(node)
			print(node.itempath)
		end

		dtree:RefreshPresets()
		panel:SizeToContents()

		return panel
	end

	parent:Help("This tool allows you to create, quickly switch to and share event characters with other admins for use on missions or other events.")

	parent.Presets = parent:AddItem(presets())

	ix.eventCharacters.panel.buildPanel()
end

hook.Add("PopulateToolMenu", "Believe_EventCharacters_PopulateMenu", function ()
  spawnmenu.AddToolMenuOption("Options", "Halo: Believe", "Believe_EventCharacters", "Event Characters", "", "", ix.eventCharacters.drawPanel)
end)

-- test
