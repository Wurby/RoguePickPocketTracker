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

-- Simplified traditional panel - just opens standalone window
local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
openBtn:SetSize(150, 25)
openBtn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
openBtn:SetText("Open Options Window")
openBtn:SetScript("OnClick", function() 
  if ShowStandaloneOptions then
    ShowStandaloneOptions() 
  else
    PPTPrint("Options window not available yet. Please try again.")
  end
end)

local descText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
descText:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -15)
descText:SetText("Click the button above to open the full options window with")
descText:SetTextColor(0.8, 0.8, 0.8)

local descText2 = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
descText2:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -5)
descText2:SetText("statistics, achievements, and all configuration options.")
descText2:SetTextColor(0.8, 0.8, 0.8)

-- Traditional panel registration  
panel.name = "RoguePickPocketTracker"

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

-- Reset popup for standalone window
StaticPopupDialogs["PPT_RESET_ALL_CONFIRM"] = {
  text = "Reset ALL data (achievements, coins, items, locations)?\nThis cannot be undone!",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function()
    ResetAllStats()
    PPTPrint("All statistics reset.")
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

------------------------------------------------------------
--                  STANDALONE OPTIONS WINDOW
------------------------------------------------------------

local standaloneFrame = nil

-- Create standalone options window
local function CreateStandaloneOptionsWindow()
  if standaloneFrame then return standaloneFrame end
  
  -- Main frame
  standaloneFrame = CreateFrame("Frame", "PPT_StandaloneOptions", UIParent, "UIPanelDialogTemplate")
  standaloneFrame:SetSize(600, 550)
  standaloneFrame:SetPoint("CENTER")
  standaloneFrame:SetFrameStrata("DIALOG")
  standaloneFrame:SetClampedToScreen(true)
  standaloneFrame:EnableMouse(true)
  standaloneFrame:SetMovable(true)
  standaloneFrame:RegisterForDrag("LeftButton")
  
  -- Make it draggable
  standaloneFrame:SetScript("OnDragStart", standaloneFrame.StartMoving)
  standaloneFrame:SetScript("OnDragStop", standaloneFrame.StopMovingOrSizing)
  
  -- ESC key handling
  standaloneFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
      self:Hide()
    end
  end)
  
  -- Close on ESC (alternative method)
  table.insert(UISpecialFrames, "PPT_StandaloneOptions")
  
  -- Title (manually set since SetTitle doesn't exist in Classic Era)
  if standaloneFrame.Title then
    standaloneFrame.Title:SetText("Rogue PickPocket Tracker")
  else
    -- Create title if it doesn't exist
    local title = standaloneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", standaloneFrame, "TOP", 0, -15)
    title:SetText("Rogue PickPocket Tracker")
    standaloneFrame.Title = title
  end
  
  -- Create content area
  local content = CreateFrame("Frame", nil, standaloneFrame)
  content:SetPoint("TOPLEFT", 16, -32)
  content:SetPoint("BOTTOMRIGHT", -16, 16)
  standaloneFrame.content = content
  
  -- Create tab system for standalone window
  standaloneFrame.tabs = {}
  standaloneFrame.currentTab = 1
  
  -- Create tab buttons
  local function CreateStandaloneTab(parent, index, text, width)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(width or 100, 24)
    tab:SetNormalFontObject("GameFontNormal")
    tab:SetHighlightFontObject("GameFontHighlight")
    tab:SetDisabledFontObject("GameFontDisable")
    tab:SetText(text)
    
    -- Tab appearance with achievement toast styling
    local normalTexture = tab:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetColorTexture(0.15, 0.15, 0.15, 0.8)
    normalTexture:SetAllPoints()
    tab:SetNormalTexture(normalTexture)
    
    local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetColorTexture(0.25, 0.25, 0.25, 0.8)
    highlightTexture:SetAllPoints()
    tab:SetHighlightTexture(highlightTexture)
    
    return tab
  end
  
  -- Create the tabs
  standaloneFrame.tabs[1] = CreateStandaloneTab(standaloneFrame, 1, "Report", 80)
  standaloneFrame.tabs[1]:SetPoint("TOPLEFT", content, "TOPLEFT", 10, 20)
  
  standaloneFrame.tabs[2] = CreateStandaloneTab(standaloneFrame, 2, "Achievements", 100)
  standaloneFrame.tabs[2]:SetPoint("LEFT", standaloneFrame.tabs[1], "RIGHT", 5, 0)
  
  standaloneFrame.tabs[3] = CreateStandaloneTab(standaloneFrame, 3, "Options", 80)
  standaloneFrame.tabs[3]:SetPoint("LEFT", standaloneFrame.tabs[2], "RIGHT", 5, 0)
  
  -- Tab content frames
  standaloneFrame.reportView = CreateFrame("Frame", nil, content)
  standaloneFrame.reportView:SetPoint("TOPLEFT", standaloneFrame.tabs[1], "BOTTOMLEFT", 0, -10)
  standaloneFrame.reportView:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
  
  standaloneFrame.achievementsView = CreateFrame("Frame", nil, content)
  standaloneFrame.achievementsView:SetPoint("TOPLEFT", standaloneFrame.tabs[1], "BOTTOMLEFT", 0, -10)
  standaloneFrame.achievementsView:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
  standaloneFrame.achievementsView:Hide()
  
  standaloneFrame.optionsView = CreateFrame("Frame", nil, content)
  standaloneFrame.optionsView:SetPoint("TOPLEFT", standaloneFrame.tabs[1], "BOTTOMLEFT", 0, -10)
  standaloneFrame.optionsView:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
  standaloneFrame.optionsView:Hide()
  
  -- Tab click handlers
  for i, tab in ipairs(standaloneFrame.tabs) do
    tab:SetScript("OnClick", function() standaloneFrame:ShowTab(i) end)
  end
  
  ------------------------------------------------
  --               REPORT VIEW
  ------------------------------------------------
  
  -- Main stats display
  local statsHeader = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  statsHeader:SetPoint("TOPLEFT", standaloneFrame.reportView, "TOPLEFT", 10, -10)
  statsHeader:SetText("Statistics:")
  statsHeader:SetTextColor(1, 0.82, 0)
  
  -- Create stat labels
  standaloneFrame.statCoin = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statCoin:SetPoint("TOPLEFT", statsHeader, "BOTTOMLEFT", 10, -10)
  standaloneFrame.statCoin:SetText("Total Coinage: 0c")
  
  standaloneFrame.statItems = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statItems:SetPoint("TOPLEFT", standaloneFrame.statCoin, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statItems:SetText("Total Items: 0")
  
  standaloneFrame.statAttempts = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statAttempts:SetPoint("TOPLEFT", standaloneFrame.statItems, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statAttempts:SetText("Attempts: 0")
  
  standaloneFrame.statSuccess = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statSuccess:SetPoint("TOPLEFT", standaloneFrame.statAttempts, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statSuccess:SetText("Successes: 0")
  
  standaloneFrame.statFails = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statFails:SetPoint("TOPLEFT", standaloneFrame.statSuccess, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statFails:SetText("Fails: 0")
  
  standaloneFrame.statAvgAttempt = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statAvgAttempt:SetPoint("TOPLEFT", standaloneFrame.statFails, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statAvgAttempt:SetText("Avg/Attempt: 0c")
  
  standaloneFrame.statAvgSuccess = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statAvgSuccess:SetPoint("TOPLEFT", standaloneFrame.statAvgAttempt, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statAvgSuccess:SetText("Avg/Success: 0c")
  
  -- Zone statistics section
  local zoneHeader = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  zoneHeader:SetPoint("TOPLEFT", standaloneFrame.statAvgSuccess, "BOTTOMLEFT", -10, -20)
  zoneHeader:SetText("Zone Statistics (Top 10):")
  zoneHeader:SetTextColor(1, 0.82, 0)
  
  standaloneFrame.zoneScrollFrame = CreateFrame("ScrollFrame", nil, standaloneFrame.reportView, "UIPanelScrollFrameTemplate")
  standaloneFrame.zoneScrollFrame:SetPoint("TOPLEFT", zoneHeader, "BOTTOMLEFT", 0, -10)
  standaloneFrame.zoneScrollFrame:SetSize(420, 140)
  
  standaloneFrame.zoneContent = CreateFrame("Frame", nil, standaloneFrame.zoneScrollFrame)
  standaloneFrame.zoneContent:SetSize(420, 140)
  standaloneFrame.zoneScrollFrame:SetScrollChild(standaloneFrame.zoneContent)
  
  ------------------------------------------------
  --            ACHIEVEMENTS VIEW
  ------------------------------------------------
  
  local achievementHeader = standaloneFrame.achievementsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  achievementHeader:SetPoint("TOPLEFT", standaloneFrame.achievementsView, "TOPLEFT", 10, -10)
  achievementHeader:SetText("Achievements:")
  achievementHeader:SetTextColor(1, 0.82, 0)
  
  standaloneFrame.achievementScrollFrame = CreateFrame("ScrollFrame", nil, standaloneFrame.achievementsView, "UIPanelScrollFrameTemplate")
  standaloneFrame.achievementScrollFrame:SetPoint("TOPLEFT", achievementHeader, "BOTTOMLEFT", 0, -10)
  standaloneFrame.achievementScrollFrame:SetSize(480, 420) -- Fit within the window properly
  
  standaloneFrame.achievementContent = CreateFrame("Frame", nil, standaloneFrame.achievementScrollFrame)
  standaloneFrame.achievementContent:SetSize(480, 420)
  standaloneFrame.achievementScrollFrame:SetScrollChild(standaloneFrame.achievementContent)
  
  ------------------------------------------------
  --              OPTIONS VIEW
  ------------------------------------------------
  
  -- Show coinage tracker checkbox
  standaloneFrame.showTrackerCheck = CreateFrame("CheckButton", nil, standaloneFrame.optionsView, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.showTrackerCheck:SetPoint("TOPLEFT", standaloneFrame.optionsView, "TOPLEFT", 10, -10)
  standaloneFrame.showTrackerCheck.Text:SetText("Show draggable coinage tracker")
  standaloneFrame.showTrackerCheck:SetScript("OnClick", function(self) 
    if self:GetChecked() then
      ShowCoinageTracker()
    else
      HideCoinageTracker()
    end
  end)
  
  -- Reset tracker position button
  local resetPosBtn = CreateFrame("Button", nil, standaloneFrame.optionsView, "UIPanelButtonTemplate")
  resetPosBtn:SetSize(120, 22)
  resetPosBtn:SetPoint("LEFT", standaloneFrame.showTrackerCheck.Text, "RIGHT", 10, 0)
  resetPosBtn:SetText("Reset Position")
  resetPosBtn:SetScript("OnClick", function() ResetCoinageTrackerPosition() end)
  
  -- Show messages checkbox
  standaloneFrame.showMsg = CreateFrame("CheckButton", nil, standaloneFrame.optionsView, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.showMsg:SetPoint("TOPLEFT", standaloneFrame.showTrackerCheck, "BOTTOMLEFT", 0, -8)
  standaloneFrame.showMsg.Text:SetText("Show loot messages")
  standaloneFrame.showMsg:SetScript("OnClick", function(self) PPT_ShowMsg = self:GetChecked() end)
  
  -- Show session toasts checkbox
  standaloneFrame.showSessionToasts = CreateFrame("CheckButton", nil, standaloneFrame.optionsView, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.showSessionToasts:SetPoint("TOPLEFT", standaloneFrame.showMsg, "BOTTOMLEFT", 0, -8)
  standaloneFrame.showSessionToasts.Text:SetText("Show session completion toasts")
  standaloneFrame.showSessionToasts:SetScript("OnClick", function(self) PPT_ShowSessionToasts = self:GetChecked() end)
  
  standaloneFrame.shareGroup = CreateFrame("CheckButton", nil, standaloneFrame.optionsView, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.shareGroup:SetPoint("TOPLEFT", standaloneFrame.showSessionToasts, "BOTTOMLEFT", 0, -8)
  standaloneFrame.shareGroup.Text:SetText("Auto-share session summaries")
  standaloneFrame.shareGroup:SetScript("OnClick", function(self) PPT_ShareGroup = self:GetChecked() end)
  
  -- Debug mode checkbox
  standaloneFrame.debugMode = CreateFrame("CheckButton", nil, standaloneFrame.optionsView, "InterfaceOptionsCheckButtonTemplate")
  standaloneFrame.debugMode:SetPoint("TOPLEFT", standaloneFrame.shareGroup, "BOTTOMLEFT", 0, -8)
  standaloneFrame.debugMode.Text:SetText("Debug mode")
  standaloneFrame.debugMode:SetScript("OnClick", function(self) PPT_Debug = self:GetChecked() end)
  
  -- Achievement alert opacity slider
  standaloneFrame.alertOpacityLabel = standaloneFrame.optionsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  standaloneFrame.alertOpacityLabel:SetPoint("TOPLEFT", standaloneFrame.debugMode, "BOTTOMLEFT", 0, -15)
  standaloneFrame.alertOpacityLabel:SetText("Achievement Alert Opacity:")
  
  standaloneFrame.alertOpacitySlider = CreateFrame("Slider", "PPT_StandaloneAlertOpacitySlider", standaloneFrame.optionsView, "OptionsSliderTemplate")
  standaloneFrame.alertOpacitySlider:SetPoint("TOPLEFT", standaloneFrame.alertOpacityLabel, "BOTTOMLEFT", 10, -10)
  standaloneFrame.alertOpacitySlider:SetMinMaxValues(0.1, 1.0)
  standaloneFrame.alertOpacitySlider:SetValue((PPT_AlertOpacity or 80) / 100) -- Convert percentage to decimal
  standaloneFrame.alertOpacitySlider:SetValueStep(0.1)
  standaloneFrame.alertOpacitySlider:SetObeyStepOnDrag(true)
  standaloneFrame.alertOpacitySlider:SetWidth(200)
  standaloneFrame.alertOpacitySlider:SetScript("OnValueChanged", function(self, value)
    PPT_AlertOpacity = math.floor(value * 100) -- Convert back to percentage for storage
    getglobal(self:GetName() .. "Text"):SetText(string.format("%.0f%%", value * 100))
  end)
  getglobal("PPT_StandaloneAlertOpacitySliderText"):SetText(string.format("%.0f%%", standaloneFrame.alertOpacitySlider:GetValue() * 100))
  
  -- Session control buttons
  local sessionHeader = standaloneFrame.optionsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  sessionHeader:SetPoint("TOPLEFT", standaloneFrame.alertOpacitySlider, "BOTTOMLEFT", -10, -25)
  sessionHeader:SetText("Session Control:")
  sessionHeader:SetTextColor(1, 0.82, 0)
  
  local resetSessionBtn = CreateFrame("Button", nil, standaloneFrame.optionsView, "UIPanelButtonTemplate")
  resetSessionBtn:SetSize(120, 22)
  resetSessionBtn:SetPoint("TOPLEFT", sessionHeader, "BOTTOMLEFT", 0, -10)
  resetSessionBtn:SetText("Reset Session")
  resetSessionBtn:SetScript("OnClick", function() PPT_ResetSession() end)
  
  local resetAllBtn = CreateFrame("Button", nil, standaloneFrame.optionsView, "UIPanelButtonTemplate")
  resetAllBtn:SetSize(120, 22)
  resetAllBtn:SetPoint("LEFT", resetSessionBtn, "RIGHT", 10, 0)
  resetAllBtn:SetText("Reset All Data")
  resetAllBtn:SetScript("OnClick", function() 
    StaticPopup_Show("PPT_RESET_ALL_CONFIRM")
  end)
  
  -- Function to show specific tab in standalone window
  function standaloneFrame:ShowTab(tabIndex)
    self.currentTab = tabIndex
    
    -- Update tab appearances
    for i, tab in ipairs(self.tabs) do
      if i == tabIndex then
        tab:SetAlpha(1)
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
    
    -- Update content based on tab
    if tabIndex == 1 then
      self:updateStats()
    elseif tabIndex == 2 then
      self:updateAchievements()
    end
  end
  
  -- Stats update function
  function standaloneFrame:updateStats()
    local coin = PPT_TotalCopper or 0
    local items = PPT_TotalItems or 0
    local attempts = PPT_TotalAttempts or 0
    local successes = PPT_SuccessfulAttempts or 0
    local fails = attempts - successes

    self.statCoin:SetText("Total Coinage: " .. coinsToString(coin))
    self.statItems:SetText("Total Items: " .. items)
    self.statAttempts:SetText("Attempts: " .. attempts)
    self.statSuccess:SetText("Successes: " .. successes)
    self.statFails:SetText("Fails: " .. fails)

    if attempts > 0 then
      self.statAvgAttempt:SetText("Avg/Attempt: " .. coinsToString(math.floor(coin / attempts)))
      if successes > 0 then
        self.statAvgSuccess:SetText("Avg/Success: " .. coinsToString(math.floor(coin / successes)))
      else
        self.statAvgSuccess:SetText("Avg/Success: 0c")
      end
    else
      self.statAvgAttempt:SetText("Avg/Attempt: 0c")
      self.statAvgSuccess:SetText("Avg/Success: 0c")
    end

    -- Update zone stats
    self:updateZoneStats()
  end
  
  -- Zone stats update
  function standaloneFrame:updateZoneStats()
    -- Clear existing zone displays
    for i = 1, 20 do
      local child = _G["PPT_StandaloneZoneEntry" .. i]
      if child then
        child:Hide()
      end
    end

    if not PPT_ZoneStats then return end

    -- Sort zones by total coin
    local sortedZones = {}
    for zone, data in pairs(PPT_ZoneStats) do
      table.insert(sortedZones, {zone = zone, coin = data.copper or 0, items = data.items or 0})
    end

    table.sort(sortedZones, function(a, b) return a.coin > b.coin end)

    local yOffset = 0
    local maxEntries = math.min(10, #sortedZones)

    for i = 1, maxEntries do
      local data = sortedZones[i]
      local entry = _G["PPT_StandaloneZoneEntry" .. i]
      
      if not entry then
        entry = self.zoneContent:CreateFontString("PPT_StandaloneZoneEntry" .. i, "ARTWORK", "GameFontHighlight")
        entry:SetPoint("TOPLEFT", self.zoneContent, "TOPLEFT", 0, -yOffset)
        entry:SetWidth(400)
        entry:SetJustifyH("LEFT")
      end
      
      entry:SetText(string.format("%s: %s (%d items)", data.zone, coinsToString(data.coin), data.items))
      entry:Show()
      yOffset = yOffset + 15
    end
    
    -- Update scroll child size
    self.zoneContent:SetHeight(math.max(140, yOffset))
  end
  
  -- Achievements update function
  function standaloneFrame:updateAchievements()
    -- Clear existing achievement displays
    for i = 1, 50 do
      local child = _G["PPT_StandaloneAchievementEntry" .. i]
      if child then
        child:Hide()
      end
      local categoryChild = _G["PPT_StandaloneAchievementCategory" .. i]
      if categoryChild then
        categoryChild:Hide()
      end
    end
    
    -- Check if achievements are available
    if not getAchievementCategories then
      local noData = self.achievementContent:CreateFontString("PPT_StandaloneAchievementNoData", "ARTWORK", "GameFontHighlight")
      noData:SetPoint("TOPLEFT", self.achievementContent, "TOPLEFT", 10, -10)
      noData:SetText("Achievement system not loaded yet...")
      return
    end
    
    local yOffset = 0
    local entryIndex = 1
    
    -- Get all categories
    local categories = getAchievementCategories()
    
    for _, categoryName in ipairs(categories) do
      local achievements = getAchievementsByCategory(categoryName)
      
      if achievements and #achievements > 0 then
        -- Category header
        local categoryHeader = _G["PPT_StandaloneAchievementCategory" .. entryIndex]
        if not categoryHeader then
          categoryHeader = self.achievementContent:CreateFontString("PPT_StandaloneAchievementCategory" .. entryIndex, "ARTWORK", "GameFontNormal")
          categoryHeader:SetPoint("TOPLEFT", self.achievementContent, "TOPLEFT", 0, -yOffset)
          categoryHeader:SetWidth(420)
          categoryHeader:SetJustifyH("LEFT")
        end
        
        categoryHeader:SetText(string.upper(categoryName:gsub("_", " ")))
        categoryHeader:SetTextColor(1, 0.82, 0) -- Gold
        categoryHeader:Show()
        yOffset = yOffset + 20
        entryIndex = entryIndex + 1
        
        -- Achievements in this category
        for _, achievement in ipairs(achievements) do
          local progress = getAchievementProgress(achievement.id)
          local isCompleted = isAchievementCompleted(achievement.id)
          local entryFrame = _G["PPT_StandaloneAchievementEntry" .. entryIndex]
          
          if not entryFrame then
            -- Create a frame container for the achievement entry
            entryFrame = CreateFrame("Frame", "PPT_StandaloneAchievementEntry" .. entryIndex, self.achievementContent)
            entryFrame:SetSize(460, 40) -- Fit within the scroll area properly
            entryFrame:SetPoint("TOPLEFT", self.achievementContent, "TOPLEFT", 5, -yOffset)
            
            -- Background for the achievement entry
            entryFrame.bg = entryFrame:CreateTexture(nil, "BACKGROUND")
            entryFrame.bg:SetAllPoints()
            entryFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
            
            -- Achievement icon
            entryFrame.icon = entryFrame:CreateTexture(nil, "ARTWORK")
            entryFrame.icon:SetSize(32, 32)
            entryFrame.icon:SetPoint("LEFT", entryFrame, "LEFT", 4, 0)
            
            -- Achievement name
            entryFrame.name = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            entryFrame.name:SetPoint("TOPLEFT", entryFrame.icon, "TOPRIGHT", 8, 0)
            entryFrame.name:SetWidth(280) -- Reduced to fit properly
            entryFrame.name:SetJustifyH("LEFT")
            
            -- Achievement description
            entryFrame.description = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            entryFrame.description:SetPoint("TOPLEFT", entryFrame.name, "BOTTOMLEFT", 0, -2)
            entryFrame.description:SetWidth(280) -- Reduced to fit properly
            entryFrame.description:SetJustifyH("LEFT")
            entryFrame.description:SetTextColor(0.8, 0.8, 0.8)
            
            -- Progress/status
            entryFrame.progress = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            entryFrame.progress:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -5, 0)
            entryFrame.progress:SetJustifyH("RIGHT")
          end
          
          -- Set achievement icon (remove the ugly background)
          if achievement.icon then
            entryFrame.icon:SetTexture(achievement.icon)
          else
            entryFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10") -- Default icon
          end
          
          -- Set achievement name with status color
          local nameText = achievement.name
          if isCompleted then
            entryFrame.name:SetText("|cff00ff00" .. nameText .. "|r")
            entryFrame.progress:SetText("|cff00ff00[COMPLETE]|r")
            entryFrame.progress:SetTextColor(0, 1, 0)
          else
            entryFrame.name:SetText(nameText)
            entryFrame.name:SetTextColor(1, 1, 1)
            local percentage = getAchievementCompletionPercentage(achievement.id)
            entryFrame.progress:SetText(string.format("|cffff8000[%d%%]|r\n%d/%d", percentage, progress, achievement.goal))
            entryFrame.progress:SetTextColor(1, 0.5, 0)
          end
          
          -- Set description
          entryFrame.description:SetText(achievement.description)
          
          entryFrame:Show()
          yOffset = yOffset + 45 -- More space for the larger entries
          entryIndex = entryIndex + 1
        end
        yOffset = yOffset + 15 -- Extra space between categories
      end
    end
    
    -- Update scroll child size
    self.achievementContent:SetHeight(math.max(450, yOffset))
  end
  
  -- Update function for options
  standaloneFrame.updateOptions = function(self)
    self.showTrackerCheck:SetChecked(IsCoinageTrackerEnabled())
    self.showMsg:SetChecked(PPT_ShowMsg)
    self.showSessionToasts:SetChecked(PPT_ShowSessionToasts)
    self.shareGroup:SetChecked(PPT_ShareGroup)
    self.debugMode:SetChecked(PPT_Debug)
    if self.alertOpacitySlider then
      self.alertOpacitySlider:SetValue((PPT_AlertOpacity or 80) / 100)
    end
  end
  
  -- Hide initially
  standaloneFrame:Hide()
  
  return standaloneFrame
end

-- Global function to show standalone options
function ShowStandaloneOptions()
  if not standaloneFrame then
    CreateStandaloneOptionsWindow()
  end
  
  standaloneFrame:updateOptions()
  standaloneFrame:ShowTab(1) -- Default to Report tab
  standaloneFrame:Show()
end

-- Global function to show achievements tab specifically
function ShowStandaloneAchievements()
  if not standaloneFrame then
    CreateStandaloneOptionsWindow()
  end
  
  standaloneFrame:updateOptions()
  standaloneFrame:ShowTab(2) -- Show Achievements tab
  standaloneFrame:Show()
end

-- Global function to hide standalone options
function HideStandaloneOptions()
  if standaloneFrame then
    standaloneFrame:Hide()
  end
end

-- Global function to toggle standalone options
function ToggleStandaloneOptions()
  if standaloneFrame and standaloneFrame:IsShown() then
    HideStandaloneOptions()
  else
    ShowStandaloneOptions()
  end
end
