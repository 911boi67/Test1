-- ============================================
-- Infected Lands Helper | v5 FULL
-- Silent Aim + Player ESP + Teleport
-- Delta Mobile | Anti-Cheat Aware
-- ============================================

local Rayfield = nil
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if ok and result then Rayfield = result
    else warn("[IL Helper] Rayfield failed"); return end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local unpack = table.unpack or unpack

-- ============================================
-- ANTI-CHEAT AWARE: Random Delays + Smooth
-- ============================================
local function humanDelay()
    return 0.05 + math.random() * 0.08
end

local function clamp(v, min, max)
    if math.clamp then return math.clamp(v, min, max) end
    if v < min then return min end
    if v > max then return max end
    return v
end

-- ============================================
-- DRAWING CHECK
-- ============================================
local DrawingSupported = false
do
    local ok = pcall(function()
        if type(Drawing) == "table" or type(Drawing) == "userdata" then
            local test = Drawing.new("Square")
            if test then
                test.Visible = false
                test:Remove()
                DrawingSupported = true
            end
        end
    end)
end

-- ============================================
-- FOV CIRCLE
-- ============================================
local FOVCircle = nil
if DrawingSupported then
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = IsMobile and 3 or 2
        FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.Transparency = 1
        FOVCircle.NumSides = 60
    end)
end

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    -- NPC ESP
    NPCESPEnabled = false,
    NPCBox = true,
    NPCName = true,
    NPCHealth = true,
    NPCDistance = true,
    NPCMaxDistance = 500,
    
    -- Player ESP
    PlayerESPEnabled = false,
    PlayerBox = true,
    PlayerName = true,
    PlayerHealth = true,
    PlayerDistance = true,
    PlayerMaxDistance = 2000,
    PlayerTeamCheck = false,
    
    -- Silent Aim
    SilentAimEnabled = false,
    SilentAimFOV = IsMobile and 150 or 120,
    ShowFOVCircle = false,
    AimPart = "Head",
    HitChance = 100,
    SilentAimTeamCheck = true,
    SilentAimWallCheck = false,
    UseScreenCenter = IsMobile,
    
    -- Teleport
    TeleportTarget = "Mouse", -- Mouse / Player
    TeleportSmooth = true,
    TeleportSpeed = 50,
    TeleportOffset = 3,
    
    -- Misc
    ESPTextSize = IsMobile and 14 or 13,
    UpdateRate = IsMobile and 30 or 60,
    DeadCheck = true,
}

-- ============================================
-- SAFE HELPERS
-- ============================================
local function SafeSet(drawing, prop, value)
    if not drawing then return end
    pcall(function() drawing[prop] = value end)
end

local function SafeRemove(drawing)
    if not drawing then return end
    pcall(function()
        if drawing.Remove then drawing:Remove() end
    end)
end

-- ============================================
-- CHARACTER / TEAM HELPERS
-- ============================================
local function IsNPC(model)
    if not model or not model.Parent then return false end
    if not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local h = model:FindFirstChildOfClass("Humanoid")
    if not h then return false end
    if not (model:FindFirstChild("HumanoidRootPart") 
        or model:FindFirstChild("Torso") 
        or model:FindFirstChild("UpperTorso")) then return false end
    return true
end

local function IsAlive(model)
    if not model or not model.Parent then return false end
    local h = model:FindFirstChildOfClass("Humanoid")
    if not h then return false end
    return h.Health > 0
end

local function IsSameTeam(player)
    if not player or not LocalPlayer then return false end
    if not player.Team or not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

-- ============================================
-- NPC CACHE
-- ============================================
local NPCCache = {}
local LastNPCCache = 0
local NPCCacheDuration = 0.2

local function GetNPCs()
    local now = tick()
    if now - LastNPCCache < NPCCacheDuration and #NPCCache > 0 then
        local valid = {}
        for _, npc in pairs(NPCCache) do
            if npc and npc.Parent and IsAlive(npc) then
                table.insert(valid, npc)
            end
        end
        NPCCache = valid
        return valid
    end
    local npcs = {}
    local seen = {}
    pcall(function()
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and IsNPC(obj) and IsAlive(obj) and not seen[obj] then
                seen[obj] = true
                table.insert(npcs, obj)
            elseif (obj:IsA("Folder") or obj:IsA("Model")) and not seen[obj] then
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Model") and IsNPC(child) and IsAlive(child) and not seen[child] then
                        seen[child] = true
                        table.insert(npcs, child)
                    end
                end
            end
        end
    end)
    NPCCache = npcs
    LastNPCCache = now
    return npcs
