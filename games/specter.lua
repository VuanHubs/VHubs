-- Specter | VuaN
-- Version 1.0

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local lp = Players.LocalPlayer

local ACCENT_COLOR = Color3.fromRGB(255, 70, 70)
local BG_MAIN = Color3.fromRGB(15, 15, 20)
local BG_PANEL = Color3.fromRGB(22, 22, 28)
local BG_ELEMENT = Color3.fromRGB(35, 35, 42)
local TEXT_PRIMARY = Color3.fromRGB(235, 235, 240)
local TEXT_SECONDARY = Color3.fromRGB(155, 155, 170)

local settings = {
    jumpEnabled = false,
    jumpValue = 10,
    flyEnabled = false,
    flySpeed = 50,
    noclip = false,
    autoRun = false,
    noFog = false,
    fullbright = false,
    antiVoid = false,
    showWatermark = true,
    showEvidence = true,
    toggleKey = Enum.KeyCode.Insert,
    espPlayers = false,
    espGhost = false,
    espEquipment = false,
    espClosets = false
}

local espObjects = {}

local function Notify(text, duration)
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "SPECTER UI",
            Text = text,
            Duration = duration
        })
    end)
end

function UpdateESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}

    if settings.espPlayers then
        for _, player in pairs(Players:GetPlayers()) do
            if player == lp then continue end
            local char = player.Character
            if not char then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            local hl = Instance.new("Highlight")
            hl.Adornee = char
            hl.FillTransparency = 1
            hl.OutlineColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineTransparency = 0.3
            hl.Parent = char
            table.insert(espObjects, hl)
        end
    end

    if settings.espGhost then
        local npcsFolder = Workspace:FindFirstChild("NPCs")
        if npcsFolder then
            local globalFolder = npcsFolder:FindFirstChild("GLOBAL")
            if globalFolder then
                for _, child in pairs(globalFolder:GetChildren()) do
                    if child:IsA("Model") or child:IsA("BasePart") then
                        local hl = Instance.new("Highlight")
                        hl.Adornee = child
                        hl.FillTransparency = 1
                        hl.OutlineColor = Color3.fromRGB(255, 70, 70)
                        hl.OutlineTransparency = 0.3
                        hl.Parent = child
                        table.insert(espObjects, hl)
                    end
                end
            end
        end
    end

    if settings.espEquipment then
        local equipmentFolder = Workspace:FindFirstChild("Equipment")
        if equipmentFolder then
            for _, child in pairs(equipmentFolder:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") then
                    local hl = Instance.new("Highlight")
                    hl.Adornee = child
                    hl.FillTransparency = 1
                    hl.OutlineColor = Color3.fromRGB(0, 100, 255)
                    hl.OutlineTransparency = 0.3
                    hl.Parent = child
                    table.insert(espObjects, hl)
                end
            end
        end
    end

    if settings.espClosets then
        local mapFolder = Workspace:FindFirstChild("Map")
        if mapFolder then
            local closetsFolder = mapFolder:FindFirstChild("Closets")
            if closetsFolder then
                for _, child in pairs(closetsFolder:GetChildren()) do
                    if child:IsA("Model") or child:IsA("BasePart") then
                        local hl = Instance.new("Highlight")
                        hl.Adornee = child
                        hl.FillTransparency = 1
                        hl.OutlineColor = Color3.fromRGB(0, 255, 100)
                        hl.OutlineTransparency = 0.3
                        hl.Parent = child
                        table.insert(espObjects, hl)
                    end
                end
            end
        end
    end
end

local flyConnection, noclipConnection, autoRunConnection, antiVoidConnection

RunService.RenderStepped:Connect(function()
    if settings.flyEnabled and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        if not flyConnection then
            local root = lp.Character.HumanoidRootPart
            local bg = Instance.new("BodyGyro"); bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = root.CFrame; bg.Parent = root
            local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.Parent = root
            lp.Character.Humanoid.PlatformStand = true
            flyConnection = RunService.RenderStepped:Connect(function()
                if not settings.flyEnabled or not lp.Character then
                    flyConnection:Disconnect(); flyConnection = nil; return
                end
                local moveDir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,-1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0,-1,0) end
                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                local cam = Camera
                bv.Velocity = (cam.CFrame.LookVector * moveDir.Z + cam.CFrame.RightVector * moveDir.X + cam.CFrame.UpVector * moveDir.Y) * settings.flySpeed
                bg.CFrame = cam.CFrame
            end)
        end
    else
        if flyConnection then
            flyConnection:Disconnect(); flyConnection = nil
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local root = lp.Character.HumanoidRootPart
                local bg = root:FindFirstChild("BodyGyro"); if bg then bg:Destroy() end
                local bv = root:FindFirstChild("BodyVelocity"); if bv then bv:Destroy() end
                lp.Character.Humanoid.PlatformStand = false
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if settings.noclip and lp.Character then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                if settings.noclip and lp.Character then
                    for _, part in pairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                else
                    noclipConnection:Disconnect(); noclipConnection = nil
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect(); noclipConnection = nil
            if lp.Character then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if settings.autoRun then
        if not autoRunConnection then
            autoRunConnection = RunService.RenderStepped:Connect(function()
                if settings.autoRun then
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.W, false, game)
                end
            end)
        end
    else
        if autoRunConnection then
            autoRunConnection:Disconnect(); autoRunConnection = nil
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end
    end
