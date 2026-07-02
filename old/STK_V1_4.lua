-- VuaN | Survive the Killer V1.4
-- Support version v2.31.0

-- Change log
-- V1.4 - Add ESP Exits, add Auto Escape, fix Teleport to Exit
-- V1.3 - UI redesign, add Killer Chance X3 (gamepass bypass)
-- V1.2 - add Double Jump (gamepass bypass)
-- V1.1 - add Auto revive self, Auto revive (risk), update ESP logic
-- V1 - release

local lp = game:FindService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local function notif(str, dur)
    StarterGui:SetCore("SendNotification", {
        Title = "VSTK V1.4",
        Text = str,
        Duration = dur or 3
    })
end

local settings = {
    Speed = 16, speedEnabled = false,
    speedDisableOnDown = true,
    Fly = false, flySpeed = 50,
    Noclip = false,
    DoubleJump = false,
    KillerChanceX3 = false,
    ESP = false,
    ESPExits = false,
    NoFog = false,
    Fullbright = false,
    AutoLoot = false,
    returnHomeAfterLoot = true,
    KillAura = false,
    killAuraRadius = 10,
    AutoReviveLegit = false,
    AutoReviveRisky = false,
    AutoReviveSelf = false,
    selfReviveCooldown = 5,
    selfReviveMode = "Random",
    AutoEscape = false
}

local flyConnection = nil
local noclipConnection = nil
local brightLoop = nil
local lootConnection = nil
local killAuraConnection = nil
local reviveLegitConnection = nil
local reviveRiskyConnection = nil
local selfReviveConnection = nil
local autoEscapeConnection = nil
local noFogConnection = nil
local espObjects = {}
local espExitObjects = {}
local savedHomePosition = nil
local isReviving = false
local lastSelfReviveTime = 0
local espCache = {}
local CurrentTab = "About"
local lastEscapeTime = 0
local timerActive = false

local function pressF()
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.1)
    vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
end

local function FindMap()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:FindFirstChild("LootSpawns") or child:FindFirstChild("ExitGateways") or child:FindFirstChild("Exits") then
            return child
        end
    end
    return nil
end

local function IsSurvivor()
    if not lp.Team then return false end
    local teamName = lp.Team.Name:lower()
    if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
        return false
    end
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    return not isKiller
end

local function IsPlayerDowned(player)
    if not player or not player.Character then return false end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
    return bleedOut and bleedOut.Enabled
end

local h = Instance.new("ScreenGui")
h.Name = "VuaN_STK"
h.Parent = game:GetService("CoreGui")
h.ResetOnSpawn = false

local Main = Instance.new("ImageLabel")
Main.Name = "Main"
Main.Parent = h
Main.Active = true
Main.Draggable = true
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.BackgroundTransparency = 0.1
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -250, 0.3, 0)
Main.Size = UDim2.new(0, 400, 0, 380)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local Top = Instance.new("Frame")
Top.Name = "Top"
Top.Parent = Main
Top.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Top.BackgroundTransparency = 0
Top.BorderSizePixel = 0
Top.Size = UDim2.new(1, 0, 0, 30)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = Top
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(0, 180, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "Survivar The Killer | VuaN"
Title.TextColor3 = Color3.fromRGB(224, 58, 58)
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center

local CloseBtn = Instance.new("TextButton")
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
local CloseCorner = Instance.new("UICorner"); CloseCorner.CornerRadius = UDim.new(0, 4); CloseCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() h:Destroy() end)

local LeftMenu = Instance.new("Frame")
LeftMenu.Name = "LeftMenu"
LeftMenu.Parent = Main
LeftMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
LeftMenu.BackgroundTransparency = 0.3
LeftMenu.BorderSizePixel = 0
LeftMenu.Position = UDim2.new(0, 0, 0, 30)
LeftMenu.Size = UDim2.new(0, 85, 1, -30)

local RightContent = Instance.new("Frame")
RightContent.Name = "RightContent"
RightContent.Parent = Main
RightContent.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
RightContent.BackgroundTransparency = 0.05
RightContent.BorderSizePixel = 0
RightContent.Position = UDim2.new(0, 85, 0, 30)
RightContent.Size = UDim2.new(1, -85, 1, -30)
RightContent.ClipsDescendants = true

local MenuItems = {"About", "Player", "World", "Revive"}
local MenuButtons = {}

