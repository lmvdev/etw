-- ETW No Visual Growth v9 - Remote Intercept
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Очистка
if coreGui:FindFirstChild("ETW_Helper") then
    coreGui:FindFirstChild("ETW_Helper"):Destroy()
end

if _G.ETW_Connections then
    for _, conn in pairs(_G.ETW_Connections) do
        pcall(function() conn:Disconnect() end)
    end
end

_G.KeepSmall = true
_G.TargetScale = 1
_G.ETW_Connections = {}
_G.OriginalValues = {}
_G.SpooledSize = 1

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ETW_Helper"
screenGui.ResetOnSpawn = false
screenGui.Parent = coreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 220)
mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -10, 0, 40)
button.Position = UDim2.new(0, 5, 0, 5)
button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "🔒 LOCKED v9"
button.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = button

-- Дебаг панель для Remote Events
local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(1, -10, 0, 170)
debugLabel.Position = UDim2.new(0, 5, 0, 48)
debugLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
debugLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
debugLabel.Font = Enum.Font.Code
debugLabel.TextSize = 9
debugLabel.Text = "Scanning Remotes..."
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.TextYAlignment = Enum.TextYAlignment.Top
debugLabel.TextWrapped = true
debugLabel.Parent = mainFrame

local debugCorner = Instance.new("UICorner")
debugCorner.CornerRadius = UDim.new(0, 6)
debugCorner.Parent = debugLabel

-- Хранилище
local originalData = {
    attachments = {},
    motor6d = {},
    partSizes = {},
    hipHeight = nil
}

local remoteLog = {}

-- Хук на RemoteEvent для логирования
local function hookRemotes()
    local text = "=== REMOTES FOUND ===\n"
    local count = 0
    
    -- Сканируем ReplicatedStorage
    for _, obj in pairs(replicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            count = count + 1
            local remoteName = obj.Name
            text = text .. remoteName .. "\n"
            
            -- Пытаемся хукнуть
            if obj:IsA("RemoteEvent") then
                local oldFire = nil
                
                pcall(function()
                    local mt = getrawmetatable(game)
                    if mt then
                        local oldNamecall = mt.__namecall
                        setreadonly(mt, false)
                        
                        mt.__namecall = newcclosure(function(self, ...)
                            local method = getnamecallmethod()
                            local args = {...}
                            
                            if self == obj and method == "FireServer" then
                                -- Логируем
                                table.insert(remoteLog, {
                                    name = remoteName,
                                    args = args,
                                    time = tick()
                                })
                                
                                -- Если это связано с размером - подменяем
                                if _G.KeepSmall then
                                    for i, arg in pairs(args) do
                                        if type(arg) == "number" and arg > 1 and arg < 1000 then
                                            args[i] = _G.SpooledSize
                                        end
                                    end
                                end
                                
                                return oldNamecall(self, unpack(args))
                            end
                            
                            return oldNamecall(self, ...)
                        end)
                        
                        setreadonly(mt, true)
                    end
                end)
            end
        end
    end
    
    text = text .. "\nTotal: " .. count .. " remotes"
    return text
end

-- Сохранение оригинальных данных
local function saveOriginalData(char)
    originalData = {
        attachments = {},
        motor6d = {},
        partSizes = {},
        hipHeight = nil
    }
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        originalData.hipHeight = hum.HipHeight
    end
    
    for _, desc in pairs(char:GetDescendants()) do
        if desc:IsA("Attachment") then
            originalData.attachments[desc] = desc.Position
        end
        
        if desc:IsA("Motor6D") then
            originalData.motor6d[desc] = {C0 = desc.C0, C1 = desc.C1}
        end
        
        if desc:IsA("BasePart") then
            originalData.partSizes[desc] = desc.Size
        end
    end
end

-- Восстановление
local function restoreAllData(char)
    if not char or not _G.KeepSmall then return end
    
    for att, pos in pairs(originalData.attachments) do
        if att and att.Parent then
            pcall(function() att.Position = pos end)
        end
    end
    
    for motor, data in pairs(originalData.motor6d) do
        if motor and motor.Parent then
            pcall(function()
                motor.C0 = data.C0
                motor.C1 = data.C1
            end)
        end
    end
    
    for part, size in pairs(originalData.partSizes) do
        if part and part.Parent then
            pcall(function() part.Size = size end)
        end
    end
end

-- Блокировка scale
local function forceAllScales(char)
    if not char or not _G.KeepSmall then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, child in pairs(hum:GetChildren()) do
            if child:IsA("NumberValue") then
                child.Value = _G.TargetScale
            end
        end
        
        if originalData.hipHeight then
            hum.HipHeight = originalData.hipHeight
        end
    end
end

-- Обновление дебага
local function updateDebug()
    local text = "=== REMOTE LOG (last 5) ===\n"
    
    -- Показываем последние вызовы
    local startIdx = math.max(1, #remoteLog - 4)
    for i = startIdx, #remoteLog do
        local log = remoteLog[i]
        if log then
            local argsStr = ""
            for _, arg in pairs(log.args) do
                argsStr = argsStr .. tostring(arg) .. ", "
            end
            text = text .. string.format("%s(%s)\n", log.name, argsStr)
        end
    end
    
    if #remoteLog == 0 then
        text = text .. "(no calls yet)\n"
    end
    
    text = text .. "\n=== STATUS ===\n"
    text = text .. "Lock: " .. tostring(_G.KeepSmall) .. "\n"
    text = text .. "Spoof Size: " .. tostring(_G.SpooledSize) .. "\n"
    
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local heightScale = hum:FindFirstChild("BodyHeightScale")
            if heightScale then
                text = text .. "HeightScale: " .. tostring(heightScale.Value) .. "\n"
            end
        end
    end
    
    debugLabel.Text = text
end

-- Главная функция
local function lockCharacter(char)
    if not char then return end
    
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    
    task.wait(0.5)
    forceAllScales(char)
    task.wait(0.3)
    saveOriginalData(char)
end

-- Хукаем remotes при старте
task.spawn(function()
    task.wait(1)
    local result = hookRemotes()
    print(result)
end)

-- Применяем
if player.Character then
    task.spawn(function()
        lockCharacter(player.Character)
    end)
end

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    lockCharacter(char)
end)

-- Циклы
runService.RenderStepped:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllData(char)
    end
end)

runService.Heartbeat:Connect(function()
    if not _G.KeepSmall then return end
    local char = player.Character
    if char then
        forceAllScales(char)
        restoreAllData(char)
    end
end)

-- Дебаг обновление
task.spawn(function()
    while true do
        pcall(updateDebug)
        task.wait(0.3)
    end
end)

-- Кнопка
button.MouseButton1Click:Connect(function()
    _G.KeepSmall = not _G.KeepSmall
    
    if _G.KeepSmall then
        button.Text = "🔒 LOCKED v9"
        button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        if player.Character then
            task.spawn(function()
                forceAllScales(player.Character)
                task.wait(0.3)
                saveOriginalData(player.Character)
            end)
        end
    else
        button.Text = "🔓 UNLOCKED v9"
        button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
end)

print("✅ ETW v9 - Remote Interceptor")
print("📊 Logging all RemoteEvent calls")
print("⚠️ Watch the debug panel when eating dirt!")
