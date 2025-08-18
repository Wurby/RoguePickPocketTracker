-- Achievements.lua
-- Achievement system for RoguePickPocketTracker

------------------------------------------------------------
--                   ACHIEVEMENT DATA
------------------------------------------------------------

-- Achievement definitions with funny names and difficulty scaling
local ACHIEVEMENT_DATA = {
  -- Mobs pickpocketed per session: 1, 2, 5, 10, 25
  session_mobs = {
    {id = "session_mobs_1", name = "Finger Exercises", description = "Pick pocket 1 mob in a single session", goal = 1, icon = "Interface\\Icons\\INV_Misc_Bag_10"},
    {id = "session_mobs_2", name = "Double Trouble", description = "Pick pocket 2 mobs in a single session", goal = 2, icon = "Interface\\Icons\\INV_Misc_Bag_10"},
    {id = "session_mobs_5", name = "Handful of Coins", description = "Pick pocket 5 mobs in a single session", goal = 5, icon = "Interface\\Icons\\INV_Misc_Bag_10"},
    {id = "session_mobs_10", name = "Master Thief", description = "Pick pocket 10 mobs in a single session", goal = 10, icon = "Interface\\Icons\\INV_Misc_Bag_10"},
    {id = "session_mobs_25", name = "Shadow Lord", description = "Pick pocket 25 mobs in a single session", goal = 25, icon = "Interface\\Icons\\INV_Misc_Bag_10"}
  },
  
  -- Items pick pocketed per session: 1, 2, 5
  session_items = {
    {id = "session_items_1", name = "Shiny Trinket", description = "Obtain 1 item in a single session", goal = 1, icon = "Interface\\Icons\\INV_Misc_Bag_08"},
    {id = "session_items_2", name = "Pocket Full", description = "Obtain 2 items in a single session", goal = 2, icon = "Interface\\Icons\\INV_Misc_Bag_08"},
    {id = "session_items_5", name = "Treasure Hunter", description = "Obtain 5 items in a single session", goal = 5, icon = "Interface\\Icons\\INV_Misc_Bag_08"}
  },
  
  -- Total mobs pick pocketed: 10, 100, 1000, 10000
  total_mobs = {
    {id = "total_mobs_10", name = "Getting Started", description = "Pick pocket 10 mobs total", goal = 10, icon = "Interface\\Icons\\Achievement_BG_killxenemies_generalsroom"},
    {id = "total_mobs_100", name = "Sticky Fingers", description = "Pick pocket 100 mobs total", goal = 100, icon = "Interface\\Icons\\Achievement_BG_killxenemies_generalsroom"},
    {id = "total_mobs_1000", name = "Professional Pickpocket", description = "Pick pocket 1,000 mobs total", goal = 1000, icon = "Interface\\Icons\\Achievement_BG_killxenemies_generalsroom"},
    {id = "total_mobs_10000", name = "Legendary Thief", description = "Pick pocket 10,000 mobs total", goal = 10000, icon = "Interface\\Icons\\Achievement_BG_killxenemies_generalsroom"}
  },
  
  -- Money pick pocketed: 1s, 1g, 10g, 100g (in copper)
  total_money = {
    {id = "total_money_100", name = "Coin Collector", description = "Accumulate 1 silver from pickpocketing", goal = 100, icon = "Interface\\Icons\\INV_Misc_Coin_02"},
    {id = "total_money_10000", name = "Gold Digger", description = "Accumulate 1 gold from pickpocketing", goal = 10000, icon = "Interface\\Icons\\INV_Misc_Coin_01"},
    {id = "total_money_100000", name = "Fortune Hunter", description = "Accumulate 10 gold from pickpocketing", goal = 100000, icon = "Interface\\Icons\\INV_Misc_Coin_01"},
    {id = "total_money_1000000", name = "Fortune Hoarder", description = "Accumulate 100 gold from pickpocketing", goal = 1000000, icon = "Interface\\Icons\\INV_Misc_Coin_01"},
    {id = "total_money_10000000", name = "Scrooge McDuck", description = "Accumulate 1000 gold from pickpocketing", goal = 10000000, icon = "Interface\\Icons\\INV_Misc_Coin_01"}
  },
  
  -- Total items pick pocketed: 1, 5, 10, 100, 1000
  total_items = {
    {id = "total_items_1", name = "First Find", description = "Obtain your first item from pickpocketing", goal = 1, icon = "Interface\\Icons\\INV_Misc_Note_01"},
    {id = "total_items_5", name = "Pack Rat", description = "Obtain 5 items from pickpocketing", goal = 5, icon = "Interface\\Icons\\INV_Misc_Note_01"},
    {id = "total_items_10", name = "Collector", description = "Obtain 10 items from pickpocketing", goal = 10, icon = "Interface\\Icons\\INV_Misc_Note_01"},
    {id = "total_items_100", name = "Hoarder", description = "Obtain 100 items from pickpocketing", goal = 100, icon = "Interface\\Icons\\INV_Misc_Note_01"},
    {id = "total_items_1000", name = "Museum Curator", description = "Obtain 1,000 items from pickpocketing", goal = 1000, icon = "Interface\\Icons\\INV_Misc_Note_01"}
  },
  
  -- Zones pick pocketed: 1, 5, 10, 20
  zones_visited = {
    {id = "zones_1", name = "Tourist", description = "Pick pocket in 1 zone", goal = 1, icon = "Interface\\Icons\\INV_Misc_Map_01"},
    {id = "zones_5", name = "Explorer", description = "Pick pocket in 5 zones", goal = 5, icon = "Interface\\Icons\\INV_Misc_Map_01"},
    {id = "zones_10", name = "World Traveler", description = "Pick pocket in 10 zones", goal = 10, icon = "Interface\\Icons\\INV_Misc_Map_01"},
    {id = "zones_20", name = "Globe Trotter", description = "Pick pocket in 20 zones", goal = 20, icon = "Interface\\Icons\\INV_Misc_Map_01"}
  }
}

