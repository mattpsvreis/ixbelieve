
function Schema:LoadFonts(font, genericFont)
    surface.CreateFont("HUD_Oxanium", {
		font = "Oxanium",
		size = math.max(10 * (ScrW()/2200), 14),
		extended = true,
		weight = 500
	})

    surface.CreateFont("Oxanium17", {
		font = "Oxanium",
		size = math.max(17 * (ScrW()/2200), 14),
		extended = true,
		weight = 500
	})

    surface.CreateFont("Oxanium22", {
        font = "Oxanium",
        size = math.max(22 * (ScrW()/2200), 14),
        extended = true,
        weight = 500
    })

    surface.CreateFont("ixGenericFontTiny", {
		font = font,
		size = 12,
		extended = true,
		weight = 500
	})

    surface.CreateFont( "ProperConsolas", {
        font = "Consolas", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
        extended = false,
        size = 28,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })

    surface.CreateFont("MenuFontNoClamp", {
		font = "Open Sans",
		extended = false,
		size = SScaleMin(20 / 3),
		weight = 550,
		antialias = true,
	})
end