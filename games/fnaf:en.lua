-- VuaN | FNAF: Eternal Night

local configs = {
    savedConfigs = {},
    currentConfigName = "Default"
}

local defaultSettings = {
    Speed = 16,
    speedEnabled = false,
    Fly = false,
    flySpeed = 50,
    ESPPlayers = false,
    ESPAnimatronics = false,
    ESPFuse = false,
    ESPBattery = false,
    ESPItems = false,
    ESPCoins = false,
    NoFog = false,
    Fullbright = false,
    AntiVoid = false,
}

local lp = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local ACCENT_COLOR = Color3.fromRGB(255, 165, 0)
local BG_MAIN = Color3.fromRGB(20, 20, 25)
local BG_PANEL = Color3.fromRGB(25, 25, 30)
local BG_ELEMENT = Color3.fromRGB(35, 35, 40)
local TEXT_PRIMARY = Color3.fromRGB(240, 240, 240)
local TEXT_SECONDARY = Color3.fromRGB(160, 160, 170)

local function notif(str, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "FNAF Eternal Night",
            Text = str,
            Duration = dur or 3
        })
    end)
end

local settings = {}
for k, v in pairs(defaultSettings) do
    settings[k] = v
end

local flyConnection = nil
local brightLoop = nil
local noFogConnection = nil
local espObjects = {}
local espCache = {}
local CurrentTab = "About"
local antiVoidConnection = nil
local lastESPUpdate = 0

local AnimatronicColors = {
    Bonnie = Color3.fromRGB(0, 0, 255),
    Chica = Color3.fromRGB(255, 255, 0),
    Foxy = Color3.fromRGB(255, 140, 0),
    Freddy = Color3.fromRGB(139, 69, 19),
    Puppet = Color3.fromRGB(128, 0, 255),
    BB = Color3.fromRGB(255, 165, 0),
    Mangle = Color3.fromRGB(255, 105, 180),
    ToyBonnie = Color3.fromRGB(0, 191, 255),
    ToyChica = Color3.fromRGB(255, 255, 100),
    ToyFreddy = Color3.fromRGB(200, 150, 50),
    ["Default"] = Color3.fromRGB(255, 0, 0)
}

local function TeleportToPuppet()
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
        notif("Character not found!", 2)
        return
    end
    local puppetPos = Vector3.new(-116.4, 3.8, -9.1)
    local lookVector = Vector3.new(-0.825, -0.56, 0.0722)
    lp.Character.HumanoidRootPart.CFrame = CFrame.new(puppetPos)
    workspace.CurrentCamera.CFrame = CFrame.new(puppetPos, puppetPos + lookVector)
    notif("Teleported to Puppet!", 2)
end

local function TeleportToSafe(pos)
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
        notif("Character not found!", 2)
        return
    end
    lp.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    notif("Teleported to Safe Place!", 2)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Z then
        settings.speedEnabled = not settings.speedEnabled
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = settings.speedEnabled and settings.Speed or 16
        end
        notif("Speed Hack: " .. (settings.speedEnabled and "ON" or "OFF"), 1.5)
    end
    
    if input.KeyCode == Enum.KeyCode.X then
        TeleportToPuppet()
    end
    
    if input.KeyCode == Enum.KeyCode.V then
        TeleportToSafe(Vector3.new(-235, 19, 212))
    end
end)

function UpdateAllFeatures()
    UpdateFly()
    
    if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = settings.Speed
    end

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
    
    if settings.Fullbright then
        if brightLoop then brightLoop:Disconnect() end
        brightLoop = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end)
    else
        if brightLoop then brightLoop:Disconnect(); brightLoop = nil end
    end
    
    espCache = {}
    UpdateESP()
    UpdateAntiVoid()
end

function UpdateESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    espObjects = {}

    if settings.ESPPlayers then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = player.Character
                highlight.FillTransparency = 1
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineTransparency = 0.2
                highlight.Parent = player.Character
                table.insert(espObjects, highlight)
            end
        end
    end

    if settings.ESPAnimatronics then
        local gameFolder = workspace:FindFirstChild("Game")
        if gameFolder then
            local animatronics = gameFolder:FindFirstChild("Animatronics")
            if animatronics then
                local mainFolder = animatronics:FindFirstChild("Animatronics")
                if mainFolder then
                    for _, child in ipairs(mainFolder:GetChildren()) do
                        if child:IsA("Model") then
                            local color = AnimatronicColors[child.Name] or AnimatronicColors["Default"]
                            local highlight = Instance.new("Highlight")
                            highlight.Adornee = child
                            highlight.FillTransparency = 0.8
                            highlight.FillColor = color
                            highlight.OutlineColor = color
                            highlight.OutlineTransparency = 0.1
                            highlight.Parent = child
                            table.insert(espObjects, highlight)
                        end
                    end
                end
                local toysFolder = animatronics:FindFirstChild("Toys")
                if toysFolder then
                    for _, child in ipairs(toysFolder:GetChildren()) do
                        if child:IsA("Model") then
                            local color = AnimatronicColors[child.Name] or AnimatronicColors["Default"]
                            local highlight = Instance.new("Highlight")
                            highlight.Adornee = child
                            highlight.FillTransparency = 0.8
                            highlight.FillColor = color
                            highlight.OutlineColor = color
                            highlight.OutlineTransparency = 0.1
                            highlight.Parent = child
                            table.insert(espObjects, highlight)
                        end
                    end
                end
            end
        end
    end

    if settings.ESPFuse then
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "Fuse" then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = child
                highlight.FillTransparency = 0.6
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineTransparency = 0.1
                highlight.Parent = child
                table.insert(espObjects, highlight)
            end
        end
    end

    if settings.ESPBattery then
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "Battery" then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = child
                highlight.FillTransparency = 0.6
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineTransparency = 0.1
                highlight.Parent = child
                table.insert(espObjects, highlight)
            end
        end
    end

    if settings.ESPItems then
        local itemNames = {"Megaphone", "Photo Camera", "Phillips screwdriver", "Pliers"}
        for _, itemName in ipairs(itemNames) do
            local item = workspace:FindFirstChild(itemName)
            if item then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = item
                highlight.FillTransparency = 0.5
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineTransparency = 0.1
                highlight.Parent = item
                table.insert(espObjects, highlight)
            end
        end
    end

    if settings.ESPCoins then
        local map = workspace:FindFirstChild("Map")
        if map then
            local coinsMap = map:FindFirstChild("CoinsMap")
            if coinsMap then
                for _, coin in ipairs(coinsMap:GetChildren()) do
                    if coin.Name == "Coin" then
                        local highlight = Instance.new("Highlight")
                        highlight.Adornee = coin
                        highlight.FillTransparency = 0.6
                        highlight.FillColor = Color3.fromRGB(255, 215, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
                        highlight.OutlineTransparency = 0.1
                        highlight.Parent = coin
                        table.insert(espObjects, highlight)
                    end
                end
            end
            
            local baus = map:FindFirstChild("Baus")
            if baus then
                local bauFolder = baus:FindFirstChild("Bau")
                if bauFolder then
                    local bauSubFolder = bauFolder:FindFirstChild("Bau")
                    if bauSubFolder then
                        for _, coin in ipairs(bauSubFolder:GetChildren()) do
                            local highlight = Instance.new("Highlight")
                            highlight.Adornee = coin
                            highlight.FillTransparency = 0.6
                            highlight.FillColor = Color3.fromRGB(255, 215, 0)
                            highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
                            highlight.OutlineTransparency = 0.1
                            highlight.Parent = coin
                            table.insert(espObjects, highlight)
                        end
                    end
                end
            end
        end
    end
end

local dynamicESPConnection = nil
local function StartDynamicESPUpdate()
    if dynamicESPConnection then return end
    dynamicESPConnection = RunService.Heartbeat:Connect(function()
        if settings.ESPFuse then
            for i = #espObjects, 1, -1 do
                local obj = espObjects[i]
                if obj and obj.Parent then
                    local parent = obj.Parent
                    if parent and parent.Name == "Fuse" then
                        pcall(function() obj:Destroy() end)
                        table.remove(espObjects, i)
                    end
                end
            end
            for _, child in ipairs(workspace:GetChildren()) do
                if child.Name == "Fuse" then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = child
                    highlight.FillTransparency = 0.6
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineTransparency = 0.1
                    highlight.Parent = child
                    table.insert(espObjects, highlight)
                end
            end
        end
        
        if settings.ESPItems then
            local itemNames = {"Megaphone", "Photo Camera", "Phillips screwdriver", "Pliers"}
            for i = #espObjects, 1, -1 do
                local obj = espObjects[i]
                if obj and obj.Parent then
                    local parent = obj.Parent
                    local isItem = false
                    for _, itemName in ipairs(itemNames) do
                        if parent and parent.Name == itemName then
                            isItem = true
                            break
                        end
                    end
                    if isItem then
                        pcall(function() obj:Destroy() end)
                        table.remove(espObjects, i)
                    end
                end
            end
            for _, itemName in ipairs(itemNames) do
                local item = workspace:FindFirstChild(itemName)
                if item then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = item
                    highlight.FillTransparency = 0.5
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                    highlight.OutlineTransparency = 0.1
                    highlight.Parent = item
                    table.insert(espObjects, highlight)
                end
            end
        end
        
        if settings.ESPCoins then
            for i = #espObjects, 1, -1 do
                local obj = espObjects[i]
                if obj and obj.Parent then
                    local parent = obj.Parent
                    if parent and (parent.Name == "Coin" or (parent.Parent and parent.Parent.Name == "Bau" and parent.Parent.Parent and parent.Parent.Parent.Name == "Bau")) then
                        pcall(function() obj:Destroy() end)
                        table.remove(espObjects, i)
                    end
                end
            end
            
            local map = workspace:FindFirstChild("Map")
            if map then
                local coinsMap = map:FindFirstChild("CoinsMap")
                if coinsMap then
                    for _, coin in ipairs(coinsMap:GetChildren()) do
                        if coin.Name == "Coin" then
                            local highlight = Instance.new("Highlight")
                            highlight.Adornee = coin
                            highlight.FillTransparency = 0.6
                            highlight.FillColor = Color3.fromRGB(255, 215, 0)
                            highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
                            highlight.OutlineTransparency = 0.1
                            highlight.Parent = coin
                            table.insert(espObjects, highlight)
                        end
                    end
                end
                
                local baus = map:FindFirstChild("Baus")
                if baus then
                    local bauFolder = baus:FindFirstChild("Bau")
                    if bauFolder then
                        local bauSubFolder = bauFolder:FindFirstChild("Bau")
                        if bauSubFolder then
                            for _, coin in ipairs(bauSubFolder:GetChildren()) do
                                local highlight = Instance.new("Highlight")
                                highlight.Adornee = coin
                                highlight.FillTransparency = 0.6
                                highlight.FillColor = Color3.fromRGB(255, 215, 0)
                                highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
                                highlight.OutlineTransparency = 0.1
                                highlight.Parent = coin
                                table.insert(espObjects, highlight)
                            end
                        end
                    end
                end
            end
        end
        
        if settings.ESPAnimatronics and tick() - lastESPUpdate >= 3 then
            lastESPUpdate = tick()
            for i = #espObjects, 1, -1 do
                local obj = espObjects[i]
                if obj and obj.Parent then
                    local parent = obj.Parent
                    if parent and parent:IsA("Model") then
                        local gameFolder = workspace:FindFirstChild("Game")
                        if gameFolder then
                            local animatronics = gameFolder:FindFirstChild("Animatronics")
                            if animatronics then
                                local mainFolder = animatronics:FindFirstChild("Animatronics")
                                if mainFolder and parent.Parent == mainFolder then
                                    pcall(function() obj:Destroy() end)
                                    table.remove(espObjects, i)
                                end
                                local toysFolder = animatronics:FindFirstChild("Toys")
                                if toysFolder and parent.Parent == toysFolder then
                                    pcall(function() obj:Destroy() end)
                                    table.remove(espObjects, i)
                                end
                            end
                        end
                    end
                end
            end
            
            local gameFolder = workspace:FindFirstChild("Game")
            if gameFolder then
                local animatronics = gameFolder:FindFirstChild("Animatronics")
                if animatronics then
                    local mainFolder = animatronics:FindFirstChild("Animatronics")
                    if mainFolder then
                        for _, child in ipairs(mainFolder:GetChildren()) do
                            if child:IsA("Model") then
                                local color = AnimatronicColors[child.Name] or AnimatronicColors["Default"]
                                local highlight = Instance.new("Highlight")
                                highlight.Adornee = child
                                highlight.FillTransparency = 0.8
                                highlight.FillColor = color
                                highlight.OutlineColor = color
                                highlight.OutlineTransparency = 0.1
                                highlight.Parent = child
                                table.insert(espObjects, highlight)
                            end
                        end
                    end
                    local toysFolder = animatronics:FindFirstChild("Toys")
                    if toysFolder then
                        for _, child in ipairs(toysFolder:GetChildren()) do
                            if child:IsA("Model") then
                                local color = AnimatronicColors[child.Name] or AnimatronicColors["Default"]
                                local highlight = Instance.new("Highlight")
                                highlight.Adornee = child
                                highlight.FillTransparency = 0.8
                                highlight.FillColor = color
                                highlight.OutlineColor = color
                                highlight.OutlineTransparency = 0.1
                                highlight.Parent = child
                                table.insert(espObjects, highlight)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function TeleportToSecurity(pos)
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
        notif("Character not found!", 2)
        return
    end
    lp.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    notif("Teleported to Security!", 2)
end

function UpdateFly()
    if settings.Fly then
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = RunService.RenderStepped:Connect(function()
            if not settings.Fly or not lp.Character then return end
            local root = lp.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local bg = root:FindFirstChild("BodyGyro") or Instance.new("BodyGyro")
            local bv = root:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
            bg.P = 9e4
            bg.Parent = root
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.CFrame = root.CFrame
            bv.Parent = root
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            lp.Character.Humanoid.PlatformStand = true
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0, -1, 0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            local cam = workspace.CurrentCamera
            bv.Velocity = (cam.CFrame.LookVector * moveDir.Z + cam.CFrame.RightVector * moveDir.X + cam.CFrame.UpVector * moveDir.Y) * settings.flySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = lp.Character.HumanoidRootPart
            local bg = root:FindFirstChild("BodyGyro")
            if bg then bg:Destroy() end
            local bv = root:FindFirstChild("BodyVelocity")
            if bv then bv:Destroy() end
            lp.Character.Humanoid.PlatformStand = false
        end
    end
end

function UpdateAntiVoid()
    if settings.AntiVoid then
        if antiVoidConnection then antiVoidConnection:Disconnect() end
        antiVoidConnection = RunService.Heartbeat:Connect(function()
            if not settings.AntiVoid then return end
            if not lp.Character then return end
            local root = lp.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if root.Position.Y < -17 then
                local safePos = Vector3.new(-235, 19, 212)
                root.CFrame = CFrame.new(safePos)
                notif("Anti-Void activated! Teleported to Safe Place!", 3)
            end
        end)
    else
        if antiVoidConnection then antiVoidConnection:Disconnect(); antiVoidConnection = nil end
    end
end

local h = Instance.new("ScreenGui")
h.Name = "FNAF_External_Night"
h.Parent = game:GetService("CoreGui")
h.ResetOnSpawn = false
h.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = h
Main.Active = true
Main.Draggable = true
Main.BackgroundColor3 = BG_MAIN
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -300, 0.3, 0)
Main.Size = UDim2.new(0, 600, 0, 500)

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = Main
TopBar.BackgroundColor3 = BG_PANEL
TopBar.BackgroundTransparency = 0.5
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.ClipsDescendants = true

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Size = UDim2.new(1, -30, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "FNAF: EXTERNAL NIGHT"
TitleLabel.TextColor3 = ACCENT_COLOR
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = TEXT_SECONDARY
CloseBtn.TextSize = 14
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = ACCENT_COLOR end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = TEXT_SECONDARY end)
CloseBtn.MouseButton1Click:Connect(function() h:Destroy() end)

local LeftMenu = Instance.new("ScrollingFrame")
LeftMenu.Name = "LeftMenu"
LeftMenu.Parent = Main
LeftMenu.BackgroundColor3 = BG_PANEL
LeftMenu.BackgroundTransparency = 0.3
LeftMenu.BorderSizePixel = 0
LeftMenu.Position = UDim2.new(0, 0, 0, 40)
LeftMenu.Size = UDim2.new(0, 150, 1, -40)
LeftMenu.ScrollBarThickness = 0
LeftMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftMenu.AutomaticCanvasSize = Enum.AutomaticSize.Y

local menuPadding = Instance.new("UIPadding")
menuPadding.Parent = LeftMenu
menuPadding.PaddingLeft = UDim.new(0, 10)
menuPadding.PaddingTop = UDim.new(0, 8)
Instance.new("UIListLayout", LeftMenu).Padding = UDim.new(0, 5)

local MenuItems = {"  About", "  Player", "  Visuals", "  Teleports", "  Settings"}
local MenuButtons = {}

for i, item in ipairs(MenuItems) do
    local btn = Instance.new("TextButton")
    btn.Parent = LeftMenu
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.LayoutOrder = i
    btn.Font = Enum.Font.GothamBold
    btn.Text = item
    btn.TextColor3 = TEXT_SECONDARY
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Position = UDim2.new(0, 15, 0, 0)
    
    local indicator = Instance.new("Frame")
    indicator.Parent = btn
    indicator.BackgroundColor3 = ACCENT_COLOR
    indicator.BorderSizePixel = 0
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)
    indicator.Visible = false
    
    local tabName = item
    btn.MouseButton1Click:Connect(function()
        CurrentTab = tabName
        for _, b in pairs(MenuButtons) do
            b.TextColor3 = TEXT_SECONDARY
            b:FindFirstChildWhichIsA("Frame").Visible = false
        end
        btn.TextColor3 = TEXT_PRIMARY
        indicator.Visible = true
        UpdateRightContent()
    end)
    table.insert(MenuButtons, btn)
end

MenuButtons[1].TextColor3 = TEXT_PRIMARY
MenuButtons[1]:FindFirstChildWhichIsA("Frame").Visible = true

local RightContent = Instance.new("ScrollingFrame")
RightContent.Name = "RightContent"
RightContent.Parent = Main
RightContent.BackgroundColor3 = BG_MAIN
RightContent.BackgroundTransparency = 0.2
RightContent.BorderSizePixel = 0
RightContent.Position = UDim2.new(0, 150, 0, 40)
RightContent.Size = UDim2.new(1, -150, 1, -40)
RightContent.ScrollBarThickness = 4
RightContent.ScrollBarImageColor3 = ACCENT_COLOR
RightContent.CanvasSize = UDim2.new(0, 0, 0, 0)
RightContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
RightContent.ClipsDescendants = true

local padding = Instance.new("UIPadding")
padding.Parent = RightContent
padding.PaddingLeft = UDim.new(0, 20)
padding.PaddingRight = UDim.new(0, 20)
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 20)

