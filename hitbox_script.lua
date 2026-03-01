--[[
    ╔══════════════════════════════════════════════╗
    ║     VOLLEYBALL LEGENDS — Hitbox & ESP         ║
    ║           Criador: Henrydangerkk             ║
    ║       Executor: Velocity Compatible          ║
    ╚══════════════════════════════════════════════╝
    Colar em StarterPlayer > StarterPlayerScripts (ou use load_volleyball_legends.lua
    para carregar por URL e colar só o loader — pode reduzir ban).
    Teclas: RightShift = GUI | H = Hitbox
]]

-- Verificação do ambiente (game no Roblox é userdata, não table)
if game == nil or type(game.GetService) ~= "function" then
    warn("[Volleyball Legends] Execute com um executor que suporte Roblox (game, GetService).")
    return
end

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

-- ═══════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════
--[[
  CONFIG LEGIT (exemplo para rankeadas / menos óbvio):
  - Hitbox: 20 (um pouco maior que o padrão ~10, ajuda a pegar bolas no limite)
  - Aim Reck: ON (marcador de queda — qualquer direção, para ajudar na recepção e aos amigos)
  - Cone da bola: ON (ajuda timing do batimento, não revela onde vai cair)
  - ESP: OFF (wallhack chama atenção em ranked)
  - Buffer: ON (ajusta timing sutilmente)
  - Ball pull: OFF (já está em ANTICHEAT_DISABLE_BALL_PULL = true)
]]
local HITBOX_ENABLED = false
local HITBOX_SIZE = 0
local MIN_HITBOX_SIZE = 0
local MAX_HITBOX_SIZE = 50
local BALL_SEARCH_INTERVAL = 0.5
local DEBUG_ENABLED = false
-- Distância (em studs) para onde a bola é puxada em direção ao jogador
local PULL_DISTANCE = 2
-- Suavização do movimento da bola (0 = instantâneo, 1 = muito lento)
local BALL_LERP_SPEED = 0.25
-- Tecla para abrir/fechar a GUI (Enum.KeyCode)
local KEYBIND_TOGGLE_GUI = Enum.KeyCode.RightShift
-- Tecla para ligar/desligar hitbox rapidamente (opcional, nil = desativado)
local KEYBIND_TOGGLE_HITBOX = Enum.KeyCode.H
-- Tamanho padrão do hitbox do jogo quando o módulo está OFF (Volleyball Legends usa ~10)
local GAME_HITBOX_DEFAULT_SIZE = 10

-- ═══════════════════════════════════════════════
-- CONFIG ANTICHEAT / QUESTÃO BANIMENTO
-- Hitbox e wallhack 100%. Para durar mais (tipo Sterling ~5 dias): não escrever em
-- ReplicatedStorage; não usar GetDescendants no ReplicatedStorage; só caminho direto Assets.Hitboxes.
-- BAN APÓS 1 USO: este script estava criando/escrevendo no ReplicatedStorage e usando
-- GetDescendants(ReplicatedStorage) — isso pode ser detectado. Removido. Só usamos Assets.Hitboxes.
-- ═══════════════════════════════════════════════
-- NÃO escreve no ReplicatedStorage. Deixe true.
local ANTICHEAT_SAFE_NO_REPLICATED_WRITE = true
-- true = NÃO faz hook no BindActivate (muito exposto). Hitbox e ESP não dependem disso.
local ANTICHEAT_SAFE_NO_BINDACTIVATE_HOOK = true
-- Pull da bola a cada N frames (só se DISABLE_BALL_PULL = false)
local BALL_PULL_FRAME_INTERVAL = 2
-- Variação no intervalo de reaplicar hitbox (evita intervalo fixo)
local HITBOX_REAPPLY_JITTER_MAX = 0.8
-- Base do intervalo de reaplicar hitbox (segundos). Como antes: ~2s.
local HITBOX_REAPPLY_BASE_SEC = 2
-- true = NÃO puxa a bola (muito exposto; servidor detecta). Hitbox expandida continua igual.
local ANTICHEAT_DISABLE_BALL_PULL = true

