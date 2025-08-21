-- Events.lua
-- Frame creation, event handling, and slash commands for RoguePickPocketTracker

------------------------------------------------------------
--                       FRAME / EVENTS
------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_MONEY")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Combat end
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Combat start

local function SafeRegister(evt) pcall(frame.RegisterEvent, frame, evt) end
SafeRegister("MERCHANT_SHOW"); SafeRegister("MAIL_SHOW"); SafeRegister("TAXIMAP_OPENED")

-- Poll (money deltas + grace timeout + tracking updates)
local pollAccum = 0
local trackingUpdateAccum = 0
local sessionUpdateAccum = 0
frame:SetScript("OnUpdate", function(_, elapsed)
  trackingUpdateAccum = trackingUpdateAccum + elapsed
  sessionUpdateAccum = sessionUpdateAccum + elapsed
  
  -- Update tracking display every 0.5 seconds when tracking is active
  if PPT_TrackingActive and trackingUpdateAccum >= 0.5 then
    trackingUpdateAccum = 0
    if UpdateCoinageTracker then
      UpdateCoinageTracker()
    end
  end
  
  -- Update session display every 1 second when session is active
  if sessionActive and sessionUpdateAccum >= 1.0 then
    sessionUpdateAccum = 0
    if UpdateCoinageTracker then
      UpdateCoinageTracker()
    end
  end
  
  if not sessionActive then return end
  pollAccum = pollAccum + elapsed
  
  -- Session timeout after grace period - end session regardless of combat
  if (not inStealth) and windowEndsAt > 0 and GetTime() >= windowEndsAt then
    -- Session timeout - finalize session (toasts will be delayed if in combat)
    finalizeSession("timeout")
    return
  end
  if pollAccum >= POLL_INTERVAL then
    pollAccum = 0
    if not uiRecentlyOpened() then
      local now = GetMoney()
      if lastMoney and now > lastMoney then
        local diff = now - lastMoney
        DebugPrint("Money(poll): +%s", coinsToString(diff))
        sessionCopper = sessionCopper + diff
        PPT_TotalCopper = PPT_TotalCopper + diff
        UpdateCoinageTracker()
        mirroredCopperThisSession = mirroredCopperThisSession + diff
      end
      lastMoney = now
    end
  end
end)

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local addonName = ...
    if addonName == "RoguePickPocketTracker" then
      -- Perform data migration first
      migrateData()
      
      -- Initialize achievement system
      if hookSessionFinalization then
        hookSessionFinalization()
      end
      
      -- Update achievements with current data
      if updateAllAchievements then
        updateAllAchievements()
      end
      
      -- Initialize UI
      if UpdateCoinageTracker then
        UpdateCoinageTracker()
      end
      
      DebugPrint(("SV @load: copper=%d attempts=%d succ=%d items=%d version=%d")
        :format(PPT_TotalCopper or -1, PPT_TotalAttempts or -1, PPT_SuccessfulAttempts or -1, PPT_TotalItems or -1, PPT_DataVersion or -1))
    end

  elseif event == "PLAYER_ENTERING_WORLD" then
    DebugPrint("PLAYER_ENTERING_WORLD - initializing session state")
    playerGUID = UnitGUID("player")
    inStealth, sessionActive = false, false
    
    -- Reset session variables to prevent leftover data from causing incorrect totals
    if resetSession then
      resetSession()
    end
    
    lastMoney = GetMoney()
    DebugPrint("PLAYER_ENTERING_WORLD - lastMoney set to: %s", coinsToString(lastMoney))
    if getStealthFlag and getStealthFlag() then onStealthGained() end
    
    -- Ensure UI is visible if enabled
    if UpdateCoinageTracker then
      UpdateCoinageTracker()
    end
    
    -- Try to hook achievements if not already done
    if tryHookLater and not _PPT_AchievementHookInstalled then
      tryHookLater()
    end

  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unitTag, _, spellID = ...
    if unitTag == "player" and spellID == PICK_ID then
      if not sessionActive then
        if startSession then startSession() end
        if getStealthFlag and not getStealthFlag() then windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END end
      end
      sessionHadPick = true
      DebugPrint("Pick: UNIT_SPELLCAST_SUCCEEDED")
    end

  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, sub, _, srcGUID, _, _, _, dstGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if not playerGUID then return end

    if dstGUID == playerGUID and STEALTH_IDS[spellID] then
      if sub == "SPELL_AURA_APPLIED" and onStealthGained then onStealthGained(); return
      elseif sub == "SPELL_AURA_REMOVED" and onStealthLost then onStealthLost(); return end
    end

    if sub == "SPELL_CAST_SUCCESS" and srcGUID == playerGUID and spellID == PICK_ID then
      if not sessionActive then
        if startSession then startSession() end
        if getStealthFlag and not getStealthFlag() then windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END end
      end
      sessionHadPick = true
      if dstGUID and not attemptedGUIDs[dstGUID] then
        attemptedGUIDs[dstGUID] = true
        PPT_TotalAttempts = PPT_TotalAttempts + 1
        
        -- Increment session mob count for unique targets
        sessionMobCount = sessionMobCount + 1
        DebugPrint("Pick: session mob count now %d", sessionMobCount)
        
        -- Update achievements when attempts are made
        if updateAllAchievements then
          updateAllAchievements()
        end
        
        -- Record location-based attempt immediately using CURRENT location (not session location)
        local currentZone = getCurrentZone()
        local currentLocation = getCurrentLocation()
        recordPickPocketAttempt(currentZone, currentLocation, false, 0, 0) -- Record as failed initially
        
        -- Store this attempt's location for potential success update later
        attemptedGUIDs[dstGUID] = {zone = currentZone, location = currentLocation}
        
        DebugPrint("Pick: attempt recorded for %s at %s", tostring(dstGUID), currentLocation)
      else
        DebugPrint("Pick: duplicate attempt ignored")
      end
    end

  elseif event == "MERCHANT_SHOW" or event == "MAIL_SHOW" or event == "TAXIMAP_OPENED" then
    markUI(event)

  elseif event == "CHAT_MSG_MONEY" then
    if sessionActive and sessionHadPick and not uiRecentlyOpened() then
      local msg = ...
      local copper = parseMoneyText(unwrapMoneyText(msg))
      if copper and copper > 0 then
        DebugPrint("Money(chat): +%s", coinsToString(copper))
        sessionCopper = sessionCopper + copper
        PPT_TotalCopper = PPT_TotalCopper + copper
        UpdateCoinageTracker()
        mirroredCopperThisSession = mirroredCopperThisSession + copper
        if not inStealth then windowEndsAt = math.max(windowEndsAt, GetTime() + 0.25) end
        
        -- Update achievements when money is gained
        if updateAllAchievements then
          updateAllAchievements()
        end
      end
    end

  elseif event == "CHAT_MSG_LOOT" then
    if sessionActive and sessionHadPick and not uiRecentlyOpened() then
      local msg = ...
      recordItemLootFromMessage(msg)
      
      -- Update achievements when items are looted
      if updateAllAchievements then
        updateAllAchievements()
      end
    end

  elseif event == "PLAYER_MONEY" then
    if sessionActive and sessionHadPick and not uiRecentlyOpened() then
      local now = GetMoney()
      if lastMoney and now > lastMoney then
        local diff = now - lastMoney
        DebugPrint("Money(event): +%s", coinsToString(diff))
        sessionCopper = sessionCopper + diff
        PPT_TotalCopper = PPT_TotalCopper + diff
        UpdateCoinageTracker()
        mirroredCopperThisSession = mirroredCopperThisSession + diff
        
        -- Update achievements when money is gained
        if updateAllAchievements then
          updateAllAchievements()
        end
      end
      lastMoney = now
    else
      -- Always update lastMoney even if not tracking to prevent false positives
      lastMoney = GetMoney()
    end

  elseif event == "PLAYER_LOGOUT" then
    sweepMoneyNow()
    if sessionActive then
      finalizeSession("logout")
    end
    DebugPrint(("SV @logout: copper=%d attempts=%d succ=%d items=%d")
      :format(PPT_TotalCopper or -1, PPT_TotalAttempts or -1, PPT_SuccessfulAttempts or -1, PPT_TotalItems or -1))
      
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Combat ended - show any pending toasts
    if pendingSessionToast then
      DebugPrint("Combat ended - showing pending session toast")
      if ShowSessionToast then
        ShowSessionToast(true) -- Use stored session data
      else
        -- Fallback to manual toast creation
        ShowSessionToast_Legacy(PPT_LastSessionData)
      end
      pendingSessionToast = false
      sessionToastShown = true
    end
    
    -- Clear session ended flag and update UI border color
    if sessionJustEnded ~= nil then -- Check if UI.lua is loaded
      sessionJustEnded = false
      if UpdateCoinageBorderColor then
        UpdateCoinageBorderColor()
      end
    end
    
    -- Process post-combat toast queue
    if ProcessPostCombatToastQueue then
      ProcessPostCombatToastQueue()
    end
    
    -- Show any pending toasts that were queued during combat (legacy support)
    if pendingCombatToasts and #pendingCombatToasts > 0 then
      for _, toastData in ipairs(pendingCombatToasts) do
        DebugPrint("Combat ended - showing pending %s toast", toastData.type or "unknown")
        -- Show the toast using legacy function
        if toastData.type == "session" then
          ShowSessionToast_Legacy(toastData)
        elseif toastData.type == "achievement" then
          ShowAchievementToast_Legacy(toastData.name, toastData.description, toastData.icon)
        else
          ShowToast(toastData.name or toastData.description or "Unknown", nil, toastData.type)
        end
      end
      pendingCombatToasts = {}
    end
    
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Combat started - we don't need to do anything special here yet
    DebugPrint("Combat started")
  end
