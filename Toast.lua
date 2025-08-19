-- Toast.lua
-- Reusable toast notification system for RoguePickPocketTracker

------------------------------------------------------------
--                     TOAST SYSTEM
------------------------------------------------------------

-- Toast queue system
local toastQueue = {}
local isShowingToast = false
local toastFrame = nil

-- Toast types with different styling
local TOAST_TYPES = {
  achievement = {
    backgroundColor = {0.15, 0.15, 0.15, 1}, -- Dark grey
    borderColor = {0.6, 0.6, 0.6, 1}, -- Grey border
    glowColor = {1, 0.84, 0, 0.1}, -- Subtle gold glow
    titleColor = {1, 0.84, 0}, -- Gold title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Achievement Unlocked!",
    defaultIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
  },
  session = {
    backgroundColor = {0.1, 0.2, 0.1, 1}, -- Dark green
    borderColor = {0.4, 0.7, 0.4, 1}, -- Green border
    glowColor = {0.4, 1, 0.4, 0.1}, -- Subtle green glow
    titleColor = {0.4, 1, 0.4}, -- Bright green title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Stealth Session Complete!",
    defaultIcon = "Interface\\Icons\\Ability_Stealth"
  },
  tracking = {
    backgroundColor = {0.1, 0.1, 0.2, 1}, -- Dark blue
    borderColor = {0.4, 0.4, 0.7, 1}, -- Blue border
    glowColor = {0.4, 0.4, 1, 0.1}, -- Subtle blue glow
    titleColor = {0.6, 0.8, 1}, -- Light blue title
    textColor = {1, 1, 1}, -- White text
    descColor = {0.8, 0.8, 0.8}, -- Light grey description
    defaultTitle = "Tracking Report",
    defaultIcon = "Interface\\Icons\\INV_Misc_PocketWatch_01"
  }
}

-- Show a toast notification
function ShowToast(data, bypassCombatCheck)
  DebugPrint("ShowToast called with type: %s, name: %s", data.type or "unknown", data.name or "unknown")
  
  -- Validate required data
  if not data.type or not TOAST_TYPES[data.type] then
    DebugPrint("Invalid toast type: %s", tostring(data.type))
    return
  end
  
  -- Check if in combat (unless bypassing check) - queue all toast types during combat
  if not bypassCombatCheck and UnitAffectingCombat and UnitAffectingCombat("player") then
    -- Queue toast for after combat ends
    if not pendingCombatToasts then
      pendingCombatToasts = {}
    end
    table.insert(pendingCombatToasts, data)
    DebugPrint("%s toast queued - waiting for combat to end", data.type)
    return
  end
  
  -- Add to queue
  table.insert(toastQueue, data)
  
  -- Start processing queue if not already showing
  if not isShowingToast then
    processToastQueue()
  end
end

