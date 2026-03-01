-- ETW No Visual Growth v5
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
    jointOffsets = {},
    partSizes = {},
    meshScales = {}
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
button.Text = "🔒 LOCKED v5"
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Сохранение всех оригинальных данных
local function saveOriginalData(char)
    originalData = {
        attachments = {},
        motor6d = {},
        jointOffsets = {},
        partSizes = {},
        meshScales = {}
    }
    
    for _, desc in pairs(char:GetDescendants()) do
        -- Attachments
        if desc:IsA("Attachment") then
            originalData.attachments[desc] = {
                Position = desc.Position,
                CFrame = desc.CFrame
            }
        end
        
        -- Motor6D (соединения между частями тела)
        if desc:IsA("Motor6D") then
            originalData.motor6d[desc] = {
                C0 = desc.C0,
                C1 = desc.C1,
                Transform = desc.Transform
            }
        end
        
        -- JointInstance (другие типы соединений)
        if desc:IsA("JointInstance") then
            originalData.jointOffsets[desc] = {
                C0 = desc.C0,
                C1 = desc.C1
            }
        end
        
        -- Размеры частей
        if desc:IsA("BasePart") then
            originalData.partSizes[desc] = desc.Size
        end
        
        -- Mesh Scale
        if desc:IsA("SpecialMesh") or desc:IsA("FileMesh") then
            originalData.meshScales[desc] = desc.Scale
        end
    end
    
    print("📦 Saved original data for " .. tostring(#originalData.attachments) .. " attachments, " .. tostring(#originalData.motor6d) .. " motors")
end

-- Восстановление всех позиций
local function restoreAllPositions(char)
    if not char then return end
    if not _G.KeepSmall then return end
    
    -- Восстанавливаем Attachments
    for attachment, data in pairs(originalData.attachments) do
        if attachment and attachment.Parent then
            pcall(function()
                attachment.Position = data.Position
                attachment.CFrame = data.CFrame
            end)
        end
    end
    
    -- Восстанавливаем Motor6D
    for motor, data in pairs(originalData.motor6d) do
        if motor and motor.Parent then
            pcall(function()
                motor.C0 = data.C0
                motor.C1 = data.C1
            end)
        end
    end
    
    -- Восстанавливаем JointInstance
    for joint, data in pairs(originalData.jointOffsets) do
        if joint and joint.Parent then
            pcall(function()
                joint.C0 = data.C0
                joint.C1 = data.C1
            end)
        end
    end
    
    -- Восстанавливаем размеры частей
    for part, size in pairs(originalData.partSizes) do
        if part and part.Parent then
            pcall(function()
                part.Size = size
            end)
        end
    end
    
    -- Восстанавливаем Mesh Scale
    for mesh, scale in pairs(originalData.meshScales) do
        if mesh and mesh.Parent then
            pcall(function()
                mesh.Scale = scale
            end)
        end
    end
end

-- Блокировка всех scale значений
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

-- Установка listeners на изменения
local function setupListeners(char)
    for _, desc in pairs(char:GetDescendants()) do
        -- Listener для Attachments
        if desc:IsA("Attachment") then
            local conn = desc:GetPropertyChangedSignal("Position"):Connect(function()
                if _G.KeepSmall and originalData.attachments[desc] then
                    desc.Position = originalData.attachments[desc].Position
                end
            end)
            table.insert(_G.ETW_Connections, conn)
        end
        
        -- Listener для Motor6D
        if desc:IsA("Motor6D") then
            local conn1 = desc:GetPropertyChangedSignal("C0"):Connect(function()
                if _G.KeepSmall and originalData.motor6d[desc] then
                    desc.C0 = originalData.motor6d[desc].C0
                end
            end)
            local conn2 = desc:GetPropertyChangedSignal("C1"):Connect(function()
                if _G.KeepSmall and originalData.motor6d[desc] then
                    desc.C1 = originalData.motor6d[desc].C1
                end
            end)
            table.insert(_G.ETW_Connections, conn1)
            table.insert(_G.ETW_Connections, conn2)
        end
        
        -- Listener для BasePart Size
        if desc:IsA("BasePart") then
            local conn = desc:GetPropertyChangedSignal("Size"):Connect(function()
                if _G.KeepSmall and originalData.partSizes[desc] then
                    desc.Size = originalData.partSizes[desc]
                end
            end)
            table.insert(_G.ETW_Connections, conn)
        end
    end
    
    -- Listener для новых объектов
    local conn = char.DescendantAdded:Connect(function(desc)
        task.wait()
        if desc:IsA("Attachment") and not originalData.attachments[desc] then
            originalData.attachments[desc] = {
                Position = desc.Position,
                CFrame = desc.CFrame
            }
        end
        if desc:IsA("Motor6D") and not originalData.motor6d[desc] then
            originalData.motor6d[desc] = {
                C0 = desc.C0,
                C1 = desc.C1
            }
        end
    end)
    table.insert(_G.ETW_Connections, conn)
end

-- Главная функция блокировки
local function lockCharacter(char)
    if not char then return end
    
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    
    task.wait(0.5)
    
    -- Сначала устанавливаем scale = 1
    forceAllScales(char)
    
    task.wait(0.2)
    
    -- Сохраняем оригинальные данные
    saveOriginalData(char)
    
    -- Устанавливаем listeners
    setupListeners(char)
    
    print("✅ Character locked!")
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
        restoreAllPositions(char)
    end
end)
table.insert(_G.ETW_Connections, conn1)

-- Цикл 2: Heartbeat
local conn2 = runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllPositions(char)
    end
end)
table.insert(_G.ETW_Connections, conn2)

-- Цикл 3: Stepped
local conn3 = runService.Stepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllPositions(char)
    end
end)
table.insert(_G.ETW_Connections, conn3)

-- Цикл 4: Быстрый while loop
task.spawn(function()
    while true do
        if _G.KeepSmall then
            local char = player.Character
            if char then
                forceAllScales(char)
                restoreAllPositions(char)
            end
        end
        task.wait()
    end
end)

-- Переключение режима
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    
    if _G.KeepSmall then
        button.Text = "🔒 LOCKED v5"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        -- Пересохраняем данные
        if player.Character then
            task.spawn(function()
                forceAllScales(player.Character)
                task.wait(0.2)
                saveOriginalData(player.Character)
            end)
        end
    else
        button.Text = "🔓 UNLOCKED v5"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
end)

print("✅ ETW v5 - Motor6D + Attachment Lock")
print("📊 Blocking: Scales, Motor6D, Attachments, Part Sizes, Mesh Scales")
