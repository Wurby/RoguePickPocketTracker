-- Options/Main.lua
-- Main options panel and standalone window framework

------------------------------------------------------------
--                     OPTIONS PANEL
------------------------------------------------------------

local panel = CreateFrame("Frame", "RoguePickPocketTrackerOptions")
panel.name = "RoguePickPocketTracker"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Rogue PickPocket Tracker")

-- Simplified traditional panel - just opens standalone window
local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
openBtn:SetSize(150, 25)
openBtn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
openBtn:SetText("Open Options Window")
openBtn:SetScript("OnClick", function() 
  if ShowStandaloneOptions then
    ShowStandaloneOptions() 
  else
    PPTPrint("Options window not available yet. Please try again.")
  end
end)

local descText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
descText:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -15)
descText:SetText("Click the button above to open the full options window with")
descText:SetTextColor(0.8, 0.8, 0.8)

local descText2 = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
descText2:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -5)
descText2:SetText("statistics, achievements, and all configuration options.")
descText2:SetTextColor(0.8, 0.8, 0.8)

-- Traditional panel registration  
panel.name = "RoguePickPocketTracker"

-- Make panel globally accessible
_G.RoguePickPocketTrackerOptions = panel

-- Register with interface options (Classic Era method)
if InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
elseif Settings and Settings.RegisterCanvasLayoutCategory then
  local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  if category then
    Settings.RegisterAddOnCategory(category)
  end
end

------------------------------------------------------------
--                  STANDALONE OPTIONS
------------------------------------------------------------

local standaloneFrame = nil

-- Show standalone options window
function ShowStandaloneOptions()
  if not standaloneFrame then
    CreateStandaloneWindow()
  end
  
  if standaloneFrame then
    standaloneFrame:Show()
    -- Always show Report tab by default
    standaloneFrame:ShowTab(1)
  else
    PPTPrint("Error: Could not create options window")
  end
end

-- Show standalone achievements window
function ShowStandaloneAchievements()
  if not standaloneFrame then
    CreateStandaloneWindow()
  end
  
  if standaloneFrame then
    standaloneFrame:Show()
    -- Show Achievements tab specifically
    standaloneFrame:ShowTab(2)
  else
    PPTPrint("Error: Could not create options window")
  end
end

-- Hide standalone options window
function HideStandaloneOptions()
  if standaloneFrame then
    standaloneFrame:Hide()
  end
end

-- Toggle standalone options window
function ToggleStandaloneOptions()
  if standaloneFrame and standaloneFrame:IsVisible() then
    HideStandaloneOptions()
  else
    ShowStandaloneOptions()
  end
end