------------------------------------------------------------
--                   ACHIEVEMENT SYSTEM
------------------------------------------------------------

-- Initialize achievement storage
PPT_Achievements = PPT_Achievements or {}
PPT_CompletedAchievements = PPT_CompletedAchievements or {}

-- Reset session achievement progress (called when a new session starts)
function resetSessionAchievements()
  DebugPrint("resetSessionAchievements called - preserving best progress")
  
  -- Don't reset session achievements to 0 - preserve the best progress reached
  -- Session achievements should show the highest progress achieved in any session
  -- until the achievement is completed
  
  -- Only reset if the achievement is already completed (so it can be earned again)
  for _, achievement in ipairs(ACHIEVEMENT_DATA.session_mobs) do
    if isAchievementCompleted(achievement.id) then
      PPT_Achievements[achievement.id] = 0
      DebugPrint("Reset completed session achievement: %s = 0", achievement.id)
    else
      DebugPrint("Preserving session achievement progress: %s = %d", achievement.id, PPT_Achievements[achievement.id] or 0)
    end
  end
  
  for _, achievement in ipairs(ACHIEVEMENT_DATA.session_items) do
    if isAchievementCompleted(achievement.id) then
      PPT_Achievements[achievement.id] = 0
      DebugPrint("Reset completed session achievement: %s = 0", achievement.id)
    else
      DebugPrint("Preserving session achievement progress: %s = %d", achievement.id, PPT_Achievements[achievement.id] or 0)
    end
  end
end

-- Helper function to check if a target gives XP
function isTargetXPEligible(targetGUID)
  if not targetGUID then return false end
  
  -- Get player level
  local playerLevel = UnitLevel("player")
  if not playerLevel then return false end
  
  -- Try to get target level using GUID
  local targetLevel = nil
  
  -- First, try to get it if we have the target selected
  if UnitGUID("target") == targetGUID then
    targetLevel = UnitLevel("target")
  end
  
  -- If we don't have target level, we'll be conservative and allow it
  -- This prevents false negatives when we can't determine the level
  if not targetLevel or targetLevel == -1 then
    return true  -- Conservative approach - allow if we can't determine
  end
  
  -- Check if target is within XP range (WoW Classic rules)
  local levelDiff = playerLevel - targetLevel
  
  -- In Classic, you get XP from mobs up to 7-8 levels below you (green mobs)
  -- Gray mobs (9+ levels below) give no XP
  return levelDiff <= 8
