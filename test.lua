-- ETW No Visual Growth v8
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

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
_G.OriginalValues = {}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ETW_Helper"
screenGui.ResetOnSpawn = false
screenGui.Parent = coreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 180)
mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -10, 0, 40)
button.Position = UDim2.new(0, 5, 0, 5)
button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "🔒 LOCKED v8"
button.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = button

-- Дебаг панель
local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(1, -10, 0, 130)
debugLabel.Position = UDim2.new(0, 5, 0, 48)
debugLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
debugLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
debugLabel.Font = Enum.Font.Code
debugLabel.TextSize = 10
debugLabel.Text = "Scanning..."
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.TextYAlignment = Enum.TextYAlignment.Top
debugLabel.TextWrapped = true
debugLabel.Parent = mainFrame

local debugCorner = Instance.new("UICorner")
debugCorner.CornerRadius = UDim.new(0, 6)
debugCorner.Parent = debugLabel

-- Хранилище
local originalData = {
    attachments = {},
    motor6d = {},
    partSizes = {},
    values = {},
    hipHeight = nil
}

-- Сканирование ВСЕХ мест где могут быть значения
local function deepScan()
    local allValues = {}
    
    -- 1. Character
    local char = player.Character
    if char then
        for _, desc in pairs(char:GetDescendants()) do
            if desc:IsA("NumberValue") or desc:IsA("IntValue") or desc:IsA("StringValue") then
                table.insert(allValues, {obj = desc, location = "Char", name = desc.Name, value = desc.Value})
            end
        end
    end
    
    -- 2. Player
    for _, desc in pairs(player:GetChildren()) do
        if desc:IsA("NumberValue") or desc:IsA("IntValue") or desc:IsA("Folder") then
            if desc:IsA("Folder") then
                for _, child in pairs(desc:GetDescendants()) do
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        table.insert(allValues, {obj = child, location = "Player/" .. desc.Name, name = child.Name, value = child.Value})
                    end
                end
            else
                table.insert(allValues, {obj = desc, location = "Player", name = desc.Name, value = desc.Value})
            end
        end
    end
    
    -- 3. leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                table.insert(allValues, {obj = stat, location = "leaderstats", name = stat.Name, value = stat.Value})
            end
        end
    end
    
    -- 4. PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, desc in pairs(playerGui:GetDescendants()) do
            if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                table.insert(allValues, {obj = desc, location = "PlayerGui", name = desc.Name, value = desc.Value})
            end
        end
    end
    
    -- 5. ReplicatedStorage (общие данные)
    for _, desc in pairs(replicatedStorage:GetDescendants()) do
        if desc:IsA("NumberValue") or desc:IsA("IntValue") then
            local nameLower = string.lower(desc.Name)
            if string.find(nameLower, "size") or string.find(nameLower, "scale") or string.find(nameLower, "mass") then
                table.insert(allValues, {obj = desc, location = "Replicated", name = desc.Name, value = desc.Value})
            end
        end
    end
    
    return allValues
end

-- Сохранение оригинальных данных
local function saveOriginalData(char)
    originalData = {
        attachments = {},
        motor6d = {},
        partSizes = {},
        values = {},
        hipHeight = nil
    }
    
    local hum = char:FindFirstChildOfClass("Humanoid")
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
        
        if desc:IsA("NumberValue") or desc:IsA("IntValue") then
            originalData.values[desc] = desc.Value
        end
    end
    
    -- Сохраняем ВСЕ найденные значения
    local allVals = deepScan()
    for _, data in pairs(allVals) do
        _G.OriginalValues[data.obj] = data.value
    end
end

-- Восстановление данных
local function restoreAllData(char)
    if not char then return end
    if not _G.KeepSmall then return end
    
    for attachment, data in pairs(originalData.attachments) do
        if attachment and attachment.Parent then
            pcall(function()
                attachment.Position = data.Position
            end)
        end
    end
    
    for motor, data in pairs(originalData.motor6d) do
        if motor and motor.Parent then
            pcall(function()
                motor.C0 = data.C0
                motor.C1 = data.C1
            end)
        end
    end
    
    for part, size in pairs(originalData.partSizes) do
        if part and part.Parent then
            pcall(function()
                part.Size = size
            end)
        end
    end
end

-- Блокировка scale
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
        
        if originalData.hipHeight then
            hum.HipHeight = originalData.hipHeight
        end
    end
end

-- Блокировка ВСЕХ значений
local function blockAllValues()
    if not _G.KeepSmall then return end
    
    for obj, origValue in pairs(_G.OriginalValues) do
        if obj and obj.Parent then
            pcall(function()
                if obj.Value ~= origValue then
                    obj.Value = origValue
                end
            end)
        end
    end
end

-- Дебаг функция
local function updateDebug()
    local text = "=== ALL VALUES ===\n"
    local allVals = deepScan()
    local count = 0
    
    for _, data in pairs(allVals) do
        if count < 10 then
            local changed = ""
            if _G.OriginalValues[data.obj] and _G.OriginalValues[data.obj] ~= data.value then
                changed = " ⚠️"
            end
            text = text .. string.format("[%s] %s: %s%s\n", data.location, data.name, tostring(data.value), changed)
            count = count + 1
        end
    end
    
    debugLabel.Text = text
end

-- Главная функция
local function lockCharacter(char)
    if not char then return end
    
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    
    task.wait(0.5)
    forceAllScales(char)
    task.wait(0.3)
    saveOriginalData(char)
    
    print("✅ v8 Locked! Tracking " .. tostring(#_G.OriginalValues) .. " values")
end

-- Применяем
if player.Character then
    task.spawn(function()
        lockCharacter(player.Character)
    end)
end

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    lockCharacter(char)
end)

-- Циклы
runService.RenderStepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllData(char)
        blockAllValues()
    end
end)

runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllData(char)
        blockAllValues()
    end
end)

-- Дебаг обновление (реже чтобы не лагало)
task.spawn(function()
    while true do
        pcall(updateDebug)
        task.wait(0.5)
    end
end)

-- Быстрый цикл
task.spawn(function()
    while true do
        if _G.KeepSmall then
            blockAllValues()
        end
        task.wait()
    end
end)

-- Кнопка
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    
    if _G.KeepSmall then
        button.Text = "🔒 LOCKED v8"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        if player.Character then
            task.spawn(function()
                forceAllScales(player.Character)
                task.wait(0.3)
                saveOriginalData(player.Character)
            end)
        end
    else
        button.Text = "🔓 UNLOCKED v8"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
end)

print("✅ ETW v8 - Deep Value Scanner")
print("📊 Scanning: Character, Player, leaderstats, PlayerGui, ReplicatedStorage")
