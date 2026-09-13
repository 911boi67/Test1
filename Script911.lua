-- ═══════════════════════════════════════════════════════════════
--   ██████╗ ███████╗██╗  ████████╗ █████╗     ██╗  ██╗██╗   ██╗
--   ██╔══██╗██╔════╝██║  ╚══██╔══╝██╔══██╗    ██║ ██╔╝██║   ██║
--   ██║  ██║█████╗  ██║     ██║   ███████║    █████╔╝ ██║   ██║
--   ██║  ██║██╔══╝  ██║     ██║   ██╔══██║    ██╔═██╗ ██║   ██║
--   ██████╔╝███████╗███████╗██║   ██║  ██║    ██║  ██╗╚██████╔╝
--   ╚═════╝ ╚══════╝╚══════╝╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ 
--              Delta Aim & ESP + Noclip | v1.0
-- ═══════════════════════════════════════════════════════════════

-- Rayfield laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════
-- KEY
-- ═══════════════════════════════════
local VALID_KEY = "Langlebestalin"

-- ═══════════════════════════════════
-- Fenster mit Key-System
-- ═══════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "Delta Aim & ESP",
    LoadingTitle = "Lade Interface...",
    LoadingSubtitle = "Aimbot • ESP • Noclip",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DeltaAimESP",
        FileName = "AutoSave"
    },
    KeySystem = true,
    KeySettings = {
        Title = "🔑 Key Eingabe",
        Subtitle = "Bitte Key eingeben um fortzufahren",
        Note = "Key: " .. VALID_KEY,
        FileName = "AimESPKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {VALID_KEY}
    }
})

-- ═══════════════════════════════════
-- Freunde laden
-- ═══════════════════════════════════
local Friends = {}
pcall(function()
    for _, id in ipairs(LocalPlayer:GetFriendsOnline()) do
        Friends[id] = true
    end
end)

-- ═══════════════════════════════════
-- AIMBOT Variablen
-- ═══════════════════════════════════
local AimbotEnabled = false
local WallCheck = true
local TeamCheck = true
local DeadCheck = true
local FriendCheck = false
local KnockedCheck = false
local FOVRadius = 90
local SmoothX = 0.5
local SmoothY = 0.5
local AimPart = "Head"
local Prediction = 0.15
local PredictionEnabled = true
local MaxDistance = 500
local Priority = "FOV"
local AimKey = Enum.UserInputType.MouseButton2
local AimKeyEnabled = false
local AimKeyMode = "Hold"
local StickyAim = true
local AimOnlyWhenShooting = false
local FOVColor = Color3.fromRGB(255, 255, 255)
local FOVThickness = 1
local FOVFilled = false
local DynamicFOV = false
local DynamicFOVMin = 30

-- Hit Chance
local HitChanceEnabled = false
local HitChance = 100
local HitRollCooldown = 0.2
local LastRollTime = 0
local CurrentRoll = true

-- Sticky
local StickyTarget = nil
local AimKeyHeld = false

-- ═══════════════════════════════════
-- ESP Variablen
-- ═══════════════════════════════════
local ESPEnabled = false
local ESPBoxes = true
local ESPTracers = true
local ESPNames = true
local ESPHealth = true
local ESPTeamCheck = true
local ESPDeadCheck = true

-- ═══════════════════════════════════
-- NOCLIP Variablen
-- ═══════════════════════════════════
local NoclipEnabled = false
local NoclipKeyEnabled = false
local NoclipKey = Enum.KeyCode.N
local NoclipKeyHeld = false
local VehicleNoclip = false
local NoclipConnection = nil

-- ═══════════════════════════════════
-- FOV Kreis
-- ═══════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Color = FOVColor
fovCircle.Thickness = FOVThickness
fovCircle.Filled = FOVFilled
fovCircle.Radius = FOVRadius
fovCircle.Visible = false
fovCircle.NumSides = 60
fovCircle.Transparency = 1

-- ═══════════════════════════════════
-- Input Handler
-- ═══════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Aim Key
    if input.UserInputType == AimKey then
        if AimKeyMode == "Toggle" then
            AimKeyHeld = not AimKeyHeld
        else
            AimKeyHeld = true
        end
    end

    -- Noclip Key
    if input.KeyCode == NoclipKey and NoclipKeyEnabled then
        NoclipKeyHeld = not NoclipKeyHeld
        if NoclipKeyHeld then
            StartNoclip()
        else
            StopNoclip()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == AimKey and AimKeyMode == "Hold" then
        AimKeyHeld = false
    end
