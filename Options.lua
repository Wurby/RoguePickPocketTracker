-- Options.lua
-- Interface options panel for RoguePickPocketTracker

------------------------------------------------------------
--                     OPTIONS PANEL
------------------------------------------------------------

local panel = CreateFrame("Frame", "RoguePickPocketTrackerOptions")
panel.name = "RoguePickPocketTracker"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Rogue PickPocket Tracker")

-- Tab system
panel.tabs = {}
panel.currentTab = 1

-- Create tab buttons
local function CreateTabButton(parent, index, text, width)
  local tab = CreateFrame("Button", nil, parent)
  tab:SetSize(width or 100, 24)
  tab:SetNormalFontObject("GameFontNormal")
  tab:SetHighlightFontObject("GameFontHighlight")
  tab:SetDisabledFontObject("GameFontDisable")
  tab:SetText(text)
  
  -- Tab appearance
  local normalTexture = tab:CreateTexture(nil, "BACKGROUND")
  normalTexture:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
  normalTexture:SetAllPoints()
  normalTexture:SetTexCoord(0, 1, 0, 1)
  tab:SetNormalTexture(normalTexture)
  
  local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
  highlightTexture:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
  highlightTexture:SetAllPoints()
  highlightTexture:SetTexCoord(0, 1, 0, 1)
  highlightTexture:SetAlpha(0.8)
  tab:SetHighlightTexture(highlightTexture)
  
  return tab
end

-- Create the three tabs
panel.tabs[1] = CreateTabButton(panel, 1, "Report", 80)
panel.tabs[1]:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

panel.tabs[2] = CreateTabButton(panel, 2, "Achievements", 100)
panel.tabs[2]:SetPoint("LEFT", panel.tabs[1], "RIGHT", 5, 0)

panel.tabs[3] = CreateTabButton(panel, 3, "Options", 80)
panel.tabs[3]:SetPoint("LEFT", panel.tabs[2], "RIGHT", 5, 0)

-- Tab click handlers
for i, tab in ipairs(panel.tabs) do
  tab:SetScript("OnClick", function() panel:ShowTab(i) end)
end

-- Tab content frames
panel.reportView = CreateFrame("Frame", nil, panel)
panel.reportView:SetPoint("TOPLEFT", panel.tabs[1], "BOTTOMLEFT", 0, -10)
panel.reportView:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 20)

panel.achievementsView = CreateFrame("Frame", nil, panel)
panel.achievementsView:SetPoint("TOPLEFT", panel.tabs[1], "BOTTOMLEFT", 0, -10)
panel.achievementsView:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 20)
panel.achievementsView:Hide()

panel.optionsView = CreateFrame("Frame", nil, panel)
panel.optionsView:SetPoint("TOPLEFT", panel.tabs[1], "BOTTOMLEFT", 0, -10)
panel.optionsView:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 20)
panel.optionsView:Hide()

-- Function to show specific tab
function panel:ShowTab(tabIndex)
  self.currentTab = tabIndex
  
  -- Update tab appearances
  for i, tab in ipairs(self.tabs) do
    if i == tabIndex then
      tab:SetAlpha(1.0)
      tab:Disable()
    else
      tab:SetAlpha(0.7)
      tab:Enable()
    end
  end
  
  -- Show/hide content
  self.reportView:SetShown(tabIndex == 1)
  self.achievementsView:SetShown(tabIndex == 2)
  self.optionsView:SetShown(tabIndex == 3)
  
  -- Update content when switching tabs
  if tabIndex == 1 then
    self:updateStats()
  elseif tabIndex == 2 then
    self:updateAchievements()
  end
end

------------------------------------------------------------
--                      REPORT VIEW
------------------------------------------------------------

-- Statistics text labels
panel.statsHeader = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.statsHeader:SetPoint("TOPLEFT", 0, -10)
panel.statsHeader:SetText("Overall Statistics:")

panel.statCoin = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statCoin:SetPoint("TOPLEFT", panel.statsHeader, "BOTTOMLEFT", 10, -8)

panel.statItems = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statItems:SetPoint("TOPLEFT", panel.statCoin, "BOTTOMLEFT", 0, -4)

panel.statAttempts = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statAttempts:SetPoint("TOPLEFT", panel.statItems, "BOTTOMLEFT", 0, -10)

panel.statSuccess = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statSuccess:SetPoint("TOPLEFT", panel.statAttempts, "BOTTOMLEFT", 0, -4)

panel.statFails = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statFails:SetPoint("TOPLEFT", panel.statSuccess, "BOTTOMLEFT", 0, -4)

