-- ETW No Visual Growth v7
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

-- Хранилище оригинальных данных
local originalData = {
    attachments = {},
    motor6d = {},
    partSizes = {},
    meshScales = {},
    values = {},
    rootY = nil,
    hipHeight = nil
}

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
button.Text = "🔒 LOCKED v7"
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Дебаг лейбл
local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(0, 200, 0, 60)
debugLabel.Position = UDim2.new(0.05, 0, 0.18, 0)
debugLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
debugLabel.BackgroundTransparency = 0.3
debugLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
debugLabel.Font = Enum.Font.Code
debugLabel.TextSize = 12
debugLabel.Text = "Debug: Loading..."
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.Parent = screenGui

local debugCorner = Instance.new("UICorner")
debugCorner.CornerRadius = UDim.new(0, 6)
debugCorner.Parent = debugLabel

-- Сохранение оригинальных данных
local function saveOriginalData(char)
    originalData = {
        attachments = {},
        motor6d = {},
        partSizes = {},
        meshScales = {},
        values = {},
        rootY = nil,
        hipHeight = nil
    }
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    -- Сохраняем Y позицию и HipHeight
    if root then
        originalData.rootY = root.Position.Y
    end
    
    if hum then
        originalData.hipHeight = hum.HipHeight
    end
    
    for _, desc in pairs(char:GetDescendants()) do
        if desc:IsA("Attachment") then
            originalData.attachments[desc] = {
                Position = desc.Position,
                CFrame = desc.CFrame
            }
        end
        
        if desc:IsA("Motor6D") then
            originalData.motor6d[desc] = {
                C0 = desc.C0,
                C1 = desc.C1
            }
        end
        
        if desc:IsA("BasePart") then
            originalData.partSizes[desc] = desc.Size
        end
        
        if desc:IsA("SpecialMesh") or desc:IsA("FileMesh") then
            originalData.meshScales[desc] = desc.Scale
        end
        
        if desc:IsA("NumberValue") or desc:IsA("IntValue") then
            originalData.values[desc] = desc.Value
        end
    end
end

-- Блокировка высоты персонажа
local function lockHeight(char)
    if not char then return end
    if not _G.KeepSmall then return end
    if not originalData.rootY then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if hum and originalData.hipHeight then
        hum.HipHeight = originalData.hipHeight
    end
    
    -- Корректируем Y позицию если персонаж слишком высоко
    if root then
        local currentY = root.Position.Y
        local maxAllowedY = originalData.rootY + 2 -- Допускаем прыжок до 2 studs
        
        if currentY > maxAllowedY and hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
            root.CFrame = CFrame.new(root.Position.X, originalData.rootY, root.Position.Z) * CFrame.Angles(root.CFrame:ToEulerAnglesXYZ())
        end
    end
end

-- Восстановление всех данных
local function restoreAllData(char)
    if not char then return end
    if not _G.KeepSmall then return end
    
    -- Attachments
    for attachment, data in pairs(originalData.attachments) do
        if attachment and attachment.Parent then
            pcall(function()
                attachment.Position = data.Position
                attachment.CFrame = data.CFrame
            end)
        end
    end
    
    -- Motor6D
    for motor, data in pairs(originalData.motor6d) do
        if motor and motor.Parent then
            pcall(function()
                motor.C0 = data.C0
                motor.C1 = data.C1
            end)
        end
    end
    
    -- Размеры частей
    for part, size in pairs(originalData.partSizes) do
        if part and part.Parent then
            pcall(function()
                part.Size = size
            end)
        end
    end
    
    -- Mesh Scale
    for mesh, scale in pairs(originalData.meshScales) do
        if mesh and mesh.Parent then
            pcall(function()
                mesh.Scale = scale
            end)
        end
    end
    
    -- Values
    for val, value in pairs(originalData.values) do
        if val and val.Parent then
            pcall(function()
                val.Value = value
            end)
        end
    end
