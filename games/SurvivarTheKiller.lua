-- VuaN | Survive the Killer V2
-- Support version v2.31.0

local configs = {
    savedConfigs = {},
    currentConfigName = "Default"
}

local defaultSettings = {
    Speed = 16, 
    speedEnabled = false,
    speedDisableOnDown = true,
    Fly = false, 
    flySpeed = 50,
    Noclip = false,
    DoubleJump = false,
    KillerChanceX3 = false,
    ESP = false,
    ESPExits = false,
    ESPTraps = false,
    NoFog = false,
    Fullbright = false,
    AutoLoot = false,
    returnHomeAfterLoot = true,
    KillAura = false,
    killAuraRadius = 10,
    AutoReviveLegit = false,
    AutoReviveRisky = false,
    AutoReviveSelf = false,
    selfReviveCooldown = 7,
    selfReviveMode = "Random",
    AutoEscape = false,
    AntiAFK = false,
    AntiTrap = false,
    PanicTP = false
}


--	  SkinChanger = false,
--    SelectedKnife = "",
--    SelectedCostume = ""

local userScripts = {}

local function LoadUserScripts()
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile("VuaN_Scripts.json"))
    end)
    if success and data then
        userScripts = data
    end
end

local function SaveUserScripts()
    pcall(function()
        writefile("VuaN_Scripts.json", game:GetService("HttpService"):JSONEncode(userScripts))
    end)
end

LoadUserScripts()

local more_scripts = {
    {
        name = "VSTK V1.4",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/AuriXDev/VHubs/refs/heads/main/old/STK_V1_4.lua'))()"
    },
    {
        name = "Infinite Yield",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()"
    }
}

local lp = game:FindService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local ACCENT_COLOR = Color3.fromRGB(224, 58, 58)
local BG_MAIN = Color3.fromRGB(20, 20, 25)
local BG_PANEL = Color3.fromRGB(25, 25, 30)
local BG_ELEMENT = Color3.fromRGB(35, 35, 40)
local TEXT_PRIMARY = Color3.fromRGB(240, 240, 240)
local TEXT_SECONDARY = Color3.fromRGB(160, 160, 170)

local function notif(str, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "VSTK V2",
            Text = str,
            Duration = dur or 3
        })
    end)
end

local settings = {}
for k, v in pairs(defaultSettings) do
    settings[k] = v
end

local spinActive = false
local spinSpeed = 20
local bringActive = false
local FlingActive = false
local viewing = nil
local viewDied = nil
local viewChanged = nil
local flyConnection = nil
local noclipConnection = nil
local brightLoop = nil
local lootConnection = nil
local killAuraConnection = nil
local reviveLegitConnection = nil
local selfReviveConnection = nil
local autoEscapeConnection = nil
local noFogConnection = nil
local antiAFKConnection = nil
local antiTrapConnection = nil
local panicTPConnection = nil
local espObjects = {}
local espExitObjects = {}
local espTrapObjects = {}
local savedHomePosition = nil
local isReviving = false
local lastSelfReviveTime = 0
local espCache = {}
local CurrentTab = "About"
local lastEscapeTime = 0
local timerActive = false
local panicTPCooldown = 0











-- SKINCHANGER (in dev)

local skinChangerConnection = nil
local availableKnives = {}
local availableCostumes = {}
local knifeDropdown = nil
local costumeDropdown = nil
local skinChangerToggle = nil

local function LoadSkinLists()
    availableKnives = {}
    availableCostumes = {}
    local knivesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
    if knivesFolder then
        local gameFolder = knivesFolder:FindFirstChild("Game")
        if gameFolder then
            local knives = gameFolder:FindFirstChild("Knives")
            if knives then
                for _, child in ipairs(knives:GetChildren()) do
                    if child:IsA("MeshPart") then
                        table.insert(availableKnives, child.Name)
                    end
                end
                table.sort(availableKnives)
            end

            local killers = gameFolder:FindFirstChild("Killers")
            if killers then
                for _, child in ipairs(killers:GetChildren()) do
                    if child:IsA("Model") or child:IsA("Folder") then
                        table.insert(availableCostumes, child.Name)
                    end
                end
                table.sort(availableCostumes)
            end
        end
    end
end

local function ApplySkin()
    if not settings.SkinChanger then return end
    if not lp then return end

    if settings.SelectedKnife ~= "" then
        lp:SetAttribute("EquippedKnife", settings.SelectedKnife)
        lp:SetAttribute("CurrentKnife", settings.SelectedKnife)
    end
    if settings.SelectedCostume ~= "" then
        lp:SetAttribute("KillerCostumeHitTag", settings.SelectedCostume)
        lp:SetAttribute("CurrentCostume", settings.SelectedCostume)
    end
end

local function UpdateSkinChanger()
    if settings.SkinChanger then
        if skinChangerConnection then skinChangerConnection:Disconnect() end
        skinChangerConnection = RunService.Heartbeat:Connect(function()
            if settings.SkinChanger then
                ApplySkin()
            end
        end)
    else
        if skinChangerConnection then
            skinChangerConnection:Disconnect()
            skinChangerConnection = nil
        end
    end
end














local function SaveConfig(name)
    local configData = {}
    for k, v in pairs(settings) do
        configData[k] = v
    end
    configData.userScripts = userScripts
    
    local configsFolder = "VuaN_Configs"
    if not isfolder(configsFolder) then
        makefolder(configsFolder)
    end
    
    local success, err = pcall(function()
        writefile(configsFolder .. "/" .. name .. ".json", HttpService:JSONEncode(configData))
    end)
    
    if success then
        notif("Config saved: " .. name, 2)
        return true
    else
        notif("Failed to save config: " .. tostring(err), 3)
        return false
    end
end

local function LoadConfig(name)
    local configsFolder = "VuaN_Configs"
    if not isfolder(configsFolder) then
        notif("No configs folder found", 2)
        return false
    end
    
    local success, data = pcall(function()
        local content = readfile(configsFolder .. "/" .. name .. ".json")
        return HttpService:JSONDecode(content)
    end)
    
    if success and data then
        for k, v in pairs(data) do
            if k ~= "userScripts" then
                settings[k] = v
            end
        end
        
        if data.userScripts then
            userScripts = data.userScripts
            SaveUserScripts()
        end
        
        UpdateAllFeatures()
        notif("Config loaded: " .. name, 2)
        return true
    else
        notif("Failed to load config: " .. tostring(success and "Invalid data" or "File not found"), 3)
        return false
    end
