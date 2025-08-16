-- RoguePickPocketTracker.lua
-- .toc MUST contain:
-- ## SavedVariables: PPT_ShowMsg, PPT_Debug, PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems, PPT_ItemCounts

------------------------------------------------------------
--                     GLOBAL STATE (SV)
------------------------------------------------------------
PPT_ShowMsg              = (PPT_ShowMsg ~= nil) and PPT_ShowMsg or true
PPT_Debug                = PPT_Debug or false
PPT_TotalCopper          = tonumber(PPT_TotalCopper) or 0
PPT_TotalAttempts        = tonumber(PPT_TotalAttempts) or 0
PPT_SuccessfulAttempts   = tonumber(PPT_SuccessfulAttempts) or 0
PPT_TotalItems           = tonumber(PPT_TotalItems) or 0
PPT_ItemCounts           = type(PPT_ItemCounts) == "table" and PPT_ItemCounts or {}

------------------------------------------------------------
--                     CONSTANTS / UTILS
------------------------------------------------------------
local WINDOW_AFTER_STEALTH_END = 2
local POLL_INTERVAL = 0.10
local PICK_ID = 921 -- Pick Pocket
local STEALTH_IDS = { [1784]=true, [1785]=true, [1786]=true, [1787]=true }

local COLOR = { blue="|cff4da3ff", dgreen="|cff006400", gray="|cffb0b0b0", reset="|r" }
local function PPTTag() return COLOR.dgreen.."[PPT]"..COLOR.reset end
local function PPTPrint(...) local t={...}; for i=1,#t do t[i]=tostring(t[i]) end; print(PPTTag().." "..COLOR.blue..table.concat(t," ")..COLOR.reset) end
local function DebugPrint(fmt, ...) if not PPT_Debug then return end; local msg=(select("#",...)>0) and string.format(fmt, ...) or tostring(fmt); print(PPTTag().." "..COLOR.gray.."[DBG]"..COLOR.reset.." "..COLOR.blue..msg..COLOR.reset) end

local function escpat(s) return (s:gsub("([%(%)%+%-%*%?%[%]%^%$%%%.])","%%%1")) end
local GOLD_INLINE   = (GOLD_AMOUNT   and escpat(GOLD_AMOUNT):gsub("%%d","(%%d+)"))   or "(%d+)%s*Gold"
local SILVER_INLINE = (SILVER_AMOUNT and escpat(SILVER_AMOUNT):gsub("%%d","(%%d+)")) or "(%d+)%s*Silver"
local COPPER_INLINE = (COPPER_AMOUNT and escpat(COPPER_AMOUNT):gsub("%%d","(%%d+)")) or "(%d+)%s*Copper"

local WRAPPERS = {}
if type(YOU_LOOT_MONEY)     == "string" then table.insert(WRAPPERS, YOU_LOOT_MONEY) end
if type(LOOT_MONEY_SPLIT)   == "string" then table.insert(WRAPPERS, LOOT_MONEY_SPLIT) end
if type(LOOT_MONEY_REFUND)  == "string" then table.insert(WRAPPERS, LOOT_MONEY_REFUND) end

local function unwrapMoneyText(msg)
  for _,fmt in ipairs(WRAPPERS) do
    local pat = "^" .. escpat(fmt):gsub("%%s","(.+)") .. "$"
    local inner = msg:match(pat)
    if inner then return inner end
  end
  return msg
end

local function parseMoneyText(text)
  local gSum, sSum, cSum = 0, 0, 0
  for n in text:gmatch(GOLD_INLINE)   do gSum = gSum + tonumber(n) end
  for n in text:gmatch(SILVER_INLINE) do sSum = sSum + tonumber(n) end
  for n in text:gmatch(COPPER_INLINE) do cSum = cSum + tonumber(n) end
  return gSum*10000 + sSum*100 + cSum
end

local function coinsToString(c)
  local g = math.floor(c / 10000)
  local s = math.floor((c % 10000) / 100)
  local k = c % 100
  local parts = {}
  if g>0 then table.insert(parts, g.."g") end
  if s>0 then table.insert(parts, s.."s") end
  if k>0 or #parts==0 then table.insert(parts, k.."c") end
  return table.concat(parts, " ")
end

------------------------------------------------------------
--                     SESSION (LOCAL) STATE
------------------------------------------------------------
local playerGUID = nil
local sessionActive = false
local inStealth = false
local windowEndsAt = 0
local lastMoney = nil
local sessionCopper = 0
local mirroredCopperThisSession = 0
local sessionHadPick = false
local attemptedGUIDs = {}      -- one attempt per target per session
local sessionItemsCount = 0
local sessionItems = {}

-- UI-guard helpers
local recentUI = {}
local function markUI(name) recentUI[name] = GetTime(); DebugPrint("UI: %s", name) end
local function uiRecentlyOpened()
  local now = GetTime()
  return (recentUI.MERCHANT_SHOW   and now - recentUI.MERCHANT_SHOW   < 2)
      or (recentUI.MAIL_SHOW       and now - recentUI.MAIL_SHOW       < 2)
      or (recentUI.TAXIMAP_OPENED  and now - recentUI.TAXIMAP_OPENED  < 2)
      or false
end