end)

-- ═══════════════════════════════════
-- Helper Funktionen
-- ═══════════════════════════════════
local function IsKnocked(character)
    if not KnockedCheck then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.PlatformStand then return true end
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BallSocketConstraint") and v.Enabled then return true end
    end
    if character:GetAttribute("Knocked") or character:GetAttribute("Downed") then return true end
    return false
end

local function IsValidTarget(character)
    if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if DeadCheck and humanoid.Health <= 0 then return false end

    local player = Players:GetPlayerFromCharacter(character)
    if TeamCheck and player and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    if FriendCheck and player and Friends[player.UserId] then return false end
    if IsKnocked(character) then return false end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
        if dist > MaxDistance then return false end
    end

    if WallCheck then
        local checkParts = {
            character:FindFirstChild("Head"),
            character:FindFirstChild("HumanoidRootPart"),
            character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        }
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        params.IgnoreWater = true

        local visible = false
        for _, part in ipairs(checkParts) do
            if part then
                local dir = part.Position - Camera.CFrame.Position
                local result = workspace:Raycast(Camera.CFrame.Position, dir, params)
                if not result or result.Instance:IsDescendantOf(character) then
                    visible = true
                    break
                end
            end
        end
        if not visible then return false end
    end
    return true
end

local function GetPredictedPosition(part)
    if not PredictionEnabled or Prediction <= 0 then return part.Position end
    local velocity = part.Velocity or part.AssemblyLinearVelocity
    if not velocity then return part.Position end
    local ping = 0
    pcall(function() ping = LocalPlayer:GetNetworkPing() * 2 end)
    return part.Position + (velocity * (Prediction + ping))
end

local function ShouldHit()
    if not HitChanceEnabled then return true end
    if HitChance >= 100 then return true end
    if HitChance <= 0 then return false end

    local now = tick()
    if now - LastRollTime > HitRollCooldown then
        LastRollTime = now
        CurrentRoll = math.random(1, 100) <= HitChance
    end
    return CurrentRoll
end

