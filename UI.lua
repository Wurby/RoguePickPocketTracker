-- UI.lua
-- Draggable UI elements for RoguePickPocketTracker

------------------------------------------------------------
--                   SAVED VARIABLES
------------------------------------------------------------
PPT_UI_Settings = PPT_UI_Settings or {
  coinageTracker = {
    enabled = true, -- On by default
    left = 100,
    top = 100,
    scale = 1.0,
    alpha = 1.0,
    backgroundColor = {0.15, 0.15, 0.15, 1}, -- Default dark grey
    showBackground = true,
    fontSize = 12,
    anchorPoint = "CENTER", -- CENTER, TOPLEFT, TOPRIGHT, BOTTOMLEFT, BOTTOMRIGHT
    showAnchor = false -- Show visible anchor point
  }
}

------------------------------------------------------------
--                   COINAGE TRACKER FRAME
------------------------------------------------------------

------------------------------------------------------------
--                   COINAGE TRACKER FRAME
------------------------------------------------------------
local coinageFrame = nil
local anchorFrame = nil
local isDragging = false -- Track dragging state
local isStealthTransition = false -- Track stealth state changes

-- Create the anchor frame (fixed point that never moves except when dragged)
local function CreateAnchorFrame()
  if anchorFrame then return anchorFrame end
  
  -- Create a small, fixed-size anchor frame
  anchorFrame = CreateFrame("Frame", "PPT_AnchorFrame", UIParent)
  anchorFrame:SetSize(16, 16) -- Larger clickable area
  anchorFrame:SetMovable(true)
  anchorFrame:EnableMouse(true)
  anchorFrame:RegisterForDrag("LeftButton")
  anchorFrame:SetClampedToScreen(true)
  anchorFrame:SetFrameStrata("HIGH") -- High strata to ensure tooltip works
  anchorFrame:SetFrameLevel(101) -- Higher than main frame
  
  -- Anchor visual (only visible when showAnchor is enabled)
  anchorFrame.visual = anchorFrame:CreateTexture(nil, "OVERLAY")
  anchorFrame.visual:SetPoint("CENTER", 0, 0)
  anchorFrame.visual:SetSize(8, 8) -- Visual is smaller than clickable area
  anchorFrame.visual:SetColorTexture(1, 0, 0, 0.7) -- Red anchor point
  
  -- Anchor border
  anchorFrame.border = anchorFrame:CreateTexture(nil, "BORDER")
  anchorFrame.border:SetPoint("CENTER", 0, 0)
  anchorFrame.border:SetSize(10, 10) -- Border slightly larger than visual
  anchorFrame.border:SetColorTexture(0, 0, 0, 1) -- Black border
  
  -- Make frame always interactive, but visual is controlled separately
  anchorFrame:Show() -- Always show the frame for interaction
  anchorFrame.visual:Hide() -- Hide visual by default
  anchorFrame.border:Hide() -- Hide border by default
  
  -- Drag functionality for anchor
  anchorFrame:SetScript("OnDragStart", function(self)
    isDragging = true
    self:StartMoving()
  end)
  
  anchorFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    isDragging = false
    -- Save position
    local x = self:GetLeft()
    local y = self:GetBottom()
    PPT_UI_Settings.coinageTracker.left = x
    PPT_UI_Settings.coinageTracker.top = y
    DebugPrint("UI: Anchor moved to %d,%d", x, y)
    -- Content frame automatically follows anchor
  end)
  
  -- Control+Click to show/hide anchor
  anchorFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and IsControlKeyDown() then
      PPT_UI_Settings.coinageTracker.showAnchor = not PPT_UI_Settings.coinageTracker.showAnchor
      UpdateAnchorVisibility()
    end
  end)
  
  -- Tooltip for anchor
  anchorFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText("Pick Pocket Tracker", 1, 1, 1)
    GameTooltip:AddLine("Drag to move tracker position", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-click for options", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  
  anchorFrame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  
  return anchorFrame
end

-- Global function for Options.lua to update anchor visibility
function UpdateAnchorVisibility()
  if not anchorFrame then return end
  
  if PPT_UI_Settings.coinageTracker.showAnchor then
    anchorFrame.visual:Show()
    anchorFrame.border:Show()
  else
    anchorFrame.visual:Hide()
    anchorFrame.border:Hide()
  end
end

-- Position the content frame relative to the anchor
local function PositionFrameFromAnchor()
  if not coinageFrame or not anchorFrame then return end
  
  local anchorPoint = PPT_UI_Settings.coinageTracker.anchorPoint or "CENTER"
  coinageFrame:ClearAllPoints()
  
  if anchorPoint == "TOPLEFT" then
    coinageFrame:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, 0)
  elseif anchorPoint == "TOPRIGHT" then
    coinageFrame:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", 0, 0)
  elseif anchorPoint == "BOTTOMLEFT" then
    coinageFrame:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", 0, 0)
  elseif anchorPoint == "BOTTOMRIGHT" then
    coinageFrame:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", 0, 0)
  else -- CENTER
    coinageFrame:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
  end
