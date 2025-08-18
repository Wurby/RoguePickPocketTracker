-- Core.lua
-- Global state, constants, and utility functions for RoguePickPocketTracker

------------------------------------------------------------
--                     GLOBAL STATE (SV)
------------------------------------------------------------
PPT_ShowMsg              = (PPT_ShowMsg ~= nil) and PPT_ShowMsg or true
PPT_Debug                = PPT_Debug or false
PPT_ShareGroup           = (PPT_ShareGroup ~= nil) and PPT_ShareGroup or false
PPT_TotalCopper          = tonumber(PPT_TotalCopper) or 0
PPT_TotalAttempts        = tonumber(PPT_TotalAttempts) or 0
PPT_SuccessfulAttempts   = tonumber(PPT_SuccessfulAttempts) or 0
PPT_TotalItems           = tonumber(PPT_TotalItems) or 0
PPT_ItemCounts           = type(PPT_ItemCounts) == "table" and PPT_ItemCounts or {}
PPT_ZoneStats            = type(PPT_ZoneStats) == "table" and PPT_ZoneStats or {}
PPT_LocationStats        = type(PPT_LocationStats) == "table" and PPT_LocationStats or {}
PPT_DataVersion          = PPT_DataVersion or 0
PPT_Achievements         = type(PPT_Achievements) == "table" and PPT_Achievements or {}
PPT_CompletedAchievements = type(PPT_CompletedAchievements) == "table" and PPT_CompletedAchievements or {}
PPT_AlertOpacity         = tonumber(PPT_AlertOpacity) or 80

------------------------------------------------------------
--                    DATA MIGRATION
------------------------------------------------------------
local CURRENT_DATA_VERSION = 2  -- Increment this when introducing breaking changes

function shouldResetData(savedVersion)
  -- Add version numbers here that require full data reset
  local breakingVersions = {
    1, -- Location-based analytics introduction
    -- 2, -- Achievement system introduction (non-breaking)
    -- 3, -- Future breaking change
  }
  
  for _, breakingVersion in ipairs(breakingVersions) do
    if savedVersion < breakingVersion then
      return true, breakingVersion
    end
  end
  return false, nil
end

function migrateData()
  local savedVersion = PPT_DataVersion or 0
  
  if savedVersion == CURRENT_DATA_VERSION then
    DebugPrint("Data version %d current, no migration needed", savedVersion)
    return
  end
  
  local needsReset, breakingVersion = shouldResetData(savedVersion)
  
  if needsReset then
    -- Reset all data
    PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems = 0,0,0,0
    PPT_ItemCounts = {}
    PPT_ZoneStats = {}
    PPT_LocationStats = {}
    PPT_Achievements = {}
    PPT_CompletedAchievements = {}
    
    -- Notify user
    PPTPrint("=== DATA RESET NOTICE ===")
    PPTPrint("Your pickpocketing statistics have been reset due to addon improvements.")
    PPTPrint("New features added: Location-based analytics and enhanced zone tracking!")
    PPTPrint("This was necessary to ensure data accuracy with the new zone tracking system.")
    PPTPrint("Your progress will now be tracked more accurately.")
    PPTPrint("=========================")
    
    DebugPrint("Data reset performed: v%d -> v%d (breaking change in v%d)", 
               savedVersion, CURRENT_DATA_VERSION, breakingVersion)
  else
    -- Future: Add non-breaking migrations here
    DebugPrint("Data migrated: v%d -> v%d (no reset needed)", savedVersion, CURRENT_DATA_VERSION)
  end
  
  -- Update version
  PPT_DataVersion = CURRENT_DATA_VERSION
end

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

------------------------------------------------------------
--                    LOCATION HELPERS
------------------------------------------------------------
function getCurrentZone()
  if GetRealZoneText then
    return GetRealZoneText() or "Unknown Zone"
  elseif GetZoneText then
    return GetZoneText() or "Unknown Zone"
  else
    return "Unknown Zone"
  end
end

function getCurrentLocation()
  local zone = getCurrentZone()
  local subZone = ""
  
  if GetSubZoneText then
    subZone = GetSubZoneText()
  end
  
  if subZone and subZone ~= "" and subZone ~= zone then
    return zone .. " - " .. subZone
  else
    return zone
  end
end

function initZoneStats(zone)
  if not PPT_ZoneStats[zone] then
    PPT_ZoneStats[zone] = {
      copper = 0,
      attempts = 0,
      successes = 0,
      items = 0
    }
  end
  return PPT_ZoneStats[zone]
end

function initLocationStats(location)
  if not PPT_LocationStats[location] then
    PPT_LocationStats[location] = {
      copper = 0,
      attempts = 0,
      successes = 0,
      items = 0
    }
  end
  return PPT_LocationStats[location]
end

function recordPickPocketAttempt(zone, location, wasSuccessful, copper, items)
  copper = copper or 0
  items = items or 0
  
  -- Update zone stats
  local zoneStats = initZoneStats(zone)
  zoneStats.attempts = zoneStats.attempts + 1
  if wasSuccessful then
    zoneStats.successes = zoneStats.successes + 1
  end
  zoneStats.copper = zoneStats.copper + copper
  zoneStats.items = zoneStats.items + items
  
  -- Update location stats
  local locationStats = initLocationStats(location)
  locationStats.attempts = locationStats.attempts + 1
  if wasSuccessful then
    locationStats.successes = locationStats.successes + 1
  end
  locationStats.copper = locationStats.copper + copper
  locationStats.items = locationStats.items + items
  
  DebugPrint("Location tracking: %s (%s) - attempt=%s, copper=%s, items=%s", 
             location, zone, tostring(wasSuccessful), tostring(copper), tostring(items))
end

function getZoneStatsSummary()
  local zones = {}
  for zone, stats in pairs(PPT_ZoneStats) do
    table.insert(zones, {zone = zone, stats = stats})
  end
  table.sort(zones, function(a, b) return a.stats.copper > b.stats.copper end)
  return zones
end

function getLocationStatsSummary(filterZone)
  local locations = {}
  for location, stats in pairs(PPT_LocationStats) do
    if not filterZone or location:find("^" .. filterZone:gsub("([%(%)%+%-%*%?%[%]%^%$%%%.])","%%%1")) then
      table.insert(locations, {location = location, stats = stats})
    end
  end
  table.sort(locations, function(a, b) return a.stats.copper > b.stats.copper end)
  return locations
end

