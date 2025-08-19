-- Options/Achievements.lua
-- Achievements tab content for standalone options window

function CreateAchievementsTab(standaloneFrame, content)
  -- Create the achievements view container
  standaloneFrame.achievementsView = CreateFrame("Frame", nil, content)
  standaloneFrame.achievementsView:SetPoint("TOPLEFT", standaloneFrame.tabs[1], "BOTTOMLEFT", 0, -5)
  standaloneFrame.achievementsView:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
  
  -- Achievements header
  local achievementHeader = standaloneFrame.achievementsView:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  achievementHeader:SetPoint("TOPLEFT", standaloneFrame.achievementsView, "TOPLEFT", 10, -10)
  achievementHeader:SetText("Achievements:")
  achievementHeader:SetTextColor(1, 0.82, 0)
  
  -- Achievements scroll frame
  standaloneFrame.achievementScrollFrame = CreateFrame("ScrollFrame", nil, standaloneFrame.achievementsView, "UIPanelScrollFrameTemplate")
  standaloneFrame.achievementScrollFrame:SetPoint("TOPLEFT", achievementHeader, "BOTTOMLEFT", 0, -10)
  standaloneFrame.achievementScrollFrame:SetSize(480, 420) -- Fit within the window properly
  
  standaloneFrame.achievementContent = CreateFrame("Frame", nil, standaloneFrame.achievementScrollFrame)
  standaloneFrame.achievementContent:SetSize(480, 420)
  standaloneFrame.achievementScrollFrame:SetScrollChild(standaloneFrame.achievementContent)
  
  -- Hide by default
  standaloneFrame.achievementsView:Hide()
end

-- Update achievements data
function UpdateAchievementsTabData(standaloneFrame)
  if not standaloneFrame or not standaloneFrame.achievementContent then return end
  
  -- Clear existing achievement displays
  for i = 1, 50 do
    local child = _G["PPT_StandaloneAchievementEntry" .. i]
    if child then
      child:Hide()
    end
    local categoryChild = _G["PPT_StandaloneAchievementCategory" .. i]
    if categoryChild then
      categoryChild:Hide()
    end
  end
  
  -- Check if achievements are available
  if not getAchievementCategories then
    local noData = standaloneFrame.achievementContent:CreateFontString("PPT_StandaloneAchievementNoData", "ARTWORK", "GameFontHighlight")
    noData:SetPoint("TOPLEFT", standaloneFrame.achievementContent, "TOPLEFT", 10, -10)
    noData:SetText("Achievement system not loaded yet...")
    return
  end
  
  local yOffset = 0
  local entryIndex = 1
  
  -- Get all categories
  local categories = getAchievementCategories()
  
  for _, categoryName in ipairs(categories) do
    local achievements = getAchievementsByCategory(categoryName)
    
    if achievements and #achievements > 0 then
      -- Category header
      local categoryHeader = _G["PPT_StandaloneAchievementCategory" .. entryIndex]
      if not categoryHeader then
        categoryHeader = standaloneFrame.achievementContent:CreateFontString("PPT_StandaloneAchievementCategory" .. entryIndex, "ARTWORK", "GameFontNormal")
        categoryHeader:SetPoint("TOPLEFT", standaloneFrame.achievementContent, "TOPLEFT", 0, -yOffset)
        categoryHeader:SetWidth(420)
        categoryHeader:SetJustifyH("LEFT")
      end
      
      categoryHeader:SetText(string.upper(categoryName:gsub("_", " ")))
      categoryHeader:SetTextColor(1, 0.82, 0) -- Gold
      categoryHeader:Show()
      yOffset = yOffset + 20
      entryIndex = entryIndex + 1
      
      -- Achievements in this category
      for _, achievement in ipairs(achievements) do
        local progress = getAchievementProgress(achievement.id)
        local isCompleted = isAchievementCompleted(achievement.id)
        local entryFrame = _G["PPT_StandaloneAchievementEntry" .. entryIndex]
        
        if not entryFrame then
          -- Create a frame container for the achievement entry
          entryFrame = CreateFrame("Frame", "PPT_StandaloneAchievementEntry" .. entryIndex, standaloneFrame.achievementContent)
          entryFrame:SetSize(460, 40)
          entryFrame:SetPoint("TOPLEFT", standaloneFrame.achievementContent, "TOPLEFT", 5, -yOffset)
          
          -- Background for the achievement entry
          entryFrame.bg = entryFrame:CreateTexture(nil, "BACKGROUND")
          entryFrame.bg:SetAllPoints()
          entryFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
          
          -- Achievement icon
          entryFrame.icon = entryFrame:CreateTexture(nil, "ARTWORK")
          entryFrame.icon:SetSize(32, 32)
          entryFrame.icon:SetPoint("LEFT", entryFrame, "LEFT", 4, 0)
          
          -- Achievement name
          entryFrame.name = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
          entryFrame.name:SetPoint("TOPLEFT", entryFrame.icon, "TOPRIGHT", 8, 0)
          entryFrame.name:SetWidth(280)
          entryFrame.name:SetJustifyH("LEFT")
          
          -- Achievement description
          entryFrame.description = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
          entryFrame.description:SetPoint("TOPLEFT", entryFrame.name, "BOTTOMLEFT", 0, -2)
          entryFrame.description:SetWidth(280)
          entryFrame.description:SetJustifyH("LEFT")
          entryFrame.description:SetTextColor(0.8, 0.8, 0.8)
          
          -- Progress/status
          entryFrame.progress = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
          entryFrame.progress:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -5, 0)
          entryFrame.progress:SetJustifyH("RIGHT")
        end
        
        -- Set achievement icon
        if achievement.icon then
          entryFrame.icon:SetTexture(achievement.icon)
        else
          entryFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
        end
        
        -- Set achievement name with status color
        local nameText = achievement.name
        if isCompleted then
          entryFrame.name:SetText("|cff00ff00" .. nameText .. "|r")
          entryFrame.progress:SetText("|cff00ff00[COMPLETE]|r")
          entryFrame.progress:SetTextColor(0, 1, 0)
        else
          entryFrame.name:SetText(nameText)
          entryFrame.name:SetTextColor(1, 1, 1)
          local percentage = getAchievementCompletionPercentage(achievement.id)
          
          -- Format progress based on achievement category
          local progressText
          if achievement.category == "total_money" then
            progressText = string.format("|cffff8000[%d%%]|r\n%s/%s", 
              percentage, 
              coinsToString(progress), 
              coinsToString(achievement.goal))
          else
            progressText = string.format("|cffff8000[%d%%]|r\n%d/%d", 
              percentage, 
              progress, 
              achievement.goal)
          end
          
          entryFrame.progress:SetText(progressText)
          entryFrame.progress:SetTextColor(1, 0.5, 0)
        end
        
        -- Set description
        entryFrame.description:SetText(achievement.description)
        
        entryFrame:Show()
        yOffset = yOffset + 45
        entryIndex = entryIndex + 1
      end
      yOffset = yOffset + 15
    end
  end
  
  -- Update scroll child size
  standaloneFrame.achievementContent:SetHeight(math.max(450, yOffset))
end