end

-- Get all achievement definitions in a flat list
function getAchievementsList()
  local achievements = {}
  for category, achList in pairs(ACHIEVEMENT_DATA) do
    for _, achievement in ipairs(achList) do
      achievement.category = category
      table.insert(achievements, achievement)
    end
  end
  return achievements
end

-- Get achievement progress for a specific achievement ID
function getAchievementProgress(achievementId)
  return PPT_Achievements[achievementId] or 0
end

-- Check if achievement is completed
function isAchievementCompleted(achievementId)
  return PPT_CompletedAchievements[achievementId] == true
end

-- Update achievement progress
function updateAchievementProgress(achievementId, newProgress)
  local oldProgress = PPT_Achievements[achievementId] or 0
  PPT_Achievements[achievementId] = newProgress
  
  DebugPrint("Achievement progress: %s = %d (was %d)", achievementId, newProgress, oldProgress)
  
  -- Check if achievement was just completed
  local achievement = findAchievementById(achievementId)
  if achievement and newProgress >= achievement.goal and not isAchievementCompleted(achievementId) then
    DebugPrint("Achievement completed: %s", achievementId)
    completeAchievement(achievementId, achievement)
  elseif achievement then
    DebugPrint("Achievement progress: %s %d/%d", achievement.name, newProgress, achievement.goal)
  end
end

-- Find achievement data by ID
function findAchievementById(achievementId)
  for category, achList in pairs(ACHIEVEMENT_DATA) do
    for _, achievement in ipairs(achList) do
      if achievement.id == achievementId then
        return achievement
      end
    end
  end
  return nil
end

-- Mark achievement as completed and celebrate
function completeAchievement(achievementId, achievement)
  PPT_CompletedAchievements[achievementId] = true
  celebrateAchievement(achievement)
  DebugPrint("Achievement completed: %s", achievement.name)
end

-- Celebration helper function
function celebrateAchievement(achievement)
  -- Show fancy achievement alert frame (no chat spam)
  showAchievementAlert(achievement)
  
  -- Play sound if available
  if PlaySoundFile then
    PlaySoundFile("Interface\\AddOns\\RoguePickPocketTracker\\Sounds\\Achievement.ogg")
  elseif PlaySound then
    PlaySound("LevelUp")
  end
end

-- Achievement alert queue system
local achievementQueue = {}
local isShowingAlert = false

-- Create achievement alert frame
local achievementAlert = nil

function showAchievementAlert(achievement)
  DebugPrint("showAchievementAlert called for: %s", achievement.name)
  
  -- Add to queue
  table.insert(achievementQueue, achievement)
  
  -- Start processing queue if not already showing
  if not isShowingAlert then
    processAchievementQueue()
  end
end

