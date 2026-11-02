--[[ 
  CORE MODULE
  Handles global state, persistence, and utility functions.
]]

local Core = {}
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- 1. GLOBAL STATE PERSISTENCE
-- Uses getgenv() to survive script reloads within the session
Core.State = getgenv().KindoHubState or {
    ActiveKey = nil,
    Settings = {
        FOV = 150,
        AimKey = "MouseButton1",
        ToggleKey = "RightShift",
        ESPColor = Color3.fromRGB(0, 255, 255),
        Speed = 1,
        FlyEnabled = false,
        GodMode = false
    },
    Logs = {}
}
getgenv().KindoHubState = Core.State

-- 2. UTILITIES
function Core.Log(msg, level)
    level = level or "INFO"
    local entry = string.format("[%s] %s: %s", os.date("%H:%M:%S"), level, msg)
    table.insert(Core.State.Logs, entry)
    if #Core.State.Logs > 100 then table.remove(Core.State.Logs, 1) end
    print(("[KINDO] " .. entry))
end

function Core.PcallSafe(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        Core.Log(result, "ERROR")
    end
    return ok, result
end

function Core.GetPlayer()
    return game.Players.LocalPlayer
end

function Core.GetCharacter()
    local plr = Core.GetPlayer()
    return plr and plr.Character
end

function Core.GetHumanoid()
    local char = Core.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Core.IsHumanoidValid()
    local hum = Core.GetHumanoid()
    return hum and hum.Health > 0
end

-- 3. EVENT BRIDGE
-- Allows modules to subscribe to core events without direct coupling
Core.Events = {}
function Core.On(event, callback)
    Core.Events[event] = Core.Events[event] or {}
    table.insert(Core.Events[event], callback)
end

function Core.Emit(event, ...)
    if Core.Events[event] then
        for _, cb in ipairs(Core.Events[event]) do
            Core.PcallSafe(cb, ...)
        end
    end
end

return Core