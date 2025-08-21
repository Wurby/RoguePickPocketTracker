-- Toast.lua
-- Main toast integration and legacy compatibility for RoguePickPocketTracker

------------------------------------------------------------
--                    TOAST INTEGRATION
------------------------------------------------------------

-- Initialize the toast system
function InitializeToastSystem()
  -- Ensure toast styles are loaded
  if not ToastStyles then
    PPT_Debug("Warning: ToastStyles not loaded, creating defaults")
    ToastStyles = {
      default = {
        bgColor = {0.1, 0.1, 0.1, 0.9},
        borderColor = {1, 1, 1, 1},
        textColor = {1, 1, 1, 1}
      }
    }
  end
  
  -- Initialize the toast core system
  if ToastCore and ToastCore.Initialize then
    ToastCore:Initialize()
  end
  
  PPT_Debug("Toast system initialized")
end

------------------------------------------------------------
--                    LEGACY COMPATIBILITY
------------------------------------------------------------

-- Legacy function for showing simple toasts
function ShowToast(text, duration, toastType)
  if not text then
    PPT_Debug("ShowToast called with no text")
    return
  end
  
  local toast = CreateToast(toastType or "info")
  toast:SetContent({
    name = text,
    description = "",
    icon = nil
  })
  
  if duration then
    toast:SetDuration(duration)
  end
  
  QueueToast(toast)
end

-- Legacy function for showing achievement toasts
function ShowAchievementToast_Legacy(achievementName, description, icon)
  local toast = CreateToast("achievement")
  toast:SetContent({
    name = achievementName or "Achievement",
    description = description or "",
    icon = icon
  })
  
  if PPT_InCombat then
    AddToPostCombatQueue(function()
      QueueToast(toast)
    end)
  else
    QueueToast(toast)
  end
end

-- Legacy function for showing session toasts
function ShowSessionToast_Legacy(sessionData)
  if not PPT_ShowSessionToasts then
    return
  end
  
  local toast = SessionToast:New()
  
  if sessionData then
    toast:SetSessionData(sessionData)
  else
    -- Use current session data
    ShowSessionCompletionToast()
    return
  end
  
  QueueToast(toast)
end

------------------------------------------------------------
--                    CONVENIENCE FUNCTIONS
------------------------------------------------------------

-- Show a quick info toast
function ShowInfoToast(title, description)
  local toast = CreateToast("info")
  toast:SetContent({
    name = title or "Information",
    description = description or "",
    icon = "Interface\\Icons\\Inv_Misc_Note_01"
  })
  QueueToast(toast)
end

-- Show a quick error toast
function ShowErrorToast(title, description)
  local toast = CreateToast("error")
  toast:SetContent({
    name = title or "Error",
    description = description or "",
    icon = "Interface\\Icons\\Ability_Spy"
  })
  QueueToast(toast)
end

-- Show a quick tracking toast
function ShowTrackingToast(title, description)
  local toast = CreateToast("tracking")
  toast:SetContent({
    name = title or "Tracking",
    description = description or "",
    icon = "Interface\\Icons\\Ability_Stealth"
  })
  QueueToast(toast)
end

------------------------------------------------------------
--                    TOAST QUEUE MANAGEMENT
------------------------------------------------------------

-- Post-combat toast queue
local postCombatToastQueue = {}

-- Add function to post-combat queue
function AddToPostCombatQueue(func)
  if type(func) == "function" then
    table.insert(postCombatToastQueue, func)
    PPT_Debug("Added function to post-combat toast queue")
  end
end

-- Process post-combat queue
function ProcessPostCombatToastQueue()
  if #postCombatToastQueue > 0 then
    PPT_Debug("Processing " .. #postCombatToastQueue .. " post-combat toasts")
    
    for _, func in ipairs(postCombatToastQueue) do
      if type(func) == "function" then
        func()
      end
    end
    
    -- Clear the queue
    postCombatToastQueue = {}
  end
end

-- Clear post-combat queue (in case of errors)
function ClearPostCombatToastQueue()
  postCombatToastQueue = {}
  PPT_Debug("Cleared post-combat toast queue")
end

------------------------------------------------------------
--                    SETTINGS INTEGRATION
------------------------------------------------------------

-- Check if toasts are enabled globally
function AreToastsEnabled()
  return PPT_ShowToasts ~= false -- Default to true if not set
end

-- Check if achievement toasts are enabled
function AreAchievementToastsEnabled()
  return PPT_ShowAchievementToasts ~= false -- Default to true if not set
end

-- Check if session toasts are enabled
function AreSessionToastsEnabled()
  return PPT_ShowSessionToasts ~= false -- Default to true if not set
end

------------------------------------------------------------
--                    INITIALIZATION
------------------------------------------------------------

-- Initialize when the addon loads
local function OnToastLoad()
  InitializeToastSystem()
end

-- Register initialization
if PPT_Frame then
  PPT_Frame:RegisterEvent("ADDON_LOADED")
  PPT_Frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "RoguePickPocketTracker" then
      OnToastLoad()
    end
  end)
end
