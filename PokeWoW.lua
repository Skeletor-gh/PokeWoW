local addonName, ns = ...

PokeWoW = PokeWoW or {}
local Core = PokeWoW
ns.Core = Core

Core.defaults = {
    addonEnabled = true,
    customMusicEnabled = true,
    music = {
        mode = "SEQUENTIAL", -- NO_MUSIC | SINGLE_LOOP | SEQUENTIAL | RANDOM
        singleTrack = 1,
        sequentialIndex = 1,
        enabled = true,
    },
    battleFrames = {
        enabled = true,
        buttonScale = 1,
        layout = "OVERLAP",
        sideAbilityPadding = 2,
        sideGroupPadding = 7,
    },
}

Core.musicFadeDuration = 1.2
Core.musicFadeSteps = 8

Core.defaultPetBattleMusicFileIDs = {
    -- Populate this list with discovered default pet battle music file IDs.
    -- Example: 123456,
}

local function deepcopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end

    local out = {}
    for k, v in pairs(tbl) do
        out[k] = deepcopy(v)
    end
    return out
end

function Core:InitDB()
    PokeWoWDB = PokeWoWDB or {}

    if PokeWoWDB.addonEnabled == nil then
        PokeWoWDB.addonEnabled = self.defaults.addonEnabled
    end

    if PokeWoWDB.customMusicEnabled == nil then
        PokeWoWDB.customMusicEnabled = self.defaults.customMusicEnabled
    end

    if type(PokeWoWDB.music) ~= "table" then
        PokeWoWDB.music = deepcopy(self.defaults.music)
    end

    for key, value in pairs(self.defaults.music) do
        if PokeWoWDB.music[key] == nil then
            PokeWoWDB.music[key] = deepcopy(value)
        end
    end

    if type(PokeWoWDB.battleFrames) ~= "table" then
        PokeWoWDB.battleFrames = deepcopy(self.defaults.battleFrames)
    end

    for key, value in pairs(self.defaults.battleFrames) do
        if PokeWoWDB.battleFrames[key] == nil then
            PokeWoWDB.battleFrames[key] = deepcopy(value)
        end
    end

    self.db = PokeWoWDB
end

function Core:PrintStatus(message)
    local text = "|cFFFF8C00PokeWoW|r " .. message
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

function Core:IsAddonEnabled()
    return self.db and self.db.addonEnabled
end

function Core:IsCustomMusicEnabled()
    return self:IsAddonEnabled() and self.db and self.db.customMusicEnabled
end

function Core:GetTracks()
    return (ns.MusicTracks and ns.MusicTracks.list) or {}
end

function Core:GetTrackByIndex(index)
    local tracks = self:GetTracks()
    local track = tracks[index]
    if not track then
        return nil
    end

    local length = tonumber(track.length) or 120
    if length < 5 then
        length = 5
    end

    return track, length
end

