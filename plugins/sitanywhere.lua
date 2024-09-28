
local PLUGIN = PLUGIN

PLUGIN.name = "Sit Anywhere compatibility"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Removes ALT+E and adds a /sit command"

-- Remove sitanywhere alt+e
hook.Remove("KeyPress", "SitAnywhere")

ix.command.Add("sit",{

  description = "Sits where you are looking (needs to be on an edge or a lip)",
  arguments = {},
  OnRun = function(self,client)

		client:ConCommand("sit")

  end
})
