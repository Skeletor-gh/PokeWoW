local _, ns = ...
local Core = ns.Core

local PetBattleUI = {}
ns.PetBattleUI = PetBattleUI

local PET_SLOTS = 3
local ENEMY_OWNER = Enum and Enum.BattlePetOwner and Enum.BattlePetOwner.Enemy or 2
local ALLY_OWNER = Enum and Enum.BattlePetOwner and Enum.BattlePetOwner.Ally or 1
local UNKNOWN_ICON = 134400

-- Each pet family maps to { strongAgainst, weakAgainst } for battle hints.
local VULNERABILITIES = {
    { 4, 5 }, -- Humanoid
    { 1, 3 }, -- Dragonkin
    { 6, 8 }, -- Flying
    { 5, 2 }, -- Undead
    { 8, 7 }, -- Critter
    { 2, 9 }, -- Magic
    { 9, 10 }, -- Elemental
    { 10, 1 }, -- Beast
    { 3, 4 }, -- Aquatic
    { 7, 6 }, -- Mechanical
}

local abilityListBuffer = {}
local abilityLevelBuffer = {}

local function FormatHealthText(health, maxHealth)
    health = tonumber(health) or 0
    maxHealth = tonumber(maxHealth) or 0
    return string.format("%d / %d", health, maxHealth)
end

local function ClearArray(tbl)
    if not tbl then
        return
    end

    for index = #tbl, 1, -1 do
        tbl[index] = nil
    end
end

local function CreatePetSubframe(parent, ownerLabel, petIndex)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(240, 88)
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

    frame.abilityIcons = {}
    for abilityIndex = 1, PET_SLOTS do
        local abilityIcon = frame:CreateTexture(nil, "ARTWORK")
        abilityIcon:SetSize(18, 18)
        if abilityIndex == 1 then
            abilityIcon:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -4)
        else
            abilityIcon:SetPoint("LEFT", frame.abilityIcons[abilityIndex - 1], "RIGHT", 6, 0)
        end
        abilityIcon:SetTexture(134400)
        frame.abilityIcons[abilityIndex] = abilityIcon
    end

    return frame
end

local function CreatePartyFrame(anchorPoint, relativePoint, x, y, titleText)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(270, 326)
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

    self:EnsureEnemyAbilityFrame()
end

function PetBattleUI:CreateAbilityButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(52, 52)

    button.back = button:CreateTexture(nil, "BACKGROUND")
    button.back:SetAllPoints(true)
    button.back:SetTexture("Interface\\ItemSocketingFrame\\UI-EngineeringSockets")
    button.back:SetTexCoord(0.015625, 0.6875, 0.412109375, 0.49609375)

    button.icon = button:CreateTexture(nil, "BORDER")
    button.icon:SetPoint("TOPLEFT", 6, -6)
    button.icon:SetPoint("BOTTOMRIGHT", -6, 6)
    button.icon:SetTexture(UNKNOWN_ICON)
    button.icon:SetTexCoord(0.0725, 0.9275, 0.0725, 0.9275)

    button.hint = button:CreateTexture(nil, "ARTWORK")
    button.hint:SetSize(20, 20)
    button.hint:SetPoint("BOTTOMRIGHT")
    button.hint:Hide()

    button.cooldown = button:CreateFontString(nil, "ARTWORK", "GameFont_Gigantic")
    button.cooldown:SetPoint("CENTER")
    button.cooldown:Hide()

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetPoint("TOPLEFT")
    button.highlight:SetPoint("BOTTOMRIGHT")
    button.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    button.highlight:SetBlendMode("ADD")

    button:SetScript("OnEnter", function(btn)
        self:ShowAbilityTooltip(btn)
    end)
    button:SetScript("OnLeave", function()
        self:HideAbilityTooltip()
    end)

    return button
end

function PetBattleUI:SetAbilityButtonHalfHeight(button, isHalf)
    if isHalf then
        button:SetHeight(26)
        button.icon:SetPoint("TOPLEFT", 6, -3)
        button.icon:SetPoint("BOTTOMRIGHT", -6, 3)
        button.icon:SetTexCoord(0.0725, 0.9275, 0.3225, 0.6775)
    else
        button:SetHeight(52)
        button.icon:SetPoint("TOPLEFT", 6, -6)
        button.icon:SetPoint("BOTTOMRIGHT", -6, 6)
        button.icon:SetTexCoord(0.0725, 0.9275, 0.0725, 0.9275)
    end
end