local ContentLayout = Instance.new("UIListLayout", RightContent)
ContentLayout.Padding = UDim.new(0, 25)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Parent = parent
    section.BackgroundTransparency = 1
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.LayoutOrder = #parent:GetChildren()
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = section
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = ACCENT_COLOR
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local itemsContainer = Instance.new("Frame")
    itemsContainer.Parent = section
    itemsContainer.BackgroundTransparency = 1
    itemsContainer.Position = UDim2.new(0, 0, 0, 25)
    itemsContainer.Size = UDim2.new(1, 0, 0, 0)
    itemsContainer.AutomaticSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout", itemsContainer)
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    return itemsContainer
end

local function CreateToggle(parent, text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.LayoutOrder = #parent:GetChildren()

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -45, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBg = Instance.new("Frame")
    toggleBg.Parent = frame
    toggleBg.BorderSizePixel = 0
    toggleBg.Position = UDim2.new(1, -36, 0.5, -9)
    toggleBg.Size = UDim2.new(0, 36, 0, 18)
    toggleBg.BackgroundColor3 = defaultValue and ACCENT_COLOR or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

    local toggleKnob = Instance.new("Frame")
    toggleKnob.Parent = toggleBg
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Position = defaultValue and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    toggleKnob.Size = UDim2.new(0, 14, 0, 14)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)
    
    local knobTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local state = defaultValue
    local clickArea = Instance.new("TextButton")
    clickArea.Parent = frame
    clickArea.BackgroundTransparency = 1
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.Text = ""
    
    clickArea.MouseButton1Click:Connect(function()
        state = not state
        toggleBg.BackgroundColor3 = state and ACCENT_COLOR or Color3.fromRGB(60, 60, 70)
        TweenService:Create(toggleKnob, knobTweenInfo, {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
        callback(state)
    end)
    
    return frame
end

local function CreateButton(parent, text, callback, size)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BorderSizePixel = 0
    btn.Size = size or UDim2.new(1, 0, 0, 32)
    btn.LayoutOrder = #parent:GetChildren()
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = TEXT_PRIMARY
    btn.TextSize = 12
    btn.BackgroundColor3 = BG_ELEMENT
    btn.TextXAlignment = Enum.TextXAlignment.Center
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() 
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55) 
    end)
    btn.MouseLeave:Connect(function() 
        btn.BackgroundColor3 = BG_ELEMENT 
    end)
    return btn
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.LayoutOrder = #parent:GetChildren()

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -45, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -40, 0, 0)
    valueLabel.Size = UDim2.new(0, 35, 0, 18)
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
    Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderTrack
    sliderFill.BorderSizePixel = 0
    sliderFill.BackgroundColor3 = ACCENT_COLOR
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Parent = sliderTrack
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Text = ""
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
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