for i, item in ipairs(MenuItems) do
    local btn = Instance.new("TextButton")
    btn.Parent = LeftMenu
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.BackgroundTransparency = 0.5
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0.05, 0, 0.03 + ((i-1) * 0.1), 0)
    btn.Size = UDim2.new(0, 80, 0, 30)
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
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 26)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.7, 0, 0, 26)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 235)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton")
    toggle.Parent = frame
    toggle.BorderSizePixel = 0
    toggle.Position = UDim2.new(1, -40, 0, 3)
    toggle.Size = UDim2.new(0, 35, 0, 18)
    toggle.Font = Enum.Font.GothamBold
    toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
    toggle.Text = defaultValue and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 9

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggle

    local state = defaultValue
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
        toggle.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(224, 58, 58) end)
    return btn
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 40)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.6, 0, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 235)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -45, 0, 0)
    valueLabel.Size = UDim2.new(0, 40, 0, 18)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(224, 58, 58)
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Parent = frame
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Position = UDim2.new(0, 5, 0, 22)
    sliderFrame.Size = UDim2.new(1, -10, 0, 5)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Parent = sliderFrame
    fill.BorderSizePixel = 0
    fill.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill

    local knob = Instance.new("TextButton")
    knob.Parent = sliderFrame
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    knob.Position = UDim2.new((default - min) / (max - min), -7.5, 0, -5)
    knob.Size = UDim2.new(0, 15, 0, 15)
    knob.Text = ""

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 8)
    knobCorner.Parent = knob

    local dragging = false
    local currentValue = default

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
        end
    end)
    return frame
end

local function CreateLabel(parent, text, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 22)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(220, 220, 235)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function CreateTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Parent = parent
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 30)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    box.BackgroundTransparency = 0.3
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 11
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box
    return box
end

local function ClearRightContent()
    for _, child in pairs(RightContent:GetChildren()) do
        if not child:IsA("UICorner") then child:Destroy() end
    end
end

-- Gamepass Bypass
local function SetSettingsAttribute(name, value)
    if not lp then return end
    local settingsFolder = lp:FindFirstChild("Settings")
    if not settingsFolder then
        settingsFolder = Instance.new("Folder")
        settingsFolder.Name = "Settings"
        settingsFolder.Parent = lp
    end
    settingsFolder:SetAttribute(name, value)
end

-- DOUBLE JUMP
local function UpdateDoubleJump()
    SetSettingsAttribute("double_jump", settings.DoubleJump)
end

-- KILLER CHANCE X3
local function UpdateKillerChance()
    SetSettingsAttribute("killer_chance_3x", settings.KillerChanceX3)
end

-- ESP PLAYERS
local function GetPlayerTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

