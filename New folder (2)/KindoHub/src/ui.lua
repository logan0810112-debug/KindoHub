--[[
  UI MODULE
  Implements the Cyberpunk-themed interface using native Roblox APIs.
  Features: Draggable window, Tabbed navigation, Custom widgets, Modal system.
]]

local UI = {}
local Core = require(script:WaitForChild("core.lua"))
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- 1. THEME CONFIGURATION
local Theme = Core.Theme
local Font = Enum.Font.Code

-- 2. UI STATE
local Window = nil
local IsDragging = false
local DragInput = nil
local DragStart = nil
local WindowPos = Vector2.new(100, 100)
local CurrentTab = "Combat"
local ActiveWidgets = {} -- Stores references to widgets for state updates

-- 3. HELPERS
local function CreateInstance(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

local function CreateLabel(text, props)
    props = props or {}
    local lbl = CreateInstance("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Font = Font,
        TextSize = props.Size or 14,
        TextColor3 = props.Color or Theme.Text,
        TextXAlignment = props.Align or Enum.TextXAlignment.Left,
        Size = UDim2.new(props.Width or 1, props.Height or 0, 0, 20),
        Position = UDim2.new(props.X or 0, 0, props.Y or 0, 0)
    })
    return lbl
end

local function CreateFrame(props)
    props = props or {}
    return CreateInstance("Frame", {
        BackgroundColor3 = props.Color or Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(props.Width or 1, 0, props.Height or 1, 0),
        Position = UDim2.new(props.X or 0, 0, props.Y or 0, 0),
        Name = props.Name or "Frame"
    })
end

local function CreateButton(props)
    props = props or {}
    local btn = CreateInstance("TextButton", {
        BackgroundColor3 = props.Color or Theme.Panel,
        BorderSizePixel = 0,
        Text = props.Text or "Button",
        Font = Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        Size = UDim2.new(props.Width or 1, 0, props.Height or 0, 30),
        Position = UDim2.new(props.X or 0, 0, props.Y or 0, 0),
        AutoButtonColor = false
    })
    -- Hover Effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = props.Color or Theme.Panel}):Play()
    end)
    return btn
end

-- 4. WIDGET FACTORIES
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
        Color = Theme.Bg
    })
    container:AddChild(box)
    
    local knob = CreateFrame({
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        Color = Theme.TextDim
    })
    box:AddChild(knob)
    
    local state = { Value = config.Default or false }
    
    local function UpdateVisuals(val)
        if val then
            box.BackgroundColor3 = Theme.Accent
            knob.Position = UDim2.new(0, 22, 0.5, -8)
            knob.BackgroundColor3 = Theme.Bg
        else
            box.BackgroundColor3 = Theme.Bg
            knob.Position = UDim2.new(0, 2, 0.5, -8)
            knob.BackgroundColor3 = Theme.TextDim
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
    
    local valueLabel = CreateLabel("0", { Align = Enum.TextXAlignment.Right, Size = 12, Color = Theme.Accent })
    valueLabel.Position = UDim2.new(1, -30, 0, 0)
    valueLabel.Size = UDim2.new(0, 30, 0, 15)
    container:AddChild(valueLabel)
    
    local track = CreateFrame({
        Name = "Track",
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 1, -15),
        Color = Theme.Bg
    })
    container:AddChild(track)
    
    local fill = CreateFrame({
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        Color = Theme.Accent
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

-- 5. MODAL SYSTEM
function UI.ShowModal(title, content)
    local overlay = CreateInstance("ScreenGui", {
        Name = "KindoModal",
        ResetOnSpawn = false
    })
    game.CoreGui:WaitForChild("PlayerGui"):AddChild(overlay)
    
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
        Color = Theme.Bg
    })
    overlay:AddChild(panel)
    
    local titleLbl = CreateLabel(title, { Size = 18, Color = Theme.Accent })
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

-- 6. MAIN WINDOW INITIALIZATION
function UI.Initialize()
    -- Clean up existing UI
    local existing = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("KindoHubUI")
    if existing then existing:Destroy() end

    local screenGui = CreateInstance("ScreenGui", {
        Name = "KindoHubUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    game.CoreGui:WaitForChild("PlayerGui"):AddChild(screenGui)
    
    -- Main Window
    Window = CreateFrame({
        Name = "MainWindow",
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0, WindowPos.X, 0, WindowPos.Y),
        Color = Theme.Bg,
        Active = true
    })
    screenGui:AddChild(Window)
    
    -- Title Bar
    local titleBar = CreateFrame({
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 30),
        Color = Theme.Panel
    })
    Window:AddChild(titleBar)
    
    local titleLbl = CreateLabel("KINDO HUB v1.0", { Size = 14, Color = Theme.Accent })
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleBar:AddChild(titleLbl)
    
    local closeBtn = CreateButton({ Text = "X", Width = 0, Height = 0, Size = 25, X = 1, Color = Theme.Error })
    closeBtn.Position = UDim2.new(1, -30, 0, 2)
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    titleBar:AddChild(closeBtn)
    
    closeBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)
    
    -- Drag Logic
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsDragging = true
            DragInput = input
            DragStart = input.Position - Window.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            Window.Position = UDim2.new(0, input.Position.X - DragStart.X, 0, input.Position.Y - DragStart.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsDragging = false
        end
    end)
    
    -- Tab Bar
    local tabBar = CreateFrame({
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.new(0, 0, 0, 30),
        Color = Theme.Bg
    })
    Window:AddChild(tabBar)
    
    local tabs = {"Combat", "Visuals", "Movement", "Utility", "Settings"}
    for i, tabName in ipairs(tabs) do
        local tabBtn = CreateButton({
            Text = tabName,
            Width = 0,
            Height = 1,
            Size = 30,
            X = (i - 1) * 0.2,
            Color = Theme.Bg
        })
        tabBtn.Size = UDim2.new(0.2, 0, 1, 0)
        tabBar:AddChild(tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            -- Highlight active tab
            for _, child in ipairs(tabBar:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = (child == tabBtn) and Theme.Accent or Theme.Bg
                end
            end
            UI.SwitchTab(tabName)
        end)
    end
    
    -- Content Area
    local contentArea = CreateFrame({
        Name = "ContentArea",
        Size = UDim2.new(1, -20, 1, -60),
        Position = UDim2.new(0, 10, 0, 65),
        BackgroundTransparency = 1
    })
    Window:AddChild(contentArea)
    
    UI.SwitchTab = function(tabName)
        -- Clear content
        for _, child in ipairs(contentArea:GetChildren()) do
            child:Destroy()
        end
        
        local scroll = CreateInstance("ScrollingFrame", {
            CanvasSize = UDim2.new(0, 0, 0, 200),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })
        contentArea:AddChild(scroll)
        
        local layout = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        scroll:AddChild(layout)
        
        -- Populate based on tab
        if tabName == "Settings" then
            UI.CreateToggle(scroll, {
                Name = "GUI Toggle (Right Shift)",
                Default = true,
                Callback = function(val)
                    -- Handle global toggle binding
                end
            })
            UI.CreateSlider(scroll, {
                Name = "FOV Radius",
                Min = 50,
                Max = 300,
                Default = 150,
                Callback = function(val)
                    Core.State.Settings.FOV = val
                end
            })
        else
            -- Placeholder for other tabs
            UI.CreateLabel(scroll, "Features for " .. tabName .. " will appear here.")
        end
    end
    
    -- Initial Tab
    UI.SwitchTab("Settings")
    
    return screenGui
end

return UI