end

-- Calculate size and apply it without moving the anchor
local function CalculateAndApplyContentSize()
  if not coinageFrame or not anchorFrame then return end
  
  local padding = 8
  local lineHeight = 14
  local buttonHeight = 20
  local headerHeight = 12
  
  -- Calculate required width
  local textWidth = coinageFrame.coinage:GetStringWidth()
  local titleWidth = coinageFrame.title:GetStringWidth()
  local maxContentWidth = math.max(textWidth, titleWidth)
  
  -- Check visible elements
  if coinageFrame.trackingInfo and coinageFrame.trackingInfo:IsVisible() then
    maxContentWidth = math.max(maxContentWidth, coinageFrame.trackingInfo:GetStringWidth())
  end
  if coinageFrame.timerDisplay and coinageFrame.timerDisplay:IsVisible() then
    maxContentWidth = math.max(maxContentWidth, coinageFrame.timerDisplay:GetStringWidth())
  end
  if coinageFrame.sessionInfo and coinageFrame.sessionInfo:IsVisible() then
    maxContentWidth = math.max(maxContentWidth, coinageFrame.sessionInfo:GetStringWidth())
  end
  
  -- Account for buttons (50 + 5 gap + 50 = 105 pixels)
  if PPT_StopwatchEnabled then
    maxContentWidth = math.max(maxContentWidth, 105)
  end
  
  local newWidth = maxContentWidth + (padding * 2)
  
  -- Calculate height
  local contentHeight = lineHeight + lineHeight -- title + coinage
  
  if coinageFrame.trackingInfo and coinageFrame.trackingInfo:IsVisible() then
    contentHeight = contentHeight + lineHeight
  end
  if coinageFrame.timerDisplay and coinageFrame.timerDisplay:IsVisible() then
    contentHeight = contentHeight + lineHeight
  end
  if coinageFrame.sessionInfo and coinageFrame.sessionInfo:IsVisible() then
    contentHeight = contentHeight + lineHeight
  end
  if PPT_StopwatchEnabled and coinageFrame.controlsHeader and coinageFrame.controlsHeader:IsVisible() then
    contentHeight = contentHeight + headerHeight + buttonHeight + 4
  end
  
  local newHeight = contentHeight + (padding * 2)
  
  -- Store current size to prevent unnecessary repositioning
  local currentWidth, currentHeight = coinageFrame:GetSize()
  
  -- Only update size and position if they actually changed
  if math.abs(currentWidth - newWidth) > 1 or math.abs(currentHeight - newHeight) > 1 then
    -- Set size first
    coinageFrame:SetSize(newWidth, newHeight)
    
    -- Then position relative to anchor
    PositionFrameFromAnchor()
  end
end

