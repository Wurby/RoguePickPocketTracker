-- UI.lua
-- Draggable UI elements for RoguePickPocketTracker

------------------------------------------------------------
--                   SAVED VARIABLES
------------------------------------------------------------
PPT_UI_Settings = PPT_UI_Settings or {
  coinageTracker = {
    enabled = true, -- On by default
    position = { point = "TOPRIGHT", x = -100, y = -100 }, -- Default to top-right, out of the way
    scale = 1.0,
    opacity = 1.0,
    showBackground = true,
    fontSize = 12
  }
}

------------------------------------------------------------
--                   COINAGE TRACKER FRAME
------------------------------------------------------------
local coinageFrame = nil

-- Create the main coinage tracker frame
local function CreateCoinageTracker()
  if coinageFrame then return coinageFrame end
  
  -- Main frame - smaller size inspired by achievement toast
  coinageFrame = CreateFrame("Frame", "PPT_CoinageTracker", UIParent)
  coinageFrame:SetSize(180, 35)
  coinageFrame:SetMovable(true)
  coinageFrame:EnableMouse(true)
  coinageFrame:RegisterForDrag("LeftButton")
  coinageFrame:SetClampedToScreen(true)
  
  -- Main background (dark grey/black like achievement toast)
  coinageFrame.bg = coinageFrame:CreateTexture(nil, "BACKGROUND")
  coinageFrame.bg:SetAllPoints()
  coinageFrame.bg:SetColorTexture(0.15, 0.15, 0.15, 0.95) -- Dark grey with slight transparency
  
  -- Create border effect with rounded corners using multiple textures (like achievement toast)
  local borderSize = 1
  
  -- Top border
  local borderTop = coinageFrame:CreateTexture(nil, "BORDER")
  borderTop:SetHeight(borderSize)
  borderTop:SetPoint("TOPLEFT", borderSize, -borderSize)
  borderTop:SetPoint("TOPRIGHT", -borderSize, -borderSize)
  borderTop:SetColorTexture(0.6, 0.6, 0.6, 0.8) -- Grey border
  
  -- Bottom border
  local borderBottom = coinageFrame:CreateTexture(nil, "BORDER")
  borderBottom:SetHeight(borderSize)
  borderBottom:SetPoint("BOTTOMLEFT", borderSize, borderSize)
  borderBottom:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
  borderBottom:SetColorTexture(0.6, 0.6, 0.6, 0.8)
  
  -- Left border
  local borderLeft = coinageFrame:CreateTexture(nil, "BORDER")
  borderLeft:SetWidth(borderSize)
  borderLeft:SetPoint("TOPLEFT", 0, 0)
  borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
  borderLeft:SetColorTexture(0.6, 0.6, 0.6, 0.8)
  
  -- Right border
  local borderRight = coinageFrame:CreateTexture(nil, "BORDER")
  borderRight:SetWidth(borderSize)
  borderRight:SetPoint("TOPRIGHT", 0, 0)
  borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
  borderRight:SetColorTexture(0.6, 0.6, 0.6, 0.8)
  
  -- Corner pieces for rounded effect (smaller than achievement toast)
  local cornerSize = 3
  
  -- Top-left corner
  local cornerTL = coinageFrame:CreateTexture(nil, "ARTWORK")
  cornerTL:SetSize(cornerSize, cornerSize)
  cornerTL:SetPoint("TOPLEFT", 0, 0)
  cornerTL:SetColorTexture(0.6, 0.6, 0.6, 0.8)
  
  -- Top-right corner
  local cornerTR = coinageFrame:CreateTexture(nil, "ARTWORK")
  cornerTR:SetSize(cornerSize, cornerSize)
  cornerTR:SetPoint("TOPRIGHT", 0, 0)
  cornerTR:SetColorTexture(0.6, 0.6, 0.6, 0.8)
  
  -- Bottom-left corner
  local cornerBL = coinageFrame:CreateTexture(nil, "ARTWORK")
  cornerBL:SetSize(cornerSize, cornerSize)
  cornerBL:SetPoint("BOTTOMLEFT", 0, 0)
  cornerBL:SetColorTexture(0.6, 0.6, 0.6, 0.8)
  
  -- Bottom-right corner
  local cornerBR = coinageFrame:CreateTexture(nil, "ARTWORK")
  cornerBR:SetSize(cornerSize, cornerSize)
  cornerBR:SetPoint("BOTTOMRIGHT", 0, 0)
  cornerBR:SetColorTexture(0.6, 0.6, 0.6, 0.8)
  
  -- Subtle inner glow (like achievement toast)
  local innerGlow = coinageFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
  innerGlow:SetPoint("TOPLEFT", 2, -2)
  innerGlow:SetPoint("BOTTOMRIGHT", -2, 2)
  innerGlow:SetColorTexture(1, 0.84, 0, 0.05) -- Very subtle gold glow
  
  -- Title text - smaller and more compact
  coinageFrame.title = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  coinageFrame.title:SetPoint("TOPLEFT", 6, -3)
  coinageFrame.title:SetText("Pick Pocket")
  coinageFrame.title:SetTextColor(1, 0.82, 0) -- Gold color like achievement toast
  
  -- Coinage text - prominent like achievement name
  coinageFrame.coinage = coinageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  coinageFrame.coinage:SetPoint("TOPLEFT", coinageFrame.title, "BOTTOMLEFT", 0, -1)
  coinageFrame.coinage:SetText("0c")
  coinageFrame.coinage:SetTextColor(1, 1, 1) -- White like achievement toast
  
  -- Close button - smaller for compact design
  coinageFrame.closeBtn = CreateFrame("Button", nil, coinageFrame, "UIPanelCloseButton")
  coinageFrame.closeBtn:SetSize(14, 14)
  coinageFrame.closeBtn:SetPoint("TOPRIGHT", -1, -1)
  coinageFrame.closeBtn:SetScript("OnClick", function()
    HideCoinageTracker()
  end)
  
  -- Store border elements for future styling changes
  coinageFrame.borders = {borderTop, borderBottom, borderLeft, borderRight, cornerTL, cornerTR, cornerBL, cornerBR}
  coinageFrame.innerGlow = innerGlow
  
  -- Drag functionality
  coinageFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  
  coinageFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, _, _, x, y = self:GetPoint()
    PPT_UI_Settings.coinageTracker.position = { point = point, x = x, y = y }
    DebugPrint("UI: Coinage tracker moved to %s %d,%d", point, x, y)
  end)
  
  -- Right-click for options (future extensibility)
  coinageFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
      ShowCoinageTrackerOptions()
    end
  end)
  
  -- Tooltip
  coinageFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText("Pick Pocket Tracker", 1, 1, 1)
    GameTooltip:AddLine("Total earnings from pickpocketing", 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click and drag to move", 0.5, 1, 0.5)
    GameTooltip:AddLine("Right-click for options", 0.5, 1, 0.5)
    GameTooltip:AddLine("Close button to hide", 0.5, 1, 0.5)
    GameTooltip:Show()
  end)
  
  coinageFrame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  
  return coinageFrame
