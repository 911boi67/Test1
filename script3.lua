-- ============================================
-- SILENT AIM + ESP | Mobile & PC Support
-- Rayfield UI | Komplett überarbeitet
-- ============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Mobile Erkennung
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- VARIABLEN
-- ============================================
local Settings = {
    -- Silent Aim
    SilentAimEnabled = false,
    TeamCheck = true,
    WallCheck = false,
    FOVCircle = false,
    FOV = IsMobile and 150 or 120,
    SelectedPart = "Head",
    HitChance = 100,
    VisibleCheck = true,
    UseScreenCenter = IsMobile,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = false,
    ESPTeamCheck = true,
    ESPMaxDistance = 1000,
    ESPTextSize = IsMobile and 14 or 13,
    ESPFillBox = false,
    
    -- Misc
    DeadCheck = true,
}

-- ============================================
-- TOUCH TRACKING (Kamera-freundlich)
-- ============================================
local TouchPosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
local ActiveTouch = nil

UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
    if gameProcessed then return end
    if touch.UserInputType == Enum.UserInputType.Touch then
        ActiveTouch = touch
        TouchPosition = Vector2.new(touch.Position.X, touch.Position.Y)
    end
end)

UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
    if gameProcessed then return end
    if touch == ActiveTouch then
        TouchPosition = Vector2.new(touch.Position.X, touch.Position.Y)
    end
end)

UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
    if touch == ActiveTouch then
        ActiveTouch = nil
    end
end)

-- ============================================
-- FOV CIRCLE
-- ============================================
local FOVCircleDrawing = Drawing.new("Circle")
FOVCircleDrawing.Color = Color3.fromRGB(255, 255, 255)
FOVCircleDrawing.Thickness = IsMobile and 3 or 2
FOVCircleDrawing.Radius = Settings.FOV
FOVCircleDrawing.Filled = false
FOVCircleDrawing.Visible = false
FOVCircleDrawing.Transparency = 1
FOVCircleDrawing.NumSides = 60

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Prüft ob Spieler tot ist
local function IsPlayerDead(player)
    if not player.Character then return true end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return true end
    if humanoid.Health <= 0 then return true end
    return false
end

-- Prüft Team
local function IsSameTeam(player)
    if not Settings.TeamCheck and not Settings.ESPTeamCheck then return false end
    if player.Team == nil or LocalPlayer.Team == nil then return false end
    return player.Team == LocalPlayer.Team
end

-- Wall Check (Sichtbarkeit)
local function IsVisible(targetPart)
    if not Settings.VisibleCheck and not Settings.WallCheck then return true end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    if not result then return true end
    if result.Instance:IsDescendantOf(targetPart.Parent) then return true end
    return false
end

-- ============================================
-- TARGET FINDING (Silent Aim)
-- ============================================
local CachedTarget = nil
local LastTargetRefresh = 0
local CacheDuration = 0.05

local function GetClosestTarget()
    local now = tick()
    if CachedTarget and (now - LastTargetRefresh) < CacheDuration then
        if CachedTarget.Parent and not IsPlayerDead(Players:GetPlayerFromCharacter(CachedTarget.Parent)) then
            return CachedTarget
        end
    end
    
    local closest = nil
    local shortestDist = Settings.FOV
    
    local refPos
    if Settings.UseScreenCenter then
        refPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif IsMobile then
        refPos = TouchPosition
    else
        refPos = Vector2.new(Mouse.X, Mouse.Y)
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Dead Check
            if Settings.DeadCheck and IsPlayerDead(player) then
                continue
            end
            
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local targetPart = char:FindFirstChild(Settings.SelectedPart)
            
            if not humanoid or not targetPart then continue end
            if humanoid.Health <= 0 then continue end
            
            -- Team Check
            if Settings.TeamCheck and IsSameTeam(player) then
                continue
            end
            
            -- Wall/Visible Check
            if (Settings.WallCheck or Settings.VisibleCheck) and not IsVisible(targetPart) then
                continue
            end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen and screenPos.Z > 0 then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - refPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = targetPart
                end
            end
        end
    end
    
    CachedTarget = closest
    LastTargetRefresh = now
    return closest
end

