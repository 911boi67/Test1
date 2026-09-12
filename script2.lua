-- ============================================
-- Infected Lands Helper | v4 FINAL
-- Delta Executor | Mobile Fully Optimized
-- ALL BUGS FIXED
-- ============================================

-- ============================================
-- SICHERE RAYFIELD LADUNG
-- ============================================
local Rayfield = nil
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if ok and result then
        Rayfield = result
    else
        warn("[IL Helper] Rayfield konnte nicht geladen werden")
        return
    end
end

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- FIX #16: table.unpack Fallback
-- ============================================
local unpack = table.unpack or unpack

-- ============================================
-- FIX #5 + #1: Drawing Support Check (korrekt)
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
-- FIX #3: math.clamp Fallback
-- ============================================
local function clamp(v, min, max)
    if math.clamp then
        return math.clamp(v, min, max)
    end
    if v < min then return min end
    if v > max then return max end
    return v
end

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
    
    UpdateRate = IsMobile and 30 or 60,
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
-- NPC ERKENNUNG
-- ============================================
local function IsNPC(model)
    if not model or not model.Parent then return false end
    if not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if not (model:FindFirstChild("HumanoidRootPart") 
        or model:FindFirstChild("Torso") 
        or model:FindFirstChild("UpperTorso")) then
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

