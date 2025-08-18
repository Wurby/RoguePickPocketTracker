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

local function SafeRegister(evt) pcall(frame.RegisterEvent, frame, evt) end
SafeRegister("MERCHANT_SHOW"); SafeRegister("MAIL_SHOW"); SafeRegister("TAXIMAP_OPENED")

-- Poll (money deltas + grace timeout)
local pollAccum = 0
frame:SetScript("OnUpdate", function(_, elapsed)
  if not sessionActive then return end
  pollAccum = pollAccum + elapsed
  if (not inStealth) and windowEndsAt > 0 and GetTime() >= windowEndsAt then
    finalizeSession("timeout"); return
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
      
      DebugPrint(("SV @load: copper=%d attempts=%d succ=%d items=%d version=%d")
        :format(PPT_TotalCopper or -1, PPT_TotalAttempts or -1, PPT_SuccessfulAttempts or -1, PPT_TotalItems or -1, PPT_DataVersion or -1))
    end

  elseif event == "PLAYER_ENTERING_WORLD" then
    playerGUID = UnitGUID("player")
    inStealth, sessionActive = false, false
    lastMoney = GetMoney()
    if getStealthFlag() then onStealthGained() end
    
    -- Try to hook achievements if not already done
    if tryHookLater and not _PPT_AchievementHookInstalled then
      tryHookLater()
    end

  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unitTag, _, spellID = ...
    if unitTag == "player" and spellID == PICK_ID then
      if not sessionActive then
        startSession()
        if not getStealthFlag() then windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END end
      end
      sessionHadPick = true
      DebugPrint("Pick: UNIT_SPELLCAST_SUCCEEDED")
    end

  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, sub, _, srcGUID, _, _, _, dstGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if not playerGUID then return end

    if dstGUID == playerGUID and STEALTH_IDS[spellID] then
      if sub == "SPELL_AURA_APPLIED" then onStealthGained(); return
      elseif sub == "SPELL_AURA_REMOVED" then onStealthLost(); return end
    end

    if sub == "SPELL_CAST_SUCCESS" and srcGUID == playerGUID and spellID == PICK_ID then
      if not sessionActive then
        startSession()
        if not getStealthFlag() then windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END end
      end
      sessionHadPick = true
      if dstGUID and not attemptedGUIDs[dstGUID] then
        attemptedGUIDs[dstGUID] = true
        PPT_TotalAttempts = PPT_TotalAttempts + 1
        
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
        mirroredCopperThisSession = mirroredCopperThisSession + copper
        if not inStealth then windowEndsAt = math.max(windowEndsAt, GetTime() + 0.25) end
      end
    end

  elseif event == "CHAT_MSG_LOOT" then
    if sessionActive and sessionHadPick and not uiRecentlyOpened() then
      local msg = ...
      recordItemLootFromMessage(msg)
    end

  elseif event == "PLAYER_MONEY" then
    if sessionActive and sessionHadPick and not uiRecentlyOpened() then
      local now = GetMoney()
      if lastMoney and now > lastMoney then
        local diff = now - lastMoney
        DebugPrint("Money(event): +%s", coinsToString(diff))
        sessionCopper = sessionCopper + diff
        PPT_TotalCopper = PPT_TotalCopper + diff
        mirroredCopperThisSession = mirroredCopperThisSession + diff
      end
      lastMoney = now
    end

  elseif event == "PLAYER_LOGOUT" then
    sweepMoneyNow()
    if sessionActive then
      finalizeSession("logout")
    end
    DebugPrint(("SV @logout: copper=%d attempts=%d succ=%d items=%d")
      :format(PPT_TotalCopper or -1, PPT_TotalAttempts or -1, PPT_SuccessfulAttempts or -1, PPT_TotalItems or -1))
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
    -- Open options panel to achievements tab
    local panel = _G.RoguePickPocketTrackerOptions
    if panel then
      -- Try to open options panel first
      if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
      elseif InterfaceOptionsFrame_OpenToPanel then
        InterfaceOptionsFrame_OpenToPanel(panel)
      elseif Settings and Settings.OpenToCategory then
        if _G.PPT_SettingsCategory then
          Settings.OpenToCategory(_G.PPT_SettingsCategory)
        elseif panel.settingsCategory then
          Settings.OpenToCategory(panel.settingsCategory)
        else
          SettingsPanel:Open()
        end
      else
        -- Direct approach - show interface options and our panel
        if InterfaceOptionsFrame then
          InterfaceOptionsFrame:Show()
          -- Force show our panel on top
          panel:SetParent(InterfaceOptionsFramePanelContainer)
          panel:Show()
        elseif SettingsPanel then
          SettingsPanel:Open()
          panel:Show()
        end
      end
      -- Switch to achievements tab (tab 2)
      if panel.ShowTab then
        panel:ShowTab(2)
      end
    end
    PPTPrint("Opening achievements panel...")
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
  elseif cmd == "testalert" then
    -- Test the achievement alert
    if showAchievementAlert then
      local testAchievement = {
        name = "Test Achievement",
        description = "This is a test achievement alert",
        icon = "Interface\\Icons\\INV_Misc_Coin_01"
      }
      PPTPrint("Testing achievement alert...")
      showAchievementAlert(testAchievement)
    else
      PPTPrint("showAchievementAlert function not found!")
    end
    return
  elseif cmd == "testmulti" then
    -- Test multiple achievement alerts
    if showAchievementAlert then
      PPTPrint("Testing multiple achievement alerts...")
      
      local testAchievements = {
        {
          name = "First Achievement",
          description = "This is the first test achievement",
          icon = "Interface\\Icons\\INV_Misc_Coin_01"
        },
        {
          name = "Second Achievement", 
          description = "This is the second test achievement",
          icon = "Interface\\Icons\\INV_Misc_Coin_02"
        },
        {
          name = "Third Achievement",
          description = "This is the third test achievement", 
          icon = "Interface\\Icons\\INV_Misc_Coin_03"
        }
      }
      
      for _, achievement in ipairs(testAchievements) do
        showAchievementAlert(achievement)
      end
    else
      PPTPrint("showAchievementAlert function not found!")
    end
    return
  elseif cmd == "forceach" then
    if PPT_Debug then
      PPTPrint("Forcing achievement update...")
      if updateAllAchievements then
        updateAllAchievements()
        PPTPrint("Achievement update forced.")
      else
        PPTPrint("updateAllAchievements function not found!")
      end
    else
      PPTPrint("Enable debug mode first with /pp debug")
    end
    return
  elseif cmd == "options" then
    -- Open options panel (Classic Era compatible)
    local panel = _G.RoguePickPocketTrackerOptions
    if panel then
      -- Try multiple approaches to open the specific panel
      if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
      elseif InterfaceOptionsFrame_OpenToPanel then
        InterfaceOptionsFrame_OpenToPanel(panel)
      elseif Settings and Settings.OpenToCategory then
        if _G.PPT_SettingsCategory then
          Settings.OpenToCategory(_G.PPT_SettingsCategory)
        elseif panel.settingsCategory then
          Settings.OpenToCategory(panel.settingsCategory)
        else
          SettingsPanel:Open()
        end
      else
        -- Direct approach - show interface options and our panel
        if InterfaceOptionsFrame then
          InterfaceOptionsFrame:Show()
          -- Force show our panel on top
          panel:SetParent(InterfaceOptionsFramePanelContainer)
          panel:Show()
        elseif SettingsPanel then
          SettingsPanel:Open()
          panel:Show()
        end
      end
    else
      PPTPrint("Error: Options panel not found!")
    end
    PPTPrint("Opening options panel...")
    return
  elseif cmd == "help" then
    PPTPrint("----- Help -----")
    PPTPrint("Usage: /pp [togglemsg, share, auto share, reset, debug, items, options, achievements, help, version]")
    PPTPrint("Zone commands:")
    PPTPrint("  /pp zone - Show current zone stats")
    PPTPrint("  /pp zone location - Show current location stats")
    PPTPrint("  /pp zone all - Show all zone stats")
    PPTPrint("  /pp zone [name] - Show specific zone stats")
    PPTPrint("  /pp zone [name] all - Show all locations in zone")
    PPTPrint("Other commands:")
    PPTPrint("  /pp togglemsg - Toggle loot messages")
    PPTPrint("  /pp share - Share totals and last session")
    PPTPrint("  /pp share achievements - Share achievement progress")
    PPTPrint("  /pp share locations - Share top pickpocket locations")
    PPTPrint("  /pp auto share - Toggle automatic sharing")
    PPTPrint("  /pp reset [type] - Reset statistics (achievements/coins/locations/all)")
    PPTPrint("  /pp debug - Toggle debug mode")
    PPTPrint("  /pp version - Show data version info")
    PPTPrint("  /pp items - Show cumulative item counts")
    PPTPrint("  /pp options - Open options panel")
    PPTPrint("  /pp achievements - Open achievements panel")
    PPTPrint("  /pp testalert - Test achievement alert (for debugging)")
    PPTPrint("  /pp testmulti - Test multiple achievement alerts")
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

