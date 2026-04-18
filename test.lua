local targetPlaceId = 16480898254 -- ID игры
local myShareCode = "ab79c82f009a0147a3f0ae768ef856d1"   -- Код приватки

repeat task.wait() until game:IsLoaded()

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local player = game.Players.LocalPlayer

-- Функция для телепорта
local function forceRejoin()
    print("🚀 Попытка аварийного переподключения...")
    -- Пытаемся телепортироваться бесконечно, пока не выйдет
    while true do
        local success, err = pcall(function()
            TeleportService:TeleportToPrivateServer(targetPlaceId, myShareCode, {player})
        end)
        if success then break end
        warn("Ожидание сети для телепорта...")
        task.wait(10) -- Ждем 10 сек перед новой попыткой
    end
end

-- МЕТОД 1: Окно ошибки (стандартный дисконнект)
GuiService.ErrorMessageChanged:Connect(function()
    if GuiService:GetErrorMessage() ~= "" then
        forceRejoin()
    end
end)

-- МЕТОД 2: Проверка "зависания" игры (если интернет мигнул, а окно не вылезло)
task.spawn(function()
    local lastTick = tick()
    while task.wait(5) do
        -- Если разница во времени между циклами стала слишком большой, 
        -- значит игра "фризила" или интернет пропадал
        if tick() - lastTick > 15 then 
            print("Обнаружен критический лаг сети, перезахожу...")
            forceRejoin()
        end
        lastTick = tick()
    end
end)

-- МЕТОД 3: Проверка связи с сервером через Stats
task.spawn(function()
    while task.wait(10) do
        -- Если входящий трафик равен 0 более 10 секунд
        local bps = game:GetService("Stats").Network.ServerStatsItem["Data Reception"]:GetValue()
        if bps <= 0 then
            print("Трафик 0. Потеря связи. Реджоин...")
            forceRejoin()
        end
    end
end)

-- ЗДЕСЬ ЗАПУСКАЙ СВОЙ ОСНОВНОЙ СКРИПТ (Автофарм)
print("Все системы защиты активны. Запускаю основной скрипт...")
-- loadstring(...)() 
