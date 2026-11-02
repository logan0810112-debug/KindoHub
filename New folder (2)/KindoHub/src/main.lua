-- ==========================================
-- KINDO HUB: ENTRY POINT
-- Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/KindoHub/main/src/main.lua"))()
-- ==========================================

local function loadModule(path)
    local file = game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/KindoHub/main/src/" .. path)
    return loadstring(file)()
end

-- Load Core Modules
local Core = loadModule("core.lua")
local Database = loadModule("database.lua")
local Engine = loadModule("engine.lua")
local UI = loadModule("ui.lua")
local KeySystem = loadModule("key_system.lua")

-- Initialize Hub
Core:Initialize()

-- Detect Game
local detectedGame = Database:DetectGame()
Core:Log("Detected Game: " .. detectedGame)

-- Apply Game Profile
Core:ApplyProfile(Database:GetProfile(detectedGame))

-- Start Engine
Engine:Start()

-- Launch UI with Key System
UI:Launch(KeySystem)

Core:Log("KindoHub Initialized Successfully.")