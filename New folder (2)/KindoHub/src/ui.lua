--[[
  UI MODULE
  Implements the Cyberpunk-themed interface using native Roblox APIs.
  Features: Draggable window, Tabbed navigation, Custom widgets, Modal system.
]]

local UI = {}
local Core = _G.KindoCore
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Window = nil
local IsDragging = false
local DragStart = nil
local CurrentTab = "Combat"

-- 1. HELPERS
local function CreateInstance(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

local function CreateLabel(text, props)
    props = props or {}
    return CreateInstance("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Code,
        TextSize = props.Size or 14,
        TextColor3 = props.Color or Core.Theme.Text,
        Size = UDim2.new(props.Width or 1, 0, props.Height or 0, 20),
        Position = UDim2.new(props.X or 0, 0, props.Y or 0, 0)
    })
end

local function CreateFrame(props)
    props = props or {}
    return CreateInstance("Frame", {
        BackgroundColor3 = props.Color or Core.Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(props.Width or 1, 0, props.Height or 1, 0),
        Position = UDim2.new(props.X or 0, 0, props.Y or 0, 0)
    })
end

local function CreateButton(props)
    props = props or {}
    local btn = CreateInstance("TextButton", {
        BackgroundColor3 = props.Color or Core.Theme.Panel,
        BorderSizePixel = 0,
        Text = props.Text or "Button",
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = Core.Theme.Text,
        Size = UDim2.new(props.Width or 1, 0, props.Height or 0, 30),
        Position = UDim2.new(props.X or 0, 0, props.Y or 0, 0),
        AutoButtonColor = false
    })
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Core.Theme.Accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = props.Color or Core.Theme.Panel}):Play()
    end)
    return btn
end

-- 2. WIDGETS
function UI.CreateToggle(parent, config)
    config = config or {}
    local container = CreateFrame({
        Name = "Toggle_" .. (config.Name or "Widget"),
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1
    })
    parent:AddChild(container)
    
    local label = CreateLabel(config.Name or "Toggle")
    label.Position = UDim2.new(0, 0, 0, 5)
    container:AddChild(label)
    
    local box = CreateFrame({
        Name = "ToggleBox",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -45, 0.5, -10),
        Color = Core.Theme.Bg
    })
    container:AddChild(box)
    
    local knob = CreateFrame({
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        Color = Core.Theme.TextDim
    })
    box:AddChild(knob)
    
    local state = { Value = config.Default or false }
    
    local function UpdateVisuals(val)
        if val then
            box.BackgroundColor3 = Core.Theme.Accent
            knob.Position = UDim2.new(0, 22, 0.5, -8)
            knob.BackgroundColor3 = Core.Theme.Bg
        else
            box.BackgroundColor3 = Core.Theme.Bg
            knob.Position = UDim2.new(0, 2, 0.5, -8)
            knob.BackgroundColor3 = Core.Theme.TextDim
        end
    end
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state.Value = not state.Value
            UpdateVisuals(state.Value)
            if config.Callback then
                config.Callback(state.Value)
            end
            Core.State.Settings[config.Name] = state.Value
        end
    end)
    
    UpdateVisuals(state.Value)
    return container, state
end

function UI.CreateSlider(parent, config)
    config = config or {}
    local container = CreateFrame({
        Name = "Slider_" .. (config.Name or "Widget"),
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1
    })
    parent:AddChild(container)
    
    local label = CreateLabel(config.Name or "Slider")
    label.Position = UDim2.new(0, 0, 0, 0)
    container:AddChild(label)
    
    local valueLabel = CreateLabel("0", { Align = Enum.TextXAlignment.Right, Size = 12, Color = Core.Theme.Accent })
    valueLabel.Position = UDim2.new(1, -30, 0, 0)
    valueLabel.Size = UDim2.new(0, 30, 0, 15)
    container:AddChild(valueLabel)
    
    local track = CreateFrame({
        Name = "Track",
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 1, -15),
        Color = Core.Theme.Bg
    })
    container:AddChild(track)
    
    local fill = CreateFrame({
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        Color = Core.Theme.Accent
    })
    track:AddChild(fill)
    
    local state = { Value = config.Default or config.Min }
    
    local function UpdateSlider(value)
        local pct = (value - config.Min) / (config.Max - config.Min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = string.format("%.0f", value)
    end
    
    local dragging = false
    local function UpdateFromMouse(pos)
        local rel = track.AbsolutePosition
        local width = track.AbsoluteSize.X
        local localX = pos.X - rel.X
        local pct = math.clamp(localX / width, 0, 1)
        local newVal = config.Min + (pct * (config.Max - config.Min))
        state.Value = math.floor(newVal + 0.5)
        UpdateSlider(state.Value)
        if config.Callback then
            config.Callback(state.Value)
        end
        Core.State.Settings[config.Name] = state.Value
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateFromMouse(input.Position)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            UpdateFromMouse(input.Position)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UpdateSlider(state.Value)
    return container, state
end

-- 3. MODAL SYSTEM
function UI.ShowModal(title, content)
    local overlay = CreateInstance("ScreenGui", {
        Name = "KindoModal",
        ResetOnSpawn = false
    })
    game:GetService("CoreGui"):WaitForChild("PlayerGui"):AddChild(overlay)
    
    local bg = CreateFrame({
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        Color = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5
    })
    overlay:AddChild(bg)
    
    local panel = CreateFrame({
        Name = "Panel",
        Size = UDim2.new(0, 400, 0, 200),
        Position = UDim2.new(0.5, -200, 0.5, -100),
        Color = Core.Theme.Bg
    })
    overlay:AddChild(panel)
    
    local titleLbl = CreateLabel(title, { Size = 18, Color = Core.Theme.Accent })
    titleLbl.Position = UDim2.new(0.5, -100, 0, 10)
    titleLbl.Size = UDim2.new(0, 200, 0, 30)
    panel:AddChild(titleLbl)
    
    local contentFrame = CreateFrame({
        Name = "Content",
        Size = UDim2.new(1, -20, 1, -60),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1
    })
    panel:AddChild(contentFrame)
    
    return overlay, contentFrame, function()
        overlay:Destroy()
    end
end

-- 4. MAIN WINDOW INITIALIZATION
function UI.Initialize()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("KindoHubUI")
    if existing then existing:Destroy() end

    local screenGui = CreateInstance("ScreenGui", {
        Name = "KindoHubUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    playerGui:AddChild(screenGui)
    
    Window = CreateFrame({
        Name = "MainWindow",
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0, 100, 0, 100),
        Color = Core.Theme.Bg,
        Active = true
    })
    screenGui:AddChild(Window)
    
    local titleBar = CreateFrame({
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 30),
        Color = Core.Theme.Panel
    })
    Window:AddChild(titleBar)
    
    local titleLbl = CreateLabel("KINDO HUB v1.0", { Size = 14, Color = Core.Theme.Accent })
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleBar:AddChild(titleLbl)
    
    local closeBtn = CreateButton({ Text = "X", Color = Core.Theme.Error })
    closeBtn.Position = UDim2.new(1, -30, 0, 2)
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    titleBar:AddChild(closeBtn)
    
    close