-- Create the main coinage tracker frame
local function CreateCoinageTracker()
  if coinageFrame then return coinageFrame end
  
  -- Ensure anchor frame exists first
  CreateAnchorFrame()
  
  -- Main frame - no longer draggable itself, anchored to anchor frame
  coinageFrame = CreateFrame("Frame", "PPT_CoinageTracker", UIParent)
  coinageFrame:SetSize(120, 60) -- Start smaller, will grow as needed
  coinageFrame:EnableMouse(true)
  coinageFrame:SetClampedToScreen(true)
  coinageFrame:SetFrameStrata("MEDIUM") -- Above basic UI elements
  coinageFrame:SetFrameLevel(100) -- High level within the strata
  
  -- Main background (color will be set by ApplyCoinageSettings)
  coinageFrame.bg = coinageFrame:CreateTexture(nil, "BACKGROUND")
  coinageFrame.bg:SetAllPoints()
  -- Background color will be applied in ApplyCoinageSettings()
  
  -- Create border effect like toast notifications with corners
  local borderSize = 2
  
  -- Top border
  coinageFrame.borderTop = coinageFrame:CreateTexture(nil, "BORDER")
  coinageFrame.borderTop:SetHeight(borderSize)
  coinageFrame.borderTop:SetPoint("TOPLEFT", borderSize, -borderSize)
  coinageFrame.borderTop:SetPoint("TOPRIGHT", -borderSize, -borderSize)
  coinageFrame.borderTop:SetColorTexture(0.6, 0.6, 0.6, 1) -- Grey border
  
  -- Bottom border
  coinageFrame.borderBottom = coinageFrame:CreateTexture(nil, "BORDER")
  coinageFrame.borderBottom:SetHeight(borderSize)
  coinageFrame.borderBottom:SetPoint("BOTTOMLEFT", borderSize, borderSize)
  coinageFrame.borderBottom:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
  coinageFrame.borderBottom:SetColorTexture(0.6, 0.6, 0.6, 1)
  
  -- Left border
  coinageFrame.borderLeft = coinageFrame:CreateTexture(nil, "BORDER")
  coinageFrame.borderLeft:SetWidth(borderSize)
  coinageFrame.borderLeft:SetPoint("TOPLEFT", 0, 0)
  coinageFrame.borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
  coinageFrame.borderLeft:SetColorTexture(0.6, 0.6, 0.6, 1)
  
  -- Right border
  coinageFrame.borderRight = coinageFrame:CreateTexture(nil, "BORDER")
  coinageFrame.borderRight:SetWidth(borderSize)
  coinageFrame.borderRight:SetPoint("TOPRIGHT", 0, 0)
  coinageFrame.borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
  coinageFrame.borderRight:SetColorTexture(0.6, 0.6, 0.6, 1)
  
  -- Corner pieces for rounded effect like toast
  local cornerSize = 6
  
  -- Top-left corner
  coinageFrame.cornerTL = coinageFrame:CreateTexture(nil, "ARTWORK")
  coinageFrame.cornerTL:SetSize(cornerSize, cornerSize)
  coinageFrame.cornerTL:SetPoint("TOPLEFT", 0, 0)
  coinageFrame.cornerTL:SetColorTexture(0.6, 0.6, 0.6, 1)
  
  -- Top-right corner
  coinageFrame.cornerTR = coinageFrame:CreateTexture(nil, "ARTWORK")
  coinageFrame.cornerTR:SetSize(cornerSize, cornerSize)
  coinageFrame.cornerTR:SetPoint("TOPRIGHT", 0, 0)
  coinageFrame.cornerTR:SetColorTexture(0.6, 0.6, 0.6, 1)
  
  -- Bottom-left corner
  coinageFrame.cornerBL = coinageFrame:CreateTexture(nil, "ARTWORK")
  coinageFrame.cornerBL:SetSize(cornerSize, cornerSize)
  coinageFrame.cornerBL:SetPoint("BOTTOMLEFT", 0, 0)
  coinageFrame.cornerBL:SetColorTexture(0.6, 0.6, 0.6, 1)
  
  -- Bottom-right corner
  coinageFrame.cornerBR = coinageFrame:CreateTexture(nil, "ARTWORK")
  coinageFrame.cornerBR:SetSize(cornerSize, cornerSize)
  coinageFrame.cornerBR:SetPoint("BOTTOMRIGHT", 0, 0)
  coinageFrame.cornerBR:SetColorTexture(0.6, 0.6, 0.6, 1)
  
  -- Subtle inner glow like toast
  coinageFrame.innerGlow = coinageFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
  coinageFrame.innerGlow:SetPoint("TOPLEFT", 4, -4)
  coinageFrame.innerGlow:SetPoint("BOTTOMRIGHT", -4, 4)
  coinageFrame.innerGlow:SetColorTexture(0.25, 0.25, 0.25, 0.3) -- Subtle grey glow, no gold
  
  -- Title (neutral color instead of gold)
  coinageFrame.title = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  coinageFrame.title:SetPoint("TOP", 0, -6)
  coinageFrame.title:SetTextColor(0.9, 0.9, 0.9) -- Light grey instead of gold
  coinageFrame.title:SetText("Pickpocket Tracker")
  
  -- Coinage text (white like toast)
  coinageFrame.coinage = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  coinageFrame.coinage:SetPoint("TOP", coinageFrame.title, "BOTTOM", 0, -2)
  coinageFrame.coinage:SetTextColor(1, 1, 1) -- White text like toast
  coinageFrame.coinage:SetText("0c")
  
  -- Tracking stats display (per-minute/hour display)
  coinageFrame.trackingInfo = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  coinageFrame.trackingInfo:SetPoint("TOP", coinageFrame.coinage, "BOTTOM", 0, -2)
  coinageFrame.trackingInfo:SetTextColor(0.8, 0.8, 0.8) -- Light grey like toast desc
  coinageFrame.trackingInfo:SetText("")
  coinageFrame.trackingInfo:Hide()
  
  -- Timer display
  coinageFrame.timerDisplay = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  coinageFrame.timerDisplay:SetPoint("TOP", coinageFrame.trackingInfo, "BOTTOM", 0, -2)
  coinageFrame.timerDisplay:SetTextColor(0.8, 0.8, 0.8) -- Light grey like toast desc
  coinageFrame.timerDisplay:SetText("")
  coinageFrame.timerDisplay:Hide()
  
  -- Session info display
  coinageFrame.sessionInfo = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  coinageFrame.sessionInfo:SetPoint("TOP", coinageFrame.timerDisplay, "BOTTOM", 0, -2)
  coinageFrame.sessionInfo:SetTextColor(0.8, 0.8, 0.8) -- Light grey like toast desc
  coinageFrame.sessionInfo:SetText("")
  coinageFrame.sessionInfo:Hide()
  
  -- Tracking controls header
  coinageFrame.controlsHeader = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  coinageFrame.controlsHeader:SetPoint("TOP", coinageFrame.sessionInfo, "BOTTOM", 0, -4)
  coinageFrame.controlsHeader:SetTextColor(1, 0.84, 0) -- Gold like title
  coinageFrame.controlsHeader:SetText("Tracking Controls")
  coinageFrame.controlsHeader:Hide()
  
  -- Start tracking button
  coinageFrame.startBtn = CreateFrame("Button", nil, coinageFrame, "UIPanelButtonTemplate")
  coinageFrame.startBtn:SetSize(50, 20)
  coinageFrame.startBtn:SetPoint("TOP", coinageFrame.controlsHeader, "BOTTOM", -27.5, -2) -- Center with gap for stop button
  coinageFrame.startBtn:SetText("Start")
  coinageFrame.startBtn:SetScript("OnClick", function()
    StartPickPocketTracking()
  end)
  coinageFrame.startBtn:Hide()
  
  -- Stop tracking button
  coinageFrame.stopBtn = CreateFrame("Button", nil, coinageFrame, "UIPanelButtonTemplate")
  coinageFrame.stopBtn:SetSize(50, 20)
  coinageFrame.stopBtn:SetPoint("TOP", coinageFrame.controlsHeader, "BOTTOM", 27.5, -2) -- Center with gap from start button
  coinageFrame.stopBtn:SetText("Stop")
  coinageFrame.stopBtn:SetScript("OnClick", function()
    StopPickPocketTracking()
  end)
  coinageFrame.stopBtn:Hide()
  
  -- Tooltip and click handlers
  coinageFrame:SetScript("OnEnter", function(self)
    -- No tooltip on tracker frame - anchor has the tooltip
  end)
  
  coinageFrame:SetScript("OnLeave", function(self)
    -- No tooltip to hide
  end)
  
  -- Right-click to toggle anchor visibility
  coinageFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
      PPT_UI_Settings.coinageTracker.showAnchor = not PPT_UI_Settings.coinageTracker.showAnchor
      UpdateAnchorVisibility()
      print("Pickpocket Tracker: Anchor " .. (PPT_UI_Settings.coinageTracker.showAnchor and "shown" or "hidden"))
    end
  end)
  
  return coinageFrame
