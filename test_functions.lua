-- Simple test script to verify key functions work in Classic Era
-- This file can be deleted after testing

print("Testing Rogue PickPocket Tracker functions...")

-- Test 1: Check if our global functions exist
if PPT_UI and PPT_UI.ShowCoinageTracker then
    print("✓ PPT_UI.ShowCoinageTracker exists")
else
    print("✗ PPT_UI.ShowCoinageTracker missing")
end

if ShowStandaloneOptions then
    print("✓ ShowStandaloneOptions exists")
else
    print("✗ ShowStandaloneOptions missing")
end

-- Test 2: Check if SavedVariables are working
if PPT_UI_Settings then
    print("✓ PPT_UI_Settings exists")
    if PPT_UI_Settings.coinageTracker then
        print("✓ coinageTracker settings exist")
    else
        print("✗ coinageTracker settings missing")
    end
else
    print("✗ PPT_UI_Settings missing")
end

-- Test 3: Check if UIPanelDialogTemplate is available
local testFrame = CreateFrame("Frame", "PPT_Test", UIParent, "UIPanelDialogTemplate")
if testFrame then
    print("✓ UIPanelDialogTemplate works")
    testFrame:Hide()
    testFrame = nil
else
    print("✗ UIPanelDialogTemplate failed")
end

-- Test 4: Check money formatting
if PPT_GetCopperString then
    local testMoney = 1234567  -- 123g 45s 67c
    local formatted = PPT_GetCopperString(testMoney)
    print("✓ Money formatting: " .. formatted)
else
    print("✗ PPT_GetCopperString missing")
end

print("Test script complete.")
