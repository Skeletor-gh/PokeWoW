local addonName, ns = ...
local Core = ns.Core

Core.defaults = Core.defaults or {}
Core.defaults.battleFrames = Core.defaults.battleFrames or {}
if Core.defaults.battleFrames.enabled == nil then
    Core.defaults.battleFrames.enabled = true
end
if Core.defaults.battleFrames.buttonScale == nil then
    Core.defaults.battleFrames.buttonScale = 1
end
if Core.defaults.battleFrames.layout == nil then
    Core.defaults.battleFrames.layout = "SIDES"
end
if Core.defaults.battleFrames.horizontalOffset == nil then
    Core.defaults.battleFrames.horizontalOffset = 0
end
if Core.defaults.battleFrames.verticalOffset == nil then
    Core.defaults.battleFrames.verticalOffset = 400
end
if Core.defaults.battleFrames.sideAbilityPadding == nil then
    Core.defaults.battleFrames.sideAbilityPadding = 2
end
if Core.defaults.battleFrames.sideGroupPadding == nil then
    Core.defaults.battleFrames.sideGroupPadding = 8
end
if Core.defaults.battleFrames.sideNameHorizontalOffset == nil then
    Core.defaults.battleFrames.sideNameHorizontalOffset = 0
end

local BATTLE_FRAME_LAYOUT = {
    OVERLAP = "OVERLAP",
    SIDES = "SIDES",
}

local function ClampButtonScale(scale)
    local numericScale = tonumber(scale) or 1
    return math.max(0.5, math.min(2, numericScale))
end

local function ClampSideAbilityPadding(padding)
    local numericPadding = tonumber(padding) or 2
    return math.max(-20, math.min(20, numericPadding))
end

local function ClampSideGroupPadding(padding)
    local numericPadding = tonumber(padding) or 8
    return math.max(0, math.min(40, numericPadding))
end

local function ClampFrameOffset(offset)
    local numericOffset = tonumber(offset) or 0
    return math.max(-400, math.min(400, numericOffset))
end

local function ClampSideNameHorizontalOffset(offset)
    local numericOffset = tonumber(offset) or 0
    return math.max(-50, math.min(50, numericOffset))
end

function Core:IsBattleFramesEnabled()
    return self:IsAddonEnabled() and self.db and self.db.battleFrames and self.db.battleFrames.enabled
end

function Core:SetBattleFramesEnabled(enabled)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    self.db.battleFrames.enabled = not not enabled
end

function Core:GetBattleFramesButtonScale()
    local scale = self.db and self.db.battleFrames and self.db.battleFrames.buttonScale
    return ClampButtonScale(scale)
end

function Core:SetBattleFramesButtonScale(scale)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    self.db.battleFrames.buttonScale = ClampButtonScale(scale)
    self:ApplyBattleFramesLayout()
end

function Core:GetBattleFramesLayoutMode()
    local mode = self.db and self.db.battleFrames and self.db.battleFrames.layout
    if mode == BATTLE_FRAME_LAYOUT.SIDES then
        return BATTLE_FRAME_LAYOUT.SIDES
    end
    return BATTLE_FRAME_LAYOUT.OVERLAP
end

function Core:SetBattleFramesLayoutMode(mode)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    if mode == BATTLE_FRAME_LAYOUT.SIDES then
        self.db.battleFrames.layout = BATTLE_FRAME_LAYOUT.SIDES
    else
        self.db.battleFrames.layout = BATTLE_FRAME_LAYOUT.OVERLAP
    end

    self:ApplyBattleFramesLayout()
end

function Core:GetBattleFramesHorizontalOffset()
    local offset = self.db and self.db.battleFrames and self.db.battleFrames.horizontalOffset
    return ClampFrameOffset(offset)
end

function Core:SetBattleFramesHorizontalOffset(offset)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    self.db.battleFrames.horizontalOffset = ClampFrameOffset(offset)
    self:ApplyBattleFramesLayout()
end

function Core:GetBattleFramesVerticalOffset()
    local offset = self.db and self.db.battleFrames and self.db.battleFrames.verticalOffset
    return ClampFrameOffset(offset)
end

function Core:SetBattleFramesVerticalOffset(offset)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    self.db.battleFrames.verticalOffset = ClampFrameOffset(offset)
    self:ApplyBattleFramesLayout()
end

function Core:GetBattleFramesSideAbilityPadding()
    local padding = self.db and self.db.battleFrames and self.db.battleFrames.sideAbilityPadding
    return ClampSideAbilityPadding(padding)
end

function Core:SetBattleFramesSideAbilityPadding(padding)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    self.db.battleFrames.sideAbilityPadding = ClampSideAbilityPadding(padding)
    self:ApplyBattleFramesLayout()
