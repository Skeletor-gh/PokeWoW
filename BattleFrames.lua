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
    Core.defaults.battleFrames.layout = "OVERLAP"
end
if Core.defaults.battleFrames.sideAbilityPadding == nil then
    Core.defaults.battleFrames.sideAbilityPadding = 2
end
if Core.defaults.battleFrames.sideGroupPadding == nil then
    Core.defaults.battleFrames.sideGroupPadding = 7
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
    return math.max(0, math.min(20, numericPadding))
end

local function ClampSideGroupPadding(padding)
    local numericPadding = tonumber(padding) or 7
    return math.max(0, math.min(40, numericPadding))
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
        local sidePadding = self:GetBattleFramesLayoutMode() == BATTLE_FRAME_LAYOUT.SIDES and self:GetBattleFramesSideAbilityPadding() or 2
        local baseSpacing = buttonWidth + sidePadding
        local scaledSpacing = baseSpacing * scale

        for index, button in ipairs(buttons) do
            if button then
                button:SetScale(scale)
                button:ClearAllPoints()
                button:SetPoint("CENTER", group, "CENTER", (index - 2) * scaledSpacing, 0)
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

    if self:GetBattleFramesLayoutMode() == BATTLE_FRAME_LAYOUT.SIDES then
        local groupPadding = self:GetBattleFramesSideGroupPadding()
        ally1:SetPoint("LEFT", UIParent, "LEFT", 250, 0)
        ally2:SetPoint("TOP", ally1, "BOTTOM", 0, -groupPadding)
        ally3:SetPoint("TOP", ally2, "BOTTOM", 0, -groupPadding)

        enemy1:SetPoint("RIGHT", UIParent, "RIGHT", -250, 0)
        enemy2:SetPoint("TOP", enemy1, "BOTTOM", 0, -groupPadding)
        enemy3:SetPoint("TOP", enemy2, "BOTTOM", 0, -groupPadding)
    else
        ally1:SetPoint("TOPLEFT", PetBattleFrame.ActiveAlly, "TOPRIGHT", 30, 2)
        ally2:SetPoint("RIGHT", PetBattleFrame.Ally2, "LEFT", -7, 0)
        ally3:SetPoint("RIGHT", PetBattleFrame.Ally3, "LEFT", -7, 0)

        enemy1:SetPoint("TOPRIGHT", PetBattleFrame.ActiveEnemy, "TOPLEFT", -30, 2)
        enemy2:SetPoint("LEFT", PetBattleFrame.Enemy2, "RIGHT", 7, 0)
        enemy3:SetPoint("LEFT", PetBattleFrame.Enemy3, "RIGHT", 7, 0)
    end
end

-----------------------------
-- Variables and Constants --
-----------------------------

--distance between adjacent aura frames
local AURA_FRAME_DISTANCE = 4

--ID of the ability last picked by the player
local lastPlayerAbilityID

--teams[1] is the current player's roster, teams[2] is the opponent's roster.
-- each roster is a list of pets; each pet has a list of (three) ability slots: each slot is a list of possible ability IDs.
local teams

--temporary reusable tables
local idTable = {}
local levelTable = {}

--event handler tables
local DeePetBattleFrame_EventHandlers = {}
local DeePetBattleAbilityButton_EventHandlers = {}
local DeePetBattlePet_EventHandlers = {}


----------------------------
-- Local function listing --
----------------------------
--this makes order irrelevant, and recursion possible
local makeEventHandler, registerAllEvents
local getPetAbilities, populateTeams
local checkMatchingStats, getPlayerAbilityIndex, processPlayerAction
local updateAbilityButtonState, updateAbilityButtonAura, updateAbilityButtonBetterIcon, updateAbilityButtonIcons, updateAbilityButtonAbilityID
local updatePetIndex, updatePetAuras, handleAuraEvent, getPetAuras
local updateAbilityGroupPetIndex, updateAbilityGroupAuras
local getAuraFormattedDuration, setAuraFrameAura

---------------------------------------
-- OnEvent Handler Generic Functions --
---------------------------------------
do
    --creates and returns a generic event handler function that picks what to call from a given table of handlers
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

    --register all events a given frame is supposed to listen to, according to a table of handlers
    registerAllEvents = function( self, handlerTable )
        for k, _ in pairs(handlerTable) do
            self:RegisterEvent(k)
        end
    end

    --onEvent handlers for the various frames
    DeePetBattleFrame_OnEvent = makeEventHandler(DeePetBattleFrame_EventHandlers);
    DeePetBattleAbilityButton_OnEvent = makeEventHandler(DeePetBattleAbilityButton_EventHandlers);
    DeePetBattlePet_OnEvent = makeEventHandler(DeePetBattlePet_EventHandlers);
