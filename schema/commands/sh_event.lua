AddCSLuaFile()

CAMI.RegisterPrivilege({
	Name = "Helix - Event",
	MinAccess = "admin",
	Description = "Ability to use the event commands."
})
ix.command.Add("Event", {
	alias = {"ev"},
	description = "@cmdEvent",
	arguments = ix.type.text,
	privilege = "Event",
	OnRun = function(self, client, text)
		ix.chat.Send(client, "event", text)
	end
})

ix.command.Add("LocalEvent", {
	alias = {"lev"},
	description = "Sends a local event",
	arguments = ix.type.text,
	privilege = "Event",
	OnRun = function(self, client, text)
		ix.chat.Send(client, "localevent", text)
	end
})

ix.command.Add("PrivateEvent", {
	alias = {"pev"},
	description = "Sends a private event",
	arguments =
	{
		ix.type.player,
		ix.type.text
	},
	acceptMulti = true,
	privilege = "Event",
	OnRun = function(self, client, target, text)
		local receivers = istable(target) and target or {target}
		table.insert(receivers, client)

		ix.chat.Send(client, "privateevent", text, false, receivers)
	end
})

ix.command.Add("pda", {
	description = "Sends a private message via PDA to a character",
	arguments =
	{
		ix.type.player,
		ix.type.text
	},
	acceptMulti = true,
	OnRun = function(self, client, target, text)
		local receivers = istable(target) and target or {target}
		table.insert(receivers, client)

		ix.chat.Send(client, "pda", text, false, receivers)
	end
})