panel.statAvgAttempt = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statAvgAttempt:SetPoint("TOPLEFT", panel.statFails, "BOTTOMLEFT", 0, -10)

panel.statAvgSuccess = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statAvgSuccess:SetPoint("TOPLEFT", panel.statAvgAttempt, "BOTTOMLEFT", 0, -4)

-- Zone statistics section
panel.zoneHeader = panel.reportView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.zoneHeader:SetPoint("TOPLEFT", panel.statAvgSuccess, "BOTTOMLEFT", -10, -20)
panel.zoneHeader:SetText("Zone Statistics:")

panel.zoneScrollFrame = CreateFrame("ScrollFrame", nil, panel.reportView, "UIPanelScrollFrameTemplate")
panel.zoneScrollFrame:SetSize(400, 150)
panel.zoneScrollFrame:SetPoint("TOPLEFT", panel.zoneHeader, "BOTTOMLEFT", 0, -5)

panel.zoneContent = CreateFrame("Frame", nil, panel.zoneScrollFrame)
panel.zoneContent:SetSize(380, 1)
panel.zoneScrollFrame:SetScrollChild(panel.zoneContent)

------------------------------------------------------------
--                  ACHIEVEMENTS VIEW
------------------------------------------------------------

-- Achievement summary header
panel.achievementSummary = panel.achievementsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.achievementSummary:SetPoint("TOPLEFT", 0, -10)

-- Achievement list scroll frame
panel.achievementScrollFrame = CreateFrame("ScrollFrame", nil, panel.achievementsView, "UIPanelScrollFrameTemplate")
panel.achievementScrollFrame:SetPoint("TOPLEFT", panel.achievementSummary, "BOTTOMLEFT", 0, -10)
panel.achievementScrollFrame:SetPoint("BOTTOMRIGHT", panel.achievementsView, "BOTTOMRIGHT", -20, 10)

panel.achievementContent = CreateFrame("Frame", nil, panel.achievementScrollFrame)
panel.achievementScrollFrame:SetScrollChild(panel.achievementContent)

------------------------------------------------------------
--                    OPTIONS VIEW
------------------------------------------------------------

-- Settings section
panel.settingsHeader = panel.optionsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.settingsHeader:SetPoint("TOPLEFT", 0, -10)
panel.settingsHeader:SetText("Settings:")

-- Checkbox: toggle loot messages
panel.showMsg = CreateFrame("CheckButton", "PPT_ShowMsgCheck", panel.optionsView, "InterfaceOptionsCheckButtonTemplate")
panel.showMsg:SetPoint("TOPLEFT", panel.settingsHeader, "BOTTOMLEFT", 10, -8)
panel.showMsg.Text:SetText("Show loot messages")
panel.showMsg:SetScript("OnClick", function(self) PPT_ShowMsg = self:GetChecked() end)

panel.shareGroup = CreateFrame("CheckButton", "PPT_ShareGroupCheck", panel.optionsView, "InterfaceOptionsCheckButtonTemplate")
panel.shareGroup:SetPoint("TOPLEFT", panel.showMsg, "BOTTOMLEFT", 0, -8)
panel.shareGroup.Text:SetText("Auto share stats")
panel.shareGroup:SetScript("OnClick", function(self) PPT_ShareGroup = self:GetChecked() end)

-- Debug mode checkbox
panel.debugMode = CreateFrame("CheckButton", "PPT_DebugModeCheck", panel.optionsView, "InterfaceOptionsCheckButtonTemplate")
panel.debugMode:SetPoint("TOPLEFT", panel.shareGroup, "BOTTOMLEFT", 0, -8)
panel.debugMode.Text:SetText("Debug mode")
panel.debugMode:SetScript("OnClick", function(self) PPT_Debug = self:GetChecked() end)

-- Achievement alert opacity slider
panel.alertOpacityLabel = panel.optionsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.alertOpacityLabel:SetPoint("TOPLEFT", panel.debugMode, "BOTTOMLEFT", 0, -15)
panel.alertOpacityLabel:SetText("Achievement Alert Opacity:")

panel.alertOpacitySlider = CreateFrame("Slider", "PPT_AlertOpacitySlider", panel.optionsView, "OptionsSliderTemplate")
panel.alertOpacitySlider:SetPoint("TOPLEFT", panel.alertOpacityLabel, "BOTTOMLEFT", 10, -10)
panel.alertOpacitySlider:SetMinMaxValues(20, 100)
panel.alertOpacitySlider:SetValue(PPT_AlertOpacity or 80)
panel.alertOpacitySlider:SetValueStep(5)
panel.alertOpacitySlider:SetObeyStepOnDrag(true)

