
local PLUGIN = PLUGIN

PLUGIN.name = "Improved Commands"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Improves command player targetting and adds various command aliases"

PLUGIN.COMMAND_TOKEN_HELP = [[$<faction> | #<squad> | +<radius>
^ : yourself
* : everyone
- : everyone not in observer
~ : the person you are looking at
!<token> : everyone except ... (use with tokens)]]
local COMMAND_PREFIX = "/"

CAMI.RegisterPrivilege({
	Name = "Helix - Command Tokens",
	MinAccess = "admin",
	Description = "Allows to use special command tokens to target multiple people at once."
})

PLUGIN.search = {"ply", "char", "act"}
PLUGIN.except = {
	["charkick"] = true,
	["charban"] = true,
	["action"] = true,
	["plyfadeout"] = true,
	["plyfadein"] = true,
}

ix.command.Add("TokenHelp", {
	description = "Prints which command tokens are available for what",
	privilege = "Command Tokens",
	OnRun = function(self, client, text)
		client:ChatNotify(PLUGIN.COMMAND_TOKEN_HELP)
	end
})


function PLUGIN:InitializedPlugins()
	for command, info in pairs(ix.command.list) do
		if (self.except[string.lower(command)]) then
			continue
		end

		for _, prefix in ipairs(self.search) do
			if string.StartWith(command, prefix) then
				local value = command:gsub(prefix, "")

				if (!info.alias) then
                    info.alias = value
                elseif (istable(info.alias)) then
                    table.insert(info.alias, value)
                else
                    info.alias = {info.alias, value}
                end

				ix.command.list[value] = info
			end
		end
	end
end

