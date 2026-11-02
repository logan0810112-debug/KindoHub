--[[
  KINDO HUB - MAIN ENTRY POINT
  This file orchestrates the loading of all modules.
  To run in an executor: Copy ALL files and paste them in this order:
  1. core.lua
  2. key_system.lua
  3. database.lua
  4. engine.lua
  5. ui.lua
  6. main.lua (This file)
]]

local Core = _G.KindoCore
local KeySystem = _G.KindoKeySystem
local Database = _G.KindoDatabase
local Engine = _G.KindoEngine
local UI = _G.KindoUI

if not Core then
    warn("[KINDO] Core module not found. Ensure all modules are loaded in order.")
    return
end

Core.Log("Initializing KindoHub v" .. Core.Version, "SYSTEM")

-- 1. DETECT GAME
local placeId = game.PlaceId
local profile = Database.GetProfile(placeId)
local gameName = profile and profile.name or game:Name()
Core.Log("Game Detected: " .. gameName, "DETECTION")

-- 2. KEY VALIDATION
local deviceId = KeySystem.GenerateDeviceId()
local expectedKey = KeySystem.GenerateKey(deviceId)
Core.Log("Device ID: " .. deviceId, "KEY")
Core.Log("Generated Key: " .. expectedKey, "KEY")

-- If no key is stored in getgenv, show the modal
if not Core.State.ActiveKey then
    Core.Log("No active key found. Launching Key Modal...", "KEY")
    local overlay, contentFrame, closeModal = UI.ShowModal("KINDO HUB - AUTHENTICATION", "Enter your key to unlock the Universal Hub.")
    
    -- Create Key Input
    local keyInput = Instance.new("TextBox", contentFrame)
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, -20, 0, 40)
    keyInput.Position = UDim2.new(0, 10, 0, 20)
    keyInput.BackgroundColor3 = Core.Theme.Bg
    keyInput.TextColor3 = Core.Theme.Text
    keyInput.Font = Enum.Font.Code
    keyInput.PlaceholderText = "Enter Key (e.g., KIND-MASTER-001 or generated key)"
    
    local submitBtn = Instance.new("TextButton", contentFrame)
    submitBtn.Name = "SubmitKey"
    submitBtn.Size = UDim2.new(1, -20, 0, 40)
    submitBtn.Position = UDim2.new(0, 10, 0, 70)
    submitBtn.BackgroundColor3 = Core.Theme.Accent
    submitBtn.TextColor3 = Core.Theme.Bg
    submitBtn.Font = Enum.Font.Code
    submitBtn.Text = "UNLOCK HUB"
    
    submitBtn.MouseButton1Click:Connect(function()
        local inputKey = keyInput.Text
        local valid, tier = KeySystem.Validate(inputKey, deviceId)
        
        if valid then
            Core.State.ActiveKey = inputKey
            Core.State.Tier = tier
            Core.Log("Key Validated. Tier: " .. tier, "KEY")
            closeModal()
            UI.Initialize()
            Engine.Start()
        else
            Core.Log("Invalid Key: " .. inputKey, "ERROR")
            keyInput.Text = ""
            keyInput.PlaceholderText = "Invalid Key. Try again."
        end
    end)
    
    -- Allow Enter key to submit
    keyInput.FocusLost:Connect(function(_, entered)
        if entered then
            submitBtn.MouseButton1Click:Fire()
        end
    end)
    
else
    Core.Log("Active Key Found: " .. Core.State.ActiveKey .. " (" .. Core.State.Tier .. ")", "KEY")
    UI.Initialize()
    Engine.Start()
end