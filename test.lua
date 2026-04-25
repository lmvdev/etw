-- FILE_CHANGE_VERSION: 31-4
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local inviteCode = "ab79c82f009a0147a3f0ae768ef856d1"

local state = {
    enabled = false,
    movingMode = true,
    running = false,
    numChunks = 0,
    timer = 0,
    grabTimer = 0,
    sellDebounce = false,
    startTime = 0,
    eatTime = 0,
    lastEatTime = 0,
    actionElapsed = 0,
    actionInterval = 1 / 6,
    lastMegaTeleportAt = 0,
    rewardCheckElapsed = 0,
    rewardsClaimed = 0,
}

local refs = {
    map = nil,
    chunks = nil,
    bedrock = nil,
    text = nil,
    autoConn = nil,
    charAddConn = nil,
    hum = nil,
    root = nil,
    size = nil,
    chunk = nil,
    radius = nil,
    eat = nil,
    grab = nil,
    sell = nil,
    sendTrack = nil,
    localChunkManager = nil,
    animate = nil,
    deathConn = nil,
}

local syncToggleButton = nil
local setAutoFarmEnabled
local stopAutoFarmAndSyncButton
local onNineRewardsClaimed

local function setupAntiAfk()
    local ok, VirtualUser = pcall(function()
        return game:GetService("VirtualUser")
    end)
    if not ok or not VirtualUser then
        return
    end

    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end)
end

local function sizeGrowth(level)
    return math.floor(((level + 0.5) ^ 2 - 0.25) / 2 * 100)
end

local function formatReadableNumber(value)
    local raw = tostring(value)
    local integerPart, fractionPart = raw:match("^(%-?%d+)%.(%d+)$")
    if not integerPart then
        integerPart = raw:match("^(%-?%d+)$") or raw
    end

    local sign = ""
    if integerPart:sub(1, 1) == "-" then
        sign = "-"
        integerPart = integerPart:sub(2)
    end

    integerPart = integerPart:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    if fractionPart and fractionPart ~= "" then
        return sign .. integerPart .. "." .. fractionPart
    end
    return sign .. integerPart
end

local function formatReadableWithSuffix(value)
    local absValue = math.abs(value)
    if absValue >= 1000000000 then
        return string.format("%.2fb", value / 1000000000)
    end
    if absValue >= 1000000 then
        return string.format("%.2fm", value / 1000000)
    end
    if absValue >= 1000 then
        return string.format("%.2fk", value / 1000)
    end
    return formatReadableNumber(value)
end

local function buildBalanceHint(maxSizeValue, multiplierValue)
    if multiplierValue <= 0 then
        return "Balance: Multiplier invalid"
    end

    local targetRatio = 5.5
    local ratio = maxSizeValue / multiplierValue
    local ratioText = string.format("%.3f", ratio)

    if ratio < targetRatio then
        local targetMaxSize = math.ceil(targetRatio * multiplierValue)
        return "Ratio: " .. ratioText .. " | Upg MaxSize -> " .. targetMaxSize
    end

    if ratio > targetRatio then
        local targetMultiplier = math.ceil(maxSizeValue / targetRatio)
        return "Ratio: " .. ratioText .. " | Upg Multiplier -> " .. targetMultiplier
    end

    return "Ratio: " .. ratioText .. " | Balanced"
end

local function changeMap()
    Events.SetServerSettings:FireServer({
        MapTime = -1,
        Paused = true,
    })
end

local function isOnMegaMap()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return false
    end

    local screenGui = playerGui:FindFirstChild("ScreenGui")
    local megaMaps = screenGui and screenGui:FindFirstChild("MegaMaps")
    local textLabel = megaMaps and megaMaps:FindFirstChild("TextLabel")
    local text = textLabel and textLabel.Text

    -- "NORMAL MAPS" button text means player is currently on mega map.
    return text == "NORMAL MAPS"
end

local function requestNormalTeleport()
    Events:WaitForChild("RequestTeleport"):FireServer("Normal")