function processAchievementQueue()
  if #achievementQueue == 0 then
    isShowingAlert = false
    return
  end
  
  isShowingAlert = true
  local achievement = table.remove(achievementQueue, 1) -- Get first in queue
  
  DebugPrint("Processing achievement from queue: %s", achievement.name)
  
  -- Create the alert frame if it doesn't exist
  if not achievementAlert then
    DebugPrint("Creating new achievement alert frame")
    achievementAlert = CreateFrame("Frame", "PPT_AchievementAlert", UIParent)
    achievementAlert:SetSize(420, 90)
    achievementAlert:SetPoint("TOP", UIParent, "TOP", 0, -100)
    achievementAlert:SetFrameStrata("FULLSCREEN_DIALOG")
    achievementAlert:SetFrameLevel(100)
    
    -- Main background (dark grey/black)
    local bg = achievementAlert:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.15, 1) -- Dark grey
    achievementAlert.bg = bg
    
    -- Create border effect with rounded corners using multiple textures
    local borderSize = 2
    
    -- Top border
    local borderTop = achievementAlert:CreateTexture(nil, "BORDER")
    borderTop:SetHeight(borderSize)
    borderTop:SetPoint("TOPLEFT", borderSize, -borderSize)
    borderTop:SetPoint("TOPRIGHT", -borderSize, -borderSize)
    borderTop:SetColorTexture(0.6, 0.6, 0.6, 1) -- Grey border
    
    -- Bottom border
    local borderBottom = achievementAlert:CreateTexture(nil, "BORDER")
    borderBottom:SetHeight(borderSize)
    borderBottom:SetPoint("BOTTOMLEFT", borderSize, borderSize)
    borderBottom:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
    borderBottom:SetColorTexture(0.6, 0.6, 0.6, 1)
    
    -- Left border
    local borderLeft = achievementAlert:CreateTexture(nil, "BORDER")
    borderLeft:SetWidth(borderSize)
    borderLeft:SetPoint("TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
    borderLeft:SetColorTexture(0.6, 0.6, 0.6, 1)
    
    -- Right border
    local borderRight = achievementAlert:CreateTexture(nil, "BORDER")
    borderRight:SetWidth(borderSize)
    borderRight:SetPoint("TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
    borderRight:SetColorTexture(0.6, 0.6, 0.6, 1)
    
    -- Corner pieces for rounded effect
    local cornerSize = 6
    
    -- Top-left corner
    local cornerTL = achievementAlert:CreateTexture(nil, "ARTWORK")
    cornerTL:SetSize(cornerSize, cornerSize)
    cornerTL:SetPoint("TOPLEFT", 0, 0)
    cornerTL:SetColorTexture(0.6, 0.6, 0.6, 1)
    
    -- Top-right corner
    local cornerTR = achievementAlert:CreateTexture(nil, "ARTWORK")
    cornerTR:SetSize(cornerSize, cornerSize)
    cornerTR:SetPoint("TOPRIGHT", 0, 0)
    cornerTR:SetColorTexture(0.6, 0.6, 0.6, 1)
    
    -- Bottom-left corner
    local cornerBL = achievementAlert:CreateTexture(nil, "ARTWORK")
    cornerBL:SetSize(cornerSize, cornerSize)
    cornerBL:SetPoint("BOTTOMLEFT", 0, 0)
    cornerBL:SetColorTexture(0.6, 0.6, 0.6, 1)
    
    -- Bottom-right corner
    local cornerBR = achievementAlert:CreateTexture(nil, "ARTWORK")
    cornerBR:SetSize(cornerSize, cornerSize)
    cornerBR:SetPoint("BOTTOMRIGHT", 0, 0)
    cornerBR:SetColorTexture(0.6, 0.6, 0.6, 1)
    
    -- Subtle inner glow
    local innerGlow = achievementAlert:CreateTexture(nil, "BACKGROUND", nil, 1)
    innerGlow:SetPoint("TOPLEFT", 4, -4)
    innerGlow:SetPoint("BOTTOMRIGHT", -4, 4)
    innerGlow:SetColorTexture(1, 0.84, 0, 0.1) -- Very subtle gold glow
    
    -- Icon
    local icon = achievementAlert:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48)
    icon:SetPoint("LEFT", achievementAlert, "LEFT", 20, 0)
    achievementAlert.icon = icon
    
    -- Title text
    local title = achievementAlert:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 15, 8)
    title:SetPoint("RIGHT", achievementAlert, "RIGHT", -20, 0)
    title:SetJustifyH("LEFT")
    title:SetText("Achievement Unlocked!")
    title:SetTextColor(1, 0.84, 0) -- Gold
    achievementAlert.title = title
    
    -- Achievement name
    local name = achievementAlert:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    name:SetPoint("RIGHT", achievementAlert, "RIGHT", -20, 0)
    name:SetJustifyH("LEFT")
    name:SetTextColor(1, 1, 1) -- White
    achievementAlert.name = name
    
    -- Description
    local desc = achievementAlert:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("RIGHT", achievementAlert, "RIGHT", -20, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.8, 0.8, 0.8) -- Light grey
    achievementAlert.desc = desc
    
    -- Store border elements for opacity changes
    achievementAlert.borders = {borderTop, borderBottom, borderLeft, borderRight, cornerTL, cornerTR, cornerBL, cornerBR}
    achievementAlert.innerGlow = innerGlow
    
    -- Hide initially
    achievementAlert:Hide()
    achievementAlert:SetAlpha(0)
    DebugPrint("Achievement alert frame created and hidden")
  end
  
  -- Set achievement data
  achievementAlert.icon:SetTexture(achievement.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
  achievementAlert.name:SetText(achievement.name)
  achievementAlert.desc:SetText(achievement.description)
  
  -- Apply current opacity setting
  local opacity = (PPT_AlertOpacity or 80) / 100
  
  DebugPrint("Achievement alert data set, showing frame with opacity: %d%%", PPT_AlertOpacity or 80)
  
  -- Show with simple fade animation
  achievementAlert:Show()
  achievementAlert:SetAlpha(0)
  
  -- Simple timer-based fade in/out instead of animation groups
  local fadeStep = 0
  local maxSteps = 10
  local holdTime = 30 -- Hold for 3 seconds (30 * 0.1)
  
  local function fadeTimer()
    if fadeStep < maxSteps then
      -- Fade in
      fadeStep = fadeStep + 1
      achievementAlert:SetAlpha((fadeStep / maxSteps) * opacity)
      -- Use C_Timer if available, otherwise use a simple OnUpdate script
      if C_Timer and C_Timer.After then
        C_Timer.After(0.05, fadeTimer)
      else
        -- Fallback for older WoW versions
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.05 then
            self:SetScript("OnUpdate", nil)
            fadeTimer()
          end
        end)
      end
    elseif fadeStep < maxSteps + holdTime then
      -- Hold
      fadeStep = fadeStep + 1
      if C_Timer and C_Timer.After then
        C_Timer.After(0.1, fadeTimer)
      else
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.1 then
            self:SetScript("OnUpdate", nil)
            fadeTimer()
          end
        end)
      end
    elseif fadeStep < maxSteps + holdTime + maxSteps then
      -- Fade out
      fadeStep = fadeStep + 1
      local fadeOutStep = maxSteps + holdTime + maxSteps - fadeStep
      achievementAlert:SetAlpha((fadeOutStep / maxSteps) * opacity)
      if C_Timer and C_Timer.After then
        C_Timer.After(0.05, fadeTimer)
      else
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.05 then
            self:SetScript("OnUpdate", nil)
            fadeTimer()
          end
        end)
      end
    else
      -- Hide and process next in queue
      achievementAlert:Hide()
      DebugPrint("Achievement alert hidden, processing next in queue")
      
      -- Process next achievement in queue after a short delay
      if C_Timer and C_Timer.After then
        C_Timer.After(0.5, processAchievementQueue)
      else
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.5 then
            self:SetScript("OnUpdate", nil)
            processAchievementQueue()
          end
        end)
      end
    end
  end
  
  DebugPrint("Starting achievement alert fade timer")
  fadeTimer()
