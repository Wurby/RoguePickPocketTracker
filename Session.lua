-- Session.lua
-- Session state management and helpers for RoguePickPocketTracker

------------------------------------------------------------
--                     SESSION STATE
------------------------------------------------------------
playerGUID = nil
sessionActive = false
inStealth = false
windowEndsAt = 0
lastMoney = nil
sessionCopper = 0
mirroredCopperThisSession = 0
sessionHadPick = false
attemptedGUIDs = {}      -- one attempt per target per session
sessionItemsCount = 0
sessionItems = {}
PPT_LastSummary = nil
sessionZone = nil
sessionLocation = nil

-- UI-guard helpers
recentUI = {}
function markUI(name) recentUI[name] = GetTime(); DebugPrint("UI: %s", name) end
function uiRecentlyOpened()
  local now = GetTime()
  return (recentUI.MERCHANT_SHOW   and now - recentUI.MERCHANT_SHOW   < 2)
      or (recentUI.MAIL_SHOW       and now - recentUI.MAIL_SHOW       < 2)
      or (recentUI.TAXIMAP_OPENED  and now - recentUI.TAXIMAP_OPENED  < 2)
      or false
end

------------------------------------------------------------
--                     PRINT HELPERS
------------------------------------------------------------
function PrintTotal()
  PPTPrint(" ", "Total Coinage: " .. coinsToString(PPT_TotalCopper))
  PPTPrint(" ", "Total Items:", PPT_TotalItems)
end

function PrintNoCoin(reason)
  if PPT_ShowMsg then
    PPTPrint("Pick Pocket: no loot", reason and ("("..reason..")") or "")
  end
end

function PrintStats()
  local avgPerAttempt = (PPT_TotalAttempts > 0) and math.floor(PPT_TotalCopper / PPT_TotalAttempts) or 0
  local avgPerSuccess = (PPT_SuccessfulAttempts > 0) and math.floor(PPT_TotalCopper / PPT_SuccessfulAttempts) or 0
  PPTPrint("Attempts:", PPT_TotalAttempts)
  PPTPrint("Successes:", PPT_SuccessfulAttempts)
  PPTPrint("Fails:", (PPT_TotalAttempts - PPT_SuccessfulAttempts))
  PPTPrint("Avg/Attempt:", coinsToString(avgPerAttempt))
  PPTPrint("Avg/Success:", coinsToString(avgPerSuccess))
end

-- Reset all saved statistics
function ResetAllStats()
  PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems = 0,0,0,0
  PPT_ItemCounts = {}
  PPT_ZoneStats = {}
  PPT_LocationStats = {}
  PPT_Achievements = {}
  PPT_CompletedAchievements = {}
  UpdateCoinageTracker()
  -- Don't reset PPT_DataVersion on manual reset - only on breaking changes
end

-- Reset only achievements
function ResetAchievements()
  PPT_Achievements = {}
  PPT_CompletedAchievements = {}
  PPTPrint("Achievements reset.")
end

-- Reset only coins and items
function ResetCoinsAndItems()
  PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems = 0,0,0,0
  PPT_ItemCounts = {}
  UpdateCoinageTracker()
  PPTPrint("Coins and items reset.")
end

-- Reset only location data
function ResetLocations()
  PPT_ZoneStats = {}
  PPT_LocationStats = {}
  PPTPrint("Location data reset.")
end

-- End-of-session block with headers like /pp
function PrintSessionSummary()
  PPTPrint("----- Stealth Report -----")
  PPTPrint("Gained:", "+"..coinsToString(sessionCopper))
  PrintTotal()
  if sessionItemsCount > 0 then
    local lines = {}
    for name, cnt in pairs(sessionItems) do table.insert(lines, string.format("%s x%d", name, cnt)) end
    table.sort(lines)
    PPTPrint("----- Items ("..sessionItemsCount..") -----")
    for _,ln in ipairs(lines) do PPTPrint(" ", ln) end
  end
  PPTPrint(" ")
end

local function getGroupChannel()
  if IsInRaid and IsInRaid() then return "RAID" end
  if IsInGroup and IsInGroup() then return "PARTY" end
  if GetNumRaidMembers and GetNumRaidMembers() > 0 then return "RAID" end
  if GetNumPartyMembers and GetNumPartyMembers() > 0 then return "PARTY" end
end

local function buildSummaryMessage()
  local msg = string.format("Pick Pocket: +%s", coinsToString(sessionCopper))
  if sessionItemsCount > 0 then
    local items = {}
    for name, cnt in pairs(sessionItems) do table.insert(items, string.format("%s x%d", name, cnt)) end
    table.sort(items)
    msg = msg .. " | " .. table.concat(items, ", ")
  end
  return msg
end

local function getLastChatTarget()
  local box = ChatEdit_GetLastActiveWindow and ChatEdit_GetLastActiveWindow()
  if box and box:GetAttribute("chatType") then
    local chatType = box:GetAttribute("chatType")
    if chatType == "WHISPER" then
      return chatType, box:GetAttribute("tellTarget")
    elseif chatType == "CHANNEL" then
      return chatType, box:GetAttribute("channelTarget")
    else
      return chatType
    end
  end
  return getGroupChannel()