local function GetClosestTarget()
    local closest = nil
    local bestScore = math.huge
    local mouse = UserInputService:GetMouseLocation()
    local mousePos = mouse - Vector2.new(0, 36)

    local currentFOV = FOVRadius
    if DynamicFOV and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        currentFOV = DynamicFOVMin
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            if IsValidTarget(character) then
                local part = character:FindFirstChild(AimPart) or character:FindFirstChild("HumanoidRootPart")
                if part then
                    local predictedPos = GetPredictedPosition(part)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    if onScreen and screenPos.Z > 0 then
                        local screenVec = Vector2.new(screenPos.X, screenPos.Y)
                        local fovDist = (screenVec - mousePos).Magnitude
                        if fovDist <= currentFOV then
                            local score
                            if Priority == "FOV" then
                                score = fovDist
                            elseif Priority == "Distance" then
                                score = (part.Position - Camera.CFrame.Position).Magnitude
                            elseif Priority == "Health" then
                                local hum = character:FindFirstChildOfClass("Humanoid")
                                score = hum and hum.Health or 1000
                            else
                                score = fovDist
                            end
                            if score < bestScore then
                                bestScore = score
                                closest = part
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ═══════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════
local function ApplyNoclip(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

function StartNoclip()
    if not LocalPlayer.Character then return end
    if not NoclipConnection then
        NoclipConnection = RunService.Stepped:Connect(function()
            if not NoclipEnabled and not NoclipKeyHeld then return end
            local char = LocalPlayer.Character
            if char then ApplyNoclip(char) end
            if VehicleNoclip and char then
                local seat = char:FindFirstChildOfClass("VehicleSeat")
                if seat then
                    local model = seat:FindFirstAncestorOfClass("Model")
                    if model then
                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end
            end
        end)
    end
end

function StopNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name == "HumanoidRootPart" or part.Name == "Torso"
                   or part.Name == "UpperTorso" or part.Name == "LowerTorso" then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ═══════════════════════════════════
-- ESP Speicher
-- ═══════════════════════════════════
local ESPObjects = {}

local function CreateESP(character)
    if ESPObjects[character] then return end

    local box = Drawing.new("Rectangle")
    box.Thickness = 1
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Filled = false
    box.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = Color3.fromRGB(255, 255, 255)
    tracer.Visible = false

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false

    local healthBar = Drawing.new("Rectangle")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false

    ESPObjects[character] = {
        box = box, tracer = tracer, name = nameTag, healthBar = healthBar
    }
end

local function RemoveESP(character)
    local esp = ESPObjects[character]
    if not esp then return end
    for _, obj in pairs(esp) do
        pcall(function() obj:Remove() end)
    end
    ESPObjects[character] = nil
end

local function HideESP(character)
    local esp = ESPObjects[character]
    if not esp then return end
    for _, obj in pairs(esp) do
        obj.Visible = false
    end
end

-- ═══════════════════════════════════
-- HAUPT RENDER LOOP
-- ═══════════════════════════════════
RunService.RenderStepped:Connect(function()
    -- ═══ AIMBOT ═══
    if AimbotEnabled then
        local mouse = UserInputService:GetMouseLocation()
        local currentFOV = FOVRadius

        if DynamicFOV and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            currentFOV = DynamicFOVMin
        end

        fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 36)
        fovCircle.Radius = currentFOV
        fovCircle.Color = FOVColor
        fovCircle.Thickness = FOVThickness
        fovCircle.Filled = FOVFilled
        fovCircle.Visible = true

        local shouldAim = true
        if AimKeyEnabled then shouldAim = AimKeyHeld end
        if AimOnlyWhenShooting and shouldAim then
            shouldAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        end
        if shouldAim and not ShouldHit() then shouldAim = false end

        if shouldAim then
            local target = nil

            if StickyAim and StickyTarget then
                if StickyTarget.Parent and IsValidTarget(StickyTarget.Parent) then
                    target = StickyTarget
                else
                    StickyTarget = nil
                end
            end

            if not target then
                target = GetClosestTarget()
                if target and StickyAim then StickyTarget = target end
            end

            if target then
                local predictedPos = GetPredictedPosition(target)
                local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)

                if SmoothX >= 1 and SmoothY >= 1 then
                    Camera.CFrame = targetCFrame
                else
                    local currentX, currentY, currentZ = Camera.CFrame:ToEulerAnglesXYZ()
                    local targetX, targetY, targetZ = targetCFrame:ToEulerAnglesXYZ()
                    local alphaX = math.clamp(SmoothX, 0.01, 1)
                    local alphaY = math.clamp(SmoothY, 0.01, 1)
                    local newX = currentX + (targetX - currentX) * alphaX
                    local newY = currentY + (targetY - currentY) * alphaY
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(newX, newY, currentZ)
                end
            else
                StickyTarget = nil
            end
        end
    else
        fovCircle.Visible = false
        StickyTarget = nil
    end

    -- ═══ ESP ═══
    if not ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do obj.Visible = false end
        end
    else
        local viewportSize = Camera.ViewportSize

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local head = character:FindFirstChild("Head")

                    if humanoid and hrp and head then
                        local skip = false
                        if ESPDeadCheck and humanoid.Health <= 0 then skip = true end
                        if ESPTeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then skip = true end

                        if not skip then
                            if not ESPObjects[character] then CreateESP(character) end
                            local esp = ESPObjects[character]
                            if esp then
                                local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                                local headPos = Camera:WorldToViewportPoint(head.Position)

                                if onScreen and hrpPos.Z > 0 then
                                    local height = math.abs(headPos.Y - hrpPos.Y) * 1.4
                                    local width = height * 0.55

                                    if ESPBoxes then
                                        esp.box.Size = Vector2.new(width, height)
                                        esp.box.Position = Vector2.new(hrpPos.X - width / 2, hrpPos.Y - height / 2)
                                        esp.box.Visible = true
                                    else
                                        esp.box.Visible = false
                                    end

                                    if ESPTracers then
                                        esp.tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                                        esp.tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                                        esp.tracer.Visible = true
                                    else
                                        esp.tracer.Visible = false
                                    end

                                    if ESPNames then
                                        esp.name.Text = player.Name
                                        esp.name.Position = Vector2.new(hrpPos.X, hrpPos.Y - height / 2 - 16)
                                        esp.name.Visible = true
                                    else
                                        esp.name.Visible = false
                                    end

                                    if ESPHealth then
                                        local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                                        local barWidth = 3
                                        esp.healthBar.Size = Vector2.new(barWidth, height * hp)
                                        esp.healthBar.Position = Vector2.new(
                                            hrpPos.X - width / 2 - barWidth - 3,
                                            hrpPos.Y - height / 2 + (height * (1 - hp))
                                        )
                                        if hp > 0.5 then
                                            esp.healthBar.Color = Color3.fromRGB(0, 255, 0)
                                        elseif hp > 0.25 then
                                            esp.healthBar.Color = Color3.fromRGB(255, 200, 0)
                                        else
                                            esp.healthBar.Color = Color3.fromRGB(255, 0, 0)
                                        end
                                        esp.healthBar.Visible = true
                                    else
                                        esp.healthBar.Visible = false
                                    end
                                else
                                    HideESP(character)
                                end
                            end
                        else
                            HideESP(character)
                        end
                    else
                        HideESP(character)
                    end
                end
            end
        end
    end

    -- ═══ NOCLIP ═══
    if NoclipEnabled and not NoclipConnection then
        StartNoclip()
    elseif not NoclipEnabled and not NoclipKeyHeld and NoclipConnection then
        StopNoclip()
    end
