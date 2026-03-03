--[[ v1.5 ]]
if game == nil or type(game.GetService) ~= "function" then return end

-- ═══════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS_ = ReplicatedStorage
local R = {}
function R.F(name) return RS_ and RS_:FindFirstChild(name) or nil end
function R.W(name, t) return RS_ and RS_:WaitForChild(name, t or 10) or nil end
local function _(a, b) return a .. b end
local N1 = _("As", "sets")
local N2 = _("Hit", "box") .. "es"
local N3 = _("Pa", "rt")
local N4 = _("Hit", "box")
local N5 = _("CLI", "ENT_") .. "BALL"
local N6 = N5 .. "_"
local HITBOX_ENABLED = false
local HITBOX_SIZE = 0
local MIN_HITBOX_SIZE = 0
local MAX_HITBOX_SIZE = 50
local BALL_SEARCH_INTERVAL = 0.18
local DEBUG_ENABLED = false
local PULL_DISTANCE = 2
local BALL_LERP_SPEED = 0.25
local KEYBIND_TOGGLE_GUI = Enum.KeyCode.RightShift
local KEYBIND_TOGGLE_HITBOX = Enum.KeyCode.H
local GAME_HITBOX_DEFAULT_SIZE = 10
local BALL_PULL_FRAME_INTERVAL = 2
local HITBOX_REAPPLY_MIN_SEC = 25
local HITBOX_REAPPLY_MAX_SEC = 45
local ANTICHEAT_DISABLE_BALL_PULL = true
local ANTICHEAT_SAFE_NO_REPLICATED_WRITE = true
local ANTICHEAT_SAFE_NO_BINDACTIVATE_HOOK = true

-- ═══════════════════════════════════════════════
-- COLOR PALETTE
-- ═══════════════════════════════════════════════
local Colors = {
    Background = Color3.fromRGB(15, 15, 25),
    Panel = Color3.fromRGB(22, 22, 38),
    PanelLight = Color3.fromRGB(30, 30, 50),
    Accent = Color3.fromRGB(138, 43, 226),       -- Violet
    AccentGlow = Color3.fromRGB(170, 80, 255),    -- Light violet
    AccentDark = Color3.fromRGB(90, 20, 160),
    Red = Color3.fromRGB(220, 50, 50),
    Green = Color3.fromRGB(50, 205, 100),
    TextPrimary = Color3.fromRGB(240, 240, 255),
    TextSecondary = Color3.fromRGB(160, 160, 190),
    TextMuted = Color3.fromRGB(100, 100, 130),
    SliderBg = Color3.fromRGB(40, 40, 65),
    SliderFill = Color3.fromRGB(138, 43, 226),
    Border = Color3.fromRGB(50, 50, 80),
    Shadow = Color3.fromRGB(5, 5, 10),
}

-- Presets para "Cor da borda" (Accent, Glow, Dark)
local BordaPresets = {
    { name = "Violeta",   main = Color3.fromRGB(138, 43, 226),  glow = Color3.fromRGB(170, 80, 255),  dark = Color3.fromRGB(90, 20, 160) },
    { name = "Azul",      main = Color3.fromRGB(59, 130, 246),   glow = Color3.fromRGB(96, 165, 250),  dark = Color3.fromRGB(29, 78, 216) },
    { name = "Ciano",     main = Color3.fromRGB(34, 211, 238),  glow = Color3.fromRGB(103, 232, 249), dark = Color3.fromRGB(22, 163, 178) },
    { name = "Verde",     main = Color3.fromRGB(34, 197, 94),    glow = Color3.fromRGB(74, 222, 128),  dark = Color3.fromRGB(21, 128, 61) },
    { name = "Dourado",   main = Color3.fromRGB(234, 179, 8),    glow = Color3.fromRGB(253, 224, 71),  dark = Color3.fromRGB(161, 98, 7) },
    { name = "Laranja",   main = Color3.fromRGB(249, 115, 22),   glow = Color3.fromRGB(251, 146, 60),  dark = Color3.fromRGB(194, 65, 12) },
    { name = "Rosa",      main = Color3.fromRGB(236, 72, 153),   glow = Color3.fromRGB(244, 114, 182), dark = Color3.fromRGB(190, 24, 93) },
    { name = "Vermelho",  main = Color3.fromRGB(239, 68, 68),    glow = Color3.fromRGB(248, 113, 113), dark = Color3.fromRGB(185, 28, 28) },
}

