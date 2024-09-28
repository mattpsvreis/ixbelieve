believe = believe or {}
believe.flows = believe.flows or {}

TOOL.Category = "Halo: Believe"
TOOL.Name = "Flow"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud

TOOL.EntList = {}
TOOL.ColorList = {}
TOOL.LastLeftClick = CurTime()
TOOL.LastRightClick = CurTime()
TOOL.LastReload = CurTime()

local function getStepName(CurrentStep)
		local name = ""
		if (!CurrentStep.isExitStep) then
			name = name .. CurrentStep.id .. ". "
		end

		if (CurrentStep.name and string.len(string.Trim(CurrentStep.name)) != 0) then
			name = name .. CurrentStep.name
		elseif (CurrentStep.description and string.len(string.Trim(CurrentStep.description)) != 0) then
			name = name .. CurrentStep.description
		else
			name = name .. "(Untitled)"
		end
		return name
end

-- reviveplayer
-- hostmessage
-- SpeedChange -- run, walk

function TOOL:LeftClick( trace )
	if (SERVER) then return false end

	if (CurTime() > self.LastLeftClick + 0.5) then
		local flow = believe.flows.currentFlow
		if (!flow.Step or !flow.steps or !flow.steps[flow.Step] or !flow.steps[flow.Step].description) then
			ix.util.Notify("You need at least a name and at least one step to spawn a flow.")
			self.LastLeftClick = CurTime()
			return false
		end

		if (!input.IsShiftDown() and (trace.HitWorld or trace.Entity:GetFlow() == nil)) then
			bignet.Send(nil, "believe.flows.add_prop", trace.HitWorld and nil or trace.Entity:EntIndex(), trace.HitPos, flow)
			self.LastLeftClick = CurTime()
			return true
		elseif (!trace.HitWorld) then
			bignet.Send(nil, "believe.flows.add", trace.Entity:EntIndex(), flow)
			self.LastLeftClick = CurTime()
			return true
		end
	end
	return false
end

function TOOL:Reload( trace )
	if CurTime() > self.LastReload + 0.5 and !trace.HitWorld and trace.Entity:GetFlow() != nil then
		trace.Entity:RemoveFlow()
		self.LastReload = CurTime()
		return true
	end
	return false
end

function TOOL:RightClick( trace )
	if CurTime() > self.LastRightClick + 0.5 then
		if CLIENT then
			if not trace.HitWorld and trace.Entity:GetFlow() != nil then
				believe.flows.currentFlow = trace.Entity:GetFlow()
				buildPanel()
			else
				believe.flows.currentFlow = {}
				buildPanel()
			end
		end
		self.LastRightClick = CurTime()
		return true
	end
	return false
end

