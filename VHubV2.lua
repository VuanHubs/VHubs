-- VuaN Hub | Universal Script Hub
-- Version 2.0.8

local lp = game:FindService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

local function notif(str, dur)
    StarterGui:SetCore("SendNotification", {
        Title = "VHub",
        Text = str,
        Duration = dur or 3
    })
end

local PlayerSettings = {
    Speed = 16, SpeedEnabled = false,
    JumpPower = 10, JumpEnabled = false,
    InfiniteJump = false, Noclip = false,
    Fly = false, FlySpeed = 50, AntiAFK = false,
    GodMode = false, AnimSpeed = 1
}

local ESPSettings = {
    Enabled = false, ESPType = "Outline",
    TeamCheck = false, Lines = false, 
    Tracers = false,
    IncludeSelf = false,
    MyTeam = nil
}

local TeleportSettings = { HomePosition = nil }
local WorldSettings = { NoFog = false, Fullbright = false, AntiVoid = false, Xray = false, XrayTransparency = 0.5 }

local FreecamSettings = { Enabled = false, Speed = 1 }
local HitboxSettings = { Enabled = false, Size = 10 }
local HitboxObjects = {}

local viewing = nil
local viewDied = nil
local viewChanged = nil
local spinActive = false
local spinSpeed = 20
local bringActive = false

local SummonSettings = {
    Shape = "Block",
    Size = 4,
    ColorR = 224, ColorG = 58, ColorB = 58,
    Glow = true,
    Anchored = false,
    CanCollide = true,
    EnableLight = true,
    LightBrightness = 2,
    LightRange = 15
}
local SummonedObjects = {}

local CurrentTab = "About"
local FlyConnection, NoclipConnection, AntiAFKConnection, InfiniteJumpConnection, AnimSpeedConnection = nil, nil, nil, nil, nil
local FreecamConnection, FreecamMouseConnection, FreecamMouseEndConnection = nil, nil, nil
local xrayLoop = nil

local ESPObjects = {}
local TracerObjects = {}
local IsMinimized = false
local MinimizedTab = nil
local lastDeathCFrame = nil
local brightLoop = nil
local antiVoidLoop = nil
local godHumanoid = nil
local HomeMarker = nil

local h = Instance.new("ScreenGui")
local Main = Instance.new("ImageLabel")
local Top = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")
local MaximizeBtn = Instance.new("TextButton")
local MinimizeBtn = Instance.new("TextButton")
local LeftMenu = Instance.new("Frame")
local RightContent = Instance.new("Frame")
local MainCorner = Instance.new("UICorner")
local CloseCorner = Instance.new("UICorner")
local MaximizeCorner = Instance.new("UICorner")
local MinimizeCorner = Instance.new("UICorner")
local Glow = Instance.new("ImageLabel")

h.Name = "VHub"
h.Parent = game:GetService("CoreGui")
h.ResetOnSpawn = false

Main.Name = "Main"
Main.Parent = h
Main.Active = true
Main.Draggable = true
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.BackgroundTransparency = 0.1
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -250, 0.3, 0)
Main.Size = UDim2.new(0, 500, 0, 340)

MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

Glow.Name = "Glow"
Glow.Parent = Main
Glow.BackgroundTransparency = 1
Glow.Position = UDim2.new(-0.05, 0, -0.05, 0)
Glow.Size = UDim2.new(1.1, 0, 1.1, 0)
Glow.Image = "rbxassetid://5028857081"
Glow.ImageColor3 = Color3.fromRGB(224, 58, 58)
Glow.ImageTransparency = 0.85
Glow.ZIndex = 0

Top.Name = "Top"
Top.Parent = Main
Top.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Top.BackgroundTransparency = 0
Top.BorderSizePixel = 0
Top.Size = UDim2.new(1, 0, 0, 30)

Title.Name = "Title"
Title.Parent = Top
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(0, 180, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "VHub"
Title.TextColor3 = Color3.fromRGB(224, 58, 58)
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center

CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = Top
CloseBtn.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
CloseBtn.BackgroundTransparency = 0.7
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "x"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function() CloseBtn.BackgroundTransparency = 0.3 end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.BackgroundTransparency = 0.7 end)
CloseBtn.MouseButton1Click:Connect(function()
    if MinimizedTab then MinimizedTab:Destroy(); MinimizedTab = nil end
    h:Destroy()
end)

MaximizeBtn.MouseEnter:Connect(function() MaximizeBtn.BackgroundTransparency = 0.3 end)
MaximizeBtn.MouseLeave:Connect(function() MaximizeBtn.BackgroundTransparency = 0.7 end)
MaximizeBtn.MouseButton1Click:Connect(function()
    if IsMinimized then RestoreGUI() end
end)

MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = Top
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
MinimizeBtn.BackgroundTransparency = 0.7
MinimizeBtn.Position = UDim2.new(1, -55, 0, 5)
MinimizeBtn.Size = UDim2.new(0, 20, 0, 20)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 16
MinimizeCorner.CornerRadius = UDim.new(0, 4)
MinimizeCorner.Parent = MinimizeBtn

MinimizeBtn.MouseEnter:Connect(function() MinimizeBtn.BackgroundTransparency = 0.3 end)
MinimizeBtn.MouseLeave:Connect(function() MinimizeBtn.BackgroundTransparency = 0.7 end)

LeftMenu.Name = "LeftMenu"
LeftMenu.Parent = Main
LeftMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
LeftMenu.BackgroundTransparency = 0.3
LeftMenu.BorderSizePixel = 0
LeftMenu.Position = UDim2.new(0, 0, 0, 30)
LeftMenu.Size = UDim2.new(0, 110, 1, -30)

RightContent.Name = "RightContent"
RightContent.Parent = Main
RightContent.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
RightContent.BackgroundTransparency = 0.05
RightContent.BorderSizePixel = 0
RightContent.Position = UDim2.new(0, 110, 0, 30)
RightContent.Size = UDim2.new(1, -110, 1, -30)
RightContent.ClipsDescendants = true

local function MinimizeGUI()
    if IsMinimized then return end
    Main.Visible = false
    IsMinimized = true
    
    MinimizedTab = Instance.new("TextButton")
    MinimizedTab.Name = "MinimizedTab"
    MinimizedTab.Parent = h
    MinimizedTab.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    MinimizedTab.BackgroundTransparency = 0.3
    MinimizedTab.BorderSizePixel = 0
    MinimizedTab.Size = UDim2.new(0, 40, 0, 40)
    MinimizedTab.Position = UDim2.new(0.25, 0, 1, -45)
    MinimizedTab.Text = "V"
    MinimizedTab.Font = Enum.Font.GothamBold
    MinimizedTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizedTab.TextSize = 20
    MinimizedTab.ZIndex = 10
    MinimizedTab.AutoButtonColor = false
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = MinimizedTab
    
    local isDragging, hasMoved = false, false
    local dragStartPos, startTabPos = nil, nil
    
    MinimizedTab.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true; hasMoved = false
            dragStartPos = input.Position; startTabPos = MinimizedTab.AbsolutePosition
        end
    end)
    
    MinimizedTab.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
            if not hasMoved then RestoreGUI() end
        end
    end)
    
    MinimizedTab.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            hasMoved = true
            local delta = input.Position - dragStartPos
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local newX = math.clamp(startTabPos.X + delta.X, 0, viewportSize.X - 40)
            local newY = math.clamp(startTabPos.Y + delta.Y, 0, viewportSize.Y - 40)
            MinimizedTab.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

