-- SessionToast.lua
-- Session-specific toast functionality for RoguePickPocketTracker

------------------------------------------------------------
--                   SESSION TOAST CLASS
------------------------------------------------------------

-- Session Toast Object (inherits from ToastCore)
SessionToast = setmetatable({}, {__index = ToastCore})
SessionToast.__index = SessionToast

-- Create a new session toast
function SessionToast:New()
  local toast = ToastCore:New("session")
  setmetatable(toast, self)
  toast:SetStyle(ToastStyles.session)
  toast:SetDuration(4.0) -- Slightly longer for sessions
  return toast
end

-- Set session data
function SessionToast:SetSessionData(sessionData)
  local copper = sessionData.copper or 0
  local itemsCount = sessionData.itemsCount or 0
  local items = sessionData.items or {}
  local duration = sessionData.duration or 0
  local mobCount = sessionData.mobCount or 0
  
  -- Build session summary
  local name = "+" .. coinsToString(copper)
  
  -- Build description with session details
  local descParts = {}
  
  -- Add duration if available
  if duration > 0 then
    table.insert(descParts, FormatSessionTime(duration))
  end
  
  -- Add mob count if available
  if mobCount > 0 then
    table.insert(descParts, mobCount .. " mobs")
  end
  
  -- Add items if any
  if itemsCount > 0 then
    local itemLines = {}
    for itemName, count in pairs(items) do
      table.insert(itemLines, string.format("%s x%d", itemName, count))
    end
    table.sort(itemLines)
    if #itemLines <= 3 then
      -- Show all items if 3 or fewer
      for _, line in ipairs(itemLines) do
        table.insert(descParts, line)
      end
    else
      -- Show first 2 items and a summary
      table.insert(descParts, itemLines[1])
      table.insert(descParts, itemLines[2])
      table.insert(descParts, string.format("and %d more items", itemsCount - 2))
    end
  else
    table.insert(descParts, "No items obtained")
  end
  
  local description = table.concat(descParts, " | ")
  
  self:SetContent({
    name = name,
    description = description,
    icon = "Interface\\Icons\\Ability_Stealth"
  })
  
  return self
end

------------------------------------------------------------
--                   SESSION TOAST FUNCTIONS
------------------------------------------------------------

-- Show session completion toast using current session data
function ShowSessionCompletionToast()
  -- Only show if session toasts are enabled
  if not PPT_ShowSessionToasts then
    return
  end
  
  local sessionData = {
    copper = sessionCopper or 0,
    itemsCount = sessionItemsCount or 0,
    items = sessionItems or {},
    mobCount = sessionMobCount or 0
  }
  
  -- Calculate session duration if we have timestamps
  if sessionStartTime then
    sessionData.duration = GetTime() - sessionStartTime
  end
  
  local toast = SessionToast:New()
  toast:SetSessionData(sessionData)
  
  -- Sessions can be shown during combat since they're important
  QueueToast(toast)
end

-- Show session toast using stored data (for manual commands)
function ShowStoredSessionToast()
  if not PPT_ShowSessionToasts then
    return
  end
  
  if not PPT_LastSessionData then
    ShowErrorToast("No Session Data", "No previous session data available")
    return
  end
  
  local toast = SessionToast:New()
  toast:SetSessionData(PPT_LastSessionData)
  
  -- Manual commands bypass combat
  QueueToast(toast)
end

-- Legacy function for compatibility
function ShowSessionToast(useStoredData)
  if useStoredData then
    ShowStoredSessionToast()
  else
    ShowSessionCompletionToast()
  end
end