-- ═══════════════════════════════════════════════
-- CAMADA INICIAL
-- ═══════════════════════════════════════════════
local function _RandomName(prefix, len)
    local s = prefix or ""
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    for _ = 1, len or 8 do
        local i = math.random(1, #chars)
        s = s .. chars:sub(i, i)
    end
    return s
end
local ANTIDETECT_START_DELAY_MIN = 0.5
local ANTIDETECT_START_DELAY_MAX = 1.5
local scriptStartTime
if ANTIDETECT_START_DELAY_MIN == 0 and ANTIDETECT_START_DELAY_MAX == 0 then
    scriptStartTime = 0
else
    scriptStartTime = tick() + (math.random() * (ANTIDETECT_START_DELAY_MAX - ANTIDETECT_START_DELAY_MIN) + ANTIDETECT_START_DELAY_MIN)
end
local GUI_PUBLIC_NAME = _RandomName("", 12)
local ESP_PUBLIC_NAME = _RandomName("", 10)

-- ═══════════════════════════════════════════════
for _, child in ipairs(CoreGui:GetChildren()) do
    if child:IsA("ScreenGui") and child:FindFirstChild("MainFrame") then
        child:Destroy()
        break
    end
end

-- ═══════════════════════════════════════════════
local Cleanup = {}
Cleanup._active = true
Cleanup._connections = {}
function Cleanup.Register(conn)
    if conn and type(conn.Disconnect) == "function" then
        table.insert(Cleanup._connections, conn)
    end
end

-- ═══════════════════════════════════════════════
-- CAMADAS DE SEGURANÇA (validação + execução segura, sem travar nem vazar erro)
-- ═══════════════════════════════════════════════
local Safe = {}
function Safe.Call(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and DEBUG_ENABLED then
        warn("[Script] ", tostring(err))
    end
    return ok
end
function Safe.IsValidPlayer()
    return type(Players) == "userdata" and LocalPlayer and LocalPlayer.Parent == Players
end
function Safe.IsValidGui()
    return ScreenGui and ScreenGui.Parent
end
function Safe.IsValidCharacter(char)
    return char and char:IsA("Model") and char.Parent and char:FindFirstChild("HumanoidRootPart")
end
function Safe.IsValidPart(obj)
    return obj and obj:IsA("BasePart") and obj.Parent
end

-- ═══════════════════════════════════════════════
-- HIT TIMING MONITOR (cliente; sem RemoteEvents/física)
-- ═══════════════════════════════════════════════
local HitTimes = {}
local MAX_HIT_TIMES = 500
local LowStdConsecutive = 0
local DelayNext = false

local function GaussDelay()
    local u1, u2 = math.random(), math.random()
    if u1 <= 0 then u1 = 0.0001 end
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return math.clamp(0.17 + 0.025 * z, 0.12, 0.22)
end

local function StdDev(arr)
    local n = #arr
    if n < 2 then return nil end
    local s = 0
    for i = 1, n do s = s + arr[i] end
    local m = s / n
    local v = 0
    for i = 1, n do v = v + (arr[i] - m)^2 end
    return math.sqrt(v / (n - 1))
end

local BindActivate = R.F("BindActivate")
if not BindActivate then
    local a1 = R.F(N1)
    if a1 then BindActivate = a1:FindFirstChild("BindActivate") end
end
if not ANTICHEAT_SAFE_NO_BINDACTIVATE_HOOK and BindActivate and BindActivate:IsA("BindableEvent") then
    local OldFire = BindActivate.Fire
    BindActivate.Fire = function(self, ...)
        table.insert(HitTimes, os.clock())
        if #HitTimes > MAX_HIT_TIMES then table.remove(HitTimes, 1) end
        if DelayNext then
            task.wait(GaussDelay())
            DelayNext = false
        end
        return OldFire(self, ...)
    end
end

task.spawn(function()
    while Cleanup._active do
        task.wait(60)
        if not Cleanup._active then break end
        local now = os.clock()
        local win = {}
        for _, t in ipairs(HitTimes) do
            if now - t <= 60 then table.insert(win, t) end
        end
        table.sort(win)
        local inter = {}
        for i = 2, #win do table.insert(inter, win[i] - win[i - 1]) end
        if #inter >= 2 then
            local sd = StdDev(inter)
            if sd and sd < 0.02 then
                LowStdConsecutive = LowStdConsecutive + 1
                if LowStdConsecutive >= 3 then
                    DelayNext = true
                    LowStdConsecutive = 0
                end
            else
                LowStdConsecutive = 0
            end
        end
    end
end)

-- ═══════════════════════════════════════════════
-- GUI CREATION
-- ═══════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_PUBLIC_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.IgnoreGuiInset = true

-- Try CoreGui first (executor), fallback to PlayerGui
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════
local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function CreateGradient(parent, c1, c2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(c1, c2)
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

local function Tween(obj, props, duration, style, direction)
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

-- ═══════════════════════════════════════════════
local MAIN_WINDOW_WIDTH = 380
local MAIN_WINDOW_HEIGHT = 730
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, MAIN_WINDOW_HEIGHT)
MainFrame.Position = UDim2.new(0.5, -MAIN_WINDOW_WIDTH/2, 0.5, -MAIN_WINDOW_HEIGHT/2)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
CreateCorner(MainFrame, 16)
CreateGradient(MainFrame, Color3.fromRGB(18, 18, 30), Color3.fromRGB(12, 12, 22), 135)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Colors.Accent
MainStroke.Thickness = 2
MainStroke.Transparency = 0.25
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame
local MainStrokeOuter = Instance.new("UIStroke")
MainStrokeOuter.Color = Colors.AccentGlow
MainStrokeOuter.Thickness = 1
MainStrokeOuter.Transparency = 0.5
MainStrokeOuter.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStrokeOuter.Parent = MainFrame

-- Borda interna sutil (efeito depth)
local InnerGlow = Instance.new("Frame")
InnerGlow.Size = UDim2.new(1, -10, 1, -10)
InnerGlow.Position = UDim2.new(0, 5, 0, 5)
InnerGlow.BackgroundTransparency = 1
InnerGlow.BorderSizePixel = 0
InnerGlow.Parent = MainFrame
CreateCorner(InnerGlow, 12)
local InnerStroke = Instance.new("UIStroke")
InnerStroke.Color = Color3.fromRGB(255, 255, 255)
InnerStroke.Thickness = 1
InnerStroke.Transparency = 0.92
InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
InnerStroke.Parent = InnerGlow

-- Linha decorativa inferior (accent)
local MainAccentBottom = Instance.new("Frame")
MainAccentBottom.Size = UDim2.new(1, 0, 0, 4)
MainAccentBottom.Position = UDim2.new(0, 0, 1, -4)
MainAccentBottom.BorderSizePixel = 0
MainAccentBottom.Parent = MainFrame
CreateCorner(MainAccentBottom, 1)
CreateGradient(MainAccentBottom, Colors.AccentDark, Colors.AccentGlow, 0)

local BallConeOutline = Instance.new("Frame")
BallConeOutline.Name = "BallConeOutline"
BallConeOutline.BackgroundTransparency = 1
BallConeOutline.Size = UDim2.new(0, 28, 0, 28)
BallConeOutline.Position = UDim2.new(0, 0, 0, 0)
BallConeOutline.AnchorPoint = Vector2.new(0.5, 0.5)
BallConeOutline.Visible = false
BallConeOutline.Parent = ScreenGui
local BallConeStroke = Instance.new("UIStroke")
BallConeStroke.Thickness = 2
BallConeStroke.Color = Color3.new(1, 0.9, 0.2)
BallConeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
BallConeStroke.Parent = BallConeOutline
local AimReckMarker = Instance.new("Frame")
AimReckMarker.Name = "AimReckMarker"
AimReckMarker.Size = UDim2.new(0, 52, 0, 52)
AimReckMarker.Position = UDim2.new(0, 0, 0, 0)
AimReckMarker.AnchorPoint = Vector2.new(0.5, 0.5)
AimReckMarker.BackgroundColor3 = Color3.fromRGB(50, 205, 100)
AimReckMarker.BackgroundTransparency = 0.25
AimReckMarker.BorderSizePixel = 0
AimReckMarker.Visible = false
AimReckMarker.ZIndex = 50
AimReckMarker.Parent = ScreenGui
CreateCorner(AimReckMarker, 26)
local AimReckStroke = Instance.new("UIStroke")
AimReckStroke.Thickness = 3
AimReckStroke.Color = Color3.fromRGB(255, 255, 255)
AimReckStroke.Transparency = 0.1
AimReckStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
AimReckStroke.Parent = AimReckMarker
local AimReckLabel = Instance.new("TextLabel")
AimReckLabel.Name = "Label"
AimReckLabel.Size = UDim2.new(1, 0, 1, 0)
AimReckLabel.BackgroundTransparency = 1
AimReckLabel.Text = "▼"
AimReckLabel.TextColor3 = Color3.new(1, 1, 1)
AimReckLabel.TextScaled = true
AimReckLabel.Font = Enum.Font.GothamBold
AimReckLabel.Parent = AimReckMarker
local CONE_HALF_DEG = 10
local CONE_LIM_RAD = math.rad(CONE_HALF_DEG)

local BallInCone = false
local B = {}
local lastT = 0
local comp = false
local lsc = 0
local BufferOn = true
local ultHitTick = 0
local hitCounterLocal = 0

local function rndName()
    local n = ""
    for _ = 1, 6 do n = n .. string.char(65 + math.random(0, 25)) end
    return n
end

local DbgSv = nil
if not ANTICHEAT_SAFE_NO_REPLICATED_WRITE then DbgSv = R.F("Dbg") end

local function gx()
    local u1, u2 = math.random(), math.random()
    if u1 <= 0 then u1 = 0.0001 end
    return (15/100) + (4/100) * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
end

local function sd(tb)
    local k = #tb
    if k < 2 then return nil end
    local s = 0
    for i = 1, k do s = s + tb[i] end
    local m = s / k
    s = 0
    for i = 1, k do s = s + (tb[i] - m)^2 end
    return math.sqrt(s / (k - 1))
end

task.spawn(function()
    while Cleanup._active do
        task.wait(5 * 60)
        if not Cleanup._active then break end
        B = {}
    end
end)

local fh = 0
task.spawn(function()
    while Cleanup._active do
        task.wait(30)
        if not Cleanup._active then break end
        fh = (fh * 1103515245 + 12345) % 0x100000000
    end
end)

Cleanup.Register(UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    -- Buffer desativado: não grava cliques (reduz risco de detecção).
    if not BufferOn or not BallInCone then return end
    local now = os.clock()
    if lastT > 0 then
        lastT = now
    else
        lastT = now
    end
    ultHitTick = tick()
end))

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 62)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Colors.Panel
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
CreateCorner(TitleBar, 14)
CreateGradient(TitleBar, Colors.Panel, Colors.PanelLight, 0)

-- Fix corner clipping on bottom of title bar
local TitleBarFix = Instance.new("Frame")
TitleBarFix.Size = UDim2.new(1, 0, 0, 18)
TitleBarFix.Position = UDim2.new(0, 0, 1, -18)
TitleBarFix.BackgroundColor3 = Colors.PanelLight
TitleBarFix.BorderSizePixel = 0
TitleBarFix.Parent = TitleBar

-- Accent line under title
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 4)
AccentLine.Position = UDim2.new(0, 0, 1, -4)
AccentLine.BorderSizePixel = 0
AccentLine.Parent = TitleBar
CreateCorner(AccentLine, 1)
CreateGradient(AccentLine, Colors.AccentDark, Colors.AccentGlow, 0)

-- Decorative corner accent
local TitleAccentCorner = Instance.new("Frame")
TitleAccentCorner.Size = UDim2.new(0, 5, 0, 28)
TitleAccentCorner.Position = UDim2.new(0, 0, 0, 17)
TitleAccentCorner.BackgroundColor3 = Colors.Accent
TitleAccentCorner.BorderSizePixel = 0
TitleAccentCorner.Parent = TitleBar
CreateCorner(TitleAccentCorner, 2)

-- Title icon
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 36, 0, 36)
TitleIcon.Position = UDim2.new(0, 16, 0, 8)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🏐"
TitleIcon.TextSize = 24
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextColor3 = Colors.TextPrimary
TitleIcon.Parent = TitleBar

-- Title text (fonte mais bonita)
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -110, 0, 24)
TitleText.Position = UDim2.new(0, 56, 0, 8)
TitleText.BackgroundTransparency = 1
TitleText.Text = "VOLLEYBALL LEGENDS"
TitleText.TextSize = 17
TitleText.Font = Enum.Font.GothamBlack
TitleText.TextColor3 = Colors.TextPrimary
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Creator (Henrydangerkk)
local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -110, 0, 20)
SubTitle.Position = UDim2.new(0, 56, 0, 32)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Criador: Henrydangerkk"
SubTitle.TextSize = 13
SubTitle.Font = Enum.Font.GothamBold
SubTitle.TextColor3 = Colors.AccentGlow
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = TitleBar

-- Close / Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 34, 0, 34)
MinimizeBtn.Position = UDim2.new(1, -44, 0.5, -17)
MinimizeBtn.ZIndex = 2
MinimizeBtn.BackgroundColor3 = Colors.PanelLight
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "—"
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Colors.TextSecondary
MinimizeBtn.Parent = TitleBar
CreateCorner(MinimizeBtn, 8)

MinimizeBtn.MouseEnter:Connect(function()
    Tween(MinimizeBtn, {BackgroundColor3 = Colors.Accent}, 0.2)
    Tween(MinimizeBtn, {TextColor3 = Colors.TextPrimary}, 0.2)
end)
MinimizeBtn.MouseLeave:Connect(function()
    Tween(MinimizeBtn, {BackgroundColor3 = Colors.PanelLight}, 0.2)
    Tween(MinimizeBtn, {TextColor3 = Colors.TextSecondary}, 0.2)
end)

-- ═══════════════════════════════════════════════
-- DRAGGABLE LOGIC
-- ═══════════════════════════════════════════════
local dragging = false
local dragStart = nil
local startPos = nil

