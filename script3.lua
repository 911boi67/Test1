-- ============================================
-- Infected Lands Helper | FIXED VERSION
-- Delta Executor | Mobile & PC
-- ============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    NPCESPEnabled = false,
    NPCBox = true,
    NPCName = true,
    NPCHealth = true,
    NPCDistance = true,
    NPCMaxDistance = 500,
    ESPTextSize = IsMobile and 14 or 13,
    
    PlayerESPEnabled = false,
    PlayerBox = true,
    PlayerName = true,
    PlayerHealth = true,
    
    HitboxEnabled = false,
    HitboxSize = 15,
    
    AutoAttack = false,
    AttackRange = 30,
    AttackDelay = 0.3,
}

-- ============================================
-- HELPER: Sichere Property-Zuweisung
-- ============================================
local function SafeSet(drawing, prop, value)
    pcall(function()
        drawing[prop] = value
    end)
end

local function SafeRemove(drawing)
    pcall(function()
        drawing:Remove()
    end)
end

-- ============================================
-- NPC ERKENNUNG (FIXED: kein doppeltes Sammeln)
-- ============================================
local function IsNPC(model)
    if not model or not model:IsA("Model") then return false end
    if not model.Parent then return false end
    local player = Players:GetPlayerFromCharacter(model)
    if player then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    -- Muss einen Root/Torso haben
    if not (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")) then
        return false
    end
    return true
end

local function IsAlive(model)
    if not model or not model.Parent then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.Health > 0
end

local function GetNPCs()
    local npcs = {}
    local seen = {}
    
    local function scan(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("Model") and IsNPC(obj) and IsAlive(obj) and not seen[obj] then
                seen[obj] = true
                table.insert(npcs, obj)
            end
        end
    end
    
    -- Nur Top-Level + eine Ebene tief scannen (nicht doppelt)
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and IsNPC(obj) then
            if not seen[obj] then
                seen[obj] = true
                table.insert(npcs, obj)
            end
        elseif obj:IsA("Folder") or obj:IsA("Model") then
            scan(obj)
        end
    end
    
    return npcs
end

-- ============================================
-- ESP SYSTEM (FIXED)
-- ============================================
local ESPCache = {}
local ESPMeta = {}  -- Trennt Metadaten von Drawings

local function CreateESP(target, isNPC)
    if ESPCache[target] then return end
    
    local color = isNPC and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 200, 255)
    
    local drawings = {}
    
    -- Box
    drawings.Box = Drawing.new("Square")
    SafeSet(drawings.Box, "Thickness", 1)
    SafeSet(drawings.Box, "Color", color)
    SafeSet(drawings.Box, "Filled", false)
    SafeSet(drawings.Box, "Visible", false)
    
    drawings.BoxOutline = Drawing.new("Square")
    SafeSet(drawings.BoxOutline, "Thickness", 3)
    SafeSet(drawings.BoxOutline, "Color", Color3.fromRGB(0, 0, 0))
    SafeSet(drawings.BoxOutline, "Filled", false)
    SafeSet(drawings.BoxOutline, "Visible", false)
    
    -- Name
    drawings.Name = Drawing.new("Text")
    SafeSet(drawings.Name, "Size", Settings.ESPTextSize)
    SafeSet(drawings.Name, "Center", true)
    SafeSet(drawings.Name, "Outline", true)
    SafeSet(drawings.Name, "Color", color)
    SafeSet(drawings.Name, "Visible", false)
    SafeSet(drawings.Name, "Font", 2)
    
    -- Health
    drawings.HealthBG = Drawing.new("Line")
    SafeSet(drawings.HealthBG, "Thickness", 2)
    SafeSet(drawings.HealthBG, "Color", Color3.fromRGB(0, 0, 0))
    SafeSet(drawings.HealthBG, "Visible", false)
    
    drawings.Health = Drawing.new("Line")
    SafeSet(drawings.Health, "Thickness", 2)
    SafeSet(drawings.Health, "Color", Color3.fromRGB(0, 255, 0))
    SafeSet(drawings.Health, "Visible", false)
    
    -- Distance
    drawings.Distance = Drawing.new("Text")
    SafeSet(drawings.Distance, "Size", Settings.ESPTextSize - 1)
    SafeSet(drawings.Distance, "Center", true)
    SafeSet(drawings.Distance, "Outline", true)
    SafeSet(drawings.Distance, "Color", Color3.fromRGB(255, 255, 255))
    SafeSet(drawings.Distance, "Visible", false)
    SafeSet(drawings.Distance, "Font", 2)
    
    ESPCache[target] = drawings
    ESPMeta[target] = { IsNPC = isNPC }
end

local function RemoveESP(target)
    if not ESPCache[target] then return end
    for _, d in pairs(ESPCache[target]) do
        if typeof(d) == "userdata" or typeof(d) == "table" then
            SafeRemove(d)
        end
    end
    ESPCache[target] = nil
    ESPMeta[target] = nil
end

local function HideAllESP(target)
    if not ESPCache[target] then return end
    for _, d in pairs(ESPCache[target]) do
        SafeSet(d, "Visible", false)
    end
end

local function UpdateESPFor(target, isNPC)
    if not target or not target.Parent then
        RemoveESP(target)
        return
    end
    
    if not ESPCache[target] then
        CreateESP(target, isNPC)
    end
    
    local drawings = ESPCache[target]
    if not drawings then return end
    
    local humanoid = target:FindFirstChild endOfClass("Humanoid")
    local rootPart = target:FindFirstChild("HumanoidRootPart") 
        or target:FindFirstChild("UpperTorso")
        or target:FindFirstChild("Torso")
    local head = target:FindFirstChild("Head") or rootPart
    
    -- FIXED: Nil Checks
    if not humanoid or not rootPart
    
 or not head or humanoid.Health <= 0 then
        HideAllESP(target)
        return
    end
    
    local ok, dist = pcall(function()
        return (Camera.CFrame.Position - rootPart.Position).Magnitude
    end)
    if not ok then HideAllESP(target) return end
    
    local maxDist = isNPC and Settings.NPCMaxDistance or 2000
    if dist > maxDist then
        HideAllESP(target)
        return
    end
    
    local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local rootPos, rootOn = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
    
    if not headOn or not rootOn or headPos.Z < 0 then
        HideAllESP(target)
        return
    end
    
    local boxHeight = math.abs(headPos.Y - rootPos.Y)
    if boxHeight < 1 then boxHeight = 1 end
    local boxWidth = boxHeight * 0.6
    local boxX = headPos.X - boxWidth / 2
    local boxY = headPos.Y
    
    -- FIXED: Position VOR Size setzen
    local showBox = isNPC and Settings.NPCBox or (not isNPC and Settings.PlayerBox)
    if showBox then
        SafeSet(drawings.Box, "Position", Vector2.new(boxX, boxY))
        SafeSet(drawings.Box, "Size", Vector2.new(boxWidth, boxHeight))
        SafeSet(drawings.Box, "Visible", true)
        SafeSet(drawings.BoxOutline, "Position", Vector2.new(boxX, boxY))
        SafeSet(drawings.BoxOutline, "Size", Vector2.new(boxWidth, boxHeight))
        SafeSet(drawings.BoxOutline, "Visible", true)
    else
        SafeSet(drawings.Box, "Visible", false)
        SafeSet(drawings.BoxOutline, "Visible", false)
    end
    
    -- Name (FIXED: sichere Namens-Ermittlung)
    local showName = isNPC and Settings.NPCName or (not isNPC and Settings.PlayerName)
    if showName then
        local name = "Unknown"
        pcall(function() name = target.Name end)
        SafeSet(drawings.Name, "Text", name)
        SafeSet(drawings.Name, "Position", Vector2.new(headPos.X, boxY - Settings.ESPTextSize - 2))
        SafeSet(drawings.Name, "Size", Settings.ESPTextSize)
        SafeSet(drawings.Name, "Visible", true)
    else
        SafeSet(drawings.Name, "Visible", false)
    end
    
    -- Health
    local showHealth = isNPC and Settings.NPCHealth or (not isNPC and Settings.PlayerHealth)
    if showHealth then
        local maxHP = humanoid.MaxHealth
        if maxHP <= 0 then maxHP = 100 end
        local healthPercent = math.clamp(humanoid.Health / maxHP, 0, 1)
        local barHeight = boxHeight * healthPercent
        
        SafeSet(drawings.HealthBG, "From", Vector2.new(boxX - 5, boxY))
        SafeSet(drawings.HealthBG, "To", Vector2.new(boxX - 5, boxY + boxHeight))
        SafeSet(drawings.HealthBG, "Visible", true)
        
        SafeSet(drawings.Health, "From", Vector2.new(boxX - 5, boxY + (boxHeight - barHeight)))
        SafeSet(drawings.Health, "To", Vector2.new(boxX - 5, boxY + boxHeight))
        
        if healthPercent > 0.5 then
            SafeSet(drawings.Health, "Color", Color3.fromRGB(0, 255, 0))
        elseif healthPercent > 0.25 then
            SafeSet(drawings.Health, "Color", Color3.fromRGB(255, 255, 0))
        else
            SafeSet(drawings.Health, "Color", Color3.fromRGB(255, 0, 0))
        end
        SafeSet(drawings.Health, "Visible", true)
    else
        SafeSet(drawings.Health, "Visible", false)
        SafeSet(drawings.HealthBG, "Visible", false)
    end
    
    -- Distance
    local showDist = isNPC and Settings.NPCDistance
    if showDist then
        SafeSet(drawings.Distance, "Text", string.format("[%d]", math.floor(dist)))
        SafeSet(drawings.Distance, "Position", Vector2.new(headPos.X, boxY + boxHeight + 2))
        SafeSet(drawings.Distance, "Size", Settings.ESPTextSize - 1)
        SafeSet(drawings.Distance, "Visible", true)
    else
        SafeSet(drawings.Distance, "Visible", false)
    end
end

-- ============================================
-- HITBOX EXPANDER (FIXED)
-- ============================================
local OriginalSizes = {}

local function ExpandHitbox(character, size)
    if not character or not character.Parent then return    for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso"}) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            if not OriginalSizes[part] then
                OriginalSizes[part] = {
                    Size = part.Size,
                    Transparency = part.Transparency,
                    CanCollide = part.CanCollide,
                    Massless = part.Massless,
                }
            end
            pcall(function()
                part.Size = Vector3.new(size, size, size)
                part.Transparency = 0.7
                part.CanCollide = false
                part.Massless = true
            end)
        end
    end
end

local function ResetHitbox(character)
    if not character then return end
    for part, data in pairs(OriginalSizes) do
        if part and part.Parent and part:IsDescendantOf(character) then
            pcall(function()
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.CanCollide = data.CanCollide
                part.Massless = data.Massless
            end)
            OriginalSizes[part] = nil
        end
    end
end

-- ============================================
-- AUTO ATTACK (FIXED für Mobile)
-- ============================================
local LastAttack = 0

local function DoAttack()
    if IsMobile then
        -- Mobile: touch input simulieren
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    else
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end
end

local function AutoAttackLoop()
    if not Settings.AutoAttack then return end
    if not LocalPlayer.Character then return end
    
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    if tick() - LastAttack < Settings.AttackDelay then return end
    
    local closest = nil
    local shortest = Settings.AttackRange
    
    for _, npc in pairs(GetNPCs()) do
        local root = npc:FindFirstChild("HumanoidRootPart")
        if root then
            local d = (myRoot.Position - root.Position).Magnitude
            if d < shortest then
                shortest = d
                closest = npc
            end
        end
    end
    
    if closest then
        LastAttack = tick()
        -- Tool aktivieren
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
        DoAttack()
    end
end

-- ============================================
-- MAIN LOOP (FIXED: sauberes cleanup)
-- ============================================
RunService.RenderStepped:Connect(function()
    -- NPC ESP
    if Settings.NPCESPEnabled then
        local npcs = GetNPCs()
        local activeSet = {}
        for _, npc in pairs(npcs) do
            activeSet[npc] = true
            UpdateESPFor(npc, true)
        end
        -- Verstecke ESPs von NPCs, die nicht mehr aktiv sind
        for target, meta in pairs(ESPMeta) do
            if meta.IsNPC and not activeSet[target] then
                HideAllESP(target)
                if not target.Parent then
                    RemoveESP(target)
                end
            end
        end
    else
        for target, meta in pairs(ESPMeta) do
            if meta.IsNPC then HideAllESP(target) end
        end
    end
    
    -- Player ESP
    if Settings.PlayerESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                UpdateESPFor(player.Character, false)
            end
        end
    else
        for target, meta in pairs(ESPMeta) do
            if not meta.IsNPC then HideAllESP(target) end
        end
    end
    
    -- Dead ESP cleanup
    for target in pairs(ESPCache) do
        if not target.Parent then
            RemoveESP(target)
        end
    end
    
    -- Hitbox
    if Settings.HitboxEnabled then
        for _, npc in pairs(GetNPCs()) do
            ExpandHitbox(npc, Settings.HitboxSize)
        end
    end
    
    -- Auto Attack
    AutoAttackLoop()
end)

-- Player cleanup
Players.PlayerRemoving:Connect(function(player)
    if player.Character then RemoveESP(player.Character) end
end)

-- ============================================
-- RAYFIELD UI
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Infected Lands Helper",
    LoadingTitle = "Infected Lands Helper",
    LoadingSubtitle = "Fixed Version",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "InfectedLandsHelper",
        FileName = "Config"
    },
    KeySystem = false
})