end

-- Update the coinage display
local function UpdateCoinageDisplay()
  if not coinageFrame or not coinageFrame:IsVisible() then return end
  
  coinageFrame.coinage:SetText(coinsToString(PPT_TotalCopper))
  
  -- Update tracking display if enabled and tracking is active
  if PPT_StopwatchEnabled and coinageFrame.trackingInfo then
    if PPT_TrackingActive then
      local stats = GetTrackingStats()
      if stats then
        local trackingText = string.format("%s/min | %s/hr", 
                                          coinsToString(math.floor(stats.copperPerMinute)),
                                          coinsToString(math.floor(stats.copperPerHour)))
        coinageFrame.trackingInfo:SetText(trackingText)
        coinageFrame.trackingInfo:Show()
        
        -- Update timer display
        if coinageFrame.timerDisplay then
          local timerText = string.format("Track Timer: %s", FormatTrackingTime(stats.elapsedTime))
          coinageFrame.timerDisplay:SetText(timerText)
          coinageFrame.timerDisplay:Show()
        end
      else
        coinageFrame.trackingInfo:SetText("")
        coinageFrame.trackingInfo:Hide()
        if coinageFrame.timerDisplay then
          coinageFrame.timerDisplay:Hide()
        end
      end
    else
      coinageFrame.trackingInfo:SetText("")
      coinageFrame.trackingInfo:Hide()
      if coinageFrame.timerDisplay then
        coinageFrame.timerDisplay:Hide()
      end
    end
  else
    if coinageFrame.trackingInfo then
      coinageFrame.trackingInfo:Hide()
    end
    if coinageFrame.timerDisplay then
      coinageFrame.timerDisplay:Hide()
    end
  end
  
  -- Update session info display
  if coinageFrame.sessionInfo then
    if ShouldShowSessionInfo and ShouldShowSessionInfo() then
      if sessionActive then
        local sessionStats = GetSessionStats()
        if sessionStats then
          local sessionText = string.format("Session: %s | %d mobs | %s | %d items", 
                                           FormatSessionTime(sessionStats.elapsedTime),
                                           sessionStats.mobCount,
                                           coinsToString(sessionStats.copper),
                                           sessionStats.items)
          coinageFrame.sessionInfo:SetText(sessionText)
          coinageFrame.sessionInfo:Show()
        else
          coinageFrame.sessionInfo:Hide()
        end
      else
        -- Show last session data during display delay period
        if PPT_LastSessionData then
          local sessionEndTime = sessionEndTime or 0
          local timeSinceEnd = GetTime() - sessionEndTime
          local sessionText = string.format("Last Session: %s | %d items", 
                                           coinsToString(PPT_LastSessionData.copper),
                                           PPT_LastSessionData.itemsCount)
          coinageFrame.sessionInfo:SetText(sessionText)
          coinageFrame.sessionInfo:Show()
        else
          coinageFrame.sessionInfo:Hide()
        end
      end
    else
      coinageFrame.sessionInfo:Hide()
    end
  end
  
  -- Update tracking buttons and header
  if PPT_StopwatchEnabled then
    if coinageFrame.startBtn and coinageFrame.stopBtn and coinageFrame.controlsHeader then
      if PPT_TrackingActive then
        coinageFrame.startBtn:Disable()
        coinageFrame.stopBtn:Enable()
        coinageFrame.startBtn:SetAlpha(0.5)
        coinageFrame.stopBtn:SetAlpha(1.0)
      else
        coinageFrame.startBtn:Enable()
        coinageFrame.stopBtn:Disable()
        coinageFrame.startBtn:SetAlpha(1.0)
        coinageFrame.stopBtn:SetAlpha(0.5)
      end
      
      -- Show controls during tracking or if tracking is enabled
      coinageFrame.controlsHeader:Show()
      coinageFrame.startBtn:Show()
      coinageFrame.stopBtn:Show()
    end
  else
    -- Hide tracking controls when disabled
    if coinageFrame.controlsHeader then coinageFrame.controlsHeader:Hide() end
    if coinageFrame.startBtn then coinageFrame.startBtn:Hide() end
    if coinageFrame.stopBtn then coinageFrame.stopBtn:Hide() end
  end
  
  -- Apply dynamic sizing and positioning
  CalculateAndApplyContentSize()
