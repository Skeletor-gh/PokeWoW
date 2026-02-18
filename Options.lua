local addonName, ns = ...
local Core = ns.Core

local function PlayCheckboxSound(checked)
    if checked then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end
end

local function SetControlEnabled(control, enabled)
    if control.SetEnabled then
        control:SetEnabled(enabled)
    end

    if control.Text then
        local r, g, b = 1, 1, 1
        if not enabled then
            r, g, b = 0.5, 0.5, 0.5
        end
        control.Text:SetTextColor(r, g, b)
    end
end

local function SetPanelEnabled(panel, enabled)
    panel:SetAlpha(enabled and 1 or 0.45)
    panel:EnableMouse(enabled)
    panel:EnableMouseWheel(enabled)

    if not panel.controls then
        return
    end

    for _, control in ipairs(panel.controls) do
        SetControlEnabled(control, enabled)
    end
end

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
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category
        if parentCategory and Settings.RegisterCanvasLayoutSubcategory then
            category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, title)
        else
            category = Settings.RegisterCanvasLayoutCategory(panel, title)
        end

        category.ID = title

        Settings.RegisterAddOnCategory(category)
        return category
    end

    panel.name = title
    panel.parent = type(parentCategory) == "table" and parentCategory.name or parentCategory
    InterfaceOptions_AddCategory(panel)
    return panel
end

local function BuildWelcomePanel(parentCategory)
    local panel = CreateFrame("Frame")
    panel:Hide()
    panel.controls = {}

    CreateTitle(panel, "PokeWoW")
    CreateBody(panel, "Welcome to PokeWoW, your UX and QoL toolbox for Pet Battles.\n\nLatest patch notes:\n- Initial addon scaffolding.\n- Added options with feature sub-panels.\n- Added custom Pet Battle music replacer and playlist support.")

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetTexture("Interface\\AddOns\\PokeWoW\\Assets\\pokewow.png")
    bg:SetAlpha(0.3)

    local addonEnabledCheckbox = CreateFrame("CheckButton", addonName .. "AddonEnabledCheckbox", panel, "UICheckButtonTemplate")
    addonEnabledCheckbox:SetPoint("TOPLEFT", 16, -120)
    addonEnabledCheckbox.Text:SetText("Enable PokeWoW")
    addonEnabledCheckbox:SetChecked(Core:IsAddonEnabled())

    local customMusicCheckbox = CreateFrame("CheckButton", addonName .. "CustomMusicEnabledCheckbox", panel, "UICheckButtonTemplate")
    customMusicCheckbox:SetPoint("TOPLEFT", 16, -155)
    customMusicCheckbox.Text:SetText("Enable Custom Pet Battle Music")
    customMusicCheckbox:SetChecked(Core.db.customMusicEnabled)

    local petBattleUICheckbox = CreateFrame("CheckButton", addonName .. "PetBattleUIEnabledCheckbox", panel, "UICheckButtonTemplate")
    petBattleUICheckbox:SetPoint("TOPLEFT", 16, -190)
    petBattleUICheckbox.Text:SetText("Enable Pet Battle Party Frames")
    petBattleUICheckbox:SetChecked(Core.db.petBattleUIEnabled)

    panel.controls = { addonEnabledCheckbox, customMusicCheckbox, petBattleUICheckbox }

    addonEnabledCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlayCheckboxSound(checked)
        Core:SetAddonEnabled(checked)
        Core:PrintStatus("Addon " .. (checked and "enabled." or "disabled."))

        SetControlEnabled(customMusicCheckbox, checked)
        ns.RefreshOptionsState()
    end)

    customMusicCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlayCheckboxSound(checked)
        Core:SetCustomMusicEnabled(checked)
        Core:PrintStatus("Custom pet battle music " .. (checked and "enabled." or "disabled."))
        ns.RefreshOptionsState()
    end)

    petBattleUICheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlayCheckboxSound(checked)
        Core:SetPetBattleUIEnabled(checked)
        Core:PrintStatus("Pet battle UI " .. (checked and "enabled." or "disabled."))
        ns.RefreshOptionsState()
    end)

    CreateFooter(panel)
    local category = AddCategory(panel, "PokeWoW", parentCategory)
    ns.rootPanel = panel
    return category
end

local function BuildMusicPanel(parentCategory)
    local panel = CreateFrame("Frame")
    panel:Hide()
    panel.controls = {}

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

    panel.controls = { modeDropdown, trackDropdown }

    CreateFooter(panel)
    local category = AddCategory(panel, "Pet Battle Music", parentCategory)
    ns.musicPanel = panel
    return category
end

local function BuildPetBattleUIPanel(parentCategory)
    local panel = CreateFrame("Frame")
    panel:Hide()
    panel.controls = {}

    CreateTitle(panel, "Pet Battle UI")
    CreateBody(panel, "This section will contain options for the custom Pet Battle party frames.\n\nMore settings are coming in future updates.")
    CreateFooter(panel)

    local category = AddCategory(panel, "Pet Battle UI", parentCategory)
    ns.petBattleUIPanel = panel
    return category
end

function ns.RefreshOptionsState()
    if not Core or not Core.db then
        return
    end

    local addonEnabled = Core:IsAddonEnabled()
    local customMusicEnabled = Core.db.customMusicEnabled

    if ns.rootPanel and ns.rootPanel.controls and ns.rootPanel.controls[2] then
        SetControlEnabled(ns.rootPanel.controls[2], addonEnabled)
    end

    if ns.rootPanel and ns.rootPanel.controls and ns.rootPanel.controls[3] then
        SetControlEnabled(ns.rootPanel.controls[3], addonEnabled)
    end

    if ns.musicPanel then
        SetPanelEnabled(ns.musicPanel, addonEnabled and customMusicEnabled)
    end

    if ns.petBattleUIPanel then
        SetPanelEnabled(ns.petBattleUIPanel, addonEnabled)
    end
end

function ns.CreateOptionsPanels()
    if ns.optionsBuilt then
        return
    end

    local root = BuildWelcomePanel()
    BuildMusicPanel(root)
    BuildPetBattleUIPanel(root)
    ns.RefreshOptionsState()
    ns.optionsBuilt = true
end