-- Zombie ESP Tab
local NPCTab = Window:CreateTab("Zombie ESP", 4483362458)

NPCTab:CreateSection("Zombie/NPC ESP")

NPCTab:CreateToggle({
    Name = "Zombie ESP aktivieren",
    CurrentValue = Settings.NPCESPEnabled,
    Flag = "NPCESPEnabled",
    Callback = function(v) Settings.NPCESPEnabled = v end
})

NPCTab:CreateToggle({
    Name = "Box",
    CurrentValue = Settings.NPCBox,
    Flag = "NPCBox",
    Callback = function(v) Settings.NPCBox = v end
})

NPCTab:CreateToggle({
    Name = "Name",
    CurrentValue = Settings.NPCName,
    Flag = "NPCName",
    Callback = function(v) Settings.NPCName = v end
})

NPCTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = Settings.NPCHealth,
    Flag = "NPCHealth",
    Callback = function(v) Settings.NPCHealth = v end
})

NPCTab:CreateToggle({
    Name = "Distanz",
    CurrentValue = Settings.NPCDistance,
    Flag = "NPCDistance",
    Callback = function(v) Settings.NPCDistance = v end
})

NPCTab:CreateSlider({
    Name = "Max. Distanz",
    Range = {50, 2000},
    Increment = 50,
    Suffix = " studs",
    CurrentValue = Settings.NPCMaxDistance,
    Flag = "NPCMaxDistance",
    Callback = function(v) Settings.NPCMaxDistance = v end
})