-- ═══════════════════════════════════════════════
-- COLOR PALETTE (Premium Dark Theme)
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

-- ═══════════════════════════════════════════════
-- CAMADA ANTI-DETECÇÃO (por fora — não mexe em hitbox nem wallhack)
-- Nomes aleatórios + atraso opcional para não parecer script injetado no join.
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
-- Atraso antes de mostrar GUI e aplicar hitbox (segundos).
-- 0,0 = como antes: janela e hitbox na hora.
local ANTIDETECT_START_DELAY_MIN = 0
local ANTIDETECT_START_DELAY_MAX = 0
local scriptStartTime
if ANTIDETECT_START_DELAY_MIN == 0 and ANTIDETECT_START_DELAY_MAX == 0 then
    scriptStartTime = 0
else
    scriptStartTime = tick() + (math.random() * (ANTIDETECT_START_DELAY_MAX - ANTIDETECT_START_DELAY_MIN) + ANTIDETECT_START_DELAY_MIN)
end
local GUI_PUBLIC_NAME = _RandomName("", 12)
local ESP_PUBLIC_NAME = _RandomName("", 10)

-- ═══════════════════════════════════════════════
-- ANTI-DUPLICATE: Remove old GUI if re-executing (por estrutura, não por nome)
-- ═══════════════════════════════════════════════
for _, child in ipairs(CoreGui:GetChildren()) do
    if child:IsA("ScreenGui") and child:FindFirstChild("MainFrame") then
        child:Destroy()
        break
    end
end

-- ═══════════════════════════════════════════════
-- MÓDULO CLEANUP (boas práticas: desconectar tudo e restaurar estado)
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

local BindActivate = ReplicatedStorage:FindFirstChild("BindActivate")
if not BindActivate and ReplicatedStorage:FindFirstChild("Assets") then
    BindActivate = ReplicatedStorage.Assets:FindFirstChild("BindActivate")
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
-- MAIN WINDOW (maior — espaço para conteúdo e decoração)
-- ═══════════════════════════════════════════════
local MAIN_WINDOW_WIDTH = 380
local MAIN_WINDOW_HEIGHT = 680
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

-- ═══════════════════════════════════════════════
-- DECORAÇÃO: bolinhas/orbs que flutuam (maiores, mais visíveis, com espaço)
-- ═══════════════════════════════════════════════
local DecorationContainer = Instance.new("Frame")
DecorationContainer.Name = "FloatingOrbs"
DecorationContainer.Size = UDim2.new(1, -24, 1, -24)
DecorationContainer.Position = UDim2.new(0, 12, 0, 12)
DecorationContainer.BackgroundTransparency = 1
DecorationContainer.BorderSizePixel = 0
DecorationContainer.ClipsDescendants = true
DecorationContainer.ZIndex = 0
DecorationContainer.Parent = MainFrame

-- Tamanho e visibilidade: bolinhas maiores, menos transparentes, amplitude maior
local FLOAT_ORB_SIZE = 14
local FLOAT_AMP = 22
local FLOAT_SPEED = 1.6
local orbData = {}
-- Posições nas bordas e cantos (espaço livre, não em cima do conteúdo central)
local orbPositions = {
    { 28, 95 },   { 352, 95 },   { 28, 585 },  { 352, 585 },
    { 28, 340 },  { 352, 340 },  { 190, 28 },  { 190, 652 },
    { 75, 200 },  { 305, 480 },  { 280, 180 },  { 100, 500 }
}
for i, pos in ipairs(orbPositions) do
    local orb = Instance.new("Frame")
    orb.Name = "Orb" .. i
    orb.Size = UDim2.new(0, FLOAT_ORB_SIZE, 0, FLOAT_ORB_SIZE)
    orb.Position = UDim2.new(0, pos[1], 0, pos[2])
    orb.AnchorPoint = Vector2.new(0.5, 0.5)
    orb.BackgroundColor3 = i % 3 == 0 and Colors.AccentGlow or (i % 3 == 1 and Colors.Accent or Color3.fromRGB(130, 60, 220))
    orb.BackgroundTransparency = 0.4
    orb.BorderSizePixel = 0
    orb.ZIndex = 0
    orb.Parent = DecorationContainer
    CreateCorner(orb, FLOAT_ORB_SIZE)
    table.insert(orbData, {
        orb = orb,
        baseX = pos[1],
        baseY = pos[2],
        phaseX = (i - 1) * 0.7,
        phaseY = (i - 1) * 0.5 + 0.3,
        ampX = FLOAT_AMP + (i % 2) * 5,
        ampY = FLOAT_AMP - (i % 3) * 3
    })