end

function Core:GetBattleFramesSideGroupPadding()
    local padding = self.db and self.db.battleFrames and self.db.battleFrames.sideGroupPadding
    return ClampSideGroupPadding(padding)
end

function Core:SetBattleFramesSideGroupPadding(padding)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    self.db.battleFrames.sideGroupPadding = ClampSideGroupPadding(padding)
    self:ApplyBattleFramesLayout()
end

function Core:GetBattleFramesSideNameHorizontalOffset()
    local offset = self.db and self.db.battleFrames and self.db.battleFrames.sideNameHorizontalOffset
    return ClampSideNameHorizontalOffset(offset)
end

function Core:SetBattleFramesSideNameHorizontalOffset(offset)
    if not self.db then
        return
    end

    self.db.battleFrames = self.db.battleFrames or {}
    self.db.battleFrames.sideNameHorizontalOffset = ClampSideNameHorizontalOffset(offset)
    self:ApplyBattleFramesLayout()
end

function Core:ApplyBattleFramesLayout()
    local frame = DeePetBattleFrame
    if not frame then
        return
    end

    local ally1, ally2, ally3 = frame.Ally1, frame.Ally2, frame.Ally3
    local enemy1, enemy2, enemy3 = frame.Enemy1, frame.Enemy2, frame.Enemy3
    if not ally1 or not ally2 or not ally3 or not enemy1 or not enemy2 or not enemy3 then
        return
    end

    local scale = self:GetBattleFramesButtonScale()
    local function ApplyGroupScale(group)
        if not group then
            return
        end

        local buttons = { group.Button1, group.Button2, group.Button3 }
        local sampleButton = buttons[1]
        if not sampleButton then
            return
        end

        local buttonWidth = sampleButton:GetWidth() > 0 and sampleButton:GetWidth() or 56
        local isSideLayout = self:GetBattleFramesLayoutMode() == BATTLE_FRAME_LAYOUT.SIDES
        local sidePadding = isSideLayout and self:GetBattleFramesSideAbilityPadding() or 2
        local baseSpacing = buttonWidth + sidePadding
        local scaledSpacing = baseSpacing * scale

        local centerOffset = 0
        if isSideLayout and scale > 1 then
            local defaultHalfSpan = buttonWidth + (buttonWidth / 2)
            local scaledHalfSpan = scaledSpacing + (buttonWidth * scale / 2)
            local overlapCompensation = math.max(0, scaledHalfSpan - defaultHalfSpan)
            local parentFrame = group:GetParent()

            if parentFrame and parentFrame.playerIndex == Enum.BattlePetOwner.Ally then
                centerOffset = overlapCompensation
            elseif parentFrame and parentFrame.playerIndex == Enum.BattlePetOwner.Enemy then
                centerOffset = -overlapCompensation
            end
        end

        for index, button in ipairs(buttons) do
            if button then
                button:SetScale(scale)
                button:ClearAllPoints()
                button:SetPoint("CENTER", group, "CENTER", (index - 2) * scaledSpacing + centerOffset, 0)
            end
        end
    end

    ApplyGroupScale(ally1.Abilities)
    ApplyGroupScale(ally2.Abilities)
    ApplyGroupScale(ally3.Abilities)
    ApplyGroupScale(enemy1.Abilities)
    ApplyGroupScale(enemy2.Abilities)
    ApplyGroupScale(enemy3.Abilities)

    ally1:ClearAllPoints()
    ally2:ClearAllPoints()
    ally3:ClearAllPoints()
    enemy1:ClearAllPoints()
    enemy2:ClearAllPoints()
    enemy3:ClearAllPoints()

    local horizontalOffset = self:GetBattleFramesHorizontalOffset()
    local verticalOffset = self:GetBattleFramesVerticalOffset()

    local isSideLayout = self:GetBattleFramesLayoutMode() == BATTLE_FRAME_LAYOUT.SIDES
    local sideNameHorizontalOffset = self:GetBattleFramesSideNameHorizontalOffset()
    local sideNameScaleAdjustment = math.floor(math.max(0, (scale - 1) * 10) + 0.5)

    local function UpdateSideNamePosition(petFrame)
        if not petFrame or not petFrame.SideName or not petFrame.Abilities then
            return
        end

        petFrame.SideName:ClearAllPoints()
        if petFrame.playerIndex == Enum.BattlePetOwner.Ally then
            petFrame.SideName:SetPoint("RIGHT", petFrame.Abilities, "LEFT", -10 + sideNameHorizontalOffset - sideNameScaleAdjustment, 0)
        else
            petFrame.SideName:SetPoint("LEFT", petFrame.Abilities, "RIGHT", 10 - sideNameHorizontalOffset + sideNameScaleAdjustment, 0)
        end
    end

    if isSideLayout then
        local groupPadding = self:GetBattleFramesSideGroupPadding()
        ally1:SetPoint("LEFT", UIParent, "LEFT", 250 + horizontalOffset, verticalOffset)
        ally2:SetPoint("TOP", ally1, "BOTTOM", 0, -groupPadding)
        ally3:SetPoint("TOP", ally2, "BOTTOM", 0, -groupPadding)

        enemy1:SetPoint("RIGHT", UIParent, "RIGHT", -250 - horizontalOffset, verticalOffset)
        enemy2:SetPoint("TOP", enemy1, "BOTTOM", 0, -groupPadding)
        enemy3:SetPoint("TOP", enemy2, "BOTTOM", 0, -groupPadding)
    else
        ally1:SetPoint("TOPLEFT", PetBattleFrame.ActiveAlly, "TOPRIGHT", 30 + horizontalOffset, 2 + verticalOffset)
        ally2:SetPoint("RIGHT", PetBattleFrame.Ally2, "LEFT", -7, 0)
        ally3:SetPoint("RIGHT", PetBattleFrame.Ally3, "LEFT", -7, 0)

        enemy1:SetPoint("TOPRIGHT", PetBattleFrame.ActiveEnemy, "TOPLEFT", -30 + horizontalOffset, 2 + verticalOffset)
        enemy2:SetPoint("LEFT", PetBattleFrame.Enemy2, "RIGHT", 7, 0)
        enemy3:SetPoint("LEFT", PetBattleFrame.Enemy3, "RIGHT", 7, 0)
    end

    local function UpdateSideName(petFrame)
        if not petFrame or not petFrame.SideName then
            return
        end

        UpdateSideNamePosition(petFrame)

        if isSideLayout and petFrame.SideName:GetText() and petFrame.SideName:GetText() ~= "" then
            petFrame.SideName:Show()
        else
            petFrame.SideName:Hide()
        end
    end

    UpdateSideName(ally1)
    UpdateSideName(ally2)
    UpdateSideName(ally3)
    UpdateSideName(enemy1)
    UpdateSideName(enemy2)
    UpdateSideName(enemy3)