end

-- ============================================
-- ESP SYSTEM
-- ============================================
local ESPCache = {}
local ESPMeta = {}

local function CreateESP(target, isNPC)
    if not DrawingSupported then return end
    if ESPCache[target] then return end
    
    local color = isNPC and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 200, 255)
    local drawings = {}
    
    local function tryCreate(name, dType)
        local ok, d = pcall(function() return Drawing.new(dType) end)
        if ok and d then drawings[name] = d return true end
        return false
    end
    
    if tryCreate("BoxOutline", "Square") then
        SafeSet(drawings.BoxOutline, "Thickness", 3)
        SafeSet(drawings.BoxOutline, "Color", Color3.fromRGB(0, 0, 0))
        SafeSet(drawings.BoxOutline, "Filled", false)
        SafeSet(drawings.BoxOutline, "Visible", false)
    end
    if tryCreate("Box", "Square") then
        SafeSet(drawings.Box, "Thickness", 1)
        SafeSet(drawings.Box, "Color", color)
        SafeSet(drawings.Box, "Filled", false)
        SafeSet(drawings.Box, "Visible", false)
    end
    if tryCreate("HealthBG", "Line") then
        SafeSet(drawings.HealthBG, "Thickness", 2)
        SafeSet(drawings.HealthBG, "Color", Color3.fromRGB(0, 0, 0))
        SafeSet(drawings.HealthBG, "Visible", false)
    end
    if tryCreate("Health", "Line") then
        SafeSet(drawings.Health, "Thickness", 2)
        SafeSet(drawings.Health, "Color", Color3.fromRGB(0, 255, 0))
        SafeSet(drawings.Health, "Visible", false)
    end
    if tryCreate("Name", "Text") then
        SafeSet(drawings.Name, "Size", Settings.ESPTextSize)
        SafeSet(drawings.Name, "Center", true)
        SafeSet(drawings.Name, "Outline", true)
        SafeSet(drawings.Name, "Color", color)
        SafeSet(drawings.Name, "Visible", false)
        pcall(function() drawings.Name.Font = 2 end)
    end
    if tryCreate("Distance", "Text") then
        SafeSet(drawings.Distance, "Size", Settings.ESPTextSize - 1)
        SafeSet(drawings.Distance, "Center", true)
        SafeSet(drawings.Distance, "Outline", true)
        SafeSet(drawings.Distance, "Color", Color3.fromRGB(255, 255, 255))
        SafeSet(drawings.Distance, "Visible", false)
        pcall(function() drawings.Distance.Font = 2 end)
    end
    
    ESPCache[target] = drawings
    ESPMeta[target] = { IsNPC = isNPC }
end

local function RemoveESP(target)
    if not ESPCache[target] then return end
    for _, d in pairs(ESPCache[target]) do SafeRemove(d) end
    ESPCache[target] = nil
    ESPMeta[target] = nil
end

local function HideAllESP(target)
    if not ESPCache[target] then return end
    for _, d in pairs(ESPCache[target]) do SafeSet(d, "Visible", false) end
end