local function ArgumentCheckStub(command, client, given)
	local arguments = command.arguments
	local multi = nil
	local multiType = nil
	local result = {}

	for i = 1, #arguments do
		local bOptional = bit.band(arguments[i], ix.type.optional) == ix.type.optional
		local argType = bOptional and bit.bxor(arguments[i], ix.type.optional) or arguments[i]
		local argument = given[i]
		local negate = false

		if (!argument and !bOptional) then
			return L("invalidArg", client, i)
		end

		if (argType == ix.type.string) then
			if (!argument and bOptional) then
				result[#result + 1] = nil
			else
				result[#result + 1] = tostring(argument)
			end
		elseif (argType == ix.type.text) then
			result[#result + 1] = table.concat(given, " ", i) or ""
			break
		elseif (argType == ix.type.number) then
			local value = tonumber(argument)

			if (!bOptional and !value) then
				return L("invalidArg", client, i)
			end

			result[#result + 1] = value
		elseif (argType == ix.type.player or argType == ix.type.character) then
			local bPlayer = argType == ix.type.player

			local idx = #result + 1
			local value = ix.util.FindPlayer(argument or "")

			if (bOptional and (!argument or argument == "")) then
				result[idx] = nil
			else
				if string.StartWith(argument, "!") then
					negate = true
					argument = string.sub(argument, 2)
				else
					negate = false
				end

				if argument == "*" then
					if multi then
						return "You can only use command tokens in one argument."
					end

					local r = {}
					if argType == ix.type.character then
						for k, v in ipairs(player.GetAll()) do
							if v:GetCharacter() != nil then
								r[k] = v:GetCharacter()
							end
						end
					else
						r = player.GetAll()
					end
					multi = idx
					result[idx]  = r
					multiType = "everyone"
				elseif string.StartWith(argument, "$") then
					if multi then
						return "You can only use command tokens in one argument."
					end

					local faction = string.lower(string.sub(argument, 2))
					if (!ix.faction.teams[faction]) then
						return "That isn't a valid faction."
					end

					local factionTable = ix.faction.teams[faction]
					local teamId = factionTable.index

					local r = {}
					for k, v in pairs(team.GetPlayers(teamId)) do
						if argType == ix.type.character then
							if v:GetCharacter() != nil then
								r[v:EntIndex()] = v:GetCharacter()
							end
						else
							r[v:EntIndex()] = v
						end

					end

					if !negate and table.Count(r) == 0 then
						return "No players matching this criteria could be found."
					end

					multi = idx
					multiType = factionTable.name
					result[idx] = r
				elseif string.StartWith(argument, "#") then
					if multi then
						return "You can only use command tokens in one argument."
					end

					local squad = string.Trim(string.lower(string.sub(argument, 2)))
					if !squad or squad == "" then
						return "That isn't a valid squad."
					end

					local r = {}
					for k, v in ipairs(player.GetAll()) do
						if string.lower(v:GetNetVar("iffSquadName", "")) != squad then
							continue
						end

						if argType == ix.type.character then
							r[v:EntIndex()] = v:GetCharacter()
						else
							r[v:EntIndex()] = v
						end
					end

					if table.Count(r) == 0 then
						return "That isn't a valid squad."
					end

					multi = idx
					multiType = "squad"
					result[idx] = r
				elseif string.StartWith(argument, "+") then
					if multi then
						return "You can only use command tokens in one argument."
					end

					local radius = tonumber(string.Trim(string.sub(argument, 2)))
					if !radius then
						return "That isn't a valid radius."
					else
						radius = radius * radius
					end

					local r = {}
					local pos = client:GetPos()
					for k, v in ipairs(player.GetAll()) do
						if  (pos:DistToSqr(v:GetPos()) > radius) then
							continue
						end

						if argType == ix.type.character then
							r[v:EntIndex()] = v:GetCharacter()
						else
							r[v:EntIndex()] = v
						end
					end

					if !negate and table.Count(r) == 0 then
						return "No players matching this criteria could be found."
					end

					multi = idx
					multiType = "radius"
					result[idx] = r
				elseif argument == "-" then
					if multi then
						return "You can only use command tokens in one argument."
					end

					local r = {}
					for k, v in ipairs(player.GetAll()) do
						if (v:GetMoveType() == MOVETYPE_NOCLIP and !v:InVehicle()) then
							continue
						end

						if argType == ix.type.character then
							r[v:EntIndex()] = v:GetCharacter()
						else
							r[v:EntIndex()] = v
						end
					end

					if !negate and table.Count(r) == 0 then
						return "No players matching this criteria could be found."
					end

					multi = idx
					multiType = "observer"
					result[idx] = r
				elseif argument == "^" then
					result[idx] = argType == ix.type.player and client or client:GetCharacter()
				elseif argument == "~" then
					local entity = client:GetEyeTraceNoCursor().Entity
					if (!IsValid(entity) or !entity:IsPlayer()) then
						return "You are not looking at a valid target!"
					end

					result[idx] = argType == ix.type.player and entity or entity:GetCharacter()
				else
					value = ix.util.FindPlayer(argument or "") -- argument could be nil due to optional type

					-- FindPlayer emits feedback for us
					if (!value and !bOptional) then
						return L(bPlayer and "plyNoExist" or "charNoExist", client)
					end

					-- check for the character if we're using the character type
					if (!bPlayer) then
						local character = value:GetCharacter()

						if (!character) then
							return L("charNoExist", client)
						end

						value = character
					end
					result[idx] = value
				end
			end

			if negate then

				if multi and multi != idx then
					return "You can only use command tokens in one argument."
				end
				multi = idx

				local r = result[idx]
				multiType = "everyone but " .. (multiType or (bPlayer and r:Name() or r:GetPlayer():Name()))
				local rIsTable = type(r) == "table"
				local out = {}

				for k, v in ipairs(player.GetAll()) do
					if rIsTable then
						if r[v:EntIndex()] then
							continue
						end
					else
						if r == v then
							continue
						end
					end

					if argType == ix.type.character then
						if v:GetCharacter() != nil then
							table.insert(out, v:GetCharacter())
						end
					else
						table.insert(out, v)
					end
				end

				if (table.Count(out) == 0) then
					return "No players matching this criteria could be found."
				end
				result[idx] = out
			end
		elseif (argType == ix.type.steamid) then
			local value = argument:match("STEAM_(%d+):(%d+):(%d+)")

			if (!value and bOptional) then
				return L("invalidArg", client, i)
			end

			result[#result + 1] = value
		elseif (argType == ix.type.bool) then
			if (argument == nil and bOptional) then
				result[#result + 1] = nil
			else
				result[#result + 1] = tobool(argument)
			end
		end
	end

	return result, multi, multiType
end

--- Forces a player to execute a command by name.
-- @realm server
-- @player client Player who is executing the command
-- @string command Full name of the command to be executed. This string gets lowered, but it's good practice to stick with
-- the exact name of the command
-- @tab arguments Array of arguments to be passed to the command
-- @usage ix.command.Run(player.GetByID(1), "Roll", {10})
function ix.command.Run(client, command, arguments)
	if ((client.ixCommandCooldown or 0) > RealTime()) then
		return
	end

	command = ix.command.list[tostring(command):lower()]

	if (!command) then
		return
	end

	-- we throw it into a table since arguments get unpacked and only
	-- the arguments table gets passed in by default
	local argumentsTable = arguments
	arguments = {argumentsTable}

	-- if feedback is non-nil, we can assume that the command failed
	-- and is a phrase string
	local feedback

	-- check for group access
	if (command.OnCheckAccess) then
		local bSuccess, phrase = command:OnCheckAccess(client)
		feedback = !bSuccess and L(phrase and phrase or "noPerm", client) or nil
	end

	-- check for strict arguments
	local multi = nil
	if (!feedback and command.arguments) then
		arguments, multi = ArgumentCheckStub(command, client, argumentsTable)

		if (isstring(arguments)) then
			feedback = arguments
		end

		if (multi and !command.allowMulti and !CAMI.PlayerHasAccess(client, "Helix - Command Tokens")) then
			feedback = "Only admins can use command tokens."
		end
	end

	-- run the command if all the checks passed
	if (!feedback) then
		if multi and !command.acceptMulti and command.noMulti != true then
			local players = arguments[multi]

			for k, v in ipairs(players) do
				local argCopy = table.Copy(arguments)
				argCopy[multi] = v

				local results = {command:OnRun(client, unpack(argCopy))}
				local phrase = results[1]

				-- check to see if the command has returned a phrase string and display it
				if (isstring(phrase)) then
					if (IsValid(client)) then
						if (phrase:sub(1, 1) == "@") then
							client:NotifyLocalized(phrase:sub(2), unpack(results, 2))
						else
							client:Notify(phrase)
						end
					else
						-- print message since we're running from the server console
						print(phrase)
					end
				end
			end
		else
			local results = {command:OnRun(client, unpack(arguments))}
			local phrase = results[1]

			-- check to see if the command has returned a phrase string and display it
			if (isstring(phrase)) then
				if (IsValid(client)) then
					if (phrase:sub(1, 1) == "@") then
						client:NotifyLocalized(phrase:sub(2), unpack(results, 2))
					else
						client:Notify(phrase)
					end
				else
					-- print message since we're running from the server console
					print(phrase)
				end
			end
		end

		client.ixCommandCooldown = RealTime() + 0.5

		if (IsValid(client)) then
			ix.log.Add(client, "command", COMMAND_PREFIX .. command.name, argumentsTable and table.concat(argumentsTable, " "))
		end
	else
		client:Notify(feedback)
	end
end