end

local AURA_FRAME_DISTANCE = 4

local lastPlayerAbilityID

local teams

local idTable = {}
local levelTable = {}

local DeePetBattleFrame_EventHandlers = {}
local DeePetBattleAbilityButton_EventHandlers = {}
local DeePetBattlePet_EventHandlers = {}

local makeEventHandler, registerAllEvents
local getPetAbilities, populateTeams
local checkMatchingStats, getPlayerAbilityIndex, processPlayerAction
local updateAbilityButtonState, updateAbilityButtonAura, updateAbilityButtonBetterIcon, updateAbilityButtonIcons, updateAbilityButtonAbilityID
local updatePetIndex, updatePetAuras, handleAuraEvent, getPetAuras
local updateAbilityGroupPetIndex, updateAbilityGroupAuras
local getAuraFormattedDuration, setAuraFrameAura

do

    makeEventHandler = function(handlerTable)
        return function(self, event, ...)
            if Core and Core.IsBattleFramesEnabled and not Core:IsBattleFramesEnabled() then
                return
            end

            local handler = handlerTable[event]

            if (handler) then
                handler(self, ...)
            end
        end
    end

    registerAllEvents = function( self, handlerTable )
        for k, _ in pairs(handlerTable) do
            self:RegisterEvent(k)
        end
    end

    DeePetBattleFrame_OnEvent = makeEventHandler(DeePetBattleFrame_EventHandlers);
    DeePetBattleAbilityButton_OnEvent = makeEventHandler(DeePetBattleAbilityButton_EventHandlers);
    DeePetBattlePet_OnEvent = makeEventHandler(DeePetBattlePet_EventHandlers);
end

do

    getPetAbilities = function( playerIndex, petIndex, speciesID, level )
        local abilities = {}
        local foundInfo = false

        for abilityIndex=1, 3 do
            local id = C_PetBattles.GetAbilityInfo(playerIndex, petIndex, abilityIndex)

            if (id == nil) then
                abilities[abilityIndex] = {}
            else
                abilities[abilityIndex] = {id}
                foundInfo = true
            end
        end

        if (not foundInfo) then
            C_PetJournal.GetPetAbilityList(speciesID, idTable, levelTable)

            for abilityIndex, abilityLevel in ipairs(levelTable) do
                if (abilityLevel <= level) then
                     table.insert(
                        abilities[((abilityIndex-1)%3)+1],
                        idTable[abilityIndex]
                     )
                end
            end
        end

        return abilities
    end

    populateTeams = function()
        teams = {}

        for playerIndex=1, 2 do
            teams[playerIndex] = {}

            local numPets = C_PetBattles.GetNumPets(playerIndex)
            for petIndex=1, numPets do
                local speciesID = C_PetBattles.GetPetSpeciesID(playerIndex, petIndex)
                local level = C_PetBattles.GetLevel(playerIndex, petIndex)
                teams[playerIndex][petIndex] = getPetAbilities( playerIndex, petIndex, speciesID, level )
            end
        end
    end
