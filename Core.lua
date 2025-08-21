-- Core.lua
-- Global state, constants, and utility functions for RoguePickPocketTracker

------------------------------------------------------------
--                     GLOBAL STATE (SV)
------------------------------------------------------------
PPT_ShowMsg              = (PPT_ShowMsg ~= nil) and PPT_ShowMsg or true
PPT_Debug                = PPT_Debug or false  -- Disable debug by default
PPT_ShareGroup           = (PPT_ShareGroup ~= nil) and PPT_ShareGroup or false
PPT_ShowToasts           = (PPT_ShowToasts ~= nil) and PPT_ShowToasts or true
PPT_ShowSessionToasts    = (PPT_ShowSessionToasts ~= nil) and PPT_ShowSessionToasts or true
PPT_ShowAchievementToasts = (PPT_ShowAchievementToasts ~= nil) and PPT_ShowAchievementToasts or true
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
PPT_LastSessionData      = type(PPT_LastSessionData) == "table" and PPT_LastSessionData or nil
-- Stopwatch/Tracking Feature Variables
PPT_StopwatchEnabled     = (PPT_StopwatchEnabled ~= nil) and PPT_StopwatchEnabled or true
PPT_TrackingActive       = (PPT_TrackingActive ~= nil) and PPT_TrackingActive or false
PPT_TrackingStartTime    = tonumber(PPT_TrackingStartTime) or nil
PPT_TrackingStartCopper  = tonumber(PPT_TrackingStartCopper) or 0
PPT_TrackingStartItems   = tonumber(PPT_TrackingStartItems) or 0
-- Session Display Options
PPT_SessionDisplayEnabled = (PPT_SessionDisplayEnabled ~= nil) and PPT_SessionDisplayEnabled or true

------------------------------------------------------------
--                    DATA MIGRATION
------------------------------------------------------------
local CURRENT_DATA_VERSION = 4  -- Increment this when introducing breaking changes