end

local decorationStartTime = tick()
local function UpdateFloatingOrbs()
    if not DecorationContainer or not DecorationContainer.Parent or not MainFrame.Visible then return end
    local t = (tick() - decorationStartTime) * FLOAT_SPEED
    for _, data in ipairs(orbData) do
        local x = data.baseX + math.sin(t + data.phaseX) * data.ampX
        local y = data.baseY + math.sin(t * 0.85 + data.phaseY) * data.ampY
        data.orb.Position = UDim2.new(0, x, 0, y)
    end
end

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
-- Marcador Aim Reck (onde a bola vai cair — recepção / ajudar amigos)
local AimReckMarker = Instance.new("Frame")
AimReckMarker.Name = "AimReckMarker"
AimReckMarker.Size = UDim2.new(0, 40, 0, 40)
AimReckMarker.Position = UDim2.new(0, 0, 0, 0)
AimReckMarker.AnchorPoint = Vector2.new(0.5, 0.5)
AimReckMarker.BackgroundColor3 = Color3.fromRGB(50, 205, 100)
AimReckMarker.BackgroundTransparency = 0.4
AimReckMarker.BorderSizePixel = 0
AimReckMarker.Visible = false
AimReckMarker.ZIndex = 5
AimReckMarker.Parent = ScreenGui
CreateCorner(AimReckMarker, 20)
local AimReckStroke = Instance.new("UIStroke")
AimReckStroke.Thickness = 3
AimReckStroke.Color = Color3.fromRGB(255, 255, 255)
AimReckStroke.Transparency = 0.2
AimReckStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
AimReckStroke.Parent = AimReckMarker
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
-- Nunca criar nem escrever no ReplicatedStorage (causa ban rápido). Sterling não fazia isso.
if not ANTICHEAT_SAFE_NO_REPLICATED_WRITE then
    DbgSv = ReplicatedStorage:FindFirstChild("Dbg")
    if not DbgSv or not DbgSv:IsA("StringValue") then
        DbgSv = Instance.new("StringValue")
        DbgSv.Name = rndName()
        DbgSv.Parent = ReplicatedStorage
    end
end

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
    if not BufferOn or not BallInCone then return end
    local now = os.clock()
    if lastT > 0 then
        local dt = now - lastT
        if comp then
            dt = math.clamp(dt * (1 + gx()), (11/100), (24/100))
            comp = false
        end
        if math.random() >= (3/100) then
            if #B >= 120 then table.remove(B, 1) end
            table.insert(B, dt)
            hitCounterLocal = hitCounterLocal + 1
        end
    end
    lastT = now
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
TitleIcon.Font = Enum.Font.SourceSans
TitleIcon.TextColor3 = Colors.TextPrimary
TitleIcon.Parent = TitleBar

