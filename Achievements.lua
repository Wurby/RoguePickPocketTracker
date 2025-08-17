-- Achievements.lua
-- Achievement tracking for RoguePickPocketTracker

-- Initialize saved variable table
PPT_Achievements = type(PPT_Achievements) == "table" and PPT_Achievements or {}

-- Achievement catalog
Achievements = {
  PICKPOCKET_100 = {
    id = 1,
    name = "Cutpurse",
    description = "Pick pocket 100 targets",
    goal = 100,
    progress = 0,
  },
  PICKPOCKET_1K = {
    id = 2,
    name = "Master Thief",
    description = "Pick pocket 1000 targets",
    goal = 1000,
    progress = 0,
  },
  PICKPOCKET_5K = {
    id = 3,
    name = "Grand Larcenist",
    description = "Pick pocket 5000 targets",
    goal = 5000,
    progress = 0,
  },
  EARN_25G_SESSION = {
    id = 4,
    name = "Big Haul",
    description = "Loot 25 gold in a single session",
    goal = 2500,
    progress = 0,
  },
  EARN_100G_SESSION = {
    id = 5,
    name = "Massive Haul",
    description = "Loot 100 gold in a single session",
    goal = 10000,
    progress = 0,
  },
  LOOT_1_ITEM_SESSION = {
    id = 6,
    name = "Ooh, Piece of Candy",
    description = "Loot 1 item in a single session",
    goal = 1,
    progress = 0,
  },
  LOOT_2_ITEMS_SESSION = {
    id = 7,
    name = "You don't need this, right?",
    description = "Loot 2 items in a single session",
    goal = 2,
    progress = 0,
  },
  LOOT_5_ITEMS_SESSION = {
    id = 8,
    name = "Thanks, Obama.",
    description = "Loot 5 items in a single session",
    goal = 5,
    progress = 0,
  },
  LOOT_10_ITEMS_SESSION = {
    id = 9,
    name = "My backpack is full",
    description = "Loot 10 items in a single session",
    goal = 10,
    progress = 0,
  },
  SESSION_TARGETS_1 = {
    id = 10,
    name = "Noob",
    description = "Pick pocket 1 target in a single session",
    goal = 1,
    progress = 0,
  },
  SESSION_TARGETS_3 = {
    id = 11,
    name = "Amateur",
    description = "Pick pocket 3 targets in a single session",
    goal = 3,
    progress = 0,
  },
  SESSION_TARGETS_5 = {
    id = 12,
    name = "Professional",
    description = "Pick pocket 5 targets in a single session",
    goal = 5,
    progress = 0,
  },
  SESSION_TARGETS_10 = {
    id = 13,
    name = "Ninja",
    description = "Pick pocket 10 targets in a single session",
    goal = 10,
    progress = 0,
  },
  SESSION_TARGETS_15 = {
    id = 14,
    name = "Was that my shadow?",
    description = "Pick pocket 15 targets in a single session",
    goal = 15,
    progress = 0,
  },
}

-- Load saved progress
for id, ach in pairs(Achievements) do
  local saved = PPT_Achievements[id]
  if type(saved) == "table" then
    ach.progress = saved.progress or ach.progress
    ach.completed = saved.completed or false
  end
end

local function persist(id)
  local ach = Achievements[id]
  if not ach then return end
  PPT_Achievements[id] = {
    progress = ach.progress,
    completed = ach.completed,
  }
end

function Celebrate(id)
  local ach = Achievements[id]
  if not ach then return end
  PPTPrint("Achievement Unlocked:", ach.name)
  PlaySound(12889)
end

function UpdateAchievement(id, value)
  local ach = Achievements[id]
  if not ach or ach.completed then return end

  ach.progress = (ach.progress or 0) + (value or 0)
  if ach.progress >= ach.goal then
    ach.completed = true
  end

  persist(id)
  if ach.completed then Celebrate(id) end
end

function GetAchievementProgressText(ach)
  if ach.completed then
    return "|cff00ff00Completed|r"
  end
  return string.format("%d/%d", ach.progress or 0, ach.goal)
end