end

do

    checkMatchingStats = function(playerIndex, hp, pow, spd)
        return  (hp == C_PetBattles.GetHealth(playerIndex, C_PetBattles.GetActivePet(playerIndex))) and
                (pow == C_PetBattles.GetPower(playerIndex, C_PetBattles.GetActivePet(playerIndex))) and
                (spd == C_PetBattles.GetSpeed(playerIndex, C_PetBattles.GetActivePet(playerIndex)))
    end

    getPlayerAbilityIndex = function( playerIndex, abilityID )
        if (not teams) then populateTeams() end

        for slot, slotList in ipairs( teams[playerIndex][C_PetBattles.GetActivePet(playerIndex)] ) do
            for _, id in ipairs(slotList) do
                if (id == abilityID) then return slot end
            end
        end
    end

    processPlayerAction = function( playerIndex, abilityIndex, abilityID )
        if (not teams) then populateTeams() end

        local petIndex = C_PetBattles.GetActivePet(playerIndex)

        local abilityGroup
        if (playerIndex == Enum.BattlePetOwner.Ally) then
            abilityGroup = DeePetBattleFrame.Ally1.Abilities
        else
            abilityGroup = DeePetBattleFrame.Enemy1.Abilities
        end

        local button = abilityGroup and abilityGroup["Button"..abilityIndex]
        if not button then
            return
        end

        button.SelectedHighlight:Show()

        if ( teams[playerIndex][petIndex][abilityIndex][2] ) then
            teams[playerIndex][petIndex][abilityIndex] = {abilityID}
            updateAbilityButtonAbilityID( button )
        end
    end

    DeePetBattleFrame_EventHandlers["PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE"] = function(self)
        if (C_PetBattles.IsSkipAvailable()) then
            lastPlayerAbilityID = nil
        end
    end

    DeePetBattleFrame_EventHandlers["PET_BATTLE_ACTION_SELECTED"] = function(self)

        local myActionType, myActionIndex = C_PetBattles.GetSelectedAction()
        if (myActionType == LE_BATTLE_PET_ACTION_ABILITY) then
            lastPlayerAbilityID = C_PetBattles.GetAbilityInfo(Enum.BattlePetOwner.Ally, C_PetBattles.GetActivePet(Enum.BattlePetOwner.Ally), myActionIndex)

        else
            lastPlayerAbilityID = nil
        end
    end

    DeePetBattleFrame_EventHandlers["CHAT_MSG_PET_BATTLE_COMBAT_LOG"] = function(self, message)
        for id, hp, pow, spd in message:gmatch("|HbattlePetAbil:(%d-):(%d-):(%d-):(%d-)|h") do

            id=id+0
            hp=hp+0
            pow=pow+0
            spd=spd+0

            local isMyAction = (id == lastPlayerAbilityID) and checkMatchingStats(Enum.BattlePetOwner.Ally, hp, pow, spd)
            if isMyAction then
                processPlayerAction(Enum.BattlePetOwner.Ally, getPlayerAbilityIndex(Enum.BattlePetOwner.Ally, id), id)
                return
            end

            local enemyAbilityIndex = getPlayerAbilityIndex(Enum.BattlePetOwner.Enemy, id)
            local isEnemyAction = enemyAbilityIndex and checkMatchingStats(Enum.BattlePetOwner.Enemy, hp, pow, spd)

            if isEnemyAction then
                processPlayerAction(Enum.BattlePetOwner.Enemy, enemyAbilityIndex, id)
                return
            end
        end
    end

    DeePetBattleFrame_OnShow = function(self)
        if Core and Core.IsBattleFramesEnabled and not Core:IsBattleFramesEnabled() then
            return
        end

        populateTeams()
        lastPlayerAbilityID = nil
        if Core and Core.ApplyBattleFramesLayout then
            Core:ApplyBattleFramesLayout()
        end
    end

    DeePetBattleFrame_EventHandlers["PET_BATTLE_CLOSE"] = function(self)
        teams = nil
        lastPlayerAbilityID = nil
    end

    DeePetBattleFrame_OnLoad = function(self)
        registerAllEvents(self, DeePetBattleFrame_EventHandlers)
        if Core and Core.ApplyBattleFramesLayout then
            Core:ApplyBattleFramesLayout()
        end
    end