local function UpdateESP()
    if not settings.ESP then
        for _, obj in pairs(espObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects = {}
        espCache = {}
        return
    end

    local currentPlayers = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp then
            local color = GetPlayerTeamColor(player)
            local hasChar = player.Character ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil
            currentPlayers[player.Name] = {team = color, hasChar = hasChar}
        end
    end
    
    local needUpdate = false
    for name, data in pairs(currentPlayers) do
        if not espCache[name] or espCache[name].team ~= data.team or espCache[name].hasChar ~= data.hasChar then
            needUpdate = true
            break
        end
    end
    for name in pairs(espCache) do
        if not currentPlayers[name] then
            needUpdate = true
            break
        end
    end
    
    if not needUpdate then return end
    espCache = currentPlayers
    
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local color = GetPlayerTeamColor(player)
            local highlight = Instance.new("Highlight")
            highlight.Adornee = player.Character
            highlight.FillTransparency = 1
            highlight.OutlineColor = color
            highlight.OutlineTransparency = 0.3
            highlight.Parent = player.Character
            table.insert(espObjects, highlight)
        end
    end
end

-- ESP EXITS
local function UpdateESPExits()
    for _, obj in pairs(espExitObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    espExitObjects = {}
    
    if not settings.ESPExits then return end
    
    local map = FindMap()
    if not map then return end
    
    local exitsFolder = map:FindFirstChild("Exits")
    if not exitsFolder then
        exitsFolder = map:FindFirstChild("ExitGateways")
        if not exitsFolder then return end
    end
    
    local isTimerActive = false
    local playerGui = lp:FindFirstChild("PlayerGui")
    if playerGui then
        local topBar = playerGui:FindFirstChild("TopBar")
        if topBar then
            local roundTimer = topBar:FindFirstChild("RoundTimer")
            if roundTimer then
                local extra = roundTimer:FindFirstChild("Extra")
                if extra then
                    local gradient = extra:FindFirstChild("Gradient")
                    if gradient then
                        local uiGradient = gradient:FindFirstChild("UIGradient")
                        if not uiGradient then
                            uiGradient = gradient:FindFirstChild("UI Gradient")
                        end
                        if uiGradient then
                            local color = uiGradient.Color
                            if color and color.Keypoints then
                                for _, keypoint in ipairs(color.Keypoints) do
                                    local c = keypoint.Value
                                    local r = math.round(c.R * 10) / 10
                                    local g = math.round(c.G * 10) / 10
                                    local b = math.round(c.B * 10) / 10
                                    if not (r == 0 and g == 0 and b == 0) then
                                        isTimerActive = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    local fillColor = isTimerActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 165, 0)
    local outlineColor = isTimerActive and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 140, 0)
    
    for _, gateway in ipairs(exitsFolder:GetChildren()) do
        if gateway.Name == "ExitGateway" or gateway:IsA("Model") then
            local doorway = gateway:FindFirstChild("Doorway")
            if doorway then
                for _, part in ipairs(doorway:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local highlight = Instance.new("Highlight")
                        highlight.Adornee = part
                        highlight.FillColor = fillColor
                        highlight.FillTransparency = 0.5
                        highlight.OutlineColor = outlineColor
                        highlight.OutlineTransparency = 0.2
                        highlight.Parent = part
                        table.insert(espExitObjects, highlight)
                    end
                end
                
                local doorwayHighlight = Instance.new("Highlight")
                doorwayHighlight.Adornee = doorway
                doorwayHighlight.FillColor = fillColor
                doorwayHighlight.FillTransparency = 0.15
                doorwayHighlight.OutlineColor = outlineColor
                doorwayHighlight.OutlineTransparency = 0.5
                doorwayHighlight.Parent = doorway
                table.insert(espExitObjects, doorwayHighlight)
            end
        end
    end
end

local lastESPUpdate = 0
local function PeriodicESPUpdate()
    if tick() - lastESPUpdate >= 0.5 then
        lastESPUpdate = tick()
        UpdateESP()
        UpdateESPExits()
    end
end

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        espCache = {}
        UpdateESP()
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        espCache = {}
        UpdateESP()
    end)
    UpdateESP()
end)

game.Players.PlayerRemoving:Connect(function()
    espCache = {}
    UpdateESP()
end)

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    espCache = {}
    UpdateESP()
end)