function RestoreGUI()
    if not IsMinimized then return end
    Main.Visible = true; IsMinimized = false
    if MinimizedTab then MinimizedTab:Destroy(); MinimizedTab = nil end
end

MinimizeBtn.MouseButton1Click:Connect(function() MinimizeGUI() end)

local MenuButtons = {}
local MenuItems = {"About", "ESP", "Me", "Teleport", "World", "Summon", "Fun", "More"}

for i, item in ipairs(MenuItems) do
    local btn = Instance.new("TextButton")
    btn.Parent = LeftMenu
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.BackgroundTransparency = 0.5
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0.1, 0, 0.02 + ((i-1) * 0.115), 0)
    btn.Size = UDim2.new(0, 90, 0, 28)
    btn.Font = Enum.Font.GothamBold
    btn.Text = item
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextSize = 12
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    local tabName = item
    btn.MouseButton1Click:Connect(function()
        CurrentTab = tabName
        for _, b in pairs(MenuButtons) do
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            b.BackgroundTransparency = 0.5
            b.TextColor3 = Color3.fromRGB(200, 200, 220)
        end
        btn.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
        btn.BackgroundTransparency = 0.2
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        UpdateRightContent()
    end)
    table.insert(MenuButtons, btn)
end

MenuButtons[1].BackgroundColor3 = Color3.fromRGB(224, 58, 58)
MenuButtons[1].BackgroundTransparency = 0.2
MenuButtons[1].TextColor3 = Color3.fromRGB(255, 255, 255)

local function CreateToggle(parent, text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent; frame.BackgroundTransparency = 1; frame.Size = UDim2.new(1, 0, 0, 28)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame; label.BackgroundTransparency = 1; label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.7, 0, 0, 28); label.Font = Enum.Font.Gotham
    label.Text = text; label.TextColor3 = Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggle = Instance.new("TextButton")
    toggle.Parent = frame; toggle.BorderSizePixel = 0; toggle.Position = UDim2.new(1, -45, 0, 4)
    toggle.Size = UDim2.new(0, 40, 0, 20); toggle.Font = Enum.Font.GothamBold
    toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
    toggle.Text = defaultValue and "ON" or "OFF"; toggle.TextColor3 = Color3.fromRGB(255, 255, 255); toggle.TextSize = 10
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4); toggleCorner.Parent = toggle
    
    local state = defaultValue
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
        toggle.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return frame
end

local function CreateStateButton(parent, text, initialState, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent; btn.BorderSizePixel = 0; btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 12
    btn.BackgroundColor3 = initialState and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
    btn.Text = text .. (initialState and " [ON]" or " [OFF]")
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 7); btnCorner.Parent = btn
    
    local state = initialState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
        btn.Text = text .. (state and " [ON]" or " [OFF]")
        callback(state)
    end)
    return btn
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent; frame.BackgroundTransparency = 1; frame.Size = UDim2.new(1, 0, 0, 45)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame; label.BackgroundTransparency = 1; label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.6, 0, 0, 20); label.Font = Enum.Font.Gotham
    label.Text = text; label.TextColor3 = Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame; valueLabel.BackgroundTransparency = 1; valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.Size = UDim2.new(0, 45, 0, 20); valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default); valueLabel.TextColor3 = Color3.fromRGB(224, 58, 58); valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Parent = frame; sliderFrame.BorderSizePixel = 0; sliderFrame.Position = UDim2.new(0, 5, 0, 25)
    sliderFrame.Size = UDim2.new(1, -10, 0, 5); sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3); sliderCorner.Parent = sliderFrame
    
    local fill = Instance.new("Frame")
    fill.Parent = sliderFrame; fill.BorderSizePixel = 0; fill.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3); fillCorner.Parent = fill
    
    local knob = Instance.new("TextButton")
    knob.Parent = sliderFrame; knob.BorderSizePixel = 0; knob.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    knob.Position = UDim2.new((default - min) / (max - min), -7.5, 0, -5)
    knob.Size = UDim2.new(0, 15, 0, 15); knob.Text = ""
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 8); knobCorner.Parent = knob
    
    local dragging = false; local currentValue = default
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = sliderFrame.AbsolutePosition.X
            local sliderWidth = sliderFrame.AbsoluteSize.X
            local t = math.clamp((mousePos.X - sliderPos) / sliderWidth, 0, 1)
            currentValue = min + (max - min) * t
            currentValue = math.floor(currentValue * 10) / 10
            valueLabel.Text = tostring(currentValue)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, -7.5, 0, -5)
            callback(currentValue)
            if text == "Light Brightness" then SummonSettings.LightBrightness = currentValue end
            if text == "Light Range" then SummonSettings.LightRange = currentValue end
            if text == "Size" then SummonSettings.Size = currentValue end
        end
    end)
    return frame
end

local function CreateList(parent, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent; frame.BackgroundTransparency = 1; frame.Size = UDim2.new(1, 0, 0, 38)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame; label.BackgroundTransparency = 1; label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.5, 0, 0, 38); label.Font = Enum.Font.Gotham
    label.Text = text; label.TextColor3 = Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local dropdown = Instance.new("TextButton")
    dropdown.Parent = frame; dropdown.BorderSizePixel = 0; dropdown.Position = UDim2.new(0.55, 0, 0, 7)
    dropdown.Size = UDim2.new(0.4, 0, 0, 24); dropdown.Font = Enum.Font.Gotham
    dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    dropdown.Text = default; dropdown.TextColor3 = Color3.fromRGB(255, 255, 255); dropdown.TextSize = 11
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 5); dropdownCorner.Parent = dropdown
    
    local currentOption = default
    dropdown.MouseButton1Click:Connect(function()
        local currentIdx = 1
        for i, opt in ipairs(options) do
            if opt == currentOption then currentIdx = i; break end
        end
        currentIdx = currentIdx % #options + 1
        currentOption = options[currentIdx]
        dropdown.Text = currentOption
        SummonSettings.Shape = currentOption
        callback(currentOption)
    end)
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent; btn.BorderSizePixel = 0; btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Font = Enum.Font.GothamBold; btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 12
    btn.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 7); btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(224, 58, 58) end)
    return btn
end

local function CreateSmallButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent; btn.BorderSizePixel = 0; btn.Size = UDim2.new(0, 60, 1, 0)
    btn.Font = Enum.Font.GothamBold; btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 11
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5); btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(100, 100, 115) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(80, 80, 95) end)
    return btn
end

local function CreateLabel(parent, text, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent; label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 0, 25)
    label.Font = Enum.Font.GothamBold; label.Text = text
    label.TextColor3 = color or Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left; label.TextWrapped = true
    return label
end

local function CreateTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Parent = parent; box.BorderSizePixel = 0; box.Size = UDim2.new(1, 0, 0, 35)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 45); box.BackgroundTransparency = 0.3
    box.Font = Enum.Font.Gotham; box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(150, 150, 170); box.Text = ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255); box.TextSize = 12
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 7); boxCorner.Parent = box
    return box
end

