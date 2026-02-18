local _, ns = ...
local Core = ns.Core

local PetBattleUI = {}
ns.PetBattleUI = PetBattleUI

local PET_SLOTS = 3

local function FormatHealthText(health, maxHealth)
    health = tonumber(health) or 0
    maxHealth = tonumber(maxHealth) or 0
    return string.format("%d / %d", health, maxHealth)
end

local function CreatePetSubframe(parent, ownerLabel, petIndex)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(240, 64)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture(134400)
    frame.icon = icon

    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    name:SetPoint("RIGHT", -8, 0)
    name:SetJustifyH("LEFT")
    name:SetText(ownerLabel .. " Pet " .. petIndex)
    frame.name = name

    local health = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    health:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    health:SetPoint("RIGHT", -8, 0)
    health:SetJustifyH("LEFT")
    health:SetText("Health: --")
    frame.health = health

    local meta = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    meta:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -3)
    meta:SetPoint("RIGHT", -8, 0)
    meta:SetJustifyH("LEFT")
    meta:SetText("--")
    frame.meta = meta

    return frame
end

local function CreatePartyFrame(anchorPoint, relativePoint, x, y, titleText)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(270, 255)
    frame:SetPoint(anchorPoint, UIParent, relativePoint, x, y)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(titleText)

    frame.petFrames = {}
    for i = 1, PET_SLOTS do
        local petFrame = CreatePetSubframe(frame, titleText, i)
        if i == 1 then
            petFrame:SetPoint("TOP", 0, -44)
        else
            petFrame:SetPoint("TOP", frame.petFrames[i - 1], "BOTTOM", 0, -8)
        end
        frame.petFrames[i] = petFrame
    end

    frame:Hide()
    return frame
end

function PetBattleUI:EnsureFrames()
    if self.playerFrame and self.enemyFrame then
        return
    end

    self.playerFrame = CreatePartyFrame("TOPLEFT", "TOPLEFT", 24, -180, "Player")
    self.enemyFrame = CreatePartyFrame("TOPRIGHT", "TOPRIGHT", -24, -180, "Enemy")
end

function PetBattleUI:UpdateParty(frame, team)
    if not frame or not frame.petFrames then
        return
    end

    local pets = (team and team.pets) or {}

    for i = 1, PET_SLOTS do
        local petFrame = frame.petFrames[i]
        local pet = pets[i]

        if pet then
            petFrame:Show()
            petFrame.icon:SetTexture(pet.icon or 134400)

            local name = pet.name or ("Pet " .. i)
            if pet.isActive then
                name = "|cff00ff00▶ " .. name .. "|r"
            end

            petFrame.name:SetText(string.format("%s (Lvl %s)", name, tostring(pet.level or "?")))
            petFrame.health:SetText("Health: " .. FormatHealthText(pet.health, pet.maxHealth))
            petFrame.meta:SetText(string.format("%s | Speed %s", tostring(pet.petTypeLabel or "Unknown"), tostring(pet.speed or "?")))
        else
            petFrame:Hide()
        end
    end
end

function PetBattleUI:Refresh()
    if not Core or not Core.IsPetBattleUIEnabled or not Core:IsPetBattleUIEnabled() or not Core.inPetBattle then
        return
    end

    self:EnsureFrames()

    local snapshot = Core:BuildBattleSnapshot()
    self:UpdateParty(self.playerFrame, snapshot.player)
    self:UpdateParty(self.enemyFrame, snapshot.enemy)
end

function PetBattleUI:ApplyVisibility()
    self:EnsureFrames()

    local shouldShow = Core and Core.IsPetBattleUIEnabled and Core:IsPetBattleUIEnabled() and Core.inPetBattle
    if shouldShow then
        self.playerFrame:Show()
        self.enemyFrame:Show()
        self:Refresh()
    else
        self.playerFrame:Hide()
        self.enemyFrame:Hide()
    end
end

function PetBattleUI:OnBattleStart()
    self:ApplyVisibility()

    if self.updateTicker then
        self.updateTicker:Cancel()
        self.updateTicker = nil
    end

    if Core and Core.IsPetBattleUIEnabled and Core:IsPetBattleUIEnabled() then
        self.updateTicker = C_Timer.NewTicker(0.2, function()
            self:Refresh()
        end)
    end
end

function PetBattleUI:OnBattleEnd()
    if self.updateTicker then
        self.updateTicker:Cancel()
        self.updateTicker = nil
    end

    if self.playerFrame then
        self.playerFrame:Hide()
    end

    if self.enemyFrame then
        self.enemyFrame:Hide()
    end
end
