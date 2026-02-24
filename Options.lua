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

    if control.Low then
        local r, g, b = 1, 1, 1
        if not enabled then
            r, g, b = 0.5, 0.5, 0.5
        end
        control.Low:SetTextColor(r, g, b)
    end

    if control.High then
        local r, g, b = 1, 1, 1
        if not enabled then
            r, g, b = 0.5, 0.5, 0.5
        end
        control.High:SetTextColor(r, g, b)
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
    CreateBody(panel, "Welcome to PokeWoW, your UX and QoL toolbox for Pet Battles.")

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

    local battleFramesCheckbox = CreateFrame("CheckButton", addonName .. "BattleFramesEnabledCheckbox", panel, "UICheckButtonTemplate")
    battleFramesCheckbox:SetPoint("TOPLEFT", 16, -190)
    battleFramesCheckbox.Text:SetText("Enable BattleFrames")
    battleFramesCheckbox:SetChecked(Core.db.battleFrames and Core.db.battleFrames.enabled)

    local patchNotesLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    patchNotesLabel:SetPoint("TOPLEFT", battleFramesCheckbox, "BOTTOMLEFT", 0, -20)
    patchNotesLabel:SetText("Latest patch notes")

    local patchNotesBody = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    patchNotesBody:SetPoint("TOPLEFT", patchNotesLabel, "BOTTOMLEFT", 0, -8)
    patchNotesBody:SetPoint("RIGHT", -16, 0)
    patchNotesBody:SetJustifyH("LEFT")
    patchNotesBody:SetJustifyV("TOP")
    patchNotesBody:SetText("- v0.2.1: Removed music fade transitions for tighter, full-length playback.\n- v0.2.1: Improved playback timer handling to better respect configured track lengths.\n- Added options with feature sub-panels.\n- Added BattleFrames UI to showcase pet abilities.")

    panel.controls = { addonEnabledCheckbox, customMusicCheckbox, battleFramesCheckbox }

    addonEnabledCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlayCheckboxSound(checked)
        Core:SetAddonEnabled(checked)
        Core:PrintStatus("Addon " .. (checked and "enabled." or "disabled."))

        SetControlEnabled(customMusicCheckbox, checked)
        SetControlEnabled(battleFramesCheckbox, checked)
        ns.RefreshOptionsState()
    end)

    customMusicCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlayCheckboxSound(checked)
        Core:SetCustomMusicEnabled(checked)
        Core:PrintStatus("Custom pet battle music " .. (checked and "enabled." or "disabled."))
        ns.RefreshOptionsState()
    end)

    battleFramesCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlayCheckboxSound(checked)
        Core:SetBattleFramesEnabled(checked)
        Core:PrintStatus("BattleFrames " .. (checked and "enabled." or "disabled."))
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

    local function RefreshTrackDropdownEnabledState()
        local isSingleLoop = (Core.db.music.mode == "SINGLE_LOOP")
        UIDropDownMenu_EnableDropDown(trackDropdown)

        if not isSingleLoop then
            UIDropDownMenu_DisableDropDown(trackDropdown)
        end
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
                RefreshTrackDropdownEnabledState()
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
    RefreshTrackDropdownEnabledState()

    panel.controls = { modeDropdown, trackDropdown }

    CreateFooter(panel)
    local category = AddCategory(panel, "Pet Battle Music", parentCategory)
    ns.musicPanel = panel
    return category
end