function processToastQueue()
  if #toastQueue == 0 then
    isShowingToast = false
    return
  end
  
  isShowingToast = true
  local data = table.remove(toastQueue, 1) -- Get first in queue
  
  DebugPrint("Processing toast from queue: %s", data.name or "unknown")
  
  -- Create the toast frame if it doesn't exist
  if not toastFrame then
    DebugPrint("Creating new toast frame")
    toastFrame = CreateFrame("Frame", "PPT_ToastFrame", UIParent)
    toastFrame:SetSize(420, 90)
    toastFrame:SetPoint("TOP", UIParent, "TOP", 0, -120) -- Moved down 20px from -100
    toastFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    toastFrame:SetFrameLevel(100)
    
    -- Main background
    local bg = toastFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    toastFrame.bg = bg
    
    -- Create border effect with rounded corners using multiple textures
    local borderSize = 2
    
    -- Top border
    local borderTop = toastFrame:CreateTexture(nil, "BORDER")
    borderTop:SetHeight(borderSize)
    borderTop:SetPoint("TOPLEFT", borderSize, -borderSize)
    borderTop:SetPoint("TOPRIGHT", -borderSize, -borderSize)
    
    -- Bottom border
    local borderBottom = toastFrame:CreateTexture(nil, "BORDER")
    borderBottom:SetHeight(borderSize)
    borderBottom:SetPoint("BOTTOMLEFT", borderSize, borderSize)
    borderBottom:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
    
    -- Left border
    local borderLeft = toastFrame:CreateTexture(nil, "BORDER")
    borderLeft:SetWidth(borderSize)
    borderLeft:SetPoint("TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
    
    -- Right border
    local borderRight = toastFrame:CreateTexture(nil, "BORDER")
    borderRight:SetWidth(borderSize)
    borderRight:SetPoint("TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- Corner pieces for rounded effect
    local cornerSize = 6
    
    -- Top-left corner
    local cornerTL = toastFrame:CreateTexture(nil, "ARTWORK")
    cornerTL:SetSize(cornerSize, cornerSize)
    cornerTL:SetPoint("TOPLEFT", 0, 0)
    
    -- Top-right corner
    local cornerTR = toastFrame:CreateTexture(nil, "ARTWORK")
    cornerTR:SetSize(cornerSize, cornerSize)
    cornerTR:SetPoint("TOPRIGHT", 0, 0)
    
    -- Bottom-left corner
    local cornerBL = toastFrame:CreateTexture(nil, "ARTWORK")
    cornerBL:SetSize(cornerSize, cornerSize)
    cornerBL:SetPoint("BOTTOMLEFT", 0, 0)
    
    -- Bottom-right corner
    local cornerBR = toastFrame:CreateTexture(nil, "ARTWORK")
    cornerBR:SetSize(cornerSize, cornerSize)
    cornerBR:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- Subtle inner glow
    local innerGlow = toastFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    innerGlow:SetPoint("TOPLEFT", 4, -4)
    innerGlow:SetPoint("BOTTOMRIGHT", -4, 4)
    
    -- Icon
    local icon = toastFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48)
    icon:SetPoint("LEFT", toastFrame, "LEFT", 20, 0)
    toastFrame.icon = icon
    
    -- Title text
    local title = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 15, 8)
    title:SetPoint("RIGHT", toastFrame, "RIGHT", -20, 0)
    title:SetJustifyH("LEFT")
    toastFrame.title = title
    
    -- Main text (name/message)
    local name = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    name:SetPoint("RIGHT", toastFrame, "RIGHT", -20, 0)
    name:SetJustifyH("LEFT")
    toastFrame.name = name
    
    -- Description
    local desc = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("RIGHT", toastFrame, "RIGHT", -20, 0)
    desc:SetJustifyH("LEFT")
    toastFrame.desc = desc
    
    -- Store border elements for color changes
    toastFrame.borders = {borderTop, borderBottom, borderLeft, borderRight, cornerTL, cornerTR, cornerBL, cornerBR}
    toastFrame.innerGlow = innerGlow
    
    -- Hide initially
    toastFrame:Hide()
    toastFrame:SetAlpha(0)
    DebugPrint("Toast frame created and hidden")
  end
  
  -- Apply styling based on toast type
  local style = TOAST_TYPES[data.type]
  toastFrame.bg:SetColorTexture(unpack(style.backgroundColor))
  toastFrame.innerGlow:SetColorTexture(unpack(style.glowColor))
  
  -- Set border colors
  for _, border in ipairs(toastFrame.borders) do
    border:SetColorTexture(unpack(style.borderColor))
  end
  
  -- Set content
  toastFrame.icon:SetTexture(data.icon or style.defaultIcon)
  toastFrame.title:SetText(data.title or style.defaultTitle)
  toastFrame.title:SetTextColor(unpack(style.titleColor))
  toastFrame.name:SetText(data.name or "")
  toastFrame.name:SetTextColor(unpack(style.textColor))
  toastFrame.desc:SetText(data.description or "")
  toastFrame.desc:SetTextColor(unpack(style.descColor))
  
  -- Apply current opacity setting
  local opacity = (PPT_AlertOpacity or 80) / 100
  
  DebugPrint("Toast data set, showing frame with opacity: %d%%", PPT_AlertOpacity or 80)
  
  -- Show with simple fade animation
  toastFrame:Show()
  toastFrame:SetAlpha(0)
  
  -- Simple timer-based fade in/out instead of animation groups
  local fadeStep = 0
  local maxSteps = 10
  local holdTime = 30 -- Hold for 3 seconds (30 * 0.1)
  
  local function fadeTimer()
    if fadeStep < maxSteps then
      -- Fade in
      fadeStep = fadeStep + 1
      toastFrame:SetAlpha((fadeStep / maxSteps) * opacity)
      -- Use C_Timer if available, otherwise use a simple OnUpdate script
      if C_Timer and C_Timer.After then
        C_Timer.After(0.05, fadeTimer)
      else
        -- Fallback for older WoW versions
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.05 then
            self:SetScript("OnUpdate", nil)
            fadeTimer()
          end
        end)
      end
    elseif fadeStep < maxSteps + holdTime then
      -- Hold
      fadeStep = fadeStep + 1
      if C_Timer and C_Timer.After then
        C_Timer.After(0.1, fadeTimer)
      else
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.1 then
            self:SetScript("OnUpdate", nil)
            fadeTimer()
          end
        end)
      end
    elseif fadeStep < maxSteps + holdTime + maxSteps then
      -- Fade out
      fadeStep = fadeStep + 1
      local fadeOutStep = maxSteps + holdTime + maxSteps - fadeStep
      toastFrame:SetAlpha((fadeOutStep / maxSteps) * opacity)
      if C_Timer and C_Timer.After then
        C_Timer.After(0.05, fadeTimer)
      else
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.05 then
            self:SetScript("OnUpdate", nil)
            fadeTimer()
          end
        end)
      end
    else
      -- Hide and process next in queue
      toastFrame:Hide()
      DebugPrint("Toast hidden, processing next in queue")
      
      -- Process next toast in queue after a short delay
      if C_Timer and C_Timer.After then
        C_Timer.After(0.5, processToastQueue)
      else
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
          self.elapsed = self.elapsed + elapsed
          if self.elapsed >= 0.5 then
            self:SetScript("OnUpdate", nil)
            processToastQueue()
          end
        end)
      end
    end
  end
  
  DebugPrint("Starting toast fade timer")
  fadeTimer()
end
