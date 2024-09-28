
--[[
    CAMI Privileges
--]]
CAMI.RegisterPrivilege({
	Name = "Helix - Fun Stuff",
	MinAccess = "superadmin",
	Description = "Allows access to some extra 'for fun' commands that aren't strictly necessary."
})

CAMI.RegisterPrivilege({
	Name = "Helix - Basic Commands",
	MinAccess = "user",
	Description = "Allows usage of basic gamemode commands."
})

CAMI.RegisterPrivilege({
	Name = "Helix - Basic Admin Commands",
	MinAccess = "admin",
	Description = "Allows the player to run basic admin commands - generally non-server breaking stuff."
})

CAMI.RegisterPrivilege({
	Name = "Helix - View Inventory",
	MinAccess = "admin"
})

CAMI.RegisterPrivilege({
	Name = "Helix - Increase Character Limit",
	MinAccess = "admin"
})

CAMI.RegisterPrivilege({
	Name = "Helix - Bastion Lookup",
	MinAccess = "superadmin"
})
CAMI.RegisterPrivilege({
	Name = "Helix - Bastion Whitelist",
	MinAccess = "admin"
})

CAMI.RegisterPrivilege({
	Name = "Helix - Container Password",
	MinAccess = "superadmin"
})
CAMI.RegisterPrivilege({
	Name = "Helix - Proxy Notify",
	MinAccess = "superadmin"
})

CAMI.RegisterPrivilege({
	Name = "Helix - Run Lua",
	MinAccess = "superadmin",
	Description = "Allows the player to run Lua on the server and all clients."
})

CAMI.RegisterPrivilege({
	Name = "Helix - Hear Reports",
	MinAccess = "superadmin",
	Description = "Allows the player to hear /reports."
})

CAMI.RegisterPrivilege({
	Name = "Helix - Bypass Char Create",
	MinAccess = "admin",
	Description = "Allows the player to make characters without any cooldown time."
})

--[[
    OPTIONS
--]]
ix.option.Add("pgi", ix.type.bool, true, {
    category = "administration",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands", nil)
	end
})

ix.option.Add("playerDeathNotification", ix.type.bool, true, {
    category = "administration",
    bNetworked = true,
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Admin", nil)
	end
})

--[[
    CONFIGS
--]]
ix.config.Add("netLoggingEnabled", false, "Enable or disable net logging into the database (WARNING: PERFORMANCE IMPACT)", nil, {
	category = "Bastion"
})
ix.config.Add("netAntiSpam", true, "Enable or disable net anti-spam (WARNING: PERFORMANCE IMPACT)", nil, {
	category = "Bastion"
})
ix.config.Add("suppressOnPlayerChat", true, "Suppress the default OnPlayerChat hook (should not be used by helix)", nil, {
	category = "Bastion"
})
ix.config.Add("maxCharactersIncreased", 15, "The maximum number of characters a player can have if they have the increased character limit permission.", nil, {
	data = {min = 1, max = 50},
	category = "characters"
})
ix.config.Add("charCreateInterval", 5, "How many minutes there should be between 2 successful character creations of one player (to avoid character spam).", nil, {
	data = {min = 1, max = 50},
	category = "characters"
})
ix.config.Add("AllowContainerSpawn", false, "Allow anyone to directly spawn containers by spawning in their prop. Disallowing this will require admins to create containers from a prop using the context menu.", nil, {
	category = "containers"
})
ix.config.Add("showConnectMessages", true, "Whether or not to show notifications when players connect to the server. When off, only Staff will be notified.", nil, {
	category = "server"
})
ix.config.Add("showDisconnectMessages", true, "Whether or not to show notifications when players disconnect from the server. When off, only Staff will be notified.", nil, {
	category = "server"
})
ix.config.Add("DiscordLink", "https://discord.gg/rVM2YhHP4U", "Invite link to the discord.", nil, {
	category = "Bastion"
})
ix.config.Add("ContentLink", "https://steamcommunity.com/sharedfiles/filedetails/?id=3326964834", "Link to the workshop collection.", nil, {
	category = "Bastion"
})
ix.config.Add("ForumLink", "https://halobelieve.boards.net", "Link to the forums", nil, {
	category = "Bastion"
})
ix.config.Add("EdictWarningLimit", 1024, "How many edicts can be left before warning messages start to appear.", nil, {
	data = {min = 100, max = 1024},
	category = "Bastion"
})