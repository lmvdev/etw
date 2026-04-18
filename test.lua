-- Ждем загрузки
repeat task.wait() until game:IsLoaded()

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- СЮДА ВСТАВЬ КОД ИЗ ССЫЛКИ (то, что после code=)
local myShareCode = "ab79c82f009a0147a3f0ae768ef856d1" 

local antiDCEnabled = false
local connection = nil

-- ===== ИНТЕРФЕЙС =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PrivateAntiDC"
screenGui.Parent = game:GetService("CoreGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 180, 0, 45)
button.Position = UDim2.new(0, 10, 0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
button.Text = "Private Anti-DC: OFF"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.Parent = button

-- Функция перетаскивания (упрощенная для iOS)
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

-- ===== ЛОГИКА ТЕЛЕПОРТА НА ПРИВАТКУ =====
local function rejoinToPrivate()
    print("🚀 Попытка зайти на приватный сервер...")
    task.wait(3)
    
    -- Используем LinkCode для входа
    -- Примечание: В некоторых версиях API может потребоваться PlaceId
    local success, err = pcall(function()
        TeleportService:TeleportToPrivateServer(game.PlaceId, myShareCode, {player})
    end)
    
    if not success then
        warn("Ошибка входа на приватку: " .. tostring(err))
        -- Если не вышло на приватку, пробуем обычный реконект через 5 сек
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, player)
    end
end

-- ===== ВКЛ / ВЫКЛ =====
button.MouseButton1Click:Connect(function()
    antiDCEnabled = not antiDCEnabled
    
    if antiDCEnabled then
        button.Text = "Private Anti-DC: ON"
        button.BackgroundColor3 = Color3.fromRGB(30, 180, 30)
        
        connection = GuiService.ErrorMessageChanged:Connect(function()
            local msg = GuiService:GetErrorMessage()
            if msg ~= "" then
                rejoinToPrivate()
            end
        end)
    else
        button.Text = "Private Anti-DC: OFF"
        button.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        if connection then connection:Disconnect() end
    end
end)
