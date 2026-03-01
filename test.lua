-- ETW No Visual Growth v4
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")

-- Полная очистка
if coreGui:FindFirstChild("ETW_Helper") then
    coreGui:FindFirstChild("ETW_Helper"):Destroy()
end

if _G.ETW_Connections then
    for _, conn in pairs(_G.ETW_Connections) do
        pcall(function() conn:Disconnect() end)
    end
end

_G.KeepSmall = true
_G.TargetScale = 1
_G.ETW_Connections = {}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ETW_Helper"
screenGui.ResetOnSpawn = false
screenGui.Parent = coreGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 50)
button.Position = UDim2.new(0.05, 0, 0.1, 0)
button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "🔒 LOCKED v4"
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Сохраняем оригинальные размеры частей тела
local originalSizes = {}
local originalScales = {}

local function saveOriginalSizes(char)
    originalSizes = {}
    originalScales = {}
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            originalSizes[part] = part.Size
        end
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, child in pairs(hum:GetChildren()) do
            if child:IsA("NumberValue") then
                originalScales[child.Name] = child.Value
            end
        end
    end
end

-- Принудительная установка ВСЕХ размеров
local function forceAllScales(char)
    if not char then return end
    if not _G.KeepSmall then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        -- Все NumberValue в Humanoid
        for _, child in pairs(hum:GetChildren()) do
            if child:IsA("NumberValue") then
                child.Value = _G.TargetScale
            end
        end
        
        -- HumanoidDescription
        local desc = hum:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            pcall(function()
                desc.HeightScale = _G.TargetScale
                desc.WidthScale = _G.TargetScale
                desc.DepthScale = _G.TargetScale
                desc.HeadScale = _G.TargetScale
                desc.BodyTypeScale = _G.TargetScale
                desc.ProportionScale = _G.TargetScale
            end)
        end
    end
end

-- Принудительная установка размеров частей тела
local function forcePartSizes(char)
    if not char then return end
    if not _G.KeepSmall then return end
    
    for part, size in pairs(originalSizes) do
        if part and part.Parent then
            pcall(function()
                part.Size = size
            end)
        end
    end
end

-- Блокировка роста через Motor6D и Attachments
local function lockAttachments(char)
    if not char then return end
    
    for _, desc in pairs(char:GetDescendants()) do
        if desc:IsA("Attachment") then
            local originalPos = desc.Position
            local conn = desc:GetPropertyChangedSignal("Position"):Connect(function()
                if _G.KeepSmall then
                    desc.Position = originalPos
                end
            end)
            table.insert(_G.ETW_Connections, conn)
        end
    end
end

-- Главная функция блокировки персонажа
local function lockCharacter(char)
    if not char then return end
    
    -- Ждем полной загрузки
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    
    task.wait(0.5)
    
    -- Сохраняем оригинальные размеры
    saveOriginalSizes(char)
    
    -- Устанавливаем scale = 1
    forceAllScales(char)
    
    -- Блокируем attachments
    lockAttachments(char)
    
    -- Слушаем изменения в Humanoid
    local conn = hum.ChildAdded:Connect(function(child)
        task.wait()
        if _G.KeepSmall and child:IsA("NumberValue") then
            child.Value = _G.TargetScale
        end
    end)
    table.insert(_G.ETW_Connections, conn)
    
    -- Слушаем каждый scale отдельно
    for _, child in pairs(hum:GetChildren()) do
        if child:IsA("NumberValue") then
            local conn2 = child.Changed:Connect(function()
                if _G.KeepSmall then
                    child.Value = _G.TargetScale
                end
            end)
            table.insert(_G.ETW_Connections, conn2)
        end
    end
    
    -- Слушаем изменения размеров частей
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local conn3 = part:GetPropertyChangedSignal("Size"):Connect(function()
                if _G.KeepSmall and originalSizes[part] then
                    part.Size = originalSizes[part]
                end
            end)
            table.insert(_G.ETW_Connections, conn3)
        end
    end
end

-- Применяем к текущему персонажу
if player.Character then
    task.spawn(function()
        lockCharacter(player.Character)
    end)
end

-- При респавне
local charConn = player.CharacterAdded:Connect(function(char)
    task.wait(1)
    lockCharacter(char)
end)
table.insert(_G.ETW_Connections, charConn)

-- МАКСИМАЛЬНО АГРЕССИВНЫЕ ЦИКЛЫ

-- Цикл 1: RenderStepped
local conn1 = runService.RenderStepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
    end
end)
table.insert(_G.ETW_Connections, conn1)

-- Цикл 2: Heartbeat
local conn2 = runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
    end
end)
table.insert(_G.ETW_Connections, conn2)

-- Цикл 3: Stepped
local conn3 = runService.Stepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
    end
end)
table.insert(_G.ETW_Connections, conn3)

-- Цикл 4: While loop для размеров частей
task.spawn(function()
    while true do
        if _G.KeepSmall then
            local char = player.Character
            if char then
                forceAllScales(char)
                forcePartSizes(char)
            end
        end
        task.wait(0.016) -- ~60fps
    end
end)

-- Цикл 5: Быстрый while loop
task.spawn(function()
    while true do
        if _G.KeepSmall then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    for _, child in pairs(hum:GetChildren()) do
                        if child:IsA("NumberValue") then
                            child.Value = _G.TargetScale
                        end
                    end
                end
            end
        end
        task.wait()
    end
end)

-- Переключение режима
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    
    if _G.KeepSmall then
        button.Text = "🔒 LOCKED v4"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        -- Пересохраняем размеры при включении
        if player.Character then
            saveOriginalSizes(player.Character)
        end
    else
        button.Text = "🔓 UNLOCKED v4"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
end)

print("✅ ETW v4 - Ultra Force Lock")
print("📊 5 parallel loops + Part Size Lock + Attachment Lock")