-- Title text
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -110, 0, 24)
TitleText.Position = UDim2.new(0, 56, 0, 8)
TitleText.BackgroundTransparency = 1
TitleText.Text = "VOLLEYBALL LEGENDS"
TitleText.TextSize = 16
TitleText.Font = Enum.Font.GothamBold
TitleText.TextColor3 = Colors.TextPrimary
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Creator (Henrydangerkk) — em destaque
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
-- CONTENT AREA
-- ═══════════════════════════════════════════════
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, -32, 1, -88)
ContentFrame.Position = UDim2.new(0, 16, 0, 72)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- ═══════════════════════════════════════════════
-- HITBOX MODULE SECTION
-- ═══════════════════════════════════════════════

-- Section Header (Hitbox)
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
SectionIcon.Font = Enum.Font.SourceSans
SectionIcon.TextColor3 = Colors.TextPrimary
SectionIcon.Parent = SectionHeader

local SectionTitle = Instance.new("TextLabel")
SectionTitle.Size = UDim2.new(1, -55, 1, 0)
SectionTitle.Position = UDim2.new(0, 50, 0, 0)
SectionTitle.BackgroundTransparency = 1
SectionTitle.Text = "HITBOX MODULE"
SectionTitle.TextSize = 13
SectionTitle.Font = Enum.Font.GothamBold
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
ToggleLabel.Font = Enum.Font.GothamMedium
ToggleLabel.TextColor3 = Colors.TextSecondary
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.Parent = ToggleContainer

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
SliderLabel.Font = Enum.Font.GothamMedium
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
SliderValue.Font = Enum.Font.GothamBold
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
-- AIM RECK (Onde a bola vai cair — recepção / ajudar amigos)
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
ReckSectionIcon.Font = Enum.Font.SourceSans
ReckSectionIcon.TextColor3 = Colors.TextPrimary
ReckSectionIcon.Parent = ReckSectionHeader

local ReckSectionTitle = Instance.new("TextLabel")
ReckSectionTitle.Size = UDim2.new(1, -55, 1, 0)
ReckSectionTitle.Position = UDim2.new(0, 50, 0, 0)
ReckSectionTitle.BackgroundTransparency = 1
ReckSectionTitle.Text = "AIM RECK"
ReckSectionTitle.TextSize = 13
ReckSectionTitle.Font = Enum.Font.GothamBold
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
ReckToggleLabel.Font = Enum.Font.GothamMedium
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
-- PLAYER ESP (Wallhack)
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
EspSectionIcon.Font = Enum.Font.SourceSans
EspSectionIcon.TextColor3 = Colors.TextPrimary
EspSectionIcon.Parent = EspSectionHeader

local EspSectionTitle = Instance.new("TextLabel")
EspSectionTitle.Size = UDim2.new(1, -55, 1, 0)
EspSectionTitle.Position = UDim2.new(0, 50, 0, 0)
EspSectionTitle.BackgroundTransparency = 1
EspSectionTitle.Text = "PLAYER ESP"
EspSectionTitle.TextSize = 13
EspSectionTitle.Font = Enum.Font.GothamBold
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
EspToggleLabel.Font = Enum.Font.GothamMedium
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

local BufferRow = Instance.new("Frame")
BufferRow.Size = UDim2.new(1, 0, 0, 28)
BufferRow.Position = UDim2.new(0, 0, 0, 392)
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
BufferBtn.Font = Enum.Font.GothamMedium
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
StatusBar.Position = UDim2.new(0, 0, 0, 368)
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
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextColor3 = Colors.TextSecondary
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusBar

local InfoText = Instance.new("TextLabel")
InfoText.Size = UDim2.new(1, -32, 0, 16)
InfoText.Position = UDim2.new(0, 16, 0, 34)
InfoText.BackgroundTransparency = 1
InfoText.Text = "RightShift = GUI | H = Hitbox"
InfoText.TextSize = 10
InfoText.Font = Enum.Font.Gotham
InfoText.TextColor3 = Colors.TextMuted
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.Parent = StatusBar

