
local PLUGIN = PLUGIN

PLUGIN.name = "Post-Processing Sync"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Allow admins to sync post-processing effects to players."

CAMI.RegisterPrivilege({
	Name = "Helix - Sync Post-Processing",
	MinAccess = "admin",
	Description = "Access to the SyncPP command."
})

PLUGIN.PP_CVARS = {
  "pp_colormod",
  "pp_colormod_addr",
  "pp_colormod_addg",
  "pp_colormod_addb",
  "pp_colormod_brightness",
  "pp_colormod_color",
  "pp_colormod_contrast",
  "pp_colormod_mulr",
  "pp_colormod_mulg",
  "pp_colormod_mulb",
  "pp_bloom",
  "pp_bloom_color",
  "pp_bloom_color_r",
  "pp_bloom_color_g",
  "pp_bloom_color_b",
  "pp_bloom_darken",
  "pp_bloom_multiply",
  "pp_bloom_passes",
  "pp_bloom_sizex",
  "pp_bloom_sizey",
  "pp_mat_overlay",
  "pp_mat_overlay_refractamount",
  "pp_motionblur",
  "pp_motionblur_addalpha",
  "pp_motionblur_delay",
  "pp_motionblur_drawalpha",
  "pp_sharpen",
  "pp_sharpen_contrast",
  "pp_sharpen_distance",
  "pp_sunbeams",
  "pp_sunbeams_darken",
  "pp_sunbeams_multiply",
  "pp_sunbeams_sunsize",
  "pp_texturize",
  "pp_texturize_scale",
  "pp_sobel",
  "pp_sobel_threshold",
  "pp_toytown",
  "pp_toytown_passes",
  "pp_toytown_size"
}

ix.command.Add("syncpp", {
	privilege = "Sync Post-Processing",
	description = "Sync your current post processing settings to a player",
	acceptMulti = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		net.Start("SyncPP_Request")
		net.Send(client)

		client.ixSyncPP = target
	end
})

if (CLIENT) then
	net.Receive("SyncPP_Request", function ()
		local data = {}
		for _, v in ipairs(PLUGIN.PP_CVARS) do
			data[v] = GetConVar(v):GetString()
		end

		--print("Sending PP payload:")
		--PrintTable(data)

		net.Start("SyncPP_Transmit")
			net.WriteTable(data)
		net.SendToServer()
	end)

	net.Receive("SyncPP_Transmit", function (len)
		for k, v in pairs(net.ReadTable()) do
			--print("Running " .. k .. " = " .. v)
			RunConsoleCommand(k, v)
		end
	end)
else
	util.AddNetworkString("SyncPP_Request")
	util.AddNetworkString("SyncPP_Transmit")
	net.Receive("SyncPP_Transmit", function (len, client)
		if (!CAMI.PlayerHasAccess(client, "Helix - Sync Post-Processing")) then
			return
		end

		-- copy the table to be sure no other cvars were sneaked in
		local toSend = {}
		local received = net.ReadTable()
		for _, v in ipairs(PLUGIN.PP_CVARS) do
			if (received[v]) then
				toSend[v] = received[v]
			end
		end

		if (client.ixSyncPP and (istable(client.ixSyncPP) or IsValid(client.ixSyncPP))) then
			net.Start("SyncPP_Transmit")
				net.WriteTable(toSend)
			net.Send(client.ixSyncPP)
			ix.util.NotifyCami(client:Name() .. " synced their post-processing effects to " ..  (istable(client.ixSyncPP) and "multiple people" or client.ixSyncPP:Name()), "Helix - Sync Post-Processing")
			client.ixSyncPP = nil
		end
	end)
end