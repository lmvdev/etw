local targetPlaceId = 16480898254 -- ID игры
local myShareCode = "ab79c82f009a0147a3f0ae768ef856d1"   -- Код приватки

-- Ожидание загрузки
repeat task.wait() until game:IsLoaded()

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")
local player = game.Players.LocalPlayer

local active = false
local connections = {} -- Для хранения потоков защиты

-- ===== ФУНКЦИЯ ТЕЛЕПОРТА =====
local function forceRejoin()
    print("🚀 Сеть упала. Жду интернет и прыгаю на приватку...")
    while true do
        local success = pcall(function()
            TeleportService:TeleportToPrivateServer(targetPlaceId, myShareCode, {player})
        end)
        if success then break end
        task.wait(10)
    end
end

-- ===== ЛОГИКА ЗАЩИТЫ =====
local function startProtection()
    -- 1. Мониторинг ошибки на экране
    table.insert(connections, GuiService.ErrorMessageChanged:Connect(function()
        if GuiService:GetErrorMessage() ~= "" then forceRejoin() end
    end))

    -- 2. Мониторинг трафика (Data Reception)
    task.spawn(function()
        while active do
            task.wait(10)
            local bps = Stats.Network.ServerStatsItem["Data Reception"]:GetValue()
            if bps <= 0 then 
                print("📡 Трафик 0! Реджоин...")
                forceRejoin() 
            end
        end
    end)
    
    print("🛡️ Защита активирована")
end

local function stopProtection()
    active = false
    for _, conn in pairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    print("🛡️ Защита отключена")
end

-- ===== ИНТЕРФЕЙС (КНОПКА) =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltraAntiDC"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 10, 0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
button.Text = "Private Guard: OFF"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Parent = screenGui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

-- Перетаскивание для iOS
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

-- Переключатель
button.MouseButton1Click:Connect(function()
    active = not active
    if active then
        button.Text = "Private Guard: ON"
        button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        startProtection()
        
        -- СЮДА МОЖНО ВСТАВИТЬ ЗАПУСК ТВОЕГО АВТОФАРМА
        -- loadstring(game:HttpGet("..."))()
    else
        button.Text = "Private Guard: OFF"
        button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        stopProtection()
    end
end)