end

local function requestMegaTeleport()
    local now = tick()
    if now - state.lastMegaTeleportAt < 3 then
        return
    end

    state.lastMegaTeleportAt = now
    Events:WaitForChild("RequestTeleport"):FireServer("Mega")
end

local function destroyText()
    if refs.text then
        refs.text:Destroy()
        refs.text = nil
    end
end

local function restoreMap()
    if refs.map and refs.chunks then
        refs.map.Parent = workspace
        refs.chunks.Parent = workspace
    end
end

local function hideMap()
    refs.map = workspace:FindFirstChild("Map")
    refs.chunks = workspace:FindFirstChild("Chunks")
    if refs.map and refs.chunks then
        refs.map.Parent = nil
        refs.chunks.Parent = nil
    end
end

local function ensureBedrock()
    if refs.bedrock then
        return
    end

    local bedrock = Instance.new("Part")
    bedrock.Name = "AutoFarmBedrock"
    bedrock.Anchored = true
    bedrock.Size = Vector3.new(2048, 10, 2048)
    bedrock.Position = Vector3.new(0, -5, 0)
    bedrock.BrickColor = BrickColor.Black()
    bedrock.Parent = workspace
    refs.bedrock = bedrock
end

local function destroyBedrock()
    if refs.bedrock then
        refs.bedrock:Destroy()
        refs.bedrock = nil
    end
end

local function ensureText()
    if refs.text then
        return
    end

    local text = Drawing.new("Text")
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.new(1, 1, 1)
    text.Center = false
    text.Position = Vector2.new(64, 64)
    text.Text = ""
    text.Size = 14
    text.Visible = true
    refs.text = text
end

local function disconnectRuntime()
    if refs.autoConn then
        refs.autoConn:Disconnect()
        refs.autoConn = nil
    end
    if refs.deathConn then
        refs.deathConn:Disconnect()
        refs.deathConn = nil
    end
end

local function resetCharacterFeatures()
    if refs.localChunkManager then
        refs.localChunkManager.Enabled = true
    end
    if refs.animate then
        refs.animate.Enabled = true
    end
    if refs.hum then
        refs.hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function cacheCharacterRefs(char)
    refs.hum = char:WaitForChild("Humanoid")
    refs.root = char:WaitForChild("HumanoidRootPart")
    refs.size = char:WaitForChild("Size")
    refs.chunk = char:WaitForChild("CurrentChunk")
    refs.radius = char:WaitForChild("Radius")

    local events = char:WaitForChild("Events")
    refs.eat = events:WaitForChild("Eat")
    refs.grab = events:WaitForChild("Grab")
    refs.sell = events:WaitForChild("Sell")
    refs.sendTrack = char:WaitForChild("SendTrack")

    refs.localChunkManager = char:WaitForChild("LocalChunkManager")
    refs.animate = char:WaitForChild("Animate")

    refs.localChunkManager.Enabled = false
    refs.animate.Enabled = false
end

