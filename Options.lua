-- Options.lua
-- Interface options panel for RoguePickPocketTracker

------------------------------------------------------------
--                     OPTIONS PANEL
------------------------------------------------------------

local panel = CreateFrame("Frame", "RoguePickPocketTrackerOptions")
panel.name = "RoguePickPocketTracker"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Rogue PickPocket Tracker")

-- Checkbox: toggle loot messages
panel.showMsg = CreateFrame("CheckButton", "PPT_ShowMsgCheck", panel, "InterfaceOptionsCheckButtonTemplate")
panel.showMsg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
panel.showMsg.Text:SetText("Show loot messages")
panel.showMsg:SetScript("OnClick", function(self) PPT_ShowMsg = self:GetChecked() end)

panel.shareGroup = CreateFrame("CheckButton", "PPT_ShareGroupCheck", panel, "InterfaceOptionsCheckButtonTemplate")
panel.shareGroup:SetPoint("TOPLEFT", panel.showMsg, "BOTTOMLEFT", 0, -8)
panel.shareGroup.Text:SetText("Auto share stats")
panel.shareGroup:SetScript("OnClick", function(self) PPT_ShareGroup = self:GetChecked() end)

-- Reset statistics button
panel.resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.resetBtn:SetSize(140, 22)
panel.resetBtn:SetPoint("TOPLEFT", panel.shareGroup, "BOTTOMLEFT", 0, -10)
panel.resetBtn:SetText("Reset Statistics")
panel.resetBtn:SetScript("OnClick", function()
  ResetAllStats()
  panel:updateStats()
end)

-- Statistics text labels
panel.statsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.statsHeader:SetPoint("TOPLEFT", panel.resetBtn, "BOTTOMLEFT", 0, -20)
panel.statsHeader:SetText("Totals:")

panel.statCoin = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statCoin:SetPoint("TOPLEFT", panel.statsHeader, "BOTTOMLEFT", 0, -4)

panel.statItems = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statItems:SetPoint("TOPLEFT", panel.statCoin, "BOTTOMLEFT", 0, -4)

panel.statAttempts = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statAttempts:SetPoint("TOPLEFT", panel.statItems, "BOTTOMLEFT", 0, -10)

panel.statSuccess = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statSuccess:SetPoint("TOPLEFT", panel.statAttempts, "BOTTOMLEFT", 0, -4)

panel.statFails = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statFails:SetPoint("TOPLEFT", panel.statSuccess, "BOTTOMLEFT", 0, -4)

panel.statAvgAttempt = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statAvgAttempt:SetPoint("TOPLEFT", panel.statFails, "BOTTOMLEFT", 0, -10)

panel.statAvgSuccess = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
panel.statAvgSuccess:SetPoint("TOPLEFT", panel.statAvgAttempt, "BOTTOMLEFT", 0, -4)

-- Refresh stats display
function panel:updateStats()
  self.showMsg:SetChecked(PPT_ShowMsg)
  self.shareGroup:SetChecked(PPT_ShareGroup)
  self.statCoin:SetText("Total Coinage: "..coinsToString(PPT_TotalCopper))
  self.statItems:SetText("Total Items: "..PPT_TotalItems)
  self.statAttempts:SetText("Attempts: "..PPT_TotalAttempts)
  self.statSuccess:SetText("Successes: "..PPT_SuccessfulAttempts)
  self.statFails:SetText("Fails: "..(PPT_TotalAttempts - PPT_SuccessfulAttempts))
  local avgAttempt = (PPT_TotalAttempts > 0) and math.floor(PPT_TotalCopper / PPT_TotalAttempts) or 0
  local avgSuccess = (PPT_SuccessfulAttempts > 0) and math.floor(PPT_TotalCopper / PPT_SuccessfulAttempts) or 0
  self.statAvgAttempt:SetText("Avg/Attempt: "..coinsToString(avgAttempt))
  self.statAvgSuccess:SetText("Avg/Success: "..coinsToString(avgSuccess))
end

panel:SetScript("OnShow", function(self) self:updateStats() end)

-- Make panel globally accessible
_G.RoguePickPocketTrackerOptions = panel

-- Register with interface options (Classic Era method)
if InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
elseif Settings and Settings.RegisterCanvasLayoutCategory then
  local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  if category then
    Settings.RegisterAddOnCategory(category)
    panel.settingsCategory = category
    _G.PPT_SettingsCategory = category
  end
end