-- ═══════════════════════════════════════════════
-- AVISO (reduzir risco de moderação)
-- ═══════════════════════════════════════════════
local DisclaimerBg = Instance.new("Frame")
DisclaimerBg.Size = UDim2.new(1, 0, 0, 32)
DisclaimerBg.Position = UDim2.new(0, 0, 0, 426)
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
DisclaimerText.Font = Enum.Font.Gotham
DisclaimerText.TextColor3 = Color3.fromRGB(180, 140, 140)
DisclaimerText.TextXAlignment = Enum.TextXAlignment.Center
DisclaimerText.TextWrapped = true
DisclaimerText.Parent = DisclaimerBg

-- ═══════════════════════════════════════════════
-- FOOTER / CREDITS
-- ═══════════════════════════════════════════════
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 24)
Footer.Position = UDim2.new(0, 0, 0, 458)
Footer.BackgroundTransparency = 1
Footer.Text = "⚡ Henrydangerkk • v1.4"
Footer.TextSize = 11
Footer.Font = Enum.Font.GothamMedium
Footer.TextColor3 = Colors.TextMuted
Footer.TextXAlignment = Enum.TextXAlignment.Center
Footer.Parent = ContentFrame

-- ═══════════════════════════════════════════════
-- MINIMIZE / TOGGLE GUI BUTTON (floating)
-- ═══════════════════════════════════════════════
local ToggleGuiBtn = Instance.new("TextButton")
ToggleGuiBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleGuiBtn.Position = UDim2.new(0, 10, 0.5, -22)
ToggleGuiBtn.BackgroundColor3 = Colors.Accent
ToggleGuiBtn.BorderSizePixel = 0
ToggleGuiBtn.Text = "🏐"
ToggleGuiBtn.TextSize = 22
ToggleGuiBtn.Font = Enum.Font.SourceSans
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