local function updateMetrics(dt)
    local upgrades = LocalPlayer:FindFirstChild("Upgrades")
    local maxSize = upgrades and upgrades:FindFirstChild("MaxSize")
    local multi = upgrades and upgrades:FindFirstChild("Multiplier")
    local hasUpgradeStats = maxSize and multi

    local ran = tick() - state.startTime
    local hours = math.floor(ran / 3600)
    local minutes = math.floor(ran / 60)
    local seconds = math.floor(ran)

    local eatMinutes = math.floor(state.eatTime / 60)
    local eatSeconds = math.floor(state.eatTime)

    local sellEstimateText = "N/A"
    local perDayText = "N/A"
    local balanceHint = "Ratio: N/A"

    if hasUpgradeStats then
        local sizeAdd = math.max(multi.Value / 100, 0.01)
        local addAmount = maxSize.Value / sizeAdd
        local sellTime = math.max(addAmount / 2, 0.01)
        local sellMinutes = math.floor(sellTime / 60)
        local sellSeconds = math.floor(sellTime)
        local secondEarn = sizeGrowth(maxSize.Value) / sellTime
        local dayEarn = secondEarn * 60 * 60 * 24

        sellEstimateText = string.format("%im%is", sellMinutes % 60, sellSeconds % 60)
        perDayText = formatReadableWithSuffix(dayEarn)
        balanceHint = buildBalanceHint(maxSize.Value, multi.Value)
    end

    refs.text.Text = ""
        .. "\nRun: " .. string.format("%ih%im%is", hours, minutes % 60, seconds % 60)
        .. "\nActual: " .. string.format("%im%is", eatMinutes % 60, eatSeconds % 60)
        .. "\nApprox: " .. sellEstimateText
        .. "\nPer day: " .. perDayText
        .. "\nPrivateServerId: " .. tostring(game.PrivateServerId)
        .. "\nPlaceId: " .. tostring(game.PlaceId)
        .. "\nJobId: " .. tostring(game.JobId)
        .. "\n" .. balanceHint
        .. "\nChunks: " .. state.numChunks
        .. "\nRewards: " .. state.rewardsClaimed

    if state.enabled and refs.chunk and refs.chunk.Value then
        if state.timer > 0 then
            state.numChunks += 1
        end
        state.timer = 0
        state.grabTimer += dt
    elseif state.enabled then
        state.timer += dt
        state.grabTimer = 0
    end
end

local function claimRewardsIfReady()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return
    end

    local screenGui = playerGui:FindFirstChild("ScreenGui")
    local sideButtons = screenGui and screenGui:FindFirstChild("SideButtons")
    local rewards = sideButtons and sideButtons:FindFirstChild("Rewards")
    local timeText = rewards and rewards:FindFirstChild("TimeText")
    if not timeText or timeText.Text ~= "Ready!" then
        return
    end

    local timedRewards = LocalPlayer:FindFirstChild("TimedRewards")
    if not timedRewards then
        return
    end

    for _, reward in timedRewards:GetChildren() do
        if reward.Value > 0 then
            Events.RewardEvent:FireServer(reward)
        end
    end
end

local function spinIfReady()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return
    end

    local screenGui = playerGui:FindFirstChild("ScreenGui")
    local rewards = screenGui and screenGui:FindFirstChild("Rewards")
    local spin = rewards and rewards:FindFirstChild("Spin")
    local nextSpin = spin and spin:FindFirstChild("NextSpin")
    local timeLabel = nextSpin and nextSpin:FindFirstChild("Time")
    if not timeLabel then
        return
    end

    if timeLabel.Text == "00:00:00" then
        Events.SpinEvent:FireServer()
    end
end

local function countClaimedTemplatesInRewardGrid()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return 0
    end

    local screenGui = playerGui:FindFirstChild("ScreenGui")
    local rewards = screenGui and screenGui:FindFirstChild("Rewards")
    local timedRewardsUi = rewards and rewards:FindFirstChild("TimedRewards")
    local rewardGrid = timedRewardsUi and timedRewardsUi:FindFirstChild("RewardGrid")
    if not rewardGrid then
        return 0
    end

    local count = 0
    for _, inst in rewardGrid:GetDescendants() do
        if inst.Name == "Template" then
            local timeField = inst:FindFirstChild("Time")
            if timeField
                and (timeField:IsA("TextLabel") or timeField:IsA("TextButton"))
                and timeField.Text == "Claimed!"
            then
                count += 1
            end
        end
    end
    return count
end

local function processSellLogic()
    local upgrades = LocalPlayer:FindFirstChild("Upgrades")
    if not upgrades then
        return
    end

    local maxSize = upgrades:FindFirstChild("MaxSize")
    if not maxSize then
        return
    end

    if state.timer > 60 then
        refs.hum.Health = 0
        state.timer = 0
        state.numChunks = 0
        return
    end

    if state.grabTimer > 15 then
        refs.size.Value = maxSize.Value
    end

    if refs.size.Value >= maxSize.Value or state.timer > 4 then
        if state.timer < 4 then
            refs.sell:FireServer()
            if not state.sellDebounce then
                changeMap()
            end
            state.sellDebounce = true
        else
            changeMap()
        end
        state.numChunks = 0
    elseif refs.size.Value == 0 then
        if state.sellDebounce then
            local now = tick()
            state.eatTime = now - state.lastEatTime
            state.lastEatTime = now
        end
        state.sellDebounce = false
    end
