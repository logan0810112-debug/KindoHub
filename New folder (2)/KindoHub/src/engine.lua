--[[
  ENGINE MODULE
  Handles Combat (Aimbot/Triggerbot), Movement, and Game-Specific Logic.
]]

local Engine = {}
local Core = require(script:WaitForChild("core.lua"))
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

Engine.State = {
    Target = nil,
    FOV = 150,
    Smoothness = 0.1,
    Triggerbot = false
}

-- 1. TARGETING LOGIC
function Engine.FindBestTarget()
    local plr = Core.GetPlayer()
    local char = Core.GetCharacter()
    if not char then return nil end
    
    local cam = Workspace.CurrentCamera
    local camPos = cam.CFrame.Position
    local camDir = cam.CFrame.LookVector
    local fov = Engine.State.FOV
    local fovRad = math.rad(fov)
    
    local bestTarget = nil
    local bestDot = -1
    local bestDist = math.huge
    
    for _, other in ipairs(game.Players:GetPlayers()) do
        if other ~= plr and other.Character then
            local targetHead = other.Character:FindFirstChild("Head")
            if targetHead then
                local headPos = targetHead.Position
                local toTarget = headPos - camPos
                local dist = toTarget.Magnitude
                
                if dist < 150 then -- Max range
                    local dirToTarget = toTarget.Unit
                    local dot = Vector3.Dot(camDir, dirToTarget)
                    
                    -- Angle check
                    if math.acos(math.clamp(dot, -1, 1)) < fovRad then
                        -- Prioritize closer targets if within FOV
                        if dist < bestDist then
                            bestDist = dist
                            bestTarget = other
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

function Engine.GetHeadPosition(player)
    local char = player.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    return head and head.Position or nil
end

-- 2. AIMBOT EXECUTION
function Engine.Tick(dt)
    local plr = Core.GetPlayer()
    local char = Core.GetCharacter()
    if not char then return end
    
    local cam = Workspace.CurrentCamera
    local camPos = cam.CFrame.Position
    
    -- 1. Determine Target
    if Core.State.Settings.Aimbot then
        Engine.State.Target = Engine.FindBestTarget()
    end
    
    -- 2. Apply Aim
    if Engine.State.Target then
        local targetHeadPos = Engine.GetHeadPosition(Engine.State.Target)
        if targetHeadPos then
            local lookAt = CFrame.lookAt(camPos, targetHeadPos)
            local currentCF = cam.CFrame
            local newCF = currentCF:Lerp(lookAt, Engine.State.Smoothness)
            
            -- Only rotate, don't move camera position
            cam.CFrame = CFrame.new(camPos, targetHeadPos)
        end
    end
    
    -- 3. Triggerbot
    if Core.State.Settings.Triggerbot and Engine.State.Target then
        local targetHeadPos = Engine.GetHeadPosition(Engine.State.Target)
        if targetHeadPos then
            -- Check if target is in center crosshair (approx 5 units)
            local center = cam.CFrame.Position + (cam.CFrame.LookVector * 20)
            if (center - targetHeadPos).Magnitude < 5 then
                -- Simulate Mouse Click
                local mouse = plr:GetMouse()
                mouse:Click()
            end
        end
    end
end

-- 3. MOVEMENT FEATURES
function Engine.ApplyMovement(dt)
    local plr = Core.GetPlayer()
    local char = Core.GetCharacter()
    local hum = Core.GetHumanoid()
    
    if not char or not hum then return end
    
    -- Speed
    if Core.State.Settings.Speed and Core.State.Settings.Speed > 0 then
        hum.WalkSpeed = 16 + (Core.State.Settings.Speed * 16)
    else
        hum.WalkSpeed = 16
    end
    
    -- Jump
    if Core.State.Settings.Jump then
        hum.JumpPower = 100
    else
        hum.JumpPower = 50
    end
    
    -- Fly
    if Core.State.Settings.FlyEnabled then
        hum.PlatformStand = true
        -- Simple fly logic: Up/Down keys
        local keys = UserInputService:GetKeysPressed()
        local up = table.find(keys, Enum.KeyCode.W)
        local down = table.find(keys, Enum.KeyCode.S)
        local upKey = table.find(keys, Enum.KeyCode.Space)
        local downKey = table.find(keys, Enum.KeyCode.LeftControl)
        
        local velocity = Vector3.new()
        if up or upKey then velocity.Y = velocity.Y + 50 end
        if down or downKey then velocity.Y = velocity.Y - 50 end
        
        -- Horizontal movement based on WASD relative to camera
        local cam = Workspace.CurrentCamera
        local camCF = cam.CFrame
        local forward = camCF.Look