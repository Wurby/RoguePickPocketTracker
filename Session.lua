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

-- Gather formatted zone stat lines sorted by average copper per success
function GetAllZoneStatLines()
  local zones = {}
  for name,data in pairs(PPT_ZoneStats) do
    table.insert(zones, {
      name = name,
      attempts = data.attempts or 0,
      successes = data.successes or 0,
      copper = data.copper or 0
    })
  end
  table.sort(zones, function(a,b)
    local avgA = (a.successes>0) and (a.copper/a.successes) or 0
    local avgB = (b.successes>0) and (b.copper/b.successes) or 0
    return avgA > avgB
  end)
  local lines = {}
  for _,z in ipairs(zones) do
    local pct = (z.attempts>0) and math.floor((z.successes/z.attempts)*100) or 0
    local avg = (z.successes>0) and math.floor(z.copper/z.successes) or 0
    local color = (pct>=80) and "|cff00ff00" or (pct>=50) and "|cffffff00" or "|cffff0000"
    table.insert(lines, string.format("%s%s|r - %d%% (%d/%d) avg %s", color, z.name, pct, z.successes, z.attempts, coinsToString(avg)))
  end
  if #lines == 0 then table.insert(lines, "No zone data") end
  return lines
end

-- Print heat map of all recorded zones
function PrintZoneStats()
  PPTPrint("----- Zone Heat Map -----")
  for _,line in ipairs(GetAllZoneStatLines()) do
    PPTPrint(" ", line)
  end
end

-- Print stats for the player's current zone
function PrintCurrentZoneStats()

  local zone = getCurrentZone()
  local data = PPT_ZoneStats[zone]
  if not data then
    PPTPrint("No data for zone:", zone)
    return
  end
  printStatReport("Zone Stats", zone, data)
end

function PrintCurrentLocationStats()
  local loc = getCurrentLocation()
  local data = PPT_LocationStats[loc]
  if not data then
    PPTPrint("No data for location:", loc)
    return
  end
  printStatReport("Location Stats", loc, data)
end

function printStatReport(title, name, data)
  local attempts = data.attempts or 0
  local successes = data.successes or 0
  local copper = data.copper or 0
  local pct = (attempts>0) and math.floor((successes/attempts)*100) or 0
  local avgSuccess = (successes>0) and math.floor(copper/successes) or 0
  local avgAttempt = (attempts>0) and math.floor(copper/attempts) or 0
  local color = (pct>=80) and "|cff00ff00" or (pct>=50) and "|cffffff00" or "|cffff0000"
  PPTPrint("----- "..title.." -----")
  PPTPrint(" ", string.format("%s%s|r - Total %s", color, name, coinsToString(copper)))
  PPTPrint(" ", string.format("Success Rate: %d%% (%d/%d)", pct, successes, attempts))
  PPTPrint(" ", string.format("Avg/Success: %s", coinsToString(avgSuccess)))
  PPTPrint(" ", string.format("Avg/Attempt: %s", coinsToString(avgAttempt)))
end

-- Reset all saved statistics
function ResetAllStats()
  PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems = 0,0,0,0
  PPT_ItemCounts, PPT_ZoneStats, PPT_LocationStats = {}, {}, {}
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
  sessionZone = nil
  sessionLocation = nil
  lastMoney = GetMoney()
  windowEndsAt = 0
end

function startSession()
  sessionActive = true
  resetSession()
  DebugPrint("Stealth: start")
end

function finalizeSession(reasonIfZero)
  if not sessionActive then return end
  local hadLoot = (sessionCopper > 0) or (sessionItemsCount > 0)

  if sessionHadPick then
    if hadLoot then
      local remainder = sessionCopper - mirroredCopperThisSession
      if remainder > 0 then
        PPT_TotalCopper = PPT_TotalCopper + remainder
        DebugPrint("Finalize: committed remainder +%s", coinsToString(remainder))
      end
      PPT_SuccessfulAttempts = PPT_SuccessfulAttempts + 1
      if sessionZone then
        local zs = PPT_ZoneStats[sessionZone] or {attempts=0, successes=0, copper=0}
        zs.successes = (zs.successes or 0) + 1
        zs.copper = (zs.copper or 0) + sessionCopper
        PPT_ZoneStats[sessionZone] = zs
      end
      if sessionLocation then
        local ls = PPT_LocationStats[sessionLocation] or {attempts=0, successes=0, copper=0}
        ls.successes = (ls.successes or 0) + 1
        ls.copper = (ls.copper or 0) + sessionCopper
        PPT_LocationStats[sessionLocation] = ls
      end
      DebugPrint("Finalize: +%s, items %d", coinsToString(sessionCopper), sessionItemsCount)
      PrintSessionSummary()
    else
      DebugPrint("Finalize: no loot (%s)", reasonIfZero or "no change")
      PrintNoCoin(reasonIfZero or "no change")
    end
  else
    DebugPrint("Finalize: no Pick Pocket in session (ignored)")
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
      mirroredCopperThisSession = mirroredCopperThisSession + diff
      lastMoney = now
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
end