-- FLY
local function UpdateFly()
    if settings.Fly then
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = RunService.RenderStepped:Connect(function()
            if not settings.Fly or not lp.Character then return end
            local root = lp.Character.HumanoidRootPart
            if not root then return end
            local bg = root:FindFirstChild("BodyGyro") or Instance.new("BodyGyro")
            local bv = root:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
            bg.P = 9e4; bg.Parent = root; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = root.CFrame
            bv.Parent = root; bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.Velocity = Vector3.new(0,0,0)
            lp.Character.Humanoid.PlatformStand = true
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0,-1,0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            local cam = workspace.CurrentCamera
            bv.Velocity = (cam.CFrame.LookVector * moveDir.Z + cam.CFrame.RightVector * moveDir.X + cam.CFrame.UpVector * moveDir.Y) * settings.flySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = lp.Character.HumanoidRootPart
            local bg = root:FindFirstChild("BodyGyro"); if bg then bg:Destroy() end
            local bv = root:FindFirstChild("BodyVelocity"); if bv then bv:Destroy() end
            lp.Character.Humanoid.PlatformStand = false
        end
    end
end

-- AUTO LOOT
local function AutoCollectLoot()
    local map = FindMap()
    if not map then return end
    local lootFolder = map:FindFirstChild("LootSpawns")
    if not lootFolder then return end

    local lootList = {}
    for _, child in ipairs(lootFolder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(lootList, child)
        end
    end
    if #lootList == 0 then return end

    local myPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position or Vector3.new()
    table.sort(lootList, function(a, b)
        return (a.Position - myPos).Magnitude < (b.Position - myPos).Magnitude
    end)

    if savedHomePosition == nil and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        savedHomePosition = lp.Character.HumanoidRootPart.CFrame
        notif("Home position saved", 2)
    end

    for _, lootPart in ipairs(lootList) do
        if not settings.AutoLoot then break end
        if lootPart and lootPart.Parent and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(lootPart.Position + Vector3.new(0, 3, 0))
            task.wait(0.25)
        end
    end
end

local function ReturnToHome()
    if savedHomePosition and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = savedHomePosition
        savedHomePosition = nil
    end
end

-- TELEPORT TO EXIT
local function TeleportToExit()
    local map = FindMap()
    if not map then
        for _, child in ipairs(workspace:GetChildren()) do
            if child:FindFirstChild("Exits") or child:FindFirstChild("ExitGateways") then
                map = child
                break
            end
        end
    end
    if not map then
        notif("Map not found!", 2)
        return false
    end
    
    local exitPosition = nil
    
    local exitsFolder = map:FindFirstChild("Exits")
    if exitsFolder then
        for _, gateway in ipairs(exitsFolder:GetChildren()) do
            if gateway.Name == "ExitGateway" then
                local trigger = gateway:FindFirstChild("Trigger")
                if trigger and trigger:IsA("BasePart") then
                    exitPosition = trigger.Position
                    break
                end
            end
        end
    end
    
    if not exitPosition then
        local exits = map:FindFirstChild("ExitGateways")
        if exits then
            for _, gateway in ipairs(exits:GetChildren()) do
                local trigger = gateway:FindFirstChild("Trigger")
                if trigger and trigger:IsA("BasePart") then
                    exitPosition = trigger.Position
                    break
                end
            end
        end
    end
    
    if not exitPosition then
        for _, child in ipairs(workspace:GetChildren()) do
            local trigger = child:FindFirstChild("Trigger")
            if trigger and trigger:IsA("BasePart") then
                exitPosition = trigger.Position
                break
            end
        end
    end
    
    if not exitPosition then
        notif("Exit not found!", 2)
        return false
    end
    
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = CFrame.new(exitPosition + Vector3.new(0, 3, 0))
        notif("Teleported to exit!", 2)
        return true
    else
        notif("Character not found!", 2)
        return false
    end
end

-- KILL AURA
local function KillAuraLoop()
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    if not isKiller then return end

    local closest = nil
    local minDist = math.huge
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local bleedOut = player.Character.HumanoidRootPart:FindFirstChild("BleedOutHealth")
                if not bleedOut or not bleedOut.Enabled then
                    local dist = (player.Character.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist and dist <= settings.killAuraRadius then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end

    if closest then
        local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
        closest.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
        task.wait(0.05)
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 0)
        task.wait()
        vim:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 0)
    end
end

-- KILL ALL
local function BringAndKillAll()
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    if not isKiller then
        notif("You are not killer!", 2)
        return
    end

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local bleedOut = player.Character.HumanoidRootPart:FindFirstChild("BleedOutHealth")
            if not bleedOut or not bleedOut.Enabled then
                local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
                player.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
                task.wait(0.05)
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 0)
                task.wait()
                vim:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 0)
            end
        end
    end
    notif("All killed", 2)
end

-- BRING
local function BringPlayer(name)
    local target = nil
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Name:lower():find(name:lower()) or player.DisplayName:lower():find(name:lower()) then
            target = player
            break
        end
    end
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
        target.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
        notif("Brought: " .. target.Name, 2)
    else
        notif("Player not found", 2)
    end
end

-- AUTO REVIVE (LEGIT)
local function isKillerNearby(position, radius)
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
            if isKiller then
                local dist = (player.Character.HumanoidRootPart.Position - position).Magnitude
                if dist <= radius then
                    return true
                end
            end
        end
    end
    return false
end