local function CreateLabel(parent, text, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 22)
    label.LayoutOrder = #parent:GetChildren()
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color or TEXT_PRIMARY
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function ClearRightContent()
    for _, child in pairs(RightContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("ScrollingFrame") then 
            child:Destroy() 
        end
    end
end

function UpdateRightContent()
    ClearRightContent()
    
    if CurrentTab == "  About" then
        local aboutSection = CreateSection(RightContent, "INFORMATION")
        CreateLabel(aboutSection, "FNAF: External Night Cheat", ACCENT_COLOR).TextSize = 16
        CreateLabel(aboutSection, "Version V1.3", TEXT_SECONDARY).TextSize = 11
        
        CreateLabel(aboutSection, "", Color3.fromRGB(50,50,50))
        
        local keybindsHeader = CreateLabel(aboutSection, "KEYBINDS:", TEXT_PRIMARY)
        keybindsHeader.TextSize = 12
        
        local keybinds = {
            "Z - Toggle Speed Hack",
            "X - Teleport to Puppet",
            "V - Teleport to Safe Place"
        }
        for _, line in ipairs(keybinds) do
            local l = CreateLabel(aboutSection, "  • " .. line, Color3.fromRGB(255, 200, 0))
            l.TextSize = 10
            l.Font = Enum.Font.Gotham
        end
        
        CreateLabel(aboutSection, "", Color3.fromRGB(50,50,50))
        
        local changesHeader = CreateLabel(aboutSection, "CHANGE LOG:", TEXT_PRIMARY)
        changesHeader.TextSize = 12
        
        local changes = {
            "V1.3 - update",
            " - Added ESP Coins (gold highlight)",
            " - Added ESP Pliers to Items",
            " - Updated Security teleport coords",
            " - Updated Safe Place teleport coords",
            " - Added Anti-Void toggle",
            " - Added V keybind for Safe Place teleport",
            " - Faster speed updates",
            " - Animatronics ESP updates every 3 seconds",
            "V1.2 - update",
            " - Added ESP Items (green highlight)",
            " - Added keybind Z for speed toggle",
            " - Added keybind X for puppet teleport",
            "V1.0 - release",
            " - ESP Players",
            " - ESP Animatronics (colored)",
            " - ESP Fuse",
            " - ESP Battery",
            " - No Fog",
            " - Fullbright",
            " - Speed hack with slider"
        }
        for _, line in ipairs(changes) do
            local l = CreateLabel(aboutSection, "  • " .. line, Color3.fromRGB(180, 180, 200))
            l.TextSize = 10
            l.Font = Enum.Font.Gotham
        end
        
        CreateLabel(aboutSection, "", Color3.fromRGB(50,50,50))
        CreateLabel(aboutSection, "Credits: VuaN", TEXT_SECONDARY).TextSize = 10
        
    elseif CurrentTab == "  Player" then
        local movementSection = CreateSection(RightContent, "MOVEMENT")
        
        CreateLabel(movementSection, "Keybinds: Z - Speed | X - Puppet TP | V - Safe TP", Color3.fromRGB(255, 200, 0))
        
        CreateToggle(movementSection, "Speed Hack", settings.speedEnabled, function(val)
            settings.speedEnabled = val
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val and settings.Speed or 16
            end
        end)
        CreateSlider(movementSection, "Speed Value", 16, 50, settings.Speed, function(val)
            settings.Speed = val
            if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val
            end
        end)
        CreateToggle(movementSection, "Fly", settings.Fly, function(val)
            settings.Fly = val
            UpdateFly()
        end)
        CreateSlider(movementSection, "Fly Speed", 20, 200, settings.flySpeed, function(val)
            settings.flySpeed = val
        end)
        
        local antiVoidSection = CreateSection(RightContent, "ANTI-VOID")
        CreateToggle(antiVoidSection, "Anti-Void (TP to Safe on fall)", settings.AntiVoid, function(val)
            settings.AntiVoid = val
            UpdateAntiVoid()
        end)
        CreateLabel(antiVoidSection, "Teleports you to Safe Place if falling below Y=-17", Color3.fromRGB(255, 200, 0))
        
    elseif CurrentTab == "  Visuals" then
        local espSection = CreateSection(RightContent, "ESP")
        CreateToggle(espSection, "ESP Players", settings.ESPPlayers, function(val)
            settings.ESPPlayers = val
            UpdateESP()
        end)
        CreateToggle(espSection, "ESP Animatronics", settings.ESPAnimatronics, function(val)
            settings.ESPAnimatronics = val
            UpdateESP()
        end)
        CreateToggle(espSection, "ESP Fuse", settings.ESPFuse, function(val)
            settings.ESPFuse = val
            if val then
                StartDynamicESPUpdate()
            else
                if not settings.ESPItems and not settings.ESPCoins and dynamicESPConnection then
                    dynamicESPConnection:Disconnect()
                    dynamicESPConnection = nil
                end
                for i = #espObjects, 1, -1 do
                    local obj = espObjects[i]
                    if obj and obj.Parent then
                        local parent = obj.Parent
                        if parent and parent.Name == "Fuse" then
                            pcall(function() obj:Destroy() end)
                            table.remove(espObjects, i)
                        end
                    end
                end
            end
        end)
        CreateToggle(espSection, "ESP Battery", settings.ESPBattery, function(val)
            settings.ESPBattery = val
            UpdateESP()
        end)
        CreateToggle(espSection, "ESP Items", settings.ESPItems, function(val)
            settings.ESPItems = val
            if val then
                StartDynamicESPUpdate()
            else
                if not settings.ESPFuse and not settings.ESPCoins and dynamicESPConnection then
                    dynamicESPConnection:Disconnect()
                    dynamicESPConnection = nil
                end
                for i = #espObjects, 1, -1 do
                    local obj = espObjects[i]
                    if obj and obj.Parent then
                        local parent = obj.Parent
                        local itemNames = {"Megaphone", "Photo Camera", "Phillips screwdriver", "Pliers"}
                        local isItem = false
                        for _, itemName in ipairs(itemNames) do
                            if parent and parent.Name == itemName then
                                isItem = true
                                break
                            end
                        end
                        if isItem then
                            pcall(function() obj:Destroy() end)
                            table.remove(espObjects, i)
                        end
                    end
                end
            end
        end)
        CreateToggle(espSection, "ESP Coins", settings.ESPCoins, function(val)
            settings.ESPCoins = val
            if val then
                StartDynamicESPUpdate()
            else
                if not settings.ESPFuse and not settings.ESPItems and dynamicESPConnection then
                    dynamicESPConnection:Disconnect()
                    dynamicESPConnection = nil
                end
                for i = #espObjects, 1, -1 do
                    local obj = espObjects[i]
                    if obj and obj.Parent then
                        local parent = obj.Parent
                        if parent and (parent.Name == "Coin" or (parent.Parent and parent.Parent.Name == "Bau")) then
                            pcall(function() obj:Destroy() end)
                            table.remove(espObjects, i)
                        end
                    end
                end
            end
        end)
        
        local visualSection = CreateSection(RightContent, "VISUAL")
        CreateButton(visualSection, "No Fog", function()
            settings.NoFog = not settings.NoFog
            UpdateAllFeatures()
            notif("No Fog: " .. (settings.NoFog and "Enabled" or "Disabled"), 2)
        end)
        CreateButton(visualSection, "Fullbright", function()
            settings.Fullbright = not settings.Fullbright
            UpdateAllFeatures()
            notif("Fullbright: " .. (settings.Fullbright and "Enabled" or "Disabled"), 2)
        end)
        
    elseif CurrentTab == "  Teleports" then
        local teleportSection = CreateSection(RightContent, "TELEPORT LOCATIONS")
        
        CreateLabel(teleportSection, "Keybinds: X - Puppet | V - Safe Place", Color3.fromRGB(255, 200, 0))
        CreateLabel(teleportSection, "", Color3.fromRGB(50,50,50))
        
        CreateButton(teleportSection, "Teleport to Puppet [X]", function()
            TeleportToPuppet()
        end)
        
        CreateButton(teleportSection, "Teleport to Security", function()
            TeleportToSecurity(Vector3.new(-213, 3, 157))
        end)
        
        CreateButton(teleportSection, "Teleport to Safe Place [V]", function()
            TeleportToSafe(Vector3.new(-235, 19, 212))
        end)
        
    elseif CurrentTab == "  Settings" then
        local infoSection = CreateSection(RightContent, "KEYBINDS")
        CreateLabel(infoSection, "Z - Toggle Speed Hack", Color3.fromRGB(255, 200, 0))
        CreateLabel(infoSection, "X - Teleport to Puppet", Color3.fromRGB(255, 200, 0))
        CreateLabel(infoSection, "V - Teleport to Safe Place", Color3.fromRGB(255, 200, 0))
        
        CreateLabel(infoSection, "", Color3.fromRGB(50,50,50))
        
        local infoSection2 = CreateSection(RightContent, "INFORMATION")
        CreateLabel(infoSection2, "Settings are saved automatically", TEXT_SECONDARY)
        CreateLabel(infoSection2, "", Color3.fromRGB(50,50,50))
        
        local footerFrame = Instance.new("Frame")
        footerFrame.Parent = RightContent
        footerFrame.BackgroundTransparency = 1
        footerFrame.Size = UDim2.new(1, 0, 0, 40)
        footerFrame.LayoutOrder = 999999

        local footerLabel1 = Instance.new("TextLabel")
        footerLabel1.Parent = footerFrame
        footerLabel1.BackgroundTransparency = 1
        footerLabel1.Size = UDim2.new(1, 0, 0, 20)
        footerLabel1.Position = UDim2.new(0, 0, 0, 10)
        footerLabel1.Font = Enum.Font.GothamBold
        footerLabel1.Text = "FNAF: External Night by VuaN"
        footerLabel1.TextColor3 = TEXT_SECONDARY
        footerLabel1.TextSize = 11
        footerLabel1.TextXAlignment = Enum.TextXAlignment.Center

        local footerLabel2 = Instance.new("TextLabel")
        footerLabel2.Parent = footerFrame
        footerLabel2.BackgroundTransparency = 1
        footerLabel2.Size = UDim2.new(1, 0, 0, 20)
        footerLabel2.Position = UDim2.new(0, 0, 0, 25)
        footerLabel2.Font = Enum.Font.GothamBold
        footerLabel2.Text = "Thanks you ❤"
        footerLabel2.TextColor3 = ACCENT_COLOR
        footerLabel2.TextSize = 11
        footerLabel2.TextXAlignment = Enum.TextXAlignment.Center
    end
end

local lastUpdate = 0
local function PeriodicUpdates()
    if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = settings.Speed
    end
end

local updateConnection = RunService.Heartbeat:Connect(PeriodicUpdates)

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if settings.speedEnabled and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = settings.Speed
    end
    espCache = {}
    UpdateESP()
end)

UpdateAllFeatures()
UpdateRightContent()

notif("FNAF External Night loaded", 3)