end

local function GetConfigList()
    local configsFolder = "VuaN_Configs"
    if not isfolder(configsFolder) then
        makefolder(configsFolder)
        return {}
    end
    
    local files = {}
    for _, file in ipairs(listfiles(configsFolder)) do
        local name = file:match("([^/]+)%.json$")
        if name then
            table.insert(files, name)
        end
    end
    return files
end

local function DeleteConfig(name)
    local configsFolder = "VuaN_Configs"
    if isfolder(configsFolder) then
        pcall(function()
            delfile(configsFolder .. "/" .. name .. ".json")
            notif("Config deleted: " .. name, 2)
        end)
    end
end

function UpdateAllFeatures()
    if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = settings.Speed
    end
    
    UpdateFly()
    
    if settings.Noclip then
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
    
    UpdateDoubleJump()
    UpdateKillerChance()
    espCache = {}
    UpdateESP()
    UpdateESPExits()
    UpdateESPTraps()
    UpdateNoFog()
    
    if settings.Fullbright then
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
    
    if settings.AutoLoot then
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
    
    if settings.KillAura then
        if killAuraConnection then killAuraConnection:Disconnect() end
        killAuraConnection = RunService.Heartbeat:Connect(function()
            if settings.KillAura and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 then
                KillAuraLoop()
            end
        end)
    else
        if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
    end
    
    if settings.AutoReviveLegit then
        if reviveLegitConnection then reviveLegitConnection:Disconnect() end
        reviveLegitConnection = RunService.Heartbeat:Connect(AutoReviveLegitLoop)
    else
        if reviveLegitConnection then reviveLegitConnection:Disconnect(); reviveLegitConnection = nil end
    end
    
    if settings.AutoReviveSelf then
        if selfReviveConnection then selfReviveConnection:Disconnect() end
        selfReviveConnection = RunService.Heartbeat:Connect(AutoReviveSelfLoop)
    else
        if selfReviveConnection then selfReviveConnection:Disconnect(); selfReviveConnection = nil end
    end
    
    if settings.AutoEscape then
        if autoEscapeConnection then autoEscapeConnection:Disconnect() end
        autoEscapeConnection = RunService.Heartbeat:Connect(AutoEscapeLoop)
    else
        if autoEscapeConnection then autoEscapeConnection:Disconnect(); autoEscapeConnection = nil end
    end
    
    if settings.AntiAFK then
        if antiAFKConnection then antiAFKConnection:Disconnect() end
        antiAFKConnection = RunService.Heartbeat:Connect(function()
            if settings.AntiAFK then
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                task.wait(15)
            end
        end)
    else
        if antiAFKConnection then antiAFKConnection:Disconnect(); antiAFKConnection = nil end
    end
    
    if settings.AntiTrap then
        if antiTrapConnection then antiTrapConnection:Disconnect() end
        antiTrapConnection = RunService.Heartbeat:Connect(function()
            if settings.AntiTrap then
                RemoveTraps()
            end
        end)
    else
        if antiTrapConnection then antiTrapConnection:Disconnect(); antiTrapConnection = nil end
    end
    
    if settings.PanicTP then
        if panicTPConnection then panicTPConnection:Disconnect() end
        panicTPConnection = RunService.Heartbeat:Connect(function()
            if settings.PanicTP then
                CheckPanicTP()
            end
        end)
    else
        if panicTPConnection then panicTPConnection:Disconnect(); panicTPConnection = nil end
    end

    if settings.SkinChanger then
        if skinChangerConnection then skinChangerConnection:Disconnect() end
        skinChangerConnection = RunService.Heartbeat:Connect(function()
            if settings.SkinChanger then
                ApplySkin()
            end
        end)
    else
        if skinChangerConnection then
            skinChangerConnection:Disconnect()
            skinChangerConnection = nil
        end
    end
end

local function RemoveTraps()
    local traps = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Trap" then
            table.insert(traps, child)
        end
    end
    
    for _, trap in ipairs(traps) do
        local trigger = trap:FindFirstChild("HitBox")
        if trigger then
            pcall(function()
                trigger:Destroy()
            end)
        end
    end
end