end)

------------------------------------------------------------
--                      SLASH COMMANDS
------------------------------------------------------------
SLASH_PICKPOCKET1 = "/pp"
SlashCmdList["PICKPOCKET"] = function(msg)
  msg = (msg or ""):lower()
  local args = {}
  for word in msg:gmatch("%S+") do
    table.insert(args, word)
  end
  
  local cmd = args[1] or ""
  local arg1 = args[2] or ""
  local arg2 = args[3] or ""
  
  if cmd == "zone" then
    if arg1 == "" then
      -- Show current zone information
      local currentZone = getCurrentZone()
      local zoneStats = PPT_ZoneStats[currentZone]
      
      if not zoneStats then
        PPTPrint("No pickpocket data for current zone: " .. currentZone)
        return
      end
      
      local successRate = zoneStats.attempts > 0 and math.floor((zoneStats.successes / zoneStats.attempts) * 100) or 0
      PPTPrint("----- " .. currentZone .. " (Current Zone) -----")
      PPTPrint("Coinage:", coinsToString(zoneStats.copper))
      PPTPrint("Attempts:", zoneStats.attempts)
      PPTPrint("Successes:", zoneStats.successes)
      PPTPrint("Success Rate:", successRate .. "%")
      PPTPrint("Items:", zoneStats.items)
      
      -- Show top locations in current zone
      local locations = getLocationStatsSummary(currentZone)
      if #locations > 0 then
        PPTPrint("----- Top Locations -----")
        for i = 1, math.min(5, #locations) do
          local locationData = locations[i]
          local stats = locationData.stats
          local failures = stats.attempts - stats.successes
          local copperPerAttempt = stats.attempts > 0 and math.floor(stats.copper / stats.attempts) or 0
          PPTPrint(string.format("%s: %s (%d attempts, %d failures, %s/attempt, %d items)",
            locationData.location, coinsToString(stats.copper), stats.attempts, failures, coinsToString(copperPerAttempt), stats.items))
        end
      end
      return
    elseif arg1 == "location" then
      -- Show current location information
      local currentLocation = getCurrentLocation()
      local locationStats = PPT_LocationStats[currentLocation]
      
      if not locationStats then
        PPTPrint("No pickpocket data for current location: " .. currentLocation)
        return
      end
      
      local successRate = locationStats.attempts > 0 and math.floor((locationStats.successes / locationStats.attempts) * 100) or 0
      PPTPrint("----- " .. currentLocation .. " (Current Location) -----")
      PPTPrint("Coinage:", coinsToString(locationStats.copper))
      PPTPrint("Attempts:", locationStats.attempts)
      PPTPrint("Successes:", locationStats.successes)
      PPTPrint("Success Rate:", successRate .. "%")
      PPTPrint("Items:", locationStats.items)
      return
    elseif arg1 == "all" then
      -- Show all zones
      PPTPrint("----- All Zone Statistics -----")
      local zones = getZoneStatsSummary()
      if #zones == 0 then
        PPTPrint("No zone data available.")
        return
      end
      for _, zoneData in ipairs(zones) do
        local stats = zoneData.stats
        local successRate = stats.attempts > 0 and math.floor((stats.successes / stats.attempts) * 100) or 0
        local copperPerAttempt = stats.attempts > 0 and math.floor(stats.copper / stats.attempts) or 0
        PPTPrint(string.format("%s: %s (%d attempts, %d%% success, %s/attempt, %d items)",
          zoneData.zone, coinsToString(stats.copper), stats.attempts, successRate, coinsToString(copperPerAttempt), stats.items))
      end
      return
    elseif arg2 == "all" then
      -- Show all locations in specified zone (case-insensitive search)
      local targetZone = nil
      for zone, _ in pairs(PPT_ZoneStats) do
        if zone:lower():find(arg1:lower(), 1, true) then
          targetZone = zone
          break
        end
      end
      
      if not targetZone then
        PPTPrint("No zone found matching: " .. arg1)
        return
      end
      
      PPTPrint("----- Locations in " .. targetZone .. " -----")
      local locations = getLocationStatsSummary(targetZone)
      if #locations == 0 then
        PPTPrint("No location data available for " .. targetZone .. ".")
        return
      end
      for _, locationData in ipairs(locations) do
        local stats = locationData.stats
        local successRate = stats.attempts > 0 and math.floor((stats.successes / stats.attempts) * 100) or 0
        local copperPerAttempt = stats.attempts > 0 and math.floor(stats.copper / stats.attempts) or 0
        PPTPrint(string.format("%s: %s (%d attempts, %d%% success, %s/attempt, %d items)",
          locationData.location, coinsToString(stats.copper), stats.attempts, successRate, coinsToString(copperPerAttempt), stats.items))
      end
      return
    elseif arg1 ~= "" then
      -- Show specific zone stats (case-insensitive search)
      local targetZone = nil
      for zone, _ in pairs(PPT_ZoneStats) do
        if zone:lower():find(arg1:lower(), 1, true) then
          targetZone = zone
          break
        end
      end
      
      if not targetZone then
        PPTPrint("No zone found matching: " .. arg1)
        return
      end
      
      local zoneStats = PPT_ZoneStats[targetZone]
      local successRate = zoneStats.attempts > 0 and math.floor((zoneStats.successes / zoneStats.attempts) * 100) or 0
      PPTPrint("----- " .. targetZone .. " Statistics -----")
      PPTPrint("Coinage:", coinsToString(zoneStats.copper))
      PPTPrint("Attempts:", zoneStats.attempts)
      PPTPrint("Successes:", zoneStats.successes)
      PPTPrint("Success Rate:", successRate .. "%")
      PPTPrint("Items:", zoneStats.items)
      
      -- Show top locations in this zone
      local locations = getLocationStatsSummary(targetZone)
      if #locations > 0 then
        PPTPrint("----- Top Locations -----")
        for i = 1, math.min(5, #locations) do
          local locationData = locations[i]
          local stats = locationData.stats
          local failures = stats.attempts - stats.successes
          local copperPerAttempt = stats.attempts > 0 and math.floor(stats.copper / stats.attempts) or 0
          PPTPrint(string.format("%s: %s (%d attempts, %d failures, %s/attempt, %d items)",
            locationData.location, coinsToString(stats.copper), stats.attempts, failures, coinsToString(copperPerAttempt), stats.items))
        end
      end
      return
    end
  end
  
  if cmd == "togglemsg" then
    PPT_ShowMsg = not PPT_ShowMsg
    PPTPrint("showMsg =", tostring(PPT_ShowMsg)); return
  elseif cmd == "toggletoasts" then
    PPT_ShowSessionToasts = not PPT_ShowSessionToasts
    PPTPrint("showSessionToasts =", tostring(PPT_ShowSessionToasts)); return
  elseif cmd == "share" then
    if arg1 == "achievements" or arg1 == "ach" then
      ShareAchievements()
    elseif arg1 == "locations" or arg1 == "loc" then
      ShareTopLocations()
    else
      ShareSummaryAndStats(true, PPT_LastSummary)
    end
    return
  elseif cmd == "auto" and arg1 == "share" then
    PPT_ShareGroup = not PPT_ShareGroup
    PPTPrint("auto share =", tostring(PPT_ShareGroup))
    return
  elseif cmd == "reset" then
    if arg1 == "achievements" then
      ResetAchievements()
      local panel = _G.RoguePickPocketTrackerOptions
      if panel and panel.updateAchievements then
        panel:updateAchievements()
      end
      return
    elseif arg1 == "coins" or arg1 == "money" or arg1 == "items" then
      ResetCoinsAndItems()
      local panel = _G.RoguePickPocketTrackerOptions
      if panel and panel.updateStats then
        panel:updateStats()
      end
      return
    elseif arg1 == "locations" or arg1 == "zones" then
      ResetLocations()
      local panel = _G.RoguePickPocketTrackerOptions
      if panel and panel.updateStats then
        panel:updateStats()
      end
      return
    elseif arg1 == "all" and arg2 == "confirm" then
      ResetAllStats()
      PPTPrint("All statistics and achievements reset.")
      local panel = _G.RoguePickPocketTrackerOptions
      if panel then
        if panel.updateStats then panel:updateStats() end
        if panel.updateAchievements then panel:updateAchievements() end
      end
      return
    elseif arg1 == "all" then
      -- Show confirmation dialog for full reset
      PPTPrint("*** WARNING: This will reset ALL statistics and achievements! ***")
      PPTPrint("Type '/pp reset all confirm' to proceed, or anything else to cancel.")
      return
    else
      -- Show reset options
      PPTPrint("----- Reset Options -----")
      PPTPrint("/pp reset achievements - Reset only achievements")
      PPTPrint("/pp reset coins - Reset only coins and items")
      PPTPrint("/pp reset locations - Reset only zone/location data") 
      PPTPrint("/pp reset all - Reset everything (requires confirmation)")
      PPTPrint("Current /pp reset behavior changed - see options above")
      return
    end
  elseif cmd == "debug" then
    PPT_Debug = not PPT_Debug
    PPTPrint("debug =", tostring(PPT_Debug))
    
    -- Test achievement system if debug is enabled
    if PPT_Debug and updateAllAchievements then
      PPTPrint("Testing achievement system...")
      updateAllAchievements()
    end
    return
  elseif cmd == "testnewtoasts" then
    PPTPrint("Testing new toast system...")
    
    -- Test info toast
    PPTPrint("Calling ShowInfoToast...")
    if ShowInfoToast then
      ShowInfoToast("Test Info", "This is an info toast using the new system")
      PPTPrint("ShowInfoToast called successfully")
    else
      PPTPrint("ERROR: ShowInfoToast function not found")
    end
    
    -- Test error toast after delay
    if C_Timer and C_Timer.After then
      PPTPrint("Setting up delayed toasts...")
      C_Timer.After(2, function()
        PPTPrint("Calling ShowErrorToast...")
        if ShowErrorToast then
          ShowErrorToast("Test Error", "This is an error toast")
        else
          PPTPrint("ERROR: ShowErrorToast function not found")
        end
      end)
      
      -- Test tracking toast after delay
      C_Timer.After(4, function()
        PPTPrint("Calling ShowTrackingToast...")
        if ShowTrackingToast then
          ShowTrackingToast("Test Tracking", "This is a tracking toast")
        else
          PPTPrint("ERROR: ShowTrackingToast function not found")
        end
      end)
      
      -- Test session toast after delay
      C_Timer.After(6, function()
        PPTPrint("Calling session toast...")
        if ShowSessionCompletionToast then
          ShowSessionCompletionToast()
        else
          ShowSessionToast(true)
        end
      end)
      
      -- Test achievement toast after delay
      C_Timer.After(8, function()
        PPTPrint("Calling achievement toast...")
        if ShowTestAchievementToast then
          ShowTestAchievementToast()
        else
          ShowAchievementToast_Legacy("Test Achievement", "This is a test achievement", "Interface\\Icons\\Achievement_General")
        end
      end)
    else
      PPTPrint("WARNING: C_Timer not available, testing immediate toasts only")
      if ShowErrorToast then
        ShowErrorToast("Test Error", "This is an error toast")
      end
      if ShowTrackingToast then
        ShowTrackingToast("Test Tracking", "This is a tracking toast")
      end
    end
    
    PPTPrint("New toast system test sequence started")
    return
  elseif cmd == "testtoastqueue" then
    PPTPrint("Testing toast queue system...")
    
    -- Add multiple toasts to test queuing
    for i = 1, 5 do
      if C_Timer and C_Timer.After then
        C_Timer.After(i * 0.5, function()
          ShowInfoToast("Queue Test " .. i, "Testing toast queue position " .. i)
        end)
      end
    end
    
    PPTPrint("Toast queue test started (5 toasts)")
    return
  elseif cmd == "testbasictoast" then
    PPTPrint("Testing basic toast creation...")
    
    -- Test the most basic toast creation
    if CreateToast then
      PPTPrint("CreateToast function found, creating toast...")
      local toast = CreateToast("info")
      if toast then
        PPTPrint("Toast created successfully, setting content...")
        toast:SetContent({
          name = "Basic Test",
          description = "Testing basic toast functionality",
          icon = "Interface\\Icons\\INV_Misc_QuestionMark"
        })
        PPTPrint("Content set, queuing toast...")
        if QueueToast then
          QueueToast(toast)
          PPTPrint("Toast queued successfully")
        else
          PPTPrint("ERROR: QueueToast function not found")
        end
      else
        PPTPrint("ERROR: Failed to create toast")
      end
    else
      PPTPrint("ERROR: CreateToast function not found")
    end
    return
  elseif cmd == "testvisibletoast" then
    PPTPrint("Testing highly visible toast...")
    
    -- Create a very obvious toast manually
    if CreateFrame then
      local testFrame = CreateFrame("Frame", "PPT_TestToast", UIParent)
      testFrame:SetSize(400, 100)
      testFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Center of screen
      testFrame:SetFrameStrata("FULLSCREEN_DIALOG") -- Top layer
      testFrame:SetFrameLevel(9999)
      
      -- Bright colored background
      local bg = testFrame:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(1, 0, 0, 0.8) -- Bright red background
      
      -- Border
      local border = testFrame:CreateTexture(nil, "BORDER")
      border:SetPoint("TOPLEFT", -2, 2)
      border:SetPoint("BOTTOMRIGHT", 2, -2)
      border:SetColorTexture(1, 1, 0, 1) -- Yellow border
      
      -- Text
      local text = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      text:SetPoint("CENTER")
      text:SetText("TEST TOAST - SHOULD BE VISIBLE")
      text:SetTextColor(1, 1, 1, 1) -- White text
      
      testFrame:Show()
      testFrame:SetAlpha(1)
      
      -- Auto-hide after 5 seconds
      if C_Timer and C_Timer.After then
        C_Timer.After(5, function()
          testFrame:Hide()
        end)
      end
      
      PPTPrint("Highly visible test toast created at screen center")
    else
      PPTPrint("ERROR: CreateFrame not available")
    end
    return
  elseif cmd == "testdirectframe" then
    -- Create a frame directly to test basic functionality
    local testFrame = CreateFrame("Frame", "PPT_DirectTestFrame", UIParent)
    testFrame:SetSize(300, 80)
    testFrame:SetFrameStrata("TOOLTIP")
    testFrame:SetFrameLevel(2000)
    testFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Add a background so we can see it
    local bg = testFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 0, 0, 0.8) -- Red background
    
    -- Add text
    local text = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("DIRECT TEST FRAME")
    text:SetTextColor(1, 1, 1, 1)
    
    testFrame:SetAlpha(1.0)
    testFrame:Show()
    
    PPTPrint("Direct test frame created and shown at center screen")
    
    -- Hide after 5 seconds
    C_Timer.After(5, function()
      testFrame:Hide()
      PPTPrint("Direct test frame hidden")
    end)
    return
  elseif cmd == "testtoastframe" then
    PPTPrint("Testing toast frame creation directly...")
    
    -- Test our toast frame creation function directly
    local frame = CreateFrame("Frame", "PPT_DirectTestToast", UIParent)
    frame:SetSize(400, 90)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(9999)
      
      -- Background (blue for visibility)
      local bg = frame:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0.1, 0.15, 0.2, 0.95) -- Dark blue-grey
      
      -- Border (light blue)
      local border = frame:CreateTexture(nil, "BORDER")
      border:SetPoint("TOPLEFT", -2, 2)
      border:SetPoint("BOTTOMRIGHT", 2, -2)
      border:SetColorTexture(0.5, 0.7, 0.9, 1) -- Light blue border
      
      -- Icon
      local icon = frame:CreateTexture(nil, "ARTWORK")
      icon:SetSize(48, 48)
      icon:SetPoint("LEFT", frame, "LEFT", 15, 0)
      icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
      
      -- Title
      local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 15, 8)
      title:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
      title:SetJustifyH("LEFT")
      title:SetText("Information")
      title:SetTextColor(0.7, 0.9, 1, 1) -- Light blue title
      
      -- Name/Message
      local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      name:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
      name:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
      name:SetJustifyH("LEFT")
      name:SetText("Basic Test")
      name:SetTextColor(1, 1, 1, 1) -- White text
      
      -- Description
      local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
      desc:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
      desc:SetJustifyH("LEFT")
      desc:SetText("Testing basic toast functionality")
      desc:SetTextColor(0.8, 0.8, 0.8, 1) -- Light grey description
      
      -- Position and show
      frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -50)
      frame:SetAlpha(1)
      frame:Show()
      
      -- Auto-hide after 5 seconds
      if C_Timer and C_Timer.After then
        C_Timer.After(5, function()
          frame:Hide()
        end)
      end
      
      PPTPrint("Direct toast frame test created")
    return
  elseif cmd == "moneycheck" then
    -- Diagnostic command to check money tracking state
    PPTPrint("=== Money Tracking Diagnostics ===")
    PPTPrint("Current Money: %s", coinsToString(GetMoney()))
    PPTPrint("Last Money: %s", lastMoney and coinsToString(lastMoney) or "nil")
    PPTPrint("Session Active: %s", tostring(sessionActive))
    PPTPrint("Session Had Pick: %s", tostring(sessionHadPick))
    PPTPrint("Session Copper: %s", coinsToString(sessionCopper))
    PPTPrint("Mirrored This Session: %s", coinsToString(mirroredCopperThisSession))
    PPTPrint("Total Copper: %s", coinsToString(PPT_TotalCopper))
    if lastMoney and GetMoney() > lastMoney then
      PPTPrint("Untracked Money Difference: %s", coinsToString(GetMoney() - lastMoney))
    end
    PPTPrint("In Stealth: %s", tostring(inStealth))
    PPTPrint("UI Recently Opened: %s", tostring(uiRecentlyOpened()))
    PPTPrint("===============================")
    return
  elseif cmd == "version" then
    PPTPrint("Data version:", PPT_DataVersion or 0)
    PPTPrint("Current version:", 2)  -- Update this when CURRENT_DATA_VERSION changes
    return
  elseif cmd == "items" then
    PPTPrint("Cumulative items:", PPT_TotalItems)
    local lines = {}
    for name, cnt in pairs(PPT_ItemCounts) do table.insert(lines, string.format("%s x%d", name, cnt)) end
    table.sort(lines, function(a,b) return a:lower() < b:lower() end)
    for _,ln in ipairs(lines) do PPTPrint(" ", ln) end
    return
  elseif cmd == "achievements" or cmd == "ach" then
    -- Open standalone options window to achievements tab
    PPTPrint("Opening achievements panel...")
    
    if ShowStandaloneAchievements then
      ShowStandaloneAchievements()
    else
      PPTPrint("Achievements panel not available yet. Please try again.")
    end
    return
  elseif cmd == "testach" then
    if PPT_Debug then
      PPTPrint("Testing achievement system...")
      PPTPrint("Current stats - Copper: %d, Attempts: %d, Success: %d, Items: %d", 
               PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems)
      
      if updateAllAchievements then
        updateAllAchievements()
      else
        PPTPrint("updateAllAchievements function not found!")
      end
      
      if hookSessionFinalization then
        hookSessionFinalization()
      else
        PPTPrint("hookSessionFinalization function not found!")
      end
    else
      PPTPrint("Enable debug mode first with /pp debug")
    end
    return
  elseif cmd == "simpleframe" then
    PPTPrint("Testing simple frame creation...")
    
    -- Test most basic frame creation
    local testFrame = CreateFrame("Frame", "PPT_TestFrame", UIParent)
    if testFrame then
      testFrame:SetSize(200, 100)
      testFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      testFrame:SetFrameStrata("FULLSCREEN_DIALOG")
      
      -- Add background
      local bg = testFrame:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(1, 0, 0, 0.8) -- Red background
      
      -- Add text
      local text = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      text:SetPoint("CENTER", 0, 0)
      text:SetTextColor(1, 1, 1)
      text:SetText("TEST FRAME - Click to close")
      
      testFrame:Show()
      testFrame:EnableMouse(true)
      testFrame:SetScript("OnMouseUp", function(self)
        self:Hide()
        PPTPrint("Test frame closed")
      end)
      
      PPTPrint("Simple test frame created - should appear in center of screen")
    else
      PPTPrint("ERROR: Failed to create test frame!")
    end
    return
  elseif cmd == "simpleframe" then
    print("Creating simple test frame...")
    local testFrame = CreateFrame("Frame", "PPT_TestFrame", UIParent)
    testFrame:SetSize(200, 100)
    testFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    testFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    testFrame:SetFrameLevel(300)
    
    -- Background
    local bg = testFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 0, 0, 0.8) -- Red background
    
    -- Text
    local text = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("TEST FRAME")
    text:SetTextColor(1, 1, 1)
    
    testFrame:Show()
    print("Test frame created and shown at center screen")
    
    -- Hide after 3 seconds
    if C_Timer and C_Timer.After then
      C_Timer.After(3, function()
        testFrame:Hide()
        print("Test frame hidden")
      end)
    end
    return
  elseif cmd == "framecheck" then
    print("Checking toast frame status...")
    if _G["PPT_ToastFrame"] then
      local frame = _G["PPT_ToastFrame"]
      print("Frame exists: " .. tostring(frame:GetName()))
      print("Frame shown: " .. tostring(frame:IsShown()))
      print("Frame visible: " .. tostring(frame:IsVisible()))
      print("Frame alpha: " .. tostring(frame:GetAlpha()))
      print("Frame strata: " .. tostring(frame:GetFrameStrata()))
      print("Frame level: " .. tostring(frame:GetFrameLevel()))
      local x, y = frame:GetCenter()
      if x and y then
        print("Frame position: " .. tostring(x) .. ", " .. tostring(y))
      else
        print("Frame position: nil")
      end
      local w, h = frame:GetSize()
      print("Frame size: " .. tostring(w) .. " x " .. tostring(h))
    else
      print("Toast frame does not exist")
    end
    return
  elseif cmd == "screeninfo" then
    print("Screen and UI information:")
    local uiScale = UIParent:GetEffectiveScale()
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiWidth = UIParent:GetWidth()
    local uiHeight = UIParent:GetHeight()
    
    print("Screen size: " .. screenWidth .. " x " .. screenHeight)
    print("UIParent size: " .. uiWidth .. " x " .. uiHeight)
    print("UI Scale: " .. uiScale)
    
    -- Check if toast frame exists and its position
    if _G["PPT_ToastFrame"] then
      local frame = _G["PPT_ToastFrame"]
      local left = frame:GetLeft()
      local right = frame:GetRight()
      local top = frame:GetTop()
      local bottom = frame:GetBottom()
      local x, y = frame:GetCenter()
      
      print("Toast frame bounds:")
      print("  Left: " .. tostring(left))
      print("  Right: " .. tostring(right))
      print("  Top: " .. tostring(top))
      print("  Bottom: " .. tostring(bottom))
      print("  Center: " .. tostring(x) .. ", " .. tostring(y))
      
      -- Check if it's within screen bounds
      if left and right and top and bottom then
        local onScreen = left >= 0 and right <= uiWidth and bottom >= 0 and top <= uiHeight
        print("  On screen: " .. tostring(onScreen))
      end
    else
      print("Toast frame doesn't exist yet")
    end
    return
  elseif cmd == "repositiontoast" then
    if _G["PPT_ToastFrame"] then
      local frame = _G["PPT_ToastFrame"]
      frame:ClearAllPoints()
      frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      frame:SetFrameStrata("TOOLTIP")
      frame:SetFrameLevel(999)
      frame:SetAlpha(1)
      frame:Show()
      print("Toast frame repositioned to center and shown")
      
      local x, y = frame:GetCenter()
      print("New position: " .. tostring(x) .. ", " .. tostring(y))
    else
      print("No toast frame to reposition")
    end
    return
  elseif cmd == "forcetoast" then
    print("Creating forced visible toast...")
    
    -- Create a completely new toast frame for testing
    local testToast = CreateFrame("Frame", "PPT_ForceToast", UIParent)
    testToast:SetSize(300, 80)
    testToast:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    testToast:SetFrameStrata("TOOLTIP")
    testToast:SetFrameLevel(999)
    
    -- Background
    local bg = testToast:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.9) -- Dark background
    
    -- Border
    local border = testToast:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0.6, 0.6, 0.6, 1) -- Grey border
    
    -- Text
    local text = testToast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("FORCED TOAST TEST")
    text:SetTextColor(1, 1, 1)
    
    testToast:SetAlpha(1)
    testToast:Show()
    
    print("Forced toast created at screen center")
    print("Frame shown: " .. tostring(testToast:IsShown()))
    print("Frame visible: " .. tostring(testToast:IsVisible()))
    print("Frame alpha: " .. tostring(testToast:GetAlpha()))
    
    -- Hide after 5 seconds
    if C_Timer and C_Timer.After then
      C_Timer.After(5, function()
        testToast:Hide()
        print("Forced toast hidden")
      end)
    end
    return
  elseif cmd == "basictoast" then
    PPTPrint("Testing basic toast...")
    
    -- Test most basic toast functionality
    if ShowInfoToast then
      ShowInfoToast("Basic Test", "Testing if toasts work at all")
      PPTPrint("Basic toast triggered using new system")
    elseif ShowToast then
      ShowToast("Basic Test - Testing if toasts work at all", nil, "info")
      PPTPrint("Basic toast triggered using legacy system")
    else
      PPTPrint("ERROR: No toast functions found!")
    end
    return
  elseif cmd == "testtoast" then
    PPTPrint("Testing toast system...")
    
    -- Test basic toast functionality
    if ShowToast then
      PPTPrint("Testing achievement toast...")
      ShowToast({
        type = "achievement",
        name = "Test Achievement",
        description = "This is a test achievement toast",
        icon = "Interface\\Icons\\Achievement_General"
      })
      
      -- Wait a moment, then test session toast
      C_Timer.After(2, function()
        PPTPrint("Testing session toast...")
        -- Create temporary session data for testing
        PPT_LastSessionData = {
          copper = 1234,
          itemsCount = 5,
          items = {["Linen Cloth"] = 3, ["Wool Cloth"] = 2}
        }
        
        if ShowSessionToast then
          ShowSessionToast(true)
          PPTPrint("Session toast test completed")
        else
          PPTPrint("ShowSessionToast function not found!")
        end
      end)
    else
      PPTPrint("ShowToast function not found!")
    end
    return
  elseif cmd == "session" then
    DebugPrint("Session command called with arg1: %s", tostring(arg1))
    DebugPrint("PPT_LastSummary: %s", tostring(PPT_LastSummary))
    DebugPrint("PPT_LastSessionData: %s", tostring(PPT_LastSessionData))
    
    if PPT_LastSummary or PPT_LastSessionData then
      if arg1 == "toast" and ShowSessionToast then
        -- Show last session as toast using stored data
        ShowSessionToast(true)
        PPTPrint("Showing last session as toast")
      elseif arg1 == "print" then
        -- Show last session as chat print
        if PPT_LastSummary then
          PPTPrint("Last session: " .. PPT_LastSummary)
        else
          PPTPrint("No session summary available")
        end
      else
        -- Default: show both chat and toast if available
        if PPT_LastSummary then
          PPTPrint("Last session: " .. PPT_LastSummary)
        else
          PPTPrint("No session summary available")
        end
        if ShowSessionToast then
          ShowSessionToast(true)
        end
      end
    else
      PPTPrint("No session data available")
    end
    return
  elseif cmd == "ui" then
    if arg1 == "coinage" or arg1 == "tracker" then
      if arg2 == "show" then
        ShowCoinageTracker()
        PPTPrint("Coinage tracker shown")
      elseif arg2 == "hide" then
        HideCoinageTracker()
        PPTPrint("Coinage tracker hidden")
      elseif arg2 == "toggle" then
        ToggleCoinageTracker()
        PPTPrint("Coinage tracker " .. (IsCoinageTrackerEnabled() and "shown" or "hidden"))
      elseif arg2 == "reset" then
        ResetCoinageTrackerPosition()
        PPTPrint("Coinage tracker position reset")
      else
        ToggleCoinageTracker()
        PPTPrint("Coinage tracker " .. (IsCoinageTrackerEnabled() and "shown" or "hidden"))
      end
    else
      PPTPrint("UI commands:")
      PPTPrint("  /pp ui coinage [show/hide/toggle/reset] - Manage coinage tracker")
      PPTPrint("  /pp ui tracker [show/hide/toggle/reset] - Alias for coinage")
    end
    return
  elseif cmd == "tracker" then
    -- Quick access to toggle coinage tracker
    ToggleCoinageTracker()
    PPTPrint("Coinage tracker " .. (IsCoinageTrackerEnabled() and "shown" or "hidden"))
    return
  elseif cmd == "options" then
    -- Open standalone options window
    if ShowStandaloneOptions then
      ShowStandaloneOptions()
    else
      PPTPrint("Options window not available yet. Try again after addon finishes loading.")
    end
    return
  elseif cmd == "track" or cmd == "tracking" then
    -- Tracking commands
    if arg1 == "start" then
      if not PPT_StopwatchEnabled then
        ShowToast({
          type = "tracking",
          name = "Feature Disabled",
          description = "Enable tracking in options first",
          icon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
        })
        return
      end
      StartPickPocketTracking()
    elseif arg1 == "stop" then
      StopPickPocketTracking()
    elseif arg1 == "toggle" then
      TogglePickPocketTracking()
    elseif arg1 == "status" or arg1 == "info" then
      if PPT_TrackingActive then
        local stats = GetTrackingStats()
        if stats then
          PPTPrint("----- Tracking Status -----")
          PPTPrint("Status: Active")
          PPTPrint("Time tracked:", FormatTrackingTime(stats.elapsedTime))
          PPTPrint("Earned:", coinsToString(stats.earnedCopper))
          PPTPrint("Items:", tostring(stats.earnedItems))
          PPTPrint("Per minute:", coinsToString(math.floor(stats.copperPerMinute)))
          PPTPrint("Per hour:", coinsToString(math.floor(stats.copperPerHour)))
        end
      else
        PPTPrint("Tracking Status: Inactive")
      end
    elseif arg1 == "report" then
      ShowTrackingReport()
    elseif arg1 == "reset" then
      if PPT_TrackingActive then
        PPTPrint("Resetting tracking...")
        StartPickPocketTracking() -- This automatically resets
      else
        PPTPrint("Tracking is not active. Use '/pp track start' to begin.")
      end
    else
      PPTPrint("Tracking commands:")
      PPTPrint("  /pp track start - Start tracking earnings")
      PPTPrint("  /pp track stop - Stop tracking earnings")
      PPTPrint("  /pp track toggle - Toggle tracking")
      PPTPrint("  /pp track status - Show tracking status")
      PPTPrint("  /pp track report - Show tracking report")
      PPTPrint("  /pp track reset - Reset current tracking session")
      if not PPT_StopwatchEnabled then
        PPTPrint("Note: Tracking is currently disabled. Enable in /pp options")
      end
    end
    return
  elseif cmd == "help" then
    PPTPrint("----- Help -----")
    PPTPrint("Usage: /pp [togglemsg, toggletoasts, share, auto share, reset, debug, items, options, achievements, help, version]")
    PPTPrint("Zone commands:")
    PPTPrint("  /pp zone - Show current zone stats")
    PPTPrint("  /pp zone location - Show current location stats")
    PPTPrint("  /pp zone all - Show all zone stats")
    PPTPrint("  /pp zone [name] - Show specific zone stats")
    PPTPrint("  /pp zone [name] all - Show all locations in zone")
    PPTPrint("UI commands:")
    PPTPrint("  /pp tracker - Toggle coinage tracker")
    PPTPrint("  /pp ui coinage [show/hide/toggle/reset] - Manage coinage tracker")
    PPTPrint("Tracking commands:")
    PPTPrint("  /pp track start/stop/toggle - Control earnings tracking")
    PPTPrint("  /pp track status - Show current tracking status")
    PPTPrint("  /pp track report - Show detailed tracking report")
    PPTPrint("Other commands:")
    PPTPrint("  /pp togglemsg - Toggle loot messages")
    PPTPrint("  /pp toggletoasts - Toggle session completion toasts")
    PPTPrint("  /pp share - Share totals and last session")
    PPTPrint("  /pp share achievements - Share achievement progress")
    PPTPrint("  /pp share locations - Share top pickpocket locations")
    PPTPrint("  /pp auto share - Toggle automatic sharing")
    PPTPrint("  /pp reset [type] - Reset statistics (achievements/coins/locations/all)")
    PPTPrint("  /pp debug - Toggle debug mode")
    PPTPrint("  /pp simpleframe - Test basic frame creation")
    PPTPrint("  /pp basictoast - Test basic toast functionality")
    PPTPrint("  /pp testtoast - Test toast notification system")
    PPTPrint("  /pp moneycheck - Check money tracking state (for debugging)")
    PPTPrint("  /pp version - Show data version info")
    PPTPrint("  /pp items - Show cumulative item counts")
    PPTPrint("  /pp session [toast/print] - Show last session summary")
    PPTPrint("  /pp options - Open options panel")
    PPTPrint("  /pp achievements - Open achievements panel")
    return
  end

  PPTPrint("----- Totals -----");  PrintTotal()
  PPTPrint("----- Stats -----");   PrintStats()
  
  -- Show top zones
  PPTPrint("----- Top Zones -----")
  local zones = getZoneStatsSummary()
  if #zones == 0 then
    PPTPrint("No zone data available yet.")
  else
    for i = 1, math.min(5, #zones) do
      local zoneData = zones[i]
      local stats = zoneData.stats
      local successRate = stats.attempts > 0 and math.floor((stats.successes / stats.attempts) * 100) or 0
      PPTPrint(string.format("%s: %s (%d%% success)",
        zoneData.zone, coinsToString(stats.copper), successRate))
    end
  end
  
  PPTPrint("Use /pp help for command list")
end