-- Create the standalone options window framework
function CreateStandaloneWindow()
  if standaloneFrame then return standaloneFrame end
  
  -- Main frame - use no template to avoid any modal behavior that blocks input
  standaloneFrame = CreateFrame("Frame", "PPT_StandaloneOptions", UIParent)
  standaloneFrame:SetSize(600, 550)
  standaloneFrame:SetPoint("CENTER")
  standaloneFrame:SetFrameStrata("DIALOG")
  standaloneFrame:SetClampedToScreen(true)
  standaloneFrame:EnableMouse(true)
  standaloneFrame:SetMovable(true)
  standaloneFrame:RegisterForDrag("LeftButton")
  
  -- Background with toast notification styling
  local bg = standaloneFrame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
  
  -- Border effect
  local borderSize = 2
  local borderTop = standaloneFrame:CreateTexture(nil, "BORDER")
  borderTop:SetHeight(borderSize)
  borderTop:SetPoint("TOPLEFT", borderSize, -borderSize)
  borderTop:SetPoint("TOPRIGHT", -borderSize, -borderSize)
  borderTop:SetColorTexture(0.4, 0.4, 0.4, 1)
  
  local borderBottom = standaloneFrame:CreateTexture(nil, "BORDER")
  borderBottom:SetHeight(borderSize)
  borderBottom:SetPoint("BOTTOMLEFT", borderSize, borderSize)
  borderBottom:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
  borderBottom:SetColorTexture(0.4, 0.4, 0.4, 1)
  
  local borderLeft = standaloneFrame:CreateTexture(nil, "BORDER")
  borderLeft:SetWidth(borderSize)
  borderLeft:SetPoint("TOPLEFT", 0, 0)
  borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
  borderLeft:SetColorTexture(0.4, 0.4, 0.4, 1)
  
  local borderRight = standaloneFrame:CreateTexture(nil, "BORDER")
  borderRight:SetWidth(borderSize)
  borderRight:SetPoint("TOPRIGHT", 0, 0)
  borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
  borderRight:SetColorTexture(0.4, 0.4, 0.4, 1)
  
  -- Close button
  local closeButton = CreateFrame("Button", nil, standaloneFrame, "UIPanelCloseButton")
  closeButton:SetScript("OnClick", function() HideStandaloneOptions() end)
  closeButton:SetPoint("TOPRIGHT", standaloneFrame, "TOPRIGHT", -5, -5)
  
  -- Enable keyboard input but propagate movement keys
  standaloneFrame:EnableKeyboard(true)
  standaloneFrame:SetPropagateKeyboardInput(true)
  
  -- Make it draggable
  standaloneFrame:SetScript("OnDragStart", standaloneFrame.StartMoving)
  standaloneFrame:SetScript("OnDragStop", standaloneFrame.StopMovingOrSizing)
  
  -- ESC key handling - only capture ESC, let other keys through
  standaloneFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
      HideStandaloneOptions()
    else
      self:SetPropagateKeyboardInput(true)
    end
  end)
  
  -- Title
  if standaloneFrame.Title then
    standaloneFrame.Title:SetText("Rogue PickPocket Tracker")
  else
    -- Create title if it doesn't exist
    local title = standaloneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", standaloneFrame, "TOP", 0, -15)
    title:SetText("Rogue PickPocket Tracker")
    standaloneFrame.Title = title
  end
  
  -- Create content area
  local content = CreateFrame("Frame", nil, standaloneFrame)
  content:SetPoint("TOPLEFT", 16, -32)
  content:SetPoint("BOTTOMRIGHT", -16, 16)
  standaloneFrame.content = content
  
  -- Create tab system for standalone window
  standaloneFrame.tabs = {}
  standaloneFrame.currentTab = 1
  
  -- Create tab buttons
  local function CreateStandaloneTab(parent, index, text, width)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(width or 100, 24)
    tab:SetNormalFontObject("GameFontNormal")
    tab:SetHighlightFontObject("GameFontHighlight")
    tab:SetDisabledFontObject("GameFontDisable")
    tab:SetText(text)
    
    -- Tab appearance with achievement toast styling
    local normalTexture = tab:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetColorTexture(0.15, 0.15, 0.15, 0.8)
    normalTexture:SetAllPoints()
    tab:SetNormalTexture(normalTexture)
    
    local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetColorTexture(0.25, 0.25, 0.25, 0.8)
    highlightTexture:SetAllPoints()
    tab:SetHighlightTexture(highlightTexture)
    
    return tab
  end
  
  -- Create the tabs
  standaloneFrame.tabs[1] = CreateStandaloneTab(standaloneFrame, 1, "Report", 80)
  standaloneFrame.tabs[1]:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
  
  standaloneFrame.tabs[2] = CreateStandaloneTab(standaloneFrame, 2, "Achievements", 100)
  standaloneFrame.tabs[2]:SetPoint("LEFT", standaloneFrame.tabs[1], "RIGHT", 5, 0)
  
  standaloneFrame.tabs[3] = CreateStandaloneTab(standaloneFrame, 3, "Options", 80)
  standaloneFrame.tabs[3]:SetPoint("LEFT", standaloneFrame.tabs[2], "RIGHT", 5, 0)
  
  -- Initialize tab content from separate files
  CreateReportTab(standaloneFrame, content)
  CreateAchievementsTab(standaloneFrame, content)
  CreateOptionsTab(standaloneFrame, content)
  
  -- Function to show specific tab in standalone window
  function standaloneFrame:ShowTab(tabIndex)
    self.currentTab = tabIndex
    
    -- Update tab appearance
    for i, tab in ipairs(self.tabs) do
      local normalTexture = tab:GetNormalTexture()
      if normalTexture then
        if i == tabIndex then
          normalTexture:SetColorTexture(0.25, 0.25, 0.25, 1.0)
        else
          normalTexture:SetColorTexture(0.15, 0.15, 0.15, 0.8)
        end
      end
    end
    
    -- Show/hide appropriate content and update data
    self.reportView:SetShown(tabIndex == 1)
    self.achievementsView:SetShown(tabIndex == 2)
    self.optionsView:SetShown(tabIndex == 3)
    
    -- Update content based on which tab is shown
    if tabIndex == 1 then
      -- Update report/stats data
      UpdateReportTabData(self)
    elseif tabIndex == 2 then
      -- Update achievements data
      UpdateAchievementsTabData(self)
    elseif tabIndex == 3 then
      -- Update options data
      UpdateOptionsTabData(self)
    end
  end
  
  -- Tab click handlers
  for i, tab in ipairs(standaloneFrame.tabs) do
    tab:SetScript("OnClick", function() standaloneFrame:ShowTab(i) end)
  end
  
  standaloneFrame:Hide()
  return standaloneFrame
end