local function FindLootPositions()
    local lootPositions = {}
    local map = FindMap()
    if not map then return lootPositions end
    
    local lootFolder = map:FindFirstChild("LootSpawns")
    if not lootFolder then return lootPositions end
    
    for _, child in ipairs(lootFolder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(lootPositions, child.Position)
        end
    end
    return lootPositions
end

local function CheckPanicTP()
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    if tick() - panicTPCooldown < 3 then return end
    
    local playerGui = lp:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local gameHUD = playerGui:FindFirstChild("GameHUD")
    if not gameHUD then return end
    
    local spottedEye = gameHUD:FindFirstChild("SpottedEye")
    if not spottedEye then return end
    
    if spottedEye.Visible == true then
        local lootPositions = {}
        local myPos = lp.Character.HumanoidRootPart.Position
        
        local map = nil
        for _, child in ipairs(workspace:GetChildren()) do
            if child:FindFirstChild("LootSpawns") then
                map = child
                break
            end
        end
        
        if map then
            local lootFolder = map:FindFirstChild("LootSpawns")
            if lootFolder then
                for _, child in ipairs(lootFolder:GetChildren()) do
                    if child:IsA("BasePart") then
                        table.insert(lootPositions, child.Position)
                    end
                end
            end
        end
        
        if #lootPositions == 0 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("loot") then
                    table.insert(lootPositions, obj.Position)
                end
            end
        end
        
        if #lootPositions > 0 then
            local farthestLoot = nil
            local farthestDist = -math.huge
            
            for _, pos in ipairs(lootPositions) do
                local dist = (pos - myPos).Magnitude
                if dist > farthestDist then
                    farthestDist = dist
                    farthestLoot = pos
                end
            end
            
            if farthestLoot then
                lp.Character.HumanoidRootPart.CFrame = CFrame.new(farthestLoot + Vector3.new(0, 3, 0))
                panicTPCooldown = tick()
                notif("Panic TP: Teleported to farthest loot!", 2)
            end
        end
    end
end

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

local function StartFling(targetName)
    local target = GetPlayerByName(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        if FlingActive then return end
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

local function AddUserScript(name, script)
    if name == "" or script == "" then
        notif("Name and script cannot be empty", 2)
        return false
    end
    
    for _, s in ipairs(userScripts) do
        if s.name:lower() == name:lower() then
            notif("Script with this name already exists", 2)
            return false
        end
    end
    
    local valid, err = SafeLoadScript(script)
    if not valid then
        notif("Invalid script: " .. tostring(err), 3)
        return false
    end
    
    table.insert(userScripts, {name = name, script = script})
    SaveUserScripts()
    UpdateRightContent()
    notif("Script added: " .. name, 2)
    return true
end

local function RemoveUserScript(index)
    if index > 0 and index <= #userScripts then
        local name = userScripts[index].name
        table.remove(userScripts, index)
        SaveUserScripts()
        UpdateRightContent()
        notif("Script removed: " .. name, 2)
        return true
    end
    return false
end

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

local function UpdateDoubleJump()
    SetSettingsAttribute("double_jump", settings.DoubleJump)
end

local function UpdateKillerChance()
    SetSettingsAttribute("killer_chance_3x", settings.KillerChanceX3)
end

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

local function UpdateESPTraps()
    for _, obj in pairs(espTrapObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    espTrapObjects = {}
    
    if not settings.ESPTraps then return end
    
    local traps = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Trap" then
            table.insert(traps, child)
        end
    end
    
    if #traps == 0 then return end
    
    local fillColor = Color3.fromRGB(255, 165, 0)
    local outlineColor = Color3.fromRGB(255, 140, 0)
    
    for _, trap in ipairs(traps) do
        local highlight = Instance.new("Highlight")
        highlight.Adornee = trap
        highlight.FillColor = fillColor
        highlight.FillTransparency = 0.3
        highlight.OutlineColor = outlineColor
        highlight.OutlineTransparency = 0.3
        highlight.Parent = trap
        table.insert(espTrapObjects, highlight)
        
        for _, part in ipairs(trap:GetDescendants()) do
            if part:IsA("BasePart") then
                local partHighlight = Instance.new("Highlight")
                partHighlight.Adornee = part
                partHighlight.FillColor = fillColor
                partHighlight.FillTransparency = 0.5
                partHighlight.OutlineColor = outlineColor
                partHighlight.OutlineTransparency = 0.2
                partHighlight.Parent = part
                table.insert(espTrapObjects, partHighlight)
            end
        end
    end
end

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
        UpdateESPTraps()
    end
end

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
            if settings.speedDisableOnDown and lp:GetAttribute("Crawling") == true then
                lp.Character.Humanoid.WalkSpeed = 10
            else
                lp.Character.Humanoid.WalkSpeed = settings.Speed
            end
        end
    end
    PeriodicESPUpdate()
end

local h = Instance.new("ScreenGui")
h.Name = "VuaN_STK"
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
TitleLabel.Text = "SURVIVE THE KILLER - V2"
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

local MenuItems = {"  About", "  Player", "  World", "  Skinchanger", "  Revive", "  Fun", "  More", "  Settings"}
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

local function CreateDropdown(parent, text, items, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.LayoutOrder = #parent:GetChildren()
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local dropdown = Instance.new("TextButton")
    dropdown.Parent = frame
    dropdown.BorderSizePixel = 0
    dropdown.Position = UDim2.new(0, 0, 0, 22)
    dropdown.Size = UDim2.new(1, 0, 0, 30)
    dropdown.BackgroundColor3 = BG_ELEMENT
    dropdown.Font = Enum.Font.Gotham
    dropdown.Text = default or "Select..."
    dropdown.TextColor3 = TEXT_PRIMARY
    dropdown.TextSize = 12
    dropdown.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 4)
    
    local padding = Instance.new("UIPadding")
    padding.Parent = dropdown
    padding.PaddingLeft = UDim.new(0, 10)
    
    local selected = default or ""
    local isOpen = false
    local dropdownFrame = nil
    
    local function CloseDropdown()
        if dropdownFrame then
            dropdownFrame:Destroy()
            dropdownFrame = nil
            isOpen = false
        end
    end
    
    dropdown.MouseButton1Click:Connect(function()
        if isOpen then
            CloseDropdown()
            return
        end
        
        isOpen = true
        dropdownFrame = Instance.new("Frame")
        dropdownFrame.Parent = frame
        dropdownFrame.BackgroundColor3 = BG_PANEL
        dropdownFrame.BorderSizePixel = 0
        dropdownFrame.Position = UDim2.new(0, 0, 0, 52)
        dropdownFrame.Size = UDim2.new(1, 0, 0, math.min(#items * 28 + 4, 200))
        dropdownFrame.ZIndex = 10
        Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 4)
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Parent = dropdownFrame
        scroll.BackgroundTransparency = 1
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.CanvasSize = UDim2.new(0, 0, 0, #items * 28)
        scroll.ScrollBarThickness = 4
        
        local listLayout = Instance.new("UIListLayout", scroll)
        listLayout.Padding = UDim.new(0, 1)
        
        for _, item in ipairs(items) do
            local btn = Instance.new("TextButton")
            btn.Parent = scroll
            btn.BackgroundTransparency = 0
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = BG_ELEMENT
            btn.Font = Enum.Font.Gotham
            btn.Text = item
            btn.TextColor3 = TEXT_PRIMARY
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.ZIndex = 11
            
            local pad = Instance.new("UIPadding")
            pad.Parent = btn
            pad.PaddingLeft = UDim.new(0, 10)
            
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 2)
            
            btn.MouseButton1Click:Connect(function()
                selected = item
                dropdown.Text = item
                callback(item)
                CloseDropdown()
            end)
            
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = BG_ELEMENT
            end)
        end
        
        local function closeOnClick(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if dropdownFrame and dropdownFrame.Parent then
                    local mousePos = input.Position
                    local absPos = dropdownFrame.AbsolutePosition
                    local absSize = dropdownFrame.AbsoluteSize
                    if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                           mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                        CloseDropdown()
                    end
                end
            end
        end
        
        local connection = UserInputService.InputBegan:Connect(closeOnClick)
        dropdownFrame.Destroying:Connect(function()
            connection:Disconnect()
        end)
    end)
    
    return dropdown
end

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

local function CreateScriptButton(parent, text, callback, removeCallback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.LayoutOrder = #parent:GetChildren()

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, 0, 1, 0)
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

    if removeCallback then
        local removeBtn = Instance.new("TextButton")
        removeBtn.Parent = frame
        removeBtn.BorderSizePixel = 0
        removeBtn.Position = UDim2.new(1, -28, 0, 2)
        removeBtn.Size = UDim2.new(0, 24, 1, -4)
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.Text = "X"
        removeBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
        removeBtn.TextSize = 14
        removeBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
        removeBtn.TextXAlignment = Enum.TextXAlignment.Center
        removeBtn.ZIndex = 2
        
        local removeCorner = Instance.new("UICorner", removeBtn)
        removeCorner.CornerRadius = UDim.new(0, 4)
        
        removeBtn.MouseButton1Click:Connect(removeCallback)
        removeBtn.MouseEnter:Connect(function() 
            removeBtn.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
            removeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        end)
        removeBtn.MouseLeave:Connect(function() 
            removeBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
            removeBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
        end)
    end
    
    return frame
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

local function CreateTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Parent = parent
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 32)
    box.LayoutOrder = #parent:GetChildren()
    box.BackgroundColor3 = BG_ELEMENT
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = TEXT_SECONDARY
    box.Text = ""
    box.TextColor3 = TEXT_PRIMARY
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextTruncate = Enum.TextTruncate.AtEnd
    
    local padding = Instance.new("UIPadding")
    padding.Parent = box
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    
    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = UDim.new(0, 6)
    return box
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
        CreateLabel(aboutSection, "VuaN | Survive the Killer", ACCENT_COLOR).TextSize = 16
        CreateLabel(aboutSection, "Version V2", TEXT_SECONDARY).TextSize = 11
        
        CreateLabel(aboutSection, "", Color3.fromRGB(50,50,50))
        
        local changesHeader = CreateLabel(aboutSection, "CHANGE LOG:", TEXT_PRIMARY)
        changesHeader.TextSize = 12
        
        local changes = {
            "V2",
            " - Added Settings tab",
            " - Added Fun tab",
            " - Added Anti Trap",
            " - Added Panic TP",
            " - Added Save/Load configs",
            " - Added User scripts manager",
            " - Added Anti AFK",
            " - Added Script delete buttons",
            " - UI improvements",
            "V1.4",
            " - Added Auto Escape",
            " - Added ESP Exits/Traps",
            " - Added Disable speed on down",
            " - Update Auto Revive (Risky)",
            " - Fix No Fog",
            " - Fix kill Aura",
            "V1.3",
            " - UI redesign",
            " - Killer Chance X3 (gamepass bypass)",
            " - bag fix",
            "V1.2",
            " - Double Jump (gamepass bypass)",
            "V1.1",
            " - Auto Revive (Legit, Risky, Self)",
            "V1",
            " - Release"
        }
        for _, line in ipairs(changes) do
            local l = CreateLabel(aboutSection, "  • " .. line, Color3.fromRGB(180, 180, 200))
            l.TextSize = 10; l.Font = Enum.Font.Gotham
        end
        
        CreateLabel(aboutSection, "", Color3.fromRGB(50,50,50))
        CreateLabel(aboutSection, "Credits: VuaN                 Test: Probka(SACR1F1C3) and Lysyy", TEXT_SECONDARY).TextSize = 12

    elseif CurrentTab == "  Player" then
        local movementSection = CreateSection(RightContent, "MOVEMENT")
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
        CreateToggle(movementSection, "Disable Speed On Crawl", settings.speedDisableOnDown, function(val)
            settings.speedDisableOnDown = val
        end)
        CreateToggle(movementSection, "Fly", settings.Fly, function(val)
            settings.Fly = val
            UpdateFly()
        end)
        CreateSlider(movementSection, "Fly Speed", 20, 200, settings.flySpeed, function(val)
            settings.flySpeed = val
        end)
        CreateToggle(movementSection, "Noclip", settings.Noclip, function(val)
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
        CreateToggle(movementSection, "Auto Escape", settings.AutoEscape, function(val)
            settings.AutoEscape = val
            if val then
                if autoEscapeConnection then autoEscapeConnection:Disconnect() end
                autoEscapeConnection = RunService.Heartbeat:Connect(AutoEscapeLoop)
            else
                if autoEscapeConnection then autoEscapeConnection:Disconnect(); autoEscapeConnection = nil end
            end
        end)
        
        CreateToggle(movementSection, "Panic TP", settings.PanicTP, function(val)
            settings.PanicTP = val
            if val then
                if panicTPConnection then panicTPConnection:Disconnect() end
                panicTPConnection = RunService.Heartbeat:Connect(function()
                    if settings.PanicTP then
                        CheckPanicTP()
                    end
                end)
            else
                if panicTPConnection then panicTPConnection:Disconnect(); panicTPConnection = nil end
            end
        end)
        
        local bypassSection = CreateSection(RightContent, "GAMEPASS BYPASS")
        CreateToggle(bypassSection, "Double Jump", settings.DoubleJump, function(val)
            settings.DoubleJump = val
            UpdateDoubleJump()
        end)
        CreateToggle(bypassSection, "Killer Chance X3", settings.KillerChanceX3, function(val)
            settings.KillerChanceX3 = val
            UpdateKillerChance()
        end)
        
        local combatSection = CreateSection(RightContent, "COMBAT")
        CreateToggle(combatSection, "Kill Aura", settings.KillAura, function(val)
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
        CreateSlider(combatSection, "Kill Aura Radius", 8, 80, settings.killAuraRadius, function(val)
            settings.killAuraRadius = val
        end)
        CreateButton(combatSection, "Kill All", BringAndKillAll)
        
        local bringBox = CreateTextBox(combatSection, "   Player name")
        CreateButton(combatSection, "Bring Player", function()
            if bringBox.Text ~= "" then BringPlayer(bringBox.Text) else notif("Enter name", 2) end
        end)
        
    elseif CurrentTab == "  World" then
        local visualSection = CreateSection(RightContent, "VISUAL")
        CreateToggle(visualSection, "ESP Players", settings.ESP, function(val)
            settings.ESP = val
            espCache = {}
            UpdateESP()
        end)
        CreateToggle(visualSection, "ESP Exits", settings.ESPExits, function(val)
            settings.ESPExits = val
            UpdateESPExits()
        end)
        CreateToggle(visualSection, "ESP Traps", settings.ESPTraps, function(val)
            settings.ESPTraps = val
            UpdateESPTraps()
        end)
        CreateToggle(visualSection, "No Fog", settings.NoFog, function(val)
            settings.NoFog = val
            UpdateNoFog()
        end)
        CreateToggle(visualSection, "Fullbright", settings.Fullbright, function(val)
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
        
        CreateToggle(visualSection, "Anti Trap", settings.AntiTrap, function(val)
            settings.AntiTrap = val
            if val then
                if antiTrapConnection then antiTrapConnection:Disconnect() end
                antiTrapConnection = RunService.Heartbeat:Connect(function()
                    if settings.AntiTrap then
                        RemoveTraps()
                    end
                end)
            else
                if antiTrapConnection then antiTrapConnection:Disconnect(); antiTrapConnection = nil end
            end
        end)
        
        local lootSection = CreateSection(RightContent, "AUTO LOOT")
        CreateToggle(lootSection, "Auto Collect Loot", settings.AutoLoot, function(val)
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
        CreateToggle(lootSection, "Return home after loot", settings.returnHomeAfterLoot, function(val)
            settings.returnHomeAfterLoot = val
        end)
        
        local teleportSection = CreateSection(RightContent, "TELEPORT")
        CreateButton(teleportSection, "Teleport to Exit", TeleportToExit)
        CreateButton(teleportSection, "Teleport to Lobby", function()
            local lobby = workspace:FindFirstChild("_Lobby")
            if lobby then
                local decor = lobby:FindFirstChild("Decor")
                if decor then
                    local knifeStatue = decor:FindFirstChild("KnifeStatue")
                    if knifeStatue and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = CFrame.new(knifeStatue.Position + Vector3.new(0, 30, 0))
                        notif("Teleported to Lobby!", 2)
                    end
                end
            end
        end)

	elseif CurrentTab == "  Skinchanger" then
        local aboutSection = CreateSection(RightContent, "SKIN CHANGER")
		CreateLabel(aboutSection, "Soon, maybe...").TextSize = 24
    
        
    elseif CurrentTab == "  Revive" then
        local reviveSection = CreateSection(RightContent, "REVIVE MODES")
        CreateToggle(reviveSection, "Auto Revive (Legit)", settings.AutoReviveLegit, function(val)
            settings.AutoReviveLegit = val
            if val then
                if reviveLegitConnection then reviveLegitConnection:Disconnect() end
                reviveLegitConnection = RunService.Heartbeat:Connect(AutoReviveLegitLoop)
            else
                if reviveLegitConnection then reviveLegitConnection:Disconnect(); reviveLegitConnection = nil end
            end
        end)
        CreateButton(reviveSection, "Revive (Risky)", function()
            AutoReviveRiskyOneUse()
        end)
        
        local selfReviveSection = CreateSection(RightContent, "SELF REVIVE")
        CreateToggle(selfReviveSection, "Auto Revive (Self)", settings.AutoReviveSelf, function(val)
            settings.AutoReviveSelf = val
            if val then
                if selfReviveConnection then selfReviveConnection:Disconnect() end
                selfReviveConnection = RunService.Heartbeat:Connect(AutoReviveSelfLoop)
            else
                if selfReviveConnection then selfReviveConnection:Disconnect(); selfReviveConnection = nil end
            end
        end)
        CreateSlider(selfReviveSection, "Self Revive Cooldown", 1, 10, settings.selfReviveCooldown, function(val)
            settings.selfReviveCooldown = val
        end)
        
        local function setSelfReviveMode(mode)
            settings.selfReviveMode = mode
            notif("Self Revive mode: " .. mode, 2)
        end
        CreateButton(selfReviveSection, "Self Revive Mode: Random", function() setSelfReviveMode("Random") end)
        CreateButton(selfReviveSection, "Self Revive Mode: Long Distant", function() setSelfReviveMode("Farthest") end)
        
    elseif CurrentTab == "  Fun" then
    local funSection = CreateSection(RightContent, "FUN FUNCTIONS")
    
    local targetBox = CreateTextBox(funSection, "   Enter player nickname...")
    
    local btnRow1 = Instance.new("Frame")
    btnRow1.Parent = funSection
    btnRow1.BackgroundTransparency = 1
    btnRow1.Size = UDim2.new(1, 0, 0, 35)
    btnRow1.LayoutOrder = #funSection:GetChildren()
    
    local rowLayout1 = Instance.new("UIListLayout", btnRow1)
    rowLayout1.FillDirection = Enum.FillDirection.Horizontal
    rowLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rowLayout1.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout1.Padding = UDim.new(0, 10)
    
    local flingBtn = Instance.new("TextButton")
    flingBtn.Parent = btnRow1
    flingBtn.BorderSizePixel = 0
    flingBtn.Size = UDim2.new(0.45, 0, 0, 32)
    flingBtn.Font = Enum.Font.GothamBold
    flingBtn.Text = "Fling"
    flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flingBtn.TextSize = 12
    flingBtn.BackgroundColor3 = ACCENT_COLOR
    local flingCorner = Instance.new("UICorner", flingBtn)
    flingCorner.CornerRadius = UDim.new(0, 6)
    flingBtn.MouseButton1Click:Connect(function()
        if targetBox.Text ~= "" then StartFling(targetBox.Text) else notif("Enter a player name", 2) end
    end)
    flingBtn.MouseEnter:Connect(function() flingBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    flingBtn.MouseLeave:Connect(function() flingBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    local stopFlingBtn = Instance.new("TextButton")
    stopFlingBtn.Parent = btnRow1
    stopFlingBtn.BorderSizePixel = 0
    stopFlingBtn.Size = UDim2.new(0.45, 0, 0, 32)
    stopFlingBtn.Font = Enum.Font.GothamBold
    stopFlingBtn.Text = "Stop Fling"
    stopFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopFlingBtn.TextSize = 12
    stopFlingBtn.BackgroundColor3 = ACCENT_COLOR
    local stopCorner = Instance.new("UICorner", stopFlingBtn)
    stopCorner.CornerRadius = UDim.new(0, 6)
    stopFlingBtn.MouseButton1Click:Connect(StopFling)
    stopFlingBtn.MouseEnter:Connect(function() stopFlingBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    stopFlingBtn.MouseLeave:Connect(function() stopFlingBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    local btnRow2 = Instance.new("Frame")
    btnRow2.Parent = funSection
    btnRow2.BackgroundTransparency = 1
    btnRow2.Size = UDim2.new(1, 0, 0, 35)
    btnRow2.LayoutOrder = #funSection:GetChildren()
    
    local rowLayout2 = Instance.new("UIListLayout", btnRow2)
    rowLayout2.FillDirection = Enum.FillDirection.Horizontal
    rowLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rowLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout2.Padding = UDim.new(0, 10)
    
    local freezeBtn = Instance.new("TextButton")
    freezeBtn.Parent = btnRow2
    freezeBtn.BorderSizePixel = 0
    freezeBtn.Size = UDim2.new(0.45, 0, 0, 32)
    freezeBtn.Font = Enum.Font.GothamBold
    freezeBtn.Text = "Freeze"
    freezeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    freezeBtn.TextSize = 12
    freezeBtn.BackgroundColor3 = ACCENT_COLOR
    local freezeCorner = Instance.new("UICorner", freezeBtn)
    freezeCorner.CornerRadius = UDim.new(0, 6)
    freezeBtn.MouseButton1Click:Connect(function()
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
    freezeBtn.MouseEnter:Connect(function() freezeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    freezeBtn.MouseLeave:Connect(function() freezeBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    local thawBtn = Instance.new("TextButton")
    thawBtn.Parent = btnRow2
    thawBtn.BorderSizePixel = 0
    thawBtn.Size = UDim2.new(0.45, 0, 0, 32)
    thawBtn.Font = Enum.Font.GothamBold
    thawBtn.Text = "Thaw"
    thawBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    thawBtn.TextSize = 12
    thawBtn.BackgroundColor3 = ACCENT_COLOR
    local thawCorner = Instance.new("UICorner", thawBtn)
    thawCorner.CornerRadius = UDim.new(0, 6)
    thawBtn.MouseButton1Click:Connect(function()
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
    thawBtn.MouseEnter:Connect(function() thawBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    thawBtn.MouseLeave:Connect(function() thawBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    local btnRow3 = Instance.new("Frame")
    btnRow3.Parent = funSection
    btnRow3.BackgroundTransparency = 1
    btnRow3.Size = UDim2.new(1, 0, 0, 35)
    btnRow3.LayoutOrder = #funSection:GetChildren()
    
    local rowLayout3 = Instance.new("UIListLayout", btnRow3)
    rowLayout3.FillDirection = Enum.FillDirection.Horizontal
    rowLayout3.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rowLayout3.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout3.Padding = UDim.new(0, 10)
    
    local viewBtn = Instance.new("TextButton")
    viewBtn.Parent = btnRow3
    viewBtn.BorderSizePixel = 0
    viewBtn.Size = UDim2.new(0.45, 0, 0, 32)
    viewBtn.Font = Enum.Font.GothamBold
    viewBtn.Text = "View"
    viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    viewBtn.TextSize = 12
    viewBtn.BackgroundColor3 = ACCENT_COLOR
    local viewCorner = Instance.new("UICorner", viewBtn)
    viewCorner.CornerRadius = UDim.new(0, 6)
    viewBtn.MouseButton1Click:Connect(function()
        if targetBox.Text ~= "" then StartView(targetBox.Text) else notif("Enter a player name", 2) end
    end)
    viewBtn.MouseEnter:Connect(function() viewBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    viewBtn.MouseLeave:Connect(function() viewBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    local unviewBtn = Instance.new("TextButton")
    unviewBtn.Parent = btnRow3
    unviewBtn.BorderSizePixel = 0
    unviewBtn.Size = UDim2.new(0.45, 0, 0, 32)
    unviewBtn.Font = Enum.Font.GothamBold
    unviewBtn.Text = "Unview"
    unviewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unviewBtn.TextSize = 12
    unviewBtn.BackgroundColor3 = ACCENT_COLOR
    local unviewCorner = Instance.new("UICorner", unviewBtn)
    unviewCorner.CornerRadius = UDim.new(0, 6)
    unviewBtn.MouseButton1Click:Connect(StopView)
    unviewBtn.MouseEnter:Connect(function() unviewBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    unviewBtn.MouseLeave:Connect(function() unviewBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    local btnRow4 = Instance.new("Frame")
    btnRow4.Parent = funSection
    btnRow4.BackgroundTransparency = 1
    btnRow4.Size = UDim2.new(1, 0, 0, 35)
    btnRow4.LayoutOrder = #funSection:GetChildren()
    
    local rowLayout4 = Instance.new("UIListLayout", btnRow4)
    rowLayout4.FillDirection = Enum.FillDirection.Horizontal
    rowLayout4.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rowLayout4.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout4.Padding = UDim.new(0, 10)
    
    local bringBtn = Instance.new("TextButton")
    bringBtn.Parent = btnRow4
    bringBtn.BorderSizePixel = 0
    bringBtn.Size = UDim2.new(0.45, 0, 0, 32)
    bringBtn.Font = Enum.Font.GothamBold
    bringBtn.Text = "Bring"
    bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bringBtn.TextSize = 12
    bringBtn.BackgroundColor3 = ACCENT_COLOR
    local bringCorner = Instance.new("UICorner", bringBtn)
    bringCorner.CornerRadius = UDim.new(0, 6)
    bringBtn.MouseButton1Click:Connect(function()
        if targetBox.Text ~= "" then StartBring(targetBox.Text) else notif("Enter a player name", 2) end
    end)
    bringBtn.MouseEnter:Connect(function() bringBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    bringBtn.MouseLeave:Connect(function() bringBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    local stopBringBtn = Instance.new("TextButton")
    stopBringBtn.Parent = btnRow4
    stopBringBtn.BorderSizePixel = 0
    stopBringBtn.Size = UDim2.new(0.45, 0, 0, 32)
    stopBringBtn.Font = Enum.Font.GothamBold
    stopBringBtn.Text = "Stop Bring"
    stopBringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBringBtn.TextSize = 12
    stopBringBtn.BackgroundColor3 = ACCENT_COLOR
    local stopCorner2 = Instance.new("UICorner", stopBringBtn)
    stopCorner2.CornerRadius = UDim.new(0, 6)
    stopBringBtn.MouseButton1Click:Connect(StopBring)
    stopBringBtn.MouseEnter:Connect(function() stopBringBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    stopBringBtn.MouseLeave:Connect(function() stopBringBtn.BackgroundColor3 = ACCENT_COLOR end)
    
    CreateToggle(funSection, "Spin", spinActive, function(val)
        spinActive = val
        UpdateSpin(val)
    end)
    
    CreateSlider(funSection, "Spin Speed", 1, 300, spinSpeed, function(val)
        spinSpeed = val
        if spinActive and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = lp.Character.HumanoidRootPart
            local spin = root:FindFirstChild("Spinning")
            if spin then
                spin.AngularVelocity = Vector3.new(0, spinSpeed, 0)
            end
        end
    end)
        
    elseif CurrentTab == "  More" then
        local scriptsSection = CreateSection(RightContent, "EXTERNAL SCRIPTS")
        
        local addRow = Instance.new("Frame")
        addRow.Parent = scriptsSection
        addRow.BackgroundTransparency = 1
        addRow.Size = UDim2.new(1, 0, 0, 32)
        addRow.LayoutOrder = #scriptsSection:GetChildren()
        
        local nameBox = Instance.new("TextBox")
        nameBox.Parent = addRow
        nameBox.BorderSizePixel = 0
        nameBox.Size = UDim2.new(0.35, -2, 1, 0)
        nameBox.Position = UDim2.new(0, 0, 0, 0)
        nameBox.BackgroundColor3 = BG_ELEMENT
        nameBox.Font = Enum.Font.Gotham
        nameBox.PlaceholderText = "Name"
        nameBox.PlaceholderColor3 = TEXT_SECONDARY
        nameBox.Text = ""
        nameBox.TextColor3 = TEXT_PRIMARY
        nameBox.TextSize = 11
        nameBox.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 4)
        
        local urlBox = Instance.new("TextBox")
        urlBox.Parent = addRow
        urlBox.BorderSizePixel = 0
        urlBox.Size = UDim2.new(0.5, -2, 1, 0)
        urlBox.Position = UDim2.new(0.36, 0, 0, 0)
        urlBox.BackgroundColor3 = BG_ELEMENT
        urlBox.Font = Enum.Font.Gotham
        urlBox.PlaceholderText = "Script URL or code"
        urlBox.PlaceholderColor3 = TEXT_SECONDARY
        urlBox.Text = ""
        urlBox.TextColor3 = TEXT_PRIMARY
        urlBox.TextSize = 11
        urlBox.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", urlBox).CornerRadius = UDim.new(0, 4)
        
        local addBtn = Instance.new("TextButton")
        addBtn.Parent = addRow
        addBtn.BorderSizePixel = 0
        addBtn.Size = UDim2.new(0.13, -2, 1, 0)
        addBtn.Position = UDim2.new(0.87, 0, 0, 0)
        addBtn.Font = Enum.Font.GothamBold
        addBtn.Text = "+"
        addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        addBtn.TextSize = 18
        addBtn.BackgroundColor3 = ACCENT_COLOR
        addBtn.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 4)
        
        addBtn.MouseButton1Click:Connect(function()
            if nameBox.Text ~= "" and urlBox.Text ~= "" then
                local scriptContent = urlBox.Text
                if scriptContent:match("^https?://") then
                    scriptContent = 'loadstring(game:HttpGet("' .. scriptContent .. '"))()'
                end
                AddUserScript(nameBox.Text, scriptContent)
                nameBox.Text = ""
                urlBox.Text = ""
            else
                notif("Please fill both fields", 2)
            end
        end)
        addBtn.MouseEnter:Connect(function() 
            addBtn.BackgroundColor3 = Color3.fromRGB(244, 78, 78)
        end)
        addBtn.MouseLeave:Connect(function() 
            addBtn.BackgroundColor3 = ACCENT_COLOR
        end)
        
        for _, scriptData in ipairs(more_scripts) do
            CreateScriptButton(scriptsSection, scriptData.name, function()
                notif("Loading: " .. scriptData.name, 2)
                local success, err = pcall(function()
                    local func = loadstring(scriptData.script)
                    if func then
                        func()
                    else
                        notif("Failed to load script: Invalid code", 3)
                    end
                end)
                if not success and err then
                    notif("Error: " .. tostring(err), 3)
                end
            end)
        end
        
        if #userScripts > 0 then
            local userSection = CreateSection(RightContent, "YOUR SCRIPTS")
            for i, scriptData in ipairs(userScripts) do
                local function removeScript()
                    RemoveUserScript(i)
                end
                CreateScriptButton(userSection, scriptData.name, function()
                    notif("Loading: " .. scriptData.name, 2)
                    local success, err = pcall(function()
                        local func = loadstring(scriptData.script)
                        if func then
                            func()
                        else
                            notif("Failed to load script: Invalid code", 3)
                        end
                    end)
                    if not success and err then
                        notif("Error: " .. tostring(err), 3)
                    end
                end, removeScript)
            end
        end
        
    elseif CurrentTab == "  Settings" then
        local configSection = CreateSection(RightContent, "CONFIGURATIONS")
        
        local nameFrame = Instance.new("Frame")
        nameFrame.Parent = configSection
        nameFrame.BackgroundTransparency = 1
        nameFrame.Size = UDim2.new(1, 0, 0, 32)
        nameFrame.LayoutOrder = #configSection:GetChildren()
        
        configNameBox = Instance.new("TextBox")
        configNameBox.Parent = nameFrame
        configNameBox.BorderSizePixel = 0
        configNameBox.Size = UDim2.new(1, 0, 1, 0)
        configNameBox.BackgroundColor3 = BG_ELEMENT
        configNameBox.Font = Enum.Font.Gotham
        configNameBox.PlaceholderText = "Config name"
        configNameBox.PlaceholderColor3 = TEXT_SECONDARY
        configNameBox.Text = "Default"
        configNameBox.TextColor3 = TEXT_PRIMARY
        configNameBox.TextSize = 12
        configNameBox.TextXAlignment = Enum.TextXAlignment.Left
        
        local namePadding = Instance.new("UIPadding")
        namePadding.Parent = configNameBox
        namePadding.PaddingLeft = UDim.new(0, 10)
        namePadding.PaddingRight = UDim.new(0, 10)
        
        local boxCorner = Instance.new("UICorner", configNameBox)
        boxCorner.CornerRadius = UDim.new(0, 6)
        
        local btnRow = Instance.new("Frame")
        btnRow.Parent = configSection
        btnRow.BackgroundTransparency = 1
        btnRow.Size = UDim2.new(1, 0, 0, 32)
        btnRow.LayoutOrder = #configSection:GetChildren()
        
        local rowLayout = Instance.new("UIListLayout", btnRow)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.Padding = UDim.new(0, 5)
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local btnWidth = UDim2.new(0.32, -4, 1, 0)
        
        CreateButton(btnRow, "Save", function()
            local configName = configNameBox.Text
            if configName == "" then configName = "Default" end
            SaveConfig(configName)
        end, btnWidth)
        
        CreateButton(btnRow, "Load", function()
            local configName = configNameBox.Text
            if configName == "" then configName = "Default" end
            LoadConfig(configName)
            UpdateRightContent()
        end, btnWidth)
        
        CreateButton(btnRow, "Delete", function()
            local configName = configNameBox.Text
            if configName == "" then configName = "Default" end
            DeleteConfig(configName)
        end, btnWidth)
        
        local configListSection = CreateSection(RightContent, "AVAILABLE CONFIGS")
        local configsList = GetConfigList()
        if #configsList > 0 then
            for _, name in ipairs(configsList) do
                CreateButton(configListSection, name, function()
                    configNameBox.Text = name
                    LoadConfig(name)
                    UpdateRightContent()
                end)
            end
        else
            CreateLabel(configListSection, "No saved configs", TEXT_SECONDARY)
        end
        
        local miscSection = CreateSection(RightContent, "MISC")
        CreateToggle(miscSection, "Anti AFK", settings.AntiAFK, function(val)
            settings.AntiAFK = val
            if val then
                if antiAFKConnection then antiAFKConnection:Disconnect() end
                antiAFKConnection = RunService.Heartbeat:Connect(function()
                    if settings.AntiAFK then
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                        task.wait(0.05)
                        vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                        task.wait(15)
                    end
                end)
            else
                if antiAFKConnection then antiAFKConnection:Disconnect(); antiAFKConnection = nil end
            end
        end)
        
        local footerFrame = Instance.new("Frame")
        footerFrame.Parent = RightContent
        footerFrame.BackgroundTransparency = 1
        footerFrame.Size = UDim2.new(1, 0, 0, 60)
        footerFrame.LayoutOrder = 999999
        
        local footerLabel1 = Instance.new("TextLabel")
        footerLabel1.Parent = footerFrame
        footerLabel1.BackgroundTransparency = 1
        footerLabel1.Size = UDim2.new(1, 0, 0, 20)
        footerLabel1.Position = UDim2.new(0, 0, 0, 10)
        footerLabel1.Font = Enum.Font.GothamBold
        footerLabel1.Text = "Support STK version V2.31.0"
        footerLabel1.TextColor3 = TEXT_SECONDARY
        footerLabel1.TextSize = 11
        footerLabel1.TextXAlignment = Enum.TextXAlignment.Center

        local footerLabel2 = Instance.new("TextLabel")
        footerLabel2.Parent = footerFrame
        footerLabel2.BackgroundTransparency = 1
        footerLabel2.Size = UDim2.new(1, 0, 0, 20)
        footerLabel2.Position = UDim2.new(0, 0, 0, 30)
        footerLabel2.Font = Enum.Font.GothamBold
        footerLabel2.Text = "Thanks you ❤"
        footerLabel2.TextColor3 = ACCENT_COLOR
        footerLabel2.TextSize = 11
        footerLabel2.TextXAlignment = Enum.TextXAlignment.Center
    end
end

local function SafeLoadScript(scriptData)
    local success, result = pcall(function()
        return loadstring(scriptData)
    end)
    if success and result then
        local execSuccess, execErr = pcall(result)
        if not execSuccess then
            return false, execErr
        end
        return true, nil
    else
        return false, "Invalid script code"
    end
end

local updateConnection = RunService.Stepped:Connect(PeriodicUpdates)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "ExitGateways" or descendant.Name == "Doorway" or descendant.Name == "Frame" then
        task.wait(0.5)
        UpdateESPExits()
    end
    if descendant.Name == "Trap" then
        task.wait(0.5)
        UpdateESPTraps()
    end
end)

workspace.DescendantRemoved:Connect(function()
    task.wait(0.5)
    UpdateESPExits()
    UpdateESPTraps()
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

--LoadSkinLists()
UpdateNoFog()
UpdateESP()
UpdateESPExits()
UpdateESPTraps()
UpdateDoubleJump()
UpdateKillerChance()
UpdateRightContent()
UpdateAllFeatures()

notif("VSTK V2 Loaded", 3)