Cleanup.Register(TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end))
Cleanup.Register(TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))
Cleanup.Register(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end))

-- ═══════════════════════════════════════════════
-- CONTENT AREA (com rolagem para tudo caber)
-- ═══════════════════════════════════════════════
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Name = "Scroll"
ScrollingFrame.Size = UDim2.new(1, -32, 1, -88)
ScrollingFrame.Position = UDim2.new(0, 16, 0, 72)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollBarImageColor3 = Colors.Accent
ScrollingFrame.ScrollBarImageTransparency = 0.5
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.ClipsDescendants = true
ScrollingFrame.Parent = MainFrame
CreateCorner(ScrollingFrame, 8)

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, -6, 0, 0)
ContentFrame.Position = UDim2.new(0, 0, 0, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.AutomaticSize = Enum.AutomaticSize.Y
ContentFrame.Parent = ScrollingFrame

-- ═══════════════════════════════════════════════
local SectionHeader = Instance.new("Frame")
SectionHeader.Size = UDim2.new(1, 0, 0, 38)
SectionHeader.Position = UDim2.new(0, 0, 0, 0)
SectionHeader.BackgroundColor3 = Colors.Panel
SectionHeader.BorderSizePixel = 0
SectionHeader.Parent = ContentFrame
CreateCorner(SectionHeader, 10)
CreateStroke(SectionHeader, Color3.fromRGB(60, 50, 90), 1)
local SectionLeftBar = Instance.new("Frame")
SectionLeftBar.Size = UDim2.new(0, 4, 0, 22)
SectionLeftBar.Position = UDim2.new(0, 8, 0.5, -11)
SectionLeftBar.BackgroundColor3 = Colors.Accent
SectionLeftBar.BorderSizePixel = 0
SectionLeftBar.Parent = SectionHeader
CreateCorner(SectionLeftBar, 1)

local SectionIcon = Instance.new("TextLabel")
SectionIcon.Size = UDim2.new(0, 28, 1, 0)
SectionIcon.Position = UDim2.new(0, 18, 0, 0)
SectionIcon.BackgroundTransparency = 1
SectionIcon.Text = "🎯"
SectionIcon.TextSize = 15
SectionIcon.Font = Enum.Font.GothamBold
SectionIcon.TextColor3 = Colors.TextPrimary
SectionIcon.Parent = SectionHeader

local SectionTitle = Instance.new("TextLabel")
SectionTitle.Size = UDim2.new(1, -55, 1, 0)
SectionTitle.Position = UDim2.new(0, 50, 0, 0)
SectionTitle.BackgroundTransparency = 1
SectionTitle.Text = "HITBOX MODULE"
SectionTitle.TextSize = 13
SectionTitle.Font = Enum.Font.GothamBlack
SectionTitle.TextColor3 = Colors.TextPrimary
SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
SectionTitle.Parent = SectionHeader

-- ═══════════════════════════════════════════════
-- TOGGLE BUTTON
-- ═══════════════════════════════════════════════
local ToggleContainer = Instance.new("Frame")
ToggleContainer.Size = UDim2.new(1, 0, 0, 48)
ToggleContainer.Position = UDim2.new(0, 0, 0, 48)
ToggleContainer.BackgroundColor3 = Colors.Panel
ToggleContainer.BorderSizePixel = 0
ToggleContainer.Parent = ContentFrame
CreateCorner(ToggleContainer, 10)
CreateStroke(ToggleContainer, Color3.fromRGB(45, 45, 70), 1)

local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
ToggleLabel.Position = UDim2.new(0, 16, 0, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "Hitbox Expander"
ToggleLabel.TextSize = 14
ToggleLabel.Font = Enum.Font.SourceSansSemibold
ToggleLabel.TextColor3 = Colors.TextSecondary
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.Parent = ToggleContainer

local ToggleRowButton = Instance.new("TextButton")
ToggleRowButton.Size = UDim2.new(0.6, -16, 1, 0)
ToggleRowButton.Position = UDim2.new(0, 0, 0, 0)
ToggleRowButton.BackgroundTransparency = 1
ToggleRowButton.Text = ""
ToggleRowButton.ZIndex = 2
ToggleRowButton.Parent = ToggleContainer

-- Toggle switch
local ToggleOuter = Instance.new("Frame")
ToggleOuter.Size = UDim2.new(0, 50, 0, 26)
ToggleOuter.Position = UDim2.new(1, -64, 0.5, -13)
ToggleOuter.BackgroundColor3 = Colors.SliderBg
ToggleOuter.BorderSizePixel = 0
ToggleOuter.Parent = ToggleContainer
CreateCorner(ToggleOuter, 13)

local ToggleKnob = Instance.new("Frame")
ToggleKnob.Size = UDim2.new(0, 20, 0, 20)
ToggleKnob.Position = UDim2.new(0, 3, 0.5, -10)
ToggleKnob.BackgroundColor3 = Colors.TextMuted
ToggleKnob.BorderSizePixel = 0
ToggleKnob.Parent = ToggleOuter
CreateCorner(ToggleKnob, 10)

-- Status indicator
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -14, 0, 12)
StatusLabel.Position = UDim2.new(0, 14, 1, -16)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "OFF"
StatusLabel.TextSize = 9
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextColor3 = Colors.Red
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = ToggleContainer

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, 0, 1, 0)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Text = ""
ToggleButton.ZIndex = 2
ToggleButton.Active = true
ToggleButton.Parent = ToggleOuter

-- ═══════════════════════════════════════════════
-- SLIDER
-- ═══════════════════════════════════════════════
local SliderContainer = Instance.new("Frame")
SliderContainer.Size = UDim2.new(1, 0, 0, 74)
SliderContainer.Position = UDim2.new(0, 0, 0, 106)
SliderContainer.BackgroundColor3 = Colors.Panel
SliderContainer.BorderSizePixel = 0
SliderContainer.Parent = ContentFrame
CreateCorner(SliderContainer, 10)
CreateStroke(SliderContainer, Color3.fromRGB(45, 45, 70), 1)

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(0.6, 0, 0, 26)
SliderLabel.Position = UDim2.new(0, 16, 0, 10)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "Hitbox Size"
SliderLabel.TextSize = 14
SliderLabel.Font = Enum.Font.SourceSansSemibold
SliderLabel.TextColor3 = Colors.TextSecondary
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Parent = SliderContainer

-- Value display
local SliderValue = Instance.new("TextLabel")
SliderValue.Size = UDim2.new(0.3, 0, 0, 26)
SliderValue.Position = UDim2.new(0.7, -16, 0, 10)
SliderValue.BackgroundTransparency = 1
SliderValue.Text = tostring(MIN_HITBOX_SIZE)
SliderValue.TextSize = 17
SliderValue.Font = Enum.Font.GothamBlack
SliderValue.TextColor3 = Colors.AccentGlow
SliderValue.TextXAlignment = Enum.TextXAlignment.Right
SliderValue.Parent = SliderContainer

-- Slider track
local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -32, 0, 10)
SliderTrack.Position = UDim2.new(0, 16, 0, 44)
SliderTrack.BackgroundColor3 = Colors.SliderBg
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderContainer
CreateCorner(SliderTrack, 4)

-- Slider fill
local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0, 0, 1, 0)
SliderFill.Position = UDim2.new(0, 0, 0, 0)
SliderFill.BackgroundColor3 = Colors.SliderFill
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack
CreateCorner(SliderFill, 4)
CreateGradient(SliderFill, Colors.AccentDark, Colors.AccentGlow, 0)

-- Slider knob
local SliderKnob = Instance.new("Frame")
SliderKnob.Size = UDim2.new(0, 18, 0, 18)
SliderKnob.Position = UDim2.new(0, -9, 0.5, -9)
SliderKnob.BackgroundColor3 = Colors.TextPrimary
SliderKnob.BorderSizePixel = 0
SliderKnob.ZIndex = 3
SliderKnob.Parent = SliderFill
CreateCorner(SliderKnob, 9)
CreateStroke(SliderKnob, Colors.Accent, 2)

-- Knob glow effect
local KnobGlow = Instance.new("Frame")
KnobGlow.Size = UDim2.new(0, 26, 0, 26)
KnobGlow.Position = UDim2.new(0.5, -13, 0.5, -13)
KnobGlow.BackgroundColor3 = Colors.Accent
KnobGlow.BackgroundTransparency = 0.7
KnobGlow.BorderSizePixel = 0
KnobGlow.ZIndex = 2
KnobGlow.Parent = SliderKnob
CreateCorner(KnobGlow, 13)

-- Min/Max labels
local MinLabel = Instance.new("TextLabel")
MinLabel.Size = UDim2.new(0, 24, 0, 16)
MinLabel.Position = UDim2.new(0, 16, 0, 56)
MinLabel.BackgroundTransparency = 1
MinLabel.Text = tostring(MIN_HITBOX_SIZE)
MinLabel.TextSize = 10
MinLabel.Font = Enum.Font.Gotham
MinLabel.TextColor3 = Colors.TextMuted
MinLabel.TextXAlignment = Enum.TextXAlignment.Left
MinLabel.Parent = SliderContainer