end

-- Блокировка всех scale
local function forceAllScales(char)
    if not char then return end
    if not _G.KeepSmall then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, child in pairs(hum:GetChildren()) do
            if child:IsA("NumberValue") then
                child.Value = _G.TargetScale
            end
        end
        
        -- HipHeight блокировка
        if originalData.hipHeight then
            hum.HipHeight = originalData.hipHeight
        end
        
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

-- Поиск и отображение всех подозрительных значений
local function debugValues(char)
    local debugText = "=== DEBUG v7 ===\n"
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        debugText = debugText .. "HipHeight: " .. string.format("%.2f", hum.HipHeight) .. "\n"
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        debugText = debugText .. "Y Pos: " .. string.format("%.2f", root.Position.Y) .. "\n"
    end
    
    -- Ищем любые значения с "size", "range", "scale" в названии
    local found = {}
    for _, desc in pairs(char:GetDescendants()) do
        if (desc:IsA("NumberValue") or desc:IsA("IntValue")) then
            local nameLower = string.lower(desc.Name)
            if string.find(nameLower, "size") or 
               string.find(nameLower, "range") or 
               string.find(nameLower, "scale") or
               string.find(nameLower, "radius") or
               string.find(nameLower, "collect") or
               string.find(nameLower, "pickup") then
                table.insert(found, desc.Name .. ": " .. tostring(desc.Value))
            end
        end
    end
    
    -- Проверяем player тоже
    for _, desc in pairs(player:GetDescendants()) do
        if (desc:IsA("NumberValue") or desc:IsA("IntValue")) and desc:IsDescendantOf(player) then
            local nameLower = string.lower(desc.Name)
            if string.find(nameLower, "size") or 
               string.find(nameLower, "range") or 
               string.find(nameLower, "scale") then
                table.insert(found, "[P]" .. desc.Name .. ": " .. tostring(desc.Value))
            end
        end
    end
    
    for i, v in ipairs(found) do
        if i <= 3 then
            debugText = debugText .. v .. "\n"
        end
    end
    
    debugLabel.Text = debugText
end

-- Главная функция блокировки
local function lockCharacter(char)
    if not char then return end
    
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    
    task.wait(0.5)
    
    -- Устанавливаем scale = 1
    forceAllScales(char)
    
    task.wait(0.3)
    
    -- Сохраняем данные
    saveOriginalData(char)
    
    print("✅ Saved! RootY: " .. tostring(originalData.rootY) .. " HipHeight: " .. tostring(originalData.hipHeight))
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

-- АГРЕССИВНЫЕ ЦИКЛЫ

-- Цикл 1: RenderStepped
local conn1 = runService.RenderStepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllData(char)
        lockHeight(char)
    end
end)
table.insert(_G.ETW_Connections, conn1)

-- Цикл 2: Heartbeat
local conn2 = runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllData(char)
        lockHeight(char)
        debugValues(char)
    end
end)
table.insert(_G.ETW_Connections, conn2)

-- Цикл 3: Stepped
local conn3 = runService.Stepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllData(char)
        lockHeight(char)
    end
end)
table.insert(_G.ETW_Connections, conn3)

-- Цикл 4: While loop
task.spawn(function()
    while true do
        if _G.KeepSmall then
            local char = player.Character
            if char then
                forceAllScales(char)
                restoreAllData(char)
                lockHeight(char)
            end
        end
        task.wait()
    end
end)

-- Переключение режима
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    
    if _G.KeepSmall then
        button.Text = "🔒 LOCKED v7"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        if player.Character then
            task.spawn(function()
                forceAllScales(player.Character)
                task.wait(0.3)
                saveOriginalData(player.Character)
            end)
        end
    else
        button.Text = "🔓 UNLOCKED v7"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
end)

print("✅ ETW v7 - Height Lock + Debug Panel")
print("📊 Blocking: Scales, Motor6D, Attachments, HipHeight, Y Position")
