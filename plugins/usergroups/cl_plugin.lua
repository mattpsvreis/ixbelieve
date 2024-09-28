
local PLUGIN = PLUGIN

PLUGIN.infoIcon = ix.util.GetMaterial("icon16/information.png")

function PLUGIN:InitPostEntity()
    net.Start("ixSyncUserGroups")
    net.SendToServer()
end

function PLUGIN:HUDPaint()
    if (LocalPlayer():HasToggleAdminGroup() and !LocalPlayer():IsAdminActive() and (!self.displayNoteTime or self.displayNoteTime > CurTime())) then
        if (!self.displayNoteTime) then
            self.displayNoteTime = CurTime() + 30
        end

        if (LocalPlayer():GetLocalVar("toggleAdminManual", 0) > CurTime()) then return end

        local offSet = -10
        if (BRANCH != "x86-64") then
            offSet = -44
        end

        local color = TimedSin(1, 191, 191 + 128, 0)
        draw.SimpleText("You can toggle your admin on!", "HUD_Oxanium", ScrW() - 10, ScrH() + offSet, Color(255,color,color,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    else
        self.displayNoteTime = nil
    end
end

function PLUGIN:GetPlayerESPText(client, toDraw, distance, alphaFar, alphaMid, alphaClose)
    if (client:IsAdminActive() and (client:GetMoveType() != MOVETYPE_OBSERVER or client:InVehicle())) then
        toDraw[#toDraw + 1] = {alpha = alphaFar, priority = 1, text = "Admin Active"}
    end
end

function PLUGIN:UpdateGroupPrivilege(userGroup, privName, value)
    net.Start("ixUpdateUserGroupPrivilege")
        net.WriteString(userGroup.Name)
        net.WriteString(privName)
        net.WriteUInt(value, 3)
    net.SendToServer()
end

function PLUGIN:PrintStaffList(amount)
    for _ = 1, amount do
        local group = net.ReadString()
        local members = net.ReadUInt(8)
        local memberList = {}
        for _ = 1, members do
            local entity = net.ReadEntity()
            memberList[#memberList + 1] = (entity.SteamName and entity:SteamName()) or entity:Name()
        end

        table.sort(memberList)
        chat.AddText(self.infoIcon, "[", string.utf8upper(group), "]: ", table.concat(memberList, ", "))
    end
end

net.Receive("ixStaffList", function(len)
    PLUGIN:PrintStaffList(net.ReadUInt(8))
end)

net.Receive("ixSyncUserGroups", function(len)
    local groupName = net.ReadString()
    local amount = net.ReadUInt(12)

    local userGroup = CAMI.GetUsergroup(groupName)
    for i = 1, amount do
        userGroup.Privileges[net.ReadString()] = net.ReadUInt(3)
        --TODO: update priv edit UI here
    end
end)

net.Receive("ixUpdateUserGroupPrivilege", function(len)
    --TODO: Open priv edit UI here
end)


-- Get usergroups: CAMI.GetUsergroups(), for name, userGroup in pairs(CAMI.GetUsergroups()) do ... end
-- Get usergroup name: userGroup.name
-- Get privileges of usergroup: for privName in pairs(userGroup.Privileges) do ... end
-- Get privilege description: CAMI.GetPrivilege(privName).Description
-- Get default value: userGroup.Defaults[privName] (1 -> INHERIT, 2 -> ALLOW)
-- Get current value: userGroup.Privileges[privName] (0 -> DEFAULT, 1 -> INHERIT, 2 -> ALLOW, 3 -> DENY, 4 -> NEVER)
-- Get actual inherited/default value: ix.userGroups:HasPermissionRaw(userGroup, privName) (2 -> ALLOW, 3 -> DENY, 4 -> NEVER) + userGroup name

--[[
    local valueToText = {[0] = "DEFAULT", [1] = "INHERIT", [2] = "ALLOW", [3] = "DENY", [4] = "NEVER"}
    local sortedGroups = {}
    for name, userGroup in pairs(CAMI.GetUsergroups()) do
        sortedGroups[#sortedGroups + 1] = userGroup
    end

    table.sort(sortedGroups, function(a, b)
        if (a.Priority == b.Priority) then
            return a.name < b.name
        else
            return a.Priority < b.Priority
        end
    end)

    for _, userGroup in ipairs(sortedGroups) do
        -- create category: groupName + inheritsFrom
        local groupName = userGroup.Name
        local inheritsFrom = userGroup.Inherits


        for privName, privilege in pairs(CAMI.GetPrivileges()) do
            if (!userGroup.privileges[privilege.LowerName]) then continue end
            local description = privilege.Description
            local curVal, defVal = userGroup.Privileges[privilege.LowerName], userGroup.Defaults[privilege.LowerName]
            local actual, actualFrom = ix.userGroups:HasPermissionRaw(userGroup, privName)

            local curText, defText, actualText = valueToText[curVal], valueToText[defText], valueToText[actual]

            --create privilege label: privName + description + curText + defText + actualText + actualFrom
            -- + a way to edit the permission to a new value 0/1/2/3/4
            -- + register this panel so we can update it
            local panel = ...
            self.panels[userGroup.Name] = self.panels[userGroup.Name] or {}
            self.panels[userGroup.Name][privName] = panel
            ...

            button.DoClick = function(self)
                PLUGIN:UpdateGroupPrivilege(userGroup, privName, value)
            end
        end
    end
--]]