-- Options/OptionsTab.lua
-- Options tab content for standalone options window

function CreateOptionsTab(standaloneFrame, content)
  -- Create the options view container
  standaloneFrame.optionsView = CreateFrame("Frame", nil, content)
  standaloneFrame.optionsView:SetPoint("TOPLEFT", standaloneFrame.tabs[1], "BOTTOMLEFT", 0, -5)
  standaloneFrame.optionsView:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
  
  -- Create scroll frame for options
  standaloneFrame.optionsScrollFrame = CreateFrame("ScrollFrame", nil, standaloneFrame.optionsView, "UIPanelScrollFrameTemplate")
  standaloneFrame.optionsScrollFrame:SetPoint("TOPLEFT", standaloneFrame.optionsView, "TOPLEFT", 0, 0)
  standaloneFrame.optionsScrollFrame:SetPoint("BOTTOMRIGHT", standaloneFrame.optionsView, "BOTTOMRIGHT", -25, 0) -- Account for scrollbar
  
  -- Create scrollable content frame
  standaloneFrame.optionsContent = CreateFrame("Frame", nil, standaloneFrame.optionsScrollFrame)
  standaloneFrame.optionsContent:SetSize(480, 600) -- Taller than visible area to ensure scrolling
  standaloneFrame.optionsScrollFrame:SetScrollChild(standaloneFrame.optionsContent)
  
  -- Show coinage tracker checkbox
  standaloneFrame.showTrackerCheck = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.showTrackerCheck:SetPoint("TOPLEFT", standaloneFrame.optionsContent, "TOPLEFT", 10, -10)
  standaloneFrame.showTrackerCheck.Text:SetText("Show draggable coinage tracker")
  standaloneFrame.showTrackerCheck:SetScript("OnClick", function(self) 
    PPT_UI_Settings.coinageTracker.enabled = self:GetChecked()
    if UpdateCoinageTracker then
      UpdateCoinageTracker()
    end
  end)
  
  -- Reset tracker position button
  local resetPosBtn = CreateFrame("Button", nil, standaloneFrame.optionsContent, "UIPanelButtonTemplate")
  resetPosBtn:SetSize(120, 22)
  resetPosBtn:SetPoint("LEFT", standaloneFrame.showTrackerCheck.Text, "RIGHT", 10, 0)
  resetPosBtn:SetText("Reset Position")
  resetPosBtn:SetScript("OnClick", function() ResetCoinageTrackerPosition() end)
  
  -- Show messages checkbox
  standaloneFrame.showMsg = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.showMsg:SetPoint("TOPLEFT", standaloneFrame.showTrackerCheck, "BOTTOMLEFT", 0, -8)
  standaloneFrame.showMsg.Text:SetText("Show loot messages")
  standaloneFrame.showMsg:SetScript("OnClick", function(self) PPT_ShowMsg = self:GetChecked() end)
  
  -- Show session toasts checkbox
  standaloneFrame.showSessionToasts = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.showSessionToasts:SetPoint("TOPLEFT", standaloneFrame.showMsg, "BOTTOMLEFT", 0, -8)
  standaloneFrame.showSessionToasts.Text:SetText("Show session completion toasts")
  standaloneFrame.showSessionToasts:SetScript("OnClick", function(self) PPT_ShowSessionToasts = self:GetChecked() end)
  
  standaloneFrame.shareGroup = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.shareGroup:SetPoint("TOPLEFT", standaloneFrame.showSessionToasts, "BOTTOMLEFT", 0, -8)
  standaloneFrame.shareGroup.Text:SetText("Auto-share session summaries")
  standaloneFrame.shareGroup:SetScript("OnClick", function(self) PPT_ShareGroup = self:GetChecked() end)
  
  -- Debug mode checkbox
  standaloneFrame.debugMode = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.debugMode:SetPoint("TOPLEFT", standaloneFrame.shareGroup, "BOTTOMLEFT", 0, -8)
  standaloneFrame.debugMode.Text:SetText("Debug mode")
  standaloneFrame.debugMode:SetScript("OnClick", function(self) PPT_Debug = self:GetChecked() end)
  
  -- Stopwatch feature checkbox
  standaloneFrame.stopwatchEnabled = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.stopwatchEnabled:SetPoint("TOPLEFT", standaloneFrame.debugMode, "BOTTOMLEFT", 0, -8)
  standaloneFrame.stopwatchEnabled.Text:SetText("Enable earnings tracking (stopwatch)")
  standaloneFrame.stopwatchEnabled:SetScript("OnClick", function(self) 
    PPT_StopwatchEnabled = self:GetChecked()
    -- If disabling while tracking is active, stop it
    if not PPT_StopwatchEnabled and PPT_TrackingActive then
      StopPickPocketTracking()
    end
    -- Update the UI to reflect the change
    if UpdateCoinageTracker then
      UpdateCoinageTracker()
    end
  end)
  
  -- Session display enabled checkbox
  standaloneFrame.sessionDisplayEnabled = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.sessionDisplayEnabled:SetPoint("TOPLEFT", standaloneFrame.stopwatchEnabled, "BOTTOMLEFT", 0, -8)
  standaloneFrame.sessionDisplayEnabled.Text:SetText("Show session info in tracker UI")
  standaloneFrame.sessionDisplayEnabled:SetScript("OnClick", function(self) 
    PPT_SessionDisplayEnabled = self:GetChecked()
    -- Update the UI to reflect the change
    if UpdateCoinageTracker then
      UpdateCoinageTracker()
    end
  end)
  
  -- UI Anchor Point dropdown
  standaloneFrame.anchorLabel = standaloneFrame.optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  standaloneFrame.anchorLabel:SetPoint("TOPLEFT", standaloneFrame.sessionDisplayEnabled, "BOTTOMLEFT", 0, -15)
  standaloneFrame.anchorLabel:SetText("UI Resize Anchor Point:")
  
  standaloneFrame.anchorDropdown = CreateFrame("Frame", "PPT_AnchorDropdown", standaloneFrame.optionsContent, "UIDropDownMenuTemplate")
  standaloneFrame.anchorDropdown:SetPoint("TOPLEFT", standaloneFrame.anchorLabel, "BOTTOMLEFT", -15, -5)
  UIDropDownMenu_SetWidth(standaloneFrame.anchorDropdown, 150)
  UIDropDownMenu_SetText(standaloneFrame.anchorDropdown, PPT_UI_Settings.coinageTracker.anchorPoint or "CENTER")
  
  local anchorOptions = {"CENTER", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
  UIDropDownMenu_Initialize(standaloneFrame.anchorDropdown, function(self, level)
    for _, option in ipairs(anchorOptions) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = option
      info.value = option
      info.func = function()
        PPT_UI_Settings.coinageTracker.anchorPoint = option
        UIDropDownMenu_SetText(standaloneFrame.anchorDropdown, option)
        if PositionFrameFromAnchor then
          PositionFrameFromAnchor()
        end
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  
  -- Show Anchor checkbox
  standaloneFrame.showAnchor = CreateFrame("CheckButton", nil, standaloneFrame.optionsContent, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.showAnchor:SetPoint("TOPLEFT", standaloneFrame.anchorDropdown, "BOTTOMLEFT", 15, -10)
  standaloneFrame.showAnchor.Text:SetText("Show Anchor Point")
  standaloneFrame.showAnchor:SetChecked(PPT_UI_Settings.coinageTracker.showAnchor or false)
  standaloneFrame.showAnchor:SetScript("OnClick", function(self)
    PPT_UI_Settings.coinageTracker.showAnchor = self:GetChecked()
    if UpdateAnchorVisibility then
      UpdateAnchorVisibility()
    end
  end)
  
  -- Achievement alert opacity slider
  standaloneFrame.alertOpacityLabel = standaloneFrame.optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  standaloneFrame.alertOpacityLabel:SetPoint("TOPLEFT", standaloneFrame.showAnchor, "BOTTOMLEFT", 0, -15)
  standaloneFrame.alertOpacityLabel:SetText("Achievement Alert Opacity:")
  
  standaloneFrame.alertOpacitySlider = CreateFrame("Slider", "PPT_StandaloneAlertOpacitySlider", standaloneFrame.optionsContent, "OptionsSliderTemplate")
  standaloneFrame.alertOpacitySlider:SetPoint("TOPLEFT", standaloneFrame.alertOpacityLabel, "BOTTOMLEFT", 10, -10)
  standaloneFrame.alertOpacitySlider:SetMinMaxValues(0.1, 1.0)
  standaloneFrame.alertOpacitySlider:SetValue(PPT_AlertOpacity or 1.0)
  standaloneFrame.alertOpacitySlider:SetValueStep(0.1)
  standaloneFrame.alertOpacitySlider:SetWidth(200)
  getglobal(standaloneFrame.alertOpacitySlider:GetName() .. 'Low'):SetText('0.1')
  getglobal(standaloneFrame.alertOpacitySlider:GetName() .. 'High'):SetText('1.0')
  getglobal(standaloneFrame.alertOpacitySlider:GetName() .. 'Text'):SetText(string.format("%.1f", PPT_AlertOpacity or 1.0))
  standaloneFrame.alertOpacitySlider:SetScript("OnValueChanged", function(self, value)
    PPT_AlertOpacity = value
    getglobal(self:GetName() .. 'Text'):SetText(string.format("%.1f", value))
  end)
  
  -- Background color section
  local bgColorHeader = standaloneFrame.optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  bgColorHeader:SetPoint("TOPLEFT", standaloneFrame.alertOpacitySlider, "BOTTOMLEFT", -10, -25)
  bgColorHeader:SetText("Tracker Background Color:")
  bgColorHeader:SetTextColor(1, 0.82, 0)
  
  -- Color preview and picker button
  standaloneFrame.colorFrame = CreateFrame("Frame", nil, standaloneFrame.optionsContent)
  standaloneFrame.colorFrame:SetSize(200, 30)
  standaloneFrame.colorFrame:SetPoint("TOPLEFT", bgColorHeader, "BOTTOMLEFT", 0, -10)
  
  -- Color preview box
  standaloneFrame.colorPreview = CreateFrame("Frame", nil, standaloneFrame.colorFrame)
  standaloneFrame.colorPreview:SetSize(50, 25)
  standaloneFrame.colorPreview:SetPoint("LEFT", 0, 0)
  standaloneFrame.colorPreview:EnableMouse(true)
  
  -- Color preview background
  standaloneFrame.colorPreview.bg = standaloneFrame.colorPreview:CreateTexture(nil, "BACKGROUND")
  standaloneFrame.colorPreview.bg:SetAllPoints()
  
  -- Color preview border
  standaloneFrame.colorPreview.border = standaloneFrame.colorPreview:CreateTexture(nil, "BORDER")
  standaloneFrame.colorPreview.border:SetAllPoints()
  standaloneFrame.colorPreview.border:SetColorTexture(0.5, 0.5, 0.5, 1)
  
  -- Make the preview clickable
  standaloneFrame.colorPreview:SetScript("OnMouseUp", function()
    local bg = PPT_UI_Settings.coinageTracker.backgroundColor or {0.15, 0.15, 0.15, 1}
    
    -- Set up the color picker
    ColorPickerFrame.swatchFunc = function()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      local a = 1 - OpacitySliderFrame:GetValue() -- WoW's opacity slider is inverted
      
      -- Update the background color setting
      PPT_UI_Settings.coinageTracker.backgroundColor = {r, g, b, a}
      
      -- Update the preview
      standaloneFrame.colorPreview.bg:SetColorTexture(r, g, b, a)
      
      -- Update the tracker
      if UpdateCoinageTracker then
        UpdateCoinageTracker()
      end
    end
    
    -- Set up opacity callback
    ColorPickerFrame.opacityFunc = function()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      local a = 1 - OpacitySliderFrame:GetValue() -- WoW's opacity slider is inverted
      
      -- Update the background color setting
      PPT_UI_Settings.coinageTracker.backgroundColor = {r, g, b, a}
      
      -- Update the preview
      standaloneFrame.colorPreview.bg:SetColorTexture(r, g, b, a)
      
      -- Update the tracker
      if UpdateCoinageTracker then
        UpdateCoinageTracker()
      end
    end
    
    ColorPickerFrame.cancelFunc = function()
      -- Restore original color if cancelled
      local r, g, b, a = bg[1], bg[2], bg[3], bg[4]
      PPT_UI_Settings.coinageTracker.backgroundColor = bg
      standaloneFrame.colorPreview.bg:SetColorTexture(r, g, b, a)
      if UpdateCoinageTracker then
        UpdateCoinageTracker()
      end
    end
    
    -- Set initial color and opacity
    ColorPickerFrame:SetColorRGB(bg[1], bg[2], bg[3])
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - bg[4] -- WoW's opacity is inverted (0=opaque, 1=transparent)
    
    -- Show the color picker
    ColorPickerFrame:Show()
  end)
  
  -- Click instruction label
  local colorLabel = standaloneFrame.colorFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  colorLabel:SetPoint("LEFT", standaloneFrame.colorPreview, "RIGHT", 10, 0)
  colorLabel:SetText("Click to open color picker")
  colorLabel:SetTextColor(0.8, 0.8, 0.8)
  
  -- Update color preview initially
  local bg = PPT_UI_Settings.coinageTracker.backgroundColor or {0.15, 0.15, 0.15, 1}
  standaloneFrame.colorPreview.bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
  
  -- Session control buttons
  local sessionHeader = standaloneFrame.optionsContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  sessionHeader:SetPoint("TOPLEFT", standaloneFrame.colorFrame, "BOTTOMLEFT", 0, -25)
  sessionHeader:SetText("Session Control:")
  sessionHeader:SetTextColor(1, 0.82, 0)
  
  local resetSessionBtn = CreateFrame("Button", nil, standaloneFrame.optionsContent, "UIPanelButtonTemplate")
  resetSessionBtn:SetSize(120, 22)
  resetSessionBtn:SetPoint("TOPLEFT", sessionHeader, "BOTTOMLEFT", 0, -10)
  resetSessionBtn:SetText("Reset Session")
  resetSessionBtn:SetScript("OnClick", function() PPT_ResetSession() end)
  
  local resetAllBtn = CreateFrame("Button", nil, standaloneFrame.optionsContent, "UIPanelButtonTemplate")
  resetAllBtn:SetSize(120, 22)
  resetAllBtn:SetPoint("LEFT", resetSessionBtn, "RIGHT", 10, 0)
  resetAllBtn:SetText("Reset All Data")
  resetAllBtn:SetScript("OnClick", function() 
    StaticPopup_Show("PPT_RESET_ALL_CONFIRM")
  end)
  
  -- Second row of reset buttons
  local resetAchievementsBtn = CreateFrame("Button", nil, standaloneFrame.optionsContent, "UIPanelButtonTemplate")
  resetAchievementsBtn:SetSize(140, 22)
  resetAchievementsBtn:SetPoint("TOPLEFT", resetSessionBtn, "BOTTOMLEFT", 0, -10)
  resetAchievementsBtn:SetText("Reset Achievements")
  resetAchievementsBtn:SetScript("OnClick", function() 
    StaticPopup_Show("PPT_RESET_ACHIEVEMENTS_CONFIRM")
  end)
  
  local resetLocationsBtn = CreateFrame("Button", nil, standaloneFrame.optionsContent, "UIPanelButtonTemplate")
  resetLocationsBtn:SetSize(140, 22)
  resetLocationsBtn:SetPoint("LEFT", resetAchievementsBtn, "RIGHT", 10, 0)
  resetLocationsBtn:SetText("Reset Locations")
  resetLocationsBtn:SetScript("OnClick", function() 
    StaticPopup_Show("PPT_RESET_LOCATIONS_CONFIRM")
  end)
  
-- Update options data
function UpdateOptionsTabData(standaloneFrame)
  if not standaloneFrame then return end
  
  standaloneFrame.showTrackerCheck:SetChecked(IsCoinageTrackerEnabled())
  standaloneFrame.showMsg:SetChecked(PPT_ShowMsg)
  standaloneFrame.showSessionToasts:SetChecked(PPT_ShowSessionToasts)
  standaloneFrame.shareGroup:SetChecked(PPT_ShareGroup)
  standaloneFrame.debugMode:SetChecked(PPT_Debug)
  standaloneFrame.stopwatchEnabled:SetChecked(PPT_StopwatchEnabled)
  standaloneFrame.sessionDisplayEnabled:SetChecked(PPT_SessionDisplayEnabled)
  if standaloneFrame.alertOpacitySlider then
    standaloneFrame.alertOpacitySlider:SetValue(PPT_AlertOpacity or 1.0)
  end
  if standaloneFrame.anchorDropdown then
    UIDropDownMenu_SetText(standaloneFrame.anchorDropdown, PPT_UI_Settings.coinageTracker.anchorPoint or "CENTER")
  end
  if standaloneFrame.showAnchor then
    standaloneFrame.showAnchor:SetChecked(PPT_UI_Settings.coinageTracker.showAnchor or false)
  end
  
  -- Update color preview
  if standaloneFrame.colorPreview then
    local bg = PPT_UI_Settings.coinageTracker.backgroundColor or {0.15, 0.15, 0.15, 1}
    standaloneFrame.colorPreview.bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
  end
end

  -- Hide by default
  standaloneFrame.optionsView:Hide()
end