end

local function buildShareMessages(summary)
  local msgs = {}
  table.insert(msgs, string.format("PP Totals: %s | Items %d", coinsToString(PPT_TotalCopper), PPT_TotalItems))
  local avgAttempt = (PPT_TotalAttempts > 0) and math.floor(PPT_TotalCopper / PPT_TotalAttempts) or 0
  local avgSuccess = (PPT_SuccessfulAttempts > 0) and math.floor(PPT_TotalCopper / PPT_SuccessfulAttempts) or 0
  table.insert(msgs, string.format("Attempts %d, Success %d, Fail %d, Avg/Att %s, Avg/Succ %s",
    PPT_TotalAttempts, PPT_SuccessfulAttempts, (PPT_TotalAttempts - PPT_SuccessfulAttempts),
    coinsToString(avgAttempt), coinsToString(avgSuccess)))
  if summary then
    table.insert(msgs, "Last Session: " .. summary)
  end
  return msgs
end

function ShareSummaryAndStats(force, summary)
  if not force and not PPT_ShareGroup then return end
  local ch, target = getLastChatTarget()
  if not ch then return end
  for _,m in ipairs(buildShareMessages(summary or PPT_LastSummary)) do
    -- "|" must be escaped as "||" to avoid item-link parsing in chat
    SendChatMessage(m:gsub("|", "||"), ch, nil, target)
  end
end

function ShareAchievements()
  local ch, target = getLastChatTarget()
  if not ch then return end
  
  local completed = getCompletedAchievementsCount()
  local total = getTotalAchievementsCount()
  local percentage = total > 0 and math.floor((completed / total) * 100) or 0
  
  local msg = string.format("PP Achievements: %d/%d (%d%%) unlocked", completed, total, percentage)
  SendChatMessage(msg:gsub("|", "||"), ch, nil, target)
end

