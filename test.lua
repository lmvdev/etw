-- FILE_CHANGE_VERSION: 21
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local GuiService = game:GetService("GuiService")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local char
local scriptEnabled = true
local farmReady = false
local farmActionsAllowedAt = 0
local farmPrepareToken = 0
local mapVisualConn
local hiddenParts = {}
local hiddenDecals = {}
local hiddenEffects = {}

local function setMapTimerPaused(paused)
    local setServerSettings = Events:FindFirstChild("SetServerSettings")
    if not setServerSettings then
        return
    end

    if paused then
        local args = {
            {
                Paused = true,
            },
        }
        setServerSettings:FireServer(unpack(args))
    else
        local args = {
            {
                Paused = false,
            },
        }
        setServerSettings:FireServer(unpack(args))
    end
end

local function getMapModeText()
    local currentGui = plr:FindFirstChild("PlayerGui")
    local screen = currentGui and currentGui:FindFirstChild("ScreenGui")
    local megaMaps = screen and screen:FindFirstChild("MegaMaps")
    local textLabel = megaMaps and megaMaps:FindFirstChild("TextLabel")
    return textLabel and textLabel.Text or nil
end

local function requestMapTeleport(modeName)
    local args = {
        modeName,
    }
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("RequestTeleport"):FireServer(unpack(args))
end

local function onErrorMessageChanged(errorMessage)
    if errorMessage and errorMessage ~= "" then
        task.wait()
        requestMapTeleport("Normal")
    end
end

GuiService.ErrorMessageChanged:Connect(onErrorMessageChanged)

local function ensureMegaMapMode()
    if getMapModeText() == "MEGA MAPS" then
        requestMapTeleport("Mega")

        local start = tick()
        while scriptEnabled and tick() - start < 15 do
            task.wait(0.25)
            if getMapModeText() == "NORMAL MAPS" then
                break
            end
        end
    end
end

local function ensureNormalMapMode()
    if getMapModeText() == "NORMAL MAPS" then
        requestMapTeleport("Normal")

        local start = tick()
        while tick() - start < 15 do
            task.wait(0.25)
            if getMapModeText() == "MEGA MAPS" then
                break
            end
        end
    end
end

local function clearLegacyFarmWelds()
    if not char or not char.Parent then
        return
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("WeldConstraint") and d.Name == "AutoFarmBedrockWeld" then
            d:Destroy()
        end
    end
end

local function setEtwCharacterMode(enabled)
    if not char or not char.Parent then
        return
    end

    local localChunkManager = char:FindFirstChild("LocalChunkManager")
    if localChunkManager and localChunkManager:IsA("LocalScript") then
        localChunkManager.Enabled = not enabled
    end

    local animate = char:FindFirstChild("Animate")
    if animate and animate:IsA("LocalScript") then
        animate.Enabled = not enabled
    end
end

