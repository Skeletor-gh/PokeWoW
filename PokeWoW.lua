local addonName, ns = ...

PokeWoW = PokeWoW or {}
local Core = PokeWoW
ns.Core = Core

Core.defaults = {
    music = {
        mode = "SEQUENTIAL", -- NO_MUSIC | SINGLE_LOOP | SEQUENTIAL | RANDOM
        singleTrack = 1,
        sequentialIndex = 1,
        enabled = true,
    },
}

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

    if type(PokeWoWDB.music) ~= "table" then
        PokeWoWDB.music = deepcopy(self.defaults.music)
    end

    for key, value in pairs(self.defaults.music) do
        if PokeWoWDB.music[key] == nil then
            PokeWoWDB.music[key] = deepcopy(value)
        end
    end

    self.db = PokeWoWDB
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

function Core:MuteDefaultPetBattleMusic(mute)
    for _, fileID in ipairs(self.defaultPetBattleMusicFileIDs) do
        if mute then
            MuteSoundFile(fileID)
        else
            UnmuteSoundFile(fileID)
        end
    end
end

function Core:ApplyNoMusicCVar()
    SetCVar("Sound_EnablePetBattleMusic", self.db.music.mode == "NO_MUSIC" and "0" or "1")
end

function Core:StopCustomMusic()
    if self.musicTimer then
        self.musicTimer:Cancel()
        self.musicTimer = nil
    end

    if self.currentSoundHandle then
        StopSound(self.currentSoundHandle)
        self.currentSoundHandle = nil
    end
end

function Core:PlayTrack(track)
    if not track or not track.path then
        return nil
    end

    local _, handle = PlaySoundFile(track.path, "Music")
    self.currentSoundHandle = handle
    return handle
end

function Core:ScheduleNextPlay(delay)
    if self.musicTimer then
        self.musicTimer:Cancel()
    end

    self.musicTimer = C_Timer.NewTimer(delay, function()
        self:PlayMusicCycle()
    end)
end

function Core:PlayMusicCycle()
    if not self.inPetBattle then
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
        index = math.max(1, math.min(self.db.music.sequentialIndex or 1, #tracks))
        self.db.music.sequentialIndex = (index % #tracks) + 1
    end

    local track, length = self:GetTrackByIndex(index)
    if not track then
        return
    end

    self:PlayTrack(track)
    self:ScheduleNextPlay(length)
end

function Core:OnPetBattleStart()
    self.inPetBattle = true
    self:MuteDefaultPetBattleMusic(true)
    self:ApplyNoMusicCVar()
    self:PlayMusicCycle()
end

function Core:OnPetBattleEnd()
    self.inPetBattle = false
    self:StopCustomMusic()
    self:MuteDefaultPetBattleMusic(false)
end

function Core:RefreshMusic()
    if not self.inPetBattle then
        self:ApplyNoMusicCVar()
        return
    end

    self:StopCustomMusic()
    self:ApplyNoMusicCVar()
    self:PlayMusicCycle()
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
        Core:ApplyNoMusicCVar()

        if ns.CreateOptionsPanels then
            ns.CreateOptionsPanels()
        end
    elseif event == "PET_BATTLE_OPENING_START" then
        Core:OnPetBattleStart()
    elseif event == "PET_BATTLE_CLOSE" then
        Core:OnPetBattleEnd()
    end
end)