end

------------------------------------------------------------
--                   PROGRESS TRACKING
------------------------------------------------------------

-- Update all relevant achievements based on current statistics
function updateAllAchievements()
  -- Session-based achievements (called after each session)
  updateSessionAchievements()
  
  -- Total-based achievements
  updateTotalAchievements()
  
  -- Zone-based achievements
  updateZoneAchievements()
end

-- Update session-based achievements
function updateSessionAchievements()
  DebugPrint("updateSessionAchievements called")
  
  -- Count unique XP-eligible targets this session
  local sessionMobCount = 0
  if attemptedGUIDs then
    for guid, locationData in pairs(attemptedGUIDs) do
      if guid and guid ~= "" and isTargetXPEligible(guid) then
        sessionMobCount = sessionMobCount + 1
        DebugPrint("XP-eligible mob counted: %s", tostring(guid))
      elseif guid and guid ~= "" then
        DebugPrint("Non-XP-eligible mob skipped: %s", tostring(guid))
      end
    end
  end
  
  DebugPrint("Session XP-eligible mob count: %d", sessionMobCount)
  DebugPrint("Session items count: %d", sessionItemsCount or 0)
  
  -- Session mobs achievements - update progress to show the best attempt
  for _, achievement in ipairs(ACHIEVEMENT_DATA.session_mobs) do
    local currentBest = PPT_Achievements[achievement.id] or 0
    if sessionMobCount > currentBest then
      DebugPrint("New best session mob progress: %s (%d > %d)", achievement.id, sessionMobCount, currentBest)
      updateAchievementProgress(achievement.id, sessionMobCount)
    else
      DebugPrint("Session mob progress not better than best: %s (%d <= %d)", achievement.id, sessionMobCount, currentBest)
    end
  end
  
  -- Session items achievements - update progress to show the best attempt
  if sessionItemsCount then
    for _, achievement in ipairs(ACHIEVEMENT_DATA.session_items) do
      local currentBest = PPT_Achievements[achievement.id] or 0
      if sessionItemsCount > currentBest then
        DebugPrint("New best session item progress: %s (%d > %d)", achievement.id, sessionItemsCount, currentBest)
        updateAchievementProgress(achievement.id, sessionItemsCount)
      else
        DebugPrint("Session item progress not better than best: %s (%d <= %d)", achievement.id, sessionItemsCount, currentBest)
      end
    end
  end