-- ═══════════════════════════════════════════════
-- MINIMIZE / RESTORE LOGIC
-- ═══════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════
-- KEYBINDS (teclas de atalho)
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
-- TOGGLE HITBOX LOGIC
-- ═══════════════════════════════════════════════
local function UpdateToggleVisual()
    if HITBOX_ENABLED then
        Tween(ToggleKnob, {Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = Colors.TextPrimary}, 0.25)
        Tween(ToggleOuter, {BackgroundColor3 = Colors.Accent}, 0.25)
        StatusLabel.Text = "ON"
        StatusLabel.TextColor3 = Colors.Green
        StatusText.Text = "Hitbox: Ativado (" .. HITBOX_SIZE .. ")"
        StatusIcon.BackgroundColor3 = Colors.Green
        pcall(function()
            ApplyGameHitboxes(HITBOX_SIZE)
            if InfoText and not GetGameHitboxesFolder() then
                InfoText.Text = "Entre numa partida para ativar hitbox"
            end
        end)
        task.delay(1, function()
            if HITBOX_ENABLED and ApplyGameHitboxes(HITBOX_SIZE) and InfoText then
                InfoText.Text = "Hitboxes: OK (alcance " .. HITBOX_SIZE .. ")"
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
-- HITBOX IN-GAME (Volleyball Legends – por ação)
-- ═══════════════════════════════════════════════
-- O jogo usa ReplicatedStorage.Assets.Hitboxes: cada ação (Spike, Bump, Dive,
-- Set, Serve, Block, JumpSet) tem uma Part. Redimensionamos essa Part para
-- o valor do slider (0–50). Assim, quando você usa BATIR / MERGULHO / etc.,
-- o alcance do toque na bola segue o tamanho que você definiu. Base em scripts
-- públicos (ex.: Sterling Hub).

-- Procura a pasta Hitboxes (como era antes: direto e depois em todo o ReplicatedStorage se precisar).
local cachedHitboxesFolder = nil

local function GetGameHitboxesFolder()
    if cachedHitboxesFolder and cachedHitboxesFolder.Parent then
        return cachedHitboxesFolder
    end
    cachedHitboxesFolder = nil
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if assets then
        local h = assets:FindFirstChild("Hitboxes")
        if h and h:IsA("Folder") then
            cachedHitboxesFolder = h
            return h
        end
    end
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child.Name == "Hitboxes" and child:IsA("Folder") then
            cachedHitboxesFolder = child
            return child
        end
    end
    return nil
end

-- Aplica o tamanho (como antes: direto em cada Part).
local function ApplyGameHitboxes(size)
    local folder = GetGameHitboxesFolder()
    if not folder then return false end
    local s = (size == nil or size <= 0) and GAME_HITBOX_DEFAULT_SIZE or math.max(1, size)
    local applied = 0
    for _, action in ipairs(folder:GetChildren()) do
        local part = action:FindFirstChild("Part") or action:FindFirstChildWhichIsA("BasePart")
        if part and part:IsA("BasePart") then
            part.Size = Vector3.new(s, s, s)
            applied = applied + 1
        end
    end
    if applied > 0 and DEBUG_ENABLED then
        print("[Script] Hitbox aplicado: " .. applied .. " ações, alcance " .. s)
    end
    return applied > 0
end

local function GetCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Aim Reck: prevê onde a bola vai cair (qualquer direção), para ajudar na recepção e aos amigos.
local AIM_RECK_MIN_VELOCITY = 18
local AIM_RECK_MAX_LANDING_DIST = 250
local AIM_RECK_GROUND_OFFSET = 3.5

local function getBallVelocity(ball)
    if not ball or not ball.Parent then return nil end
    if ball.AssemblyLinearVelocity then return ball.AssemblyLinearVelocity end
    if ball.Velocity then return ball.Velocity end
    return nil
end

local function predictLandingPosition(ball, rootPart)
    if not rootPart or not rootPart.Parent then return nil end
    local vel = getBallVelocity(ball)
    if not vel or vel.Magnitude < AIM_RECK_MIN_VELOCITY then return nil end
    local g = workspace.Gravity or 196.2
    local gravityVec = Vector3.new(0, -g, 0)
    local dt = 1/90
    local p = ball.Position
    local v = Vector3.new(vel.X, vel.Y, vel.Z)
    local groundY = rootPart.Position.Y - AIM_RECK_GROUND_OFFSET
    for _ = 1, 900 do
        p = p + v * dt
        v = v + gravityVec * dt
        if p.Y <= groundY then
            local landing = Vector3(p.X, groundY, p.Z)
            if (landing - rootPart.Position).Magnitude > AIM_RECK_MAX_LANDING_DIST then return nil end
            return landing
        end
    end
    return nil
end

-- Find the ball object in workspace
-- Volleyball Legends: bola = CLIENT_BALL ou CLIENT_BALL_ (Model ou Part). Velocity compatible.
local cachedBall = nil
local lastBallSearch = 0
-- Busca pesada (GetDescendants) só a cada 2.5s para não expor padrão
local BALL_HEAVY_SEARCH_INTERVAL = 2.5
local lastHeavyBallSearch = 0

-- Nomes específicos do Volleyball Legends primeiro; depois genéricos
local BALL_SEARCH_PATHS = {
    "CLIENT_BALL", "CLIENT_BALL_",  -- Volleyball Legends (objeto da bola no workspace)
    "Ball", "Volleyball", "bola", "VolleyBall", "GameBall",
    "BallPart", "MainBall", "Sphere", "Projectile"
}

local function getPartFromBallObj(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then
        return (obj.Size.Magnitude > 0.5 and obj.Size.Magnitude < 20) and obj or nil
    end
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if part and part.Size.Magnitude > 0.5 and part.Size.Magnitude < 20 then
            return part
        end
    end
    return nil
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

    -- 1) Volleyball Legends: CLIENT_BALL / CLIENT_BALL_
    for _, name in ipairs({"CLIENT_BALL", "CLIENT_BALL_"}) do
        local obj = workspace:FindFirstChild(name, true)
        local part = getPartFromBallObj(obj)
        if part then
            cachedBall = part
            return part
        end
    end

    -- 2) Outros caminhos comuns
    for _, pathName in ipairs(BALL_SEARCH_PATHS) do
        if pathName == "CLIENT_BALL" or pathName == "CLIENT_BALL_" then
        else
            local obj = workspace:FindFirstChild(pathName, true)
            if obj and obj:IsA("BasePart") then
                if obj.Size.Magnitude < 20 and obj.Size.Magnitude > 0.5 then
                    cachedBall = obj
                    return obj
                end
            end
        end
    end

    -- 3 e 4) Busca pesada (GetDescendants) só de vez em quando
    if now - lastHeavyBallSearch < BALL_HEAVY_SEARCH_INTERVAL then
        return nil
    end
    lastHeavyBallSearch = now

    -- 3) Busca por nome em todos os descendants
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("ball") or name:find("volley") or name:find("bola") or name:find("sphere") or name:find("projectile") then
                if obj.Size.Magnitude < 20 and obj.Size.Magnitude > 0.5 then
                    cachedBall = obj
                    return obj
                end
            end
        end
    end

    -- 4) Partes Part com Shape = Ball
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Shape == Enum.PartType.Ball then
            if obj.Size.Magnitude < 20 and obj.Size.Magnitude > 0.5 then
                cachedBall = obj
                return obj
            end
        end
    end

    return nil