end)

RunService.Stepped:Connect(function()
    if settings.antiVoid then
        if not antiVoidConnection then
            antiVoidConnection = RunService.Stepped:Connect(function()
                if settings.antiVoid and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local root = lp.Character.HumanoidRootPart
                    if root.Position.Y <= -500 then
                        root.Velocity = root.Velocity + Vector3.new(0, 250, 0)
                    end
                end
            end)
        end
    else
        if antiVoidConnection then
            antiVoidConnection:Disconnect(); antiVoidConnection = nil
        end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SPECTER_UI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local EvidencePanel = Instance.new("Frame")
EvidencePanel.Name = "EvidencePanel"
EvidencePanel.Parent = ScreenGui
EvidencePanel.BackgroundTransparency = 0.4
EvidencePanel.BackgroundColor3 = BG_PANEL
EvidencePanel.BorderSizePixel = 2
EvidencePanel.BorderColor3 = Color3.fromRGB(255, 70, 70)
EvidencePanel.Position = UDim2.new(1, -280, 0.5, -150) 
EvidencePanel.Size = UDim2.new(0, 260, 0, 300)
EvidencePanel.AnchorPoint = Vector2.new(1, 0.5)
EvidencePanel.Visible = true
EvidencePanel.Draggable = true
EvidencePanel.Active = true

local EvTitle = Instance.new("TextLabel")
EvTitle.Parent = EvidencePanel
EvTitle.BackgroundTransparency = 1
EvTitle.Size = UDim2.new(1, 0, 0, 40)
EvTitle.Font = Enum.Font.GothamBold
EvTitle.Text = "EVIDENCE HELPER"
EvTitle.TextColor3 = ACCENT_COLOR
EvTitle.TextSize = 16
EvTitle.TextXAlignment = Enum.TextXAlignment.Center
EvTitle.TextYAlignment = Enum.TextYAlignment.Center

local EvLine = Instance.new("Frame")
EvLine.Parent = EvidencePanel
EvLine.BackgroundColor3 = ACCENT_COLOR
EvLine.BorderSizePixel = 0
EvLine.Position = UDim2.new(0, 15, 0, 40)
EvLine.Size = UDim2.new(1, -30, 0, 2)

local EvidenceListContainer = Instance.new("Frame")
EvidenceListContainer.Parent = EvidencePanel
EvidenceListContainer.BackgroundTransparency = 1
EvidenceListContainer.Position = UDim2.new(0, 0, 0, 50)
EvidenceListContainer.Size = UDim2.new(1, 0, 1, -50)
EvidenceListContainer.ClipsDescendants = true

local EvListLayout = Instance.new("UIListLayout", EvidenceListContainer)
EvListLayout.Padding = UDim.new(0, 8)
EvListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
EvListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
EvListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local EvPadding = Instance.new("UIPadding", EvidenceListContainer)
EvPadding.PaddingTop = UDim.new(0, 5) 
EvPadding.PaddingBottom = UDim.new(0, 10)
EvPadding.PaddingLeft = UDim.new(0, 10)
EvPadding.PaddingRight = UDim.new(0, 10)

local function CreateEvidenceItem(name, color)
    local item = Instance.new("Frame")
    item.Parent = EvidenceListContainer
    item.BackgroundTransparency = 1
    item.Size = UDim2.new(1, -20, 0, 28)
    
    local icon = Instance.new("Frame")
    icon.Parent = item
    icon.BorderSizePixel = 0
    icon.Size = UDim2.new(0, 6, 0, 6)
    icon.Position = UDim2.new(0, 0, 0.5, -3)
    icon.BackgroundColor3 = color or ACCENT_COLOR
    
    local label = Instance.new("TextLabel")
    label.Parent = item
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -15, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = name
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    return item
end

local activeEvidences = {}
local evidenceTimers = {}

local function UpdateEvidenceOverlay()
    if not settings.showEvidence then 
        for key, obj in pairs(activeEvidences) do obj:Destroy() end
        activeEvidences = {}
        evidenceTimers = {}
        return 
    end

    local ws = game:GetService("Workspace")
    local dynamicFolder = ws:FindFirstChild("Dynamic")
    local evidenceFolder = dynamicFolder and dynamicFolder:FindFirstChild("Evidence")
    
    if not evidenceFolder then return end

    local emfFolder = evidenceFolder:FindFirstChild("EMF")
    if emfFolder and emfFolder:FindFirstChild("EMF5") then
        if not activeEvidences["EMF5"] then
            activeEvidences["EMF5"] = CreateEvidenceItem("EMF Level 5", Color3.fromRGB(255, 100, 100))
        end
        evidenceTimers["EMF5"] = tick() + 5
    end

    local orbsFolder = evidenceFolder:FindFirstChild("Orbs")
    if orbsFolder and #orbsFolder:GetChildren() > 0 then
        if not activeEvidences["GhostOrb"] then
            activeEvidences["GhostOrb"] = CreateEvidenceItem("Ghost Orb", Color3.fromRGB(100, 200, 255))
        end
        evidenceTimers["GhostOrb"] = tick() + 5
    end

    local fpFolder = evidenceFolder:FindFirstChild("Fingerprints")
    if fpFolder then
        local hasPrint = fpFolder:FindFirstChild("Fingerprint") or fpFolder:FindFirstChild("Finderprint")
        if hasPrint then
            if not activeEvidences["Fingerprints"] then
                activeEvidences["Fingerprints"] = CreateEvidenceItem("Fingerprints", Color3.fromRGB(100, 255, 100))
            end
            evidenceTimers["Fingerprints"] = tick() + 5
        end
    end

    local sensorGrid = evidenceFolder:FindFirstChild("MotionGrids")
    if sensorGrid then
        local hasActiveSensor = false
        local salmonColor = Color3.fromRGB(250, 128, 114)
        
        for _, grid in ipairs(sensorGrid:GetChildren()) do
            if hasActiveSensor then break end
            
            local partsToCheck = grid:IsA("Model") and grid:GetDescendants() or {grid}
            
            for _, part in ipairs(partsToCheck) do
                if part:IsA("BasePart") then
                    local c = part.Color
                    
                    local isSalmon = math.abs(c.R - salmonColor.R) < 0.02 and 
                                     math.abs(c.G - salmonColor.G) < 0.02 and 
                                     math.abs(c.B - salmonColor.B) < 0.02
                                     
                    local isReallyRed = c.R > 0.95 and c.G < 0.05 and c.B < 0.05
                    
                    if isSalmon or isReallyRed then
                        hasActiveSensor = true
                        break
                    end
                end
            end
        end
        
        if hasActiveSensor then
            if not activeEvidences["SensorGrid"] then
                activeEvidences["SensorGrid"] = CreateEvidenceItem("Motion Sensor", Color3.fromRGB(255, 50, 50))
            end
            evidenceTimers["SensorGrid"] = tick() + 5
        end
    end

    local currentTime = tick()
    for key, expireTime in pairs(evidenceTimers) do
        if currentTime >= expireTime then
            if activeEvidences[key] then
                activeEvidences[key]:Destroy()
                activeEvidences[key] = nil
            end
            evidenceTimers[key] = nil
        end
    end
end

RunService.RenderStepped:Connect(UpdateEvidenceOverlay)

local Watermark = Instance.new("Frame")
Watermark.Name = "Watermark"
Watermark.Parent = ScreenGui
Watermark.BackgroundTransparency = 1
Watermark.Position = UDim2.new(1, -10, 1, -10)
Watermark.Size = UDim2.new(0, 220, 0, 60)
Watermark.AnchorPoint = Vector2.new(1, 1)

local WatermarkLabel1 = Instance.new("TextLabel")
WatermarkLabel1.Parent = Watermark
WatermarkLabel1.BackgroundTransparency = 1
WatermarkLabel1.Size = UDim2.new(1, 0, 0, 20)
WatermarkLabel1.Position = UDim2.new(0, 0, 0, 0)
WatermarkLabel1.Font = Enum.Font.GothamBold
WatermarkLabel1.Text = "SPECTER | VuaN"
WatermarkLabel1.TextColor3 = ACCENT_COLOR
WatermarkLabel1.TextSize = 14
WatermarkLabel1.TextXAlignment = Enum.TextXAlignment.Right
WatermarkLabel1.TextYAlignment = Enum.TextYAlignment.Bottom

local WatermarkLabel2 = Instance.new("TextLabel")
WatermarkLabel2.Parent = Watermark
WatermarkLabel2.BackgroundTransparency = 1
WatermarkLabel2.Size = UDim2.new(1, 0, 0, 20)
WatermarkLabel2.Position = UDim2.new(0, 0, 0, 20)
WatermarkLabel2.Font = Enum.Font.Gotham
WatermarkLabel2.Text = "Press [Insert] to toggle"
WatermarkLabel2.TextColor3 = TEXT_SECONDARY
WatermarkLabel2.TextSize = 11
WatermarkLabel2.TextXAlignment = Enum.TextXAlignment.Right
WatermarkLabel2.TextYAlignment = Enum.TextYAlignment.Bottom

local WatermarkLabel3 = Instance.new("TextLabel")
WatermarkLabel3.Parent = Watermark
WatermarkLabel3.BackgroundTransparency = 1
WatermarkLabel3.Size = UDim2.new(1, 0, 0, 20)
WatermarkLabel3.Position = UDim2.new(0, 0, 0, 40)
WatermarkLabel3.Font = Enum.Font.Gotham
WatermarkLabel3.Text = "t.me/EndoSCripts"
WatermarkLabel3.TextColor3 = TEXT_SECONDARY
WatermarkLabel3.TextSize = 11
WatermarkLabel3.TextXAlignment = Enum.TextXAlignment.Right
WatermarkLabel3.TextYAlignment = Enum.TextYAlignment.Bottom

local function UpdateWatermark()
    local keyName = settings.toggleKey.Name
    WatermarkLabel2.Text = "Press [" .. keyName .. "] to toggle"
end
UpdateWatermark()
Watermark.Visible = settings.showWatermark

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BackgroundColor3 = BG_MAIN
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(30, 30, 38)
MainFrame.Position = UDim2.new(0.5, -350, 0.3, 0)
MainFrame.Size = UDim2.new(0, 700, 0, 500)
MainFrame.ClipsDescendants = true
MainFrame.Visible = false

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = BG_PANEL
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 45)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "SPECTER | VuaN"
TitleLabel.TextColor3 = ACCENT_COLOR
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = TEXT_SECONDARY
CloseBtn.TextSize = 16
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = ACCENT_COLOR end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = TEXT_SECONDARY end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local LeftMenu = Instance.new("ScrollingFrame")
LeftMenu.Name = "LeftMenu"
LeftMenu.Parent = MainFrame
LeftMenu.BackgroundColor3 = BG_PANEL
LeftMenu.BackgroundTransparency = 0.5
LeftMenu.BorderSizePixel = 0
LeftMenu.Position = UDim2.new(0, 0, 0, 45)
LeftMenu.Size = UDim2.new(0, 160, 1, -45)
LeftMenu.ScrollBarThickness = 0

