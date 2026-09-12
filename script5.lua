-- JJJUI – Volume 100 Jumpscare UI
-- 10 Sounds × Volume 10 = effektiv Volume 100
-- Author-Tag: JJJUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------
-- IDs
------------------------------------------------------------
local IMAGE_ID = "rbxassetid://12412007525"
local SOUND_ID = "rbxassetid://140617516722342"
local FALLBACK_SOUND_ID = "rbxassetid://131961136"

------------------------------------------------------------
-- Alte Instanz entfernen
------------------------------------------------------------
local old = PlayerGui:FindFirstChild("JJJUI")
if old then old:Destroy() end

------------------------------------------------------------
-- ScreenGui
------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JJJUI"
ScreenGui.DisplayOrder = 2147483647
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = PlayerGui

local alive = true
ScreenGui.Destroying:Connect(function()
    alive = false
end)

------------------------------------------------------------
-- Farben
------------------------------------------------------------
local COL_PANEL     = Color3.fromRGB(22, 22, 32)
local COL_ACCENT    = Color3.fromRGB(0, 220, 255)
local COL_ACCENT2   = Color3.fromRGB(255, 0, 180)
local COL_TEXT      = Color3.fromRGB(235, 235, 245)
local COL_MUTED     = Color3.fromRGB(140, 140, 160)
local COL_WARN      = Color3.fromRGB(255, 20, 20)

------------------------------------------------------------
-- WARNUNG
------------------------------------------------------------
local WarningLabel = Instance.new("TextLabel")
WarningLabel.Name = "WarningLabel"
WarningLabel.Size = UDim2.new(1, 0, 0, 120)
WarningLabel.Position = UDim2.new(0, 0, 0.5, -60)
WarningLabel.BackgroundTransparency = 1
WarningLabel.Text = "DONT CHEAT IN GAMES DU NIGGER"
WarningLabel.TextColor3 = COL_WARN
WarningLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
WarningLabel.TextStrokeTransparency = 0
WarningLabel.Font = Enum.Font.Code
WarningLabel.TextScaled = true
WarningLabel.TextWrapped = true
WarningLabel.ZIndex = 2000
WarningLabel.Visible = false
WarningLabel.Parent = ScreenGui

task.spawn(function()
    while alive and WarningLabel.Parent do
        if WarningLabel.Visible then
            local t = 0
            while alive and WarningLabel.Visible and t < 1 do
                t = t + 0.02
                local a = 0.5 + 0.5 * math.abs(math.sin(t * math.pi))
                WarningLabel.TextTransparency = 1 - a
                task.wait(0.03)
            end
        else
            task.wait(0.1)
        end
    end
end)

------------------------------------------------------------
-- MAIN PANEL
------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 240)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -120)
MainFrame.BackgroundColor3 = COL_PANEL
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 5
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = COL_ACCENT
MainStroke.Transparency = 0.3
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 22)),
})
MainGradient.Rotation = 90
MainGradient.Parent = MainFrame

task.spawn(function()
    local t = 0
    while alive and MainStroke.Parent do
        t = t + 0.03
        MainStroke.Transparency = 0.3 + 0.25 * math.abs(math.sin(t))
        task.wait(0.05)
    end
end)

------------------------------------------------------------
-- HEADER
------------------------------------------------------------
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 46)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Header.BackgroundTransparency = 0.6
Header.BorderSizePixel = 0
Header.ZIndex = 6
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local HeaderMask = Instance.new("Frame")
HeaderMask.Size = UDim2.new(1, 0, 0, 14)
HeaderMask.Position = UDim2.new(0, 0, 1, -14)
HeaderMask.BackgroundColor3 = COL_PANEL
HeaderMask.BackgroundTransparency = 0.1
HeaderMask.BorderSizePixel = 0
HeaderMask.ZIndex = 6
HeaderMask.Parent = Header

local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(0, 4, 0, 26)
AccentBar.Position = UDim2.new(0, 14, 0.5, -13)
AccentBar.BackgroundColor3 = COL_ACCENT
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 8
AccentBar.Parent = Header

local AccentBarCorner = Instance.new("UICorner")
AccentBarCorner.CornerRadius = UDim.new(0, 4)
AccentBarCorner.Parent = AccentBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -60, 1, 0)
TitleText.Position = UDim2.new(0, 30, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "JJJUI"
TitleText.TextColor3 = COL_TEXT
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 22
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 8
TitleText.Parent = Header

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 10, 0, 10)
StatusDot.Position = UDim2.new(1, -24, 0.5, -5)
StatusDot.BackgroundColor3 = COL_ACCENT
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 8
StatusDot.Parent = Header

local StatusDotCorner = Instance.new("UICorner")
StatusDotCorner.CornerRadius = UDim.new(1, 0)
StatusDotCorner.Parent = StatusDot

task.spawn(function()
    local t = 0
    while alive and StatusDot.Parent do
        t = t + 0.08
        StatusDot.BackgroundColor3 = COL_ACCENT:Lerp(COL_ACCENT2, (math.sin(t) + 1) / 2)
        task.wait(0.05)
    end
end)

