-- ETW No Visual Growth v3
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")

-- Удаление старого GUI
if coreGui:FindFirstChild("ETW_Helper") then
    coreGui:FindFirstChild("ETW_Helper"):Destroy()
end

-- Отключаем старые соединения
if _G.ETW_Connections then
    for _, conn in pairs(_G.ETW_Connections) do
        if conn then conn:Disconnect() end
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
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.05, 0, 0.1, 0)
button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "🔒 LOCKED v3"
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Принудительная установка размера
local function forceScale(hum)
    if not hum then return end
    
    -- Все возможные названия scale
    local scaleNames = {
        "BodyHeightScale",
        "BodyWidthScale", 
        "BodyDepthScale",
        "HeadScale",
        "BodyTypeScale",
        "BodyProportionScale"
    }
    
    for _, name in ipairs(scaleNames) do
        local scale = hum:FindFirstChild(name)
        if scale and scale:IsA("NumberValue") then
            scale.Value = _G.TargetScale
        end
    end
    
    -- Также ищем любые другие Scale объекты
    for _, child in pairs(hum:GetChildren()) do
        if child:IsA("NumberValue") and string.find(child.Name, "Scale") then
            child.Value = _G.TargetScale
        end
    end
end

-- Блокировка через properties напрямую
local function lockCharacter(char)
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then 
        hum = char:WaitForChild("Humanoid", 10)
    end
    if not hum then return end
    
    -- Мгновенная установка
    forceScale(hum)
    
    -- Слушаем изменения каждого scale
    for _, child in pairs(hum:GetChildren()) do
        if child:IsA("NumberValue") and string.find(child.Name, "Scale") then
            local conn = child:GetPropertyChangedSignal("Value"):Connect(function()
                if _G.KeepSmall then
                    child.Value = _G.TargetScale
                end
            end)
            table.insert(_G.ETW_Connections, conn)
        end
    end
    
    -- Слушаем новые scale объекты
    local conn = hum.ChildAdded:Connect(function(child)
        if child:IsA("NumberValue") and string.find(child.Name, "Scale") then
            task.wait()
            if _G.KeepSmall then
                child.Value = _G.TargetScale
            end
            local conn2 = child:GetPropertyChangedSignal("Value"):Connect(function()
                if _G.KeepSmall then
                    child.Value = _G.TargetScale
                end
            end)
            table.insert(_G.ETW_Connections, conn2)
        end
    end)
    table.insert(_G.ETW_Connections, conn)
end

-- Блокировка HumanoidDescription (некоторые игры используют это)
local function blockHumanoidDescription(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local function resetDescription()
        if not _G.KeepSmall then return end
        local desc = hum:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            desc.HeightScale = _G.TargetScale
            desc.WidthScale = _G.TargetScale
            desc.DepthScale = _G.TargetScale
            desc.HeadScale = _G.TargetScale
            desc.BodyTypeScale = _G.TargetScale
            desc.ProportionScale = _G.TargetScale
        end
    end
    
    local conn = hum.ChildAdded:Connect(function(child)
        if child:IsA("HumanoidDescription") then
            task.wait()
            resetDescription()
        end
    end)
    table.insert(_G.ETW_Connections, conn)
    
    resetDescription()
end

-- Применяем к текущему персонажу
if player.Character then
    lockCharacter(player.Character)
    blockHumanoidDescription(player.Character)
end

-- При респавне
local charConn = player.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    lockCharacter(char)
    blockHumanoidDescription(char)
end)
table.insert(_G.ETW_Connections, charConn)

-- Агрессивный цикл #1 - RenderStepped (каждый кадр до рендера)
local conn1 = runService.RenderStepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then forceScale(hum) end
    end
end)
table.insert(_G.ETW_Connections, conn1)

-- Агрессивный цикл #2 - Heartbeat
local conn2 = runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then forceScale(hum) end
    end
end)
table.insert(_G.ETW_Connections, conn2)

-- Агрессивный цикл #3 - Stepped
local conn3 = runService.Stepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then forceScale(hum) end
    end
end)
table.insert(_G.ETW_Connections, conn3)

-- Дополнительный while loop
task.spawn(function()
    while task.wait(0.01) do
        if _G.KeepSmall then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then forceScale(hum) end
            end
        end
    end
end)

-- Переключение режима
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    
    if _G.KeepSmall then
        button.Text = "🔒 LOCKED v3"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
    else
        button.Text = "🔓 UNLOCKED v3"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
end)

print("✅ ETW v3 - Maximum Force Lock Active")
print("📊 Running 4 parallel loops")