end)

-- ═══════════════════════════════════
-- Cleanup + Respawn Support
-- ═══════════════════════════════════
Players.PlayerRemoving:Connect(function(player)
    if player.Character then RemoveESP(player.Character) end
end)

local function HookPlayer(player)
    if player ~= LocalPlayer then
        player.CharacterRemoving:Connect(function(character)
            RemoveESP(character)
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do HookPlayer(player) end
Players.PlayerAdded:Connect(HookPlayer)

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    if NoclipEnabled or NoclipKeyHeld then
        ApplyNoclip(character)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--                              UI
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════
-- AIMBOT TAB
-- ═══════════════════════════════════
local AimbotTab = Window:CreateTab("🎯 Aimbot", nil)

AimbotTab:CreateSection("Hauptoptionen")

AimbotTab:CreateToggle({
    Name = "Aimbot Aktiviert",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(v) AimbotEnabled = v end
})

AimbotTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Flag = "WallCheck",
    Callback = function(v) WallCheck = v end
})

AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(v) TeamCheck = v end
})

AimbotTab:CreateToggle({
    Name = "Dead Check",
    CurrentValue = true,
    Flag = "DeadCheck",
    Callback = function(v) DeadCheck = v end
})

AimbotTab:CreateToggle({
    Name = "Freunde ignorieren",
    CurrentValue = false,
    Flag = "FriendCheck",
    Callback = function(v) FriendCheck = v end
})

AimbotTab:CreateToggle({
    Name = "Knocked ignorieren",
    CurrentValue = false,
    Flag = "KnockedCheck",
    Callback = function(v) KnockedCheck = v end
})

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {20, 400},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 90,
    Flag = "FOVRadius",
    Callback = function(v) FOVRadius = v end
})

AimbotTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 2000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 500,
    Flag = "MaxDistance",
    Callback = function(v) MaxDistance = v end
})

AimbotTab:CreateSection("Ziel-Auswahl")

AimbotTab:CreateDropdown({
    Name = "Ziel-Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "AimPart",
    Callback = function(o)
        AimPart = typeof(o) == "table" and o[1] or o
    end
})

AimbotTab:CreateDropdown({
    Name = "Priorität",
    Options = {"FOV", "Distance", "Health"},
    CurrentOption = {"FOV"},
    MultipleOptions = false,
    Flag = "AimPriority",
    Callback = function(o)
        Priority = typeof(o) == "table" and o[1] or o
    end
})

AimbotTab:CreateToggle({
    Name = "Sticky Aim",
    CurrentValue = true,
    Flag = "StickyAim",
    Callback = function(v) StickyAim = v end
})

AimbotTab:CreateSection("Prediction")

AimbotTab:CreateToggle({
    Name = "Prediction aktiviert",
    CurrentValue = true,
    Flag = "PredictionEnabled",
    Callback = function(v) PredictionEnabled = v end
})

AimbotTab:CreateSlider({
    Name = "Prediction Stärke",
    Range = {0, 0.5},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.15,
    Flag = "Prediction",
    Callback = function(v) Prediction = v end
})

AimbotTab:CreateSection("Smoothness")

AimbotTab:CreateSlider({
    Name = "Smooth X (horizontal)",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "SmoothX",
    Callback = function(v) SmoothX = v end
})

AimbotTab:CreateSlider({
    Name = "Smooth Y (vertikal)",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "SmoothY",
    Callback = function(v) SmoothY = v end
})

AimbotTab:CreateSection("🎲 Hit Chance")

AimbotTab:CreateToggle({
    Name = "Hit Chance aktiviert",
    CurrentValue = false,
    Flag = "HitChanceEnabled",
    Callback = function(v) HitChanceEnabled = v end
})