local MaxLabel = Instance.new("TextLabel")
MaxLabel.Size = UDim2.new(0, 24, 0, 16)
MaxLabel.Position = UDim2.new(1, -40, 0, 56)
MaxLabel.BackgroundTransparency = 1
MaxLabel.Text = tostring(MAX_HITBOX_SIZE)
MaxLabel.TextSize = 10
MaxLabel.Font = Enum.Font.Gotham
MaxLabel.TextColor3 = Colors.TextMuted
MaxLabel.TextXAlignment = Enum.TextXAlignment.Right
MaxLabel.Parent = SliderContainer

-- Slider interaction area
local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(1, 20, 0, 30)
SliderButton.Position = UDim2.new(0, -10, 0, -11)
SliderButton.BackgroundTransparency = 1
SliderButton.Text = ""
SliderButton.ZIndex = 4
SliderButton.Parent = SliderTrack

-- ═══════════════════════════════════════════════
local ReckSectionHeader = Instance.new("Frame")
ReckSectionHeader.Size = UDim2.new(1, 0, 0, 38)
ReckSectionHeader.Position = UDim2.new(0, 0, 0, 188)
ReckSectionHeader.BackgroundColor3 = Colors.Panel
ReckSectionHeader.BorderSizePixel = 0
ReckSectionHeader.Parent = ContentFrame
CreateCorner(ReckSectionHeader, 10)
CreateStroke(ReckSectionHeader, Color3.fromRGB(50, 60, 90), 1)
local ReckSectionLeftBar = Instance.new("Frame")
ReckSectionLeftBar.Size = UDim2.new(0, 4, 0, 22)
ReckSectionLeftBar.Position = UDim2.new(0, 8, 0.5, -11)
ReckSectionLeftBar.BackgroundColor3 = Colors.Green
ReckSectionLeftBar.BorderSizePixel = 0
ReckSectionLeftBar.Parent = ReckSectionHeader
CreateCorner(ReckSectionLeftBar, 1)

local ReckSectionIcon = Instance.new("TextLabel")
ReckSectionIcon.Size = UDim2.new(0, 28, 1, 0)
ReckSectionIcon.Position = UDim2.new(0, 18, 0, 0)
ReckSectionIcon.BackgroundTransparency = 1
ReckSectionIcon.Text = "📍"
ReckSectionIcon.TextSize = 15
ReckSectionIcon.Font = Enum.Font.GothamBold
ReckSectionIcon.TextColor3 = Colors.TextPrimary
ReckSectionIcon.Parent = ReckSectionHeader

local ReckSectionTitle = Instance.new("TextLabel")
ReckSectionTitle.Size = UDim2.new(1, -55, 1, 0)
ReckSectionTitle.Position = UDim2.new(0, 50, 0, 0)
ReckSectionTitle.BackgroundTransparency = 1
ReckSectionTitle.Text = "AIM RECK"
ReckSectionTitle.TextSize = 13
ReckSectionTitle.Font = Enum.Font.GothamBlack
ReckSectionTitle.TextColor3 = Colors.TextPrimary
ReckSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
ReckSectionTitle.Parent = ReckSectionHeader

local ReckToggleContainer = Instance.new("Frame")
ReckToggleContainer.Size = UDim2.new(1, 0, 0, 48)
ReckToggleContainer.Position = UDim2.new(0, 0, 0, 234)
ReckToggleContainer.BackgroundColor3 = Colors.Panel
ReckToggleContainer.BorderSizePixel = 0
ReckToggleContainer.Parent = ContentFrame
CreateCorner(ReckToggleContainer, 10)
CreateStroke(ReckToggleContainer, Color3.fromRGB(45, 45, 70), 1)

local ReckToggleLabel = Instance.new("TextLabel")
ReckToggleLabel.Size = UDim2.new(0.75, 0, 1, 0)
ReckToggleLabel.Position = UDim2.new(0, 16, 0, 0)
ReckToggleLabel.BackgroundTransparency = 1
ReckToggleLabel.Text = "Mostra onde a bola vai cair (recepção / ajudar amigos)"
ReckToggleLabel.TextSize = 12
ReckToggleLabel.Font = Enum.Font.SourceSansSemibold
ReckToggleLabel.TextColor3 = Colors.TextSecondary
ReckToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ReckToggleLabel.TextWrapped = true
ReckToggleLabel.Parent = ReckToggleContainer

local ReckToggleOuter = Instance.new("Frame")
ReckToggleOuter.Size = UDim2.new(0, 50, 0, 26)
ReckToggleOuter.Position = UDim2.new(1, -64, 0.5, -13)
ReckToggleOuter.BackgroundColor3 = Colors.SliderBg
ReckToggleOuter.BorderSizePixel = 0
ReckToggleOuter.Parent = ReckToggleContainer
CreateCorner(ReckToggleOuter, 13)

local ReckToggleKnob = Instance.new("Frame")
ReckToggleKnob.Size = UDim2.new(0, 20, 0, 20)
ReckToggleKnob.Position = UDim2.new(0, 3, 0.5, -10)
ReckToggleKnob.BackgroundColor3 = Colors.TextMuted
ReckToggleKnob.BorderSizePixel = 0
ReckToggleKnob.Parent = ReckToggleOuter
CreateCorner(ReckToggleKnob, 10)

local ReckToggleButton = Instance.new("TextButton")
ReckToggleButton.Size = UDim2.new(1, 0, 1, 0)
ReckToggleButton.BackgroundTransparency = 1
ReckToggleButton.Text = ""
ReckToggleButton.Parent = ReckToggleOuter

local AIM_RECK_ENABLED = false

ReckToggleButton.MouseButton1Click:Connect(function()
    AIM_RECK_ENABLED = not AIM_RECK_ENABLED
    if AIM_RECK_ENABLED then
        Tween(ReckToggleKnob, {Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = Colors.TextPrimary}, 0.25)
        Tween(ReckToggleOuter, {BackgroundColor3 = Colors.Green}, 0.25)
    else
        Tween(ReckToggleKnob, {Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = Colors.TextMuted}, 0.25)
        Tween(ReckToggleOuter, {BackgroundColor3 = Colors.SliderBg}, 0.25)
    end
    if AimReckMarker then AimReckMarker.Visible = false end
end)

ReckToggleOuter.MouseEnter:Connect(function()
    if not AIM_RECK_ENABLED then Tween(ReckToggleOuter, {BackgroundColor3 = Colors.PanelLight}, 0.2) end
end)
ReckToggleOuter.MouseLeave:Connect(function()
    if not AIM_RECK_ENABLED then Tween(ReckToggleOuter, {BackgroundColor3 = Colors.SliderBg}, 0.2) end
end)

-- ═══════════════════════════════════════════════
local EspSectionHeader = Instance.new("Frame")
EspSectionHeader.Size = UDim2.new(1, 0, 0, 38)
EspSectionHeader.Position = UDim2.new(0, 0, 0, 290)
EspSectionHeader.BackgroundColor3 = Colors.Panel
EspSectionHeader.BorderSizePixel = 0
EspSectionHeader.Parent = ContentFrame
CreateCorner(EspSectionHeader, 10)
CreateStroke(EspSectionHeader, Color3.fromRGB(70, 45, 45), 1)
local EspSectionLeftBar = Instance.new("Frame")
EspSectionLeftBar.Size = UDim2.new(0, 4, 0, 22)
EspSectionLeftBar.Position = UDim2.new(0, 8, 0.5, -11)
EspSectionLeftBar.BackgroundColor3 = Colors.Red
EspSectionLeftBar.BorderSizePixel = 0
EspSectionLeftBar.Parent = EspSectionHeader
CreateCorner(EspSectionLeftBar, 1)

local EspSectionIcon = Instance.new("TextLabel")
EspSectionIcon.Size = UDim2.new(0, 28, 1, 0)
EspSectionIcon.Position = UDim2.new(0, 18, 0, 0)
EspSectionIcon.BackgroundTransparency = 1
EspSectionIcon.Text = "👁"
EspSectionIcon.TextSize = 15
EspSectionIcon.Font = Enum.Font.GothamBold
EspSectionIcon.TextColor3 = Colors.TextPrimary
EspSectionIcon.Parent = EspSectionHeader

local EspSectionTitle = Instance.new("TextLabel")
EspSectionTitle.Size = UDim2.new(1, -55, 1, 0)
EspSectionTitle.Position = UDim2.new(0, 50, 0, 0)
EspSectionTitle.BackgroundTransparency = 1
EspSectionTitle.Text = "PLAYER ESP"
EspSectionTitle.TextSize = 13
EspSectionTitle.Font = Enum.Font.GothamBlack
EspSectionTitle.TextColor3 = Colors.TextPrimary
EspSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
EspSectionTitle.Parent = EspSectionHeader

local EspToggleContainer = Instance.new("Frame")
EspToggleContainer.Size = UDim2.new(1, 0, 0, 48)
EspToggleContainer.Position = UDim2.new(0, 0, 0, 336)
EspToggleContainer.BackgroundColor3 = Colors.Panel
EspToggleContainer.BorderSizePixel = 0
EspToggleContainer.Parent = ContentFrame
CreateCorner(EspToggleContainer, 10)
CreateStroke(EspToggleContainer, Color3.fromRGB(45, 45, 70), 1)

