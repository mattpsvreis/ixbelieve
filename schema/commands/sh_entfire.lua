AddCSLuaFile()

ix.command.Add("entfire", {
	description = "A version of ent_fire that doesn't need sv_cheats 1",
	adminOnly = true,
	arguments = {
		ix.type.string,
		ix.type.string,
		bit.bor(ix.type.string, ix.type.optional)
	},
	OnRun = function(self, ply, target, input, parameters)
		parameters = parameters or ""

		if target == "!picker" or target == "!lookingat" then

			local trace = ply:GetEyeTrace()
			local targ = trace.Entity

			if IsValid( targ ) then

				targ:Fire( input, parameters )
				ix.util.Notify("Command ".. input .. " executed on " .. targ:GetName() .." with parameters: ".. parameters ..".", ply)
				return

			end

			ix.util.Notify("Invalid target specified", ply)

		elseif target == "!allplayers" or target == "!all" then

			local targets = player.GetAll()

			for k, v in pairs( targets ) do

				v:Fire( input, parameters )

			end

		else

			local targets = ents.FindByName( target )

			if #targets == 0 then

				targets = ents.FindByClass( target )

			end

			if #targets == 0 then

				ix.util.Notify("No targets available", ply)
				return

			end

			for k, v in pairs( targets ) do

				v:Fire( input, parameters )

			end

			ix.util.Notify("Command ".. input .. " executed on ".. #targets .." targets with parameters: ".. parameters ..".", ply)
			return

		end
	end
})