end

-- Apply settings to the frame
local function ApplyCoinageSettings()
  if not coinageFrame or not anchorFrame then return end
  
  local settings = PPT_UI_Settings.coinageTracker
  
  -- Position the anchor frame  
  anchorFrame:ClearAllPoints()
  anchorFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 
                       settings.left or 50, 
                       settings.top or 50)
  
  -- Update anchor visibility
  UpdateAnchorVisibility()
  
  -- Position content frame relative to anchor
  PositionFrameFromAnchor()
  
  -- Apply alpha setting
  coinageFrame:SetAlpha(settings.alpha or 1.0)
  
  -- Apply background color setting
  if coinageFrame.bg then
    local bgColor = settings.backgroundColor or {0.15, 0.15, 0.15, 1} -- Default dark grey
    -- Ensure the backgroundColor is saved to settings if it doesn't exist
    if not settings.backgroundColor then
      settings.backgroundColor = {0.15, 0.15, 0.15, 1}
    end
    coinageFrame.bg:SetColorTexture(unpack(bgColor))
  end
end

-- Check if frame should be visible
local function ShouldShowCoinageTracker()
  return PPT_UI_Settings.coinageTracker.enabled
end

-- Global function for Options.lua to check coinage tracker status
function IsCoinageTrackerEnabled()
  return PPT_UI_Settings.coinageTracker.enabled