if CLIENT then

	believe.flows.currentFlow = believe.flows.currentFlow or {}

	local function addForm(parent, title, expanded, color, bgcolor)
		local form = vgui.Create("DForm")
		form:SetName(title)
		form:SetExpanded(expanded)

		form.Header.FgColor = color
		form.BgColor = bgcolor

		if color then
			form.Header:SetPaintBackgroundEnabled(true)
			form.Header.PerformLayout = function (n)
				n:SetBGColor(n.FgColor)
			end
		end

		if bgcolor then
			form._PerformLayout = form.PerformLayout
			form.PerformLayout = function (n)
				n:_PerformLayout()
				n:SetBGColor(n.BgColor)
			end
		end

		parent:AddItem(form)
		return form
	end

	local function bind(itm, t, key)
		if t[key] != nil then
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


	function buildPanel()

		local parent = believe.flows.panel

		for k, v in ipairs(parent:GetChildren()) do
			if k < 4 then continue end
			v:Remove()
		end

		local CurrentFlow = believe.flows.currentFlow
		if CurrentFlow == -1 then
			-- CurrentFlow is set to -1 when we're loading a flow.
			return
		end

		CurrentFlow.nextStepId = CurrentFlow.nextStepId or 1
		CurrentFlow.steps = CurrentFlow.steps or {}

		if (#CurrentFlow.steps == 0) then
			local stp = {}
			stp.id = CurrentFlow.nextStepId
			stp.name = "Initial step"
			stp.isInitialStep = true
			CurrentFlow.steps[stp.id] = stp

			CurrentFlow.nextStepId = CurrentFlow.nextStepId + 1

			CurrentFlow.Step = stp.id
			CurrentFlow.StepName = stp.name
		end

		local hasExitStep = false
		for k, v in pairs(CurrentFlow.steps) do
			if v.isExitStep then
				hasExitStep = true
				break
			end
		end

		if not hasExitStep then
			local lststp = {}
			lststp.id = 9999999
			lststp.name = "Exit step"
			lststp.isExitStep = true

			CurrentFlow.steps[lststp.id] = lststp
		end

		CurrentFlow.type = CurrentFlow.type or "Standard"
		e = parent:ComboBox("Flow Type")
		e:AddChoice("Standard")
		e:AddChoice("Injury")
		e:AddChoice("Vehicle")

		function e:OnSelect(idx, value)
			CurrentFlow.type = value
			self:SetValue(value)
			buildPanel()
		end
		e:SetValue(CurrentFlow.type)

		e = parent:ComboBox("Step")
		if CurrentFlow.StepName != nil then
			e:SetValue(CurrentFlow.StepName)
		end

		e._OpenMenu = e.OpenMenu
		e.OpenMenu = function (this)
			this:Clear()

			for k, v in pairs(CurrentFlow.steps) do
				this:AddChoice(v.id .. ". " .. (v.name or "(untitled)"), v.id)
			end
			this:_OpenMenu()
		end

		function e:OnSelect(idx, value, data)
			CurrentFlow.Step = data

			local targetName = "(not set)"
			if CurrentFlow.steps[CurrentFlow.Step] != nil then
				local nxt = CurrentFlow.steps[CurrentFlow.Step]
				targetName = nxt.id .. ". " .. (nxt.name or "(untitled)")
			end

			CurrentFlow.StepName = targetName
			self:SetValue(value)
			buildPanel()
		end

		e = parent:Button("Add step")
		e.DoClick = function ()
			local stp = {}
			stp.id = CurrentFlow.nextStepId
			CurrentFlow.steps[stp.id] = stp
			addStep(parent, stp)

			CurrentFlow.nextStepId = CurrentFlow.nextStepId + 1
		end

		if CurrentFlow.type == "Injury" then
			local injury = addForm(parent, "Auto-injury system", true, Color(0, 0, 0, 255), Color(192, 192, 192, 128))

			CurrentFlow.InjuryData = CurrentFlow.InjuryData or {}

			e = bind(injury:CheckBox("Enabled"), CurrentFlow.InjuryData, "active")
			e._OnChange = e.OnChange
			function e:OnChange(value)
				self:_OnChange(value)
				buildPanel()
			end

			if (CurrentFlow.InjuryData.active == true) then

				CurrentFlow.InjuryData.roll_min = CurrentFlow.InjuryData.roll_min or -100
				e = bind(injury:NumSlider("Roll Min", nil, -100, 0, 0), CurrentFlow.InjuryData, "roll_min")

				CurrentFlow.InjuryData.roll_max = CurrentFlow.InjuryData.roll_max or 0
				e = bind(injury:NumSlider("Roll Max", nil, -100, 0, 0), CurrentFlow.InjuryData, "roll_max")

				e = bind(injury:TextEntry("Attacker(s)"), CurrentFlow.InjuryData, "attacker")
				e:SetPlaceholderText("npc_combine_s, believe_warrior")

				e = bind(injury:TextEntry("Attacker model(s)"), CurrentFlow.InjuryData, "attacker_model")
				e:SetPlaceholderText("models/combine_soldier.mdl, models/combine_strider.mdl")

				e = bind(injury:TextEntry("Attacker weapon(s)"), CurrentFlow.InjuryData, "attacker_weapon")
				e:SetPlaceholderText("cw_ak74, sst_saw")

				e = bind(injury:ComboBox("Damage type"), CurrentFlow.InjuryData, "damage_type")
				e:AddChoice("")
				e:AddChoice("DMG_GENERIC")
				e:AddChoice("DMG_CRUSH")
				e:AddChoice("DMG_BULLET")
				e:AddChoice("DMG_SLASH")
				e:AddChoice("DMG_BURN")
				e:AddChoice("DMG_VEHICLE")
				e:AddChoice("DMG_FALL")
				e:AddChoice("DMG_BLAST")
				e:AddChoice("DMG_CLUB")
				e:AddChoice("DMG_SHOCK")
				e:AddChoice("DMG_SONIC")
				e:AddChoice("DMG_ENERGYBEAM")
				e:AddChoice("DMG_PREVENT_PHYSICS_FORCE")
				e:AddChoice("DMG_NEVERGIB")
				e:AddChoice("DMG_ALWAYSGIB")
				e:AddChoice("DMG_DROWN")
				e:AddChoice("DMG_PARALYZE")
				e:AddChoice("DMG_NERVEGAS")
				e:AddChoice("DMG_POISON")
				e:AddChoice("DMG_RADIATION")
				e:AddChoice("DMG_DROWNRECOVER")
				e:AddChoice("DMG_ACID")
				e:AddChoice("DMG_SLOWBURN")
				e:AddChoice("DMG_REMOVENORAGDOLL")
				e:AddChoice("DMG_PHYSGUN")
				e:AddChoice("DMG_PLASMA")
				e:AddChoice("DMG_AIRBOAT")
				e:AddChoice("DMG_DISSOLVE")
				e:AddChoice("DMG_BLAST_SURFACE")
				e:AddChoice("DMG_DIRECT")
				e:AddChoice("DMG_BUCKSHOT")
				e:AddChoice("DMG_SNIPER")
				e:AddChoice("DMG_MISSILEDEFENSE")

				e = bind(injury:ComboBox("Hitgroup"), CurrentFlow.InjuryData, "hitgroup")
				e:AddChoice("")
				e:AddChoice("HITGROUP_GENERIC")
				e:AddChoice("HITGROUP_HEAD")
				e:AddChoice("HITGROUP_CHEST")
				e:AddChoice("HITGROUP_STOMACH")
				e:AddChoice("HITGROUP_LEFTARM")
				e:AddChoice("HITGROUP_RIGHTARM")
				e:AddChoice("HITGROUP_LEFTLEG")
				e:AddChoice("HITGROUP_RIGHTLEG")
				e:AddChoice("HITGROUP_GENERIC")



				injury:Help("")

				e = bind(injury:CheckBox("Allow players to revive themselves"), CurrentFlow.InjuryData, "self_revive")

			end
			injury:Help("")
		elseif CurrentFlow.type == "Vehicle" then
			local injury = addForm(parent, "Auto-damage system", true, Color(0, 0, 0, 255), Color(192, 192, 192, 128))

			CurrentFlow.VehicleDmgData = CurrentFlow.VehicleDmgData or {}

			e = bind(injury:CheckBox("Enabled"), CurrentFlow.VehicleDmgData, "active")
			e._OnChange = e.OnChange
			function e:OnChange(value)
				self:_OnChange(value)
				buildPanel()
			end

			if (CurrentFlow.VehicleDmgData.active == true) then

				CurrentFlow.VehicleDmgData.roll_min = CurrentFlow.VehicleDmgData.roll_min or -100
				e = bind(injury:NumSlider("Roll Min", nil, -100, 0, 0), CurrentFlow.VehicleDmgData, "roll_min")

				CurrentFlow.VehicleDmgData.roll_max = CurrentFlow.VehicleDmgData.roll_max or 0
				e = bind(injury:NumSlider("Roll Max", nil, -100, 0, 0), CurrentFlow.VehicleDmgData, "roll_max")

				e = bind(injury:TextEntry("Vehicle model"), CurrentFlow.VehicleDmgData, "model")
				e:SetPlaceholderText("models/error.mdl")

			end
			injury:Help("")
		end

		function addStep(parent, CurrentStep, bgcolor)

			CurrentStep.branches = CurrentStep.branches or {}
			CurrentStep.nextBranchId = CurrentStep.nextBranchId or 1

			local isActiveStep = (CurrentFlow.Step == CurrentStep.id)

			--local steps = addForm(parent, CurrentStep.id .. ". " .. (CurrentStep.name or "(untitled)"), isActiveStep == true, isActiveStep == true and Color(0, 128, 0, 255) or Color(128, 128, 128, 255), Color(0, 0, 0, 64))
			bgcolor = bgcolor or (isActiveStep == true and Color(0, 128, 0, 255) or Color(128, 128, 128, 255))

			local steps = addForm(parent, getStepName(CurrentStep), true, bgcolor, Color(0, 0, 0, 64))

			if CurrentStep.isExitStep then
				steps:Help("This step is ran whenever a flow is removed from an entity.")
				steps:Help(" ")
			end

			e = bind(steps:TextEntry("Step label"), CurrentStep, "name")
			e._OnChange = e.OnChange
			e.OnChange = function (itm, v)
				itm._OnChange(itm, v)


				local name = ""
				if not CurrentStep.isInitialStep and not CurrentStep.isExitStep then
					name = name .. CurrentStep.id .. ". "
				end

				if (CurrentStep.name != nil and string.len(string.Trim(CurrentStep.name)) != 0) then
					name = name .. CurrentStep.name
				elseif (CurrentStep.description and not string.len(string.Trim(CurrentStep.description)) != 0) then
					name = name .. CurrentStep.description
				else
					name = name .. "(Untitled)"
				end

				steps:SetName(name)
			end


			if not CurrentStep.isExitStep then
				e = bind(steps:TextEntry("Description"), CurrentStep, "description")
				e:SetTall(50)
				e:SetMultiline(true)
			end

			-- Removed because it is huge
			--[[e = vgui.Create("DColorCombo")
			e:SetColor(CurrentStep.color or ix.config.Get("color"))

			e.OnValueChanged = function (i, value)
				CurrentStep.color = value
				e:SetColor(CurrentStep.color or ix.config.Get("color"))
			end

			steps:AddItem(e)--]]

			local actions = addForm(steps, "Actions", false, Color(0, 0, 0, 255))
			actions:Help("Whenever this step is triggered, these actions will be ran.\n\n")

			-- notify admins
			bind(actions:CheckBox("Send admins a notification"), CurrentStep, "notifyadmins")

			-- /ev
			actions:Help("\nEvent (/ev)")
			e = vgui.Create("DTextEntry")
			e:SetTall(50)
			e:SetMultiline(true)
			bind(e, CurrentStep, "event")
			e:SetPlaceholderText("The door lets out a whirring sound and opens...")
			actions:AddItem(e)

			actions:Help("\nAction (/it)")
			e = vgui.Create("DTextEntry")
			e:SetTall(50)
			e:SetMultiline(true)
			bind(e, CurrentStep, "ittext")
			e:SetPlaceholderText("Sgt. McRann opens up the panel infront of you...")
			actions:AddItem(e)

			-- reviveplayer
			-- hostmessage
			-- SpeedChange -- run, walk
			if CurrentFlow.type == "Injury" then

				actions:Help("")

				e = bind(actions:CheckBox("Revive player if downed"), CurrentStep, "revive")

				-- send message to player
				actions:Help("\nSend a message to the player")
				e = vgui.Create("DTextEntry")
				e:SetTall(50)
				e:SetMultiline(true)
				bind(e, CurrentStep, "playermessage")
				e:SetPlaceholderText("The screwdriver does XYZ.")
				actions:AddItem(e)

				-- send message to host of flow (player)
				actions:Help("\nSend a message to the injured player")
				e = vgui.Create("DTextEntry")
				e:SetTall(50)
				e:SetMultiline(true)
				bind(e, CurrentStep, "hostmessage")
				e:SetPlaceholderText("Person uses screwdriver on you, doing XYZ.")
				actions:AddItem(e)

				actions:Help("\nMove speed modifier")
				e = vgui.Create("DNumSlider")
				e:SetMinMax(0.2, 1.0)
				CurrentStep.SpeedModifier = CurrentStep.SpeedModifier or 1.0
				bind(e, CurrentStep, "SpeedModifier")
				actions:AddItem(e)

				actions:Help("\nBleed Rate (per minute)")
				e = vgui.Create("DNumSlider")
				e:SetMinMax(0, 15.0)
				CurrentStep.BleedRate = CurrentStep.BleedRate or 0.0
				bind(e, CurrentStep, "BleedRate")
				actions:AddItem(e)

				actions:Help("\nAttribute debuff(s)")
				e = vgui.Create("DTextEntry")
				e:SetTall(50)
				e:SetMultiline(true)
				bind(e, CurrentStep, "attrs")
				e:SetPlaceholderText("STM 5")
				actions:AddItem(e)

				actions:Help("\nRun following console command(s) on injured player")
				e = vgui.Create("DTextEntry")
				e:SetTall(50)
				e:SetMultiline(true)
				bind(e, CurrentStep, "commands")
				e:SetPlaceholderText("pp_colormod 1")
				actions:AddItem(e)
			end

			if CurrentFlow.type == "Vehicle" then

				actions:Help("")

				if CurrentStep.isExitStep then
					CurrentStep.fixengine = CurrentStep.fixengine or true
					CurrentStep.fixlights = CurrentStep.fixlights or true
					CurrentStep.fixfire = CurrentStep.fixfire or true
					CurrentStep.fixsmoke = CurrentStep.fixsmoke or true
					CurrentStep.fixtyres = CurrentStep.fixtyres or true
					CurrentStep.VehicleHealth = CurrentStep.VehicleHealth or 1.0
				end

				e = bind(actions:CheckBox("Fix engine"), CurrentStep, "fixengine")
				e = bind(actions:CheckBox("Extinguish engine fire"), CurrentStep, "fixfire")
				e = bind(actions:CheckBox("Stop the car smoking"), CurrentStep, "fixsmoke")
				e = bind(actions:CheckBox("Fix lights"), CurrentStep, "fixlights")
				e = bind(actions:CheckBox("Fix tyres"), CurrentStep, "fixtyres")

				actions:Help("\nSet vehicle health (%)")
				e = vgui.Create("DNumSlider")
				e:SetMinMax(0, 1.0)
				CurrentStep.VehicleHealth = CurrentStep.VehicleHealth or 0
				bind(e, CurrentStep, "VehicleHealth")
				actions:AddItem(e)

				actions:Help("\n")

				e = bind(actions:CheckBox("Explode vehicle"), CurrentStep, "explode")
			end

			actions:Help("\nEnt_fire(s)")
			actions:Help("You can use the Entity Inspector tool to get the name and class of an entity. From there, you can look up an entity's inputs via the Valve Wiki (i.e. https://developer.valvesoftware.com/wiki/Func_door).")
			e = vgui.Create("DTextEntry")
			e:SetTall(50)
			e:SetMultiline(true)
			bind(e, CurrentStep, "entfire")
			e:SetPlaceholderText("[time:]name input [params]...")
			actions:AddItem(e)

			-- lua
			actions:Help("\nLua Code (Serverside)")
			actions:Help("self = this entity; ply = the player.")
			e = vgui.Create("DTextEntry")
			e:SetTall(50)
			e:SetMultiline(true)
			bind(e, CurrentStep, "lua")
			e:SetPlaceholderText("self:GetParent():SetLocked(false)")
			actions:AddItem(e)

			-- trigger a step on another flow
			--[[actions:Help("\nTrigger step on another flow")
			e = bind(actions:TextEntry("Step: Lua Name"), CurrentStep, "step_luaname")
			e:SetPlaceholderText("Name of flow goes here")
			actions:AddItem(e)

			e = bind(actions:TextEntry("Step: Set Step To"), CurrentStep, "step_set_to")
			e:SetPlaceholderText("Default")
			actions:AddItem(e)--]]

			function addBranch(steps, CurrentStep, CurrentBranch)

				local targetName = CurrentBranch.nextStepName or "(not set)"

				local branch = addForm(steps, CurrentStep.id .. "." .. CurrentBranch.id .. ": " .. (CurrentBranch.items or "(default)") .. " -> " .. targetName, false, Color(128, 64, 0, 255), Color(128, 128, 128, 64))
				branch:SetExpanded(false)

				e = bind(branch:TextEntry("Item(s)"), CurrentBranch, "items")
				e:SetPlaceholderText("Screwdriver")
				e._OnChange = e.OnChange
				e.OnChange = function (itm, v)

					local targetName = "(not set)"
					if CurrentBranch.nextStep != nil and CurrentFlow.steps[CurrentBranch.nextStep] != nil then
						local nxt = CurrentFlow.steps[CurrentBranch.nextStep]
						targetName = nxt.id .. ". " .. (nxt.name or "(untitled)")
					end


					itm._OnChange(itm, v)
					branch:SetName(CurrentStep.id .. "." .. CurrentBranch.id .. ": " .. (CurrentBranch.items or "(default)") .. " -> " .. targetName)
				end

				if CurrentFlow.type == "Injury" then
					e = bind(branch:CheckBox("Allow apply to self"), CurrentBranch, "can_apply_to_self")
				end

				e = branch:ComboBox("Next step")
				if CurrentBranch.nextStepName != nil then
					e:SetValue(CurrentBranch.nextStepName)
				end

				e._OpenMenu = e.OpenMenu
				e.OpenMenu = function (this)
					this:Clear()

					this:AddChoice("")
					for k, v in pairs(CurrentFlow.steps) do
						if v.id == CurrentStep.id then continue end
						this:AddChoice(getStepName(v), v.id)
					end
					this:_OpenMenu()
				end

				function e:OnSelect(idx, value, data)
					CurrentBranch.nextStep = data

					local targetName = "(not set)"
					if CurrentBranch.nextStep != nil and CurrentFlow.steps[CurrentBranch.nextStep] != nil then
						local nxt = CurrentFlow.steps[CurrentBranch.nextStep]
						targetName = getStepName(nxt)
					end

					branch:SetName(CurrentStep.id .. "." .. CurrentBranch.id .. ": " .. (CurrentBranch.items or "(default)") .. " -> " .. targetName)
					CurrentBranch.nextStepName = targetName
				end

				CurrentBranch.action_time = CurrentBranch.action_time or 0
				e = bind(branch:NumSlider("Action time", nil, 0, 60, 1), CurrentBranch, "action_time")
				e = bind(branch:TextEntry("Action text"), CurrentBranch, "action_text")
				e:SetPlaceholderText("Leave blank for 'Applying [item name]...'")

				CurrentBranch.consume = CurrentBranch.consume or false
				e = bind(branch:CheckBox("Remove item on use"), CurrentBranch, "consume")

				e = branch:Button("Remove branch")
				e.DoClick = function ()
					table.remove(CurrentStep.branches, x)
					branch:Remove()
					branch:InvalidateParent(true)
				end

				branch:Help("")
			end

			for x, CurrentBranch in ipairs(CurrentStep.branches) do
				addBranch(steps, CurrentStep, CurrentBranch)
			end

			if not CurrentStep.isExitStep then
				e = steps:Button("Add branch")
				e.DoClick = function ()
					CurrentStep.branches = CurrentStep.branches or {}
					local branch = {}
					branch.id = CurrentStep.nextBranchId
					CurrentStep.branches[branch.id] = branch
					addBranch(steps, CurrentStep, branch)

					CurrentStep.nextBranchId = CurrentStep.nextBranchId + 1
				end
			end

			if not CurrentStep.isInitialStep and not CurrentStep.isExitStep then
				e = steps:Button("Delete step")
				e.DoClick = function ()
					if (CurrentFlow.Step == CurrentStep.id) then
						Derma_Message("You can't delete the flow's current active step.", "Error", "OK")
						return
					end

					table.RemoveByValue(CurrentFlow.steps, CurrentStep)
					steps:Remove()
				end
			end

			steps:Help(" ")
		end

		for k, CurrentStep in pairs(CurrentFlow.steps) do
			if (CurrentStep.isExitStep) then
				addStep(parent, CurrentStep, Color(0, 0, 0, 255))
			else
				addStep(parent, CurrentStep)
			end
		end
	end

	function TOOL.BuildCPanel( parent )

		believe.flows.panel = parent

		local expanded = {}

		-- Rebuild it if we're called again test
		local function presets()
			local panel = vgui.Create("DPanel")
			panel:SetTall(ScrH() * 0.2)
			panel:SetDrawBackground(false)

			local dtree  = vgui.Create( "DTree", panel )
			dtree:Dock( FILL )

			function dtree:RefreshPresets()
				dtree:Clear()

				believe.serverpresets.list('flows', function (ply, data)
					if not data then return end

					local function recurse(t, path, node)

						-- solve issues with numerical indices
						local t2 = {}
						for k, v in pairs(t) do
							t2[tostring(k)] = v
						end

						t = t2

						-- Folders first!
						for k, v in SortedPairs(t) do
							if (type(v) == "table") then
								local itm = node:AddNode(k, "icon16/folder.png")
								itm.flowpath = path .. "/" .. k
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

											if (string.find(x, ":") or string.find(x, "/") or string.find(x, "\\") or string.EndsWith(x, ".")) then
												Derma_Message("The preset name must be a valid Windows folder name.", "Error", "OK")
												return
											end

											believe.serverpresets.folder('flows', itm.flowpath .. "/" .. x)
											dtree:RefreshPresets()
										end)
									end

									opt = menu:AddOption("Save flow")
									opt:SetIcon("icon16/drive_add.png")
									function opt:DoClick()
										Derma_StringRequest("Enter a file name", "Please enter a title for the new file", "", function (x)
											if (x == "") then return end

											local flow = believe.flows.currentFlow
											if not flow.Step or not flow.steps or not flow.steps[flow.Step] or not flow.steps[flow.Step].description then
												Derma_Message("You need at least a name and at least one step to save a flow.", "Error", "OK")
												return
											end

											if (string.find(x, ":") or string.find(x, "/") or string.find(x, "\\") or string.EndsWith(x, ".")) then
												Derma_Message("The preset name must be a valid Windows file name.", "Error", "OK")
												return
											end

											local path = itm.flowpath .. "/" .. x
											flow.Path = path
											believe.serverpresets.save('flows', path, util.TableToJSON(flow))
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

										Derma_Query("Are you sure you want to delete '" .. itm.flowpath .. "'", "Delete preset", "Yes", function (x)
											believe.serverpresets.delete('flows', string.TrimLeft(itm.flowpath, "/"))
											dtree:RefreshPresets()
										end, "Cancel")
						      end

						      menu:Open()
								end
								recurse(v, itm.flowpath, itm)
							end
						end

						for k, v in SortedPairs(t) do
							if (type(v) == "table") then
								continue
							end

							local itmpath = path .. "/" .. k

							local ico = "icon16/page.png"
							--[[if ix.medicalSystem.injuryFlows[itmpath] then
								ico = "icon16/pill.png"
							end--]]
							local itm = node:AddNode(k, ico)
							itm.flowpath = itmpath

							function itm:DoClick()
								believe.flows.currentFlow = -1
								buildPanel()

								believe.serverpresets.get('flows', string.TrimLeft(itmpath, "/"), function (ply, data)
									believe.flows.currentFlow = data and util.JSONToTable(data) or {}
									buildPanel()
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
									believe.flows.currentFlow = -1
									buildPanel()

									believe.serverpresets.get('flows', string.TrimLeft(itmpath, "/"), function (ply, data)
										believe.flows.currentFlow = data and util.JSONToTable(data) or {}

										believe.flows.currentFlow.Path = string.TrimLeft(itmpath, "/")
										buildPanel()
									end)
				        end

				        opt = menu:AddOption("Save (overwrite)")
				        opt:SetIcon("icon16/drive.png")
								function opt:DoClick()

										local flow = believe.flows.currentFlow
										if not flow.Step or not flow.steps or not flow.steps[flow.Step] or not flow.steps[flow.Step].description then
											Derma_Message("You need at least a name and at least one step to save a flow.", "Error", "OK")
											return
										end

										local path = string.Replace(itm.flowpath, ".json")
										flow.Path = path
										believe.serverpresets.save('flows', path, util.TableToJSON(flow))
										dtree:RefreshPresets()
								end

					      opt = menu:AddOption("Delete")
					      opt:SetIcon("icon16/delete.png")
					      function opt:DoClick()
									Derma_Query("Are you sure you want to delete '" .. itm.flowpath .. "'", "Delete preset", "Yes", function (x)
										believe.serverpresets.delete('flows', string.TrimLeft(itm.flowpath, "/"))
										dtree:RefreshPresets()
									end, "Cancel")
					      end

					      menu:Open()
							end
						end
					end

					local node = dtree:AddNode("Flows", "icon16/folder.png")
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

								believe.serverpresets.folder('flows', x)
								dtree:RefreshPresets()
							end)
						end

						opt = menu:AddOption("Save flow")
						opt:SetIcon("icon16/drive_add.png")
						function opt:DoClick()
							Derma_StringRequest("Enter a file name", "Please enter a title for the new file", "", function (x)
								if (x == "") then return end

								local flow = believe.flows.currentFlow
								if not flow.Step or not flow.steps or not flow.steps[flow.Step] or not flow.steps[flow.Step].description then
									Derma_Message("You need at least a name and at least one step to save a flow.", "Error", "OK")
									return
								end

								if (string.find(x, ":") or string.find(x, "/") or string.find(x, "\\") or string.EndsWith(x, ".")) then
									Derma_Message("The preset name must be a valid Windows file name.", "Error", "OK")
									return
								end

								believe.serverpresets.save('flows', x, util.TableToJSON(believe.flows.currentFlow))
								dtree:RefreshPresets()
							end)
						end

						menu:Open()
					end

					recurse(data, "", node)
		      believe.flows.presets = data
				end)
			end

			function dtree:OnNodeSelected(node)
				print(node.flowpath)
			end

			dtree:RefreshPresets()
			panel:SizeToContents()

			return panel
		end

		parent:Help("Flows are an entity/mechanic primarily designed for engineering tasks like overriding doors, and for medical injuries. They allow you to apply a description/title to a prop and then have that change (and also trigger actions) based on what items players use on them.")

		parent.Presets = parent:AddItem(presets())


		buildPanel()
	end

	language.Add( "Tool.believe_flows.name", "Halo: Believe - Flow" )
	language.Add( "Tool.believe_flows.desc", "Creates a Flow mechanic that requires users to use a collection of items in the right sequence to solve." )
	language.Add( "Tool.believe_flows.0", "Left-click: Spawns a flow. Shift + left-click: apply a flow to an existing entity. Right-click: Copies the settings from a flow you are looking at. R removes a flow from an existing entity." )
	language.Add( "Undone_flows", "Flow has been undone." )
end