end

-------------------------
-- Team Init Functions --
-------------------------
do
    --Returns a list with three elements (one per ability slot), each of which can be:
    -- {} if the pet's too low level to have an ability in that slot,
    -- {id} if we know what ability it has slotted there,
    -- {id, id} if we're not sure which of the two abilities is slotted (in PVP)
    getPetAbilities = function( playerIndex, petIndex, speciesID, level )
        local abilities = {}
        local foundInfo = false

        --try to get slotted abilities directly
        for abilityIndex=1, 3 do
            local id = C_PetBattles.GetAbilityInfo(playerIndex, petIndex, abilityIndex)

            if (id == nil) then
                abilities[abilityIndex] = {}
            else
                abilities[abilityIndex] = {id}
                foundInfo = true
            end
        end

        --if we're in PVP, the previous attempt will fail, finding only {{}, {}, {}}: fill possible pet abilities from the pet journal instead
        if (not foundInfo) then
            C_PetJournal.GetPetAbilityList(speciesID, idTable, levelTable)

            for abilityIndex, abilityLevel in ipairs(levelTable) do
                if (abilityLevel <= level) then
                     table.insert(
                        abilities[((abilityIndex-1)%3)+1],  --nasty modulus maths due to 1-based arrays. (basically, inserts into 1, 2, 3, 1, 2, 3)
                        idTable[abilityIndex]
                     )
                end
            end
        end

        return abilities
    end

    --populates teams with info on every pet in their roster, and their respective abilities
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