------------------------------------------------------------
-- BODY
------------------------------------------------------------
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, -40, 1, -100)
Body.Position = UDim2.new(0, 20, 0, 60)
Body.BackgroundTransparency = 1
Body.ZIndex = 6
Body.Parent = MainFrame

------------------------------------------------------------
-- OPEN SCRIPT BUTTON
------------------------------------------------------------
local TriggerButton = Instance.new("TextButton")
TriggerButton.Name = "TriggerButton"
TriggerButton.Size = UDim2.new(1, 0, 0, 64)
TriggerButton.Position = UDim2.new(0, 0, 0.5, -32)
TriggerButton.BackgroundColor3 = COL_ACCENT
TriggerButton.BorderSizePixel = 0
TriggerButton.Text = "EXECUTE"
TriggerButton.TextColor3 = Color3.fromRGB(10, 10, 15)
TriggerButton.Font = Enum.Font.GothamBold
TriggerButton.TextSize = 18
TriggerButton.AutoButtonColor = false
TriggerButton.ZIndex = 7
TriggerButton.Parent = Body

local TriggerCorner = Instance.new("UICorner")
TriggerCorner.CornerRadius = UDim.new(0, 10)
TriggerCorner.Parent = TriggerButton

local TriggerGradient = Instance.new("UIGradient")
TriggerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COL_ACCENT),
    ColorSequenceKeypoint.new(1, COL_ACCENT2),
})
TriggerGradient.Rotation = 45
TriggerGradient.Parent = TriggerButton

TriggerButton.MouseEnter:Connect(function()
    if not alive or not TriggerButton.Active then return end
    TweenService:Create(TriggerButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
end)
TriggerButton.MouseLeave:Connect(function()
    if not alive then return end
    TweenService:Create(TriggerButton, TweenInfo.new(0.15), {
        BackgroundColor3 = COL_ACCENT
    }):Play()
end)

------------------------------------------------------------
-- FOOTER
------------------------------------------------------------
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, -40, 0, 20)
Footer.Position = UDim2.new(0, 20, 1, -28)
Footer.BackgroundTransparency = 1
Footer.Text = "made by NSDAP Studios"
Footer.TextColor3 = COL_MUTED
Footer.Font = Enum.Font.Gotham
Footer.TextSize = 11
Footer.TextXAlignment = Enum.TextXAlignment.Right
Footer.ZIndex = 6
Footer.Parent = MainFrame

------------------------------------------------------------
-- JUMPSCARE OVERLAY
------------------------------------------------------------
local JumpscareImage = Instance.new("ImageLabel")
JumpscareImage.Name = "JumpscareImage"
JumpscareImage.Size = UDim2.new(1, 0, 1, 0)
JumpscareImage.Position = UDim2.new(0, 0, 0, 0)
JumpscareImage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
JumpscareImage.BackgroundTransparency = 1
JumpscareImage.BorderSizePixel = 0
JumpscareImage.Image = IMAGE_ID
JumpscareImage.ImageTransparency = 1
JumpscareImage.ScaleType = Enum.ScaleType.Stretch
JumpscareImage.Visible = false
JumpscareImage.ZIndex = 900
JumpscareImage.Parent = ScreenGui

------------------------------------------------------------
-- 🔊 VOLUME 100 SOUND STACK
-- 10 Sounds × Volume 10 = effektiv Volume 100
------------------------------------------------------------
local SOUND_COUNT = 10
local sounds = {}

for i = 1, SOUND_COUNT do
    local s = Instance.new("Sound")
    s.Name = "JJJUI_Sound_" .. i
    s.SoundId = SOUND_ID
    s.Volume = 10           -- Max pro Sound
    s.Looped = true
    s.PlayOnRemove = false
    s.Parent = ScreenGui
    table.insert(sounds, s)
end

-- Robuster Fallback
task.spawn(function()
    local ok = pcall(function()
        ContentProvider:PreloadAsync({ sounds[1] })
    end)
    if not ok or not sounds[1] or sounds[1].TimeLength <= 0 then
        warn("[JJJUI] Sound-ID ungültig – nutze Fallback")
        for _, s in ipairs(sounds) do
            s.SoundId = FALLBACK_SOUND_ID
        end
    end
end)

local function playAllSounds()
    for _, s in ipairs(sounds) do
        if s and s.Parent then
            s.Volume = 10
            s.Looped = true
            pcall(function() s:Play() end)
        end
    end
end

------------------------------------------------------------
-- TRIGGER (nicht stoppbar)
------------------------------------------------------------
local triggered = false

local function triggerJumpscare()
    if triggered then return end
    triggered = true

    TriggerButton.Active = false
    TriggerButton.Text = "..."
    TriggerButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

    JumpscareImage.Visible = true
    JumpscareImage.ImageTransparency = 1
    JumpscareImage.BackgroundTransparency = 0

    TweenService:Create(
        JumpscareImage,
        TweenInfo.new(0.05, Enum.EasingStyle.Linear),
        { ImageTransparency = 0 }
    ):Play()

    WarningLabel.Visible = true
    playAllSounds()

    MainFrame.Visible = false
end

TriggerButton.MouseButton1Click:Connect(triggerJumpscare)
