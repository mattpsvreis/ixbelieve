
local PLUGIN = PLUGIN
local ix = ix

PLUGIN.name = "Bastion"
PLUGIN.author = "Gr4Ss"
PLUGIN.description = "Some admin extensions for Helix."

ix.util.Include("cl_dupes.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sh_classes.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("sh_commands_basicadmin.lua")
ix.util.Include("sh_context.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sh_register.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("sv_plugin.lua")