local function UpdateESPFor(target, isNPC)
    if not DrawingSupported then return end
    if not target then return end
    
    local ok_p, parent = pcall(function() return target.Parent end)
    if not ok_p or not parent then
        RemoveESP(target)
        return
    end
    
    if not ESPCache[target] then CreateESP(target, isNPC) end
    local drawings = ESPCache[target]
    if not drawings or not next(drawings) then return end
    
    local ok, humanoid, rootPart, head = pcall(function()
        local h = target:FindFirstChildOfClass("Humanoid")
        local r = target:FindFirstChild("HumanoidRootPart") 
            or target:FindFirstChild("UpperTorso")
            or target:FindFirstChild("Torso")
        local hd = target:FindFirstChild("Head") or r
        return h, r, hd
    end)
    if not ok or not humanoid or not rootPart or not head then
        HideAllESP(target) return
    end
    if humanoid.Health <= 0 then HideAllESP(target) return end
    
    -- Dead Check
    if Settings.DeadCheck and humanoid.Health <= 0 then
        HideAllESP(target) return
    end
    
    local ok2, dist = pcall(function()
        return (Camera.CFrame.Position - rootPart.Position).Magnitude
    end)
    if not ok2 then HideAllESP(target) return end
    
    local maxDist = isNPC and Settings.NPCMaxDistance or Settings.PlayerMaxDistance
    if dist > maxDist then HideAllESP(target) return end
    
    local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local rootPos, rootOn = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
    if not headOn or not rootOn or headPos.Z < 0 then HideAllESP(target) return end
    
    local boxHeight = math.abs(headPos.Y - rootPos.Y)
    if boxHeight < 1 then boxHeight = 1 end
    local boxWidth = boxHeight * 0.6
    local boxX = headPos.X - boxWidth / 2
    local boxY = headPos.Y
    
    -- Box
    local showBox = isNPC and Settings.NPCBox or (not isNPC and Settings.PlayerBox)
    if showBox then
        if drawings.BoxOutline then
            SafeSet(drawings.BoxOutline, "Position", Vector2.new(boxX, boxY))
            SafeSet(drawings.BoxOutline, "Size", Vector2.new(boxWidth, boxHeight))
            SafeSet(drawings.BoxOutline, "Visible", true)
        end
        if drawings.Box then
            SafeSet(drawings.Box, "Position", Vector2.new(boxX, boxY))
            SafeSet(drawings.Box, "Size", Vector2.new(boxWidth, boxHeight))
            SafeSet(drawings.Box, "Visible", true)
        end
    else
        if drawings.Box then SafeSet(drawings.Box, "Visible", false) end
        if drawings.BoxOutline then SafeSet(drawings.BoxOutline, "Visible", false) end
    end
    
    -- Name
    local showName = isNPC and Settings.NPCName or (not isNPC and Settings.PlayerName)
    if showName and drawings.Name then
        local name = "Unknown"
        pcall(function() name = target.Name end)
        SafeSet(drawings.Name, "Text", name)
        SafeSet(drawings.Name, "Position", Vector2.new(headPos.X, boxY - Settings.ESPTextSize - 2))
        SafeSet(drawings.Name, "Size", Settings.ESPTextSize)
        SafeSet(drawings.Name, "Visible", true)
    elseif drawings.Name then
        SafeSet(drawings.Name, "Visible", false)
    end
    
    -- Health
    local showHealth = isNPC and Settings.NPCHealth or (not isNPC and Settings.PlayerHealth)
    if showHealth and drawings.Health and drawings.HealthBG then
        local maxHP = humanoid.MaxHealth
        if maxHP <= 0 then maxHP = 100 end
        local hp = clamp(humanoid.Health / maxHP, 0, 1)
        local barH = boxHeight * hp
        
        SafeSet(drawings.HealthBG, "From", Vector2.new(boxX - 5, boxY))
        SafeSet(drawings.HealthBG, "To", Vector2.new(boxX - 5, boxY + boxHeight))
        SafeSet(drawings.HealthBG, "Visible", true)
        SafeSet(drawings.Health, "From", Vector2.new(boxX - 5, boxY + (boxHeight - barH)))
        SafeSet(drawings.Health, "To", Vector2.new(boxX - 5, boxY + boxHeight))
        if hp > 0.5 then
            SafeSet(drawings.Health, "Color", Color3.fromRGB(0, 255, 0))
        elseif hp > 0.25 then
            SafeSet(drawings.Health, "Color", Color3.fromRGB(255, 255, 0))
        else
            SafeSet(drawings.Health, "Color", Color3.fromRGB(255, 0, 0))
        end
        SafeSet(drawings.Health, "Visible", true)
    else
        if drawings.Health then SafeSet(drawings.Health, "Visible", false) end
        if drawings.HealthBG then SafeSet(drawings.HealthBG, "Visible", false) end
    end
    
    -- Distance
    local showDist = isNPC and Settings.NPCDistance or (not isNPC and Settings.PlayerDistance)
    if showDist and drawings.Distance then
        SafeSet(drawings.Distance, "Text", string.format("[%d]", math.floor(dist)))
        SafeSet(drawings.Distance, "Position", Vector2.new(headPos.X, boxY + boxHeight + 2))
        SafeSet(drawings.Distance, "Size", Settings.ESPTextSize - 1)
        SafeSet(drawings.Distance, "Visible", true)
    elseif drawings.Distance then
        SafeSet(drawings.Distance, "Visible", false)
    end
