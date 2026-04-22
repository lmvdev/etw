local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local char
local scriptEnabled = false
local mapVisualConn
local hiddenParts = {}
local hiddenDecals = {}
local hiddenEffects = {}

local function updateCharacter(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
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

local function placeCharacterUpright(targetPosition)
    if not char or not char.Parent then
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local look = hrp.CFrame.LookVector
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

local function teleportToMapCenter()
    if not char or not char.Parent then
        return
    end

    local bedrock = getBedrockPart()
    if bedrock then
        local y = bedrock.Position.Y + (bedrock.Size.Y * 0.5) + 1.61
        placeCharacterUpright(Vector3.new(bedrock.Position.X, y, bedrock.Position.Z))
        return
    end

    placeCharacterUpright(Vector3.new(0, 1.61, 0))
end

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

toggleButton.MouseButton1Click:Connect(function()
    scriptEnabled = not scriptEnabled
    refreshToggleText()

    if scriptEnabled then
        hideMapVisuals()
        teleportToMapCenter()
    elseif mapVisualConn then
        mapVisualConn:Disconnect()
        mapVisualConn = nil
        restoreMapVisuals()
    else
        restoreMapVisuals()
    end
end)

refreshToggleText()

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