-- ============================================
-- SILENT AIM HOOK
-- ============================================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if Settings.SilentAimEnabled and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "Raycast") then
        
        -- Kamera-Ray erkennen und ignorieren (verhindert Kamera-Drehen)
        local rayOrigin
        if method == "Raycast" then
            rayOrigin = args[1]
        else
            local ray = args[1]
            if typeof(ray) == "Ray" then
                rayOrigin = ray.Origin
            end
        end
        
        if rayOrigin and typeof(rayOrigin) == "Vector3" then
            local distToCamera = (rayOrigin - Camera.CFrame.Position).Magnitude
            if distToCamera < 1 then
                return oldNamecall(self, table.unpack(args))
            end
        end
        
        local target = GetClosestTarget()
        if target and math.random(1, 100) <= Settings.HitChance then
            if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                local ray = args[1]
                if typeof(ray) == "Ray" then
                    local newDir = (target.Position - ray.Origin).Unit * 1000
                    args[1] = Ray.new(ray.Origin, newDir)
                end
            elseif method == "Raycast" then
                local origin = args[1]
                if typeof(origin) == "Vector3" and typeof(args[2]) == "Vector3" then
                    args[2] = (target.Position - origin).Unit * 1000
                end
            end
        end
    end
    
    return oldNamecall(self, table.unpack(args))
end)

-- ============================================
-- ESP SYSTEM
-- ============================================
local ESPCache = {}

local function CreateESP(player)
    if ESPCache[player] then return end
    
    local drawings = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Line"),
        HealthBG = Drawing.new("Line"),
        Distance = Drawing.new("Text"),
    }
    
    -- Box
    drawings.Box.Thickness = 1
    drawings.Box.Color = Color3.fromRGB(255, 255, 255)
    drawings.Box.Filled = false
    drawings.Box.Visible = false
    
    drawings.BoxOutline.Thickness = 3
    drawings.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    drawings.BoxOutline.Filled = false
    drawings.BoxOutline.Visible = false
    
    -- Name
    drawings.Name.Size = Settings.ESPTextSize
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Color = Color3.fromRGB(255, 255, 255)
    drawings.Name.Visible = false
    drawings.Name.Font = 2
    
    -- Health Bar
    drawings.HealthBG.Thickness = 2
    drawings.HealthBG.Color = Color3.fromRGB(0, 0, 0)
    drawings.HealthBG.Visible = false
    
    drawings.Health.Thickness = 2
    drawings.Health.Color = Color3.fromRGB(0, 255, 0)
    drawings.Health.Visible = false
    
    -- Distance
    drawings.Distance.Size = Settings.ESPTextSize - 1
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Color = Color3.fromRGB(255, 255, 255)
    drawings.Distance.Visible = false
    drawings.Distance.Font = 2
    
    ESPCache[player] = drawings
end

local function RemoveESP(player)
    if not ESPCache[player] then return end
    for _, drawing in pairs(ESPCache[player]) do
        drawing:Remove()
    end
    ESPCache[player] = nil
end