local EspToggleLabel = Instance.new("TextLabel")
EspToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
EspToggleLabel.Position = UDim2.new(0, 16, 0, 0)
EspToggleLabel.BackgroundTransparency = 1
EspToggleLabel.Text = "Ver jogadores através de paredes"
EspToggleLabel.TextSize = 13
EspToggleLabel.Font = Enum.Font.SourceSansSemibold
EspToggleLabel.TextColor3 = Colors.TextSecondary
EspToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
EspToggleLabel.Parent = EspToggleContainer

local EspToggleOuter = Instance.new("Frame")
EspToggleOuter.Size = UDim2.new(0, 50, 0, 26)
EspToggleOuter.Position = UDim2.new(1, -64, 0.5, -13)
EspToggleOuter.BackgroundColor3 = Colors.SliderBg
EspToggleOuter.BorderSizePixel = 0
EspToggleOuter.Parent = EspToggleContainer
CreateCorner(EspToggleOuter, 13)

local EspToggleKnob = Instance.new("Frame")
EspToggleKnob.Size = UDim2.new(0, 20, 0, 20)
EspToggleKnob.Position = UDim2.new(0, 3, 0.5, -10)
EspToggleKnob.BackgroundColor3 = Colors.TextMuted
EspToggleKnob.BorderSizePixel = 0
EspToggleKnob.Parent = EspToggleOuter
CreateCorner(EspToggleKnob, 10)

local EspToggleButton = Instance.new("TextButton")
EspToggleButton.Size = UDim2.new(1, 0, 1, 0)
EspToggleButton.BackgroundTransparency = 1
EspToggleButton.Text = ""
EspToggleButton.Parent = EspToggleOuter

local ESP_ENABLED = false
local ESP_HIGHLIGHT_NAME = ESP_PUBLIC_NAME
-- Vermelho mais forte na listra (contorno do wallhack)
local ESP_OUTLINE_COLOR = Color3.fromRGB(255, 75, 75)

local function RemoveEspFromCharacter(char)
    if not Safe.IsValidCharacter(char) then return end
    Safe.Call(function()
        local h = char:FindFirstChild(ESP_HIGHLIGHT_NAME)
        if h then h:Destroy() end
    end)
end

local function AddEspToCharacter(char)
    if not Safe.IsValidCharacter(char) or char == LocalPlayer.Character then return end
    RemoveEspFromCharacter(char)
    Safe.Call(function()
        local h = Instance.new("Highlight")
        h.Name = ESP_HIGHLIGHT_NAME
        h.OutlineColor = ESP_OUTLINE_COLOR
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Adornee = char
        h.Parent = char
    end)
end

local function UpdateEspForAll()
    if not Safe.IsValidPlayer() then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if ESP_ENABLED then AddEspToCharacter(plr.Character) else RemoveEspFromCharacter(plr.Character) end
        end
    end
end

EspToggleButton.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    if ESP_ENABLED then
        Tween(EspToggleKnob, {Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = Colors.TextPrimary}, 0.25)
        Tween(EspToggleOuter, {BackgroundColor3 = Colors.Accent}, 0.25)
    else
        Tween(EspToggleKnob, {Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = Colors.TextMuted}, 0.25)
        Tween(EspToggleOuter, {BackgroundColor3 = Colors.SliderBg}, 0.25)
    end
    UpdateEspForAll()
end)

EspToggleOuter.MouseEnter:Connect(function()
    if not ESP_ENABLED then Tween(EspToggleOuter, {BackgroundColor3 = Colors.PanelLight}, 0.2) end
end)
EspToggleOuter.MouseLeave:Connect(function()
    if not ESP_ENABLED then Tween(EspToggleOuter, {BackgroundColor3 = Colors.SliderBg}, 0.2) end
end)

-- ═══════════════════════════════════════════════
-- COR BORDA (escolher cor da decoração da interface)
-- ═══════════════════════════════════════════════
local BordaSectionHeader = Instance.new("Frame")
BordaSectionHeader.Size = UDim2.new(1, 0, 0, 38)
BordaSectionHeader.Position = UDim2.new(0, 0, 0, 384)
BordaSectionHeader.BackgroundColor3 = Colors.Panel
BordaSectionHeader.BorderSizePixel = 0
BordaSectionHeader.Parent = ContentFrame
CreateCorner(BordaSectionHeader, 10)
CreateStroke(BordaSectionHeader, Color3.fromRGB(60, 55, 85), 1)
local BordaSectionLeftBar = Instance.new("Frame")
BordaSectionLeftBar.Size = UDim2.new(0, 4, 0, 22)
BordaSectionLeftBar.Position = UDim2.new(0, 8, 0.5, -11)
BordaSectionLeftBar.BackgroundColor3 = Colors.Accent
BordaSectionLeftBar.BorderSizePixel = 0
BordaSectionLeftBar.Parent = BordaSectionHeader
CreateCorner(BordaSectionLeftBar, 1)

local BordaSectionIcon = Instance.new("TextLabel")
BordaSectionIcon.Size = UDim2.new(0, 28, 1, 0)
BordaSectionIcon.Position = UDim2.new(0, 18, 0, 0)
BordaSectionIcon.BackgroundTransparency = 1
BordaSectionIcon.Text = "🎨"
BordaSectionIcon.TextSize = 15
BordaSectionIcon.Font = Enum.Font.GothamBold
BordaSectionIcon.TextColor3 = Colors.TextPrimary
BordaSectionIcon.Parent = BordaSectionHeader

local BordaSectionTitle = Instance.new("TextLabel")
BordaSectionTitle.Size = UDim2.new(1, -55, 1, 0)
BordaSectionTitle.Position = UDim2.new(0, 50, 0, 0)
BordaSectionTitle.BackgroundTransparency = 1
BordaSectionTitle.Text = "COR BORDA"
BordaSectionTitle.TextSize = 13
BordaSectionTitle.Font = Enum.Font.GothamBlack
BordaSectionTitle.TextColor3 = Colors.TextPrimary
BordaSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
BordaSectionTitle.Parent = BordaSectionHeader

local BordaColorRow = Instance.new("Frame")
BordaColorRow.Size = UDim2.new(1, -24, 0, 36)
BordaColorRow.Position = UDim2.new(0, 12, 0, 430)
BordaColorRow.BackgroundColor3 = Colors.Panel
BordaColorRow.BorderSizePixel = 0
BordaColorRow.ClipsDescendants = true
BordaColorRow.Parent = ContentFrame
CreateCorner(BordaColorRow, 8)
CreateStroke(BordaColorRow, Color3.fromRGB(45, 45, 70), 1)

local BordaLabel = Instance.new("TextLabel")
BordaLabel.Size = UDim2.new(0, 72, 1, 0)
BordaLabel.Position = UDim2.new(0, 8, 0, 0)
BordaLabel.BackgroundTransparency = 1
BordaLabel.Text = "Cor da borda"
BordaLabel.TextSize = 11
BordaLabel.Font = Enum.Font.SourceSansSemibold
BordaLabel.TextColor3 = Colors.TextSecondary
BordaLabel.TextXAlignment = Enum.TextXAlignment.Left
BordaLabel.Parent = BordaColorRow

local BordaButtonsContainer = Instance.new("Frame")
BordaButtonsContainer.Size = UDim2.new(1, -84, 1, -12)
BordaButtonsContainer.Position = UDim2.new(0, 84, 0, 6)
BordaButtonsContainer.BackgroundTransparency = 1
BordaButtonsContainer.ClipsDescendants = true
BordaButtonsContainer.LayoutOrder = 1
BordaButtonsContainer.Parent = BordaColorRow

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = BordaButtonsContainer

local currentBordaIndex = 1

local function ApplyBordaColor(accent, glow, dark)
    Colors.Accent = accent
    Colors.AccentGlow = glow
    Colors.AccentDark = dark
    Colors.SliderFill = accent
    MainStroke.Color = accent
    MainStrokeOuter.Color = glow
    TitleAccentCorner.BackgroundColor3 = accent
    SubTitle.TextColor3 = glow
    SectionLeftBar.BackgroundColor3 = accent
    SliderValue.TextColor3 = glow
    SliderFill.BackgroundColor3 = accent
    BordaSectionLeftBar.BackgroundColor3 = accent
    ReckSectionLeftBar.BackgroundColor3 = accent
    EspSectionLeftBar.BackgroundColor3 = accent
    ToggleGuiBtn.BackgroundColor3 = accent
    local gradMain = MainAccentBottom:FindFirstChildOfClass("UIGradient")
    if gradMain then gradMain.Color = ColorSequence.new(dark, glow) end
    local gradAccent = AccentLine:FindFirstChildOfClass("UIGradient")
    if gradAccent then gradAccent.Color = ColorSequence.new(dark, glow) end
    local gradSlider = SliderFill:FindFirstChildOfClass("UIGradient")
    if gradSlider then gradSlider.Color = ColorSequence.new(dark, glow) end
    local strokeKnob = SliderKnob:FindFirstChildOfClass("UIStroke")
    if strokeKnob then strokeKnob.Color = accent end
    local glowKnob = SliderKnob:FindFirstChildOfClass("Frame")
    if glowKnob then glowKnob.BackgroundColor3 = accent end
    local strokeGui = ToggleGuiBtn:FindFirstChildOfClass("UIStroke")
    if strokeGui then strokeGui.Color = glow end
    if HITBOX_ENABLED then Tween(ToggleOuter, {BackgroundColor3 = accent}, 0.2) end
    if AIM_RECK_ENABLED then Tween(ReckToggleOuter, {BackgroundColor3 = accent}, 0.2) end
    if ESP_ENABLED then Tween(EspToggleOuter, {BackgroundColor3 = accent}, 0.2) end