end

-- Update total-based achievements
function updateTotalAchievements()
  DebugPrint("updateTotalAchievements called")
  DebugPrint("PPT_SuccessfulAttempts: %d, PPT_TotalCopper: %d, PPT_TotalItems: %d", 
             PPT_SuccessfulAttempts or 0, PPT_TotalCopper or 0, PPT_TotalItems or 0)
  
  -- Total mobs achievements
  for _, achievement in ipairs(ACHIEVEMENT_DATA.total_mobs) do
    updateAchievementProgress(achievement.id, PPT_SuccessfulAttempts)
  end
  
  -- Total money achievements
  for _, achievement in ipairs(ACHIEVEMENT_DATA.total_money) do
    updateAchievementProgress(achievement.id, PPT_TotalCopper)
  end
  
  -- Total items achievements
  for _, achievement in ipairs(ACHIEVEMENT_DATA.total_items) do
    updateAchievementProgress(achievement.id, PPT_TotalItems)
  end
end

-- Update zone-based achievements
function updateZoneAchievements()
  -- Count zones with successful pickpockets
  local zonesWithPickpockets = 0
  if PPT_ZoneStats then
    for zone, stats in pairs(PPT_ZoneStats) do
      if stats.successes and stats.successes > 0 then
        zonesWithPickpockets = zonesWithPickpockets + 1
      end
    end
  end
  
  -- Zone achievements
  for _, achievement in ipairs(ACHIEVEMENT_DATA.zones_visited) do
    updateAchievementProgress(achievement.id, zonesWithPickpockets)
  end
end

