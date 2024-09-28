--VERSION SUPPORT: 1.1, 1.1-beta

PLUGIN.name = "Scrolling Text"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Provides an interface for drawing and sending 'scrolling text.'"

ix.scroll = ix.scroll or {}
ix.scroll.buffer = ix.scroll.buffer or {}

local CHAR_DELAY = 0.1

if (CLIENT) then
	NUT_CVAR_SCROLLVOL = CreateClientConVar("ix_scrollvol", 40, true)

	--[[
		Purpose: Adds the text into the scrolling queue so it will draw.
		If a callback is provided, then it will be called once the text has
		finished typing and no longer draws.
	--]]
	function ix.scroll.add(text, callback)
		local info = {text = "", callback = callback, nextChar = 0, char = ""}
		table.insert(ix.scroll.buffer, info)
		local i = 1

		timer.Create("ix_Scroll"..tostring(info), CHAR_DELAY, #text, function()
			if (info) then
				info.text = string.sub(text, 1, i)
				i = i + 1

				LocalPlayer():EmitSound("common/talk.wav", NUT_CVAR_SCROLLVOL:GetInt(), math.random(120, 140))

				if (i >= #text) then
					info.char = ""
					info.start = CurTime() + 3
					info.finish = CurTime() + 5
				end
			end
		end)
	end

	local SCROLL_X = ScrW() * 0.05
	local SCROLL_Y = ScrH() * 0.4

	--[[
		Purpose: Called in the HUDPaint hook, it loops through the
		scrolling text and draws the text accordingly.
	--]]
	function PLUGIN:HUDPaint()
		local curTime = CurTime()
		for k, v in pairs(ix.scroll.buffer) do
			local alpha = 255

			if (v.start and v.finish) then
				alpha = 255 - math.Clamp(math.TimeFraction(v.start, v.finish, curTime) * 255, 0, 255)
			elseif (v.nextChar < curTime) then
				v.nextChar = CurTime() + 0.01
				v.char = string.char(math.random(47, 90))
			end

			ix.util.DrawText(v.text..v.char, SCROLL_X, SCROLL_Y + (k * 24), Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)


			if (alpha == 0) then
				if (v.callback) then
					v.callback()
				end

				table.remove(ix.scroll.buffer, k)
			end
		end
	end

	netstream.Hook("ix_ScrollData", function(data)
		ix.scroll.add(data)
	end)
else
	--[[
		Purpose: Sends a net message to call ix.scroll.Add client-side. If
		provided a callback, it will be called once the text finishes 'typing.'
	--]]
	function ix.scroll.send(text, receiver, callback)
		netstream.Start(receiver, "ix_ScrollData", text)

		timer.Simple(CHAR_DELAY*#text, function()
			if (callback) then
				callback()
			end
		end)
	end

	function ix.scroll.add(text)
		local cr = coroutine.create(function ()
			for k, v in pairs(text) do
				local cor = coroutine.running()
				ix.scroll.send(v, nil, function ()
					local success, err = coroutine.resume(cor)
					if not success then Error(err) end
				end)
				coroutine.yield()
			end
		end)

		local success, err = coroutine.resume(cr)
		if not success then Error(err) end
	end
end


ix.command.Add("scrolltext", {
	description = "Prints scrolling text to a player's screen",
	adminOnly = true,
	arguments = {
		ix.type.text
	},
	OnRun = function(self, client, text)
    	if text == "" then return end
		ix.scroll.add(string.Split(text, "\\n"))
	end
})