end

-- ═══════════════════════════════════════════════
-- DEBUG: Print ALL workspace objects (run once)
-- ═══════════════════════════════════════════════
local debugRan = not DEBUG_ENABLED
local function DebugPrintObjects()
    if debugRan then return end
    debugRan = true

    print("[Madara877fa] 🔍 DEBUG — Scanning ALL workspace descendants...")
    local partCount = 0
    local modelCount = 0
    
    -- Print top-level children first
    print("[Madara877fa] 📁 Top-level workspace children:")
    for _, child in ipairs(workspace:GetChildren()) do
        print(string.format("  [%s] %s", child.ClassName, child.Name))
    end
    
    -- Scan ALL BaseParts
    print("[Madara877fa] 📦 All BaseParts in workspace:")
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            partCount = partCount + 1
            -- Print everything to find the ball
            if partCount <= 100 then
                local shape = ""
                if obj:IsA("Part") then
                    shape = " Shape:" .. tostring(obj.Shape)
                end
                print(string.format("  [Part] %s | Size: %s%s | Path: %s",
                    obj.Name, tostring(obj.Size), shape,
                    obj:GetFullName()
                ))
            end
        elseif obj:IsA("Model") then
            modelCount = modelCount + 1
        end
    end
    
    print(string.format("[Madara877fa] 📊 Total: %d BaseParts, %d Models", partCount, modelCount))
end