end

-- Update the coinage display
local function UpdateCoinageDisplay()
  if not coinageFrame or not coinageFrame:IsVisible() then return end
  
  coinageFrame.coinage:SetText(coinsToString(PPT_TotalCopper))
  
  -- Adjust frame width based on text - more compact than before
  local textWidth = coinageFrame.coinage:GetStringWidth()
  local titleWidth = coinageFrame.title:GetStringWidth()
  local minWidth = math.max(textWidth, titleWidth) + 30 -- Less padding for compact design
  coinageFrame:SetWidth(math.max(minWidth, 120)) -- Smaller minimum width
end

-- Apply settings to the frame
local function ApplyCoinageSettings()
  if not coinageFrame then return end
  
  local settings = PPT_UI_Settings.coinageTracker
  
  -- Position
  coinageFrame:ClearAllPoints()
  coinageFrame:SetPoint(settings.position.point, UIParent, settings.position.point, 
                       settings.position.x, settings.position.y)
  
  -- Scale
  coinageFrame:SetScale(settings.scale)
  
  -- Opacity
  coinageFrame:SetAlpha(settings.opacity)
  
  -- Background visibility
  if settings.showBackground then
    coinageFrame.bg:Show()
    coinageFrame.innerGlow:Show()
    -- Show all border elements
    if coinageFrame.borders then
      for _, border in ipairs(coinageFrame.borders) do
        border:Show()
      end
    end
  else
    coinageFrame.bg:Hide()
    coinageFrame.innerGlow:Hide()
    -- Hide all border elements
    if coinageFrame.borders then
      for _, border in ipairs(coinageFrame.borders) do
        border:Hide()
      end
    end
  end
  
  -- Font size (future extensibility)
  -- Note: This would require recreating font strings with different font objects
  -- For now, we'll keep it simple but the infrastructure is here
