-- ETW No Visual Growth with GUI
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")

-- Переменная состояния
_G.KeepSmall = true

-- Создание простого интерфейса
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ETW_Helper"
screenGui.Parent = coreGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 120, 0, 40)
button.Position = UDim2.new(0.05, 0, 0.1, 0) -- Слева вверху
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.Text = "Mode: SMALL"
button.Parent = screenGui

-- Скругление углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Функция переключения
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    if _G.KeepSmall then
        button.Text = "Mode: SMALL"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40) -- Зеленый
    else
        button.Text = "Mode: NORMAL"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40) -- Красный
    end
end)

-- Основной цикл заморозки размера
runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        local scales = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}
        
        for _, name in ipairs(scales) do
            local s = hum:FindFirstChild(name)
            if s and s.Value ~= 1 then
                s.Value = 1
            end
        end
    end
end)

print("ETW GUI Loaded: Use the button to toggle visual size.")
