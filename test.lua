local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local char

local function updateCharacter(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
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