function PetBattleUI:EnsureEnemyAbilityFrame()
    if self.enemyAbilityFrame then
        return
    end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(172, 68)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -220)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:Hide()

    frame.buttons = {}
    for i = 1, 6 do
        frame.buttons[i] = self:CreateAbilityButton(frame)
        self:SetAbilityButtonHalfHeight(frame.buttons[i], false)

        if i <= 3 then
            frame.buttons[i]:SetPoint("TOPLEFT", (i - 1) * 54 + 6, -8)
            frame.buttons[i]:SetID(i)
        else
            frame.buttons[i]:SetPoint("TOPLEFT", frame.buttons[i - 3], "BOTTOMLEFT")
            frame.buttons[i]:SetID(i - 3)
            self:SetAbilityButtonHalfHeight(frame.buttons[i], true)
            frame.buttons[i]:Hide()
        end
    end

    self.enemyAbilityFrame = frame
end

function PetBattleUI:ShowAbilityTooltip(button)
    if not button or not button.abilityID then
        return
    end

    if not PetBattlePrimaryAbilityTooltip or not PetBattleAbilityTooltip_SetAbilityByID then
        return
    end

    local activeEnemyPet = C_PetBattles.GetActivePet(ENEMY_OWNER)
    if activeEnemyPet == nil then
        return
    end

    PetBattleAbilityTooltip_SetAbilityByID(ENEMY_OWNER, activeEnemyPet, button.abilityID)
    PetBattlePrimaryAbilityTooltip:ClearAllPoints()
    PetBattlePrimaryAbilityTooltip:SetPoint("BOTTOM", button, "TOP", 0, 0)
    PetBattlePrimaryAbilityTooltip:Show()
end

function PetBattleUI:HideAbilityTooltip()
    if PetBattlePrimaryAbilityTooltip then
        PetBattlePrimaryAbilityTooltip:Hide()
    end
end

function PetBattleUI:FillAbilityButton(button, abilityID)
    button.abilityID = abilityID

    if not abilityID then
        button.icon:SetTexture(UNKNOWN_ICON)
        button.icon:SetDesaturated(true)
        button.icon:SetVertexColor(0.5, 0.5, 0.5)
        button.hint:Hide()
        return
    end

    local _, abilityIcon, _, abilityType = C_PetBattles.GetAbilityInfoByID(abilityID)
    button.icon:SetTexture(abilityIcon or UNKNOWN_ICON)
    button.icon:SetDesaturated(false)
    button.icon:SetVertexColor(1, 1, 1)
    button.hint:Hide()

    local allyActivePet = C_PetBattles.GetActivePet(ALLY_OWNER)
    if not allyActivePet then
        return
    end

    local myPetType = C_PetBattles.GetPetType(ALLY_OWNER, allyActivePet)
    local relation = myPetType and VULNERABILITIES[myPetType]
    if not relation or not abilityType then
        return
    end

    if relation[1] == abilityType then
        button.hint:SetTexture("Interface\\PetBattles\\BattleBar-AbilityBadge-Strong")
        button.hint:Show()
    elseif relation[2] == abilityType then
        button.hint:SetTexture("Interface\\PetBattles\\BattleBar-AbilityBadge-Weak")
        button.hint:Show()
    end
end

local function ResolveCooldown(owner, petIndex, abilityIndex, stateCooldown, stateLockdown)
    local cd = tonumber(stateCooldown)
    local ld = tonumber(stateLockdown)
    if cd or ld then
        return math.max(cd or 0, ld or 0)
    end

    if C_PetBattles.GetAbilityCooldown then
        local remaining = C_PetBattles.GetAbilityCooldown(owner, petIndex, abilityIndex)
        return tonumber(remaining) or 0
    end

    return 0
end

function PetBattleUI:FillAbilityCooldown(button, owner, petIndex, abilityIndex)
    local isUsable, stateCooldown, stateLockdown = C_PetBattles.GetAbilityState(owner, petIndex, abilityIndex)
    local usable = isUsable and true or false
    local cooldown = ResolveCooldown(owner, petIndex, abilityIndex, stateCooldown, stateLockdown)

    button.cooldown:Hide()
    if usable and cooldown <= 0 then
        button.icon:SetDesaturated(false)
        button.icon:SetVertexColor(1, 1, 1)
        return
    end

    button.icon:SetDesaturated(true)
    button.icon:SetVertexColor(0.45, 0.45, 0.45)
    if cooldown > 0 then
        button.cooldown:SetText(cooldown)
        button.cooldown:Show()
    end
end