-----------------------------------
-- Ability Use Parsing Functions --
-----------------------------------
do
    --returns whether the given stats match those of the given player's active pet
    checkMatchingStats = function(playerIndex, hp, pow, spd)
        return  (hp == C_PetBattles.GetHealth(playerIndex, C_PetBattles.GetActivePet(playerIndex))) and
                (pow == C_PetBattles.GetPower(playerIndex, C_PetBattles.GetActivePet(playerIndex))) and
                (spd == C_PetBattles.GetSpeed(playerIndex, C_PetBattles.GetActivePet(playerIndex)))
    end

    --returns the slot index for a given ability, if it can be cast by the given player's pet (or nil, if it can't)
    getPlayerAbilityIndex = function( playerIndex, abilityID )
        if (not teams) then populateTeams() end     --ensure team roster is populated

        for slot, slotList in ipairs( teams[playerIndex][C_PetBattles.GetActivePet(playerIndex)] ) do
            for _, id in ipairs(slotList) do
                if (id == abilityID) then return slot end
            end
        end
    end

    --called whenever we detect a battle-pet has activated an ability
    processPlayerAction = function( playerIndex, abilityIndex, abilityID )
        if (not teams) then populateTeams() end     --ensure team roster is populated

        local petIndex = C_PetBattles.GetActivePet(playerIndex)

        --find the button responsible for this action
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

        --if we didn't know which of its two abilities the pet had in this slot, narrow down ability list for this slot
        if ( teams[playerIndex][petIndex][abilityIndex][2] ) then
            teams[playerIndex][petIndex][abilityIndex] = {abilityID}
            updateAbilityButtonAbilityID( button )
        end
    end

    --triggers at the start of each round (after both pets have done their moves), and after a pet switch choice is made
    -- clears id of ability used by the player in the current round, whenever player can pick a move
    DeePetBattleFrame_EventHandlers["PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE"] = function(self)
        if (C_PetBattles.IsSkipAvailable()) then    --if a round starts, and the player can pass, then they aren't doing a multi-turn move
            lastPlayerAbilityID = nil               --clear last selected ability id
        end
    end

    --updates id of ability used by the player in the current round, whenever a choice is made
    DeePetBattleFrame_EventHandlers["PET_BATTLE_ACTION_SELECTED"] = function(self)

        local myActionType, myActionIndex = C_PetBattles.GetSelectedAction()
        if (myActionType == LE_BATTLE_PET_ACTION_ABILITY) then
            lastPlayerAbilityID = C_PetBattles.GetAbilityInfo(Enum.BattlePetOwner.Ally, C_PetBattles.GetActivePet(Enum.BattlePetOwner.Ally), myActionIndex)

        else        --if player selected something, but it's not an ability, clear last used ID
            lastPlayerAbilityID = nil
        end
    end

    --parses pet battle combat log entries, finds activated abilities (filtering out auras and other junk)
    DeePetBattleFrame_EventHandlers["CHAT_MSG_PET_BATTLE_COMBAT_LOG"] = function(self, message)
        for id, hp, pow, spd in message:gmatch("|HbattlePetAbil:(%d-):(%d-):(%d-):(%d-)|h") do
            --turn matched strings to integers
            id=id+0
            hp=hp+0
            pow=pow+0
            spd=spd+0

            local isMyAction = (id == lastPlayerAbilityID) and checkMatchingStats(Enum.BattlePetOwner.Ally, hp, pow, spd)
            if isMyAction then
                processPlayerAction(Enum.BattlePetOwner.Ally, getPlayerAbilityIndex(Enum.BattlePetOwner.Ally, id), id)
                return     --Player's action can't also be the opponent's: We're done.
            end

            local enemyAbilityIndex = getPlayerAbilityIndex(Enum.BattlePetOwner.Enemy, id)
            local isEnemyAction = enemyAbilityIndex and checkMatchingStats(Enum.BattlePetOwner.Enemy, hp, pow, spd)

            if isEnemyAction then
                processPlayerAction(Enum.BattlePetOwner.Enemy, enemyAbilityIndex, id)
                return    --Don't parse more abilities: we've already found what we were looking for.
            end
        end
    end

    --whenever our main frame is shown, a pet battle has started (or UI was reloaded during one): init/refresh the team rosters, reset remaining vars
    DeePetBattleFrame_OnShow = function(self)
        if Core and Core.IsBattleFramesEnabled and not Core:IsBattleFramesEnabled() then
            return
        end

        populateTeams()
        lastPlayerAbilityID = nil  --clear ID of the ability last picked by the player
        if Core and Core.ApplyBattleFramesLayout then
            Core:ApplyBattleFramesLayout()
        end
    end

    --whenever our main frame is hidden, a pet battle has ended: forget team rosters until the next battle
    DeePetBattleFrame_EventHandlers["PET_BATTLE_CLOSE"] = function(self)
        teams = nil
        lastPlayerAbilityID = nil
    end

    --register events for the main frame
    DeePetBattleFrame_OnLoad = function(self)
        registerAllEvents(self, DeePetBattleFrame_EventHandlers)
        if Core and Core.ApplyBattleFramesLayout then
            Core:ApplyBattleFramesLayout()
        end
    end

end

