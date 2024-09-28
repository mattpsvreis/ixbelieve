PLUGIN.name = "Vehicle Damage"
PLUGIN.description = "Adds car vehicledmg :("
PLUGIN.author = "Xalphox"

local PLUGIN = PLUGIN

believe = believe or {}
believe.vehicledmg = believe.vehicledmg or {}

--asdf
function believe.vehicledmg.load()
	local data = {}
	local originPath = "presets/flows/vehicles"

	local function recurse(path, t)
		local files, directories = file.Find(path .. "/*", "DATA")
		for k, v in pairs(files) do
			if not string.EndsWith(v, ".json") then
				continue
			end

			local fpath = path .. "/" .. v
			--local key = string.Replace(fpath, originPath .. "/", "") -- remove the /presets/flows/ etc.

			local contents = util.JSONToTable(file.Read(fpath, "DATA"))
			contents.Path = fpath
			if not contents.VehicleDmgData or not contents.VehicleDmgData.active then
				continue
			end

			t[fpath] = contents
		end

		for k, v in pairs(directories) do
			local fpath = path .. "/" .. v
			recurse(fpath, data)
		end
	end
	recurse(originPath, data)

	believe.vehicledmg.all = data
end


hook.Add("OnEntityCreated", "believe.vehicledamage.entitycreated", function (ent)
  if ent:GetClass() == "gmod_sent_vehicle_fphysics_base" then
    ent.ForceExplodeVehicle = ent.ExplodeVehicle
		ent.ExplodeVehicle = believe.vehicledmg.ExplodeVehicle
  end
end)

function believe.vehicledmg.ExplodeVehicle(ent)

	if ent:GetFlow() then return end

  -- Roll an injury
  local roll = math.random(-100, 0)

  local attacked = tostring(ent)

	local availableFlows = {}

  for k, v in pairs(believe.vehicledmg.all) do
    local rollMin = tonumber(v.VehicleDmgData.roll_min)
    local rollMax = tonumber(v.VehicleDmgData.roll_max)

    if roll < rollMin then
      continue
    end

    if roll > rollMax then
      continue
    end

		if v.VehicleDmgData.model and ent:GetModel() ~= v.VehicleDmgData.model then
			continue
		end

		--[[

    local attacker = IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():GetClass()
    if v.VehicleDmgData.attacker && string.len(v.VehicleDmgData.attacker) > 0 then
      local attackers = string.Split(string.Replace(string.lower(v.VehicleDmgData.attacker), " ", ""), ",")
      if !table.HasValue(attackers, attacker) then
        continue
      end
    end

    local attackerModel = IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():GetModel()

    if v.VehicleDmgData.attacker_model && string.len(v.VehicleDmgData.attacker_model) > 0 then
      local models = string.Split(string.Replace(string.lower(v.VehicleDmgData.attacker_model), " ", ""), ",")
      if !table.HasValue(models, attackerModel) then
        continue
      end
    end

    local inflictor = IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker().GetActiveWeapon and IsValid(dmginfo:GetAttacker():GetActiveWeapon()) and dmginfo:GetAttacker():GetActiveWeapon():GetClass()
    if v.VehicleDmgData.attacker_weapon && string.len(v.VehicleDmgData.attacker_weapon) > 0 then
      local weapons = string.Split(string.Replace(string.lower(v.VehicleDmgData.attacker_weapon), " ", ""), ",")

      if !table.HasValue(weapons, inflictor) then
        continue
      end
    end

    if v.VehicleDmgData.damage_type && string.len(v.VehicleDmgData.damage_type) > 0 then
      assert(string.StartWith(v.VehicleDmgData.damage_type, "DMG_")) -- tiny bit of security
      local dmg = _G[v.VehicleDmgData.damage_type]

      if !dmginfo:IsDamageType(dmg) then
        continue
      end
    end
		--]]

		v.path = k
    availableFlows[#availableFlows+1] = v
  end

	local flow
  if #availableFlows > 0 then
    flow = availableFlows[math.random(1,#availableFlows)]

    ent:SetFlow(flow)
    ent:FlowSetStep(nil, 1)
		ix.log.AddRaw(string.format("%s (%s) was incapacitated (roll: %i) | flow: %s (%s)", tostring(ent), ent:GetModel(), roll, flow.path, flow.VehicleDmgData.self_revive and "true" or "false"))

	else
		ix.log.AddRaw(string.format("%s (%s) was destroyed (roll: %i) | flow: none", tostring(ent), ent:GetModel(), roll))
		ent:ForceExplodeVehicle()
  end

	return true

end


ix.command.Add("reloadvehicledamagedefinitions", {
	description = "Reloads the vehicle damage definitions table",
	adminOnly = true,
	OnRun = function(self, ply)

		believe.vehicledmg.load()

		ix.util.NotifyCami(ply:Name() .. " reloaded the vehicle damage table.", "Helix - Admin")
	end
})

if believe.vehicledmg.all == nil then
	believe.vehicledmg.load()
end