local function CreateRGBInputs(parent)
    local frame = Instance.new("Frame")
    frame.Name = "RGBFrame"
    frame.Parent = parent; frame.BackgroundTransparency = 1; frame.Size = UDim2.new(1, 0, 0, 40)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame; label.BackgroundTransparency = 1; label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.25, 0, 0, 35); label.Font = Enum.Font.Gotham
    label.Text = "Color (RGB):"; label.TextColor3 = Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local function makeBox(defaultVal, offsetX, isR)
        local box = Instance.new("TextBox")
        box.Parent = frame; box.BorderSizePixel = 0; box.Size = UDim2.new(0, 55, 0, 30)
        box.Position = UDim2.new(0, 90 + offsetX, 0, 2)
        box.BackgroundColor3 = Color3.fromRGB(35, 35, 45); box.BackgroundTransparency = 0.3
        box.Font = Enum.Font.GothamBold; box.Text = tostring(defaultVal)
        box.TextColor3 = isR and Color3.fromRGB(255, 100, 100) or (not isR and offsetX == 60 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 150, 255))
        box.TextSize = 12
        box.ClearTextOnFocus = false
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5); corner.Parent = box
        
        box.FocusLost:Connect(function()
            local val = tonumber(box.Text)
            if val then
                local clamped = math.clamp(math.floor(val), 0, 255)
                box.Text = tostring(clamped)
                if isR then SummonSettings.ColorR = clamped
                elseif offsetX == 60 then SummonSettings.ColorG = clamped
                else SummonSettings.ColorB = clamped end
            else
                box.Text = tostring(defaultVal)
            end
        end)
        return box
    end
    
    makeBox(SummonSettings.ColorR, 0, true)
    makeBox(SummonSettings.ColorG, 60, false)
    makeBox(SummonSettings.ColorB, 120, false)
    
    return frame
end

local function ClearRightContent()
    for _, child in pairs(RightContent:GetChildren()) do
        if not child:IsA("UICorner") then child:Destroy() end
    end
end

local function GetPlayerTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)
end

local function CreateTracer(player)
    if TracerObjects[player] then
        TracerObjects[player]:Destroy()
    end
    
    if not ESPSettings.Tracers then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local tracer = Instance.new("BillboardGui")
    tracer.Name = player.Name.."_Tracer"
    tracer.Adornee = char.HumanoidRootPart
    tracer.Size = UDim2.new(0, 0, 0, 0)
    tracer.StudsOffset = Vector3.new(0, 0, 0)
    tracer.AlwaysOnTop = true
    tracer.Enabled = true
    
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.Parent = tracer
    line.BackgroundColor3 = ESPSettings.TeamCheck and GetPlayerTeamColor(player) or Color3.fromRGB(224, 58, 58)
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0.5, 0, 1, 0)
    line.Size = UDim2.new(0, 2, 0, 100)
    line.AnchorPoint = Vector2.new(0.5, 0)
    
    tracer.Parent = char.HumanoidRootPart
    TracerObjects[player] = tracer
end

local function CreateESP(player)
    if ESPObjects[player] then
        DestroyESP(player)
    end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local objects = {}
    local teamColor = ESPSettings.TeamCheck and GetPlayerTeamColor(player) or Color3.fromRGB(224, 58, 58)
    
    if ESPSettings.ESPType == "Box3D" then
        local box = Instance.new("BoxHandleAdornment")
        box.Size = Vector3.new(3, 5, 3)
        box.Adornee = char
        box.Color3 = teamColor
        box.Transparency = 0.5
        box.AlwaysOnTop = true
        box.ZIndex = 2
        box.Parent = char
        table.insert(objects, box)
        
    elseif ESPSettings.ESPType == "Outline" then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = char
        highlight.FillTransparency = 1
        highlight.OutlineColor = teamColor
        highlight.OutlineTransparency = 0.3
        highlight.Parent = char
        table.insert(objects, highlight)
        
    elseif ESPSettings.ESPType == "Fill" then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = char
        highlight.FillColor = teamColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 1
        highlight.Parent = char
        table.insert(objects, highlight)
    end
    
    if ESPSettings.Lines then
        local line = Instance.new("SelectionBox")
        line.Adornee = char
        line.Color3 = teamColor
        line.LineThickness = 0.05
        line.Transparency = 0.5
        line.Parent = char
        table.insert(objects, line)
    end
    
    ESPObjects[player] = objects
    
    if ESPSettings.Tracers then
        CreateTracer(player)
    end
end

function DestroyESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        ESPObjects[player] = nil
    end
    
    if TracerObjects[player] then
        TracerObjects[player]:Destroy()
        TracerObjects[player] = nil
    end
end

local function UpdateESP()
    for _, player in pairs(game:FindService("Players"):GetPlayers()) do
        if player == lp and not ESPSettings.IncludeSelf then continue end
        
        if ESPSettings.Enabled then
            CreateESP(player)
        else
            DestroyESP(player)
        end
    end
end

game:GetService("Players").PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if ESPSettings.Enabled then
            repeat task.wait(0.1) until char:FindFirstChild("HumanoidRootPart")
            if ESPObjects[player] then
                DestroyESP(player)
            end
            task.wait(0.2)
            CreateESP(player)
        end
    end)
    
    player:GetPropertyChangedSignal("Team"):Connect(function()
        if ESPSettings.Enabled and ESPObjects[player] then
            DestroyESP(player)
            CreateESP(player)
        end
    end)
end)