-- ═══════════════════════════════════════════════
-- MAIN LOOP (RenderStepped — runs before physics)
-- ═══════════════════════════════════════════════
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

    -- Atualiza decoração das bolinhas flutuantes (só quando a janela está visível)
    UpdateFloatingOrbs()

    local cam = workspace.CurrentCamera
    -- Uma única chamada FindBall() por frame (cone + pull)
    local ball = FindBall()
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

    -- Aim Reck: marcador de queda (qualquer direção — ajuda na recepção e aos amigos)
    if AIM_RECK_ENABLED and AimReckMarker and AimReckMarker.Parent then
        local rootPart = GetRootPart()
        if ball and ball.Parent and rootPart and cam then
            local landing = predictLandingPosition(ball, rootPart)
            if landing then
                local v2, onScreen = cam:WorldToViewportPoint(landing)
                if onScreen then
                    AimReckMarker.Position = UDim2.new(0, v2.X, 0, v2.Y)
                    AimReckMarker.Visible = true
                else
                    AimReckMarker.Visible = false
                end
            else
                AimReckMarker.Visible = false
            end
        else
            AimReckMarker.Visible = false
        end
    end

    if BufferOn and frameCounter % 60 == 0 and #B >= 2 then
        local s = sd(B)
        if s and s < (7/200) then
            lsc = lsc + 1
            if lsc >= 2 then comp = true; lsc = 0 end
        else
            lsc = 0
        end
    end

    frameCounter = frameCounter + 1
    if DEBUG_ENABLED and frameCounter == 180 then
        Safe.Call(DebugPrintObjects)
    end

    if not HITBOX_ENABLED or HITBOX_SIZE <= 0 then return end
    local rootPart = GetRootPart()
    if not rootPart then return end
    -- Reutiliza 'ball' já obtido no início do frame
    if not ball then return end
    -- Modo conservador: sem pull da bola (só hitbox expandida)
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
            -- Pequena variação para não usar sempre os mesmos valores (menos assinatura)
            local pullDist = PULL_DISTANCE * (0.92 + math.random() * 0.16)
            local lerpSpeed = math.clamp(BALL_LERP_SPEED * (0.9 + math.random() * 0.25), 0.05, 0.5)
            local targetPos = playerPos + direction * pullDist
            local newPos = ball.Position:Lerp(targetPos, lerpSpeed)
            ball.CFrame = CFrame.new(newPos)
        end)
    end
end)
Cleanup.Register(hitboxConnection)

-- Reset ball cache on respawn; reaplica hitboxes do jogo se ainda estiver ON
Cleanup.Register(LocalPlayer.CharacterAdded:Connect(function()
    cachedBall = nil
    cachedHitboxesFolder = nil
    task.defer(function()
        task.wait(1)
        if not Cleanup._active then return end
        if HITBOX_ENABLED and HITBOX_SIZE > 0 then
            pcall(function() ApplyGameHitboxes(HITBOX_SIZE) end)
        end
    end)
end))

-- Reaplica hitboxes a cada ~2s quando ON (como era antes).
task.spawn(function()
    while Cleanup._active do
        local baseSec = (type(HITBOX_REAPPLY_BASE_SEC) == "number" and HITBOX_REAPPLY_BASE_SEC > 0) and HITBOX_REAPPLY_BASE_SEC or 2
        task.wait(baseSec + (math.random() * 0.5))
        if not Cleanup._active then break end
        if not Safe.IsValidGui() then break end
        if HITBOX_ENABLED and HITBOX_SIZE > 0 then
            local ok = pcall(function()
                if ApplyGameHitboxes(HITBOX_SIZE) then
                    InfoText.Text = "Hitboxes: OK (alcance " .. HITBOX_SIZE .. ")"
                else
                    InfoText.Text = "Entre numa partida para ativar hitbox"
                end
            end)
            if not ok and InfoText then
                InfoText.Text = "RightShift = GUI | H = Hitbox"
            end
        end
    end
end)

-- ═══════════════════════════════════════════════
-- OPENING ANIMATION (só depois do atraso anti-detecção)
-- ═══════════════════════════════════════════════
MainFrame.Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, 0)
MainFrame.BackgroundTransparency = 1

local waitRemaining = scriptStartTime - tick()
if waitRemaining > 0 then task.wait(waitRemaining) end

task.wait(0.1)

Tween(MainFrame, {BackgroundTransparency = 0}, 0.3)
Tween(MainFrame, {Size = UDim2.new(0, MAIN_WINDOW_WIDTH, 0, MAIN_WINDOW_HEIGHT)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════════
-- CLEANUP: restaura estado e desconecta tudo ao fechar
-- ═══════════════════════════════════════════════
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
    StarterGui:SetCore("SendNotification", {
        Title = "Volleyball Legends",
        Text = "Modo conservador ON. Risco de ban por sua conta.",
        Duration = 4
    })
end)

if DEBUG_ENABLED then
    print("[Henrydangerkk] Script carregado. Hitbox + ESP. Debug ativo.")
end
