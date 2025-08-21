-- ToastCore.lua
-- Core toast notification framework for RoguePickPocketTracker

------------------------------------------------------------
--                   TOAST CORE SYSTEM
------------------------------------------------------------

-- Toast Core Object (acts as a parent class)
ToastCore = {}
ToastCore.__index = ToastCore

-- Global toast state
local activeToasts = {}
local toastQueue = {}
local isProcessingQueue = false
local toastFramePool = {}
local nextToastId = 1

-- Global variable for combat toast queuing (used by Events.lua)
pendingCombatToasts = pendingCombatToasts or {}

------------------------------------------------------------
--                   TOAST FRAME MANAGEMENT
------------------------------------------------------------

-- Create a new toast frame
local function CreateToastFrame(id)
  local frame = CreateFrame("Frame", "PPT_ToastFrame_" .. id, UIParent)
  frame:SetSize(400, 90)
  frame:SetFrameStrata("FULLSCREEN_DIALOG") -- Restore proper strata
  frame:SetFrameLevel(1000 + id) -- Ensure newer toasts appear above older ones
  frame:SetAlpha(0)
  frame:Hide()
  
  -- Border (bottom layer)
  frame.border = frame:CreateTexture(nil, "BACKGROUND")
  frame.border:SetAllPoints()
  
  -- Background (top layer, inset to show border)
  frame.bg = frame:CreateTexture(nil, "BORDER")
  frame.bg:SetPoint("TOPLEFT", 2, -2)
  frame.bg:SetPoint("BOTTOMRIGHT", -2, 2)
  
  -- Icon
  frame.icon = frame:CreateTexture(nil, "ARTWORK")
  frame.icon:SetSize(48, 48)
  frame.icon:SetPoint("LEFT", frame, "LEFT", 15, 0)
  
  -- Title
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.title:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 15, 8)
  frame.title:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
  frame.title:SetJustifyH("LEFT")
  
  -- Name/Message
  frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.name:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
  frame.name:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
  frame.name:SetJustifyH("LEFT")
  
  -- Description
  frame.desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.desc:SetPoint("TOPLEFT", frame.name, "BOTTOMLEFT", 0, -4)
  frame.desc:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
  frame.desc:SetJustifyH("LEFT")
  
  return frame
end