end

do
    updateAbilityButtonState = function(self)

        local petFrame = self:GetParent():GetParent()
        local hp = C_PetBattles.GetHealth(petFrame.playerIndex, petFrame.petIndex)
        local _, currentCooldown, currentLockdown = C_PetBattles.GetAbilityState(petFrame.playerIndex, petFrame.petIndex, self.abilityIndex)
        local cooldown = max(currentCooldown or 0, currentLockdown or 0)

        if ( not self.abilityID ) then

            self.Icon:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon:SetDesaturated(true)
            self.Icon2:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon2:SetDesaturated(true)
            self:Disable()

            self.Lock:Show()
            self.CooldownShadow:Show()
            self.Cooldown:Hide()
            self.BetterIcon:Hide()

        elseif (hp <= 0) then

            self.Icon:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon:SetDesaturated(true)
            self.Icon2:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon2:SetDesaturated(true)
            self:Disable()

            self.Lock:Hide()
            self.CooldownShadow:Hide()
            self.Cooldown:Hide()

        elseif (cooldown > 0) then

            self.Icon:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon:SetDesaturated(true)
            self.Icon2:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon2:SetDesaturated(true)
            self:Disable()

            self.Lock:Hide()
            self.CooldownShadow:Show()
            self.Cooldown:SetText(cooldown)
            self.Cooldown:Show()

        else

            self.Icon:SetVertexColor(1, 1, 1)
            self.Icon:SetDesaturated(false)
            self.Icon2:SetVertexColor(1, 1, 1)
            self.Icon2:SetDesaturated(false)
            self:Enable()

            self.Lock:Hide()
            self.CooldownShadow:Hide()
            self.Cooldown:Hide()
            self.CooldownFlashAnim:Play()
        end
    end

    updateAbilityButtonAura = function( self )
        local auraInfo = self.auraInfo

        if (auraInfo == nil) then
            self.Duration:SetText("")
            self.AuraBorder:Hide()

        else
            if (auraInfo.duration < 0) then
                self.Duration:SetText("")
            else
                self.Duration:SetText(auraInfo.duration)
            end

            if (auraInfo.isBuff) then
                self.AuraBorder:SetVertexColor(0, .8, 0, 1)
            else
                self.AuraBorder:SetVertexColor(1, 0, 0, 1)
            end
            self.AuraBorder:Show()
        end
    end

    updateAbilityButtonBetterIcon = function(self)
        if Core and Core.IsBattleFramesEnabled and not Core:IsBattleFramesEnabled() then
            return
        end

        self.BetterIcon:Hide()
        self.BetterIcon2:Hide()

        local petFrame = self:GetParent():GetParent()
        local opposingTeam = Enum.BattlePetOwner.Ally + Enum.BattlePetOwner.Enemy - petFrame.playerIndex
        local opposingPetSlot = C_PetBattles.GetActivePet(opposingTeam)
        local opposingType = C_PetBattles.GetPetType(opposingTeam, opposingPetSlot)
        local abilityIds = { self.abilityID, self.abilityID2 }
        local icons = { self.BetterIcon, self.BetterIcon2 }

        for k, abilityID in ipairs(abilityIds) do
            if (not abilityID) then return end
            local icon = icons[k]

            local _, _, _, _, _, _, attackPetType, noStrongWeakHints = C_PetBattles.GetAbilityInfoByID(abilityID)
            if (not attackPetType) then return end

            local modifier = C_PetBattles.GetAttackModifier(attackPetType, opposingType)

            if (noStrongWeakHints or modifier == 1) then
                icon:Hide()
            elseif (modifier > 1) then
                icon:SetTexture("Interface\\PetBattles\\BattleBar-AbilityBadge-Strong")
                icon:Show()
            elseif (modifier < 1) then
                icon:SetTexture("Interface\\PetBattles\\BattleBar-AbilityBadge-Weak")
                icon:Show()
            end
        end
    end

    updateAbilityButtonIcons = function(self)

        if (not self.abilityID) then
            local petFrame = self:GetParent():GetParent()
            local speciesID = C_PetBattles.GetPetSpeciesID(petFrame.playerIndex, petFrame.petIndex)

            C_PetJournal.GetPetAbilityList(speciesID, idTable, levelTable)
            local abilityID = idTable[self.abilityIndex]

            if ( not abilityID ) then
                self.Icon:SetTexture("INTERFACE\\ICONS\\INV_Misc_Key_05")
                self:Hide()
            else
                local name, icon = C_PetJournal.GetPetAbilityInfo(abilityID)
                self.Icon:SetTexture(icon)
                self.Lock:Show()
                self:Show()
            end

            self.Icon:SetVertexColor(1, 1, 1)
            self:Disable()
            return
        end

        local id, name, icon = C_PetBattles.GetAbilityInfoByID(self.abilityID)
        if ( not icon ) then
    	    icon = "Interface\\Icons\\INV_Misc_QuestionMark"
        end

        self.Icon:SetTexture(icon)
        self.Lock:Hide()
        self:Enable()
        self:Show()

        if (self.abilityID2) then
           local id2, name2, icon2 = C_PetBattles.GetAbilityInfoByID(self.abilityID2)
            if ( not icon2 ) then
        	    icon2 = "Interface\\Icons\\INV_Misc_QuestionMark"
            end

            self.Icon2:SetTexture(icon2)
            self.Icon2:Show()
            self.topHalfBorder:Show()
            self.bottomHalfBorder:Show()
        else
            self.Icon2:Hide()
            self.topHalfBorder:Hide()
            self.bottomHalfBorder:Hide()
        end

        updateAbilityButtonBetterIcon(self)
    end

    updateAbilityButtonAbilityID = function(self)
        local petFrame = self:GetParent():GetParent()
        if (not (petFrame.playerIndex and petFrame.petIndex and self.abilityIndex)) then return end

        if (not teams) then populateTeams() end
        local petData = teams[petFrame.playerIndex][petFrame.petIndex]

        if (not petData) then return end
        local abilityList = petData[self.abilityIndex]

        self.abilityID = abilityList[1]
        self.abilityID2 = abilityList[2]

        updateAbilityButtonIcons(self)
        updateAbilityButtonState(self)
    end

    DeePetBattleAbilityButton_EventHandlers["PET_BATTLE_PET_CHANGED"] = updateAbilityButtonBetterIcon

    DeePetBattleAbilityButton_EventHandlers["PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE"] = function(self)
        self.SelectedHighlight:Hide()
        updateAbilityButtonBetterIcon(self)
        updateAbilityButtonState(self)
    end

    DeePetBattleAbilityButton_OnShow = updateAbilityButtonBetterIcon

    DeePetBattleAbilityButton_OnLoad = function(self)
        registerAllEvents(self, DeePetBattleAbilityButton_EventHandlers)
    end

    function DeePetBattleAbilityButton_OnEnter(self)
        local petFrame = self:GetParent():GetParent()

        if ( self.abilityID ) then
            local bonusString = getAuraFormattedDuration( self.auraInfo )
            PetBattleAbilityTooltip_SetAbilityByID(petFrame.playerIndex, petFrame.petIndex, self.abilityID, bonusString)

            if (petFrame.playerIndex == Enum.BattlePetOwner.Ally ) then
                PetBattleAbilityTooltip_Show("TOPLEFT", self, "BOTTOMRIGHT", 0, 0)
            else
                PetBattleAbilityTooltip_Show("TOPRIGHT", self, "BOTTOMLEFT", 0, 0)
            end
        else
            PetBattlePrimaryAbilityTooltip:Hide()
        end
    end

    function DeePetBattleAbilityButton_topHalf_OnEnter(self)
        local buttonFrame = self:GetParent()
        local petFrame = buttonFrame:GetParent():GetParent()

        if ( buttonFrame.abilityID2 ) then
            local bonusString = getAuraFormattedDuration( buttonFrame.auraInfo )
            PetBattleAbilityTooltip_SetAbilityByID(petFrame.playerIndex, petFrame.petIndex, buttonFrame.abilityID2, bonusString)

            if (petFrame.playerIndex == Enum.BattlePetOwner.Ally ) then
                PetBattleAbilityTooltip_Show("TOPLEFT", self, "BOTTOMRIGHT", 0, 0)
            else
                PetBattleAbilityTooltip_Show("TOPRIGHT", self, "BOTTOMLEFT", 0, 0)
            end
        else
            DeePetBattleAbilityButton_OnEnter(buttonFrame)
        end
    end

    function DeePetBattleAbilityButton_OnLeave(self)
        PetBattlePrimaryAbilityTooltip:Hide()
    end