function ShareTopLocations()
  local ch, target = getLastChatTarget()
  if not ch then return end
  
  -- Get top 3 locations by total attempts
  local locations = {}
  for location, data in pairs(PPT_LocationStats) do
    if data.attempts and data.attempts > 0 then
      table.insert(locations, {
        name = location,
        attempts = data.attempts,
        copper = data.copper or 0
      })
    end
  end
  
  -- Sort by attempts (descending)
  table.sort(locations, function(a, b) return a.attempts > b.attempts end)
  
  if #locations == 0 then
    SendChatMessage("PP Locations: No data yet", ch, nil, target)
    return
  end
  
  -- Build minimal message with top 3
  local parts = {}
  for i = 1, math.min(3, #locations) do
    local loc = locations[i]
    table.insert(parts, string.format("%s(%d)", loc.name, loc.attempts))
  end
  
  local msg = "PP Top Locations: " .. table.concat(parts, ", ")
  SendChatMessage(msg:gsub("|", "||"), ch, nil, target)
end

------------------------------------------------------------
--                     SESSION LIFECYCLE
------------------------------------------------------------
function resetSession()
  sessionCopper = 0
  mirroredCopperThisSession = 0
  sessionHadPick = false
  sessionItemsCount = 0
  sessionItems = {}
  attemptedGUIDs = {}
  lastMoney = GetMoney()
  windowEndsAt = 0
  sessionZone = nil
  sessionLocation = nil
end

function startSession()
  sessionActive = true
  resetSession()
  sessionZone = getCurrentZone()
  sessionLocation = getCurrentLocation()
  DebugPrint("Stealth: start at %s", sessionLocation)
end

function finalizeSession(reasonIfZero)
  if not sessionActive then return end
  local hadLoot = (sessionCopper > 0) or (sessionItemsCount > 0)

  if sessionHadPick then
    if hadLoot then
      local remainder = sessionCopper - mirroredCopperThisSession
      if remainder > 0 then
        PPT_TotalCopper = PPT_TotalCopper + remainder
        UpdateCoinageTracker()
        DebugPrint("Finalize: committed remainder +%s", coinsToString(remainder))
      end
      
      -- Count actual number of successful pickpockets (number of attempted GUIDs)
      local successfulAttempts = 0
      for guid, locationData in pairs(attemptedGUIDs) do
        if guid and guid ~= "" then
          successfulAttempts = successfulAttempts + 1
        end
      end
      PPT_SuccessfulAttempts = PPT_SuccessfulAttempts + successfulAttempts
      DebugPrint("Finalize: adding %d successful attempts (total now %d)", successfulAttempts, PPT_SuccessfulAttempts)
      
      -- Update location-based statistics to reflect success and add copper/items
      if sessionZone and sessionLocation then
        -- Collect all locations that had attempts in this session
        local sessionLocations = {}
        for guid, locationData in pairs(attemptedGUIDs) do
          if type(locationData) == "table" then
            local locKey = locationData.location
            if not sessionLocations[locKey] then
              sessionLocations[locKey] = {zone = locationData.zone, count = 0}
            end
            sessionLocations[locKey].count = sessionLocations[locKey].count + 1
          end
        end
        
        -- If we have multiple locations, distribute items/copper proportionally
        local totalAttempts = 0
        for _, data in pairs(sessionLocations) do
          totalAttempts = totalAttempts + data.count
        end
        
        if totalAttempts > 0 then
          for location, data in pairs(sessionLocations) do
            local proportion = data.count / totalAttempts
            local locationCopper = math.floor(sessionCopper * proportion)
            local locationItems = math.floor(sessionItemsCount * proportion)
            
            local locationStats = PPT_LocationStats[location]
            local zoneStats = PPT_ZoneStats[data.zone]
            
            if locationStats and zoneStats then
              -- Add one success per attempt at this location (converting failed attempts to successes)
              locationStats.successes = locationStats.successes + data.count
              locationStats.copper = locationStats.copper + locationCopper
              locationStats.items = locationStats.items + locationItems
              
              zoneStats.successes = zoneStats.successes + data.count
              zoneStats.copper = zoneStats.copper + locationCopper
              zoneStats.items = zoneStats.items + locationItems
              
              DebugPrint("Location tracking: Updated %s (%s) - %d successes, copper +%s, items +%s", 
                         location, data.zone, data.count, coinsToString(locationCopper), tostring(locationItems))
            end
          end
        else
          -- Fallback to old method if no location data available
          local locationStats = PPT_LocationStats[sessionLocation]
          local zoneStats = PPT_ZoneStats[sessionZone]
          
          if locationStats and zoneStats then
            locationStats.successes = locationStats.successes + 1
            locationStats.copper = locationStats.copper + sessionCopper
            locationStats.items = locationStats.items + sessionItemsCount
            
            zoneStats.successes = zoneStats.successes + 1
            zoneStats.copper = zoneStats.copper + sessionCopper
            zoneStats.items = zoneStats.items + sessionItemsCount
            
            DebugPrint("Location tracking: Updated %s (%s) to success - copper +%s, items +%s", 
                       sessionLocation, sessionZone, coinsToString(sessionCopper), tostring(sessionItemsCount))
          end
        end
      end
      
      DebugPrint("Finalize: +%s, items %d", coinsToString(sessionCopper), sessionItemsCount)
      local summaryMsg = buildSummaryMessage()
      PrintSessionSummary()
      ShareSummaryAndStats(nil, summaryMsg)
      PPT_LastSummary = summaryMsg
    else
      -- Failed session - attempts already recorded as failed, nothing more to do
      DebugPrint("Finalize: no loot (%s)", reasonIfZero or "no change")
      PrintNoCoin(reasonIfZero or "no change")
      PPT_LastSummary = nil
    end
  else
    DebugPrint("Finalize: no Pick Pocket in session (ignored)")
    PPT_LastSummary = nil
  end

  sessionActive = false
  inStealth = false
  lastMoney = nil
  resetSession()
end

------------------------------------------------------------
--                  STEALTH & MONEY HELPERS
------------------------------------------------------------
function getStealthFlag() return not not IsStealthed() end

function onStealthGained()
  if sessionActive then finalizeSession("restarted") end
  inStealth = true
  startSession()
end

function onStealthLost()
  inStealth = false
  windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END
  DebugPrint("Stealth: end (grace %ds)", WINDOW_AFTER_STEALTH_END)
  if not sessionActive then
    startSession()
    windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END
  end
end

function sweepMoneyNow()
  if not uiRecentlyOpened() then
    local now = GetMoney()
    if lastMoney and now > lastMoney then
      local diff = now - lastMoney
      DebugPrint("Money(sweep): +%s", coinsToString(diff))
      sessionCopper = sessionCopper + diff
      PPT_TotalCopper = PPT_TotalCopper + diff
      UpdateCoinageTracker()
      mirroredCopperThisSession = mirroredCopperThisSession + diff
      lastMoney = now
      
      -- Update total money achievements in real-time
      if updateTotalAchievementsOnly then
        updateTotalAchievementsOnly()
      elseif updateTotalAchievements then
        updateTotalAchievements()
      end
    end
  end
end

function recordItemLootFromMessage(msg)
  local link = msg:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)")
  if not link then return end
  local name = link:match("%[(.-)%]") or "Unknown Item"
  local qty = tonumber(msg:match("x(%d+)")) or 1
  sessionItems[name] = (sessionItems[name] or 0) + qty
  sessionItemsCount = sessionItemsCount + qty
  PPT_TotalItems = PPT_TotalItems + qty
  PPT_ItemCounts[name] = (PPT_ItemCounts[name] or 0) + qty
  DebugPrint("Item: +%dx %s", qty, name)
  
  -- Update total item achievements in real-time
  if updateTotalAchievementsOnly then
    updateTotalAchievementsOnly()
  elseif updateTotalAchievements then
    updateTotalAchievements()
  end
end

