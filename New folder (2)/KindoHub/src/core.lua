local Core = {}
Core.Version = "1.0.0"
Core.Theme = {
    Bg = Color3.fromRGB(18, 18, 18),
    Panel = Color3.fromRGB(28, 28, 32),
    Accent = Color3.fromRGB(0, 255, 255),
    AccentAlt = Color3.fromRGB(255, 0, 255),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(120, 120, 130),
    Success = Color3.fromRGB(0, 255, 100),
    Error = Color3.fromRGB(255, 60, 60),
    Border = Color3.fromRGB(50, 50, 60)
}

-- 1. GLOBAL STATE PERSISTENCE
Core.State = getgenv().KindoHubState or {
    ActiveKey = nil,
    Tier = nil,
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

-- 3. EVENT BRIDGE
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

-- Register in Global Namespace
_G.KindoCore = Core
return Core