end

-- ============================================
-- SILENT AIM
-- ============================================
local TouchPosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
local ActiveTouch = nil

UserInputService.TouchStarted:Connect(function(touch, gp)
    if gp then return end
    if touch.UserInputType == Enum.UserInputType.Touch then
        ActiveTouch = touch
        TouchPosition = Vector2.new(touch.Position.X, touch.Position.Y)
    end
end)

UserInputService.TouchMoved:Connect(function(touch, gp)
    if gp then return end
    if touch == ActiveTouch then
        TouchPosition = Vector2.new(touch.Position.X, touch.Position.Y)
    end
end)

UserInputService.TouchEnded:Connect(function(touch, gp)
    if touch == ActiveTouch then ActiveTouch = nil end
end)

local CachedTarget = nil
local LastTargetRefresh = 0
local TargetCacheDuration = 0.05

local function IsVisible(targetPart)
    if not Settings.SilentAimWallCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    local origin = Camera.CFrame.Position
    local dir = targetPart.Position - origin
    local result = Workspace:Raycast(origin, dir, rayParams)
    if not result then return true end
    if result.Instance:IsDescendantOf(targetPart.Parent) then return true end
    return false
end

local function GetClosestTarget()
    local now = tick()
    if CachedTarget and (now - LastTargetRefresh) < TargetCacheDuration then
        local p = CachedTarget.Parent
        if p and IsAlive(p) then return CachedTarget end
    end
    
    local closest = nil
    local shortestDist = Settings.SilentAimFOV
    
    local refPos
    if Settings.UseScreenCenter then
        refPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif IsMobile then
        refPos = TouchPosition
    else
        refPos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    end
    
    -- Player Targets
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsAlive(player.Character) then
            if Settings.DeadCheck and not IsAlive(player.Character) then continue end
            if Settings.SilentAimTeamCheck and IsSameTeam(player) then continue end
            
            local char = player.Character
            local targetPart = char:FindFirstChild(Settings.AimPart)
                or char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("UpperTorso")
            
            if targetPart and IsVisible(targetPart) then
                local sp, on = Camera:WorldToViewportPoint(targetPart.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - refPos).Magnitude
                    if d < shortestDist then
                        shortestDist = d
                        closest = targetPart
                    end
                end
            end
        end
    end
    
    CachedTarget = closest
    LastTargetRefresh = now
    return closest
end

-- Silent Aim Hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if Settings.SilentAimEnabled and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "Raycast") then
        -- Kamera-Ray Filter (verhindert Bildschirm-Drehen)
        local rayOrigin
        if method == "Raycast" then
            rayOrigin = args[1]
        else
            local ray = args[1]
            if typeof(ray) == "Ray" then rayOrigin = ray.Origin end
        end
        
        if rayOrigin and typeof(rayOrigin) == "Vector3" then
            local distToCam = (rayOrigin - Camera.CFrame.Position).Magnitude
            if distToCam < 1 then
                return oldNamecall(self, unpack(args))
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
                if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                    args[2] = (target.Position - args[1]).Unit * 1000
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

