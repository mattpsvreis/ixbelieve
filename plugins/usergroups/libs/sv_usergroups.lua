
local ix = ix

ix.userGroups = ix.userGroups or {}

local function findPrivilegeByLowerName(lowerName)
    for privName, privilege in pairs(CAMI.GetPrivileges()) do
        if (privilege.lowerName == lowerName) then
            return privilege
        end
    end
end

function ix.userGroups:SetUserGroupPrivilege(userGroup, privilege, value)
    if (!privilege) then return end

    value = value or ix.userGroups.DEFAULT

    if (userGroup.Privileges[privilege.LowerName]) then
        userGroup.Privileges[privilege.LowerName] = value
        local updateQuery = mysql:Update("ix_privileges")
            updateQuery:Where("group", userGroup.Name)
            updateQuery:Where("privilege", privilege.LowerName)
            updateQuery:Update("value", value)
        updateQuery:Execute()

        self:SyncUserGroupPrivilege(userGroup, privilege.LowerName)
    end
end

function ix.userGroups:LoadUserGroupPrivilege(userGroup, privilege)
    if (!self.DB_READY) then return end

    local selectQuery = mysql:Select("ix_privileges")
        selectQuery:Where("group", userGroup.Name)
        if (privilege) then
            selectQuery:Where("privilege", privilege.LowerName)
        end
        selectQuery:Callback(function(result)
            if (result and #result > 0) then
                for _, v in ipairs(result) do
                    if (!userGroup.Defaults[v.privilege]) then continue end

                    if (userGroup.Privileges[v.privilege] != v.value) then
                        userGroup.Privileges[v.privilege] = v.value
                        self:SyncUserGroupPrivilege(userGroup, v.privilege)
                        if (v.default != userGroup.Defaults[v.privilege]) then
                            local updateQuery = mysql:Update("ix_privileges")
                                updateQuery:Where("id", v.id)
                                updateQuery:Update("default", userGroup.Defaults[v.privilege])
                            updateQuery:Execute()
                        end
                    end
                end
            elseif (privilege) then
                local insertQuery = mysql:Insert("ix_privileges")
                    insertQuery:Insert("group", userGroup.Name)
                    insertQuery:Insert("privilege", privilege.LowerName)
                    insertQuery:Insert("value", ix.userGroups.DEFAULT)
                    insertQuery:Insert("default", userGroup.Defaults[privilege.LowerName])
                insertQuery:Execute()
            else
                for k, v in pairs(userGroup.Defaults) do
                    local insertQuery = mysql:Insert("ix_privileges")
                        insertQuery:Insert("group", userGroup.Name)
                        insertQuery:Insert("privilege", k)
                        insertQuery:Insert("value", ix.userGroups.DEFAULT)
                        insertQuery:Insert("default", v)
                    insertQuery:Execute()
                end
            end
        end)
    selectQuery:Execute()
end

function ix.userGroups:ReloadPrivileges()
    for _, userGroup in pairs(CAMI.GetUsergroups()) do
        ix.userGroups:LoadUserGroupPrivilege(userGroup)
    end
end

function ix.userGroups:PrunePrivileges()
    for name, userGroup in pairs(CAMI.GetUsergroups()) do
        local inheritFrom = CAMI.GetUsergroup(userGroup.Inherits)
        if (!inheritFrom or inheritFrom == userGroup) then continue end

        for lowerName, privValue in pairs(userGroup.Privileges) do
            local bUpdate = false
            if (privValue > ix.userGroups.INHERIT) then
                local value = ix.userGroups:HasPermissionRaw(inheritFrom, lowerName)
                if (value == privValue) then
                    userGroup.Privileges[lowerName] = ix.userGroups.INHERIT
                    bUpdate = true
                end
            end

            if (privValue == userGroup.Defaults[lowerName]) then
                userGroup.Privileges[lowerName] = ix.userGroups.DEFAULT
                bUpdate = true
            end

            if (bUpdate) then
                ix.userGroups:SetUserGroupPrivilege(userGroup, findPrivilegeByLowerName(lowerName), userGroup.Privileges[lowerName])
            end
        end
    end
end

function ix.userGroups:CleanStalePrivileges()
    local selectQuery = mysql:Select("ix_privileges")
        selectQuery:Select("privilege")
        selectQuery:Callback(function(result)
            if (!result) then return end
            local privileges = CAMI.GetPrivileges()
            local deleted = {}
            for _, priv in ipairs(result) do
                local privName = priv.privilege
                if (deleted[privName]) then continue end
                local bFound = false
                for _, privilege in pairs(privileges) do
                    if privilege.LowerName == privName then
                        bFound = true
                        break
                    end
                end

                if (!bFound) then
                    print(privName.." not found, deleting")
                    local deleteQuery = mysql:Delete("ix_privileges")
                        deleteQuery:Where("privilege", privName)
                    deleteQuery:Execute()
                    deleted[privName] = true
                end
            end
        end)
    selectQuery:Execute()
end

function ix.userGroups:SyncUserGroups(client)
    local i = 0.1
    local bToClient = IsValid(client)
    for _, userGroup in pairs(CAMI.GetUsergroups()) do
        timer.Simple(i + math.random(1, 5) * FrameTime(), function()
            net.Start("ixSyncUserGroups")
                net.WriteString(userGroup.Name)
                net.WriteUInt(table.Count(userGroup.Privileges), 12)
                for k, v in pairs(userGroup.Privileges) do
                    net.WriteString(k)
                    net.WriteUInt(v, 3)
                end
            if (bToClient) then
                if (IsValid(client)) then
                    net.Send(client)
                end
            else
                net.Broadcast()
            end
        end)

        i = i + 0.5
    end
end

function ix.userGroups:SyncUserGroupPrivilege(userGroup, privilege)
    net.Start("ixSyncUserGroups")
        net.WriteString(userGroup.Name)
        net.WriteUInt(1, 12)
        net.WriteString(privilege)
        net.WriteUInt(userGroup.Privileges[privilege], 3)
    net.Broadcast()
end

function ix.userGroups:DeleteUserGroup(userGroup)
    if (!self.DB_READY) then return end

    local deleteQuery = mysql:Delete("ix_privileges")
        deleteQuery:Where("group", userGroup.Name)
    deleteQuery:Execute()
end

function ix.userGroups:DeletePrivilege(privilege)
    if (!self.DB_READY) then return end

    local deleteQuery = mysql:Delete("ix_privileges")
        deleteQuery:Where("privilege", privilege.LowerName)
    deleteQuery:Execute()
end

concommand.Add("usergroups_cleanstale", function(ply)
    if (IsValid(ply)) then return end
    ix.userGroups:CleanStalePrivileges()
end)

concommand.Add("usergroups_prune", function(ply)
    if (IsValid(ply)) then return end
    ix.userGroups:PrunePrivileges()
end)

concommand.Add("usergroups_updateactuals", function(ply)
    if (IsValid(ply)) then return end
    for name, userGroup in pairs(CAMI.GetUsergroups()) do
        for privName in pairs(userGroup.Privileges) do
            local actual, from = ix.userGroups:HasPermissionRaw(userGroup, privName)
            local updateQuery = mysql:Update("ix_privileges")
                updateQuery:Update("actual", actual)
                updateQuery:Update("actual_from", from)
                updateQuery:Where("group", name)
                updateQuery:Where("privilege", string.lower(privName))
            updateQuery:Execute()
        end
    end
end)