end

------------------------------------------------------------
--                   PUBLIC FUNCTIONS
------------------------------------------------------------

-- Show the coinage tracker
function ShowCoinageTracker()
  if not coinageFrame then
    CreateCoinageTracker()
  end
  
  PPT_UI_Settings.coinageTracker.enabled = true
  ApplyCoinageSettings()
  UpdateCoinageDisplay()
  coinageFrame:Show()
  
  DebugPrint("UI: Coinage tracker shown")
end

-- Hide the coinage tracker
function HideCoinageTracker()
  if coinageFrame then
    coinageFrame:Hide()
  end
  
  PPT_UI_Settings.coinageTracker.enabled = false
  DebugPrint("UI: Coinage tracker hidden")
end

-- Toggle the coinage tracker
function ToggleCoinageTracker()
  if PPT_UI_Settings.coinageTracker.enabled then
    HideCoinageTracker()
  else
    ShowCoinageTracker()
  end
end

-- Check if coinage tracker is enabled
function IsCoinageTrackerEnabled()
  return PPT_UI_Settings.coinageTracker.enabled
end

-- Update coinage display (called when money changes)
function UpdateCoinageTracker()
  UpdateCoinageDisplay()
end

-- Reset coinage tracker to default position
function ResetCoinageTrackerPosition()
  PPT_UI_Settings.coinageTracker.position = { point = "TOPRIGHT", x = -100, y = -100 }
  if coinageFrame then
    ApplyCoinageSettings()
  end
  DebugPrint("UI: Coinage tracker position reset")
end

-- Show options for coinage tracker (future extensibility)
function ShowCoinageTrackerOptions()
  -- Use the new standalone options window
  if ShowStandaloneOptions then
    ShowStandaloneOptions()
    DebugPrint("UI: Coinage tracker options requested - showing standalone window")
  else
    PPTPrint("Options window not available yet. Please use /pp options instead.")
    DebugPrint("UI: ShowStandaloneOptions function not available")
  end
end

------------------------------------------------------------
--                   INITIALIZATION
------------------------------------------------------------

-- Initialize UI elements on addon load
local function InitializeUI()
  -- Restore coinage tracker if it was enabled
  if PPT_UI_Settings.coinageTracker.enabled then
    ShowCoinageTracker()
  end
end

-- Event frame for UI initialization
local uiEventFrame = CreateFrame("Frame")
uiEventFrame:RegisterEvent("ADDON_LOADED")
uiEventFrame:SetScript("OnEvent", function(self, event, addonName)
  if event == "ADDON_LOADED" and addonName == "RoguePickPocketTracker" then
    InitializeUI()
    self:UnregisterEvent("ADDON_LOADED")
  end
end)

------------------------------------------------------------
--                   FUTURE EXTENSIBILITY
------------------------------------------------------------

-- Framework for additional UI elements
-- This structure allows easy addition of new draggable elements in the future

PPT_UI_Elements = {
  coinageTracker = {
    create = CreateCoinageTracker,
    show = ShowCoinageTracker,
    hide = HideCoinageTracker,
    toggle = ToggleCoinageTracker,
    update = UpdateCoinageTracker,
    isEnabled = IsCoinageTrackerEnabled
  }
  -- Future elements can be added here:
  -- sessionTracker = { ... },
  -- locationTracker = { ... },
  -- etc.
}

-- Generic function to manage UI elements
function ManageUIElement(elementName, action, ...)
  local element = PPT_UI_Elements[elementName]
  if element and element[action] then
    return element[action](...)
  else
    DebugPrint("UI: Unknown element '%s' or action '%s'", elementName or "nil", action or "nil")
  end
end
