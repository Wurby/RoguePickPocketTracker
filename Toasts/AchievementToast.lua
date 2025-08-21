-- AchievementToast.lua
-- Achievement-specific toast functionality for RoguePickPocketTracker

------------------------------------------------------------
--                 ACHIEVEMENT TOAST CLASS
------------------------------------------------------------

-- Achievement Toast Object (inherits from ToastCore)
AchievementToast = setmetatable({}, {__index = ToastCore})
AchievementToast.__index = AchievementToast

-- Create a new achievement toast
function AchievementToast:New()
  local toast = ToastCore:New("achievement")
  setmetatable(toast, self)
  toast:SetStyle(ToastStyles.achievement)
  toast:SetDuration(5.0) -- Longer duration for achievements
  return toast
end

-- Set achievement data
function AchievementToast:SetAchievementData(achievementId, progressData)
  local achievement = findAchievementById(achievementId)
  
  if not achievement then
    PPT_Debug("Achievement not found: " .. tostring(achievementId))
    return self
  end
  
  local name = achievement.name
  local description = ""
  local iconTexture = achievement.icon or "Interface\\Icons\\Achievement_General"
  
  -- Get current progress from PPT_Achievements
  local currentProgress = PPT_Achievements[achievementId] or 0
  local isCompleted = PPT_CompletedAchievements and PPT_CompletedAchievements[achievementId]
  
  -- Check if this is a completion or progress update
  if isCompleted then
    -- Show the achievement's description/goal instead of generic "completed" message
    description = achievement.description or "Achievement Completed!"
  else
    -- Show progress
    local progress = progressData and progressData.progress or currentProgress
    local requirement = achievement.goal or 0
    
    if requirement > 0 then
      description = string.format("Progress: %d / %d", progress, requirement)
      
      -- Add percentage if meaningful
      local percentage = math.floor((progress / requirement) * 100)
      if percentage > 0 and percentage < 100 then
        description = description .. string.format(" (%d%%)", percentage)
      end
    else
      description = "Progress Updated"
    end
  end
  
  self:SetContent({
    name = name,
    description = description,
    icon = iconTexture
  })
  
  return self
end

-- Set milestone data for milestone achievements
function AchievementToast:SetMilestoneData(achievementId, milestone)
  local achievement = findAchievementById(achievementId)
  
  if not achievement then
    PPT_Debug("Achievement not found: " .. tostring(achievementId))
    return self
  end
  
  local name = achievement.name
  local description = ""
  local iconTexture = achievement.icon or "Interface\\Icons\\Achievement_General"
  
  if milestone then
    description = string.format("Milestone: %s", milestone.name or "Unknown")
    if milestone.description then
      description = description .. " - " .. milestone.description
    end
  else
    description = "Milestone achieved!"
  end
  
  self:SetContent({
    name = name,
    description = description,
    icon = iconTexture
  })
  
  return self
end

------------------------------------------------------------
--                ACHIEVEMENT TOAST FUNCTIONS
------------------------------------------------------------

-- Show achievement completion toast
function ShowAchievementCompletionToast(achievementId)
  -- Only show if achievement toasts are enabled
  if not PPT_ShowAchievementToasts then
    return
  end
  
  local toast = AchievementToast:New()
  toast:SetAchievementData(achievementId)
  
  -- Achievements should be shown after combat if currently in combat
  if PPT_InCombat then
    AddToPostCombatQueue(function()
      QueueToast(toast)
    end)
  else
    QueueToast(toast)
  end
end

-- Show achievement progress toast
function ShowAchievementProgressToast(achievementId, progressData)
  -- Only show if achievement toasts are enabled
  if not PPT_ShowAchievementToasts then
    return
  end
  
  -- Don't show progress toasts for completed achievements
  local isCompleted = PPT_CompletedAchievements and PPT_CompletedAchievements[achievementId]
  if isCompleted then
    return
  end
  
  local toast = AchievementToast:New()
  toast:SetAchievementData(achievementId, progressData)
  
  -- Progress updates should wait for combat to end
  if PPT_InCombat then
    AddToPostCombatQueue(function()
      QueueToast(toast)
    end)
  else
    QueueToast(toast)
  end
end

-- Show achievement milestone toast
function ShowAchievementMilestoneToast(achievementId, milestone)
  -- Only show if achievement toasts are enabled
  if not PPT_ShowAchievementToasts then
    return
  end
  
  local toast = AchievementToast:New()
  toast:SetMilestoneData(achievementId, milestone)
  
  -- Milestones should be shown after combat if currently in combat
  if PPT_InCombat then
    AddToPostCombatQueue(function()
      QueueToast(toast)
    end)
  else
    QueueToast(toast)
  end
end

-- Show achievement toast using achievement ID (for manual commands)
function ShowAchievementToast(achievementId)
  if not PPT_ShowAchievementToasts then
    return
  end
  
  if not achievementId then
    ShowErrorToast("No Achievement", "No achievement ID provided")
    return
  end
  
  local achievement = findAchievementById(achievementId)
  if not achievement then
    ShowErrorToast("Invalid Achievement", "Achievement ID " .. tostring(achievementId) .. " not found")
    return
  end
  
  local toast = AchievementToast:New()
  toast:SetAchievementData(achievementId)
  
  -- Manual commands bypass combat
  QueueToast(toast)
end

-- Test function to show a sample achievement toast
function ShowTestAchievementToast()
  local toast = AchievementToast:New()
  toast:SetContent({
    name = "Test Achievement",
    description = "This is a test achievement notification",
    icon = "Interface\\Icons\\Achievement_General"
  })
  
  QueueToast(toast)
end