------------------------------------------------------------
--                     PRINT HELPERS
------------------------------------------------------------
local function PrintTotal()
  PPTPrint(" ", "Total Coinage: " .. coinsToString(PPT_TotalCopper))
  PPTPrint(" ", "Total Items:", PPT_TotalItems)
end

local function PrintNoCoin(reason)
  if PPT_ShowMsg then
    PPTPrint("Pick Pocket: no loot", reason and ("("..reason..")") or "")
  end
end

local function PrintStats()
  local avgPerAttempt = (PPT_TotalAttempts > 0) and math.floor(PPT_TotalCopper / PPT_TotalAttempts) or 0
  local avgPerSuccess = (PPT_SuccessfulAttempts > 0) and math.floor(PPT_TotalCopper / PPT_SuccessfulAttempts) or 0
  PPTPrint("Attempts:", PPT_TotalAttempts)
  PPTPrint("Successes:", PPT_SuccessfulAttempts)
  PPTPrint("Fails:", (PPT_TotalAttempts - PPT_SuccessfulAttempts))
  PPTPrint("Avg/Attempt:", coinsToString(avgPerAttempt))
  PPTPrint("Avg/Success:", coinsToString(avgPerSuccess))
end

-- End-of-session block with headers like /pp
local function PrintSessionSummary()
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
local function resetSession()
  sessionCopper = 0
  mirroredCopperThisSession = 0
  sessionHadPick = false
  sessionItemsCount = 0
  sessionItems = {}
  attemptedGUIDs = {}
  lastMoney = GetMoney()
  windowEndsAt = 0
end

local function startSession()
  sessionActive = true
  resetSession()
  DebugPrint("Stealth: start")
end

local function finalizeSession(reasonIfZero)
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
      -- Nicely formatted summary with headers:
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
local function getStealthFlag() return not not IsStealthed() end

local function onStealthGained()
  if sessionActive then finalizeSession("restarted") end
  inStealth = true
  startSession()
end

local function onStealthLost()
  inStealth = false
  windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END
  DebugPrint("Stealth: end (grace %ds)", WINDOW_AFTER_STEALTH_END)
  if not sessionActive then
    startSession()
    windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END
  end
end

local function sweepMoneyNow()
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

local function recordItemLootFromMessage(msg)
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
    -- If you want a strict name check, use your actual folder name:
    -- local addon = ...; if addon ~= "RoguePickPocketTracker" then return end
    DebugPrint(("SV @load: copper=%d attempts=%d succ=%d items=%d")
      :format(PPT_TotalCopper or -1, PPT_TotalAttempts or -1, PPT_SuccessfulAttempts or -1, PPT_TotalItems or -1))

  elseif event == "PLAYER_ENTERING_WORLD" then
    playerGUID = UnitGUID("player")
    inStealth, sessionActive = false, false
    lastMoney = GetMoney() -- baseline for sweeps even before a session
    if getStealthFlag() then onStealthGained() end

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

    -- Stealth auras on player
    if dstGUID == playerGUID and STEALTH_IDS[spellID] then
      if sub == "SPELL_AURA_APPLIED" then onStealthGained(); return
      elseif sub == "SPELL_AURA_REMOVED" then onStealthLost(); return end
    end

    -- Pick Pocket attempt (one per target per session)
    if sub == "SPELL_CAST_SUCCESS" and srcGUID == playerGUID and spellID == PICK_ID then
      if not sessionActive then
        startSession()
        if not getStealthFlag() then windowEndsAt = GetTime() + WINDOW_AFTER_STEALTH_END end
      end
      sessionHadPick = true
      if dstGUID and not attemptedGUIDs[dstGUID] then
        attemptedGUIDs[dstGUID] = true
        PPT_TotalAttempts = PPT_TotalAttempts + 1
        DebugPrint("Pick: attempt recorded for %s", tostring(dstGUID))
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
    -- Always sweep so last coin is mirrored even if the session flag got missed.
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
  if msg == "togglemsg" then
    PPT_ShowMsg = not PPT_ShowMsg
    PPTPrint("showMsg =", tostring(PPT_ShowMsg)); return
  elseif msg == "reset" then
    PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems = 0,0,0,0
    PPT_ItemCounts = {}
    PPTPrint("Stats reset."); return
  elseif msg == "debug" then
    PPT_Debug = not PPT_Debug
    PPTPrint("debug =", tostring(PPT_Debug)); return
  elseif msg == "items" then
    PPTPrint("Cumulative items:", PPT_TotalItems)
    local list = {}
    for name, cnt in pairs(PPT_ItemCounts) do table.insert(lines, string.format("%s x%d", name, cnt)) end
    local lines = {}
    for name, cnt in pairs(PPT_ItemCounts) do table.insert(lines, string.format("%s x%d", name, cnt)) end
    table.sort(lines, function(a,b) return a:lower() < b:lower() end)
    for _,ln in ipairs(lines) do PPTPrint(" ", ln) end
    return
  end

  PPTPrint("----- Totals -----");  PrintTotal()
  PPTPrint("----- Stats -----");   PrintStats()
  PPTPrint("----- Help -----");    PPTPrint("Usage: /pp [togglemsg, reset, debug, items]")
end