end

for i, preset in ipairs(BordaPresets) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.BackgroundColor3 = preset.main
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.LayoutOrder = i
    btn.Parent = BordaButtonsContainer
    CreateCorner(btn, 11)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    stroke.Parent = btn
    if i == currentBordaIndex then
        stroke.Transparency = 0
        stroke.Thickness = 2
    end
    btn.MouseButton1Click:Connect(function()
        currentBordaIndex = i
        ApplyBordaColor(preset.main, preset.glow, preset.dark)
        for _, c in ipairs(BordaButtonsContainer:GetChildren()) do
            if c:IsA("TextButton") then
                local s = c:FindFirstChildOfClass("UIStroke")
                if s then s.Transparency = 0.6; s.Thickness = 1 end
            end
        end
        local s = btn:FindFirstChildOfClass("UIStroke")
        if s then s.Transparency = 0; s.Thickness = 2 end
    end)
    btn.MouseEnter:Connect(function()
        Tween(btn, {Size = UDim2.new(0, 24, 0, 24)}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {Size = UDim2.new(0, 22, 0, 22)}, 0.15)
    end)
end

local BufferRow = Instance.new("Frame")
BufferRow.Size = UDim2.new(1, 0, 0, 28)
BufferRow.Position = UDim2.new(0, 0, 0, 474)
BufferRow.BackgroundColor3 = Colors.Panel
BufferRow.BorderSizePixel = 0
BufferRow.Parent = ContentFrame
CreateCorner(BufferRow, 8)
CreateStroke(BufferRow, Color3.fromRGB(45, 45, 70), 1)
local BufferBtn = Instance.new("TextButton")
BufferBtn.Size = UDim2.new(1, 0, 1, 0)
BufferBtn.BackgroundTransparency = 1
BufferBtn.Text = "Buffer: ON"
BufferBtn.TextSize = 12
BufferBtn.Font = Enum.Font.SourceSansSemibold
BufferBtn.TextColor3 = Colors.Green
BufferBtn.TextXAlignment = Enum.TextXAlignment.Left
BufferBtn.Parent = BufferRow
BufferBtn.MouseButton1Click:Connect(function()
    BufferOn = not BufferOn
    BufferBtn.Text = "Buffer: " .. (BufferOn and "ON" or "OFF")
    BufferBtn.TextColor3 = BufferOn and Colors.Green or Colors.TextMuted
end)

Cleanup.Register(Players.PlayerAdded:Connect(function(plr)
    Cleanup.Register(plr.CharacterAdded:Connect(function(char)
        if Cleanup._active and ESP_ENABLED then AddEspToCharacter(char) end
    end))
    if plr.Character and ESP_ENABLED then AddEspToCharacter(plr.Character) end
end))

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        Cleanup.Register(plr.CharacterAdded:Connect(function(char)
            if Cleanup._active and ESP_ENABLED then AddEspToCharacter(char) end
        end))
        if plr.Character and ESP_ENABLED then AddEspToCharacter(plr.Character) end
    end
end

-- Reaplica ESP a cada 2.5s (throttled; loop encerra no cleanup)
task.spawn(function()
    while Cleanup._active do
        task.wait(2.5)
        if not Cleanup._active then break end
        if ESP_ENABLED then pcall(UpdateEspForAll) end
    end
end)

-- ═══════════════════════════════════════════════
-- STATUS BAR (Bottom)
-- ═══════════════════════════════════════════════
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, 0, 0, 58)
StatusBar.Position = UDim2.new(0, 0, 0, 510)
StatusBar.BackgroundColor3 = Colors.Panel
StatusBar.BorderSizePixel = 0
StatusBar.Parent = ContentFrame
CreateCorner(StatusBar, 10)
CreateStroke(StatusBar, Color3.fromRGB(45, 45, 70), 1)
local StatusBarTopLine = Instance.new("Frame")
StatusBarTopLine.Size = UDim2.new(1, 0, 0, 1)
StatusBarTopLine.Position = UDim2.new(0, 0, 0, 0)
StatusBarTopLine.BackgroundColor3 = Colors.Border
StatusBarTopLine.BorderSizePixel = 0
StatusBarTopLine.Parent = StatusBar
CreateCorner(StatusBarTopLine, 0)

local StatusIcon = Instance.new("Frame")
StatusIcon.Size = UDim2.new(0, 10, 0, 10)
StatusIcon.Position = UDim2.new(0, 16, 0, 14)
StatusIcon.BackgroundColor3 = Colors.Red
StatusIcon.BorderSizePixel = 0
StatusIcon.Parent = StatusBar
CreateCorner(StatusIcon, 5)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -44, 0, 18)
StatusText.Position = UDim2.new(0, 32, 0, 10)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Hitbox: Desativado"
StatusText.TextSize = 12
StatusText.Font = Enum.Font.SourceSansSemibold
StatusText.TextColor3 = Colors.TextSecondary
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusBar

local InfoText = Instance.new("TextLabel")
InfoText.Size = UDim2.new(1, -32, 0, 16)
InfoText.Position = UDim2.new(0, 16, 0, 34)
InfoText.BackgroundTransparency = 1
InfoText.Text = "RightShift = GUI | H = Hitbox"
InfoText.TextSize = 10
InfoText.Font = Enum.Font.SourceSans
InfoText.TextColor3 = Colors.TextMuted
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.Parent = StatusBar

-- ═══════════════════════════════════════════════
-- AVISO (reduzir risco de moderação)
-- ═══════════════════════════════════════════════
local DisclaimerBg = Instance.new("Frame")
DisclaimerBg.Size = UDim2.new(1, 0, 0, 32)
DisclaimerBg.Position = UDim2.new(0, 0, 0, 576)
DisclaimerBg.BackgroundColor3 = Color3.fromRGB(35, 25, 25)
DisclaimerBg.BorderSizePixel = 0
DisclaimerBg.Parent = ContentFrame
CreateCorner(DisclaimerBg, 8)
CreateStroke(DisclaimerBg, Color3.fromRGB(80, 50, 50), 1)
local DisclaimerText = Instance.new("TextLabel")
DisclaimerText.Size = UDim2.new(1, -20, 1, -10)
DisclaimerText.Position = UDim2.new(0, 10, 0, 5)
DisclaimerText.BackgroundTransparency = 1
DisclaimerText.Text = "⚠️ Pode violar ToS do Roblox/jogo. Risco de BAN por sua conta. Modo conservador ON."
DisclaimerText.TextSize = 10
DisclaimerText.Font = Enum.Font.SourceSans
DisclaimerText.TextColor3 = Color3.fromRGB(180, 140, 140)
DisclaimerText.TextXAlignment = Enum.TextXAlignment.Center
DisclaimerText.TextWrapped = true
DisclaimerText.Parent = DisclaimerBg

-- ═══════════════════════════════════════════════
-- FOOTER / CREDITS
-- ═══════════════════════════════════════════════
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 24)
Footer.Position = UDim2.new(0, 0, 0, 612)
Footer.BackgroundTransparency = 1
Footer.Text = "⚡ Henrydangerkk • v1.5 Final"
Footer.TextSize = 11
Footer.Font = Enum.Font.SourceSansSemibold
Footer.TextColor3 = Colors.TextMuted
Footer.TextXAlignment = Enum.TextXAlignment.Center
Footer.Parent = ContentFrame

local ToggleGuiBtn = Instance.new("TextButton")
ToggleGuiBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleGuiBtn.Position = UDim2.new(0, 10, 0.5, -22)
ToggleGuiBtn.BackgroundColor3 = Colors.Accent
ToggleGuiBtn.BorderSizePixel = 0
ToggleGuiBtn.Text = "🏐"
ToggleGuiBtn.TextSize = 22
ToggleGuiBtn.Font = Enum.Font.GothamBold
ToggleGuiBtn.TextColor3 = Colors.TextPrimary
ToggleGuiBtn.Visible = false
ToggleGuiBtn.Parent = ScreenGui
CreateCorner(ToggleGuiBtn, 22)
CreateStroke(ToggleGuiBtn, Colors.AccentGlow, 2)

ToggleGuiBtn.MouseEnter:Connect(function()
    Tween(ToggleGuiBtn, {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 7, 0.5, -25)}, 0.2)
end)
ToggleGuiBtn.MouseLeave:Connect(function()
    Tween(ToggleGuiBtn, {Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 10, 0.5, -22)}, 0.2)
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    Tween(MainFrame, {Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.3)
    MainFrame.Visible = false
    ToggleGuiBtn.Visible = true
    Tween(ToggleGuiBtn, {BackgroundTransparency = 0}, 0.2)
end)

ToggleGuiBtn.MouseButton1Click:Connect(function()
    ToggleGuiBtn.Visible = false
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, 0)
    Tween(MainFrame, {Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, MAIN_WINDOW_HEIGHT)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)

local cachedHitboxesFolder = nil
local hitboxWaiterActive = false