-- ============================================
-- TELEPORT SYSTEM
-- ============================================
local function GetTeleportTargetPosition()
    if Settings.TeleportTarget == "Mouse" then
        -- Mobile: Bildschirmmitte / Touch; PC: Maus
        local pos
        if IsMobile then
            if Settings.UseScreenCenter then
                pos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            else
                pos = TouchPosition
            end
        else
            pos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        end
        
        local ray = Camera:ViewportPointToRay(pos.X, pos.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
        if result then
            return result.Position + result.Normal * Settings.TeleportOffset
        end
    end
    return nil
end

local function TeleportTo(position)
    if not position then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Anti-Cheat: Character Velocity clearen vor Teleport
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    
    if Settings.TeleportSmooth then
        -- Smooth Teleport via Tween (weniger auffällig)
        local dist = (root.Position - position).Magnitude
        local duration = math.max(0.1, dist / Settings.TeleportSpeed)
        
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(position)
        })
        tween:Play()
    else
        -- Instant Teleport
        root.CFrame = CFrame.new(position)
    end
end

local function TeleportToPlayer(playerName)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(playerName:lower()) and p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                TeleportTo(root.Position + Vector3.new(0, Settings.TeleportOffset, 0))
                return true
            end
        end
    end
    return false
end

-- ============================================
-- MAIN LOOP
-- ============================================
local UpdateAccumulator = 0

RunService.Heartbeat:Connect(function(dt)
    if dt > 0.5 then dt = 0.5 end
    UpdateAccumulator = UpdateAccumulator + dt
    local interval = 1 / Settings.UpdateRate
    if UpdateAccumulator < interval then return end
    UpdateAccumulator = 0
    
    -- FOV Circle Update
    if FOVCircle then
        local pos
        if Settings.UseScreenCenter then
            pos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        elseif IsMobile then
            pos = TouchPosition
        else
            pos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        end
        SafeSet(FOVCircle, "Position", pos)
        SafeSet(FOVCircle, "Radius", Settings.SilentAimFOV)
        SafeSet(FOVCircle, "Visible", Settings.ShowFOVCircle and Settings.SilentAimEnabled)
    end
    
    -- NPC ESP
    if Settings.NPCESPEnabled then
        local npcs = GetNPCs()
        local activeSet = {}
        for _, npc in pairs(npcs) do
            if npc and npc.Parent then
                activeSet[npc] = true
                UpdateESPFor(npc, true)
            end
        end
        local toHide = {}
        for target, meta in pairs(ESPMeta) do
            if meta.IsNPC and not activeSet[target] then table.insert(toHide, target) end
        end
        for _, t in pairs(toHide) do
            HideAllESP(t)
            if not t.Parent then RemoveESP(t) end
        end
    else
        local toHide = {}
        for target, meta in pairs(ESPMeta) do
            if meta.IsNPC then table.insert(toHide, target) end
        end
        for _, t in pairs(toHide) do HideAllESP(t) end
    end
    
    -- Player ESP
    if Settings.PlayerESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and IsAlive(player.Character) then
                if Settings.PlayerTeamCheck and IsSameTeam(player) then
                    HideAllESP(player.Character)
                else
                    UpdateESPFor(player.Character, false)
                end
            end
        end
    else
        local toHide = {}
        for target, meta in pairs(ESPMeta) do
            if not meta.IsNPC then table.insert(toHide, target) end
        end
        for _, t in pairs(toHide) do HideAllESP(t) end
    end
    
    -- Cleanup
    local toRemove = {}
    for target in pairs(ESPCache) do
        if not target.Parent then table.insert(toRemove, target) end
    end
    for _, t in pairs(toRemove) do RemoveESP(t) end
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then RemoveESP(player.Character) end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    for target in pairs(ESPCache) do
        if not target.Parent then RemoveESP(target) end
    end
end)

-- ============================================
-- RAYFIELD UI
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Infected Lands Helper",
    LoadingTitle = "Infected Lands Helper",
    LoadingSubtitle = "v5 | Full Features",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "InfectedLandsHelper",
        FileName = "Config"
    },
    KeySystem = false
})

-- ============================================
-- SILENT AIM TAB
-- ============================================
local AimTab = Window:CreateTab("Silent Aim", 4483362458)

AimTab:CreateSection("Silent Aim")

AimTab:CreateToggle({
    Name = "Silent Aim aktivieren",
    CurrentValue = Settings.SilentAimEnabled,
    Flag = "SilentAimEnabled",
    Callback = function(v) Settings.SilentAimEnabled = v end
})