local MenuPadding = Instance.new("UIPadding")
MenuPadding.Parent = LeftMenu
MenuPadding.PaddingLeft = UDim.new(0, 8)
MenuPadding.PaddingTop = UDim.new(0, 8)

local MenuLayout = Instance.new("UIListLayout", LeftMenu)
MenuLayout.Padding = UDim.new(0, 4)

local MenuItems = {"About", "ESP", "Teleport", "More", "Settings"}
local MenuButtons = {}
local CurrentTab = "About"

for i, item in ipairs(MenuItems) do
    local btn = Instance.new("TextButton")
    btn.Parent = LeftMenu
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.Font = Enum.Font.GothamBold
    btn.Text = "  " .. item
    btn.TextColor3 = TEXT_SECONDARY
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    
    local Indicator = Instance.new("Frame")
    Indicator.Parent = btn
    Indicator.BackgroundColor3 = ACCENT_COLOR
    Indicator.BorderSizePixel = 0
    Indicator.Size = UDim2.new(0, 3, 0.7, 0)
    Indicator.Position = UDim2.new(0, 0, 0.15, 0)
    Indicator.Visible = (i == 1)
    
    btn.MouseButton1Click:Connect(function()
        CurrentTab = item
        for _, b in pairs(MenuButtons) do
            b.TextColor3 = TEXT_SECONDARY
            b:FindFirstChildWhichIsA("Frame").Visible = false
        end
        btn.TextColor3 = TEXT_PRIMARY
        Indicator.Visible = true
        UpdateContent()
    end)
    
    table.insert(MenuButtons, btn)
