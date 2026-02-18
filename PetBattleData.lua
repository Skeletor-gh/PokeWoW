local _, ns = ...

local PetBattleData = {}
ns.PetBattleData = PetBattleData

local function ResolveOwnerToken(...)
    for index = 1, select("#", ...) do
        local candidate = select(index, ...)
        if type(candidate) == "number" then
            return candidate
        end
    end

    return nil
end

local OWNER_MAP = {
    -- Client builds differ in where these constants are exposed.
    -- Fall back to the documented numeric owner IDs used by C_PetBattles.
    player = ResolveOwnerToken(
        LE_BATTLE_PET_ALLY,
        _G and _G.LE_BATTLE_PET_ALLY,
        Enum and Enum.BattlePetOwner and Enum.BattlePetOwner.Ally,
        1
    ),
    enemy = ResolveOwnerToken(
        LE_BATTLE_PET_ENEMY,
        _G and _G.LE_BATTLE_PET_ENEMY,
        Enum and Enum.BattlePetOwner and Enum.BattlePetOwner.Enemy,
        2
    ),
}

local PET_SLOTS = 3

local PET_TYPE_LABELS = {
    [1] = "Humanoid",
    [2] = "Dragonkin",
    [3] = "Flying",
    [4] = "Undead",
    [5] = "Critter",
    [6] = "Magic",
    [7] = "Elemental",
    [8] = "Beast",
    [9] = "Aquatic",
    [10] = "Mechanical",
}

local function Bool(value)
    return value and true or false
end

local function NumberOrNil(value)
    local numberValue = tonumber(value)
    if numberValue == nil then
        return nil
    end

    return numberValue
end

local function GetPetTypeLabel(petType)
    if petType == nil then
        return nil
    end

    return _G["BATTLE_PET_NAME_" .. petType] or PET_TYPE_LABELS[petType] or tostring(petType)
end

local function BuildAbility(owner, petIndex, abilityIndex)
    local abilityID, abilityName, abilityIcon, _, _, _, abilityType = C_PetBattles.GetAbilityInfo(owner, petIndex, abilityIndex)
    local usable, disabled = C_PetBattles.GetAbilityState(owner, petIndex, abilityIndex)
    local cooldownRemaining, cooldownMax = C_PetBattles.GetAbilityCooldown(owner, petIndex, abilityIndex)

    abilityID = NumberOrNil(abilityID)
    if abilityID and C_PetBattles.GetAbilityInfoByID then
        local infoName, infoIcon, _, infoType = C_PetBattles.GetAbilityInfoByID(abilityID)
        abilityName = abilityName or infoName
        abilityIcon = abilityIcon or infoIcon
        abilityType = abilityType or infoType
    end

    return {
        index = abilityIndex,
        id = abilityID,
        name = abilityName,
        icon = abilityIcon,
        petType = NumberOrNil(abilityType),
        familyLabel = GetPetTypeLabel(NumberOrNil(abilityType)),
        typeLabel = GetPetTypeLabel(NumberOrNil(abilityType)),
        usable = Bool(usable),
        disabled = Bool(disabled),
        cooldownRemaining = NumberOrNil(cooldownRemaining) or 0,
        cooldownMax = NumberOrNil(cooldownMax) or 0,
    }
end

local function PetExists(owner, petIndex)
    if NumberOrNil(C_PetBattles.GetPetSpeciesID(owner, petIndex)) then
        return true
    end

    if C_PetBattles.GetName(owner, petIndex) then
        return true
    end

    if C_PetBattles.GetIcon(owner, petIndex) then
        return true
    end

    return false
end

local function BuildPet(owner, petIndex, isActive)
    local petType = NumberOrNil(C_PetBattles.GetPetType(owner, petIndex))
    local health = NumberOrNil(C_PetBattles.GetHealth(owner, petIndex))
    local maxHealth = NumberOrNil(C_PetBattles.GetMaxHealth(owner, petIndex))
    local level = NumberOrNil(C_PetBattles.GetLevel(owner, petIndex))
    local speed = NumberOrNil(C_PetBattles.GetSpeed(owner, petIndex))
    local speciesID = NumberOrNil(C_PetBattles.GetPetSpeciesID(owner, petIndex))

    local pet = {
        index = petIndex,
        exists = PetExists(owner, petIndex),
        isActive = Bool(isActive),
        name = C_PetBattles.GetName(owner, petIndex),
        species = speciesID,
        speciesID = speciesID,
        icon = C_PetBattles.GetIcon(owner, petIndex),
        health = health,
        maxHealth = maxHealth,
        healthPercent = (health and maxHealth and maxHealth > 0) and (health / maxHealth) or nil,
        speed = speed,
        level = level,
        petType = petType,
        petTypeLabel = GetPetTypeLabel(petType),
        abilities = {},
    }

    for abilityIndex = 1, (NUM_BATTLE_PET_ABILITIES or 3) do
        pet.abilities[abilityIndex] = BuildAbility(owner, petIndex, abilityIndex)
    end

    return pet
end

local function BuildTeamSnapshot(owner)
    local activePetIndex = C_PetBattles.GetActivePet(owner)
    local totalSlots = NumberOrNil(C_PetBattles.GetNumPets(owner)) or PET_SLOTS
    if totalSlots < PET_SLOTS then
        totalSlots = PET_SLOTS
    end

    local team = {
        owner = owner,
        activePetIndex = NumberOrNil(activePetIndex),
        pets = {},
    }

    for petIndex = 1, totalSlots do
        team.pets[petIndex] = BuildPet(owner, petIndex, petIndex == activePetIndex)
    end

    return team
end

function PetBattleData.BuildBattleSnapshot()
    if not C_PetBattles or not C_PetBattles.IsInBattle or not C_PetBattles.IsInBattle() then
        return {
            player = { pets = {} },
            enemy = { pets = {} },
            active = {},
        }
    end

    local player = BuildTeamSnapshot(OWNER_MAP.player)
    local enemy = BuildTeamSnapshot(OWNER_MAP.enemy)

    return {
        player = player,
        enemy = enemy,
        active = {
            playerIndex = player.activePetIndex,
            enemyIndex = enemy.activePetIndex,
            player = player.pets[player.activePetIndex],
            enemy = enemy.pets[enemy.activePetIndex],
        },
    }
end

ns.BuildBattleSnapshot = function()
    return PetBattleData.BuildBattleSnapshot()
end

BuildBattleSnapshot = ns.BuildBattleSnapshot