-- Slider labels
panel.alertOpacitySlider.Low = panel.alertOpacitySlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
panel.alertOpacitySlider.Low:SetPoint("TOPLEFT", panel.alertOpacitySlider, "BOTTOMLEFT", 0, 0)
panel.alertOpacitySlider.Low:SetText("20%")

panel.alertOpacitySlider.High = panel.alertOpacitySlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
panel.alertOpacitySlider.High:SetPoint("TOPRIGHT", panel.alertOpacitySlider, "BOTTOMRIGHT", 0, 0)
panel.alertOpacitySlider.High:SetText("100%")

panel.alertOpacitySlider.Text = panel.alertOpacitySlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.alertOpacitySlider.Text:SetPoint("TOP", panel.alertOpacitySlider, "BOTTOM", 0, -15)

-- Update slider text and save value
local function updateOpacityText()
  local value = panel.alertOpacitySlider:GetValue()
  panel.alertOpacitySlider.Text:SetText(value .. "%")
  PPT_AlertOpacity = value
end

panel.alertOpacitySlider:SetScript("OnValueChanged", function(self, value)
  updateOpacityText()
end)

-- Initialize slider text
updateOpacityText()

-- Danger zone section
panel.dangerHeader = panel.optionsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.dangerHeader:SetPoint("TOPLEFT", panel.alertOpacitySlider.Text, "BOTTOMLEFT", -10, -20)
panel.dangerHeader:SetText("Danger Zone:")
panel.dangerHeader:SetTextColor(1, 0.2, 0.2) -- Red color

-- Reset buttons with confirmations
panel.resetAchBtn = CreateFrame("Button", nil, panel.optionsView, "UIPanelButtonTemplate")
panel.resetAchBtn:SetSize(130, 22)
panel.resetAchBtn:SetPoint("TOPLEFT", panel.dangerHeader, "BOTTOMLEFT", 10, -10)
panel.resetAchBtn:SetText("Reset Achievements")
panel.resetAchBtn:SetScript("OnClick", function()
  StaticPopup_Show("PPT_RESET_ACHIEVEMENTS_CONFIRM")
end)

panel.resetCoinsBtn = CreateFrame("Button", nil, panel.optionsView, "UIPanelButtonTemplate")
panel.resetCoinsBtn:SetSize(120, 22)
panel.resetCoinsBtn:SetPoint("LEFT", panel.resetAchBtn, "RIGHT", 5, 0)
panel.resetCoinsBtn:SetText("Reset Coins/Items")
panel.resetCoinsBtn:SetScript("OnClick", function()
  StaticPopup_Show("PPT_RESET_COINS_CONFIRM")
end)

panel.resetLocBtn = CreateFrame("Button", nil, panel.optionsView, "UIPanelButtonTemplate")
panel.resetLocBtn:SetSize(110, 22)
panel.resetLocBtn:SetPoint("TOPLEFT", panel.resetAchBtn, "BOTTOMLEFT", 0, -5)
panel.resetLocBtn:SetText("Reset Locations")
panel.resetLocBtn:SetScript("OnClick", function()
  StaticPopup_Show("PPT_RESET_LOCATIONS_CONFIRM")
end)

panel.resetAllBtn = CreateFrame("Button", nil, panel.optionsView, "UIPanelButtonTemplate")
panel.resetAllBtn:SetSize(100, 22)
panel.resetAllBtn:SetPoint("LEFT", panel.resetLocBtn, "RIGHT", 5, 0)
panel.resetAllBtn:SetText("Reset Everything")
panel.resetAllBtn:SetScript("OnClick", function()
  StaticPopup_Show("PPT_RESET_ALL_CONFIRM")
end)