end
MenuButtons[1].TextColor3 = TEXT_PRIMARY

local RightContent = Instance.new("ScrollingFrame")
RightContent.Name = "RightContent"
RightContent.Parent = MainFrame
RightContent.BackgroundColor3 = BG_MAIN
RightContent.BackgroundTransparency = 0.3
RightContent.BorderSizePixel = 0
RightContent.Position = UDim2.new(0, 160, 0, 45)
RightContent.Size = UDim2.new(1, -160, 1, -45)
RightContent.ScrollBarThickness = 4
RightContent.ScrollBarImageColor3 = ACCENT_COLOR
RightContent.CanvasSize = UDim2.new(0, 0, 0, 0)
RightContent.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ContentPadding = Instance.new("UIPadding")
ContentPadding.Parent = RightContent
ContentPadding.PaddingLeft = UDim.new(0, 20)
ContentPadding.PaddingRight = UDim.new(0, 20)
ContentPadding.PaddingTop = UDim.new(0, 15)
ContentPadding.PaddingBottom = UDim.new(0, 20)

local ContentLayout = Instance.new("UIListLayout", RightContent)
ContentLayout.Padding = UDim.new(0, 12)

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Parent = parent
    section.BackgroundTransparency = 1
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = section
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = ACCENT_COLOR
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local line = Instance.new("Frame")
    line.Parent = section
    line.BackgroundColor3 = BG_PANEL
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 0, 0, 25)
    line.Size = UDim2.new(1, 0, 0, 2)
    
    local container = Instance.new("Frame")
    container.Parent = section
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 0, 0, 30)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 6)
    
    return container
