local addonName, ns = ...
local Core = ns.Core

local function CreateTitle(parent, text)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(text)
    return title
end

local function CreateBody(parent, text)
    local body = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 16, -52)
    body:SetPoint("RIGHT", -16, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetText(text)
    return body
end

local function CreateFooter(parent)
    local author = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    author:SetPoint("BOTTOMLEFT", 16, 16)
    author:SetText("Author: skeletor-gh")

    local version = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    version:SetPoint("BOTTOMRIGHT", -16, 16)
    version:SetText("Version: " .. (Core and Core:GetVersion() or "0.0.0"))
end

local function AddCategory(panel, title, parentCategory)
    panel.name = title
    panel.parent = parentCategory
    InterfaceOptions_AddCategory(panel)
    return panel
end

local function BuildWelcomePanel()
    local panel = CreateFrame("Frame")
    panel:Hide()

    CreateTitle(panel, "PokeWoW")
    CreateBody(panel, "Welcome to PokeWoW, your UX and QoL toolbox for Pet Battles.\n\nLatest patch notes:\n- Initial addon scaffolding.\n- Added options with feature sub-panels.\n- Added custom Pet Battle music replacer and playlist support.")

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetTexture("Interface\\AddOns\\PokeWoW\\assets\\images\\welcome-bg")
    bg:SetVertexColor(1, 1, 1, 0.08)

    CreateFooter(panel)
    return AddCategory(panel, "PokeWoW")
end

local function BuildMusicPanel(parentName)
    local panel = CreateFrame("Frame")
    panel:Hide()

    CreateTitle(panel, "Pet Battle Music Replacer")
    CreateBody(panel, "Replace default Pet Battle music using your custom track list from MusicTracks.lua.")

    local modeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", 16, -120)
    modeLabel:SetText("Playback Mode")

    local modeDropdown = CreateFrame("Frame", addonName .. "ModeDropdown", panel, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", 0, -135)

    local trackLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trackLabel:SetPoint("TOPLEFT", 16, -190)
    trackLabel:SetText("Single Track")

    local trackDropdown = CreateFrame("Frame", addonName .. "TrackDropdown", panel, "UIDropDownMenuTemplate")
    trackDropdown:SetPoint("TOPLEFT", 0, -205)

    local modeItems = {
        { text = "No Music", value = "NO_MUSIC" },
        { text = "Single Track (Loop)", value = "SINGLE_LOOP" },
        { text = "Sequential Playback", value = "SEQUENTIAL" },
        { text = "Random", value = "RANDOM" },
    }

    local function GetModeText(value)
        for _, item in ipairs(modeItems) do
            if item.value == value then
                return item.text
            end
        end
        return modeItems[1].text
    end

    local function RefreshTrackDropdown()
        UIDropDownMenu_Initialize(trackDropdown, function(self, _, _)
            local tracks = Core:GetTracks()
            for index, track in ipairs(tracks) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = track.name or ("Track " .. index)
                info.value = index
                info.checked = (Core.db.music.singleTrack == index)
                info.func = function()
                    Core.db.music.singleTrack = index
                    UIDropDownMenu_SetSelectedValue(trackDropdown, index)
                    UIDropDownMenu_SetText(trackDropdown, info.text)
                    Core:RefreshMusic()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        local selected = Core.db.music.singleTrack or 1
        local track = Core:GetTracks()[selected]
        UIDropDownMenu_SetSelectedValue(trackDropdown, selected)
        UIDropDownMenu_SetText(trackDropdown, track and track.name or "No tracks configured")
    end

    UIDropDownMenu_Initialize(modeDropdown, function(self, _, _)
        for _, item in ipairs(modeItems) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.value = item.value
            info.checked = (Core.db.music.mode == item.value)
            info.func = function()
                Core.db.music.mode = item.value
                UIDropDownMenu_SetSelectedValue(modeDropdown, item.value)
                UIDropDownMenu_SetText(modeDropdown, item.text)
                Core:RefreshMusic()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetWidth(modeDropdown, 220)
    UIDropDownMenu_SetSelectedValue(modeDropdown, Core.db.music.mode)
    UIDropDownMenu_SetText(modeDropdown, GetModeText(Core.db.music.mode))

    UIDropDownMenu_SetWidth(trackDropdown, 260)
    RefreshTrackDropdown()

    CreateFooter(panel)
    return AddCategory(panel, "Pet Battle Music", parentName)
end

function ns.CreateOptionsPanels()
    if ns.optionsBuilt then
        return
    end

    local root = BuildWelcomePanel()
    BuildMusicPanel(root.name)
    ns.optionsBuilt = true
end