end

do
    local function updatePetSideName(self)
        if not self or not self.SideName then
            return
        end

        local petName = ""
        if self.playerIndex and self.petIndex then
            petName = C_PetBattles.GetName(self.playerIndex, self.petIndex) or ""
        end

        self.SideName:SetText(petName)

        if Core and Core.ApplyBattleFramesLayout then
            Core:ApplyBattleFramesLayout()
        end
    end

    DeePetBattlePet_OnLoad = function( self, playerIndex, frameIndex )

        self.playerIndex = playerIndex
        self.frameIndex = frameIndex

        if (self.SideName == nil) then
            self.SideName = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.SideName:SetJustifyH("CENTER")

            self.SideName:Hide()
        end

        local groupFrame = self.Abilities
        if (self.Auras == nil) then
            groupFrame:SetScale(0.7)

            for _, button in pairs({groupFrame.Button1, groupFrame.Button2, groupFrame.Button3}) do
                button.Duration:SetPoint("TOP", button, "BOTTOM", 0, -10)
            end
        else
            self:SetWidth(99)
            groupFrame:SetScale(0.6)
            self.Auras:SetScale(0.7)

            local auraFrame = self.Auras.NextFrame

            self.auraWidth = auraFrame:GetWidth()
            self.totalAuraWidth = self.auraWidth
            self.growsFromDirection = auraFrame:GetPoint(1)

            if (self.growsFromDirection == "LEFT") then
                self.growsToDirection = "RIGHT"
            else
                self.growsToDirection = "LEFT"
            end
        end

        local _, anchorFrame = self:GetPoint(1)
        if (anchorFrame) then
            anchorFrame:HookScript("OnShow", function() self:Show() end)
            anchorFrame:HookScript("OnHide", function() self:Hide() end)
            if (not anchorFrame:IsShown()) then self:Hide() end
        end

        registerAllEvents(self, DeePetBattlePet_EventHandlers)
    end

    updatePetIndex = function( self )
        local activePetIndex = C_PetBattles.GetActivePet(self.playerIndex)
        if (not activePetIndex) then return end

        local frameIndex = self.frameIndex
        local petIndex

        if (frameIndex == 1) then
            petIndex = activePetIndex
        elseif (activePetIndex < frameIndex) then
            petIndex = frameIndex
        else
            petIndex = frameIndex-1
        end

        if (petIndex ~= self.petIndex) then
            self.petIndex = petIndex
            updateAbilityGroupPetIndex( self.Abilities )
            updatePetAuras( self )
        end

        updatePetSideName(self)
    end

    getPetAuras = function( playerIndex, petIndex )
        local numAuras = C_PetBattles.GetNumAuras(playerIndex, petIndex)

        if (numAuras == nil) or (C_PetBattles.GetHealth(playerIndex, petIndex) <= 0) then
            numAuras = 0
        end

        local auraTable = {}
        for auraIndex=1, numAuras do

            local id, instanceID, duration, isBuff, auraPlayerIndex, auraPetIndex =
                C_PetBattles.GetAuraInfo(playerIndex, petIndex, auraIndex)
            local _, name, icon = C_PetBattles.GetAbilityInfoByID(id)

            auraTable[auraIndex] = {
                id = id,
                name = name,
                icon = icon,
                duration = duration,
                isBuff = isBuff,
                playerIndex = auraPlayerIndex,
                petIndex = auraPetIndex,
            }
        end

        table.sort(auraTable,
            function(a,b)
               if (a.duration == b.duration) then
                    return (a.isBuff and not b.isBuff)
                else
                    return (b.duration < 0) or ((a.duration >= 0) and (a.duration < b.duration))
                end
            end
        )

        return auraTable
    end

    updatePetAuras = function( self )
        local auraTable = getPetAuras(self.playerIndex, self.petIndex)

        updateAbilityGroupAuras( self.Abilities, auraTable )

        local prevAuraFrame = self.Auras
        for _, auraInfo in ipairs(auraTable) do
            if (prevAuraFrame == nil) then return end

            if (not auraInfo.isButtonAura) then
                local auraFrame = prevAuraFrame.NextFrame

                if (auraFrame == nil) and (self.totalAuraWidth + AURA_FRAME_DISTANCE < self.Auras:GetWidth()) then
                    auraFrame = CreateFrame("frame", nil, self.Auras, "DeePetBattleAuraTemplate")
                    auraFrame:SetPoint(self.growsFromDirection, prevAuraFrame, self.growsToDirection)
                    self.totalAuraWidth = self.totalAuraWidth + AURA_FRAME_DISTANCE + self.auraWidth
                    prevAuraFrame.NextFrame = auraFrame
                end

                if (auraFrame ~= nil) then
                    setAuraFrameAura(auraFrame,auraInfo)
                end

                prevAuraFrame = auraFrame
            end
        end

        while (prevAuraFrame ~= nil) do
            local auraFrame = prevAuraFrame.NextFrame

            if (auraFrame ~= nil) then
                auraFrame:Hide()
            end

            prevAuraFrame = auraFrame
        end
    end

    DeePetBattlePet_OnShow = updatePetIndex

    DeePetBattlePet_EventHandlers["PET_BATTLE_CLOSE"] = function(self)
        self.petIndex = nil
        updatePetSideName(self)
    end

    DeePetBattlePet_EventHandlers["PET_BATTLE_PET_CHANGED"] = function(self, playerIndex)
        if (self.playerIndex == playerIndex) then
            updatePetIndex(self)
        end
    end

    handleAuraEvent = function(self, playerIndex, petIndex, instanceID)
        if ( playerIndex == self.playerIndex and petIndex == self.petIndex ) then
            updatePetAuras(self)
        end
    end

    DeePetBattlePet_EventHandlers["PET_BATTLE_AURA_APPLIED"] = handleAuraEvent
    DeePetBattlePet_EventHandlers["PET_BATTLE_AURA_CANCELED"] = handleAuraEvent
    DeePetBattlePet_EventHandlers["PET_BATTLE_AURA_CHANGED"] = handleAuraEvent

    DeePetBattlePet_EventHandlers["PET_BATTLE_HEALTH_CHANGED"] = function( self, playerIndex, petIndex, amount )
        if ( playerIndex == self.playerIndex and petIndex == self.petIndex ) then
            local hp = C_PetBattles.GetHealth(playerIndex, petIndex)
            if (amount < 0 and hp==0) or (amount > 0 and hp==amount) then
                updatePetAuras(self)
            end
        end
    end