-- Hook into session finalization to update achievements
function hookSessionFinalization()
  DebugPrint("hookSessionFinalization called")
  
  -- Only hook if finalizeSession exists and we haven't hooked it yet
  if finalizeSession and not _PPT_AchievementHookInstalled then
    local originalFinalizeSession = finalizeSession
    
    function finalizeSession(reasonIfZero)
      DebugPrint("finalizeSession called with reason: %s", tostring(reasonIfZero))
      DebugPrint("sessionHadPick: %s, sessionActive: %s", tostring(sessionHadPick), tostring(sessionActive))
      DebugPrint("sessionCopper: %d, sessionItemsCount: %d", sessionCopper or 0, sessionItemsCount or 0)
      
      -- Capture session state BEFORE calling original function
      local capturedSessionHadPick = sessionHadPick
      local capturedSessionActive = sessionActive
      local capturedSessionCopper = sessionCopper
      local capturedSessionItemsCount = sessionItemsCount
      local capturedAttemptedGUIDs = attemptedGUIDs
      
      -- Call original function
      originalFinalizeSession(reasonIfZero)
      
      -- Update achievements using captured state
      DebugPrint("Using captured session state - sessionHadPick: %s", tostring(capturedSessionHadPick))
      if capturedSessionHadPick then
        DebugPrint("Session had pick, updating achievements")
        -- Temporarily restore session state for achievement calculations
        local oldSessionHadPick = sessionHadPick
        local oldAttemptedGUIDs = attemptedGUIDs
        local oldSessionItemsCount = sessionItemsCount
        
        sessionHadPick = capturedSessionHadPick
        attemptedGUIDs = capturedAttemptedGUIDs or {}
        sessionItemsCount = capturedSessionItemsCount or 0
        
        updateAllAchievements()
        
        -- Restore current state
        sessionHadPick = oldSessionHadPick
        attemptedGUIDs = oldAttemptedGUIDs
        sessionItemsCount = oldSessionItemsCount
      else
        DebugPrint("Session had no pick, skipping achievements")
        -- But still update total achievements in case there were changes
        updateTotalAchievements()
      end
    end
    
    _PPT_AchievementHookInstalled = true
    DebugPrint("Achievement hook installed for finalizeSession")
  elseif not finalizeSession then
    DebugPrint("finalizeSession function not found - will retry later")
  elseif _PPT_AchievementHookInstalled then
    DebugPrint("Achievement hook already installed")
  end
end

-- Alternative hook method - try to hook when the session module is loaded
function tryHookLater()
  if finalizeSession and not _PPT_AchievementHookInstalled then
    hookSessionFinalization()
    return true
  end
  return false
end

-- Separate function to update only total achievements (for real-time updates)
function updateTotalAchievementsOnly()
  DebugPrint("updateTotalAchievementsOnly called")
  
  -- Total mobs achievements
  for _, achievement in ipairs(ACHIEVEMENT_DATA.total_mobs) do
    updateAchievementProgress(achievement.id, PPT_SuccessfulAttempts)
  end
  
  -- Total money achievements
  for _, achievement in ipairs(ACHIEVEMENT_DATA.total_money) do
    updateAchievementProgress(achievement.id, PPT_TotalCopper)
  end
  
  -- Total items achievements
  for _, achievement in ipairs(ACHIEVEMENT_DATA.total_items) do
    updateAchievementProgress(achievement.id, PPT_TotalItems)
  end
  
  -- Zone achievements
  updateZoneAchievements()
end

------------------------------------------------------------
--                   UTILITY FUNCTIONS
------------------------------------------------------------

-- Get completion percentage for an achievement
function getAchievementCompletionPercentage(achievementId)
  local achievement = findAchievementById(achievementId)
  if not achievement then return 0 end
  
  local progress = getAchievementProgress(achievementId)
  return math.min(100, math.floor((progress / achievement.goal) * 100))
end

-- Get achievements by category
function getAchievementsByCategory(category)
  return ACHIEVEMENT_DATA[category] or {}
end

-- Get all categories
function getAchievementCategories()
  local categories = {}
  for category, _ in pairs(ACHIEVEMENT_DATA) do
    table.insert(categories, category)
  end
  table.sort(categories)
  return categories
end

-- Get completed achievements count
function getCompletedAchievementsCount()
  local count = 0
  for _, _ in pairs(PPT_CompletedAchievements) do
    count = count + 1
  end
  return count
end

-- Get total achievements count
function getTotalAchievementsCount()
  local count = 0
  for _, achList in pairs(ACHIEVEMENT_DATA) do
    count = count + #achList
  end
  return count
end

-- Format achievement progress text
function formatAchievementProgress(achievementId)
  local achievement = findAchievementById(achievementId)
  if not achievement then return "Unknown" end
  
  local progress = getAchievementProgress(achievementId)
  local goal = achievement.goal
  
  -- Format based on achievement type
  if achievement.category == "total_money" then
    return string.format("%s / %s", coinsToString(progress), coinsToString(goal))
  else
    return string.format("%d / %d", progress, goal)
  end
end