-- Player ESP Tab
local PlayerTab = Window:CreateTab("Player ESP", 4483362458)

PlayerTab:CreateSection("Spieler ESP")

PlayerTab:CreateToggle({
    Name = "Spieler ESP aktivieren",
    CurrentValue = Settings.PlayerESPEnabled,
    Flag = "PlayerESPEnabled",
    Callback = function(v) Settings.PlayerESPEnabled = v end
})

PlayerTab:CreateToggle({
    Name = "Box",
    CurrentValue = Settings.PlayerBox,
    Flag = "PlayerBox",
    Callback = function(v) Settings.PlayerBox = v end
})

PlayerTab:CreateToggle({
    Name = "Name",
    CurrentValue = Settings.PlayerName,
    Flag = "PlayerName",
    Callback = function(v) Settings.PlayerName = v end
})

PlayerTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = Settings.PlayerHealth,
    Flag = "PlayerHealth",
    Callback = function(v) Settings.PlayerHealth = v end
})

-- Combat Tab
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Hitbox Expander")

CombatTab:CreateToggle({
    Name = "Hitbox Expander (Zombies)",
    CurrentValue = Settings.HitboxEnabled,
    Flag = "HitboxEnabled",
    Callback = function(v)
        Settings.HitboxEnabled = v
        if not v then
            for _, npc in pairs(GetNPCs()) do
                ResetHitbox(npc)
            end
        end
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Größe",
    Range = {5, 30},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = Settings.HitboxSize,
    Flag = "HitboxSize",
    Callback = function(v) Settings.HitboxSize = v end
})

CombatTab:CreateSection("Auto Attack")

CombatTab:CreateToggle({
    Name = "Auto Attack (Zombies)",
    CurrentValue = Settings.AutoAttack,
    Flag = "AutoAttack",
    Callback = function(v) Settings.AutoAttack = v end
})

CombatTab:CreateSlider({
    Name = "Attack Range",
    Range = {10, 100},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = Settings.AttackRange,
    Flag = "AttackRange",
    Callback = function(v) Settings.AttackRange = v end
})

CombatTab:CreateSlider({
    Name = "Attack Delay",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = Settings.AttackDelay,
    Flag = "AttackDelay",
    Callback = function(v) Settings.AttackDelay = v end
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Allgemein")

SettingsTab:CreateSlider({
    Name = "ESP Text Größe",
    Range = {8, 24},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Settings.ESPTextSize,
    Flag = "ESPTextSize",
    Callback = function(v) Settings.ESPTextSize = v end
})

Rayfield:Notify({
    Title = "Infected Lands Helper",
    Content = "Fixed Version geladen! Bugs behoben.",
    Duration = 6,
    Image = 4483362458
})