local function GetGameHitboxesFolder()
    if cachedHitboxesFolder and cachedHitboxesFolder.Parent then return cachedHitboxesFolder end
    cachedHitboxesFolder = nil
    local assets = R.F(N1)
    if assets then
        local h = assets:FindFirstChild(N2)
        if h and h:IsA("Folder") then cachedHitboxesFolder = h; return h end
    end
    local h = R.F(N2)
    if h and h:IsA("Folder") then cachedHitboxesFolder = h; return h end
    return nil
end

local function ApplyGameHitboxes(size)
    local folder = GetGameHitboxesFolder()
    if not folder then return false end
    local s = (size == nil or size <= 0) and GAME_HITBOX_DEFAULT_SIZE or math.clamp(size, 1, MAX_HITBOX_SIZE)
    local applied = 0
    for _, action in ipairs(folder:GetChildren()) do
        local part = action:FindFirstChild(N3) or action:FindFirstChild(N4) or action:FindFirstChildWhichIsA("BasePart")
        if not part and action:IsA("Model") then part = action.PrimaryPart or action:FindFirstChildWhichIsA("BasePart") end
        if not part and action:IsA("BasePart") then part = action end
        if part and part:IsA("BasePart") then part.Size = Vector3.new(s, s, s); applied = applied + 1 end
    end
    return applied > 0
end

local function TryWaitForHitboxesFolder()
    if hitboxWaiterActive or GetGameHitboxesFolder() then return end
    hitboxWaiterActive = true
    task.spawn(function()
        local a = R.W(N1, 6)
        if a and Cleanup._active and HITBOX_ENABLED then
            local h = a:WaitForChild(N2, 6)
            if h and h:IsA("Folder") then
                cachedHitboxesFolder = h
                pcall(function() ApplyGameHitboxes(HITBOX_SIZE) end)
                if InfoText then InfoText.Text = "Hitboxes: OK (alcance " .. HITBOX_SIZE .. ")" end
            end
        end
        hitboxWaiterActive = false
    end)
end

-- ═══════════════════════════════════════════════
Cleanup.Register(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == KEYBIND_TOGGLE_GUI then
        if MainFrame.Visible then
            task.spawn(function()
                Tween(MainFrame, {Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                task.wait(0.3)
                MainFrame.Visible = false
                ToggleGuiBtn.Visible = true
                Tween(ToggleGuiBtn, {BackgroundTransparency = 0}, 0.2)
            end)
        else
            ToggleGuiBtn.Visible = false
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, 0)
            Tween(MainFrame, {Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, MAIN_WINDOW_HEIGHT)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    elseif KEYBIND_TOGGLE_HITBOX and input.KeyCode == KEYBIND_TOGGLE_HITBOX then
        HITBOX_ENABLED = not HITBOX_ENABLED
        UpdateToggleVisual()
    end
end))

-- ═══════════════════════════════════════════════
local function UpdateToggleVisual()
    if HITBOX_ENABLED then
        cachedHitboxesFolder = nil
        TryWaitForHitboxesFolder()
        Tween(ToggleKnob, {Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = Colors.TextPrimary}, 0.25)
        Tween(ToggleOuter, {BackgroundColor3 = Colors.Accent}, 0.25)
        StatusLabel.Text = "ON"
        StatusLabel.TextColor3 = Colors.Green
        StatusText.Text = "Hitbox: Ativado (" .. HITBOX_SIZE .. ")"
        StatusIcon.BackgroundColor3 = Colors.Green
        pcall(function()
            ApplyGameHitboxes(HITBOX_SIZE)
            if InfoText then
                InfoText.Text = GetGameHitboxesFolder() and ("Hitboxes: OK (alcance " .. HITBOX_SIZE .. ")") or "Entre numa partida para ativar hitbox"
            end
        end)
    else
        Tween(ToggleKnob, {Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = Colors.TextMuted}, 0.25)
        Tween(ToggleOuter, {BackgroundColor3 = Colors.SliderBg}, 0.25)
        StatusLabel.Text = "OFF"
        StatusLabel.TextColor3 = Colors.Red
        StatusText.Text = "Hitbox: Desativado"
        StatusIcon.BackgroundColor3 = Colors.Red
        pcall(function() ApplyGameHitboxes(0) end)
        if InfoText then InfoText.Text = "RightShift = GUI | H = Hitbox" end
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    HITBOX_ENABLED = not HITBOX_ENABLED
    UpdateToggleVisual()
end)

ToggleRowButton.MouseButton1Click:Connect(function()
    HITBOX_ENABLED = not HITBOX_ENABLED
    UpdateToggleVisual()
end)

-- ═══════════════════════════════════════════════
-- SLIDER LOGIC
-- ═══════════════════════════════════════════════
local sliderDragging = false

local function UpdateSlider(input)
    local trackAbsPos = SliderTrack.AbsolutePosition.X
    local trackAbsSize = SliderTrack.AbsoluteSize.X
    if trackAbsSize <= 0 then return end
    local mouseX = input.Position.X

    local relX = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
    HITBOX_SIZE = math.floor(relX * MAX_HITBOX_SIZE)

    SliderFill.Size = UDim2.new(relX, 0, 1, 0)
    SliderValue.Text = tostring(HITBOX_SIZE)

    if HITBOX_ENABLED then
        StatusText.Text = "Hitbox: Ativado (" .. HITBOX_SIZE .. ")"
        pcall(function() ApplyGameHitboxes(HITBOX_SIZE) end)
    end
end

SliderButton.MouseButton1Down:Connect(function()
    sliderDragging = true
end)

Cleanup.Register(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end))
Cleanup.Register(UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSlider(input)
    end
end))

SliderButton.MouseButton1Click:Connect(function()
    -- Also update on single click
    local mousePos = UserInputService:GetMouseLocation()
    local input = {Position = Vector2.new(mousePos.X, 0)}
    UpdateSlider(input)
end)

-- Sincroniza o visual do slider com o valor atual (útil ao carregar ou resetar)
local function SyncSliderVisual()
    local range = MAX_HITBOX_SIZE - MIN_HITBOX_SIZE
    local relX = (range > 0) and math.clamp((HITBOX_SIZE - MIN_HITBOX_SIZE) / range, 0, 1) or 0
    SliderFill.Size = UDim2.new(relX, 0, 1, 0)
    SliderValue.Text = tostring(HITBOX_SIZE)
end
SyncSliderVisual()

-- ═══════════════════════════════════════════════
-- ═══════════════════════════════════════════════

local function GetCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local BALL_SEARCH_PATHS = {
    N5, N6,
    _("Bal", "l"), _("Volley", "ball"), _("bo", "la"), _("Volley", "Ball"), _("Game", "Ball"),
    _("Ball", "Part"), _("Main", "Ball"), _("Sph", "ere"), _("Project", "ile"),
    "TheBall", "SportsBall", "VB", "BallMesh", "SpherePart", "ClientBall", "GameBall",
    "Bola", "BeachBall", "Volei", "Ball1", "Ball 1", "Voleyball", "Volleyball"
}

local function looksLikeBall(obj)
    if not obj or not obj.Parent then return false end
    if obj:IsA("BasePart") then
        local m = obj.Size.Magnitude
        return m > 0.3 and m < 25
    end
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        return part and looksLikeBall(part)
    end
    return false
end