AimTab:CreateSlider({
    Name = "Hit Chance",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = Settings.HitChance,
    Flag = "HitChance",
    Callback = function(v) Settings.HitChance = v end
})

AimTab:CreateDropdown({
    Name = "Ziel-Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"},
    CurrentOption = {Settings.AimPart},
    Flag = "AimPart",
    Callback = function(opt)
        if type(opt) == "table" then Settings.AimPart = opt[1]
        else Settings.AimPart = opt end
    end
})

AimTab:CreateSection("FOV")

AimTab:CreateToggle({
    Name = "FOV Circle anzeigen",
    CurrentValue = Settings.ShowFOVCircle,
    Flag = "ShowFOVCircle",
    Callback = function(v) Settings.ShowFOVCircle = v end
})

AimTab:CreateSlider({
    Name = "FOV Größe",
    Range = {30, 600},
    Increment = 10,
    Suffix = "px",
    CurrentValue = Settings.SilentAimFOV,
    Flag = "SilentAimFOV",
    Callback = function(v) Settings.SilentAimFOV = v end
})

AimTab:CreateSection("Checks")

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.SilentAimTeamCheck,
    Flag = "SACheck",
    Callback = function(v) Settings.SilentAimTeamCheck = v end
})

AimTab:CreateToggle({
    Name = "Wall Check (Sichtbarkeit)",
    CurrentValue = Settings.SilentAimWallCheck,
    Flag = "SAWall",
    Callback = function(v) Settings.SilentAimWallCheck = v end
})

-- ============================================
-- PLAYER ESP TAB
-- ============================================
local PESPTab = Window:CreateTab("Player ESP", 4483362458)

PESPTab:CreateSection("Spieler ESP")

PESPTab:CreateToggle({
    Name = "Spieler ESP aktivieren",
    CurrentValue = Settings.PlayerESPEnabled,
    Flag = "PlayerESPEnabled",
    Callback = function(v) Settings.PlayerESPEnabled = v end
})

PESPTab:CreateToggle({
    Name = "Box",
    CurrentValue = Settings.PlayerBox,
    Flag = "PlayerBox",
    Callback = function(v) Settings.PlayerBox = v end
})

PESPTab:CreateToggle({
    Name = "Name",
    CurrentValue = Settings.PlayerName,
    Flag = "PlayerName",
    Callback = function(v) Settings.PlayerName = v end
})

PESPTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = Settings.PlayerHealth,
    Flag = "PlayerHealth",
    Callback = function(v) Settings.PlayerHealth = v end
})

PESPTab:CreateToggle({
    Name = "Distanz",
    CurrentValue = Settings.PlayerDistance,
    Flag = "PlayerDistance",
    Callback = function(v) Settings.PlayerDistance = v end
})

PESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.PlayerTeamCheck,
    Flag = "PTeamCheck",
    Callback = function(v) Settings.PlayerTeamCheck = v end
})

PESPTab:CreateSlider({
    Name = "Max. Distanz",
    Range = {100, 5000},
    Increment = 100,
    Suffix = " studs",
    CurrentValue = Settings.PlayerMaxDistance,
    Flag = "PlayerMaxDistance",
    Callback = function(v) Settings.PlayerMaxDistance = v end
})

-- ============================================
-- ZOMBIE ESP TAB
-- ============================================
local ZTab = Window:CreateTab("Zombie ESP", 4483362458)

ZTab:CreateSection("Zombie/NPC ESP")

ZTab:CreateToggle({
    Name = "Zombie ESP aktivieren",
    CurrentValue = Settings.NPCESPEnabled,
    Flag = "NPCESPEnabled",
    Callback = function(v) Settings.NPCESPEnabled = v end
})

ZTab:CreateToggle({
    Name = "Box",
    CurrentValue = Settings.NPCBox,
    Flag = "NPCBox",
    Callback = function(v) Settings.NPCBox = v end
})

ZTab:CreateToggle({
    Name = "Name",
    CurrentValue = Settings.NPCName,
    Flag = "NPCName",
    Callback = function(v) Settings.NPCName = v end
})

ZTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = Settings.NPCHealth,
    Flag = "NPCHealth",
    Callback = function(v) Settings.NPCHealth = v end
})