end

local function CreateLabel(parent, text, color, size)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = color or TEXT_PRIMARY
    label.TextSize = size or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    return label
end

local function CreateToggle(parent, text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 30)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Parent = frame
    toggleBg.BorderSizePixel = 0
    toggleBg.Position = UDim2.new(1, -44, 0.5, -12)
    toggleBg.Size = UDim2.new(0, 40, 0, 24)
    toggleBg.BackgroundColor3 = defaultValue and ACCENT_COLOR or Color3.fromRGB(60, 60, 70)
    local toggleCorner = Instance.new("UICorner", toggleBg)
    toggleCorner.CornerRadius = UDim.new(1, 0)
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Parent = toggleBg
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Position = defaultValue and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    toggleKnob.Size = UDim2.new(0, 18, 0, 18)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    local knobCorner = Instance.new("UICorner", toggleKnob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    local state = defaultValue
    local function Toggle()
        state = not state
        toggleBg.BackgroundColor3 = state and ACCENT_COLOR or Color3.fromRGB(60, 60, 70)
        TweenService:Create(toggleKnob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        callback(state)
    end
    local clickArea = Instance.new("TextButton")
    clickArea.Parent = frame
    clickArea.BackgroundTransparency = 1
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.Text = ""
    clickArea.MouseButton1Click:Connect(Toggle)
    return frame
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 40)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_SECONDARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.Size = UDim2.new(0, 45, 0, 18)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = ACCENT_COLOR
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Parent = frame
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Position = UDim2.new(0, 0, 0, 24)
    sliderTrack.Size = UDim2.new(1, 0, 0, 4)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    local trackCorner = Instance.new("UICorner", sliderTrack)
    trackCorner.CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderTrack
    sliderFill.BorderSizePixel = 0
    sliderFill.BackgroundColor3 = ACCENT_COLOR
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    local fillCorner = Instance.new("UICorner", sliderFill)
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("TextButton")
    knob.Parent = sliderTrack
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Text = ""
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local currentValue = default
    local function updateSlider(input)
        local mousePos = input.Position.X
        local sliderPos = sliderTrack.AbsolutePosition.X
        local sliderWidth = sliderTrack.AbsoluteSize.X
        local t = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
        currentValue = min + (max - min) * t
        currentValue = math.floor(currentValue * 10) / 10
        valueLabel.Text = tostring(currentValue)
        sliderFill.Size = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, -6, 0.5, -6)
        callback(currentValue)
    end
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
            dragging = true
        end
    end)
    return frame