local function getPartFromBallObj(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then
        return (obj.Size.Magnitude > 0.3 and obj.Size.Magnitude < 25) and obj or nil
    end
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if part and part.Size.Magnitude > 0.3 and part.Size.Magnitude < 25 then
            return part
        end
    end
    return nil
end

local cachedBall = nil
local lastBallSearch = 0

local function isPartOfCharacter(part)
    if not part then return false end
    local p = part.Parent
    while p and p ~= workspace do
        if p:IsA("Model") and p:FindFirstChild("Humanoid") then return true end
        p = p.Parent
    end
    return false
end

local function looksLikeSphere(part)
    if not part or not part:IsA("BasePart") then return false end
    local s = part.Size
    local a, b, c = s.X, s.Y, s.Z
    if a < 0.4 or a > 12 or b < 0.4 or b > 12 or c < 0.4 or c > 12 then return false end
    local min, max = math.min(a, b, c), math.max(a, b, c)
    return (max - min) <= 2
end

local function findBallByShape()
    local root = GetRootPart()
    local myPos = root and root.Parent and root.Position or Vector3.new(0, 0, 0)
    local netPos = nil
    do
        local netNames = {"Net", "Rede", "RedeVolei", "VolleyballNet", "Middle", "Nets"}
        for _, nn in ipairs(netNames) do
            local obj = workspace:FindFirstChild(nn, true)
            if obj then
                if obj:IsA("BasePart") then netPos = obj.Position break end
                if obj:IsA("Model") and obj.PrimaryPart then netPos = obj.PrimaryPart.Position break end
                local p = obj:FindFirstChildWhichIsA("BasePart")
                if p then netPos = p.Position break end
            end
        end
    end
    local candidates = {}
    for _, a in ipairs(workspace:GetChildren()) do
        if a:IsA("BasePart") and not isPartOfCharacter(a) and looksLikeSphere(a) then
            candidates[#candidates + 1] = a
        end
        if not a:IsA("BasePart") then
            for _, b in ipairs(a:GetChildren()) do
                if b:IsA("BasePart") and not isPartOfCharacter(b) and looksLikeSphere(b) then
                    candidates[#candidates + 1] = b
                end
                if not b:IsA("BasePart") then
                    for _, c in ipairs(b:GetChildren()) do
                        if c:IsA("BasePart") and not isPartOfCharacter(c) and looksLikeSphere(c) then
                            candidates[#candidates + 1] = c
                        end
                    end
                end
            end
        end
    end
    if #candidates == 0 then return nil end
    if #candidates == 1 then return candidates[1] end
    local best = candidates[1]
    local bestScore = -1
    for i = 1, #candidates do
        local p = candidates[i]
        local vel = 0
        if p.AssemblyLinearVelocity then vel = p.AssemblyLinearVelocity.Magnitude
        elseif p.Velocity then vel = p.Velocity.Magnitude end
        local score = vel * 3
        if netPos and p.Parent then
            local distNet = (p.Position - netPos).Magnitude
            score = score + 80 / (1 + math.min(distNet, 50))
        end
        local distMe = (p.Position - myPos).Magnitude
        score = score - distMe * 0.02
        if vel > 12 then score = score + 150 end
        if score > bestScore then
            bestScore = score
            best = p
        end
    end
    return best
end

local function FindBall()
    if cachedBall and cachedBall.Parent then
        return cachedBall
    end

    local now = tick()
    if now - lastBallSearch < BALL_SEARCH_INTERVAL then
        return nil
    end
    lastBallSearch = now

    for _, pathName in ipairs(BALL_SEARCH_PATHS) do
        local obj = workspace:FindFirstChild(pathName, true)
        if obj then
            local part = getPartFromBallObj(obj)
            if part then
                cachedBall = part
                return part
            end
            if obj:IsA("BasePart") and obj.Size.Magnitude < 25 and obj.Size.Magnitude > 0.3 then
                cachedBall = obj
                return obj
            end
        end
    end

    local nameLower
    for _, child in ipairs(workspace:GetChildren()) do
        nameLower = child.Name:lower()
        if (nameLower:find("ball") or nameLower:find("bola") or nameLower:find("sphere") or nameLower:find("volley")) and looksLikeBall(child) then
            local part = getPartFromBallObj(child)
            if part then
                cachedBall = part
                return part
            end
        end
        for _, sub in ipairs(child:GetChildren()) do
            nameLower = sub.Name:lower()
            if (nameLower:find("ball") or nameLower:find("bola") or nameLower:find("sphere") or nameLower:find("volley")) and looksLikeBall(sub) then
                local part = getPartFromBallObj(sub)
                if part then
                    cachedBall = part
                    return part
                end
            end
        end
    end

    local byShape = findBallByShape()
    if byShape then
        cachedBall = byShape
        return byShape
    end

    return nil
end
local function DebugPrintObjects()
    if debugRan then return end
    debugRan = true
    for _, child in ipairs(workspace:GetChildren()) do
        print("  " .. child.ClassName .. " " .. child.Name)
    end
end
local hitboxConnection = nil
local frameCounter = 0

local function ResetAll()
    HITBOX_ENABLED = false
    HITBOX_SIZE = MIN_HITBOX_SIZE
    cachedBall = nil
    cachedHitboxesFolder = nil
    pcall(function() ApplyGameHitboxes(0) end)
end

hitboxConnection = RunService.RenderStepped:Connect(function()
    if not Cleanup._active then return end
    if not Safe.IsValidGui() then return end

    local cam = workspace.CurrentCamera
    local ball = FindBall()
    if AIM_RECK_ENABLED and not ball then cachedBall = nil end
    if cam and BallConeOutline and BallConeOutline.Parent then
        if ball and ball.Parent then
            local cf = cam.CFrame
            local lv = cf.LookVector
            local tp = cf.Position
            local bp = ball.Position
            local dv = (bp - tp).Unit
            local dot = math.clamp(lv:Dot(dv), -1, 1)
            local ang = math.acos(dot)
            if ang <= CONE_LIM_RAD then
                local vx, vy, on = cam:WorldToViewportPoint(bp)
                if on then
                    if math.random() < (30/100) then
                        vx = vx + (math.random(1, 2) * (math.random() >= 0.5 and 1 or -1))
                        vy = vy + (math.random(1, 2) * (math.random() >= 0.5 and 1 or -1))
                    end
                    BallConeOutline.Position = UDim2.new(0, vx, 0, vy)
                    BallConeOutline.Visible = true
                    BallInCone = true
                else
                    BallConeOutline.Visible = false
                    BallInCone = false
                end
            else
                BallConeOutline.Visible = false
                BallInCone = false
            end
        else
            BallConeOutline.Visible = false
            BallInCone = false
        end
    elseif BallConeOutline then
        BallConeOutline.Visible = false
        BallInCone = false
    end

    if AIM_RECK_ENABLED and AimReckMarker and AimReckMarker.Parent then
        local rp = GetRootPart()
        if rp and rp.Parent and ball and ball.Parent and cam then
            local v2 = cam:WorldToViewportPoint(ball.Position)
            local vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
            local m = 50
            AimReckMarker.Position = UDim2.new(0, math.clamp(v2.X, m, vw - m), 0, math.clamp(v2.Y, m, vh - m))
            AimReckMarker.Visible = true
        else
            AimReckMarker.Visible = false
        end
    end

    if BufferOn and frameCounter % 60 == 0 and #B >= 2 then end

    frameCounter = frameCounter + 1
    if DEBUG_ENABLED and frameCounter == 180 then
        Safe.Call(DebugPrintObjects)
    end

    if not HITBOX_ENABLED or HITBOX_SIZE <= 0 then return end
    local rootPart = GetRootPart()
    if not rootPart then return end
    if not ball then return end
    if ANTICHEAT_DISABLE_BALL_PULL then return end

    -- Aplicar pull só a cada N frames (+ jitter) para não ficar padrão constante
    local pullInterval = BALL_PULL_FRAME_INTERVAL
    if pullInterval < 1 then pullInterval = 1 end
    if frameCounter % pullInterval ~= 0 then return end

    local playerPos = rootPart.Position
    local ballPos = ball.Position
    local distance = (ballPos - playerPos).Magnitude
    if distance <= HITBOX_SIZE and distance > 1 then
        pcall(function()
            local direction = (ballPos - playerPos).Unit
            local pullDist = PULL_DISTANCE * (0.92 + math.random() * 0.16)
            local lerpSpeed = math.clamp(BALL_LERP_SPEED * (0.9 + math.random() * 0.25), 0.05, 0.5)
            local targetPos = playerPos + direction * pullDist
            local newPos = ball.Position:Lerp(targetPos, lerpSpeed)
            ball.CFrame = CFrame.new(newPos)
        end)
    end
end)
Cleanup.Register(hitboxConnection)
Cleanup.Register(LocalPlayer.CharacterAdded:Connect(function()
    cachedBall = nil
    cachedHitboxesFolder = nil
    task.defer(function()
        task.wait(1)
        if not Cleanup._active or not HITBOX_ENABLED then return end
        pcall(function() ApplyGameHitboxes(HITBOX_SIZE) end)
    end)
end))
task.spawn(function()
    while Cleanup._active do
        local minS = (type(HITBOX_REAPPLY_MIN_SEC) == "number" and HITBOX_REAPPLY_MIN_SEC > 0) and HITBOX_REAPPLY_MIN_SEC or 25
        local maxS = (type(HITBOX_REAPPLY_MAX_SEC) == "number" and HITBOX_REAPPLY_MAX_SEC >= minS) and HITBOX_REAPPLY_MAX_SEC or (minS + 20)
        task.wait(minS + (math.random() * (maxS - minS)))
        if not Cleanup._active then break end
        if not Safe.IsValidGui() then break end
        if HITBOX_ENABLED then
            pcall(function()
                if ApplyGameHitboxes(HITBOX_SIZE) and InfoText then
                    InfoText.Text = "Hitboxes: OK (alcance " .. HITBOX_SIZE .. ")"
                end
            end)
        end
    end
end)
MainFrame.Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, 0)
MainFrame.BackgroundTransparency = 1

local waitRemaining = scriptStartTime - tick()
if waitRemaining > 0 then task.wait(waitRemaining) end

task.wait(0.1)

Tween(MainFrame, {BackgroundTransparency = 0}, 0.3)
Tween(MainFrame, {Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, MAIN_WINDOW_HEIGHT)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
function Cleanup.Run()
    Cleanup._active = false
    for _, conn in ipairs(Cleanup._connections) do
        Safe.Call(function() conn:Disconnect() end)
    end
    Cleanup._connections = {}
    if hitboxConnection then Safe.Call(function() hitboxConnection:Disconnect() end); hitboxConnection = nil end
    Safe.Call(function() ApplyGameHitboxes(0) end)
    ESP_ENABLED = false
    AIM_RECK_ENABLED = false
    if AimReckMarker and AimReckMarker.Parent then AimReckMarker.Visible = false end
    if Safe.IsValidPlayer() then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then RemoveEspFromCharacter(plr.Character) end
        end
    end
    ResetAll()
end

ScreenGui.Destroying:Connect(function()
    Cleanup.Run()
end)

-- ═══════════════════════════════════════════════
-- NOTIFICATION
-- ═══════════════════════════════════════════════
pcall(function()
    StarterGui:SetCore("SendNotification", { Title = "VL", Text = "OK", Duration = 2 })
end)

if DEBUG_ENABLED then print("[VL] ok") end