end

do

    DeePetBattleAbilityGroup_OnLoad = function(self)
        for index, button in ipairs({self.Button1, self.Button2, self.Button3}) do
            button.abilityIndex = index
        end
    end

    updateAbilityGroupPetIndex = function( self )
        self.nameTable = {}

        for _, button in pairs({self.Button1, self.Button2, self.Button3}) do
            updateAbilityButtonAbilityID( button )

            for _, id in pairs({button.abilityID, button.abilityID2}) do
                if (id ~= nil) then
                    local _, name = C_PetBattles.GetAbilityInfoByID(id)
                    self.nameTable[name] = button
                end
            end
        end
    end

    updateAbilityGroupAuras = function( self, auraTable )
        local petFrame = self:GetParent()

        for _, button in pairs({self.Button1, self.Button2, self.Button3}) do
            button.auraInfo = nil
        end

        for _, auraInfo in ipairs(auraTable) do
            local button = self.nameTable[auraInfo.name]
            if
                (button ~= nil) and
                (auraInfo.playerIndex == petFrame.playerIndex) and
                (auraInfo.petIndex == petFrame.petIndex)
            then
                auraInfo.isButtonAura = true
                button.auraInfo = auraInfo
            end
        end

        for _, button in pairs({self.Button1, self.Button2, self.Button3}) do
            updateAbilityButtonAura( button )
        end
    end