AimbotTab:CreateSlider({
    Name = "Hit Chance",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "HitChance",
    Callback = function(v) HitChance = v end
})

AimbotTab:CreateSlider({
    Name = "Roll Cooldown",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.2,
    Flag = "HitRollCooldown",
    Callback = function(v) HitRollCooldown = v end
})

AimbotTab:CreateSection("🔑 Aim Key")

AimbotTab:CreateToggle({
    Name = "Aim Key aktiviert",
    CurrentValue = false,
    Flag = "AimKeyEnabled",
    Callback = function(v) AimKeyEnabled = v end
})

AimbotTab:CreateDropdown({
    Name = "Aim Key Modus",
    Options = {"Hold", "Toggle"},
    CurrentOption = {"Hold"},
    MultipleOptions = false,
    Flag = "AimKeyMode",
    Callback = function(o)
        AimKeyMode = typeof(o) == "table" and o[1] or o
    end
})

AimbotTab:CreateDropdown({
    Name = "Aim Key Taste",
    Options = {"Rechte Maus", "Linke Maus", "E", "Q", "Shift", "C", "F"},
    CurrentOption = {"Rechte Maus"},
    MultipleOptions = false,
    Flag = "AimKeyBind",
    Callback = function(o)
        local k = typeof(o) == "table" and o[1] or o
        local map = {
            ["Rechte Maus"] = Enum.UserInputType.MouseButton2,
            ["Linke Maus"] = Enum.UserInputType.MouseButton1,
            ["E"] = Enum.KeyCode.E,
            ["Q"] = Enum.KeyCode.Q,
            ["Shift"] = Enum.KeyCode.LeftShift,
            ["C"] = Enum.KeyCode.C,
            ["F"] = Enum.KeyCode.F,
        }
        AimKey = map[k] or Enum.UserInputType.MouseButton2
    end
})

AimbotTab:CreateToggle({
    Name = "Nur beim Schießen aimen",
    CurrentValue = false,
    Flag = "AimOnlyWhenShooting",
    Callback = function(v) AimOnlyWhenShooting = v end
})

AimbotTab:CreateSection("🎨 FOV Design")

AimbotTab:CreateColorPicker({
    Name = "FOV Farbe",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "FOVColor",
    Callback = function(c) FOVColor = c end
})

AimbotTab:CreateSlider({
    Name = "FOV Dicke",
    Range = {1, 5},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 1,
    Flag = "FOVThickness",
    Callback = function(v) FOVThickness = v end
})

AimbotTab:CreateToggle({
    Name = "FOV gefüllt",
    CurrentValue = false,
    Flag = "FOVFilled",
    Callback = function(v) FOVFilled = v end
})

AimbotTab:CreateToggle({
    Name = "Dynamisches FOV",
    CurrentValue = false,
    Flag = "DynamicFOV",
    Callback = function(v) DynamicFOV = v end
})

AimbotTab:CreateSlider({
    Name = "Dynamisches FOV Minimum",
    Range = {10, 200},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 30,
    Flag = "DynamicFOVMin",
    Callback = function(v) DynamicFOVMin = v end
})

-- ═══════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════
local ESPTab = Window:CreateTab("👁️ ESP", nil)

ESPTab:CreateSection("ESP Einstellungen")

ESPTab:CreateToggle({
    Name = "ESP Aktiviert",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v) ESPEnabled = v end
})

ESPTab:CreateToggle({
    Name = "Boxen",
    CurrentValue = true,
    Flag = "ESPBoxes",
    Callback = function(v) ESPBoxes = v end
})

ESPTab:CreateToggle({
    Name = "Tracers (Linien)",
    CurrentValue = true,
    Flag = "ESPTracers",
    Callback = function(v) ESPTracers = v end
})

ESPTab:CreateToggle({
    Name = "Namen",
    CurrentValue = true,
    Flag = "ESPNames",
    Callback = function(v) ESPNames = v end
})

ESPTab:CreateToggle({
    Name = "Health Bars",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(v) ESPHealth = v end
})

ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "ESPTeamCheck",
    Callback = function(v) ESPTeamCheck = v end
})

ESPTab:CreateToggle({
    Name = "Dead Check",
    CurrentValue = true,
    Flag = "ESPDeadCheck",
    Callback = function(v) ESPDeadCheck = v end
})

-- ═══════════════════════════════════
-- NOCLIP TAB
-- ═══════════════════════════════════
local NoclipTab = Window:CreateTab("🚪 Noclip", nil)

NoclipTab:CreateSection("Noclip Einstellungen")