end

local function moveCharacter()
    local y = refs.bedrock.Position.Y + refs.bedrock.Size.Y / 2 + refs.hum.HipHeight + refs.root.Size.Y / 2
    if state.movingMode then
        local bound = 300
        local startPos = CFrame.new(-bound / 2, y, -bound / 2)
        local r = refs.radius.Value * 1.1
        local dist = r * state.numChunks
        local x = dist % bound
        local z = math.floor(dist / bound) * r
        local offset = CFrame.new(x, 0, z + r * 2)

        if z > bound then
            changeMap()
            state.numChunks = 0
        end

        refs.root.CFrame = startPos * offset
    else
        refs.root.CFrame = CFrame.new(0, y, 0)
    end
end

local function heartbeat(dt)
    if not state.enabled then
        return
    end

    if workspace:FindFirstChild("Loading") then
        workspace.Loading:Destroy()
    end

    refs.hum:ChangeState(Enum.HumanoidStateType.Physics)
    refs.root.Anchored = false

    state.actionElapsed += dt
    if state.actionElapsed >= state.actionInterval then
        state.actionElapsed = 0

        local hasChunk = refs.chunk.Value ~= nil
        if hasChunk then
            refs.eat:FireServer()
        else
            refs.grab:FireServer()
        end

        refs.sendTrack:FireServer()
    end

    state.rewardCheckElapsed += dt
    if state.rewardCheckElapsed >= 1 then
        state.rewardCheckElapsed = 0
        state.rewardsClaimed = countClaimedTemplatesInRewardGrid()
        if state.rewardsClaimed >= 9 then
            onNineRewardsClaimed()
            return
        end
        claimRewardsIfReady()
        spinIfReady()
    end

    updateMetrics(dt)
    processSellLogic()
    moveCharacter()
end

local function startCharacter(char)
    if not isOnMegaMap() then
        requestMegaTeleport()
        task.delay(3, function()
            if state.enabled and LocalPlayer.Character == char and not refs.autoConn then
                startCharacter(char)
            end
        end)
        return
    end

    disconnectRuntime()
    state.numChunks = 0
    state.timer = 0
    state.grabTimer = 0
    state.sellDebounce = false
    state.rewardCheckElapsed = 0

    cacheCharacterRefs(char)

    refs.autoConn = RunService.Heartbeat:Connect(heartbeat)
    refs.deathConn = refs.hum.Died:Connect(function()
        disconnectRuntime()
        if state.enabled then
            changeMap()
        end
    end)
end

local function stopAutoFarm()
    state.enabled = false
    state.running = false
    disconnectRuntime()
    if refs.charAddConn then
        refs.charAddConn:Disconnect()
        refs.charAddConn = nil
    end
    restoreMap()
    destroyBedrock()
    resetCharacterFeatures()
    updateMetrics(0)
end

stopAutoFarmAndSyncButton = function()
    setAutoFarmEnabled(false)
    if syncToggleButton then
        syncToggleButton()
    end
end

onNineRewardsClaimed = function()
    stopAutoFarmAndSyncButton()
    if refs.sell then
        refs.sell:FireServer()
    end
    requestNormalTeleport()
end

local function startAutoFarm()
    if state.running then
        state.enabled = true
        return
    end

    state.enabled = true
    state.running = true
    state.startTime = tick()
    state.lastEatTime = tick()

    ensureText()
    ensureBedrock()
    hideMap()

    if LocalPlayer.Character then
        task.spawn(startCharacter, LocalPlayer.Character)
    end

    refs.charAddConn = LocalPlayer.CharacterAdded:Connect(startCharacter)
