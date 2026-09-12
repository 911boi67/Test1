-- Jumpscare UI im MVSS DUELS Style (Onion UI Library Version)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

------------------------------------------------------------
-- ONION UI LIBRARY LADEN
------------------------------------------------------------
local Onion = loadstring(game:HttpGet("https://raw.githubusercontent.com/OnionHub/OnyxUI/main/OnionUI.lua"))()

------------------------------------------------------------
-- IDs
------------------------------------------------------------
local IMAGE_ID = "rbxassetid://12412007525"
local SOUND_ID = "rbxassetid://140617516722342"

------------------------------------------------------------
-- SCREEN GUI (MAX DisplayOrder)
------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JumpscareUI"
ScreenGui.DisplayOrder = 2147483647
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------
-- WARNUNG: ROTER TEXT (erst nach Trigger sichtbar)
------------------------------------------------------------
local WarningLabel = Instance.new("TextLabel")
WarningLabel.Name = "WarningLabel"
WarningLabel.Size = UDim2.new(1, 0, 0, 120)
WarningLabel.Position = UDim2.new(0, 0, 0.5, -60)
WarningLabel.BackgroundTransparency = 1
WarningLabel.Text = "DONT CHEAT IN GAMES"
WarningLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
WarningLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
WarningLabel.TextStrokeTransparency = 0
WarningLabel.Font = Enum.Font.Code
WarningLabel.TextScaled = true
WarningLabel.TextWrapped = true
WarningLabel.ZIndex = 2000
WarningLabel.Visible = false
WarningLabel.Parent = ScreenGui

-- Puls-Effekt
task.spawn(function()
    while WarningLabel.Parent do
        if WarningLabel.Visible then
            for i = 0, 1, 0.02 do
                local alpha = 0.5 + 0.5 * math.abs(math.sin(i * math.pi))
                WarningLabel.TextTransparency = 1 - alpha
                task.wait(0.03)
            end
        else
            task.wait(0.1)
        end
    end
end)

------------------------------------------------------------
-- Jumpscare Overlay
------------------------------------------------------------
local JumpscareImage = Instance.new("ImageLabel")
JumpscareImage.Name = "JumpscareImage"
JumpscareImage.Size = UDim2.new(1, 0, 1, 0)
JumpscareImage.Position = UDim2.new(0, 0, 0, 0)
JumpscareImage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
JumpscareImage.BackgroundTransparency = 0
JumpscareImage.BorderSizePixel = 0
JumpscareImage.Image = IMAGE_ID
JumpscareImage.ImageTransparency = 1
JumpscareImage.ScaleType = Enum.ScaleType.Stretch
JumpscareImage.Visible = false
JumpscareImage.ZIndex = 900
JumpscareImage.Parent = ScreenGui

------------------------------------------------------------
-- SOUND STACKING → effektiv VOLUME 100
------------------------------------------------------------
local SOUND_COUNT = 10
local sounds = {}

for i = 1, SOUND_COUNT do
    local s = Instance.new("Sound")
    s.Name = "JumpscareSound_" .. i
    s.SoundId = SOUND_ID
    s.Volume = 10
    s.Looped = true
    s.PlayOnRemove = false
    s.Parent = ScreenGui
    table.insert(sounds, s)
end

-- Fallback: wenn Sound nicht lädt, versuche klassische ID
task.spawn(function()
    task.wait(1)
    if sounds[1] and sounds[1].TimeLength == 0 then
        warn("[Jumpscare] Sound-ID ungültig – nutze Fallback")
        for _, s in ipairs(sounds) do
            s.SoundId = "rbxassetid://131961136"
        end
    end
end)

local function playAllSounds()
    for _, s in ipairs(sounds) do
        s.Volume = 10
        s.Looped = true
        s:Play()
    end
end

------------------------------------------------------------
-- JUMPSCARE FUNKTION
------------------------------------------------------------
local triggered = false

local function triggerJumpscare()
    if triggered then return end
    triggered = true

    -- Overlay einblenden
    JumpscareImage.Visible = true
    JumpscareImage.ImageTransparency = 1
    JumpscareImage.BackgroundTransparency = 0

    TweenService:Create(
        JumpscareImage,
        TweenInfo.new(0.05, Enum.EasingStyle.Linear),
        { ImageTransparency = 0 }
    ):Play()

    -- Roten Text einblenden
    WarningLabel.Visible = true

    -- Sound-Stack starten (Volume 100)
    playAllSounds()

    -- Onion Fenster schließen
    if OnionWindow then
        OnionWindow:Close()
    end
end

------------------------------------------------------------
-- ONION UI FENSTER
------------------------------------------------------------
local OnionWindow = Onion:CreateWindow({
    Title = "ENI SCRIPT",
    Subtitle = "made by Eni Service",
    Size = UDim2.new(0, 400, 0, 300),
    Position = UDim2.new(0.5, -200, 0.5, -150),
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightControl,
})

------------------------------------------------------------
-- TAB: MAIN
------------------------------------------------------------
local MainTab = OnionWindow:CreateTab("Main")

local MainSection = MainTab:CreateSection("Jumpscare")

------------------------------------------------------------
-- TRIGGER BUTTON (Get Key → Jumpscare)
------------------------------------------------------------
MainSection:CreateButton({
    Name = "Get Key",
    Description = "Achtung: Nicht klicken!",
    Callback = function()
        triggerJumpscare()
    end,
})

------------------------------------------------------------
-- KEY TEXTBOX
------------------------------------------------------------
MainSection:CreateTextBox({
    Name = "Key",
    Placeholder = "Enter Key",
    Callback = function(text)
        print("[ENI] Key eingegeben: " .. tostring(text))
    end,
})

------------------------------------------------------------
-- INFO / FOOTER
------------------------------------------------------------
local InfoSection = MainTab:CreateSection("Info")

InfoSection:CreateLabel({
    Text = "made by Eni Service",
    Color = Color3.fromRGB(150, 150, 150),
})

------------------------------------------------------------
-- FERTIG
------------------------------------------------------------
print("[ENI SCRIPT] Onion UI erfolgreich geladen!")
