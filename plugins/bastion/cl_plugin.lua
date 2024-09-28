local CAMI = CAMI
local LocalPlayer = LocalPlayer
local L = L
local SetClipboardText = SetClipboardText
local chat = chat
local net = net
local string = string
local tonumber = tonumber
local render = render
local Color = Color
local gui = gui
local hook = hook
local surface = surface
local netstream = netstream
local ipairs = ipairs
local MsgN = MsgN
local ix = ix

local PLUGIN = PLUGIN

function PLUGIN:PopulateScoreboardPlayerMenu(client, menu)
    if (CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands")) then
        menu:AddOption(L("bastionCopySteamName"), function()
            SetClipboardText(client:SteamName())
            LocalPlayer():NotifyLocalized("bastionCopiedSteamName")
        end)

        menu:AddOption(L("bastionCopyCharName"), function()
            SetClipboardText(client:Name())
            LocalPlayer():NotifyLocalized("bastionCopiedCharName")
        end)
    end

	if (CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Basic Admin Commands") and !LocalPlayer():InVehicle() and client != LocalPlayer()) then
        menu:AddOption(L("bastionGoto"), function()
            if (LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP) then
                LocalPlayer():ConCommand("noclip")
            end
            LocalPlayer():ConCommand("say /goto "..client:Name())
        end)
    end
end

function PLUGIN:PrintTarget(target)
    if (ix.option.Get("pgi")) then
        SetClipboardText(target:SteamID())
    end

    local text = {
        target:Name(), " (", target:SteamName(), "; ", target:SteamID(), ") | HP: ", target:Health(), " | Armor: ", target:Armor()
    }

    LocalPlayer():ChatNotify(table.concat(text))
end

function PLUGIN:ShouldDisplayArea(id)
    if (LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP and !LocalPlayer():InVehicle()) then
        return false
    end
end

local commands = {
    ["playsound"] = 2,
    ["showentsinradius"] = 1,
    ["playsong"] = 3,
    ["spawnremove"] = 1
}

function PLUGIN:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
    local command = string.utf8lower(ix.chat.currentCommand)

    if (commands[command]) then
        local range = tonumber(ix.chat.currentArguments[commands[command]])

        if (range) then
            render.SetColorMaterial()
            render.DrawSphere(LocalPlayer():GetPos(), 0 - range, 50, 50, Color(255, 150, 0, 100))
        end
    elseif (IsValid(ix.gui.chat) and ix.gui.chat:IsVisible() and ix.gui.chat.bActive and ix.chat.currentCommand != "") then
        for k, v in ipairs(ix.chat.currentArguments) do
            local _, _, match = string.find(v, "^!?%+(%d+)")
            if (match) then
                render.SetColorMaterial()
                render.DrawSphere(LocalPlayer():GetPos(), 0 - match, 50, 50, Color(255, 150, 0, 100))
            end
        end
    end
end

net.Receive("ixOpenURL", function(len)
    gui.OpenURL(net.ReadString())
end)

net.Receive("ixPlayerInfo", function(len)
    PLUGIN:PrintTarget(net.ReadEntity())
end)

net.Receive("ixPlaySound", function(len)
    local sound = net.ReadString()
    local isGlobal = net.ReadBool()

    if (hook.Run("PrePlaySound", sound, isGlobal) != false) then
        surface.PlaySound(sound)

        hook.Run("PostPlaySound", sound, isGlobal)
    end
end)

netstream.Hook("PrintInfoList", function(list)
    for _, v in ipairs(list) do
        MsgN(v)
    end
end)

function PLUGIN:OnPlayerChat()
    if (ix.config.Get("suppressOnPlayerChat", true)) then
        return true
    end
end
