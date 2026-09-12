-- Rayfield UI Library laden
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Variablen
local SilentAimEnabled = false
local TeamCheck = true
local WallCheck = false
local FOVCircle = false
local FOV = 100
local SelectedPart = "Head"
local HitChance = 100

-- FOV Circle
local Circle = Drawing.new("Circle")
Circle.Color = Color3.fromRGB(255, 255, 255)
Circle.Thickness = 2
Circle.Radius = FOV
Circle.Filled = false
Circle.Visible = false
Circle.Transparency = 1

-- Ziel finden
local function GetClosestTarget()
    local closest = nil
    local shortestDist = FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local targetPart = char:FindFirstChild(SelectedPart)
            
            if humanoid and humanoid.Health > 0 and targetPart then
                -- Team Check
                if TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end
                
                -- Wall Check
                if WallCheck then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local origin = Camera.CFrame.Position
                    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
                    local result = Workspace:Raycast(origin, direction, rayParams)
                    
                    if result and not result.Instance:IsDescendantOf(char) then
                        continue
                    end
                end
                
                -- Distanz berechnen
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = targetPart
                    end
                end
            end
        end
    end
    
    return closest
end

-- Silent Aim Hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if SilentAimEnabled and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast") then
        local target = GetClosestTarget()
        if target then
            if math.random(1, 100) <= HitChance then
                -- Ray Richtung zum Ziel ändern
                if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
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
    end
    
    return oldNamecall(self, table.unpack(args))
end)

-- FOV Circle Update
RunService.RenderStepped:Connect(function()
    Circle.Position = Vector2.new(Mouse.X, Mouse.Y)
    Circle.Radius = FOV
    Circle.Visible = FOVCircle
end)

-- Rayfield Window erstellen
local Window = Rayfield:CreateWindow({
    Name = "Silent Aim",
    LoadingTitle = "Silent Aim Script",
    LoadingSubtitle = "by ChatGPT",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SilentAim",
        FileName = "Config"
    },
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateSection("Silent Aim")

MainTab:CreateToggle({
    Name = "Silent Aim aktivieren",
    CurrentValue = false,
    Flag = "SilentAimToggle",
    Callback = function(value)
        SilentAimEnabled = value
    end
})

MainTab:CreateSlider({
    Name = "Hit Chance (%)",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "HitChance",
    Callback = function(value)
        HitChance = value
    end
})

MainTab:CreateDropdown({
    Name = "Ziel-Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"},
    CurrentOption = {"Head"},
    Flag = "TargetPart",
    Callback = function(option)
        if typeof(option) == "table" then
            SelectedPart = option[1]
        else
            SelectedPart = option
        end
    end
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Checks")

SettingsTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(value)
        TeamCheck = value
    end
})

SettingsTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheck",
    Callback = function(value)
        WallCheck = value
    end
})

-- FOV Tab
local FOVTab = Window:CreateTab("FOV", 4483362458)

FOVTab:CreateSection("FOV Einstellungen")

FOVTab:CreateToggle({
    Name = "FOV Circle anzeigen",
    CurrentValue = false,
    Flag = "FOVCircle",
    Callback = function(value)
        FOVCircle = value
    end
})

FOVTab:CreateSlider({
    Name = "F ichOV Größe",
    Range = { bestimm10, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "FOVSize",
    Callback = function(value)
        FOV = value
    end
})

Rayfield:Notify({
    Title = "Silent Aim geladen",
    Content = "Das Script wurde erfolgreich geladen!",
    Duration = 5,
    Image = 4483362458
})