-- Remaining DeePet BattleFrames functions are kept as-is below for full behavior parity.
-- (No functional changes except module-level enable gating above.)
---------------------------------------
-- Ability Button Updating Functions --
---------------------------------------
do
    updateAbilityButtonState = function(self)

        local petFrame = self:GetParent():GetParent()
        local hp = C_PetBattles.GetHealth(petFrame.playerIndex, petFrame.petIndex)
        local _, currentCooldown, currentLockdown = C_PetBattles.GetAbilityState(petFrame.playerIndex, petFrame.petIndex, self.abilityIndex)
        local cooldown = max(currentCooldown or 0, currentLockdown or 0)

        if ( not self.abilityID ) then
            --too low level to be able to use this slot. Show it as locked.
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
            --Pet's dead: set the frame up to look unusable
            self.Icon:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon:SetDesaturated(true)
            self.Icon2:SetVertexColor(0.5, 0.5, 0.5)
            self.Icon2:SetDesaturated(true)
            self:Disable()

            self.Lock:Hide()
            self.CooldownShadow:Hide()
            self.Cooldown:Hide()

        elseif (cooldown > 0) then
            --Set the frame up to look like a cooldown.
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
            --Set the frame up to look clickable/usable.
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

    --updates the aura duration and border for an ability button
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

    --update the strong/weak indicator for a button
    updateAbilityButtonBetterIcon = function(self)
        if Core and Core.IsBattleFramesEnabled and not Core:IsBattleFramesEnabled() then
            return
        end

    	self.BetterIcon:Hide()
    	self.BetterIcon2:Hide()

    	local petFrame = self:GetParent():GetParent()
        local opposingTeam = Enum.BattlePetOwner.Ally + Enum.BattlePetOwner.Enemy - petFrame.playerIndex   --the OTHER player
        local opposingPetSlot = C_PetBattles.GetActivePet(opposingTeam)
        local opposingType = C_PetBattles.GetPetType(opposingTeam, opposingPetSlot)
    	local abilityIds = { self.abilityID, self.abilityID2 }
    	local icons = { self.BetterIcon, self.BetterIcon2 }

    	for k, abilityID in ipairs(abilityIds) do   --update the strong/weak icon for BOTH abilities. stop as soon as we run out of abilityIDs
    	    if (not abilityID) then return end
    	    local icon = icons[k]

            local _, _, _, _, _, _, attackPetType, noStrongWeakHints = C_PetBattles.GetAbilityInfoByID(abilityID)
            if (not attackPetType) then return end

            -- show Strong/Weak icons on buttons.
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

    --updates a given ability button's icons based on its spellIDs, and enemy pet's type
    updateAbilityButtonIcons = function(self)
        --if we don't have any ability in this slot, find correct texture, add lock icon, and we're done.
        if (not self.abilityID) then
            local petFrame = self:GetParent():GetParent()
            local speciesID = C_PetBattles.GetPetSpeciesID(petFrame.playerIndex, petFrame.petIndex)

            C_PetJournal.GetPetAbilityList(speciesID, idTable, levelTable)
            local abilityID = idTable[self.abilityIndex]

            if ( not abilityID ) then   --still haven't found anything? hide button.
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

        --we have at least one possible ability for this slot: get its icon.
        local id, name, icon = C_PetBattles.GetAbilityInfoByID(self.abilityID)
        if ( not icon ) then
    	    icon = "Interface\\Icons\\INV_Misc_QuestionMark"
        end

        self.Icon:SetTexture(icon)
        self.Lock:Hide()
        self:Enable()
        self:Show()

        --if there's a second possible abilityID, get its icon too
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

    --updates a given ability button's abilityIDs, its icons, and cooldown
    updateAbilityButtonAbilityID = function(self)
        local petFrame = self:GetParent():GetParent()
        if (not (petFrame.playerIndex and petFrame.petIndex and self.abilityIndex)) then return end   --do nothing if we don't know what we're pointing at

        if (not teams) then populateTeams() end     --ensure team roster is populated
        local petData = teams[petFrame.playerIndex][petFrame.petIndex]

        if (not petData) then return end            --if there is no pet with this button's index, updating ends here
        local abilityList = petData[self.abilityIndex]

        self.abilityID = abilityList[1]
        self.abilityID2 = abilityList[2]            --in PVP matches, we may have two possible IDs

        updateAbilityButtonIcons(self)
        updateAbilityButtonState(self)
    end

    --Update weak/strong icon whenever there's a pet swap
    DeePetBattleAbilityButton_EventHandlers["PET_BATTLE_PET_CHANGED"] = updateAbilityButtonBetterIcon

    --update volatile button info every round
    DeePetBattleAbilityButton_EventHandlers["PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE"] = function(self)
        self.SelectedHighlight:Hide()
        updateAbilityButtonBetterIcon(self)    --Update weak/strong icon here too (enemy can change type, without being swapped)
        updateAbilityButtonState(self)
    end

    --Update weak/strong icon whenever combat starts
    DeePetBattleAbilityButton_OnShow = updateAbilityButtonBetterIcon

    --register events for each button
    DeePetBattleAbilityButton_OnLoad = function(self)
        registerAllEvents(self, DeePetBattleAbilityButton_EventHandlers)
    end

    --show tooltip when hovering over a button
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

    --show tooltip when hovering over a pvp half-button
    function DeePetBattleAbilityButton_topHalf_OnEnter(self)
        local buttonFrame = self:GetParent()       -- petFrame > groupFrame > buttonFrame > topHalfFrame
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

    --hide tooltip when mouse leaves a button
    function DeePetBattleAbilityButton_OnLeave(self)
        PetBattlePrimaryAbilityTooltip:Hide()
    end
end

