-- ETW No Visual Growth - Fixed Version
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")

-- Удаление старого GUI
if coreGui:FindFirstChild("ETW_Helper") then
    coreGui:FindFirstChild("ETW_Helper"):Destroy()
end

_G.KeepSmall = true
_G.TargetScale = 1 -- Целевой размер

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ETW_Helper"
screenGui.ResetOnSpawn = false
screenGui.Parent = coreGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 130, 0, 45)
button.Position = UDim2.new(0.05, 0, 0.1, 0)
button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Text = "🔒 SIZE LOCKED"
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Функция блокировки одного scale
local function lockScale(scaleObj)
    if not scaleObj then return end
    
    -- Устанавливаем значение
    scaleObj.Value = _G.TargetScale
    
    -- Слушаем изменения и мгновенно откатываем
    scaleObj.Changed:Connect(function()
        if _G.KeepSmall and scaleObj.Value ~= _G.TargetScale then
            scaleObj.Value = _G.TargetScale
        end
    end)
end

-- Функция блокировки всех scales персонажа
local function lockCharacterScales(char)
    if not char then return end
    
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    
    local scaleNames = {
        "BodyHeightScale",
        "BodyWidthScale", 
        "BodyDepthScale",
        "HeadScale"
    }
    
    for _, name in ipairs(scaleNames) do
        local scale = hum:FindFirstChild(name)
        if scale then
            lockScale(scale)
        end
    end
    
    -- Следим за новыми scale объектами
    hum.ChildAdded:Connect(function(child)
        if child:IsA("NumberValue") and table.find(scaleNames, child.Name) then
            task.wait(0.1)
            lockScale(child)
        end
    end)
end

-- Применяем к текущему персонажу
if player.Character then
    lockCharacterScales(player.Character)
end

-- Применяем при респавне
player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    lockCharacterScales(char)
end)

-- Дополнительный цикл для надежности
runService.RenderStepped:Connect(function()
    if not _G.KeepSmall then return end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    for _, child in pairs(hum:GetChildren()) do
        if child:IsA("NumberValue") and child.Name:find("Scale") then
            if child.Value ~= _G.TargetScale then
                child.Value = _G.TargetScale
            end
        end
    end
end)

-- Второй цикл на Heartbeat (двойная защита)
runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    for _, child in pairs(hum:GetChildren()) do
        if child:IsA("NumberValue") and child.Name:find("Scale") then
            if child.Value ~= _G.TargetScale then
                child.Value = _G.TargetScale
            end
        end
    end
end)

-- Переключение режима
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    
    if _G.KeepSmall then
        button.Text = "🔒 SIZE LOCKED"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
    else
        button.Text = "🔓 UNLOCKED"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
end)

print("✅ ETW Fixed - Size Lock Active")
