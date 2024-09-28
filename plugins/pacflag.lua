PLUGIN.name = "PAC Flag"
PLUGIN.author = "Gr4Ss"
PLUGIN.description = "Adds a flag to restrict PAC to characters with a certain flag."

ix.flag.Add("P", "Access to PAC3.")

ix.config.Add("AlwaysAllowPACEditor", false, "Always allow people to use the PAC editor, even without the PAC flag.", nil, {category = "PAC3"})

local function checkPacFlag(client)
    if (!client:GetCharacter() or !client:GetCharacter():HasFlags("P")) then
        return false,"You need the PAC flag to use PAC!"
    end
end
hook.Add("PrePACConfigApply", "ixPACFlag", checkPacFlag)

hook.Add("PrePACEditorOpen", "ixPACFlagEditor", function(client)
    if (!ix.config.Get("AlwaysAllowPACEditor")) then
        return checkPacFlag(client)
    end
end)