local function GetPlayerByName(name)
    local found = nil
    local lowerName = name:lower()
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player.Name:lower():sub(1, #lowerName) == lowerName or player.DisplayName:lower():sub(1, #lowerName) == lowerName then
            found = player
            break
        end
    end
    return found
end

local function TeleportToPlayer(targetName)
    local target = GetPlayerByName(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            notif("Teleported to: " .. target.Name, 2)
        else
            notif("Character not found", 2)
        end
    else
        notif("Player not found", 2)
    end
end

local FlingActive = false
local function StartFling(targetName)
    local target = GetPlayerByName(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        FlingActive = true
        notif("Fling activated on: " .. target.Name, 2)
        local thrust = Instance.new('BodyThrust', lp.Character.HumanoidRootPart)
        thrust.Force = Vector3.new(9999, 9999, 9999)
        thrust.Name = "YeetForce"
        
        coroutine.wrap(function()
            while FlingActive and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") do
                lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
                thrust.Location = target.Character.HumanoidRootPart.Position
                RunService.Heartbeat:Wait()
            end
            thrust:Destroy()
            if FlingActive then notif("Fling stopped (Target left)", 2) end
            FlingActive = false
        end)()
    else
        notif("Player not found", 2)
    end
end

local function StopFling()
    FlingActive = false
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local thrust = lp.Character.HumanoidRootPart:FindFirstChild("YeetForce")
        if thrust then thrust:Destroy() end
    end
    notif("Fling stopped", 2)
end

local function StartBring(targetName)
    local target = GetPlayerByName(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        if bringActive then return end
        bringActive = true
        notif("Bringing: " .. target.Name, 2)
        
        coroutine.wrap(function()
            while bringActive and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") do
                local targetRoot = target.Character.HumanoidRootPart
                local myRoot = lp.Character.HumanoidRootPart
                
                targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                
                local hum = target.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Velocity = Vector3.new(0, 0, 0)
                    hum.PlatformStand = true
                end
                
                RunService.Heartbeat:Wait()
            end
            
            if target.Character then
                local hum = target.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
            bringActive = false
            notif("Bring stopped", 2)
        end)()
    else
        notif("Player not found", 2)
    end
end

local function StopBring()
    bringActive = false
    notif("Bring stopped", 2)
end

local function DiedTP()
    if lastDeathCFrame and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = lastDeathCFrame
        notif("Teleported to last death location", 2)
    else
        notif("No death location saved yet", 2)
    end
end

local function GiveBTools()
    for i = 1, 4 do
        local tool = Instance.new("HopperBin")
        tool.BinType = i
        tool.Parent = lp:FindFirstChildOfClass("Backpack")
    end
    notif("BTools added to backpack", 2)
end

local function GiveTPTool()
    local tool = Instance.new("Tool")
    tool.Name = "Teleport Tool"
    tool.RequiresHandle = false
    tool.Parent = lp:FindFirstChildOfClass("Backpack")
    tool.Activated:Connect(function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local hit = lp:GetMouse().Hit
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(hit.X, hit.Y + 3, hit.Z)
        end
    end)
    notif("TP Tool added to backpack", 2)
end

local function ServerHop()
    notif("Server hopping...", 2)
    pcall(function()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
        local body = game:GetService("HttpService"):JSONDecode(req)
        local servers = {}
        if body and body.data then
            for _, v in pairs(body.data) do
                if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
        end
        if #servers > 0 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], lp)
        else
            notif("No servers found, rejoining", 3)
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end
    end)
end

local function UpdateNoFog(state)
    if state then
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then v:Destroy() end
        end
    end
end

local function UpdateFullbright(state)
    if state then
        if not brightLoop then
            brightLoop = RunService.RenderStepped:Connect(function()
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end)
        end
    else
        if brightLoop then
            brightLoop:Disconnect()
            brightLoop = nil
        end
    end
end

local function UpdateAntiVoid(state)
    if state then
        if not antiVoidLoop then
            antiVoidLoop = RunService.Stepped:Connect(function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local root = lp.Character.HumanoidRootPart
                    if root.Position.Y <= -500 then
                        root.Velocity = root.Velocity + Vector3.new(0, 250, 0)
                    end
                end
            end)
        end
    else
        if antiVoidLoop then
            antiVoidLoop:Disconnect()
            antiVoidLoop = nil
        end
    end
end

local function UpdateFly()
    if PlayerSettings.Fly then
        if not FlyConnection and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = lp.Character.HumanoidRootPart
            local bg = Instance.new("BodyGyro")
            local bv = Instance.new("BodyVelocity")
            bg.P = 9e4; bg.Parent = root; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = root.CFrame
            bv.Parent = root; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0, 0, 0)
            
            FlyConnection = RunService.RenderStepped:Connect(function()
                if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
                    FlyConnection:Disconnect(); FlyConnection = nil; return
                end
                lp.Character.Humanoid.PlatformStand = true
                local cam = workspace.CurrentCamera
                local moveDir = Vector3.new()
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, 1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, -1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0, -1, 0) end
                
                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                
                local forward = cam.CFrame.LookVector
                local right = cam.CFrame.RightVector
                local up = cam.CFrame.UpVector
                
                bv.Velocity = (forward * moveDir.Z + right * moveDir.X + up * moveDir.Y) * PlayerSettings.FlySpeed
                bg.CFrame = cam.CFrame
            end)
        end
    else
        if FlyConnection then
            FlyConnection:Disconnect(); FlyConnection = nil
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local root = lp.Character.HumanoidRootPart
                local bg = root:FindFirstChild("BodyGyro")
                local bv = root:FindFirstChild("BodyVelocity")
                if bg then bg:Destroy() end
                if bv then bv:Destroy() end
                lp.Character.Humanoid.PlatformStand = false
            end
        end
    end
end

local function UpdateJumpPower()
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        local hum = lp.Character.Humanoid
        if PlayerSettings.JumpEnabled then
            if hum.UseJumpPower then hum.JumpPower = PlayerSettings.JumpPower
            else hum.JumpHeight = PlayerSettings.JumpPower end
        else
            if hum.UseJumpPower then hum.JumpPower = 50
            else hum.JumpHeight = 50 end
        end
    end
end

local function UpdateAnimSpeed(val)
    PlayerSettings.AnimSpeed = val
    if lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid") or lp.Character:FindFirstChildOfClass("AnimationController")
        if hum then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(val)
            end
            
            if AnimSpeedConnection then AnimSpeedConnection:Disconnect() end
            if val ~= 1 then
                AnimSpeedConnection = hum.AnimationPlayed:Connect(function(track)
                    track:AdjustSpeed(val)
                end)
            end
        end
    end
end

local function RemoveForces()
    if lp.Character then
        for _, v in pairs(lp.Character:GetDescendants()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyThrust") or v:IsA("VectorForce") then
                v:Destroy()
            end
        end
        notif("Forces removed", 2)
    end
end

local function UpdateGodMode(state)
    if state then
        if lp.Character and lp.Character:FindFirstChild("Humanoid") and not godHumanoid then
            local char = lp.Character
            local cam = workspace.CurrentCamera
            local pos = cam.CFrame
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            
            godHumanoid = hum:Clone()
            godHumanoid.Parent = char
            lp.Character = nil
            godHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            godHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            godHumanoid.BreakJointsOnDeath = true
            
            lp.Character = char
            cam.CameraSubject = godHumanoid
            cam.CFrame = pos
            godHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            
            local script = char:FindFirstChild("Animate")
            if script then
                script.Disabled = true
                task.wait()
                script.Disabled = false
            end
            godHumanoid.Health = godHumanoid.MaxHealth
        end
    else
        if godHumanoid then
            godHumanoid:Destroy()
            godHumanoid = nil
            notif("God Mode disabled", 2)
        end
    end
end

local function UpdateXray(state)
    if state then
        if not xrayLoop then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then
                    v.LocalTransparencyModifier = WorldSettings.XrayTransparency
                end
            end
            
            xrayLoop = workspace.DescendantAdded:Connect(function(v)
                if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then
                    v.LocalTransparencyModifier = WorldSettings.XrayTransparency
                end
            end)
        end
    else
        if xrayLoop then
            xrayLoop:Disconnect()
            xrayLoop = nil
        end
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = 0
            end
        end
    end
end

local function UpdateFreecam(state)
    if state then
        if FreecamConnection then FreecamConnection:Disconnect() end
        if FreecamMouseConnection then FreecamMouseConnection:Disconnect() end
        if FreecamMouseEndConnection then FreecamMouseEndConnection:Disconnect() end
        
        local cam = workspace.CurrentCamera
        local cf = cam.CFrame
        local isRMBDown = false
        
        FreecamMouseConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                isRMBDown = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            end
        end)
        
        FreecamMouseEndConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                isRMBDown = false
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)
        
        FreecamConnection = RunService.RenderStepped:Connect(function(dt)
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0, -1, 0) end
            
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            
            local delta = UserInputService:GetMouseDelta()
            if isRMBDown and delta.Magnitude > 0 then
                local rx, ry = -delta.Y * 0.002, -delta.X * 0.002
                cf = cf * CFrame.Angles(rx, ry, 0)
            end
            
            cf = cf + cf:VectorToWorldSpace(moveDir) * (FreecamSettings.Speed * dt * 60)
            cam.CFrame = cf
        end)
        
        cam.CameraType = Enum.CameraType.Scriptable
    else
        if FreecamConnection then FreecamConnection:Disconnect(); FreecamConnection = nil end
        if FreecamMouseConnection then FreecamMouseConnection:Disconnect(); FreecamMouseConnection = nil end
        if FreecamMouseEndConnection then FreecamMouseEndConnection:Disconnect(); FreecamMouseEndConnection = nil end
        
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = lp.Character.Humanoid
        end
    end
