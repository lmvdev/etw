local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local char
local characterReady = false

local function waitForMapAndLanding(character)
    Workspace:WaitForChild("Map")

    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")

    while character.Parent do
        local landed = humanoid.FloorMaterial ~= Enum.Material.Air

        if not landed then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {character}
            local ray = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayParams)
            landed = ray ~= nil
        end

        if landed then
            return true
        end

        task.wait(0.2)
    end

    return false
end

local function updateCharacter(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
    characterReady = false

    task.spawn(function()
        local currentChar = char
        local ready = waitForMapAndLanding(currentChar)
        if ready and char == currentChar then
            characterReady = true
        end
    end)
end

if plr.Character then
    updateCharacter(plr.Character)
else
    updateCharacter(plr.CharacterAdded:Wait())
end

plr.CharacterAdded:Connect(updateCharacter)

getgenv().autoGrab = true
getgenv().autoSell = true

task.spawn(function()
    local lastChange = tick()
    local lastValue = nil

    while getgenv().autoGrab do
        task.wait(0.5)

        if not char or not char.Parent or not characterReady then
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
    while getgenv().autoSell do
        task.wait(0.1)

        if not char or not char.Parent then
            continue
        end

        local playerGui = plr:FindFirstChild("PlayerGui")
        local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
        local sellGui = screenGui and screenGui:FindFirstChild("Sell")
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
