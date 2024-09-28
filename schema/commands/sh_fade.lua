AddCSLuaFile()

CAMI.RegisterPrivilege({
	Name = "Helix - Player Fade",
	MinAccess = "admin",
	Description = "Allows to fade players' screen in and out."
})
ix.command.Add("PlyFadeIn", {
	description = "Fades a player in",
	privilege = "Player Fade",
	arguments = {
		ix.type.player,
		ix.type.number,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, duration, r, g, b, a)
		r = r or 0
		g = g or 0
		b = b or 0
		a = a or 255

		target:ScreenFade( SCREENFADE.PURGE, Color( r, g, b, a ), 0, 0 )
		target:ScreenFade( SCREENFADE.IN, Color( r, g, b, a ), duration, 0 )

		ix.util.NotifyCami(string.format("%s faded in %s's screen [%i %i %i %f/%fs]", client:Name(), target:Name(), r, g, b, a, duration), "Helix - Player Fade", target)
	end
})


ix.command.Add("PlyFadeOut", {
	description = "Fades a player out",
	privilege = "Player Fade",
	arguments = {
		ix.type.player,
		ix.type.number,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, duration, r, g, b, a)
		r = r or 0
		g = g or 0
		b = b or 0
		a = a or 255

		target:ScreenFade( SCREENFADE.PURGE, Color( r, g, b, a ), 0, 0 )
		target:ScreenFade( SCREENFADE.OUT, Color( r, g, b, a ), duration, 0 )

		timer.Simple( duration, function()

			target:ScreenFade( SCREENFADE.STAYOUT, Color( r, g, b, a ), 0, 0 )

		end )

		ix.util.NotifyCami(string.format("%s faded out %s's screen [%i %i %i %f/%fs]", client:Name(), target:Name(), r, g, b, a, duration), "Helix - Player Fade", target)
	end
})


ix.command.Add("FadeIn", {
	description = "Fades the server in",
	adminOnly = true,
	arguments = {
		ix.type.number,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, duration, r, g, b, a)
		r = r or 0
		g = g or 0
		b = b or 0
		a = a or 255

		for k, target in pairs(player.GetAll()) do
			target:ScreenFade( SCREENFADE.PURGE, Color( r, g, b, a ), 0, 0 )
			target:ScreenFade( SCREENFADE.IN, Color( r, g, b, a ), duration, 0 )
		end

		ix.util.Notify(string.format("%s faded in everyone's screen [%i %i %i %f/%fs]", client:Name(), r, g, b, a, duration))
	end
})

ix.command.Add("FadeOut", {
	description = "Fades the server out",
	adminOnly = true,
	arguments = {
		ix.type.number,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, duration, r, g, b, a)
		r = r or 0
		g = g or 0
		b = b or 0
		a = a or 255

		local text = string.format("%s faded out everyone's screen [%i %i %i %f/%fs]", client:Name(), r, g, b, a, duration)
		for k, target in pairs(player.GetAll()) do
			target:ScreenFade( SCREENFADE.PURGE, Color( r, g, b, a ), 0, 0 )
			target:ScreenFade( SCREENFADE.OUT, Color( r, g, b, a ), duration, 0 )
		end

		timer.Simple( duration, function()
			for k, target in pairs(player.GetAll()) do
				target:ScreenFade( SCREENFADE.STAYOUT, Color( r, g, b, a ), 0, 0 )
			end
		end )

		ix.util.Notify(text)
	end
})

ix.command.Add("Unfade", {
	description = "Removes any fade effects.",
	OnRun = function(self, client)
		client:ScreenFade( SCREENFADE.PURGE, color_black, 0, 0 )

		ix.util.NotifyCami(string.format("%s unfaded their screen", client:Name()), "Helix - Player Fade", client)
	end
})