end

local function UpdateHitboxes()
    for player, data in pairs(HitboxObjects) do
        if data and data.original then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Size = data.original.size
                root.Transparency = data.original.transparency
                root.Color = data.original.color
                root.CanCollide = data.original.canCollide
            end
        end
    end
    HitboxObjects = {}
    
    if HitboxSettings.Enabled then
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player ~= lp and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    HitboxObjects[player] = {
                        original = {
                            size = root.Size,
                            transparency = root.Transparency,
                            color = root.Color,
                            canCollide = root.CanCollide
                        }
                    }
                    root.Size = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                    root.Transparency = 0.7
                    root.Color = Color3.fromRGB(224, 58, 58)
                    root.CanCollide = false
                end
            end
        end
    end
end

local function StartView(targetName)
    local target = GetPlayerByName(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        if viewDied then viewDied:Disconnect() end
        if viewChanged then viewChanged:Disconnect() end
        
        viewing = target
        workspace.CurrentCamera.CameraSubject = viewing.Character
        notif("Viewing: " .. target.Name, 2)
        
        viewDied = target.CharacterAdded:Connect(function()
            repeat task.wait() until target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            workspace.CurrentCamera.CameraSubject = target.Character
        end)
        
        viewChanged = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
            if viewing and viewing.Character then
                workspace.CurrentCamera.CameraSubject = viewing.Character
            end
        end)
    else
        notif("Player not found", 2)
    end
end

local function StopView()
    if viewing then
        viewing = nil
        notif("View turned off", 2)
    end
    if viewDied then viewDied:Disconnect(); viewDied = nil end
    if viewChanged then viewChanged:Disconnect(); viewChanged = nil end
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        workspace.CurrentCamera.CameraSubject = lp.Character.Humanoid
    end
end

local function UpdateSpin(state)
    spinActive = state
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local root = lp.Character.HumanoidRootPart
        local existingSpin = root:FindFirstChild("Spinning")
        if existingSpin then existingSpin:Destroy() end
        
        if state then
            local Spin = Instance.new("BodyAngularVelocity")
            Spin.Name = "Spinning"
            Spin.Parent = root
            Spin.MaxTorque = Vector3.new(0, math.huge, 0)
            Spin.AngularVelocity = Vector3.new(0, spinSpeed, 0)
            notif("Spin enabled", 2)
        else
            notif("Spin disabled", 2)
        end
    end
end

local function ExecuteSummon()
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local color = Color3.fromRGB(SummonSettings.ColorR, SummonSettings.ColorG, SummonSettings.ColorB)
    
    local obj = Instance.new("Part")
    
    if SummonSettings.Shape == "Block" then obj.Shape = Enum.PartType.Block
    elseif SummonSettings.Shape == "Sphere" then obj.Shape = Enum.PartType.Ball
    elseif SummonSettings.Shape == "Wedge" then obj.Shape = Enum.PartType.Wedge
    elseif SummonSettings.Shape == "Cylinder" then obj.Shape = Enum.PartType.Cylinder
    end

    obj.Size = Vector3.new(SummonSettings.Size, SummonSettings.Size, SummonSettings.Size)
    obj.Position = char.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
    obj.Anchored = SummonSettings.Anchored
    obj.CanCollide = SummonSettings.CanCollide
    obj.Color = color
    obj.BrickColor = BrickColor.new(color)
    obj.Material = SummonSettings.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    
    obj.Parent = game.Workspace
    table.insert(SummonedObjects, obj)

    if SummonSettings.EnableLight then
        local light = Instance.new("PointLight", obj)
        light.Color = color
        light.Brightness = SummonSettings.LightBrightness
        light.Range = SummonSettings.LightRange
    end

    notif("Object summoned successfully!", 2)
end

local function ClearAllSummoned()
    local count = 0
    for _, obj in pairs(SummonedObjects) do
        if obj and obj.Parent then 
            obj:Destroy() 
            count = count + 1
        end
    end
    SummonedObjects = {}
    notif("Cleared " .. count .. " summoned objects", 2)
end

local function CreateHomeMarker(position)
    if HomeMarker then
        HomeMarker:Destroy()
        HomeMarker = nil
    end
    
    if not position then return end
    
    HomeMarker = Instance.new("BillboardGui")
    HomeMarker.Name = "HomeMarker"
    HomeMarker.AlwaysOnTop = true
    HomeMarker.Size = UDim2.new(0, 100, 0, 40)
    HomeMarker.StudsOffset = Vector3.new(0, 3, 0)
    HomeMarker.Enabled = true
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = HomeMarker
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = "Home"
    textLabel.TextColor3 = Color3.fromRGB(224, 58, 58)
    textLabel.TextSize = 18
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    local markerPart = Instance.new("Part")
    markerPart.Name = "HomeMarkerPart"
    markerPart.Anchored = true
    markerPart.CanCollide = false
    markerPart.Transparency = 1
    markerPart.Size = Vector3.new(1, 1, 1)
    markerPart.Position = position.Position
    markerPart.Parent = workspace
    
    HomeMarker.Adornee = markerPart
    HomeMarker.Parent = markerPart
    
    notif("Home marker placed in world!", 2)
end