function shouldResetData(savedVersion)
  -- Add version numbers here that require full data reset
  local breakingVersions = {
    1, -- Location-based analytics introduction
    -- 2, -- Achievement system introduction (non-breaking)
    3, -- Breaking change for release versioning
    4,
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
    -- Use existing reset logic to avoid duplication
    -- Note: ResetAllStats() is available since this runs during ADDON_LOADED
    if ResetAllStats then
      ResetAllStats()
      DebugPrint("Used ResetAllStats() for migration reset")
    else
      -- Fallback: manual reset if function not available (shouldn't happen)
      PPT_TotalCopper, PPT_TotalAttempts, PPT_SuccessfulAttempts, PPT_TotalItems = 0,0,0,0
      PPT_ItemCounts = {}
      PPT_ZoneStats = {}
      PPT_LocationStats = {}
      PPT_Achievements = {}
      PPT_CompletedAchievements = {}
      UpdateCoinageTracker()
      DebugPrint("Used fallback manual reset for migration")
    end
    
    -- Notify user about the reset
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

------------------------------------------------------------
--                   STOPWATCH/TRACKING FUNCTIONS
------------------------------------------------------------

-- Start tracking pick pocket earnings
function StartPickPocketTracking()
  if PPT_TrackingActive then
    DebugPrint("Tracking already active, resetting...")
  end
  
  PPT_TrackingActive = true
  PPT_TrackingStartTime = GetTime()
  PPT_TrackingStartCopper = PPT_TotalCopper
  PPT_TrackingStartItems = PPT_TotalItems
  
  DebugPrint("Pick pocket tracking started at %d copper, %d items", PPT_TrackingStartCopper, PPT_TrackingStartItems)
  
  -- Show start toast
  ShowToast({
    type = "tracking",
    name = "Tracking Started",
    description = "Pick pocket earnings tracking is now active",
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
  })
  
  -- Update the UI to reflect the new state
  if UpdateCoinageTracker then
    UpdateCoinageTracker()
  end
  
  -- Force UI to resize properly
  if ForceUIResize then
    ForceUIResize()
  end
end

-- Stop tracking pick pocket earnings
function StopPickPocketTracking()
  if not PPT_TrackingActive then
    DebugPrint("Tracking not active")
    -- Show error toast
    ShowToast({
      type = "tracking",
      name = "Not Tracking",
      description = "Pick pocket tracking is not currently active",
      icon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
    })
    return
  end
  
  -- Calculate final stats before stopping
  local elapsedTime = GetTime() - (PPT_TrackingStartTime or 0)
  local earnedCopper = PPT_TotalCopper - PPT_TrackingStartCopper
  local earnedItems = PPT_TotalItems - PPT_TrackingStartItems
  
  -- Calculate final rates
  local minutes = elapsedTime / 60
  local hours = elapsedTime / 3600
  local copperPerMinute = minutes > 0 and (earnedCopper / minutes) or 0
  local copperPerHour = hours > 0 and (earnedCopper / hours) or 0
  
  -- Now stop tracking
  PPT_TrackingActive = false
  
  DebugPrint("Pick pocket tracking stopped after %.2f seconds, earned %d copper, %d items", 
             elapsedTime, earnedCopper, earnedItems)
  
  -- Build comprehensive description for toast
  local description = string.format("Time: %s | Earned: %s | %s/hr", 
                                   FormatTrackingTime(elapsedTime),
                                   coinsToString(earnedCopper),
                                   coinsToString(math.floor(copperPerHour)))
  
  if earnedItems > 0 then
    description = description .. string.format(" | Items: %d", earnedItems)
  end
  
  -- Show final report toast
  ShowToast({
    type = "tracking",
    name = "Tracking Complete",
    description = description,
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
  })
  
  -- Update the UI to reflect the new state
  if UpdateCoinageTracker then
    UpdateCoinageTracker()
  end
  
  -- Force UI to resize properly
  if ForceUIResize then
    ForceUIResize()
  end
end

-- Get current tracking stats
function GetTrackingStats()
  if not PPT_TrackingActive or not PPT_TrackingStartTime then
    return nil
  end
  
  local elapsedTime = GetTime() - PPT_TrackingStartTime
  local earnedCopper = PPT_TotalCopper - PPT_TrackingStartCopper
  local earnedItems = PPT_TotalItems - PPT_TrackingStartItems
  
  -- Calculate per minute and per hour rates
  local minutes = elapsedTime / 60
  local hours = elapsedTime / 3600
  
  local copperPerMinute = minutes > 0 and (earnedCopper / minutes) or 0
  local copperPerHour = hours > 0 and (earnedCopper / hours) or 0
  local itemsPerMinute = minutes > 0 and (earnedItems / minutes) or 0
  local itemsPerHour = hours > 0 and (earnedItems / hours) or 0
  
  return {
    elapsedTime = elapsedTime,
    earnedCopper = earnedCopper,
    earnedItems = earnedItems,
    copperPerMinute = copperPerMinute,
    copperPerHour = copperPerHour,
    itemsPerMinute = itemsPerMinute,
    itemsPerHour = itemsPerHour
  }
end

-- Format tracking time for display
function FormatTrackingTime(seconds)
    if not seconds or seconds <= 0 then return "0:00" end
    
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    
    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60
        return string.format("%d:%02d:%02d", hours, minutes, remainingSeconds)
    else
        return string.format("%d:%02d", minutes, remainingSeconds)
    end
end

-- Show a tracking report
function ShowTrackingReport()
  local stats = GetTrackingStats()
  if not stats then
    -- Show error toast
    ShowToast({
      type = "tracking",
      name = "No Tracking Data",
      description = "No tracking session is currently active",
      icon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
    })
    return
  end
  
  -- Build comprehensive description for toast
  local description = string.format("Time: %s | Earned: %s | %s/hr", 
                                   FormatTrackingTime(stats.elapsedTime),
                                   coinsToString(stats.earnedCopper),
                                   coinsToString(math.floor(stats.copperPerHour)))
  
  if stats.earnedItems > 0 then
    description = description .. string.format(" | Items: %d", stats.earnedItems)
  end
  
  -- Show tracking report toast
  ShowToast({
    type = "tracking",
    name = "Tracking Report",
    description = description,
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
  })
end