local function BuildBattleFramesPanel(parentCategory)
    local panel = CreateFrame("Frame")
    panel:Hide()
    panel.controls = {}

    local scrollFrame = CreateFrame("ScrollFrame", addonName .. "BattleFramesOptionsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 28)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 720)
    scrollFrame:SetScrollChild(scrollChild)

    panel:SetScript("OnSizeChanged", function(self, width)
        scrollChild:SetWidth(math.max(1, width - 44))
    end)

    local content = scrollChild

    CreateTitle(content, "BattleFrames")
    CreateBody(content, "Customized Pet Battle UI")

    local scaleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 16, -120)
    scaleLabel:SetText("Button Scale")

    local scaleSlider = CreateFrame("Slider", addonName .. "BattleFramesScaleSlider", content, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 20, -145)
    scaleSlider:SetWidth(260)
    scaleSlider:SetMinMaxValues(0.5, 2)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider.Low:SetText("0.5")
    scaleSlider.High:SetText("2.0")

    local scaleValueText = scaleSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    scaleValueText:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -4)

    local function RefreshScaleText()
        scaleValueText:SetText(string.format("Current: %.2f", Core:GetBattleFramesButtonScale()))
    end

    scaleSlider:SetValue(Core:GetBattleFramesButtonScale())
    RefreshScaleText()

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        local snapped = math.floor((value + 0.025) / 0.05) * 0.05
        Core:SetBattleFramesButtonScale(snapped)
        RefreshScaleText()
    end)

    local positioningLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    positioningLabel:SetPoint("TOPLEFT", 16, -220)
    positioningLabel:SetText("Positioning")

    local positioningDropdown = CreateFrame("Frame", addonName .. "BattleFramesPositioningDropdown", content, "UIDropDownMenuTemplate")
    positioningDropdown:SetPoint("TOPLEFT", 0, -235)

    local horizontalOffsetLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    horizontalOffsetLabel:SetPoint("TOPLEFT", 16, -300)
    horizontalOffsetLabel:SetText("Side Mode: Team Center Spacing")

    local horizontalOffsetSlider = CreateFrame("Slider", addonName .. "BattleFramesHorizontalOffsetSlider", content, "OptionsSliderTemplate")
    horizontalOffsetSlider:SetPoint("TOPLEFT", 20, -325)
    horizontalOffsetSlider:SetWidth(220)
    horizontalOffsetSlider:SetMinMaxValues(-400, 400)
    horizontalOffsetSlider:SetValueStep(1)
    horizontalOffsetSlider:SetObeyStepOnDrag(true)
    horizontalOffsetSlider.Low:SetText("-400")
    horizontalOffsetSlider.High:SetText("400")

    local horizontalOffsetValueText = horizontalOffsetSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    horizontalOffsetValueText:SetPoint("TOP", horizontalOffsetSlider, "BOTTOM", 0, -4)

    local function RefreshHorizontalOffsetText()
        horizontalOffsetValueText:SetText(string.format("Current: %d", Core:GetBattleFramesHorizontalOffset()))
    end

    horizontalOffsetSlider:SetValue(Core:GetBattleFramesHorizontalOffset())
    RefreshHorizontalOffsetText()

    horizontalOffsetSlider:SetScript("OnValueChanged", function(self, value)
        local snapped = math.floor(value + 0.5)
        Core:SetBattleFramesHorizontalOffset(snapped)
        RefreshHorizontalOffsetText()
    end)

    local verticalOffsetLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    verticalOffsetLabel:SetPoint("TOPLEFT", 296, -300)
    verticalOffsetLabel:SetText("Position Offset: Vertical")

    local verticalOffsetSlider = CreateFrame("Slider", addonName .. "BattleFramesVerticalOffsetSlider", content, "OptionsSliderTemplate")
    verticalOffsetSlider:SetPoint("TOPLEFT", 300, -325)
    verticalOffsetSlider:SetWidth(220)
    verticalOffsetSlider:SetMinMaxValues(-400, 400)
    verticalOffsetSlider:SetValueStep(1)
    verticalOffsetSlider:SetObeyStepOnDrag(true)
    verticalOffsetSlider.Low:SetText("-400")
    verticalOffsetSlider.High:SetText("400")

    local verticalOffsetValueText = verticalOffsetSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    verticalOffsetValueText:SetPoint("TOP", verticalOffsetSlider, "BOTTOM", 0, -4)

    local function RefreshVerticalOffsetText()
        verticalOffsetValueText:SetText(string.format("Current: %d", Core:GetBattleFramesVerticalOffset()))
    end

    verticalOffsetSlider:SetValue(Core:GetBattleFramesVerticalOffset())
    RefreshVerticalOffsetText()

    verticalOffsetSlider:SetScript("OnValueChanged", function(self, value)
        local snapped = math.floor(value + 0.5)
        Core:SetBattleFramesVerticalOffset(snapped)
        RefreshVerticalOffsetText()
    end)

    local sideAbilityPaddingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sideAbilityPaddingLabel:SetPoint("TOPLEFT", 16, -410)
    sideAbilityPaddingLabel:SetText("Side Mode: Ability Horizontal Padding")

    local sideAbilityPaddingSlider = CreateFrame("Slider", addonName .. "BattleFramesSideAbilityPaddingSlider", content, "OptionsSliderTemplate")
    sideAbilityPaddingSlider:SetPoint("TOPLEFT", 20, -435)
    sideAbilityPaddingSlider:SetWidth(220)
    sideAbilityPaddingSlider:SetMinMaxValues(-20, 20)
    sideAbilityPaddingSlider:SetValueStep(1)
    sideAbilityPaddingSlider:SetObeyStepOnDrag(true)
    sideAbilityPaddingSlider.Low:SetText("-20")
    sideAbilityPaddingSlider.High:SetText("20")

    local sideAbilityPaddingValueText = sideAbilityPaddingSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sideAbilityPaddingValueText:SetPoint("TOP", sideAbilityPaddingSlider, "BOTTOM", 0, -4)

    local function RefreshSideAbilityPaddingText()
        sideAbilityPaddingValueText:SetText(string.format("Current: %d", Core:GetBattleFramesSideAbilityPadding()))
    end

    sideAbilityPaddingSlider:SetValue(Core:GetBattleFramesSideAbilityPadding())
    RefreshSideAbilityPaddingText()

    sideAbilityPaddingSlider:SetScript("OnValueChanged", function(self, value)
        local snapped = math.floor(value + 0.5)
        Core:SetBattleFramesSideAbilityPadding(snapped)
        RefreshSideAbilityPaddingText()
    end)

    local sideGroupPaddingLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sideGroupPaddingLabel:SetPoint("TOPLEFT", 296, -410)
    sideGroupPaddingLabel:SetText("Side Mode: Group Vertical Padding")

    local sideGroupPaddingSlider = CreateFrame("Slider", addonName .. "BattleFramesSideGroupPaddingSlider", content, "OptionsSliderTemplate")
    sideGroupPaddingSlider:SetPoint("TOPLEFT", 300, -435)
    sideGroupPaddingSlider:SetWidth(220)
    sideGroupPaddingSlider:SetMinMaxValues(0, 40)
    sideGroupPaddingSlider:SetValueStep(1)
    sideGroupPaddingSlider:SetObeyStepOnDrag(true)
    sideGroupPaddingSlider.Low:SetText("0")
    sideGroupPaddingSlider.High:SetText("40")

    local sideGroupPaddingValueText = sideGroupPaddingSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sideGroupPaddingValueText:SetPoint("TOP", sideGroupPaddingSlider, "BOTTOM", 0, -4)

    local function RefreshSideGroupPaddingText()
        sideGroupPaddingValueText:SetText(string.format("Current: %d", Core:GetBattleFramesSideGroupPadding()))
    end

    sideGroupPaddingSlider:SetValue(Core:GetBattleFramesSideGroupPadding())
    RefreshSideGroupPaddingText()

    sideGroupPaddingSlider:SetScript("OnValueChanged", function(self, value)
        local snapped = math.floor(value + 0.5)
        Core:SetBattleFramesSideGroupPadding(snapped)
        RefreshSideGroupPaddingText()
    end)

    local sideNameHorizontalOffsetLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sideNameHorizontalOffsetLabel:SetPoint("TOPLEFT", 16, -520)
    sideNameHorizontalOffsetLabel:SetText("Side Mode: Pet Name Center Offset")

    local sideNameHorizontalOffsetSlider = CreateFrame("Slider", addonName .. "BattleFramesSideNameHorizontalOffsetSlider", content, "OptionsSliderTemplate")
    sideNameHorizontalOffsetSlider:SetPoint("TOPLEFT", 20, -545)
    sideNameHorizontalOffsetSlider:SetWidth(220)
    sideNameHorizontalOffsetSlider:SetMinMaxValues(-50, 50)
    sideNameHorizontalOffsetSlider:SetValueStep(5)
    sideNameHorizontalOffsetSlider:SetObeyStepOnDrag(true)
    sideNameHorizontalOffsetSlider.Low:SetText("-50")
    sideNameHorizontalOffsetSlider.High:SetText("50")

    local sideNameHorizontalOffsetValueText = sideNameHorizontalOffsetSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sideNameHorizontalOffsetValueText:SetPoint("TOP", sideNameHorizontalOffsetSlider, "BOTTOM", 0, -4)

    local function RefreshSideNameHorizontalOffsetText()
        sideNameHorizontalOffsetValueText:SetText(string.format("Current: %d", Core:GetBattleFramesSideNameHorizontalOffset()))
    end

    sideNameHorizontalOffsetSlider:SetValue(Core:GetBattleFramesSideNameHorizontalOffset())
    RefreshSideNameHorizontalOffsetText()

    sideNameHorizontalOffsetSlider:SetScript("OnValueChanged", function(self, value)
        local snapped = math.floor((value / 5) + (value >= 0 and 0.5 or -0.5)) * 5
        Core:SetBattleFramesSideNameHorizontalOffset(snapped)
        RefreshSideNameHorizontalOffsetText()
    end)

    local resetButton = CreateFrame("Button", addonName .. "BattleFramesResetDefaultsButton", content, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", 16, -630)
    resetButton:SetSize(230, 28)
    resetButton:SetText("Restore Side Mode Defaults")

    local resetHint = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    resetHint:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 4, -6)
    resetHint:SetText("Applies only to Split to sides mode.")

    local sideModeControls = {
        horizontalOffsetSlider,
        verticalOffsetSlider,
        sideAbilityPaddingSlider,
        sideGroupPaddingSlider,
        sideNameHorizontalOffsetSlider,
        resetButton,
    }

    local sideModeLabels = {
        horizontalOffsetLabel,
        verticalOffsetLabel,
        sideAbilityPaddingLabel,
        sideGroupPaddingLabel,
        sideNameHorizontalOffsetLabel,
    }

    local function SetFontStringEnabled(fontString, enabled)
        fontString:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
    end

    local function RefreshSideModeEnabledState()
        local inSideMode = (Core:GetBattleFramesLayoutMode() == "SIDES")
        for _, control in ipairs(sideModeControls) do
            SetControlEnabled(control, inSideMode)
        end

        for _, label in ipairs(sideModeLabels) do
            SetFontStringEnabled(label, inSideMode)
        end

        SetFontStringEnabled(resetHint, inSideMode)
    end

    local layoutItems = {
        { text = "Overlapped with top bar", value = "OVERLAP" },
        { text = "Split to sides", value = "SIDES" },
    }

    local function GetLayoutText(value)
        for _, item in ipairs(layoutItems) do
            if item.value == value then
                return item.text
            end
        end
        return layoutItems[1].text
    end

    UIDropDownMenu_Initialize(positioningDropdown, function(self, _, _)
        for _, item in ipairs(layoutItems) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.value = item.value
            info.checked = (Core:GetBattleFramesLayoutMode() == item.value)
            info.func = function()
                Core:SetBattleFramesLayoutMode(item.value)
                UIDropDownMenu_SetSelectedValue(positioningDropdown, item.value)
                UIDropDownMenu_SetText(positioningDropdown, item.text)
                RefreshSideModeEnabledState()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local currentLayout = Core:GetBattleFramesLayoutMode()
    UIDropDownMenu_SetWidth(positioningDropdown, 240)
    UIDropDownMenu_SetSelectedValue(positioningDropdown, currentLayout)
    UIDropDownMenu_SetText(positioningDropdown, GetLayoutText(currentLayout))

    resetButton:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        Core:SetBattleFramesButtonScale(1)
        Core:SetBattleFramesHorizontalOffset(0)
        Core:SetBattleFramesVerticalOffset(400)
        Core:SetBattleFramesSideAbilityPadding(2)
        Core:SetBattleFramesSideGroupPadding(8)
        Core:SetBattleFramesSideNameHorizontalOffset(0)

        scaleSlider:SetValue(Core:GetBattleFramesButtonScale())
        horizontalOffsetSlider:SetValue(Core:GetBattleFramesHorizontalOffset())
        verticalOffsetSlider:SetValue(Core:GetBattleFramesVerticalOffset())
        sideAbilityPaddingSlider:SetValue(Core:GetBattleFramesSideAbilityPadding())
        sideGroupPaddingSlider:SetValue(Core:GetBattleFramesSideGroupPadding())
        sideNameHorizontalOffsetSlider:SetValue(Core:GetBattleFramesSideNameHorizontalOffset())
        RefreshScaleText()
        RefreshHorizontalOffsetText()
        RefreshVerticalOffsetText()
        RefreshSideAbilityPaddingText()
        RefreshSideGroupPaddingText()
        RefreshSideNameHorizontalOffsetText()
    end)

    RefreshSideModeEnabledState()

    panel.controls = {
        scaleSlider,
        positioningDropdown,
        horizontalOffsetSlider,
        verticalOffsetSlider,
        sideAbilityPaddingSlider,
        sideGroupPaddingSlider,
        sideNameHorizontalOffsetSlider,
        resetButton,
    }

    CreateFooter(content)
    local category = AddCategory(panel, "BattleFrames", parentCategory)
    ns.battleFramesPanel = panel
    return category
end

function ns.RefreshOptionsState()
    if not Core or not Core.db then
        return
    end

    local addonEnabled = Core:IsAddonEnabled()
    local customMusicEnabled = Core.db.customMusicEnabled
    local battleFramesEnabled = Core.db.battleFrames and Core.db.battleFrames.enabled

    if ns.rootPanel and ns.rootPanel.controls and ns.rootPanel.controls[2] then
        SetControlEnabled(ns.rootPanel.controls[2], addonEnabled)
    end

    if ns.rootPanel and ns.rootPanel.controls and ns.rootPanel.controls[3] then
        SetControlEnabled(ns.rootPanel.controls[3], addonEnabled)
    end

    if ns.musicPanel then
        SetPanelEnabled(ns.musicPanel, addonEnabled and customMusicEnabled)
    end

    if ns.battleFramesPanel then
        SetPanelEnabled(ns.battleFramesPanel, addonEnabled and battleFramesEnabled)
    end
end

function ns.CreateOptionsPanels()
    if ns.optionsBuilt then
        return
    end

    local root = BuildWelcomePanel()
    BuildMusicPanel(root)
    BuildBattleFramesPanel(root)
    ns.RefreshOptionsState()
    ns.optionsBuilt = true
end