local function updateCharacter(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
end

local function checkLoaded()
    local currentChar = char or plr.Character
    return (currentChar
        and currentChar:FindFirstChild("Humanoid")
        and currentChar:FindFirstChild("Size")
        and currentChar:FindFirstChild("Events")
        and currentChar.Events:FindFirstChild("Grab")
        and currentChar.Events:FindFirstChild("Eat")
        and currentChar.Events:FindFirstChild("Sell")
        and currentChar:FindFirstChild("CurrentChunk")) ~= nil
end

if plr.Character then
    updateCharacter(plr.Character)
else
    updateCharacter(plr.CharacterAdded:Wait())
end

plr.CharacterAdded:Connect(updateCharacter)

local playerGui = plr:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("AutoFarmToggleGui")
if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmToggleGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 190, 0, 44)
toggleButton.Position = UDim2.new(1, -230, 0, 35)
toggleButton.AnchorPoint = Vector2.new(0, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleButton

local function refreshToggleText()
    if scriptEnabled then
        toggleButton.Text = "AUTO FARM: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(40, 170, 70)
    else
        toggleButton.Text = "AUTO FARM: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
    end
end

local function getBedrockPart()
    local bedrockCandidate

    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") then
            local n = string.lower(inst.Name)
            if n == "bedrock" then
                return inst
            end
            if not bedrockCandidate and (n == "baseplate" or n == "ground") then
                bedrockCandidate = inst
            end
        end
    end

    return bedrockCandidate
end

local function placeCharacterUpright(targetPosition, lookDirection)
    if not char or not char.Parent then
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local look = lookDirection or hrp.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.01 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end

    local targetCFrame = CFrame.lookAt(targetPosition, targetPosition + flatLook)
    char:PivotTo(targetCFrame)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    if humanoid then
        humanoid.Sit = false
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function getStandOffset(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    local hip = humanoid and humanoid.HipHeight or 2
    local rootHalf = hrp and (hrp.Size.Y * 0.5) or 1
    return hip + rootHalf
end

local function setAntiFallMode(enabled)
    if not char or not char.Parent then
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid then
        return
    end

    local blockedStates = {
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Physics,
    }

    for _, state in ipairs(blockedStates) do
        pcall(function()
            humanoid:SetStateEnabled(state, not enabled)
        end)
    end

    if not enabled then
        humanoid.PlatformStand = false
    end
    humanoid.Sit = false
    humanoid.AutoRotate = not enabled

    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    if enabled then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    else
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function teleportToMapCenter()
    if not char or not char.Parent then
        return
    end

    local bedrock = getBedrockPart()
    if bedrock then
        local standOffset = getStandOffset(char)
        local yLocal = (bedrock.Size.Y * 0.5) + standOffset
        local inset = math.min(3, bedrock.Size.X * 0.1, bedrock.Size.Z * 0.1)
        local xLocal = math.max(0, (bedrock.Size.X * 0.5) - inset)
        local zLocal = math.max(0, (bedrock.Size.Z * 0.5) - inset)

        local startCorner = bedrock.CFrame:PointToWorldSpace(Vector3.new(-xLocal, yLocal, -zLocal))
        local oppositeCorner = bedrock.CFrame:PointToWorldSpace(Vector3.new(xLocal, yLocal, zLocal))
        local diagonalLook = oppositeCorner - startCorner

        placeCharacterUpright(startCorner, diagonalLook)
        return
    end

    placeCharacterUpright(Vector3.new(0, getStandOffset(char), 0), nil)
end

local function getFarmCornerCFrame()
    if not char or not char.Parent then
        return nil
    end

    local bedrock = getBedrockPart()
    if bedrock then
        local standOffset = getStandOffset(char)
        local yLocal = (bedrock.Size.Y * 0.5) + standOffset
        local inset = math.min(3, bedrock.Size.X * 0.1, bedrock.Size.Z * 0.1)
        local xLocal = math.max(0, (bedrock.Size.X * 0.5) - inset)
        local zLocal = math.max(0, (bedrock.Size.Z * 0.5) - inset)

        local startCorner = bedrock.CFrame:PointToWorldSpace(Vector3.new(-xLocal, yLocal, -zLocal))
        local oppositeCorner = bedrock.CFrame:PointToWorldSpace(Vector3.new(xLocal, yLocal, zLocal))
        return CFrame.lookAt(startCorner, oppositeCorner)
    end

    return CFrame.new(0, getStandOffset(char), 0)
end

local function teleportToCenterAbove()
    local bedrock = getBedrockPart()
    if bedrock then
        local standOffset = getStandOffset(char)
        local yLocal = (bedrock.Size.Y * 0.5) + standOffset + 25
        local centerAbove = bedrock.CFrame:PointToWorldSpace(Vector3.new(0, yLocal, 0))
        placeCharacterUpright(centerAbove, Vector3.new(1, 0, 1))
        return
    end

    placeCharacterUpright(Vector3.new(0, 30, 0), Vector3.new(1, 0, 1))
end

plr.CharacterAdded:Connect(function(newChar)
    if scriptEnabled then
        task.wait(0.15)
        if scriptEnabled and char == newChar then
            farmPrepareToken = farmPrepareToken + 1
            local token = farmPrepareToken
            farmReady = false
            farmActionsAllowedAt = math.huge

            task.spawn(function()
                ensureMegaMapMode()
                if not scriptEnabled or token ~= farmPrepareToken or char ~= newChar then
                    return
                end

                setEtwCharacterMode(true)
                clearLegacyFarmWelds()
                teleportToMapCenter()

                if not scriptEnabled or token ~= farmPrepareToken or char ~= newChar then
                    return
                end

                farmActionsAllowedAt = 0
                farmReady = true
            end)
        end
    end
end)

local function isBaseLayerPart(inst)
    if not inst:IsA("BasePart") then
        return false
    end

    local n = string.lower(inst.Name)
    return n == "bedrock" or n == "baseplate" or n == "ground"
end

local function hideMapVisuals()
    local function hideInstance(inst)
        if not inst then
            return
        end

        if char and inst:IsDescendantOf(char) then
            return
        end

        if inst:IsA("Model") then
            local playerFromModel = Players:GetPlayerFromCharacter(inst)
            if playerFromModel then
                return
            end
        end

        if isBaseLayerPart(inst) then
            inst.LocalTransparencyModifier = 0
            return
        end

        if inst:IsA("BasePart") then
            hiddenParts[inst] = inst.LocalTransparencyModifier
            inst.LocalTransparencyModifier = 1
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            hiddenDecals[inst] = inst.Transparency
            inst.Transparency = 1
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail") then
            hiddenEffects[inst] = inst.Enabled
            inst.Enabled = false
        elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            hiddenEffects[inst] = inst.Enabled
            inst.Enabled = false
        end
    end

    for _, inst in ipairs(Workspace:GetDescendants()) do
        hideInstance(inst)
    end

    if mapVisualConn then
        mapVisualConn:Disconnect()
    end

    mapVisualConn = Workspace.DescendantAdded:Connect(function(inst)
        if scriptEnabled then
            hideInstance(inst)
        end
    end)
end

local function restoreMapVisuals()
    for inst, originalValue in pairs(hiddenParts) do
        if inst and inst.Parent then
            inst.LocalTransparencyModifier = originalValue
        end
        hiddenParts[inst] = nil
    end

    for inst, originalValue in pairs(hiddenDecals) do
        if inst and inst.Parent then
            inst.Transparency = originalValue
        end
        hiddenDecals[inst] = nil
    end

    for inst, originalValue in pairs(hiddenEffects) do
        if inst and inst.Parent then
            inst.Enabled = originalValue
        end
        hiddenEffects[inst] = nil
    end
end

local function getTimedRewardRemoteByIndex(index)
    local timedRewards = plr:FindFirstChild("TimedRewards")
    if not timedRewards then
        return nil
    end

    if index >= 1 and index <= 3 then
        return timedRewards:FindFirstChild("SmallReward")
    elseif index >= 4 and index <= 6 then
        return timedRewards:FindFirstChild("MediumReward")
    elseif index >= 7 and index <= 9 then
        return timedRewards:FindFirstChild("LargeReward")
    end

    return nil
end

local function isRewardTemplateClaimable(template)
    for _, desc in ipairs(template:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local text = (desc.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" and not text:find(":") and not text:match("%d") then
                return true
            end
        end
    end
    return false
end

local function tryClaimTimedRewards()
    local playerGuiRef = plr:FindFirstChild("PlayerGui")
    local rootScreenGui = playerGuiRef and playerGuiRef:FindFirstChild("ScreenGui")
    local rewards = rootScreenGui and rootScreenGui:FindFirstChild("Rewards")
    local timedRewards = rewards and rewards:FindFirstChild("TimedRewards")
    local rewardGrid = timedRewards and timedRewards:FindFirstChild("RewardGrid")
    if not rewardGrid then
        return
    end

    local templates = {}
    for _, child in ipairs(rewardGrid:GetChildren()) do
        if child.Name == "Template" and child:IsA("GuiObject") then
            templates[#templates + 1] = child
        end
    end

    table.sort(templates, function(a, b)
        if a.LayoutOrder == b.LayoutOrder then
            return a:GetDebugId() < b:GetDebugId()
        end
        return a.LayoutOrder < b.LayoutOrder
    end)

    local rewardEvent = ReplicatedStorage:FindFirstChild("Events")
    rewardEvent = rewardEvent and rewardEvent:FindFirstChild("RewardEvent")
    if not rewardEvent then
        return
    end

    for i, template in ipairs(templates) do
        if i > 9 then
            break
        end

        if isRewardTemplateClaimable(template) then
            local rewardRemote = getTimedRewardRemoteByIndex(i)
            if rewardRemote then
                local args = {rewardRemote}
                rewardEvent:FireServer(unpack(args))
            end
        end
    end
end

local function prepareFarmStart()
    farmPrepareToken = farmPrepareToken + 1
    local token = farmPrepareToken

    farmReady = false
    farmActionsAllowedAt = math.huge

    task.spawn(function()
        ensureMegaMapMode()
        if not scriptEnabled or token ~= farmPrepareToken then
            return
        end

        setEtwCharacterMode(true)
        clearLegacyFarmWelds()
        teleportToMapCenter()

        if not scriptEnabled or token ~= farmPrepareToken then
            return
        end

        farmActionsAllowedAt = 0
        farmReady = true
    end)
end

toggleButton.MouseButton1Click:Connect(function()
    scriptEnabled = not scriptEnabled
    refreshToggleText()

    if scriptEnabled then
        setMapTimerPaused(true)
        hideMapVisuals()
        prepareFarmStart()
    elseif mapVisualConn then
        setMapTimerPaused(false)
        farmPrepareToken = farmPrepareToken + 1
        farmReady = false
        farmActionsAllowedAt = 0
        clearLegacyFarmWelds()
        setEtwCharacterMode(false)
        teleportToCenterAbove()
        mapVisualConn:Disconnect()
        mapVisualConn = nil
        restoreMapVisuals()
    else
        setMapTimerPaused(false)
        farmPrepareToken = farmPrepareToken + 1
        farmReady = false
        farmActionsAllowedAt = 0
        clearLegacyFarmWelds()
        setEtwCharacterMode(false)
        teleportToCenterAbove()
        restoreMapVisuals()
    end
end)

refreshToggleText()

if scriptEnabled then
    setMapTimerPaused(true)
    hideMapVisuals()
    prepareFarmStart()
end

task.spawn(function()
    while true do
        task.wait()

        if not scriptEnabled then
            continue
        end

        if not checkLoaded() then
            continue
        end

        if not farmReady then
            continue
        end

        local currentChar = char
        local hum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
        local root = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        local targetCFrame = getFarmCornerCFrame()
        if not hum or not root or not targetCFrame then
            continue
        end

        hum:ChangeState(Enum.HumanoidStateType.Physics)
        root.Anchored = false
        root.CFrame = targetCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end)

task.spawn(function()
    local lastChange = tick()
    local lastValue = nil

    while true do
        task.wait(0.5)

        if not scriptEnabled then
            continue
        end

        if not char or not char.Parent then
            continue
        end

        if not checkLoaded() then
            continue
        end

        if not farmReady then
            continue
        end

        local chunk = char:FindFirstChild("CurrentChunk")
        if chunk then
            local v = chunk.Value

            if v ~= lastValue then
                lastChange = tick()
                lastValue = v
            end

            if v == nil then
                local events = char:FindFirstChild("Events")
                local grabEvent = events and events:FindFirstChild("Grab")
                if grabEvent then
                    grabEvent:FireServer(false, false, false)
                end

                if tick() - lastChange > 1.3 then
                    -- TODO: here we will add another unstuck logic later.
                    lastChange = tick()
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)

        if not scriptEnabled then
            continue
        end

        if not char or not char.Parent then
            continue
        end

        if not checkLoaded() then
            continue
        end

        if not farmReady then
            continue
        end

        local currentPlayerGui = plr:FindFirstChild("PlayerGui")
        local currentScreenGui = currentPlayerGui and currentPlayerGui:FindFirstChild("ScreenGui")
        local sellGui = currentScreenGui and currentScreenGui:FindFirstChild("Sell")
        local sellText = sellGui and sellGui:FindFirstChild("SellText")

        if char:FindFirstChild("Size") and sellText and sellText.Visible then
            local events = char:FindFirstChild("Events")
            local sellEvent = events and events:FindFirstChild("Sell")
            if sellEvent then
                sellEvent:FireServer()
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)

        if not scriptEnabled then
            continue
        end

        if not char or not char.Parent then
            continue
        end

        if not checkLoaded() then
            continue
        end

        if not farmReady then
            continue
        end

        local chunk = char:FindFirstChild("CurrentChunk")
        if not chunk or chunk.Value == nil then
            continue
        end

        local events = char:FindFirstChild("Events")
        local eatEvent = events and events:FindFirstChild("Eat")
        if eatEvent then
            eatEvent:FireServer()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)

        if not scriptEnabled then
            continue
        end

        tryClaimTimedRewards()
    end
end)