function UpdateRightContent()
    ClearRightContent()
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = RightContent
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Position = UDim2.new(0.05, 0, 0, 8)
    scrollFrame.Size = UDim2.new(0.9, 0, 1, -16)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageTransparency = 0.7
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    if CurrentTab == "About" then
        local titleLabel = CreateLabel(scrollFrame, "VHub | VuaN HUB", Color3.fromRGB(224, 58, 58))
        titleLabel.TextSize = 18; titleLabel.Font = Enum.Font.GothamBlack
        
        local versionLabel = CreateLabel(scrollFrame, "Version 2.0.8", Color3.fromRGB(150, 150, 170))
        versionLabel.TextSize = 11; versionLabel.Font = Enum.Font.Gotham
        
        local changeLabel = CreateLabel(scrollFrame, "• Added visual 'Home' waypoint marker in world", Color3.fromRGB(180, 180, 200))
        changeLabel.TextSize = 10; changeLabel.Font = Enum.Font.Gotham
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(150, 150, 170))
        
        local aboutHeader = CreateLabel(scrollFrame, "About:", Color3.fromRGB(220, 220, 235))
        aboutHeader.TextSize = 13; aboutHeader.Font = Enum.Font.GothamBold
        
        local aboutText = CreateLabel(scrollFrame, "VHub is a universal script hub designed for various Roblox games", Color3.fromRGB(200, 200, 215))
        aboutText.TextSize = 11; aboutText.Font = Enum.Font.Gotham; aboutText.TextWrapped = true; aboutText.Size = UDim2.new(1, 0, 0, 60)
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(150, 150, 170))
        
        local featuresHeader = CreateLabel(scrollFrame, "Features:", Color3.fromRGB(220, 220, 235))
        featuresHeader.TextSize = 13; featuresHeader.Font = Enum.Font.GothamBold
        
        local featuresList = {"ESP System", "Player Mods", "Freecam & Hitbox Expander", "Xray Vision", "Advanced Summon Creator", "Fling, Spin & Spectate", "Server Hop & Console"}
        for _, feature in ipairs(featuresList) do
            local fLabel = CreateLabel(scrollFrame, "  > " .. feature, Color3.fromRGB(180, 180, 200))
            fLabel.TextSize = 11; fLabel.Font = Enum.Font.Gotham
        end
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(150, 150, 170))
        CreateButton(scrollFrame, "Copy Hub Link", function() notif("Link copied to clipboard!", 2) end)
        
    elseif CurrentTab == "ESP" then
        CreateToggle(scrollFrame, "ESP Enabled", ESPSettings.Enabled, function(val) ESPSettings.Enabled = val; UpdateESP() end)
        CreateList(scrollFrame, "ESP Type", {"Box3D", "Outline", "Fill"}, ESPSettings.ESPType, function(val)
            ESPSettings.ESPType = val
            if ESPSettings.Enabled then UpdateESP() end
        end)
        CreateToggle(scrollFrame, "Team Check", ESPSettings.TeamCheck, function(val) ESPSettings.TeamCheck = val; if ESPSettings.Enabled then UpdateESP() end end)
        CreateToggle(scrollFrame, "Lines (Selection)", ESPSettings.Lines, function(val) ESPSettings.Lines = val; if ESPSettings.Enabled then UpdateESP() end end)
        CreateToggle(scrollFrame, "Tracers", ESPSettings.Tracers, function(val) ESPSettings.Tracers = val; UpdateESP() end)
        CreateToggle(scrollFrame, "Include Self", ESPSettings.IncludeSelf, function(val) 
            ESPSettings.IncludeSelf = val
            if ESPSettings.Enabled then UpdateESP() end
        end)
        
    elseif CurrentTab == "Me" then
        local speedFrame = Instance.new("Frame")
        speedFrame.Parent = scrollFrame; speedFrame.BackgroundTransparency = 1; speedFrame.Size = UDim2.new(1, 0, 0, 30)
        
        local speedToggle = CreateToggle(speedFrame, "Speed Hacks", PlayerSettings.SpeedEnabled, function(val)
            PlayerSettings.SpeedEnabled = val
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val and PlayerSettings.Speed or 16
            end
        end)
        speedToggle.Size = UDim2.new(0.75, 0, 1, 0)
        
        local speedReset = CreateSmallButton(speedFrame, "Reset", function()
            PlayerSettings.Speed = 16
            if PlayerSettings.SpeedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = 16
            end
            notif("Speed reset to 16", 2)
        end)
        speedReset.Position = UDim2.new(0.8, 0, 0, 0)
        
        CreateSlider(scrollFrame, "Speed Value", 16, 200, PlayerSettings.Speed, function(val)
            PlayerSettings.Speed = val
            if PlayerSettings.SpeedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val
            end
        end)
        
        local jumpFrame = Instance.new("Frame")
        jumpFrame.Parent = scrollFrame; jumpFrame.BackgroundTransparency = 1; jumpFrame.Size = UDim2.new(1, 0, 0, 30)
        
        local jumpToggle = CreateToggle(jumpFrame, "JumpPower Hacks", PlayerSettings.JumpEnabled, function(val)
            PlayerSettings.JumpEnabled = val
            UpdateJumpPower()
        end)
        jumpToggle.Size = UDim2.new(0.75, 0, 1, 0)
        
        local jumpReset = CreateSmallButton(jumpFrame, "Reset", function()
            PlayerSettings.JumpPower = 50
            if PlayerSettings.JumpEnabled then UpdateJumpPower() end
            notif("Jump Power reset to 50", 2)
        end)
        jumpReset.Position = UDim2.new(0.8, 0, 0, 0)
        
        CreateSlider(scrollFrame, "Jump Value", 0, 200, PlayerSettings.JumpPower, function(val)
            PlayerSettings.JumpPower = val
            if PlayerSettings.JumpEnabled then UpdateJumpPower() end
        end)
        
        CreateToggle(scrollFrame, "Infinite Jump", PlayerSettings.InfiniteJump, function(val)
            PlayerSettings.InfiniteJump = val
            if val then
                InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect(); InfiniteJumpConnection = nil end
            end
        end)
        
        CreateToggle(scrollFrame, "Noclip", PlayerSettings.Noclip, function(val)
            PlayerSettings.Noclip = val
            if val then
                NoclipConnection = RunService.Stepped:Connect(function()
                    if lp.Character then
                        for _, part in pairs(lp.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            else
                if NoclipConnection then
                    NoclipConnection:Disconnect(); NoclipConnection = nil
                    if lp.Character then
                        for _, part in pairs(lp.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = true end
                        end
                    end
                end
            end
        end)
        
        CreateToggle(scrollFrame, "Fly Mode", PlayerSettings.Fly, function(val)
            PlayerSettings.Fly = val
            UpdateFly()
        end)
        CreateSlider(scrollFrame, "Fly Speed", 20, 200, PlayerSettings.FlySpeed, function(val)
            PlayerSettings.FlySpeed = val
        end)

        CreateToggle(scrollFrame, "God Mode", PlayerSettings.GodMode, function(val)
            PlayerSettings.GodMode = val
            UpdateGodMode(val)
        end)
        
        CreateSlider(scrollFrame, "Animation Speed", 0.1, 5, PlayerSettings.AnimSpeed, function(val)
            UpdateAnimSpeed(val)
        end)

        CreateToggle(scrollFrame, "Freecam (PC)", FreecamSettings.Enabled, function(val)
            FreecamSettings.Enabled = val
            UpdateFreecam(val)
        end)
        CreateSlider(scrollFrame, "Freecam Speed", 0.5, 10, FreecamSettings.Speed, function(val)
            FreecamSettings.Speed = val
        end)

        CreateToggle(scrollFrame, "Hitbox Expander", HitboxSettings.Enabled, function(val)
            HitboxSettings.Enabled = val
            UpdateHitboxes()
        end)
        CreateSlider(scrollFrame, "Hitbox Size", 5, 25, HitboxSettings.Size, function(val)
            HitboxSettings.Size = val
            if HitboxSettings.Enabled then UpdateHitboxes() end
        end)

        CreateButton(scrollFrame, "Remove Forces (Anti-Fling)", RemoveForces)
        
        CreateToggle(scrollFrame, "Anti-AFK", PlayerSettings.AntiAFK, function(val)
            PlayerSettings.AntiAFK = val
            if val then
                AntiAFKConnection = RunService.RenderStepped:Connect(function()
                    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end)
            else
                if AntiAFKConnection then AntiAFKConnection:Disconnect(); AntiAFKConnection = nil end
            end
        end)
        
    elseif CurrentTab == "Teleport" then
        local tpHeader = CreateLabel(scrollFrame, "Teleport to Player", Color3.fromRGB(224, 58, 58))
        tpHeader.TextSize = 14; tpHeader.Font = Enum.Font.GothamBlack
        
        local targetBox = CreateTextBox(scrollFrame, "Enter player nickname...")
        CreateButton(scrollFrame, "Teleport", function()
            if targetBox.Text ~= "" then TeleportToPlayer(targetBox.Text) else notif("Enter a player name", 2) end
        end)
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(150, 150, 170))
        
        local homeHeader = CreateLabel(scrollFrame, "Waypoints", Color3.fromRGB(224, 58, 58))
        homeHeader.TextSize = 14; homeHeader.Font = Enum.Font.GothamBlack
        
        local homeFrame = Instance.new("Frame")
        homeFrame.Parent = scrollFrame; homeFrame.BackgroundTransparency = 1; homeFrame.Size = UDim2.new(1, 0, 0, 35)
        
        local homeLayout = Instance.new("UIListLayout")
        homeLayout.Parent = homeFrame; homeLayout.FillDirection = Enum.FillDirection.Horizontal
        homeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        homeLayout.VerticalAlignment = Enum.VerticalAlignment.Center; homeLayout.Padding = UDim.new(0, 10)
        
        local saveBtn = CreateButton(homeFrame, "Home", function()
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                TeleportSettings.HomePosition = lp.Character.HumanoidRootPart.CFrame
                CreateHomeMarker(TeleportSettings.HomePosition)
                notif("Home position saved with marker!", 2)
            end
        end)
        saveBtn.Size = UDim2.new(0.45, 0, 0, 32)
        
        local homeBtn = CreateButton(homeFrame, "Go Home", function()
            if TeleportSettings.HomePosition and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = TeleportSettings.HomePosition
                notif("Teleported to home!", 2)
            else
                notif("No home saved - save first", 3)
            end
        end)
        homeBtn.Size = UDim2.new(0.45, 0, 0, 32)

        CreateButton(scrollFrame, "Flashback (DiedTP)", DiedTP)
        
    elseif CurrentTab == "World" then
        local worldHeader = CreateLabel(scrollFrame, "World Modifications", Color3.fromRGB(224, 58, 58))
        worldHeader.TextSize = 14; worldHeader.Font = Enum.Font.GothamBlack
        
        CreateStateButton(scrollFrame, "No Fog", WorldSettings.NoFog, function(val)
            WorldSettings.NoFog = val
            UpdateNoFog(val)
        end)
        
        CreateStateButton(scrollFrame, "Fullbright", WorldSettings.Fullbright, function(val)
            WorldSettings.Fullbright = val
            UpdateFullbright(val)
        end)

        CreateToggle(scrollFrame, "Anti Void", WorldSettings.AntiVoid, function(val)
            WorldSettings.AntiVoid = val
            UpdateAntiVoid(val)
        end)

        CreateToggle(scrollFrame, "Xray", WorldSettings.Xray, function(val)
            WorldSettings.Xray = val
            UpdateXray(val)
        end)

        CreateSlider(scrollFrame, "Xray Transparency", 0, 1, WorldSettings.XrayTransparency, function(val)
            WorldSettings.XrayTransparency = val
            if WorldSettings.Xray then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then
                        v.LocalTransparencyModifier = val
                    end
                end
            end
        end)

        CreateSlider(scrollFrame, "Clock Time (Day/Night)", 0, 24, Lighting.ClockTime, function(val)
            Lighting.ClockTime = val
        end)

        CreateButton(scrollFrame, "Remove Terrain", function()
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain:Clear()
                notif("Terrain removed", 2)
            end
        end)
        
    elseif CurrentTab == "Summon" then
        local headerLabel = CreateLabel(scrollFrame, "SUMMON CREATOR", Color3.fromRGB(224, 58, 58))
        headerLabel.TextSize = 14; headerLabel.Font = Enum.Font.GothamBlack
        
        CreateButton(scrollFrame, "SUMMON OBJECT", ExecuteSummon)
        
        CreateList(scrollFrame, "Shape", {"Block", "Sphere", "Wedge", "Cylinder"}, SummonSettings.Shape, function(val)
            SummonSettings.Shape = val
        end)
        
        CreateSlider(scrollFrame, "Size", 1, 20, SummonSettings.Size, function(val)
            SummonSettings.Size = val
        end)
        
        CreateRGBInputs(scrollFrame)
        
        CreateLabel(scrollFrame, "Appearance & Physics", Color3.fromRGB(180, 180, 200))
        
        CreateToggle(scrollFrame, "Glow (Neon)", SummonSettings.Glow, function(val) SummonSettings.Glow = val end)
        CreateToggle(scrollFrame, "Anchored", SummonSettings.Anchored, function(val) SummonSettings.Anchored = val end)
        CreateToggle(scrollFrame, "Can Collide", SummonSettings.CanCollide, function(val) SummonSettings.CanCollide = val end)
        
        CreateLabel(scrollFrame, "Lighting", Color3.fromRGB(180, 180, 200))
        
        CreateToggle(scrollFrame, "Enable PointLight", SummonSettings.EnableLight, function(val) SummonSettings.EnableLight = val end)
        CreateSlider(scrollFrame, "Light Brightness", 0, 5, SummonSettings.LightBrightness, function(val) SummonSettings.LightBrightness = val end)
        CreateSlider(scrollFrame, "Light Range", 5, 30, SummonSettings.LightRange, function(val) SummonSettings.LightRange = val end)
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(150, 150, 170))
        
        CreateButton(scrollFrame, "Clear All Summoned", ClearAllSummoned)
        
    elseif CurrentTab == "Fun" then
        local funHeader = CreateLabel(scrollFrame, "Fun Functions", Color3.fromRGB(224, 58, 58))
        funHeader.TextSize = 14; funHeader.Font = Enum.Font.GothamBlack
        
        local targetBox = CreateTextBox(scrollFrame, "Enter player nickname...")
        
        local actionFrame1 = Instance.new("Frame")
        actionFrame1.Parent = scrollFrame; actionFrame1.BackgroundTransparency = 1; actionFrame1.Size = UDim2.new(1, 0, 0, 35)
        local actionLayout1 = Instance.new("UIListLayout")
        actionLayout1.Parent = actionFrame1; actionLayout1.FillDirection = Enum.FillDirection.Horizontal
        actionLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
        actionLayout1.VerticalAlignment = Enum.VerticalAlignment.Center; actionLayout1.Padding = UDim.new(0, 10)
        
        local flingBtn = CreateButton(actionFrame1, "Fling", function()
            if targetBox.Text ~= "" then StartFling(targetBox.Text) else notif("Enter a player name", 2) end
        end)
        flingBtn.Size = UDim2.new(0.48, 0, 0, 32)
        
        local stopFlingBtn = CreateButton(actionFrame1, "Stop Fling", StopFling)
        stopFlingBtn.Size = UDim2.new(0.48, 0, 0, 32)
        
        local actionFrame2 = Instance.new("Frame")
        actionFrame2.Parent = scrollFrame; actionFrame2.BackgroundTransparency = 1; actionFrame2.Size = UDim2.new(1, 0, 0, 35)
        local actionLayout2 = Instance.new("UIListLayout")
        actionLayout2.Parent = actionFrame2; actionLayout2.FillDirection = Enum.FillDirection.Horizontal
        actionLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
        actionLayout2.VerticalAlignment = Enum.VerticalAlignment.Center; actionLayout2.Padding = UDim.new(0, 10)
        
        local freezeBtn = CreateButton(actionFrame2, "Freeze", function()
            local target = GetPlayerByName(targetBox.Text)
            if target and target.Character then
                for _, part in pairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = true end
                end
                notif("Froze: " .. target.Name, 2)
            else
                notif("Player not found", 2)
            end
        end)
        freezeBtn.Size = UDim2.new(0.48, 0, 0, 32)
        
        local thawBtn = CreateButton(actionFrame2, "Thaw", function()
            local target = GetPlayerByName(targetBox.Text)
            if target and target.Character then
                for _, part in pairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = false end
                end
                notif("Thawed: " .. target.Name, 2)
            else
                notif("Player not found", 2)
            end
        end)
        thawBtn.Size = UDim2.new(0.48, 0, 0, 32)

        CreateLabel(scrollFrame, "", Color3.fromRGB(150, 150, 170))

        local actionFrame3 = Instance.new("Frame")
        actionFrame3.Parent = scrollFrame; actionFrame3.BackgroundTransparency = 1; actionFrame3.Size = UDim2.new(1, 0, 0, 35)
        local actionLayout3 = Instance.new("UIListLayout")
        actionLayout3.Parent = actionFrame3; actionLayout3.FillDirection = Enum.FillDirection.Horizontal
        actionLayout3.HorizontalAlignment = Enum.HorizontalAlignment.Center
        actionLayout3.VerticalAlignment = Enum.VerticalAlignment.Center; actionLayout3.Padding = UDim.new(0, 10)
        
        local viewBtn = CreateButton(actionFrame3, "View", function()
            if targetBox.Text ~= "" then StartView(targetBox.Text) else notif("Enter a player name", 2) end
        end)
        viewBtn.Size = UDim2.new(0.48, 0, 0, 32)
        
        local unviewBtn = CreateButton(actionFrame3, "Unview", StopView)
        unviewBtn.Size = UDim2.new(0.48, 0, 0, 32)

        local actionFrame4 = Instance.new("Frame")
        actionFrame4.Parent = scrollFrame; actionFrame4.BackgroundTransparency = 1; actionFrame4.Size = UDim2.new(1, 0, 0, 35)
        local actionLayout4 = Instance.new("UIListLayout")
        actionLayout4.Parent = actionFrame4; actionLayout4.FillDirection = Enum.FillDirection.Horizontal
        actionLayout4.HorizontalAlignment = Enum.HorizontalAlignment.Center
        actionLayout4.VerticalAlignment = Enum.VerticalAlignment.Center; actionLayout4.Padding = UDim.new(0, 10)
        
        local bringBtn = CreateButton(actionFrame4, "Bring", function()
            if targetBox.Text ~= "" then StartBring(targetBox.Text) else notif("Enter a player name", 2) end
        end)
        bringBtn.Size = UDim2.new(0.48, 0, 0, 32)
        
        local stopBringBtn = CreateButton(actionFrame4, "Stop Bring", StopBring)
        stopBringBtn.Size = UDim2.new(0.48, 0, 0, 32)

        CreateButton(scrollFrame, "Jerk (Tool + Anim)", function()
            local humanoid = lp.Character:FindFirstChildWhichIsA("Humanoid")
            local backpack = lp:FindFirstChildWhichIsA("Backpack")
            if not humanoid or not backpack then return end
            
            for _, child in pairs(backpack:GetChildren()) do
                if child.Name == "Jerk Off" then child:Destroy() end
            end

            local tool = Instance.new("Tool")
            tool.Name = "Jerk Off"
            tool.ToolTip = "in the stripped club. straight up \"jorking it\"."
            tool.RequiresHandle = false
            tool.Parent = backpack

            local jorkin = false
            local track = nil

            local function stopTomfoolery()
                jorkin = false
                if track then track:Stop(); track = nil end
            end

            tool.Equipped:Connect(function() jorkin = true end)
            tool.Unequipped:Connect(stopTomfoolery)
            humanoid.Died:Connect(stopTomfoolery)

            task.spawn(function()
                while task.wait() do
                    if not jorkin or not lp.Character then break end
                    local isR15 = lp.Character:FindFirstChildOfClass('Humanoid').RigType == Enum.HumanoidRigType.R15
                    if not track then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                        track = humanoid:LoadAnimation(anim)
                    end
                    track:Play()
                    track:AdjustSpeed(isR15 and 0.7 or 0.65)
                    track.TimePosition = 0.6
                    task.wait(0.1)
                    while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
                    if track then track:Stop(); track = nil end
                end
            end)
            notif("Jerk tool added to backpack. Equip it!", 2)
        end)

        CreateToggle(scrollFrame, "Spin Character", spinActive, function(val)
            spinActive = val
            UpdateSpin(val)
        end)
        
        CreateSlider(scrollFrame, "Spin Speed", 1, 300, spinSpeed, function(val)
            spinSpeed = val
            if spinActive and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local root = lp.Character.HumanoidRootPart
                local spin = root:FindFirstChild("Spinning")
                if spin then
                    spin.AngularVelocity = Vector3.new(0, spinSpeed, 0)
                end
            end
        end)
        
    elseif CurrentTab == "More" then
        local moreHeader = CreateLabel(scrollFrame, "Utilities", Color3.fromRGB(224, 58, 58))
        moreHeader.TextSize = 14; moreHeader.Font = Enum.Font.GothamBlack
        
        CreateButton(scrollFrame, "Server Hop", ServerHop)
        CreateButton(scrollFrame, "Rejoin", function()
            notif("Rejoining...", 2)
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end)
        CreateButton(scrollFrame, "Open Console", function()
            StarterGui:SetCore("DevConsoleVisible", true)
        end)
        CreateButton(scrollFrame, "Give BTools", GiveBTools)
        CreateButton(scrollFrame, "Give TP Tool", GiveTPTool)
        
        local infoLabel = CreateLabel(scrollFrame, "More scripts can be added here.\nContact developer for custom scripts.", Color3.fromRGB(150, 150, 170))
        infoLabel.Size = UDim2.new(1, 0, 0, 45)
    end
end

Main.Position = UDim2.new(0.5, -250, -0.5, 0)
Main:TweenPosition(UDim2.new(0.5, -250, 0.3, 0), "Out", "Quad", 0.5, true)

notif("VHub loaded successfully!", 3)
UpdateRightContent()

if queue_on_teleport then
    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/VuaN_Hub.lua"))()]])
    notif("Auto-Inject", "KeepIY enabled! Script will auto-load on next server.")
end

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    
    if FreecamSettings.Enabled then
        FreecamSettings.Enabled = false
        UpdateFreecam(false)
        notif("Freecam disabled on respawn", 2)
    end
    
    if viewing then
        StopView()
    end
    
    if PlayerSettings.SpeedEnabled and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = PlayerSettings.Speed end
    UpdateJumpPower()
    UpdateFly()
    if PlayerSettings.GodMode then UpdateGodMode(true) end
    if PlayerSettings.AnimSpeed ~= 1 then UpdateAnimSpeed(PlayerSettings.AnimSpeed) end
    if HitboxSettings.Enabled then UpdateHitboxes() end
    
    char:WaitForChild("Humanoid").Died:Connect(function()
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then lastDeathCFrame = root.CFrame end
    end)
end)

game:GetService("Players").PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if HitboxSettings.Enabled then UpdateHitboxes() end
    end)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    if HitboxObjects[player] then
        HitboxObjects[player] = nil
    end
    if viewing == player then
        StopView()
    end
end)

UpdateESP()
