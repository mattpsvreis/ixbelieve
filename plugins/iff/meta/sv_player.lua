
local PLAYER = FindMetaTable("Player")

function PLAYER:UpdateIFFInfo()
    local character = self:GetCharacter()
    if (!character) then return end

    local inventory = character:GetInventory()

    local item
    for k, v in pairs(inventory:GetItems()) do
        if (!v.isIFF) then continue end
        if (v:GetData("iff") != 3) then
            item = v
            break
        end
    end

    if (item) then
        self:SetNetVar("iffMode", item:GetData("iff"))
        local squad = item:GetData("squad")
        self:SetNetVar("iffSquadName", squad != "NONE" and squad or "")
        self:SetNetVar("iffFireTeam", item:GetData("fireTeam"))
        self:SetNetVar("iffRole", item:GetData("role"))
    else
        self:SetNetVar("iffMode", 3)
        self:SetNetVar("iffSquadName", nil)
        self:SetNetVar("iffFireTeam", nil)
        self:SetNetVar("iffRole", nil)
    end
end