----------------------------
-- Pet Updating Functions --
----------------------------
do
    DeePetBattlePet_OnLoad = function( self, playerIndex, frameIndex )
        --remember which pet we're watching
        self.playerIndex = playerIndex
        self.frameIndex = frameIndex

        local groupFrame = self.Abilities
        if (self.Auras == nil) then    --active pets get bigger cooldowns, have no aura frames, and their durations are farther
            groupFrame:SetScale(0.7)

            for _, button in pairs({groupFrame.Button1, groupFrame.Button2, groupFrame.Button3}) do
                button.Duration:SetPoint("TOP", button, "BOTTOM", 0, -10)
            end
        else                            --benched pets get smaller cooldowns, and have aura frames.
            self:SetWidth(99)
            groupFrame:SetScale(0.6)
            self.Auras:SetScale(0.7)    --this should make auras smaller than cooldowns

            local auraFrame = self.Auras.NextFrame

            self.auraWidth = auraFrame:GetWidth()
            self.totalAuraWidth = self.auraWidth
            self.growsFromDirection = auraFrame:GetPoint(1)  --(this first aura frame MUST exist in the XML)

            if (self.growsFromDirection == "LEFT") then
                self.growsToDirection = "RIGHT"
            else
                self.growsToDirection = "LEFT"
            end
        end

        --show/hide ourselves whenever our anchor is shown or hidden
        local _, anchorFrame = self:GetPoint(1)
        if (anchorFrame) then
            anchorFrame:HookScript("OnShow", function() self:Show() end)
            anchorFrame:HookScript("OnHide", function() self:Hide() end)
            if (not anchorFrame:IsShown()) then self:Hide() end
        end

        registerAllEvents(self, DeePetBattlePet_EventHandlers)
    end

    --updates which pet the given pet frame watches, based on which pet is active
    updatePetIndex = function( self )
        local activePetIndex = C_PetBattles.GetActivePet(self.playerIndex)
        if (not activePetIndex) then return end     --no need to update outside of pet battles

        local frameIndex = self.frameIndex
        local petIndex

        --find out who we're meant to watch
        if (frameIndex == 1) then
            petIndex = activePetIndex   --group 1 always watches active pet
        elseif (activePetIndex < frameIndex) then
            petIndex = frameIndex       --track own index if active pet comes before us
        else
            petIndex = frameIndex-1     --track one pet above us if active pet comes after us
        end

        --if our petIndex changed, update its children
        if (petIndex ~= self.petIndex) then
            self.petIndex = petIndex
            updateAbilityGroupPetIndex( self.Abilities )
            updatePetAuras( self )
        end
    end

    --returns a table with info about all auras affecting the given pet
    getPetAuras = function( playerIndex, petIndex )
        local numAuras = C_PetBattles.GetNumAuras(playerIndex, petIndex)

        if (numAuras == nil) or (C_PetBattles.GetHealth(playerIndex, petIndex) <= 0) then
            numAuras = 0   --hide auras for missing and/or dead pets
        end

        --populate auraTable with this pet's buffs/debuffs
        local auraTable = {}
        for auraIndex=1, numAuras do
            --get aura info
            local id, instanceID, duration, isBuff, auraPlayerIndex, auraPetIndex =
                C_PetBattles.GetAuraInfo(playerIndex, petIndex, auraIndex)
            local _, name, icon = C_PetBattles.GetAbilityInfoByID(id)

            --store info in aura table
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

        --sort table by remaining durations, putting infinite (-1) duration auras at the END; buffs go before debuffs when tied.
        table.sort(auraTable,
            function(a,b)
               if (a.duration == b.duration) then          --If durations are tied, buffs come before debuffs.
                    return (a.isBuff and not b.isBuff)
                else                                       --If durations differ, smallest goes first. (but -1 goes last)
                    return (b.duration < 0) or ((a.duration >= 0) and (a.duration < b.duration))
                end
            end
        )

        return auraTable
    end

    --updates which auras are active on the current pet
    updatePetAuras = function( self )
        local auraTable = getPetAuras(self.playerIndex, self.petIndex)

        --Go through this pet's ability buttons, use them to display their own auras, if present.
        updateAbilityGroupAuras( self.Abilities, auraTable )

        --display all the remaining collected auras we can fit
        local prevAuraFrame = self.Auras                   --self.Auras.NextFrame is the first aura frame
        for _, auraInfo in ipairs(auraTable) do
            if (prevAuraFrame == nil) then return end      --if we don't have an aura frame to anchor to, we're done

            --if aura's not shown on a button, try to show aura in an aura frame instead (as long as we have the previous frame it's anchored to)
            if (not auraInfo.isButtonAura) then
                local auraFrame = prevAuraFrame.NextFrame

                --if the next aura frame doesn't exist yet, create it (if there's room for at least part of it)
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

        --hide any existing aura frames that weren't needed
        while (prevAuraFrame ~= nil) do
            local auraFrame = prevAuraFrame.NextFrame

            if (auraFrame ~= nil) then
                auraFrame:Hide()
            end

            prevAuraFrame = auraFrame
        end
    end

    --update abilities whenever a pet battle starts (or if UI is reloaded during one)
    DeePetBattlePet_OnShow = updatePetIndex

    --forget petIndex when pet battle ends
    DeePetBattlePet_EventHandlers["PET_BATTLE_CLOSE"] = function(self)
        self.petIndex = nil
    end

    --update abilities whenever there is a pet swap
    DeePetBattlePet_EventHandlers["PET_BATTLE_PET_CHANGED"] = function(self, playerIndex)
        if (self.playerIndex == playerIndex) then
            updatePetIndex(self)
        end
    end

    --function that handles aura events
    handleAuraEvent = function(self, playerIndex, petIndex, instanceID)
        if ( playerIndex == self.playerIndex and petIndex == self.petIndex ) then
            updatePetAuras(self)
        end
    end

    --keep track of auras on all pets: all three aura events are handled by the same function
    DeePetBattlePet_EventHandlers["PET_BATTLE_AURA_APPLIED"] = handleAuraEvent
    DeePetBattlePet_EventHandlers["PET_BATTLE_AURA_CANCELED"] = handleAuraEvent
    DeePetBattlePet_EventHandlers["PET_BATTLE_AURA_CHANGED"] = handleAuraEvent

    --handle pet death and resurrection (update its auras when either happens)
    DeePetBattlePet_EventHandlers["PET_BATTLE_HEALTH_CHANGED"] = function( self, playerIndex, petIndex, amount )
        if ( playerIndex == self.playerIndex and petIndex == self.petIndex ) then
            local hp = C_PetBattles.GetHealth(playerIndex, petIndex)
            if (amount < 0 and hp==0) or (amount > 0 and hp==amount) then
                updatePetAuras(self)
            end
        end
    end