function PetBattleUI:GetEnemyAbilityCandidates(enemyPetIndex, abilityIndex)
    local candidates = {}
    local abilityID = C_PetBattles.GetAbilityInfo(ENEMY_OWNER, enemyPetIndex, abilityIndex)
    if abilityID then
        table.insert(candidates, abilityID)
        return candidates
    end

    local speciesID = C_PetBattles.GetPetSpeciesID(ENEMY_OWNER, enemyPetIndex)
    local level = C_PetBattles.GetLevel(ENEMY_OWNER, enemyPetIndex)
    if not speciesID or not level or not C_PetJournal or not C_PetJournal.GetPetAbilityList then
        return candidates
    end

    ClearArray(abilityListBuffer)
    ClearArray(abilityLevelBuffer)
    C_PetJournal.GetPetAbilityList(speciesID, abilityListBuffer, abilityLevelBuffer)

    for listOffset = 0, 3, 3 do
        local listIndex = abilityIndex + listOffset
        local candidateID = abilityListBuffer[listIndex]
        local candidateLevel = abilityLevelBuffer[listIndex]
        if candidateID and candidateLevel and candidateLevel <= level then
            table.insert(candidates, candidateID)
        end
    end

    return candidates
end

function PetBattleUI:UpdateEnemyAbilityFrame(snapshot)
    if not self.enemyAbilityFrame then
        return
    end

    local enemyActivePet = snapshot and snapshot.active and snapshot.active.enemyIndex
    if not enemyActivePet then
        self.enemyAbilityFrame:Hide()
        return
    end

    self.enemyAbilityFrame:Show()

    for abilityIndex = 1, PET_SLOTS do
        local topButton = self.enemyAbilityFrame.buttons[abilityIndex]
        local bottomButton = self.enemyAbilityFrame.buttons[abilityIndex + 3]
        local candidates = self:GetEnemyAbilityCandidates(enemyActivePet, abilityIndex)

        self:FillAbilityButton(topButton, candidates[1])

        if #candidates > 1 then
            self:SetAbilityButtonHalfHeight(topButton, true)
            topButton.cooldown:Hide()
            self:FillAbilityButton(bottomButton, candidates[2])
            bottomButton:Show()
        else
            self:SetAbilityButtonHalfHeight(topButton, false)
            self:FillAbilityCooldown(topButton, ENEMY_OWNER, enemyActivePet, abilityIndex)
            bottomButton:Hide()
        end
    end
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

            local familyLabel = pet.petTypeLabel or "Unknown"
            petFrame.name:SetText(string.format("%s [%s]", name, familyLabel))
            petFrame.health:SetText("Health: " .. FormatHealthText(pet.health, pet.maxHealth))

            if pet.level or pet.speed then
                petFrame.meta:SetText(string.format("Lvl %s | Speed %s", tostring(pet.level or "?"), tostring(pet.speed or "?")))
            else
                petFrame.meta:SetText("--")
            end

            for abilityIndex = 1, PET_SLOTS do
                local ability = pet.abilities and pet.abilities[abilityIndex]
                local icon = petFrame.abilityIcons[abilityIndex]
                icon:SetTexture((ability and ability.icon) or 134400)
                icon:SetDesaturated(not (ability and ability.name))
                icon:Show()
            end
        else
            petFrame:Show()
            petFrame.icon:SetTexture(134400)
            petFrame.name:SetText(string.format("%s Pet %d [Unknown]", frame == self.playerFrame and "Player" or "Enemy", i))
            petFrame.health:SetText("Health: --")
            petFrame.meta:SetText("--")

            for abilityIndex = 1, PET_SLOTS do
                local icon = petFrame.abilityIcons[abilityIndex]
                icon:SetTexture(134400)
                icon:SetDesaturated(true)
                icon:Show()
            end
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
    self:UpdateEnemyAbilityFrame(snapshot)
end

function PetBattleUI:ApplyVisibility()
    self:EnsureFrames()

    local shouldShow = Core and Core.IsPetBattleUIEnabled and Core:IsPetBattleUIEnabled() and Core.inPetBattle
    if shouldShow then
        self.playerFrame:Show()
        self.enemyFrame:Show()
        if self.enemyAbilityFrame then
            self.enemyAbilityFrame:Show()
        end
        self:Refresh()
    else
        self.playerFrame:Hide()
        self.enemyFrame:Hide()
        if self.enemyAbilityFrame then
            self.enemyAbilityFrame:Hide()
        end
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

    if self.enemyAbilityFrame then
        self.enemyAbilityFrame:Hide()
    end
end