NoclipTab:CreateToggle({
    Name = "Noclip Aktiviert",
    CurrentValue = false,
    Flag = "NoclipEnabled",
    Callback = function(v)
        NoclipEnabled = v
        if not v and not NoclipKeyHeld then
            StopNoclip()
        end
    end
})

NoclipTab:CreateToggle({
    Name = "Noclip per Taste",
    CurrentValue = false,
    Flag = "NoclipKeyEnabled",
    Callback = function(v) NoclipKeyEnabled = v end
})

NoclipTab:CreateDropdown({
    Name = "Noclip Taste",
    Options = {"N", "M", "V", "B", "G", "H"},
    CurrentOption = {"N"},
    MultipleOptions = false,
    Flag = "NoclipKeyBind",
    Callback = function(o)
        local k = typeof(o) == "table" and o[1] or o
        local map = {
            ["N"] = Enum.KeyCode.N,
            ["M"] = Enum.KeyCode.M,
            ["V"] = Enum.KeyCode.V,
            ["B"] = Enum.KeyCode.B,
            ["G"] = Enum.KeyCode.G,
            ["H"] = Enum.KeyCode.H,
        }
        NoclipKey = map[k] or Enum.KeyCode.N
    end
})

NoclipTab:CreateToggle({
    Name = "Fahrzeug Noclip",
    CurrentValue = false,
    Flag = "VehicleNoclip",
    Callback = function(v) VehicleNoclip = v end
})

NoclipTab:CreateSection("ℹ️ Info")

NoclipTab:CreateParagraph({
    Title = "Wie funktioniert Noclip?",
    Content = "Noclip deaktiviert die Kollision deines Charakters. Du kannst durch Wände, Böden und Objekte gehen. Der Toggle muss aktiv bleiben, damit die Kollision deaktiviert bleibt."
})

-- ═══════════════════════════════════
-- CONFIG TAB
-- ═══════════════════════════════════
local ConfigTab = Window:CreateTab("💾 Configs", nil)

ConfigTab:CreateSection("Config Verwaltung")

local ConfigName = "Default"

ConfigTab:CreateInput({
    Name = "Config Name",
    CurrentValue = "Default",
    PlaceholderText = "z.B. Legit, Rage, Test...",
    RemoveTextAfterFocusLost = false,
    Flag = "ConfigNameInput",
    Callback = function(text) ConfigName = text end
})

ConfigTab:CreateButton({
    Name = "💾 Config Speichern",
    Callback = function()
        if not ConfigName or ConfigName == "" then
            Rayfield:Notify({Title = "❌ Fehler", Content = "Bitte einen Config-Namen eingeben!", Duration = 4})
            return
        end
        local ok, err = pcall(function() Rayfield:SaveConfiguration(ConfigName) end)
        if ok then
            Rayfield:Notify({Title = "✅ Gespeichert", Content = "Config '" .. ConfigName .. "' gespeichert!", Duration = 4})
        else
            Rayfield:Notify({Title = "❌ Fehler", Content = tostring(err), Duration = 5})
        end
    end
})

ConfigTab:CreateButton({
    Name = "📂 Config Laden",
    Callback = function()
        if not ConfigName or ConfigName == "" then
            Rayfield:Notify({Title = "❌ Fehler", Content = "Bitte einen Config-Namen eingeben!", Duration = 4})
            return
        end
        local ok, err = pcall(function() Rayfield:LoadConfiguration(ConfigName) end)
        if ok then
            Rayfield:Notify({Title = "✅ Geladen", Content = "Config '" .. ConfigName .. "' geladen!", Duration = 4})
        else
            Rayfield:Notify({Title = "❌ Fehler", Content = "Config nicht gefunden: " .. tostring(err), Duration = 5})
        end
    end
})

ConfigTab:CreateButton({
    Name = "🗑️ Config Löschen",
    Callback = function()
        local ok, err = pcall(function() Rayfield:DeleteConfiguration(ConfigName) end)
        if ok then
            Rayfield:Notify({Title = "🗑️ Gelöscht", Content = "Config '" .. ConfigName .. "' gelöscht!", Duration = 4})
        else
            Rayfield:Notify({Title = "❌ Fehler", Content = tostring(err), Duration = 5})
        end
    end
})

-- ═══════════════════════════════════
-- Start Notify
-- ═══════════════════════════════════
Rayfield:Notify({
    Title = "✅ Geladen",
    Content = "Aimbot • ESP • Noclip bereit!",
    Duration = 5,
    Image = nil
})
