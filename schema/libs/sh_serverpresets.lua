believe = believe or {}
believe.serverpresets = {}

CAMI.RegisterPrivilege({
	Name = "Helix - Manage Server Presets",
	MinAccess = "admin",
	Description = "Allows the player to manage server presets."
})

if (SERVER) then
	function believe.serverpresets.folder(src, presetType, name)
		if (!CAMI.PlayerHasAccess(src, "Helix - Manage Server Presets")) then return end

		if (!file.Exists("presets/" .. presetType .. "/" .. name, "DATA")) then
			file.CreateDir("presets/" .. presetType .. "/" .. name, "DATA")
			hook.Run("PostPresetFolder", presetType, name)
		end
	end

	function believe.serverpresets.save(src, presetType, name, data)
		if (!CAMI.PlayerHasAccess(src, "Helix - Manage Server Presets")) then return end

		local decompedTable = util.JSONToTable(data) or {}
		local status, errorMessage = hook.Run("PresetSaveCheck", presetType, name, decompedTable)
		if (status == false) then
			src:Notify(errorMessage)
			return
		end

		if (!file.Exists("presets/" .. presetType, "DATA")) then
			file.CreateDir("presets/" .. presetType, "DATA")
		end

		file.Write("presets/" .. presetType .. "/" .. name .. ".json", data)
		hook.Run("PostPresetSave", presetType, name, decompedTable)
	end

	function believe.serverpresets.delete(src, presetType, name)
		if (!CAMI.PlayerHasAccess(src, "Helix - Manage Server Presets")) then return end

		file.Delete("presets/" .. presetType .. "/" .. name)
		hook.Run("PostPresetDelete", presetType, name)
	end

	function believe.serverpresets.get(src, presetType, name)
		if (!CAMI.PlayerHasAccess(src, "Helix - Manage Server Presets")) then return end

		bignet.Send(src, "believe.serverpresets.get.response." .. presetType, file.Read("presets/" .. presetType .. "/" .. name))
	end


	function believe.serverpresets.list(src, presetType)
		local data = {}
		local originPath = "presets/" .. presetType

		local function recurse(path, t)
			local files, directories = file.Find(path .. "/*", "DATA")
			for k, v in pairs(files) do
				if (!string.EndsWith(v, ".json")) then
					continue
				end

				--local fpath = path .. "/" .. v
				--local key = string.Replace(fpath, originPath .. "/", "") -- remove the /presets/flows/ etc.
				t[tostring(v)] = true
			end

			for k, v in pairs(directories) do
				local fpath = path .. "/" .. v
				t[tostring(v)] = {}
				recurse(fpath, t[v])
			end
		end
		recurse(originPath, data)

		bignet.Send(src, "believe.serverpresets.list.response." .. presetType, data)
	end

	bignet.Hook("believe.serverpresets.save", believe.serverpresets.save)
	bignet.Hook("believe.serverpresets.delete", believe.serverpresets.delete)
	bignet.Hook("believe.serverpresets.list", believe.serverpresets.list)
	bignet.Hook("believe.serverpresets.get", believe.serverpresets.get)
	bignet.Hook("believe.serverpresets.folder", believe.serverpresets.folder)
else
	function believe.serverpresets.save(presetType, name, data)
		bignet.Send(nil, "believe.serverpresets.save", presetType, name, data)
	end

	function believe.serverpresets.delete(presetType, name)
		bignet.Send(nil, "believe.serverpresets.delete", presetType, name)
	end

	function believe.serverpresets.list(presetType, callback)
		bignet.Hook("believe.serverpresets.list.response." .. presetType, callback)
		bignet.Send(nil, "believe.serverpresets.list", presetType)
	end

	function believe.serverpresets.get(presetType, name, callback)
		bignet.Hook("believe.serverpresets.get.response." .. presetType, callback)
		bignet.Send(nil, "believe.serverpresets.get", presetType, name)
	end

	function believe.serverpresets.folder(presetType, name)
		bignet.Send(nil, "believe.serverpresets.folder", presetType, name)
	end
end
