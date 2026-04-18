-- Ждем загрузки
repeat task.wait() until game:IsLoaded()

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Состояние: включен ли Anti-Disconnect
local antiDCEnabled = false
local connection = nil

-- ===== СОЗДАНИЕ ИНТЕРФЕЙСА =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiDCGui"
screenGui.ResetOnSpawn = false

-- Используем syn.protect_gui если доступен (защита от game:FindFirstChild)
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = game:GetService("CoreGui")
else
    screenGui.Parent = game:GetService("CoreGui")
end

-- Кнопка
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 45)
button.Position = UDim2.new(0, 10, 0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "Anti-DC: OFF"
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.Parent = screenGui

-- Скругление углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Прозрачность фона
button.BackgroundTransparency = 0.2

-- Делаем кнопку перетаскиваемой
local dragging = false
local dragStart, startPos

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
    end
end)

button.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

button.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ===== ФУНКЦИЯ ПЕРЕЗАХОДА =====
local function rejoin()
    task.wait(5)
    TeleportService:Teleport(game.PlaceId, player)
end

-- ===== ВКЛЮЧЕНИЕ / ВЫКЛЮЧЕНИЕ =====
local function enableAntiDC()
    antiDCEnabled = true
    button.Text = "Anti-DC: ON"
    button.BackgroundColor3 = Color3.fromRGB(30, 180, 30)

    connection = GuiService.ErrorMessageChanged:Connect(function()
        local msg = GuiService:GetErrorMessage()
        if msg ~= "" then
            print("⚠️ Ошибка сети: " .. msg)
            print("🔄 Перезаход через 5 секунд...")
            rejoin()
        end
    end)

    print("✅ Anti-Disconnect включен")
end

local function disableAntiDC()
    antiDCEnabled = false
    button.Text = "Anti-DC: OFF"
    button.BackgroundColor3 = Color3.fromRGB(180, 30, 30)

    if connection then
        connection:Disconnect()
        connection = nil
    end

    print("❌ Anti-Disconnect выключен")
end

-- ===== ОБРАБОТКА НАЖАТИЯ =====
button.MouseButton1Click:Connect(function()
    if antiDCEnabled then
        disableAntiDC()
    else
        enableAntiDC()
    end
end)

print("🛡️ Anti-DC скрипт загружен. Нажми кнопку для включения.")