-- ============================================
-- NPC CACHE (Performance)
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
    
    local ok = pcall(function()
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
    
    if not ok then return {} end
    
    NPCCache = npcs
    LastNPCCache = now
    return npcs
end

-- ============================================
-- ESP SYSTEM (FIXED #4 + #5 + #8)
-- ============================================
local ESPCache = {}
local ESPMeta = {}

local function CreateESP(target, isNPC)
    if not DrawingSupported then return end
    if ESPCache[target] then return end
    
    local color = isNPC and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 200, 255)
    local drawings = {}
    local created = {}
    
    -- FIX #4: Einzeln erstellen, nicht in einem pcall
    local function tryCreate(name, drawingType)
        local ok, d = pcall(function()
            return Drawing.new(drawingType)
        end)
        if ok and d then
            drawings[name] = d
            table.insert(created, d)
            return true
        end
        return false
    end
    
    -- Box Outline
    if tryCreate("BoxOutline", "Square") then
        SafeSet(drawings.BoxOutline, "Thickness", 3)
        SafeSet(drawings.BoxOutline, "Color", Color3.fromRGB(0, 0, 0))
        SafeSet(drawings.BoxOutline, "Filled", false)
        SafeSet(drawings.BoxOutline, "Visible", false)
    end
    
    -- Box
    if tryCreate("Box", "Square") then
        SafeSet(drawings.Box, "Thickness", 1)
        SafeSet(drawings.Box, "Color", color)
        SafeSet(drawings.Box, "Filled", false)
        SafeSet(drawings.Box, "Visible", false)
    end
    
    -- Health BG
    if tryCreate("HealthBG", "Line") then
        SafeSet(drawings.HealthBG, "Thickness", 2)
        SafeSet(drawings.HealthBG, "Color", Color3.fromRGB(0, 0, 0))
        SafeSet(drawings.HealthBG, "Visible", false)
    end
    
    -- Health
    if tryCreate("Health", "Line") then
        SafeSet(drawings.Health, "Thickness", 2)
        SafeSet(drawings.Health, "Color", Color3.fromRGB(0, 255, 0))
        SafeSet(drawings.Health, "Visible", false)
    end
    
    -- Name
    if tryCreate("Name", "Text") then
        SafeSet(drawings.Name, "Size", Settings.ESPTextSize)
        SafeSet(drawings.Name, "Center", true)
        SafeSet(drawings.Name, "Outline", true)
        SafeSet(drawings.Name, "Color", color)
        SafeSet(drawings.Name, "Visible", false)
        -- FIX #12: Font nur einmal versuchen, Warning unterdrücken
        pcall(function() drawings.Name.Font = 2 end)
    end
    
    -- Distance
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
    for _, d in pairs(ESPCache[target]) do
        SafeRemove(d)
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
    if not DrawingSupported then return end
    -- FIX #14: Parent Race Condition
    if not target then return end
    
    local pcall_ok, parent = pcall(function() return target.Parent end)
    if not pcall_ok or not parent then
        RemoveESP(target)
        return
    end
    
    if not ESPCache[target] then
        CreateESP(target, isNPC)
    end
    
    local drawings = ESPCache[target]
    if not drawings or not next(drawings) then return end
    
    -- FIX #14: Alle Property-Zugriffe in pcall
    local ok, humanoid, rootPart, head = pcall(function()
        local h = target:FindFirstChildOfClass("Humanoid")
        local r = target:FindFirstChild("HumanoidRootPart") 
            or target:FindFirstChild("UpperTorso")
            or target:FindFirstChild("Torso")
        local hd = target:FindFirstChild("Head") or r
        return h, r, hd
    end)
    
    if not ok or not humanoid or not rootPart or not head then
        HideAllESP(target)
        return
    end
    
    if humanoid.Health <= 0 then
        HideAllESP(target)
        return
    end
    
    local ok2, dist = pcall(function()
        return (Camera.CFrame.Position - rootPart.Position).Magnitude
    end)
    if not ok2 then HideAllESP(target) return end
    
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
        local healthPercent = clamp(humanoid.Health / maxHP, 0, 1)
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
        if drawings.Health then SafeSet(drawings.Health, "Visible", false) end
        if drawings.HealthBG then SafeSet(drawings.HealthBG, "Visible", false) end
    end
    
    -- Distance
    if isNPC and Settings.NPCDistance and drawings.Distance then
        SafeSet(drawings.Distance, "Text", string.format("[%d]", math.floor(dist)))
        SafeSet(drawings.Distance, "Position", Vector2.new(headPos.X, boxY + boxHeight + 2))
        SafeSet(drawings.Distance, "Size", Settings.ESPTextSize - 1)
        SafeSet(drawings.Distance, "Visible", true)
    elseif drawings.Distance then
        SafeSet(drawings.Distance, "Visible", false)
    end
end

-- ============================================
-- HITBOX EXPANDER (FIX #11)
-- ============================================
local OriginalSizes = {}

local function ExpandHitbox(character, size)
    if not character or not character.Parent then return end
    
    for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso"}) do
        local ok, part = pcall(function() return character:FindFirstChild(partName) end)
        if ok and part and part:IsA("BasePart") then
            if not OriginalSizes[part] then
                OriginalSizes[part] = {
                    Size = part.Size,
                    Transparency = part.Transparency,
                    CanCollide = part.CanCollide,
                    -- FIX #11: Massless kann nil sein
                    Massless = part.Massless,
                }
            end
            pcall(function()
                part.Size = Vector3.new(size, size, size)
                part.Transparency = 0.7
                part.CanCollide = false
                if part.Massless ~= nil then
                    part.Massless = true
                end
            end)
        end
    end
end

local function ResetHitbox(character)
    if not character then return end
    local toRemove = {}
    for part, data in pairs(OriginalSizes) do
        local ok = pcall(function()
            if part and part.Parent and part:IsDescendantOf(character) then
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.CanCollide = data.CanCollide
                if data.Massless ~= nil and part.Massless ~= nil then
                    part.Massless = data.Massless
                end
                table.insert(toRemove, part)
            end
        end)
    end
    for _, part in pairs(toRemove) do
        OriginalSizes[part] = nil
    end
end

-- ============================================
-- AUTO ATTACK (FIX #7 + #9 + #10)
-- ============================================
local LastAttack = 0
local AttackPending = false

local function DoAttack()
    -- FIX #9: Mobile nutzt Button 1 (nicht 0)
    pcall(function()
        local button = IsMobile and 1 or 1
        VirtualInputManager:SendMouseButtonEvent(0, 0, button, true, game, 0)
    end)
    
    task.delay(0.03, function()
        pcall(function()
            local button = IsMobile and 1 or 1
            VirtualInputManager:SendMouseButtonEvent(0, 0, button, false, game, 0)
        end)
    end)
end

local function AutoAttackLoop()
    if not Settings.AutoAttack then return end
    -- FIX #10: Character nil check
    if not LocalPlayer or not LocalPlayer.Character then return end
    
    local ok, myRoot = pcall(function()
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end)
    if not ok or not myRoot then return end
    
    -- FIX #7: Race Condition mit AttackPending
    if AttackPending then return end
    if tick() - LastAttack < Settings.AttackDelay then return end
    
    local closest = nil
    local shortest = Settings.AttackRange
    
    for _, npc in pairs(GetNPCs()) do
        if npc and npc.Parent then
            local root = npc:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (myRoot.Position - root.Position).Magnitude
                if d < shortest then
                    shortest = d
                    closest = npc
                end
            end
        end
    end
    
    if closest then
        AttackPending = true
        LastAttack = tick()
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
        DoAttack()
        AttackPending = false
    end
end

-- ============================================
-- MAIN LOOP (FIX #6 + #13)
-- ============================================
local UpdateAccumulator = 0

RunService.Heartbeat:Connect(function(dt)
    -- FIX #13: Overflow-Schutz
    if dt > 0.5 then dt = 0.5 end
    UpdateAccumulator = UpdateAccumulator + dt
    local interval = 1 / Settings.UpdateRate
    if UpdateAccumulator < interval then return end
    UpdateAccumulator = 0
    
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
            if meta.IsNPC and not activeSet[target] then
                table.insert(toHide, target)
            end
        end
        for _, target in pairs(toHide) do
            HideAllESP(target)
            if not target.Parent then
                RemoveESP(target)
            end
        end
    else
        local toHide = {}
        for target, meta in pairs(ESPMeta) do
            if meta.IsNPC then table.insert(toHide, target) end
        end
        for _, target in pairs(toHide) do HideAllESP(target) end
    end
    
    -- Player ESP (FIX #8: alter Char)
    if Settings.PlayerESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                UpdateESPFor(player.Character, false)
            end
        end
    else
        local toHide = {}
        for target, meta in pairs(ESPMeta) do
            if not meta.IsNPC then table.insert(toHide, target) end
        end
        for _, target in pairs(toHide) do HideAllESP(target) end
    end
    
    -- Cleanup
    local toRemove = {}
    for target in pairs(ESPCache) do
        if not target.Parent then
            table.insert(toRemove, target)
        end
    end
    for _, target in pairs(toRemove) do
        RemoveESP(target)
    end
    
    -- Hitbox
    if Settings.HitboxEnabled then
        for _, npc in pairs(GetNPCs()) do
            ExpandHitbox(npc, Settings.HitboxSize)
        end
    end
    
    -- FIX #6: Auto Attack hier, nicht in eigener Loop
    AutoAttackLoop()
end)

-- Player cleanup
Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        RemoveESP(player.Character)
    end
end)

-- Respawn cleanup (FIX #8)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    for target in pairs(ESPCache) do
        if not target.Parent then RemoveESP(target) end
    end
end)

-- ============================================
-- RAYFIELD UI (FIX #15: Window VOR Notify)
-- ============================================
local Window = Rayfield:CreateWindow({
    Name = "Infected Lands Helper",
    LoadingTitle = "Infected Lands Helper",
    LoadingSubtitle = "v4 | FINAL",
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

SettingsTab:CreateSection("Performance")

SettingsTab:CreateSlider({
    Name = "ESP Update Rate",
    Range = {10, 60},
    Increment = 5,
    Suffix = " FPS",
    CurrentValue = Settings.UpdateRate,
    Flag = "UpdateRate",
    Callback = function(v) Settings.UpdateRate = v end
})

SettingsTab:CreateSection("Darstellung")

SettingsTab:CreateSlider({
    Name = "ESP Text Größe",
    Range = {8, 24},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Settings.ESPTextSize,
    Flag = "ESPTextSize",
    Callback = function(v) Settings.ESPTextSize = v end
})

-- ============================================
-- NOTIFY (FIX #15: Nach Window)
-- ============================================
Rayfield:Notify({
    Title = "Infected Lands Helper v4",
    Content = DrawingSupported 
        and "Geladen! Alle Features verfügbar." 
        or "Geladen! ESP nicht verfügbar (Drawing fehlt).",
    Duration = 6,
    Image = 4483362458
})
