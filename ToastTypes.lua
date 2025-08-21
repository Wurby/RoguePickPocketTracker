-- ToastTypes.lua
-- Toast type definitions and styling for RoguePickPocketTracker

------------------------------------------------------------
--                   TOAST TYPE STYLES
------------------------------------------------------------

-- Define styles for different toast types
ToastStyles = {
  achievement = {
    backgroundColor = {0, 0, 0, 0.95}, -- Pure black background
    borderColor = {0.8, 0.6, 0.2, 1}, -- Gold border
    titleColor = {1, 0.84, 0}, -- Gold title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Achievement Unlocked!",
    defaultIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
  },
  
  session = {
    backgroundColor = {0, 0, 0, 0.95}, -- Pure black background
    borderColor = {0.3, 0.6, 1, 1}, -- Blue border (stealth theme)
    titleColor = {0.4, 0.7, 1}, -- Light blue title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Stealth Session Complete!",
    defaultIcon = "Interface\\Icons\\Ability_Stealth"
  },
  
  tracking = {
    backgroundColor = {0, 0, 0, 0.95}, -- Pure black background
    borderColor = {0.6, 0.4, 0.8, 1}, -- Purple border
    titleColor = {0.7, 0.5, 1}, -- Light purple title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Tracking Report",
    defaultIcon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
  },
  
  error = {
    backgroundColor = {0, 0, 0, 0.95}, -- Pure black background
    borderColor = {0.8, 0.2, 0.2, 1}, -- Red border
    titleColor = {1, 0.4, 0.4}, -- Light red title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Error",
    defaultIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
  },
  
  info = {
    backgroundColor = {0, 0, 0, 0.95}, -- Pure black background
    borderColor = {0.5, 0.7, 0.9, 1}, -- Light blue border
    titleColor = {0.7, 0.9, 1}, -- Light blue title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Information",
    defaultIcon = "Interface\\Icons\\INV_Misc_Note_01"
  }
}

------------------------------------------------------------
--                   TOAST TYPE FACTORY
------------------------------------------------------------

-- Factory function to create toasts of specific types
function CreateToast(toastType, data)
  if not ToastStyles[toastType] then
    error("Unknown toast type: " .. tostring(toastType))
    return nil
  end
  
  local toast = ToastCore:New(toastType)
  toast:SetStyle(ToastStyles[toastType])
  
  -- Only set content if data is provided
  if data then
    toast:SetContent(data)
  end
  
  return toast
end

------------------------------------------------------------
--                   CONVENIENCE FUNCTIONS
------------------------------------------------------------

-- Show a toast immediately (if not in combat)
function ShowToast(toastType, data, bypassCombat)
  if not bypassCombat and IsInCombat() then
    -- Queue for after combat
    QueueCombatToast({type = toastType, data = data})
    return
  end
  
  local toast = CreateToast(toastType, data)
  if toast then
    QueueToast(toast)
  end
end

-- Show an achievement toast
function ShowAchievementToast(name, description, icon)
  ShowToast("achievement", {
    name = name,
    description = description,
    icon = icon
  })
end

-- Show a session toast
function ShowSessionToast(name, description, icon, bypassCombat)
  ShowToast("session", {
    name = name,
    description = description,
    icon = icon
  }, bypassCombat)
end

-- Show a tracking toast
function ShowTrackingToast(name, description, icon)
  ShowToast("tracking", {
    name = name,
    description = description,
    icon = icon
  })
end

-- Show an error toast
function ShowErrorToast(name, description)
  ShowToast("error", {
    name = name,
    description = description
  }, true) -- Always bypass combat for errors
end

-- Show an info toast
function ShowInfoToast(name, description, icon)
  ShowToast("info", {
    name = name,
    description = description,
    icon = icon
  }, true) -- Always bypass combat for info
end