end

do

    setAuraFrameAura = function( self, auraInfo )
        self.auraInfo = auraInfo

        if ( auraInfo.isBuff ) then
            self.DebuffBorder:Hide()
        else
            self.DebuffBorder:Show()
        end

        self.Icon:SetTexture(auraInfo.icon)

        if ( auraInfo.duration < 0 ) then
            self.Duration:SetText("")
        else
            self.Duration:SetText(auraInfo.duration)
        end

        self:Show()
    end

    getAuraFormattedDuration = function(auraInfo)
        if (auraInfo == nil) or (auraInfo.duration < 0) then
            return ""
        else
            local colorPrefix
            if (auraInfo.isBuff) then
                colorPrefix = "|cFF00DD00"
            else
                colorPrefix = "|cFFFF0000"
            end

            local roundsString
            if (auraInfo.duration == 1) then
                roundsString = " Round"
            else
                roundsString = " Rounds"
            end

            return colorPrefix .. auraInfo.duration .. roundsString .. " Remaining|h"
        end
    end

    function DeePetBattleAura_OnEnter(self)
        local petFrame = self:GetParent():GetParent()
        local auraInfo = self.auraInfo

        if ( auraInfo ) then
            local bonusString = getAuraFormattedDuration( auraInfo )
            PetBattleAbilityTooltip_SetAbilityByID(auraInfo.playerIndex, auraInfo.petIndex, auraInfo.id, bonusString)

            if (petFrame.playerIndex == Enum.BattlePetOwner.Ally ) then
                PetBattleAbilityTooltip_Show("TOPLEFT", self, "BOTTOMRIGHT", 0, 0)
            else
                PetBattleAbilityTooltip_Show("TOPRIGHT", self, "BOTTOMLEFT", 0, 0)
            end
        else
            PetBattlePrimaryAbilityTooltip:Hide()
        end
    end

    function DeePetBattleAura_OnLeave(self)
        PetBattlePrimaryAbilityTooltip:Hide()
    end
end