-- ESP Update Loop
RunService.RenderStepped:Connect(function()
    -- FOV Circle Update
    if Settings.UseScreenCenter then
        FOVCircleDrawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif IsMobile then
        FOVCircleDrawing.Position = TouchPosition
    else
        FOVCircleDrawing.Position = Vector2.new(Mouse.X, Mouse.Y)
    end
    FOVCircleDrawing.Radius = Settings.FOV
    FOVCircleDrawing.Visible = Settings.FOVCircle and Settings.SilentAimEnabled
    
    -- ESP Update
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        if not ESPCache[player] then
            CreateESP(player)
        end
        
        local drawings = ESPCache[player]
        if not drawings then continue end
        
        local shouldDraw = Settings.ESPEnabled
        
        if shouldDraw then
            -- Team Check
            if Settings.ESPTeamCheck and IsSameTeam(player) then
                shouldDraw = false
            end
            
            -- Dead Check
            if Settings.DeadCheck and IsPlayerDead(player) then
                shouldDraw = false
            end
            
            if shouldDraw then
                local char = player.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head")
                
                if not char or not humanoid or not rootPart or humanoid.Health <= 0 then
                    shouldDraw = false
                else
                    -- Distanz Check
                    local distToPlayer = (Camera.CFrame.Position - rootPart.Position).Magnitude
                    if distToPlayer > Settings.ESPMaxDistance then
                        shouldDraw = false
                    end
                    
                    if shouldDraw then
                        -- Berechne Box-Größe aus Head + RootPart
                        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                        
                        if headOnScreen and rootOnScreen then
                            local boxHeight = math.abs(headPos.Y - rootPos.Y)
                            local boxWidth = boxHeight * 0.6
                            
                            local boxX = headPos.X - boxWidth / 2
                            local boxY = headPos.Y
                            
                            -- Box
                            if Settings.ESPBox then
                                drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
                                drawings.Box.Position = Vector2.new(boxX, boxY)
                                drawings.Box.Visible = true
                                
                                drawings.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                                drawings.BoxOutline.Position = Vector2.new(boxX, boxY)
                                drawings.BoxOutline.Visible = true
                            else
                                drawings.Box.Visible = false
                                drawings.BoxOutline.Visible = false
                            end
                            
                            -- Name
                            if Settings.ESPName then
                                drawings.Name.Text = player.Name
                                drawings.Name.Position = Vector2.new(headPos.X, boxY - Settings.ESPTextSize - 2)
                                drawings.Name.Size = Settings.ESPTextSize
                                drawings.Name.Visible = true
                            else
                                drawings.Name.Visible = false
                            end
                            
                            -- Health Bar
                            if Settings.ESPHealth then
                                local healthPercent = humanoid.Health / humanoid.MaxHealth
                                local barHeight = boxHeight * healthPercent
                                
                                drawings.HealthBG.From = Vector2.new(boxX - 5, boxY)
                                drawings.HealthBG.To = Vector2.new(boxX - 5, boxY + boxHeight)
                                drawings.HealthBG.Visible = true
                                
                                drawings.Health.From = Vector2.new(boxX - 5, boxY + (boxHeight - barHeight))
                                drawings.Health.To = Vector2.new(boxX - 5, boxY + boxHeight)
                                
                                -- Farbe: Grün → Gelb → Rot
                                if healthPercent > 0.5 then
                                    drawings.Health.Color = Color3.fromRGB(0, 255, 0)
                                elseif healthPercent > 0.25 then
                                    drawings.Health.Color = Color3.fromRGB(255, 255, 0)
                                else
                                    drawings.Health.Color = Color3.fromRGB(255, 0, 0)
                                end
                                drawings.Health.Visible = true
                            else
                                drawings.Health.Visible = false
                                drawings.HealthBG.Visible = false
                            end
                            
                            -- Distance
                            if Settings.ESPDistance then
                                drawings.Distance.Text = string.format("[%d studs]", math.floor(distToPlayer))
                                drawings.Distance.Position = Vector2.new(headPos.X, boxY + boxHeight + 2)
                                drawings.Distance.Size = Settings.ESPTextSize - 1
                                drawings.Distance.Visible = true
                            else
                                drawings.Distance.Visible = false
                            end
                            
                            goto continue
                        end
                    end
                end
            end
        end
        
        -- Hide all drawings
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
        
        ::continue::
    end
end)

-- Cleanup on Player Removing
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- ============================================
-- RAYFIELD UI
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Nigger NAZI UI",
    LoadingTitle = "NDSAP UI WIRD GELADEN ...",
    LoadingSubtitle = "Nigger NAZI UI Mobile & PC Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SilentAimESP",
        FileName = "Config"
    },
    KeySystem = false
})

-- ============================================
-- AIMBOT TAB
-- ============================================
local AimbotTab = Window:CreateTab("Silent Aim", 4483362458)

AimbotTab:CreateSection("Silent Aim")

AimbotTab:CreateToggle({
    Name = "Silent Aim aktivieren",
    CurrentValue = Settings.SilentAimEnabled,
    Flag = "SilentAimEnabled",
    Callback = function(value)
        Settings.SilentAimEnabled = value
    end
})

AimbotTab:CreateSlider({
    Name = "Hit Chance (%)",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = Settings.HitChance,
    Flag = "HitChance",
    Callback = function(value)
        Settings.HitChance = value
    end
})

AimbotTab:CreateDropdown({
    Name = "Ziel-Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"},
    CurrentOption = {Settings.SelectedPart},
    Flag = "TargetPart",
    Callback = function(option)
        if typeof(option) == "table" then
            Settings.SelectedPart = option[1]
        else
            Settings.SelectedPart = option
        end
    end
})

AimbotTab:CreateSection("Checks")

AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.TeamCheck,
    Flag = "TeamCheck",
    Callback = function(value)
        Settings.TeamCheck = value
    end
})