ZTab:CreateToggle({
    Name = "Distanz",
    CurrentValue = Settings.NPCDistance,
    Flag = "NPCDistance",
    Callback = function(v) Settings.NPCDistance = v end
})

ZTab:CreateSlider({
    Name = "Max. Distanz",
    Range = {50, 2000},
    Increment = 50,
    Suffix = " studs",
    CurrentValue = Settings.NPCMaxDistance,
    Flag = "NPCMaxDistance",
    Callback = function(v) Settings.NPCMaxDistance = v end
})

-- ============================================
-- TELEPORT TAB
-- ============================================
local TPTab = Window:CreateTab("Teleport", 4483362458)

TPTab:CreateSection("Teleport Ziel")

TPTab:CreateDropdown({
    Name = "Teleport-Modus",
    Options = {"Mouse", "Player"},
    CurrentOption = {Settings.TeleportTarget},
    Flag = "TeleportTarget",
    Callback = function(opt)
        if type(opt) == "table" then Settings.TeleportTarget = opt[1]
        else Settings.TeleportTarget = opt end
    end
})

TPTab:CreateSection("Teleport Einstellungen")

TPTab:CreateToggle({
    Name = "Smooth Teleport (weniger auffällig)",
    CurrentValue = Settings.TeleportSmooth,
    Flag = "TeleportSmooth",
    Callback = function(v) Settings.TeleportSmooth = v end
})

TPTab:CreateSlider({
    Name = "Teleport Speed",
    Range = {20, 500},
    Increment = 10,
    Suffix = " studs/s",
    CurrentValue = Settings.TeleportSpeed,
    Flag = "TeleportSpeed",
    Callback = function(v) Settings.TeleportSpeed = v end
})

TPTab:CreateSlider({
    Name = "Teleport Offset",
    Range = {0, 20},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = Settings.TeleportOffset,
    Flag = "TeleportOffset",
    Callback = function(v) Settings.TeleportOffset = v end
})

TPTab:CreateSection("Aktionen")

TPTab:CreateButton({
    Name = "📍 Zu Maus/Touch teleportieren",
    Callback = function()
        local pos = GetTeleportTargetPosition()
        if pos then TeleportTo(pos) end
    end
})

TPTab:CreateInput({
    Name = "Spieler Name",
    PlaceholderText = "Spieler Name eingeben",
    RemoveTextAfterFocusLost = false,
    Flag = "TPPlayerName",
    Callback = function(text)
        if text and text ~= "" then
            TeleportToPlayer(text)
        end
    end
})

-- ============================================
-- SETTINGS TAB
-- ============================================
local STab = Window:CreateTab("Settings", 4483362458)

STab:CreateSection("Performance")

STab:CreateSlider({
    Name = "ESP Update Rate",
    Range = {10, 60},
    Increment = 5,
    Suffix = " FPS",
    CurrentValue = Settings.UpdateRate,
    Flag = "UpdateRate",
    Callback = function(v) Settings.UpdateRate = v end
})

STab:CreateSection("Darstellung")

STab:CreateSlider({
    Name = "ESP Text Größe",
    Range = {8, 24},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Settings.ESPTextSize,
    Flag = "ESPTextSize",
    Callback = function(v) Settings.ESPTextSize = v end
})

STab:CreateSection("Misc")

STab:CreateToggle({
    Name = "Dead Check (tote ignorieren)",
    CurrentValue = Settings.DeadCheck,
    Flag = "DeadCheck",
    Callback = function(v) Settings.DeadCheck = v end
})

STab:CreateToggle({
    Name = "Bildschirmmitte nutzen (Mobile)",
    CurrentValue = Settings.UseScreenCenter,
    Flag = "UseScreenCenter",
    Callback = function(v) Settings.UseScreenCenter = v end
})

-- ============================================
-- NOTIFY
-- ============================================
Rayfield:Notify({
    Title = "Infected Lands Helper v5",
    Content = DrawingSupported 
        and "Geladen! Silent Aim + ESP + Teleport bereit." 
        or "Geladen! ESP nicht verfügbar (Drawing fehlt).",
    Duration = 6,
    Image = 4483362458
})