end

local function CreateCyclicButton(parent, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 30)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0.65, 0, 0, 0)
    btn.Size = UDim2.new(0.3, 0, 1, 0)
    btn.Font = Enum.Font.GothamBold
    btn.Text = default
    btn.TextColor3 = ACCENT_COLOR
    btn.TextSize = 13
    btn.BackgroundColor3 = BG_ELEMENT
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 4)
    
    local currentIndex = 1
    for i, opt in ipairs(options) do
        if opt == default then currentIndex = i break end
    end
    
    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        local newVal = options[currentIndex]
        btn.Text = newVal
        callback(newVal)
    end)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = BG_ELEMENT end)
    return frame
end

local function CreateTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Parent = parent
    box.BackgroundColor3 = BG_ELEMENT
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 32)
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = TEXT_SECONDARY
    box.Text = ""
    box.TextColor3 = TEXT_PRIMARY
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    local padding = Instance.new("UIPadding")
    padding.Parent = box
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = UDim.new(0, 6)
    return box
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BackgroundColor3 = BG_ELEMENT
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = TEXT_PRIMARY
    btn.TextSize = 13
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = BG_ELEMENT end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

function UpdateContent()
    for _, child in pairs(RightContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end
    
    if CurrentTab == "About" then
        local sec = CreateSection(RightContent, "ABOUT")
        CreateLabel(sec, "Specter by VuaN", ACCENT_COLOR, 18)
        CreateLabel(sec, "v1.0", TEXT_SECONDARY, 12)
        CreateLabel(sec, "Beta version", TEXT_SECONDARY, 12)
        CreateLabel(sec, " - ESP ghost/players/equipment/closet", TEXT_SECONDARY, 12)
        CreateLabel(sec, " - Player modif", TEXT_SECONDARY, 12)
        CreateLabel(sec, " - Teleport to van", TEXT_SECONDARY, 12)
        CreateLabel(sec, " - Evidence helper", TEXT_SECONDARY, 12)
        CreateLabel(sec, " - UI settings", TEXT_SECONDARY, 12)
        CreateLabel(sec, "", TEXT_SECONDARY, 1)
        CreateLabel(sec, "UI Tabs:", ACCENT_COLOR, 14)
        CreateLabel(sec, "• About - Information", TEXT_SECONDARY, 13)
        CreateLabel(sec, "• ESP - Player, Ghost, Equipment & Closets ESP", TEXT_SECONDARY, 13)
        CreateLabel(sec, "• Teleport - Teleport to locations", TEXT_SECONDARY, 13)
        CreateLabel(sec, "• More - Jump, Fly, Noclip, World mods", TEXT_SECONDARY, 13)
        CreateLabel(sec, "• Settings - UI, Keybinds", TEXT_SECONDARY, 13)
        CreateLabel(sec, "", TEXT_SECONDARY, 1)
        CreateLabel(sec, "thx you for using VHubs :3", ACCENT_COLOR, 14)
        
    elseif CurrentTab == "ESP" then
        local sec = CreateSection(RightContent, "ESP SETTINGS")
        CreateToggle(sec, "Player ESP", settings.espPlayers, function(v) 
            settings.espPlayers = v 
            UpdateESP()
        end)
        CreateToggle(sec, "Ghost ESP", settings.espGhost, function(v) 
            settings.espGhost = v 
            UpdateESP()
        end)
        CreateToggle(sec, "Equipment ESP", settings.espEquipment, function(v) 
            settings.espEquipment = v 
            UpdateESP()
        end)
        CreateToggle(sec, "Closets ESP", settings.espClosets, function(v) 
            settings.espClosets = v 
            UpdateESP()
        end)
        CreateLabel(sec, "More soon", TEXT_SECONDARY, 11)
        
    elseif CurrentTab == "Teleport" then
        local sec = CreateSection(RightContent, "TELEPORT")
        CreateButton(sec, "TP to Van", function()
            local vanSpawn = Workspace:FindFirstChild("Van")
            if vanSpawn then
                local spawnPart = vanSpawn:FindFirstChild("Spawn")
                if spawnPart and spawnPart:IsA("BasePart") then
                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
                        Notify("Teleported to Van")
                    end
                end
            end
        end)
        
        local playerSec = CreateSection(RightContent, "TP TO PLAYER")
        local playerBox = CreateTextBox(playerSec, "Player name...")
        CreateButton(playerSec, "Teleport to Player", function()
            local target = nil
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Name:lower():find(playerBox.Text:lower()) then
                    target = plr; break
                end
            end
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                    Notify("Teleported to " .. target.Name)
                end
            else
                Notify("Player not found")
            end
        end)
        
    elseif CurrentTab == "More" then
        local sec = CreateSection(RightContent, "PLAYER MODS")
        CreateToggle(sec, "Jump Hack", settings.jumpEnabled, function(v)
            settings.jumpEnabled = v
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.JumpPower = v and settings.jumpValue or 50
            end
        end)
        CreateSlider(sec, "Jump Power", 0, 100, settings.jumpValue, function(v)
            settings.jumpValue = v
            if settings.jumpEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.JumpPower = v
            end
        end)
        CreateToggle(sec, "Fly Hack", settings.flyEnabled, function(v) settings.flyEnabled = v end)
        CreateSlider(sec, "Fly Speed", 1, 100, settings.flySpeed, function(v) settings.flySpeed = v end)
        CreateToggle(sec, "Noclip", settings.noclip, function(v) settings.noclip = v end)
        CreateToggle(sec, "No Fog", settings.noFog, function(v)
            settings.noFog = v
            Lighting.FogEnd = v and 100000 or 1000
        end)
        CreateToggle(sec, "Fullbright", settings.fullbright, function(v)
            settings.fullbright = v
            if v then
                Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
            else
                Lighting.Brightness = 1; Lighting.ClockTime = 12; Lighting.GlobalShadows = true
            end
        end)
        
    elseif CurrentTab == "Settings" then
        local sec = CreateSection(RightContent, "UI SETTINGS")
        CreateToggle(sec, "Watermark", settings.showWatermark, function(v)
            settings.showWatermark = v
            Watermark.Visible = v
        end)
        
        CreateToggle(sec, "Evidence Panel", settings.showEvidence, function(v)
            settings.showEvidence = v
            EvidencePanel.Visible = v
            if not v then
                for k, obj in pairs(activeEvidences) do obj:Destroy() end
                activeEvidences = {}
                evidenceTimers = {}
            end
        end)

        local keySec = CreateSection(RightContent, "KEYBINDS")
        CreateCyclicButton(keySec, "Toggle UI Key", {"Insert","F1","F2","F3","F4"}, "Insert", function(v)
            local keyMap = {
                Insert = Enum.KeyCode.Insert,
                RightShift = Enum.KeyCode.RightShift,
                LeftShift = Enum.KeyCode.LeftShift,
                F1 = Enum.KeyCode.F1,
                F2 = Enum.KeyCode.F2,
                F3 = Enum.KeyCode.F3,
                F4 = Enum.KeyCode.F4
            }
            settings.toggleKey = keyMap[v] or Enum.KeyCode.Insert
            UpdateWatermark()
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == settings.toggleKey then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

UpdateContent()
Notify("Press " .. settings.toggleKey.Name .. " to open.", 3)

local function RefreshESP()
    UpdateESP()
end

local function onCharacterAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        RefreshESP()
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= lp then
        onCharacterAdded(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= lp then
        onCharacterAdded(player)
        task.wait(0.2)
        RefreshESP()
    end
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    RefreshESP()
end)

local lastESPUpdate = 0
RunService.Heartbeat:Connect(function()
    if tick() - lastESPUpdate > 2 then
        lastESPUpdate = tick()
        if settings.espPlayers or settings.espGhost or settings.espEquipment or settings.espClosets then
            RefreshESP()
        end
    end
end)

RefreshESP()

ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        if flyConnection then flyConnection:Disconnect() end
        if noclipConnection then noclipConnection:Disconnect() end
        if autoRunConnection then autoRunConnection:Disconnect() end
        if antiVoidConnection then antiVoidConnection:Disconnect() end
    end
end)