AimbotTab:CreateToggle({
    Name = "Wall Check (Sichtbarkeit)",
    CurrentValue = Settings.VisibleCheck,
    Flag = "WallCheck",
    Callback = function(value)
        Settings.VisibleCheck = value
        Settings.WallCheck = value
    end
})

AimbotTab:CreateToggle({
    Name = "Dead Check (tote ignorieren)",
    CurrentValue = Settings.DeadCheck,
    Flag = "DeadCheck",
    Callback = function(value)
        Settings.DeadCheck = value
    end
})

AimbotTab:CreateSection("FOV")

AimbotTab:CreateToggle({
    Name = "FOV Circle anzeigen",
    CurrentValue = Settings.FOVCircle,
    Flag = "FOVCircle",
    Callback = function(value)
        Settings.FOVCircle = value
    end
})

AimbotTab:CreateSlider({
    Name = "FOV Größe",
    Range = {30, 600},
    Increment = 10,
    Suffix = "px",
    CurrentValue = Settings.FOV,
    Flag = "FOVSize",
    Callback = function(value)
        Settings.FOV = value
    end
})

-- ============================================
-- ESP TAB
-- ============================================
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateSection("ESP Hauptschalter")

ESPTab:CreateToggle({
    Name = "ESP aktivieren",
    CurrentValue = Settings.ESPEnabled,
    Flag = "ESPEnabled",
    Callback = function(value)
        Settings.ESPEnabled = value
    end
})

ESPTab:CreateSection("ESP Elemente")

ESPTab:CreateToggle({
    Name = "Box anzeigen",
    CurrentValue = Settings.ESPBox,
    Flag = "ESPBox",
    Callback = function(value)
        Settings.ESPBox = value
    end
})

ESPTab:CreateToggle({
    Name = "Name anzeigen",
    CurrentValue = Settings.ESPName,
    Flag = "ESPName",
    Callback = function(value)
        Settings.ESPName = value
    end
})

ESPTab:CreateToggle({
    Name = "Health Bar anzeigen",
    CurrentValue = Settings.ESPHealth,
    Flag = "ESPHealth",
    Callback = function(value)
        Settings.ESPHealth = value
    end
})

ESPTab:CreateToggle({
    Name = "Distanz anzeigen",
    CurrentValue = Settings.ESPDistance,
    Flag = "ESPDistance",
    Callback = function(value)
        Settings.ESPDistance = value
    end
})

ESPTab:CreateSection("ESP Einstellungen")

ESPTab:CreateToggle({
    Name = "ESP Team Check",
    CurrentValue = Settings.ESPTeamCheck,
    Flag = "ESPTeamCheck",
    Callback = function(value)
        Settings.ESPTeamCheck = value
    end
})

ESPTab:CreateSlider({
    Name = "Max. Distanz",
    Range = {100, 5000},
    Increment = 100,
    Suffix = " studs",
    CurrentValue = Settings.ESPMaxDistance,
    Flag = "ESPMaxDistance",
    Callback = function(value)
        Settings.ESPMaxDistance = value
    end
})

ESPTab:CreateSlider({
    Name = "Text Größe",
    Range = {8, 24},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Settings.ESPTextSize,
    Flag = "ESPTextSize",
    Callback = function(value)
        Settings.ESPTextSize = value
    end
})

-- ============================================
-- MOBILE TAB
-- ============================================
local MobileTab = Window:CreateTab("Mobile", 4483362458)

MobileTab:CreateSection("Mobile Steuerung")

MobileTab:CreateToggle({
    Name = "Bildschirmmitte nutzen (empfohlen)",
    CurrentValue = Settings.UseScreenCenter,
    Flag = "UseScreenCenter",
    Callback = function(value)
        Settings.UseScreenCenter = value
    end
})

MobileTab:CreateParagraph({
    Title = "📱 Mobile Tipp",
    Content = "Wenn sich dein Bildschirm dreht: Aktiviere 'Bildschirmmitte nutzen'. Dann zielst du einfach mit dem Crosshair in der Mitte."
})

-- ============================================
-- NOTIFY
-- ============================================
Rayfield:Notify({
    Title = "Silent Aim + ESP geladen",
    Content = "Alle Features sind bereit! " .. (IsMobile and "(Mobile Mode)" or "(PC Mode)"),
    Duration = 5,
    Image = 4483362458
})