-- Confirmation dialogs
StaticPopupDialogs["PPT_RESET_ACHIEVEMENTS_CONFIRM"] = {
  text = "Reset all achievement progress?\n\nThis cannot be undone!",
  button1 = "Yes, Reset",
  button2 = "Cancel",
  OnAccept = function()
    ResetAchievements()
    if panel then
      if panel.updateStats then panel:updateStats() end
      if panel.updateAchievements then panel:updateAchievements() end
    end
    PPTPrint("All achievements have been reset.")
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["PPT_RESET_COINS_CONFIRM"] = {
  text = "Reset all coins and items data?\n\nThis cannot be undone!",
  button1 = "Yes, Reset",
  button2 = "Cancel",
  OnAccept = function()
    ResetCoinsAndItems()
    if panel then
      if panel.updateStats then panel:updateStats() end
      if panel.updateAchievements then panel:updateAchievements() end
    end
    PPTPrint("Coins and items data has been reset.")
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["PPT_RESET_LOCATIONS_CONFIRM"] = {
  text = "Reset all location statistics?\n\nThis cannot be undone!",
  button1 = "Yes, Reset",
  button2 = "Cancel",
  OnAccept = function()
    ResetLocations()
    if panel then
      if panel.updateStats then panel:updateStats() end
      if panel.updateAchievements then panel:updateAchievements() end
    end
    PPTPrint("Location statistics have been reset.")
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["PPT_RESET_ALL_CONFIRM"] = {
  text = "*** WARNING ***\n\nThis will reset ALL statistics and achievements!\n\nAre you sure you want to continue?",
  button1 = "Yes, Reset Everything",
  button2 = "Cancel",
  OnAccept = function()
    ResetAllStats()
    if panel then
      if panel.updateStats then panel:updateStats() end
      if panel.updateAchievements then panel:updateAchievements() end
    end
    PPTPrint("All statistics and achievements have been reset.")
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

------------------------------------------------------------
--                    VIEW FUNCTIONS
------------------------------------------------------------

-- Function to update zone statistics display
function panel:updateZoneStats()
  -- Check if zone functions are available
  if not getZoneStatsSummary then
    return
  end
  
  -- Clear existing zone stat displays
  if self.zoneStatStrings then
    for _, fontString in ipairs(self.zoneStatStrings) do
      fontString:Hide()
    end
  end
  self.zoneStatStrings = {}
  
  local zones = getZoneStatsSummary()
  local yOffset = 0
  
  for i, zoneData in ipairs(zones) do
    if i > 10 then break end  -- Limit to top 10 zones
    
    local stats = zoneData.stats
    local successRate = stats.attempts > 0 and math.floor((stats.successes / stats.attempts) * 100) or 0
    local text = string.format("%s: %s (%d/%d, %d%%, %d items)",
      zoneData.zone, coinsToString(stats.copper), stats.successes, stats.attempts, successRate, stats.items)
    
    local fontString = self.zoneContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fontString:SetPoint("TOPLEFT", 0, yOffset)
    fontString:SetText(text)
    fontString:SetJustifyH("LEFT")
    fontString:SetWidth(380)
    
    table.insert(self.zoneStatStrings, fontString)
    yOffset = yOffset - 14
  end
  
  if #zones == 0 then
    local noDataString = self.zoneContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    noDataString:SetPoint("TOPLEFT", 0, 0)
    noDataString:SetText("No zone data available yet.")
    table.insert(self.zoneStatStrings, noDataString)
    yOffset = -14
  end
  
  self.zoneContent:SetHeight(math.abs(yOffset))
end

-- Function to update achievements display
function panel:updateAchievements()
  -- Check if achievement functions are available
  if not getAchievementsList or not getCompletedAchievementsCount or not getTotalAchievementsCount then
    return
  end
  
  -- Get the scroll frame width for dynamic sizing
  local scrollWidth = self.achievementScrollFrame:GetWidth() - 20 -- Account for scrollbar
  if scrollWidth < 400 then scrollWidth = 400 end -- Minimum width
  
  -- Set content frame width
  self.achievementContent:SetWidth(scrollWidth)
  
  -- Update summary
  local completed = getCompletedAchievementsCount()
  local total = getTotalAchievementsCount()
  local percentage = total > 0 and math.floor((completed / total) * 100) or 0
  self.achievementSummary:SetText(string.format("Achievements: %d/%d (%d%% complete)", completed, total, percentage))
  
  -- Clear existing achievement displays
  if self.achievementStrings then
    for _, entry in ipairs(self.achievementStrings) do
      if entry.frame then entry.frame:Hide() end
      if entry.icon then entry.icon:Hide() end
      if entry.title then entry.title:Hide() end
      if entry.description then entry.description:Hide() end
      if entry.progress then entry.progress:Hide() end
      if entry.completed then entry.completed:Hide() end
    end
  end
  self.achievementStrings = {}
  
  local achievements = getAchievementsList()
  local yOffset = 0
  
  -- Sort achievements by category first, then by completion status within category, then by goal
  table.sort(achievements, function(a, b)
    -- First sort by category
    if a.category ~= b.category then
      return a.category < b.category
    end
    
    -- Within same category, sort by completion status (completed first)
    local aCompleted = isAchievementCompleted(a.id)
    local bCompleted = isAchievementCompleted(b.id)
    if aCompleted ~= bCompleted then
      return aCompleted  -- Completed first within category
    end
    
    -- Finally sort by goal (difficulty)
    return a.goal < b.goal
  end)
  
  local lastCategory = nil
  for _, achievement in ipairs(achievements) do
    -- Add category header if different from last
    if lastCategory ~= achievement.category then
      local categoryHeader = self.achievementContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      categoryHeader:SetPoint("TOPLEFT", 0, yOffset)
      categoryHeader:SetText(string.upper(achievement.category:gsub("_", " ")))
      categoryHeader:SetTextColor(1, 0.82, 0)  -- Gold color
      lastCategory = achievement.category
      
      local entry = {frame = categoryHeader}
      table.insert(self.achievementStrings, entry)
      yOffset = yOffset - 18
    end
    
    -- Create achievement entry frame
    local entryFrame = CreateFrame("Frame", nil, self.achievementContent)
    entryFrame:SetSize(scrollWidth, 40)
    entryFrame:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Achievement icon (placeholder for now)
    local icon = entryFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT", 5, -4)
    if achievement.icon then
      icon:SetTexture(achievement.icon)
    else
      icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    -- Achievement title
    local title = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
    title:SetText(achievement.name)
    title:SetJustifyH("LEFT")
    title:SetWidth(scrollWidth - 200) -- Leave space for progress text
    
    -- Achievement description
    local description = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    description:SetText(achievement.description)
    description:SetJustifyH("LEFT")
    description:SetWidth(scrollWidth - 200)
    description:SetTextColor(0.8, 0.8, 0.8)
    
    -- Progress text
    local progress = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    progress:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -5, -4)
    progress:SetJustifyH("RIGHT")
    
    local completed = nil
    if isAchievementCompleted(achievement.id) then
      title:SetTextColor(0, 1, 0)  -- Green for completed
      progress:SetText("COMPLETE")
      progress:SetTextColor(0, 1, 0)
      
      completed = entryFrame:CreateTexture(nil, "OVERLAY")
      completed:SetSize(16, 16)
      completed:SetPoint("RIGHT", progress, "LEFT", -5, 0)
      completed:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    else
      title:SetTextColor(1, 1, 1)  -- White for incomplete
      progress:SetText(formatAchievementProgress(achievement.id))
      progress:SetTextColor(1, 1, 1)
    end
    
    local entry = {
      frame = entryFrame,
      icon = icon,
      title = title,
      description = description,
      progress = progress,
      completed = completed
    }
    table.insert(self.achievementStrings, entry)
    yOffset = yOffset - 45
  end
  
  if #achievements == 0 then
    local noDataString = self.achievementContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    noDataString:SetPoint("TOPLEFT", 0, 0)
    noDataString:SetText("No achievements available.")
    local entry = {frame = noDataString}
    table.insert(self.achievementStrings, entry)
    yOffset = -14
  end
  
  self.achievementContent:SetHeight(math.abs(yOffset))
end

-- Refresh stats display
function panel:updateStats()
  self.showMsg:SetChecked(PPT_ShowMsg)
  self.shareGroup:SetChecked(PPT_ShareGroup)
  self.debugMode:SetChecked(PPT_Debug)
  if self.alertOpacitySlider then
    self.alertOpacitySlider:SetValue(PPT_AlertOpacity or 80)
  end
  self.statCoin:SetText("Total Coinage: "..coinsToString(PPT_TotalCopper))
  self.statItems:SetText("Total Items: "..PPT_TotalItems)
  self.statAttempts:SetText("Attempts: "..PPT_TotalAttempts)
  self.statSuccess:SetText("Successes: "..PPT_SuccessfulAttempts)
  self.statFails:SetText("Fails: "..(PPT_TotalAttempts - PPT_SuccessfulAttempts))
  local avgAttempt = (PPT_TotalAttempts > 0) and math.floor(PPT_TotalCopper / PPT_TotalAttempts) or 0
  local avgSuccess = (PPT_SuccessfulAttempts > 0) and math.floor(PPT_TotalCopper / PPT_SuccessfulAttempts) or 0
  self.statAvgAttempt:SetText("Avg/Attempt: "..coinsToString(avgAttempt))
  self.statAvgSuccess:SetText("Avg/Success: "..coinsToString(avgSuccess))
  self:updateZoneStats()
end

-- Initialize with report view
panel:SetScript("OnShow", function(self) 
  self:ShowTab(1)
end)

-- Make panel globally accessible
_G.RoguePickPocketTrackerOptions = panel

-- Register with interface options (Classic Era method)
if InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
elseif Settings and Settings.RegisterCanvasLayoutCategory then
  local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  if category then
    Settings.RegisterAddOnCategory(category)
    panel.settingsCategory = category
    _G.PPT_SettingsCategory = category
  end
end