end

-- Initialize or update the coinage tracker
function UpdateCoinageTracker()
  if ShouldShowCoinageTracker() then
    if not coinageFrame then
      CreateCoinageTracker()
    end
    
    if coinageFrame then
      coinageFrame:Show()
      UpdateCoinageDisplay()
      ApplyCoinageSettings()
    end
  else
    if coinageFrame then
      coinageFrame:Hide()
    end
    -- Don't hide the anchor frame - just its visual elements
    if anchorFrame then
      anchorFrame.visual:Hide()
      anchorFrame.border:Hide()
    end
  end
end

-- Set stealth transition state to prevent jumping
function SetStealthTransition(inTransition)
  isStealthTransition = inTransition
  -- During stealth transitions, we may want to delay updates
  if not inTransition then
    -- Update display after transition completes
    if UpdateCoinageDisplay then
      UpdateCoinageDisplay()
    end
  end
end

-- Toggle the UI element
function ToggleCoinageTracker()
  PPT_UI_Settings.coinageTracker.enabled = not PPT_UI_Settings.coinageTracker.enabled
  UpdateCoinageTracker()
end

-- Reset the coinage tracker position to default
function ResetCoinageTrackerPosition()
  PPT_UI_Settings.coinageTracker.left = 100
  PPT_UI_Settings.coinageTracker.top = 100
  PPT_UI_Settings.coinageTracker.anchorPoint = "CENTER"
  if UpdateCoinageTracker then
    UpdateCoinageTracker()
  end
  print("Pickpocket Tracker: Position reset to default")
end

------------------------------------------------------------
--                   EVENT HANDLERS
------------------------------------------------------------

-- Update display when money changes
local function OnMoneyChanged()
  UpdateCoinageDisplay()
end

-- Main update function called by other modules
function UpdateUI()
  UpdateCoinageTracker()
end

-- Initialize UI
function InitializeUI()
  DebugPrint("UI: Initializing UI system")
  UpdateCoinageTracker()
end

-- Clean up UI
function CleanupUI()
  if coinageFrame then
    coinageFrame:Hide()
    coinageFrame = nil
  end
  if anchorFrame then
    anchorFrame:Hide()
    anchorFrame = nil
  end
end
