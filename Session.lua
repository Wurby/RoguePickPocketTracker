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
sessionTargetCount = 0
sessionItemsCount = 0
sessionItems = {}

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
  sessionTargetCount = 0
  sessionItemsCount = 0
  sessionItems = {}
  attemptedGUIDs = {}
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
      DebugPrint("Finalize: +%s, items %d", coinsToString(sessionCopper), sessionItemsCount)
      PrintSessionSummary()
      if Achievements then
        if Achievements.EARN_25G_SESSION and sessionCopper >= Achievements.EARN_25G_SESSION.goal then
          UpdateAchievement("EARN_25G_SESSION", sessionCopper)
        end
        if Achievements.EARN_100G_SESSION and sessionCopper >= Achievements.EARN_100G_SESSION.goal then
          UpdateAchievement("EARN_100G_SESSION", sessionCopper)
        end
        local itemAch = {
          "LOOT_1_ITEM_SESSION",
          "LOOT_2_ITEMS_SESSION",
          "LOOT_5_ITEMS_SESSION",
          "LOOT_10_ITEMS_SESSION",
        }
        for _, id in ipairs(itemAch) do
          if Achievements[id] and sessionItemsCount >= Achievements[id].goal then
            UpdateAchievement(id, sessionItemsCount)
          end
        end
        local targetAch = {
          "SESSION_TARGETS_1",
          "SESSION_TARGETS_3",
          "SESSION_TARGETS_5",
          "SESSION_TARGETS_10",
          "SESSION_TARGETS_15",
        }
        for _, id in ipairs(targetAch) do
          if Achievements[id] and sessionTargetCount >= Achievements[id].goal then
            UpdateAchievement(id, sessionTargetCount)
          end
        end
      end
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