local function AutoReviveLegitLoop()
    if not settings.AutoReviveLegit then return end
    if isReviving then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = lp.Character.HumanoidRootPart
    local myBleedOut = myRoot:FindFirstChild("BleedOutHealth")
    if myBleedOut and myBleedOut.Enabled then return end
    
    if lp.Team then
        local teamName = lp.Team.Name:lower()
        if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
            return
        end
    end

    local closest = nil
    local minDist = math.huge
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
                if bleedOut and bleedOut.Enabled then
                    local dist = (rootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = {player = player, rootPart = rootPart, bleedOut = bleedOut}
                    end
                end
            end
        end
    end
    
    if closest then
        if isKillerNearby(closest.rootPart.Position, 15) then
            return
        end
        
        isReviving = true
        local myHomePos = lp.Character.HumanoidRootPart.CFrame
        
        local wasFlying = settings.Fly
        local wasNoclip = settings.Noclip
        if wasFlying then settings.Fly = false; UpdateFly() end
        if wasNoclip then settings.Noclip = false; if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end end
        
        local forward = closest.rootPart.CFrame.LookVector
        lp.Character.HumanoidRootPart.CFrame = closest.rootPart.CFrame + (forward * 2)
        task.wait(0.1)
        
        notif("Reviving (Legit): " .. closest.player.Name, 2)
        
        local bleedOut = closest.bleedOut
        local startTime = tick()
        while bleedOut and bleedOut.Enabled and (tick() - startTime) <= 15 do
            task.wait(0.5)
        end
        
        if bleedOut and not bleedOut.Enabled then
            notif(closest.player.Name .. " has been revived!", 2)
        else
            notif("Revive timeout for " .. closest.player.Name, 2)
        end
        
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = myHomePos
            notif("Returned to home", 2)
        end
        
        if wasFlying then settings.Fly = true; UpdateFly() end
        if wasNoclip then settings.Noclip = true; 
            if noclipConnection then noclipConnection:Disconnect() end
            noclipConnection = RunService.Stepped:Connect(function()
                if settings.Noclip and lp.Character then
                    for _, part in pairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
        
        isReviving = false
    end
end

-- AUTO REVIVE (RISKY)
local function AutoReviveRiskyOneUse()
    if isReviving then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
        notif("You need a character!", 2)
        return 
    end
    
    local myRoot = lp.Character.HumanoidRootPart
    local myBleedOut = myRoot:FindFirstChild("BleedOutHealth")
    if myBleedOut and myBleedOut.Enabled then
        notif("You are downed! Can't revive others.", 2)
        return
    end
    
    if lp.Team then
        local teamName = lp.Team.Name:lower()
        if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
            notif("You are in lobby!", 2)
            return
        end
    end

    local closest = nil
    local minDist = math.huge
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
                if bleedOut and bleedOut.Enabled then
                    if not (player.Team and (player.Team.Name:lower() == "lobby" or player.Team.TeamColor == BrickColor.new("White"))) then
                        local dist = (rootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closest = {player = player, rootPart = rootPart, bleedOut = bleedOut}
                        end
                    end
                end
            end
        end
    end
    
    if not closest then
        notif("No downed players found!", 2)
        return
    end
    
    local killerNearby = false
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
            if isKiller then
                local dist = (player.Character.HumanoidRootPart.Position - closest.rootPart.Position).Magnitude
                if dist <= 15 then
                    killerNearby = true
                    break
                end
            end
        end
    end
    
    if killerNearby then
        notif("Killer nearby! Risky revive cancelled.", 2)
        return
    end
    
    isReviving = true
    local myHomePos = lp.Character.HumanoidRootPart.CFrame
    
    local wasFlying = settings.Fly
    local wasNoclip = settings.Noclip
    if wasFlying then settings.Fly = false; UpdateFly() end
    if wasNoclip then 
        settings.Noclip = false
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    end
    
    local forward = closest.rootPart.CFrame.LookVector
    lp.Character.HumanoidRootPart.CFrame = closest.rootPart.CFrame + (forward * 2)
    task.wait(0.2)
    
    notif("RISKY Revive: picking up " .. closest.player.Name, 2)
    
    pressF()
    task.wait(0.3)
    
    if savedHomePosition then
        lp.Character.HumanoidRootPart.CFrame = savedHomePosition + Vector3.new(0, 0, 3)
    else
        lp.Character.HumanoidRootPart.CFrame = myHomePos
    end
    task.wait(0.3)
    
    pressF()
    task.wait(0.2)
    
    notif("RISKY Revive completed for " .. closest.player.Name, 2)
    
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = myHomePos
        notif("Returned to home", 2)
    end
    
    if wasFlying then settings.Fly = true; UpdateFly() end
    if wasNoclip then 
        settings.Noclip = true
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if settings.Noclip and lp.Character then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
    
    isReviving = false
end

-- AUTO REVIVE (SELF)
local function IsPlayerInLobby(player)
    if not player or not player.Team then return false end
    return player.Team.Name:lower() == "lobby" or player.Team.TeamColor == BrickColor.new("White")
end

local function AutoReviveSelfLoop()
    if not settings.AutoReviveSelf then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    if tick() - lastSelfReviveTime < settings.selfReviveCooldown then return end
    
    local myPos = lp.Character.HumanoidRootPart.Position
    local myBleedOut = lp.Character.HumanoidRootPart:FindFirstChild("BleedOutHealth")
    
    if myBleedOut and myBleedOut.Enabled then
        local target = nil
        
        if settings.selfReviveMode == "Farthest" then
            local farthestDist = -math.huge
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
                    if not isKiller and not IsPlayerInLobby(player) and not IsPlayerDowned(player) then
                        local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
                        if dist > farthestDist then
                            farthestDist = dist
                            target = player.Character.HumanoidRootPart
                        end
                    end
                end
            end
        else
            local survivors = {}
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
                    if not isKiller and not IsPlayerInLobby(player) and not IsPlayerDowned(player) then
                        table.insert(survivors, player.Character.HumanoidRootPart)
                    end
                end
            end
            if #survivors > 0 then
                target = survivors[math.random(1, #survivors)]
            end
        end
        
        if target then
            lp.Character.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 0, 5)
            lastSelfReviveTime = tick()
            notif("Self Revive: teleported to survivor", 2)
        elseif savedHomePosition then
            lp.Character.HumanoidRootPart.CFrame = savedHomePosition
            lastSelfReviveTime = tick()
            notif("Self Revive: teleported home", 2)
        else
            notif("Self Revive: no valid target found", 2)
        end
    end
end

-- AUTO ESCAPE
local function CheckTimerColors()
    local playerGui = lp:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local topBar = playerGui:FindFirstChild("TopBar")
    if not topBar then return false end
    
    local roundTimer = topBar:FindFirstChild("RoundTimer")
    if not roundTimer then return false end
    
    local extra = roundTimer:FindFirstChild("Extra")
    if not extra then return false end
    
    local gradient = extra:FindFirstChild("Gradient")
    if not gradient then return false end
    
    local uiGradient = gradient:FindFirstChild("UIGradient")
    if not uiGradient then
        uiGradient = gradient:FindFirstChild("UI Gradient")
    end
    if not uiGradient then return false end
    
    local color = uiGradient.Color
    if not color then return false end
    
    if color.Keypoints then
        for _, keypoint in ipairs(color.Keypoints) do
            local c = keypoint.Value
            local r = math.round(c.R * 10) / 10
            local g = math.round(c.G * 10) / 10
            local b = math.round(c.B * 10) / 10
            if not (r == 0 and g == 0 and b == 0) then
                return true
            end
        end
    end
    
    return false
end

local function AutoEscapeLoop()
    if not settings.AutoEscape then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    
    if not IsSurvivor() then return end
    
    if tick() - lastEscapeTime < 1 then return end
    
    local wasTimerActive = timerActive
    timerActive = CheckTimerColors()
    
    if timerActive ~= wasTimerActive then
        UpdateESPExits()
    end
    
    if timerActive then
        TeleportToExit()
        lastEscapeTime = tick()
    end
end

-- NO FOG
local function UpdateNoFog()
    if settings.NoFog then
        if noFogConnection then noFogConnection:Disconnect() end
        noFogConnection = RunService.Heartbeat:Connect(function()
            if settings.NoFog then
                Lighting.FogEnd = 100000
                for _, v in pairs(Lighting:GetDescendants()) do 
                    if v:IsA("Atmosphere") then v:Destroy() end 
                end
            end
        end)
    else
        if noFogConnection then noFogConnection:Disconnect(); noFogConnection = nil end
        Lighting.FogEnd = 1000
    end
end

local lastUpdate = 0
local function PeriodicUpdates()
    if tick() - lastUpdate >= 0.05 then
        lastUpdate = tick()
        if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            if settings.speedDisableOnDown and IsPlayerDowned(lp) then
                lp.Character.Humanoid.WalkSpeed = 16
            else
                lp.Character.Humanoid.WalkSpeed = settings.Speed
            end
        end
    end
    PeriodicESPUpdate()
end

function UpdateRightContent()
    ClearRightContent()
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = RightContent
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Position = UDim2.new(0.05, 0, 0, 5)
    scrollFrame.Size = UDim2.new(0.9, 0, 1, -10)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageTransparency = 0.7
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    if CurrentTab == "About" then
        local titleLabel = CreateLabel(scrollFrame, "VuaN | Survive the Killer", Color3.fromRGB(224, 58, 58))
        titleLabel.TextSize = 16; titleLabel.Font = Enum.Font.GothamBlack
        
        local versionLabel = CreateLabel(scrollFrame, "Version 1.4", Color3.fromRGB(150, 150, 170))
        versionLabel.TextSize = 10; versionLabel.Font = Enum.Font.Gotham
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(50,50,50))
        
        local changesHeader = CreateLabel(scrollFrame, "CHANGE LOG:", Color3.fromRGB(220, 220, 235))
        changesHeader.TextSize = 12; changesHeader.Font = Enum.Font.GothamBold
        
        local changes = {
            "V1.4 - Added Auto Escape, Added Speed Disable On Down, Added ESP Exits",
            "V1.4 - Fixed Teleport to Exit (now uses Trigger)",
            "V1.4 - Improved Revive (Risky) as one-use button",
            "V1.3 - UI redesign, Killer Chance X3 (gamepass bypass)",
            "V1.2 - Double Jump (gamepass bypass)",
            "V1.1 - Auto Revive (Legit, Risky, Self)",
            "V1 - Release"
        }
        for _, line in ipairs(changes) do
            local l = CreateLabel(scrollFrame, "  • " .. line, Color3.fromRGB(180, 180, 200))
            l.TextSize = 10; l.Font = Enum.Font.Gotham
        end
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(50,50,50))
        
        local credits = CreateLabel(scrollFrame, "Credits: VuaN", Color3.fromRGB(150, 150, 170))
        credits.TextSize = 10; credits.Font = Enum.Font.Gotham
        
    elseif CurrentTab == "Player" then
        CreateLabel(scrollFrame, "MOVEMENT", Color3.fromRGB(224, 58, 58))
        
        CreateToggle(scrollFrame, "Speed Hack", settings.speedEnabled, function(val)
            settings.speedEnabled = val
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val and settings.Speed or 16
            end
        end)
        CreateSlider(scrollFrame, "Speed Value", 16, 50, settings.Speed, function(val)
            settings.Speed = val
            if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val
            end
        end)
        
        CreateToggle(scrollFrame, "Disable Speed On Down", settings.speedDisableOnDown, function(val)
            settings.speedDisableOnDown = val
        end)
        
        CreateToggle(scrollFrame, "Fly", settings.Fly, function(val)
            settings.Fly = val
            UpdateFly()
        end)
        CreateSlider(scrollFrame, "Fly Speed", 20, 200, settings.flySpeed, function(val)
            settings.flySpeed = val
        end)
        
        CreateToggle(scrollFrame, "Noclip", settings.Noclip, function(val)
            settings.Noclip = val
            if val then
                if noclipConnection then noclipConnection:Disconnect() end
                noclipConnection = RunService.Stepped:Connect(function()
                    if settings.Noclip and lp.Character then
                        for _, part in pairs(lp.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            else
                if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
            end
        end)
        
        CreateToggle(scrollFrame, "Auto Escape", settings.AutoEscape, function(val)
            settings.AutoEscape = val
            if val then
                if autoEscapeConnection then autoEscapeConnection:Disconnect() end
                autoEscapeConnection = RunService.Heartbeat:Connect(AutoEscapeLoop)
            else
                if autoEscapeConnection then autoEscapeConnection:Disconnect(); autoEscapeConnection = nil end
            end
        end)
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(50,50,50))
        CreateLabel(scrollFrame, "GAMEPASS BYPASS", Color3.fromRGB(224, 58, 58))
        
        CreateToggle(scrollFrame, "Double Jump", settings.DoubleJump, function(val)
            settings.DoubleJump = val
            UpdateDoubleJump()
        end)
        
        CreateToggle(scrollFrame, "Killer Chance X3", settings.KillerChanceX3, function(val)
            settings.KillerChanceX3 = val
            UpdateKillerChance()
        end)
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(50,50,50))
        CreateLabel(scrollFrame, "COMBAT", Color3.fromRGB(224, 58, 58))
        
        CreateToggle(scrollFrame, "Kill Aura", settings.KillAura, function(val)
            settings.KillAura = val
            if val then
                if killAuraConnection then killAuraConnection:Disconnect() end
                killAuraConnection = RunService.Heartbeat:Connect(function()
                    if settings.KillAura and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 then
                        KillAuraLoop()
                    end
                end)
            else
                if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
            end
        end)
        CreateSlider(scrollFrame, "Kill Aura Radius", 8, 80, settings.killAuraRadius, function(val)
            settings.killAuraRadius = val
        end)
        
        CreateButton(scrollFrame, "Kill All", BringAndKillAll)
        
        local bringBox = CreateTextBox(scrollFrame, "Player name")
        CreateButton(scrollFrame, "Bring Player", function()
            if bringBox.Text ~= "" then BringPlayer(bringBox.Text) else notif("Enter name", 2) end
        end)
        
        CreateButton(scrollFrame, "Teleport to Exit", TeleportToExit)
        
    elseif CurrentTab == "World" then
        CreateLabel(scrollFrame, "VISUAL", Color3.fromRGB(224, 58, 58))
        
        CreateToggle(scrollFrame, "ESP Players", settings.ESP, function(val)
            settings.ESP = val
            espCache = {}
            UpdateESP()
        end)

        CreateToggle(scrollFrame, "ESP Exits", settings.ESPExits, function(val)
            settings.ESPExits = val
            UpdateESPExits()
        end)
        
        CreateToggle(scrollFrame, "No Fog", settings.NoFog, function(val)
            settings.NoFog = val
            UpdateNoFog()
        end)
        
        CreateToggle(scrollFrame, "Fullbright", settings.Fullbright, function(val)
            settings.Fullbright = val
            if val then
                if brightLoop then brightLoop:Disconnect() end
                brightLoop = RunService.RenderStepped:Connect(function()
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.GlobalShadows = false
                    Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
                end)
            else
                if brightLoop then brightLoop:Disconnect(); brightLoop = nil end
            end
        end)
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(50,50,50))
        CreateLabel(scrollFrame, "AUTO LOOT", Color3.fromRGB(224, 58, 58))
        
        CreateToggle(scrollFrame, "Auto Collect Loot", settings.AutoLoot, function(val)
            settings.AutoLoot = val
            if val then
                savedHomePosition = nil
                if lootConnection then lootConnection:Disconnect() end
                lootConnection = RunService.Heartbeat:Connect(function()
                    if settings.AutoLoot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        AutoCollectLoot()
                    end
                end)
            else
                if lootConnection then lootConnection:Disconnect(); lootConnection = nil end
                if settings.returnHomeAfterLoot then ReturnToHome() else savedHomePosition = nil end
            end
        end)
        
        CreateToggle(scrollFrame, "Return home after loot", settings.returnHomeAfterLoot, function(val)
            settings.returnHomeAfterLoot = val
        end)
        
    elseif CurrentTab == "Revive" then
        CreateLabel(scrollFrame, "REVIVE MODES", Color3.fromRGB(224, 58, 58))
        
        CreateToggle(scrollFrame, "Auto Revive (Legit)", settings.AutoReviveLegit, function(val)
            settings.AutoReviveLegit = val
            if val then
                if reviveLegitConnection then reviveLegitConnection:Disconnect() end
                reviveLegitConnection = RunService.Heartbeat:Connect(AutoReviveLegitLoop)
            else
                if reviveLegitConnection then reviveLegitConnection:Disconnect(); reviveLegitConnection = nil end
            end
        end)
        
        CreateButton(scrollFrame, "Revive (Risky) - One Use", function()
            AutoReviveRiskyOneUse()
        end)
        
        CreateLabel(scrollFrame, "", Color3.fromRGB(50,50,50))
        CreateLabel(scrollFrame, "SELF REVIVE", Color3.fromRGB(224, 58, 58))
        
        CreateToggle(scrollFrame, "Auto Revive (Self)", settings.AutoReviveSelf, function(val)
            settings.AutoReviveSelf = val
            if val then
                if selfReviveConnection then selfReviveConnection:Disconnect() end
                selfReviveConnection = RunService.Heartbeat:Connect(AutoReviveSelfLoop)
            else
                if selfReviveConnection then selfReviveConnection:Disconnect(); selfReviveConnection = nil end
            end
        end)
        
        CreateSlider(scrollFrame, "Self Revive Cooldown", 1, 10, settings.selfReviveCooldown, function(val)
            settings.selfReviveCooldown = val
        end)
        
        local function setSelfReviveMode(mode)
            settings.selfReviveMode = mode
            notif("Self Revive mode: " .. mode, 2)
        end
        
        CreateButton(scrollFrame, "Self Revive Mode: Random", function() setSelfReviveMode("Random") end)
        CreateButton(scrollFrame, "Self Revive Mode: Farthest", function() setSelfReviveMode("Farthest") end)
    end
end

local updateConnection = RunService.Stepped:Connect(PeriodicUpdates)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "ExitGateways" or descendant.Name == "Doorway" or descendant.Name == "Frame" then
        task.wait(0.5)
        UpdateESPExits()
    end
end)

workspace.DescendantRemoved:Connect(function()
    task.wait(0.5)
    UpdateESPExits()
end)

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if settings.speedEnabled and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = settings.Speed
    end
    espCache = {}
    UpdateESP()
    UpdateDoubleJump()
    UpdateKillerChance()
end)

UpdateNoFog()
UpdateESP()
UpdateESPExits()
UpdateDoubleJump()
UpdateKillerChance()
UpdateRightContent()

notif("VSTK V1.4 loaded", 3)