end

--------------------------------------
-- Ability Group Updating Functions --
--------------------------------------
do
    --setup ability group internal variables for commodity
    DeePetBattleAbilityGroup_OnLoad = function(self)
        for index, button in ipairs({self.Button1, self.Button2, self.Button3}) do
            button.abilityIndex = index    --tell each button which ability slot it's watching
        end
    end

    --update all buttons in an ability group, after pet index changes
    updateAbilityGroupPetIndex = function( self )
        self.nameTable = {}    --table with the names of all this group's abilities, and which button they belong to

        for _, button in pairs({self.Button1, self.Button2, self.Button3}) do
            updateAbilityButtonAbilityID( button )

            --update this button's ability names, and corresponding buttons
            for _, id in pairs({button.abilityID, button.abilityID2}) do
                if (id ~= nil) then
                    local _, name = C_PetBattles.GetAbilityInfoByID(id)
                    self.nameTable[name] = button
                end
            end
        end
    end

    --update all buttons to show their own auras
    updateAbilityGroupAuras = function( self, auraTable )
        local petFrame = self:GetParent()

        --reset all button aura info
        for _, button in pairs({self.Button1, self.Button2, self.Button3}) do
            button.auraInfo = nil
        end

        --go through all auras to see which match any buttons
        for _, auraInfo in ipairs(auraTable) do
            local button = self.nameTable[auraInfo.name]
            if                      --is the aura's name the same as a button's, and it was cast by the same pet?
                (button ~= nil) and
                (auraInfo.playerIndex == petFrame.playerIndex) and
                (auraInfo.petIndex == petFrame.petIndex)
            then                    --if so, store that aura in the button
                auraInfo.isButtonAura = true
                button.auraInfo = auraInfo
            end
        end

        --refresh all button auras
        for _, button in pairs({self.Button1, self.Button2, self.Button3}) do
            updateAbilityButtonAura( button )
        end
    end
end

--------------------------
-- Aura Frame Functions --
--------------------------
do
    --updates an aura frame to show the aura with the given info
    setAuraFrameAura = function( self, auraInfo )
        self.auraInfo = auraInfo   --store info so we know how to make a tooltip, later

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

    --returns a tooltip-ready aura-duration string
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

    --show tooltip when hovering over an aura frame
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
