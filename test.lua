-- ETW No Visual Growth with Enhanced GUI
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")

-- Удаление предыдущей версии GUI
if coreGui:FindFirstChild("ETW_Helper") then
    coreGui:FindFirstChild("ETW_Helper"):Destroy()
end

-- Переменная состояния
_G.KeepSmall = _G.KeepSmall or true

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ETW_Helper"
screenGui.ResetOnSpawn = false
screenGui.Parent = coreGui

-- Главная рамка
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 140, 0, 50)
mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Кнопка переключения
local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -10, 1, -10)
button.Position = UDim2.new(0, 5, 0, 5)
button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Text = "🔒 LOCKED"
button.BorderSizePixel = 0
button.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = button

-- Индикатор статуса
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 15)
statusLabel.Position = UDim2.new(0, 0, 1, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.Text = "Active"
statusLabel.Parent = mainFrame

-- Функция обновления UI
local function updateUI()
    if _G.KeepSmall then
        button.Text = "🔒 LOCKED"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        statusLabel.Text = "Size Locked"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        button.Text = "🔓 UNLOCKED"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        statusLabel.Text = "Normal Growth"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Анимация нажатия
local function animateButton()
    button:TweenSize(
        UDim2.new(1, -15, 1, -15),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.1,
        true,
        function()
            button:TweenSize(
                UDim2.new(1, -10, 1, -10),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true
            )
        end
    )
end

-- Переключение режима
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    animateButton()
    updateUI()
end)

-- Перетаскивание GUI
local dragging = false
local dragInput, mousePos, framePos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

runService.Heartbeat:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- Основной цикл контроля размера
local connection
connection = runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        local scales = {
            "BodyHeightScale",
            "BodyWidthScale",
            "BodyDepthScale",
            "HeadScale"
        }
        
        for _, scaleName in ipairs(scales) do
            local scale = hum:FindFirstChild(scaleName)
            if scale and scale:IsA("NumberValue") and scale.Value ~= 1 then
                scale.Value = 1
            end
        end
    end
end)

-- Обработка смерти персонажа
player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
end)

-- Инициализация UI
updateUI()

print("✅ ETW No Visual Growth GUI Loaded")
print("📌 Drag the GUI to move it")
print("🔄 Click to toggle size lock")
