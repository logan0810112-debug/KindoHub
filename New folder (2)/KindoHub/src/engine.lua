local Engine = {}
local Core = _G.KindoCore
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

Engine.State = {
    Target = nil,
    Smoothness = 0.15,
    Running = false
}

function Engine.FindBestTarget()
    local plr = Core.GetPlayer()
    local char = Core.GetCharacter()
    if not char then return nil end
    
    local cam = workspace.CurrentCamera
    local camPos = cam.CFrame.Position
    local camDir = cam.CFrame.LookVector
    local fovRad = math.rad(Core.State.Settings.FOV)
    
    local bestTarget = nil
    local bestDist = math.huge
    
    for _, other in ipairs(game.Players:GetPlayers()) do
        if other ~= plr and other.Character then
            local head = other.Character:FindFirstChild("Head")
            if head then
                local headPos = head.Position
                local toTarget = headPos - camPos
                local dist = toTarget.Magnitude
                
                if dist < 150 then
                    local dirToTarget = toTarget.Unit
                    local dot = Vector3.Dot(camDir, dirToTarget)
                    if math.acos(math.clamp(dot, -1, 1)) < fovRad and dist < bestDist then
                        bestDist = dist
                        bestTarget = other
                    end
                end
            end
        end
    end
    return bestTarget
end

function Engine.Tick()
    local plr = Core.GetPlayer()
    local char = Core.GetCharacter()
    if not char then return end
    
    local cam = workspace.CurrentCamera
    local camPos = cam.CFrame.Position
    
    -- Aimbot
    if Core.State.Settings.Aimbot then
        Engine.State.Target = Engine.FindBestTarget()
        if Engine.State.Target then
            local head = Engine.State.Target.Character:FindFirstChild("Head")
            if head then
                local lookAt = CFrame.lookAt(camPos, head.Position)
                cam.CFrame = cam.CFrame:Lerp(lookAt, Engine.State.Smoothness)
            end
        end
    end
    
    -- Triggerbot
    if Core.State.Settings.Triggerbot and Engine.State.Target then
        local head = Engine.State.Target.Character:FindFirstChild("Head")
        if head then
            local center = camPos + (cam.CFrame.LookVector * 20)
            if (center - head.Position).Magnitude < 5 then
                plr:GetMouse():Click()
            end
        end
    end
    
    -- Movement
    local hum = Core.GetHumanoid()
    if hum then
        hum.WalkSpeed = 16 + (Core.State.Settings.Speed * 16)
        if Core.State.Settings.FlyEnabled then
            hum.PlatformStand = true
        else
            hum.PlatformStand = false
        end
    end
end

function Engine.Start()
    if Engine.State.Running then return end
    Engine.State.Running = true
    Core.Log("Engine Started", "SYSTEM")
    
    RunService.Heartbeat:Connect(function()
        Core.PcallSafe(Engine.Tick)
    end)
end

_G.KindoEngine = Engine
return Engine