-- Настройки сервера
local targetPlaceId = 16480898254 -- <--- ВСТАВЬ СЮДА ID ИГРЫ
local myShareCode = "ab79c82f009a0147a3f0ae768ef856d1" -- <--- ВСТАВЬ КОД ИЗ ССЫЛКИ (после code=)

-- Ожидание загрузки
repeat task.wait() until game:IsLoaded()

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local antiDCEnabled = false
local connection = nil

-- ===== СОЗДАНИЕ ИНТЕРФЕЙСА =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PrivateOnlyAntiDC"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 45)
button.Position = UDim2.new(0, 10, 0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Темно-красный (выкл)
button.Text = "Private DC Protection: OFF"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 13
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

-- Перетаскивание для iOS (Touch)
local dragging, dragStart, startPos
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
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
button.InputEnded:Connect(function() dragging = false end)

-- ===== ЛОГИКА ТОЛЬКО ПРИВАТНОГО ПЕРЕЗАХОДА =====
local function rejoinToPrivate()
    print("🔄 Обнаружен вылет! Пытаюсь вернуться на приватный сервер...")
    
    -- Цикл попыток, пока не получится зайти (на случай, если интернет еще не поднялся)
    while true do
        local success, err = pcall(function()
            -- Метод для входа по Share Code
            TeleportService:TeleportToPrivateServer(targetPlaceId, myShareCode, {player})
        end)
        
        if success then 
            print("✅ Запрос на телепорт отправлен.")
            break 
        else
            warn("❌ Ошибка входа на приватку: " .. tostring(err))
            task.wait(10) -- Ждем 10 секунд перед следующей попыткой
        end
    end
end

-- ===== ВКЛЮЧЕНИЕ / ВЫКЛЮЧЕНИЕ =====
button.MouseButton1Click:Connect(function()
    antiDCEnabled = not antiDCEnabled
    
    if antiDCEnabled then
        button.Text = "Private DC Protection: ON"
        button.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Темно-зеленый (вкл)
        
        -- Подключаем отслеживание ошибок
        connection = GuiService.ErrorMessageChanged:Connect(function()
            local msg = GuiService:GetErrorMessage()
            if msg ~= "" then
                rejoinToPrivate()
            end
        end)
        print("🛡️ Защита включена. Режим: Только Приватка.")
    else
        button.Text = "Private DC Protection: OFF"
        button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        print("🛡️ Защита выключена.")
    end
end)