end

setAutoFarmEnabled = function(enabled)
    if enabled then
        startAutoFarm()
    else
        stopAutoFarm()
    end
end

local function createToggleButton()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoFarmToggleGui"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.Name = "AutoFarmToggleButton"
    button.Size = UDim2.fromOffset(180, 44)
    button.AnchorPoint = Vector2.new(0.5, 1)
    button.Position = UDim2.new(0.5, 0, 1, -64)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 18
    button.Font = Enum.Font.SourceSansBold
    button.Parent = gui

    local function syncButtonText()
        if state.enabled then
            button.Text = "AutoFarm: ON"
            button.BackgroundColor3 = Color3.fromRGB(30, 110, 45)
        else
            button.Text = "AutoFarm: OFF"
            button.BackgroundColor3 = Color3.fromRGB(110, 40, 40)
        end
    end

    button.MouseButton1Click:Connect(function()
        setAutoFarmEnabled(not state.enabled)
        syncButtonText()
    end)

    local privateServerButton = Instance.new("TextButton")
    privateServerButton.Name = "PrivateServerButton"
    privateServerButton.Size = UDim2.fromOffset(220, 40)
    privateServerButton.AnchorPoint = Vector2.new(0.5, 1)
    privateServerButton.Position = UDim2.new(0.5, 0, 1, -112)
    privateServerButton.BackgroundColor3 = Color3.fromRGB(45, 70, 130)
    privateServerButton.BorderSizePixel = 0
    privateServerButton.TextColor3 = Color3.new(1, 1, 1)
    privateServerButton.TextSize = 17
    privateServerButton.Font = Enum.Font.SourceSansBold
    privateServerButton.Text = "Join Private Server"
    privateServerButton.Parent = gui

    privateServerButton.MouseButton1Click:Connect(function()
        pcall(function()
            -- TeleportService:HandleInviteLink(inviteCode)
            -- if setclipboard then
            --     setclipboard("roblox://navigation/share_links?code=ab79c82f009a0147a3f0ae768ef856d1&type=Server")
            -- end
            -- openurl("roblox://navigation/share_links?code=ab79c82f009a0147a3f0ae768ef856d1&type=Server")
            -- local placeId = game.PlaceId
            -- local privateServerId = game.PrivateServerId
            -- TeleportService:TeleportToPlaceInstance(placeId, privateServerId, game.Players.LocalPlayer)
            -- local TeleportService = game:GetService("TeleportService")
            -- local teleportOptions = Instance.new("TeleportOptions")
            -- teleportOptions.ReservedServerAccessCode = "ab79c82f009a0147a3f0ae768ef856d1"
            -- TeleportService:TeleportAsync(game.PlaceId, { game.Players.LocalPlayer }, teleportOptions)
            -- local jobId = "58a46f85-82ad-4174-9fdb-3479f87cf9af"
            -- local placeId = game.PlaceId
            -- game:GetService("RunService").Stepped:Connect(function()
            --     if game.JobId ~= jobId then
            --         game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, jobId, game.Players.LocalPlayer)
            --     end
            -- end)
            local url = "https://www.roblox.com/share?code=ab79c82f009a0147a3f0ae768ef856d1&type=Server"
            local player = Players.LocalPlayer
            -- game:GetService("HttpService"):GetAsync(url)
            -- game:GetService("Players").LocalPlayer:SendExternalUrl(url)
            -- TeleportService:Teleport(16480898254, nil, url)
            -- TeleportService:TeleportToPrivateServer(16480898254, "ab79c82f009a0147a3f0ae768ef856d1", Players.LocalPlayer)
            TeleportService:TeleportToPrivateServerFromLink(url, {player})
        end)
    end)

    syncButtonText()
    syncToggleButton = syncButtonText
end

createToggleButton()
ensureText()
setupAntiAfk()
setAutoFarmEnabled(false)
updateMetrics(0)