-- Get an available toast frame from the pool
local function GetToastFrame()
  DebugPrint("GetToastFrame called, pool size: " .. #toastFramePool)
  for i, frame in ipairs(toastFramePool) do
    if not frame:IsShown() then
      DebugPrint("Found available frame at index " .. i)
      return frame, i
    end
  end
  
  -- Create new frame if none available
  local id = #toastFramePool + 1
  DebugPrint("Creating new toast frame with id " .. id)
  local frame = CreateToastFrame(id)
  if frame then
    table.insert(toastFramePool, frame)
    DebugPrint("New frame created and added to pool, frame name: " .. (frame:GetName() or "unnamed"))
    DebugPrint("Frame size: " .. frame:GetWidth() .. "x" .. frame:GetHeight())
    DebugPrint("Frame strata: " .. frame:GetFrameStrata())
    return frame, id
  else
    DebugPrint("ERROR: Failed to create toast frame")
    return nil
  end
end

-- Position toast frames in a stack
local function RepositionToasts()
  DebugPrint("RepositionToasts called")
  local yOffset = 0
  local visibleCount = 0
  for i, frame in ipairs(toastFramePool) do
    if frame:IsShown() then
      visibleCount = visibleCount + 1
      frame:ClearAllPoints()
      -- Position toasts at top-center of screen
      frame:SetPoint("TOP", UIParent, "TOP", 0, -50 - yOffset)
      DebugPrint("Positioned toast frame %d at TOP, UIParent, TOP, 0, %d", i, -50 - yOffset)
      yOffset = yOffset + 100 -- Stack toasts vertically
    end
  end
  DebugPrint("Repositioned %d visible toasts", visibleCount)
end

------------------------------------------------------------
--                   TOAST CORE METHODS
------------------------------------------------------------

-- Create a new toast instance
function ToastCore:New(toastType)
  local toast = setmetatable({}, self)
  toast.type = toastType
  toast.id = nextToastId
  nextToastId = nextToastId + 1
  toast.frame = nil
  toast.isVisible = false
  toast.duration = 3.0 -- Default duration
  toast.fadeInTime = 0.3
  toast.fadeOutTime = 0.3
  return toast
end

-- Set toast content
function ToastCore:SetContent(data)
  if not data then
    DebugPrint("ToastCore:SetContent called with nil data")
    return self
  end
  
  self.title = data.title
  self.name = data.name
  self.description = data.description
  self.icon = data.icon
  return self -- For method chaining
end

-- Set toast styling
function ToastCore:SetStyle(style)
  self.style = style
  return self -- For method chaining
end

-- Set toast duration
function ToastCore:SetDuration(duration)
  self.duration = duration or 3.0
  return self -- For method chaining
end

-- Apply styling to the frame
function ToastCore:ApplyStyle()
  if not self.frame or not self.style then 
    DebugPrint("ApplyStyle: Missing frame or style")
    return 
  end
  
  DebugPrint("Applying style to frame")
  DebugPrint("Background color: " .. table.concat(self.style.backgroundColor, ", "))
  DebugPrint("Border color: " .. table.concat(self.style.borderColor, ", "))
  
  -- Apply colors
  self.frame.bg:SetColorTexture(unpack(self.style.backgroundColor))
  self.frame.border:SetColorTexture(unpack(self.style.borderColor))
  
  -- Apply text colors
  self.frame.title:SetTextColor(unpack(self.style.titleColor))
  self.frame.name:SetTextColor(unpack(self.style.textColor))
  self.frame.desc:SetTextColor(unpack(self.style.descColor))
  
  DebugPrint("Style applied successfully")
end

-- Apply content to the frame
function ToastCore:ApplyContent()
  if not self.frame then 
    DebugPrint("ApplyContent: Missing frame")
    return 
  end
  
  DebugPrint("Applying content to frame")
  
  self.frame.icon:SetTexture(self.icon or self.style.defaultIcon)
  self.frame.title:SetText(self.title or self.style.defaultTitle)
  self.frame.name:SetText(self.name or "")
  self.frame.desc:SetText(self.description or "")
  
  DebugPrint("Content applied: icon=%s, title=%s, name=%s, desc=%s", 
    tostring(self.icon or self.style.defaultIcon), 
    tostring(self.title or self.style.defaultTitle),
    tostring(self.name),
    tostring(self.description))
end

-- Show the toast
function ToastCore:Show()
  if self.isVisible then 
    DebugPrint("Toast already visible, skipping")
    return 
  end
  
  DebugPrint("Showing toast: " .. tostring(self.name or "Unknown"))
  
  -- Get a frame from the pool
  self.frame = GetToastFrame()
  if not self.frame then 
    DebugPrint("ERROR: Failed to get toast frame")
    return 
  end
  
  DebugPrint("Got toast frame, applying styling...")
  
  -- Apply styling and content
  self:ApplyStyle()
  self:ApplyContent()
  
  DebugPrint("Applied styling and content, positioning...")
  
  -- Show the frame first (required for positioning)
  self.frame:Show()
  self.isVisible = true
  
  -- Now position it (after it's shown)
  RepositionToasts()
  
  -- Start with invisible and fade in
  self.frame:SetAlpha(0)
  
  -- Get target opacity
  local targetOpacity = PPT_AlertOpacity or 0.8
  if targetOpacity <= 0 or targetOpacity > 1 then 
    targetOpacity = 0.8 
  end
  
  -- Fade in animation
  local fadeInDuration = 0.3 -- 300ms fade in
  local fadeInSteps = 15
  local alphaStep = targetOpacity / fadeInSteps
  local stepDelay = fadeInDuration / fadeInSteps
  
  DebugPrint("Starting fade-in to alpha: " .. targetOpacity)
  
  for i = 1, fadeInSteps do
    C_Timer.After(stepDelay * i, function()
      if self.frame and self.isVisible then
        local newAlpha = math.min(alphaStep * i, targetOpacity)
        self.frame:SetAlpha(newAlpha)
        if i == fadeInSteps then
          DebugPrint("Fade-in complete, alpha: " .. self.frame:GetAlpha())
        end
      end
    end)
  end
  
  -- Schedule hide after duration
  if C_Timer and C_Timer.After then
    C_Timer.After(self.duration, function()
      DebugPrint("Auto-hiding toast after duration")
      self:Hide()
    end)
  end
end

-- Hide the toast
function ToastCore:Hide()
  if not self.isVisible or not self.frame then return end
  
  self.isVisible = false
  
  -- Fade out animation
  local currentAlpha = self.frame:GetAlpha()
  local fadeOutDuration = 0.2 -- 200ms fade out
  local fadeOutSteps = 10
  local alphaStep = currentAlpha / fadeOutSteps
  local stepDelay = fadeOutDuration / fadeOutSteps
  
  DebugPrint("Starting fade-out from alpha: " .. currentAlpha)
  
  for i = 1, fadeOutSteps do
    C_Timer.After(stepDelay * i, function()
      if self.frame then
        local newAlpha = math.max(currentAlpha - (alphaStep * i), 0)
        self.frame:SetAlpha(newAlpha)
        
        -- Hide the frame completely after fade out is done
        if i == fadeOutSteps then
          self.frame:Hide()
          RepositionToasts()
          DebugPrint("Fade-out complete, frame hidden")
          
          -- Process next toast in queue
          ProcessToastQueue()
        end
      end
    end)
  end
end

-- Fade in animation
function ToastCore:FadeIn()
  if not self.frame then return end
  
  local opacity = (PPT_AlertOpacity or 80) / 100
  if opacity <= 0 or opacity > 1 then opacity = 0.8 end
  
  local step = 0
  local maxSteps = math.floor(self.fadeInTime * 20) -- 20 FPS
  
  local function fadeStep()
    if step < maxSteps and self.frame then
      step = step + 1
      local alpha = (step / maxSteps) * opacity
      self.frame:SetAlpha(alpha)
      
      if C_Timer and C_Timer.After then
        C_Timer.After(0.05, fadeStep)
      end
    end
  end
  
  fadeStep()
end

-- Fade out animation
function ToastCore:FadeOut(callback)
  if not self.frame then return end
  
  local currentAlpha = self.frame:GetAlpha()
  local step = 0
  local maxSteps = math.floor(self.fadeOutTime * 20) -- 20 FPS
  
  local function fadeStep()
    if step < maxSteps and self.frame then
      step = step + 1
      local alpha = currentAlpha * (1 - (step / maxSteps))
      self.frame:SetAlpha(alpha)
      
      if C_Timer and C_Timer.After then
        C_Timer.After(0.05, fadeStep)
      end
    elseif callback then
      callback()
    end
  end
  
  fadeStep()
end

------------------------------------------------------------
--                   QUEUE MANAGEMENT
------------------------------------------------------------

-- Add toast to queue
function QueueToast(toast)
  DebugPrint("QueueToast called with toast: " .. tostring(toast and toast.name or "nil"))
  table.insert(toastQueue, toast)
  DebugPrint("Toast queue size: " .. #toastQueue)
  if not isProcessingQueue then
    DebugPrint("Starting queue processing...")
    ProcessToastQueue()
  else
    DebugPrint("Queue already processing, toast added to queue")
  end
end

-- Process the toast queue
function ProcessToastQueue()
  if #toastQueue == 0 then
    DebugPrint("Toast queue empty, stopping processing")
    isProcessingQueue = false
    return
  end
  
  DebugPrint("Processing toast queue, " .. #toastQueue .. " toasts remaining")
  isProcessingQueue = true
  local toast = table.remove(toastQueue, 1)
  DebugPrint("Removed toast from queue: " .. tostring(toast and toast.name or "nil"))
  toast:Show()
end

------------------------------------------------------------
--                   COMBAT INTEGRATION
------------------------------------------------------------

-- Queue toast for after combat (used by toast types)
function QueueCombatToast(data)
  if not pendingCombatToasts then
    pendingCombatToasts = {}
  end
  table.insert(pendingCombatToasts, data)
end

-- Check if player is in combat
function IsInCombat()
  return UnitAffectingCombat and UnitAffectingCombat("player")
end