function Core:GetSortedTrackIndices()
    local tracks = self:GetTracks()
    local indices = {}

    for index = 1, #tracks do
        indices[#indices + 1] = index
    end

    table.sort(indices, function(a, b)
        local trackA = tracks[a] or {}
        local trackB = tracks[b] or {}
        local keyA = string.lower(trackA.name or trackA.path or "")
        local keyB = string.lower(trackB.name or trackB.path or "")

        if keyA == keyB then
            return a < b
        end

        return keyA < keyB
    end)

    return indices
end

function Core:MuteDefaultPetBattleMusic(mute)
    for _, fileID in ipairs(self.defaultPetBattleMusicFileIDs) do
        if mute then
            MuteSoundFile(fileID)
        else
            UnmuteSoundFile(fileID)
        end
    end
end

function Core:EnsurePetBattleMusicCVarEnabled()
    if GetCVar("Sound_EnablePetBattleMusic") == "0" then
        SetCVar("Sound_EnablePetBattleMusic", "1")
    end
end

function Core:ApplyPetBattleMusicCVar()
    if not self:IsAddonEnabled() then
        return
    end

    if self:IsCustomMusicEnabled() and self.inPetBattle then
        SetCVar("Sound_EnablePetBattleMusic", "0")
        return
    end

    if self.db.music.mode == "NO_MUSIC" then
        SetCVar("Sound_EnablePetBattleMusic", "0")
    else
        SetCVar("Sound_EnablePetBattleMusic", "1")
    end
end

function Core:StopCustomMusic()
    if self.musicTimer then
        self.musicTimer:Cancel()
        self.musicTimer = nil
    end

    if self.musicFadeTicker then
        self.musicFadeTicker:Cancel()
        self.musicFadeTicker = nil
    end

    self.pendingTrack = nil

    if self.currentSoundHandle then
        StopSound(self.currentSoundHandle)
        self.currentSoundHandle = nil
    end

    if self.customMusicPlaying and StopMusic then
        StopMusic()
    end

    self.customMusicPlaying = false
    self:RestoreMusicVolume()
end

function Core:GetMusicVolume()
    if not GetCVar then
        return 1
    end

    local volume = tonumber(GetCVar("Sound_MusicVolume"))
    if not volume then
        return 1
    end

    return math.max(0, math.min(1, volume))
end

function Core:SetMusicVolume(volume)
    if not SetCVar then
        return
    end

    local clamped = math.max(0, math.min(1, tonumber(volume) or 1))
    SetCVar("Sound_MusicVolume", tostring(clamped))
end

function Core:CaptureMusicVolumeBaseline()
    if self.musicVolumeBaseline == nil then
        self.musicVolumeBaseline = self:GetMusicVolume()
    end
end

function Core:RestoreMusicVolume()
    if self.musicVolumeBaseline == nil then
        return
    end

    self:SetMusicVolume(self.musicVolumeBaseline)
    self.musicVolumeBaseline = nil
end

function Core:StartTrackPlayback(track, useFadeIn)
    if not track then
        return
    end

    self:CaptureMusicVolumeBaseline()

    if useFadeIn and self.musicVolumeBaseline and self.musicVolumeBaseline > 0 then
        self:SetMusicVolume(0)
    end

    self:PlayTrack(track)

    if not useFadeIn then
        return
    end

    self:FadeMusicVolume(0, self.musicVolumeBaseline or 1, self.musicFadeDuration)
end

function Core:FadeMusicVolume(fromVolume, toVolume, duration, onComplete)
    if self.musicFadeTicker then
        self.musicFadeTicker:Cancel()
        self.musicFadeTicker = nil
    end

    local steps = math.max(1, tonumber(self.musicFadeSteps) or 8)
    local tickInterval = math.max(0.05, (tonumber(duration) or 0) / steps)
    local fromValue = math.max(0, math.min(1, tonumber(fromVolume) or 1))
    local toValue = math.max(0, math.min(1, tonumber(toVolume) or 1))
    local currentStep = 0

    self:SetMusicVolume(fromValue)

    local ticker
    ticker = C_Timer.NewTicker(tickInterval, function()
        currentStep = currentStep + 1
        local progress = currentStep / steps
        local volume = fromValue + ((toValue - fromValue) * progress)
        self:SetMusicVolume(volume)

        if currentStep >= steps then
            if ticker then
                ticker:Cancel()
            end
            if self.musicFadeTicker == ticker then
                self.musicFadeTicker = nil
            end
            self:SetMusicVolume(toValue)

            if onComplete then
                onComplete()
            end
        end
    end)

    self.musicFadeTicker = ticker
end

function Core:IsZoneMusicPlaying()
    if IsMusicPlaying then
        return IsMusicPlaying()
    end

    return false
end

function Core:PauseZoneMusic()
    self.zoneMusicWasPlaying = self:IsZoneMusicPlaying()

    if self.zoneMusicWasPlaying and StopMusic then
        StopMusic()
    end
end

function Core:ResumeZoneMusicIfNeeded()
    if not self.zoneMusicWasPlaying then
        return
    end

    self.zoneMusicWasPlaying = false

    if RestartMusic then
        RestartMusic()
        return
    end

    -- Fallback for clients without RestartMusic.
    if GetCVar and SetCVar then
        local previous = GetCVar("Sound_EnableMusic")
        if previous == "1" then
            SetCVar("Sound_EnableMusic", "0")
            SetCVar("Sound_EnableMusic", "1")
        end
    end
end

function Core:PlayTrack(track)
    if not track or not track.path then
        return nil
    end

    if PlayMusic then
        PlayMusic(track.path)
        self.customMusicPlaying = true
        return true
    end

    local _, handle = PlaySoundFile(track.path, "Music")
    self.currentSoundHandle = handle
    self.customMusicPlaying = true
    return handle
end

function Core:ScheduleNextPlay(delay)
    if self.musicTimer then
        self.musicTimer:Cancel()
    end

    local safeDelay = math.max(0.1, (tonumber(delay) or 0) + 0.1)
    self.musicTimer = C_Timer.NewTimer(safeDelay, function()
        self:PlayMusicCycle()
    end)
end

function Core:PlayMusicCycle()
    if not self.inPetBattle or not self:IsCustomMusicEnabled() then
        return
    end

    local mode = self.db.music.mode
    local tracks = self:GetTracks()
    if #tracks == 0 then
        return
    end

    if mode == "NO_MUSIC" then
        self:StopCustomMusic()
        return
    end

    local index
    if mode == "SINGLE_LOOP" then
        index = math.max(1, math.min(self.db.music.singleTrack or 1, #tracks))
    elseif mode == "RANDOM" then
        index = math.random(1, #tracks)
    else
        local orderedIndices = self:GetSortedTrackIndices()
        local orderPosition = math.max(1, math.min(self.db.music.sequentialIndex or 1, #orderedIndices))
        index = orderedIndices[orderPosition]
        self.db.music.sequentialIndex = (orderPosition % #orderedIndices) + 1
    end

    local track, length = self:GetTrackByIndex(index)
    if not track then
        return
    end

    local shouldFadeTransition = (mode == "SEQUENTIAL" or mode == "RANDOM") and self.customMusicPlaying
    if shouldFadeTransition and self.musicVolumeBaseline and self.musicVolumeBaseline > 0 then
        self.pendingTrack = track
        self:FadeMusicVolume(self:GetMusicVolume(), 0, self.musicFadeDuration, function()
            if not self.inPetBattle or not self:IsCustomMusicEnabled() or not self.pendingTrack then
                return
            end

            local nextTrack = self.pendingTrack
            self.pendingTrack = nil
            self:StartTrackPlayback(nextTrack, true)
        end)
    else
        self:StartTrackPlayback(track, false)
    end

    self:ScheduleNextPlay(length)
end

function Core:OnPetBattleStart()
    if not self:IsAddonEnabled() then
        return
    end

    self.inPetBattle = true
    self:PauseZoneMusic()
    self:MuteDefaultPetBattleMusic(true)
    self:ApplyPetBattleMusicCVar()

    if self:IsCustomMusicEnabled() then
        C_Timer.After(0.2, function()
            if self.inPetBattle and self:IsCustomMusicEnabled() then
                self:PlayMusicCycle()
            end
        end)
    end
end

function Core:OnPetBattleEnd()
    self.inPetBattle = false
    self:StopCustomMusic()
    self:ResumeZoneMusicIfNeeded()
    self:MuteDefaultPetBattleMusic(false)
    self:ApplyPetBattleMusicCVar()
end

function Core:RefreshMusic()
    if not self.inPetBattle then
        self:ApplyPetBattleMusicCVar()
        return
    end

    self:StopCustomMusic()
    self:ApplyPetBattleMusicCVar()
    self:PlayMusicCycle()
end

function Core:SetAddonEnabled(enabled)
    self.db.addonEnabled = enabled and true or false
    if not self.db.addonEnabled then
        self.inPetBattle = false
        self:StopCustomMusic()
        self:ResumeZoneMusicIfNeeded()
        self:MuteDefaultPetBattleMusic(false)
    end
    self:ApplyPetBattleMusicCVar()
end

function Core:SetCustomMusicEnabled(enabled)
    self.db.customMusicEnabled = enabled and true or false

    if self.db.customMusicEnabled then
        self:EnsurePetBattleMusicCVarEnabled()
    else
        self:StopCustomMusic()
    end

    self:ApplyPetBattleMusicCVar()

    if self.inPetBattle and self:IsCustomMusicEnabled() then
        self:PlayMusicCycle()
    end
end

function Core:GetVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"
    end

    if GetAddOnMetadata then
        return GetAddOnMetadata(addonName, "Version") or "0.0.0"
    end

    return "0.0.0"
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PET_BATTLE_OPENING_START")
events:RegisterEvent("PET_BATTLE_CLOSE")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Core:InitDB()
        Core:ApplyPetBattleMusicCVar()

        if ns.CreateOptionsPanels then
            ns.CreateOptionsPanels()
        end
    elseif event == "PET_BATTLE_OPENING_START" then
        Core:OnPetBattleStart()
    elseif event == "PET_BATTLE_CLOSE" then
        Core:OnPetBattleEnd()
    end
end)
