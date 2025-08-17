-- Core.lua
-- Global state, constants, and utility functions for RoguePickPocketTracker

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
PPT_ZoneStats            = type(PPT_ZoneStats) == "table" and PPT_ZoneStats or {}

------------------------------------------------------------
--                     CONSTANTS / UTILS
------------------------------------------------------------
WINDOW_AFTER_STEALTH_END = 2
POLL_INTERVAL = 0.10
PICK_ID = 921 -- Pick Pocket
STEALTH_IDS = { [1784]=true, [1785]=true, [1786]=true, [1787]=true }

COLOR = { blue="|cff4da3ff", dgreen="|cff006400", gray="|cffb0b0b0", reset="|r" }
function PPTTag() return COLOR.dgreen.."[PPT]"..COLOR.reset end
function PPTPrint(...) local t={...}; for i=1,#t do t[i]=tostring(t[i]) end; print(PPTTag().." "..COLOR.blue..table.concat(t," ")..COLOR.reset) end
function DebugPrint(fmt, ...) if not PPT_Debug then return end; local msg=(select("#",...)>0) and string.format(fmt, ...) or tostring(fmt); print(PPTTag().." "..COLOR.gray.."[DBG]"..COLOR.reset.." "..COLOR.blue..msg..COLOR.reset) end

local function escpat(s) return (s:gsub("([%(%)%+%-%*%?%[%]%^%$%%%.])","%%%1")) end
local GOLD_INLINE   = (GOLD_AMOUNT   and escpat(GOLD_AMOUNT):gsub("%%d","(%%d+)"))   or "(%d+)%s*Gold"
local SILVER_INLINE = (SILVER_AMOUNT and escpat(SILVER_AMOUNT):gsub("%%d","(%%d+)")) or "(%d+)%s*Silver"
local COPPER_INLINE = (COPPER_AMOUNT and escpat(COPPER_AMOUNT):gsub("%%d","(%%d+)")) or "(%d+)%s*Copper"

local WRAPPERS = {}
if type(YOU_LOOT_MONEY)     == "string" then table.insert(WRAPPERS, YOU_LOOT_MONEY) end
if type(LOOT_MONEY_SPLIT)   == "string" then table.insert(WRAPPERS, LOOT_MONEY_SPLIT) end
if type(LOOT_MONEY_REFUND)  == "string" then table.insert(WRAPPERS, LOOT_MONEY_REFUND) end

function unwrapMoneyText(msg)
  for _,fmt in ipairs(WRAPPERS) do
    local pat = "^" .. escpat(fmt):gsub("%%s","(.+)") .. "$"
    local inner = msg:match(pat)
    if inner then return inner end
  end
  return msg
end

function parseMoneyText(text)
  local gSum, sSum, cSum = 0, 0, 0
  for n in text:gmatch(GOLD_INLINE)   do gSum = gSum + tonumber(n) end
  for n in text:gmatch(SILVER_INLINE) do sSum = sSum + tonumber(n) end
  for n in text:gmatch(COPPER_INLINE) do cSum = cSum + tonumber(n) end
  return gSum*10000 + sSum*100 + cSum
end

function coinsToString(c)
  local g = math.floor(c / 10000)
  local s = math.floor((c % 10000) / 100)
  local k = c % 100
  local parts = {}
  if g>0 then table.insert(parts, g.."g") end
  if s>0 then table.insert(parts, s.."s") end
  if k>0 or #parts==0 then table.insert(parts, k.."c") end
  return table.concat(parts, " ")
end

function getCurrentZone()
  local zone = GetRealZoneText() or GetZoneText() or "Unknown Zone"
  local sub = GetSubZoneText()
  if sub and sub ~= "" and sub ~= zone then
    zone = zone .. " - " .. sub
  end
  return zone
end

