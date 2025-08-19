-- Options/Report.lua
-- Report tab content for standalone options window

function CreateReportTab(standaloneFrame, content)
  -- Create the report view container
  standaloneFrame.reportView = CreateFrame("Frame", nil, content)
  standaloneFrame.reportView:SetPoint("TOPLEFT", standaloneFrame.tabs[1], "BOTTOMLEFT", 0, -5)
  standaloneFrame.reportView:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
  
  -- Main stats display
  local statsHeader = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  statsHeader:SetPoint("TOPLEFT", standaloneFrame.reportView, "TOPLEFT", 10, -10)
  statsHeader:SetText("Statistics:")
  statsHeader:SetTextColor(1, 0.82, 0)
  
  -- Create stat labels
  standaloneFrame.statCoin = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statCoin:SetPoint("TOPLEFT", statsHeader, "BOTTOMLEFT", 10, -10)
  standaloneFrame.statCoin:SetText("Total Coinage: 0c")
  
  standaloneFrame.statItems = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statItems:SetPoint("TOPLEFT", standaloneFrame.statCoin, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statItems:SetText("Total Items: 0")
  
  standaloneFrame.statAttempts = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statAttempts:SetPoint("TOPLEFT", standaloneFrame.statItems, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statAttempts:SetText("Attempts: 0")
  
  standaloneFrame.statSuccess = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statSuccess:SetPoint("TOPLEFT", standaloneFrame.statAttempts, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statSuccess:SetText("Successes: 0")
  
  standaloneFrame.statFails = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statFails:SetPoint("TOPLEFT", standaloneFrame.statSuccess, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statFails:SetText("Fails: 0")
  
  standaloneFrame.statAvgAttempt = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statAvgAttempt:SetPoint("TOPLEFT", standaloneFrame.statFails, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statAvgAttempt:SetText("Avg/Attempt: 0c")
  
  standaloneFrame.statAvgSuccess = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  standaloneFrame.statAvgSuccess:SetPoint("TOPLEFT", standaloneFrame.statAvgAttempt, "BOTTOMLEFT", 0, -5)
  standaloneFrame.statAvgSuccess:SetText("Avg/Success: 0c")
  
  -- Zone statistics section
  local zoneHeader = standaloneFrame.reportView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  zoneHeader:SetPoint("TOPLEFT", standaloneFrame.statAvgSuccess, "BOTTOMLEFT", -10, -20)
  zoneHeader:SetText("Zone Statistics (Top 10):")
  zoneHeader:SetTextColor(1, 0.82, 0)
  
  standaloneFrame.zoneScrollFrame = CreateFrame("ScrollFrame", nil, standaloneFrame.reportView, "UIPanelScrollFrameTemplate")
  standaloneFrame.zoneScrollFrame:SetPoint("TOPLEFT", zoneHeader, "BOTTOMLEFT", 0, -10)
  standaloneFrame.zoneScrollFrame:SetSize(420, 140)
  
  standaloneFrame.zoneContent = CreateFrame("Frame", nil, standaloneFrame.zoneScrollFrame)
  standaloneFrame.zoneContent:SetSize(420, 140)
  standaloneFrame.zoneScrollFrame:SetScrollChild(standaloneFrame.zoneContent)
  
  -- Hide by default
  standaloneFrame.reportView:Hide()
end

-- Update functions for Report tab data
function UpdateReportTabData(standaloneFrame)
  if not standaloneFrame or not standaloneFrame.reportView then return end
  
  -- Update statistics
  local coin = PPT_TotalCopper or 0
  local items = PPT_TotalItems or 0
  local attempts = PPT_TotalAttempts or 0
  local successes = PPT_SuccessfulAttempts or 0
  local fails = attempts - successes

  standaloneFrame.statCoin:SetText("Total Coinage: " .. coinsToString(coin))
  standaloneFrame.statItems:SetText("Total Items: " .. items)
  standaloneFrame.statAttempts:SetText("Attempts: " .. attempts)
  standaloneFrame.statSuccess:SetText("Successes: " .. successes)
  standaloneFrame.statFails:SetText("Fails: " .. fails)

  if attempts > 0 then
    standaloneFrame.statAvgAttempt:SetText("Avg/Attempt: " .. coinsToString(math.floor(coin / attempts)))
    if successes > 0 then
      standaloneFrame.statAvgSuccess:SetText("Avg/Success: " .. coinsToString(math.floor(coin / successes)))
    else
      standaloneFrame.statAvgSuccess:SetText("Avg/Success: 0c")
    end
  else
    standaloneFrame.statAvgAttempt:SetText("Avg/Attempt: 0c")
    standaloneFrame.statAvgSuccess:SetText("Avg/Success: 0c")
  end

  -- Update zone stats
  UpdateZoneStatsData(standaloneFrame)
end

-- Zone stats update function
function UpdateZoneStatsData(standaloneFrame)
  if not standaloneFrame or not standaloneFrame.zoneContent then return end
  
  -- Clear existing zone displays
  for i = 1, 20 do
    local child = _G["PPT_StandaloneZoneEntry" .. i]
    if child then
      child:Hide()
    end
  end

  if not PPT_ZoneStats then return end

  -- Sort zones by total coin
  local sortedZones = {}
  for zone, data in pairs(PPT_ZoneStats) do
    table.insert(sortedZones, {zone = zone, coin = data.copper or 0, items = data.items or 0})
  end

  table.sort(sortedZones, function(a, b) return a.coin > b.coin end)

  local yOffset = 0
  local maxEntries = math.min(10, #sortedZones)

  for i = 1, maxEntries do
    local data = sortedZones[i]
    local entry = _G["PPT_StandaloneZoneEntry" .. i]
    
    if not entry then
      entry = standaloneFrame.zoneContent:CreateFontString("PPT_StandaloneZoneEntry" .. i, "ARTWORK", "GameFontHighlight")
      entry:SetPoint("TOPLEFT", standaloneFrame.zoneContent, "TOPLEFT", 0, -yOffset)
      entry:SetWidth(400)
      entry:SetJustifyH("LEFT")
    end
    
    entry:SetText(string.format("%s: %s (%d items)", data.zone, coinsToString(data.coin), data.items))
    entry:Show()
    yOffset = yOffset + 15
  end
  
  -- Update scroll child size
  standaloneFrame.zoneContent:SetHeight(math.max(140, yOffset))
end
