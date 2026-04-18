-- === НАСТРОЙКИ ===
local targetPlaceId = 16480898254
local myShareCode = "ab79c82f009a0147a3f0ae768ef856d1"

repeat task.wait() until game:IsLoaded()

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local player = game.Players.LocalPlayer

local active = false
local connections = {}

-- ===== ФУНКЦИЯ УВЕДОМЛЕНИЙ =====
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Guard",
            Text = text or "",
            Duration = duration or 5
        })
    end)
    print("[Guard] " .. tostring(title) .. ": " .. tostring(text))
end

-- ===== ФУНКЦИЯ ТЕЛЕПОРТА =====
local function forceRejoin()
    notify("⚠️ Disconnect", "Обнаружен разрыв соединения!", 10)
    task.wait(2)

    local attempt = 0
    while true do
        attempt = attempt + 1
        notify("🔄 Попытка #" .. attempt, "Пытаюсь зайти на приватку...", 5)

        local success, err = pcall(function()
            TeleportService:TeleportToPrivateServer(targetPlaceId, myShareCode, {player})
        end)

        if success then
            notify("✅ Телепорт", "Запрос отправлен! Ждём перехода...", 10)
            task.wait(15)
            -- Если мы всё ещё здесь через 15 сек, значит телепорт не сработал
            notify("❌ Телепорт", "Переход не произошёл. Пробую снова...", 5)
        else
            notify("❌ Ошибка", tostring(err), 5)
        end

        task.wait(10)
    end
end

-- ===== ЛОГИКА ЗАЩИТЫ =====
local function startProtection()
    -- 1. Мониторинг ошибки на экране
    local conn = GuiService.ErrorMessageChanged:Connect(function()
        local msg = GuiService:GetErrorMessage()
        if msg ~= "" then
            notify("🔴 GuiService", "Ошибка: " .. msg, 10)
            forceRejoin()
        end
    end)
    table.insert(connections, conn)
    notify("✅ Метод 1", "GuiService.ErrorMessageChanged подключён", 3)

    -- 2. Мониторинг трафика
    -- 2. Мониторинг трафика (Data Reception)
    task.spawn(function()
        local zeroCount = 0
        while active do
            task.wait(5)

            local success, bps = pcall(function()
                -- Пытаемся достать значение более безопасным путем
                local serverStats = Stats.Network:FindFirstChild("ServerStatsItem")
                if serverStats then
                    local dataRec = serverStats:FindFirstChild("Data Reception")
                    if dataRec then
                        return dataRec:GetValue()
                    end
                end
                return -1 -- Если не нашли путь, возвращаем -1
            end)

            if success and bps ~= -1 then
                if bps <= 0 then
                    zeroCount = zeroCount + 1
                    notify("📡 Трафик", "Связь потеряна (0 BPS) - Проверка " .. zeroCount .. "/3", 3)
                    if zeroCount >= 3 then
                        notify("📡 Трафик", "Перезахожу...", 5)
                        forceRejoin()
                    end
                else
                    zeroCount = 0
                end
            elseif bps == -1 then
                -- Если путь не найден, используем альтернативный счетчик пинга
                local ping = player:GetNetworkPing() * 1000
                if ping <= 0 or ping > 15000 then -- Если пинг 0 или больше 15 сек
                    zeroCount = zeroCount + 1
                    notify("📡 Пинг", "Проблема со связью! (" .. math.floor(ping) .. "ms)", 3)
                    if zeroCount >= 4 then forceRejoin() end
                else
                    zeroCount = 0
                end
            end
        end
    end)
    notify("✅ Метод 2", "Мониторинг трафика запущен", 3)

    -- 3. Мониторинг фриза
    task.spawn(function()
        local lastTick = tick()
        while active do
            task.wait(5)
            local gap = tick() - lastTick
            if gap > 20 then
                notify("🥶 Фриз", "Игра зависала " .. math.floor(gap) .. " сек. Реджоин!", 5)
                forceRejoin()
            end
            lastTick = tick()
        end
    end)
    notify("✅ Метод 3", "Мониторинг фризов запущен", 3)
end

local function stopProtection()
    active = false
    for _, conn in pairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    notify("🛑 Guard", "Все системы защиты отключены", 3)
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

-- Перетаскивание
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

        notify("🟢 Guard", "Защита включается...", 3)
        notify("ℹ️ Настройки", "PlaceId: " .. targetPlaceId, 3)
        notify("ℹ️ Настройки", "ShareCode: " .. myShareCode, 3)
        notify("ℹ️ Текущий PlaceId", tostring(game.PlaceId), 3)

        startProtection()
    else
        button.Text = "Private Guard: OFF"
        button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        stopProtection()
    end
end)

notify("🛡️ Guard", "Скрипт загружен. Нажми кнопку.", 5)
