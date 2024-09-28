local ix = ix

ix.userGroups = ix.userGroups or {}

ix.userGroups.DEFAULT = 0
ix.userGroups.INHERIT = 1
ix.userGroups.ALLOW = 2
ix.userGroups.DENY = 3
ix.userGroups.NEVER = 4

function ix.userGroups:HasPermissionRaw(userGroup, privName)
    if (!userGroup) then
        return self.DENY, "invalidGroup"
    end

    privName = string.lower(privName)

    value = userGroup.Privileges[privName]
    if (value == self.DEFAULT) then
        value = userGroup.Defaults[privName]
    end

    if (!value) then
        return self.DENY, "invalidPriv"
    end

    if (value == self.INHERIT) then
        if (userGroup.Inherits and userGroup.Inherits != userGroup.Name) then
            return self:HasPermissionRaw(CAMI.GetUsergroup(userGroup.Inherits), privName)
        else
            return self.DENY, "notgranted"
        end
    end

    return value, userGroup.Name
end