local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local LocalPlayer = Players.LocalPlayer

local UILib = getgenv().UILibCache or loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))
getgenv().UILibCache = UILib

local UI = UILib()
local window = UI:NewWindow("吃吃世界")
local main = window:NewSection("自动")
local upgrades = window:NewSection("升级")
local figure = window:NewSection("人物")
local others = window:NewSection("其它")

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function randomTp(character)
    local pos = workspace.Map.Bedrock.Position + Vector3.new(math.random(-workspace.Map.Bedrock.Size.X / 2, workspace.Map.Bedrock.Size.X / 2), 0, math.random(-workspace.Map.Bedrock.Size.X / 2, workspace.Map.Bedrock.Size.X / 2))
    character:MoveTo(pos)
    character:PivotTo(CFrame.new(character:GetPivot().Position, workspace.Map.Bedrock.Position))
end

local function changeMap()
    local args = {
    	{
    		MapTime = -1,
    		Paused = true
    	}
    }
    Events.SetServerSettings:FireServer(unpack(args))
end

local function checkLoaded()
    return (LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("Humanoid")
        and LocalPlayer.Character:FindFirstChild("Size")
        and LocalPlayer.Character:FindFirstChild("Events")
        and LocalPlayer.Character.Events:FindFirstChild("Grab")
        and LocalPlayer.Character.Events:FindFirstChild("Eat")
        and LocalPlayer.Character.Events:FindFirstChild("Sell")
        and LocalPlayer.Character:FindFirstChild("CurrentChunk")) ~= nil
end

local function sizeGrowth(level)
    return math.floor(((level + 0.5) ^ 2 - 0.25) / 2 * 100)
end

local function speedGrowth(level)
    return math.floor(level * 2 + 10)
end

local function multiplierGrowth(level)
    return math.floor(level)
end

local function eatSpeedGrowth(level)
    return math.floor((1 + (level - 1) * 0.2) * 10) / 10
end

local function sizePrice(level)
    return math.floor(level ^ 3 / 2) * 20
end

local function speedPrice(level)
    return math.floor((level * 3) ^ 3 / 200) * 1000
end

local function multiplierPrice(level)
    return math.floor((level * 10) ^ 3 / 200) * 1000
end

local function eatSpeedPrice(level)
    return math.floor((level * 10) ^ 3 / 200) * 2000
end

local function teleportPos()
    LocalPlayer.Character:PivotTo(CFrame.new(0, LocalPlayer.Character.Humanoid.HipHeight * 2, -100) * CFrame.Angles(0, math.rad(-90), 0))
end

main:CreateToggle("自动刷", function(enabled)
    autofarm = enabled
    
    coroutine.wrap(function()
    	local text = Drawing.new("Text")
    	text.Outline = true
    	text.OutlineColor = Color3.new(0, 0, 0)
    	text.Color = Color3.new(1, 1, 1)
    	text.Center = false
    	text.Position = Vector2.new(64, 64)
    	text.Text = ""
    	text.Size = 14
    	text.Visible = true
    	
    	local startTime = tick()
    	local eatTime = 0
    	local lastEatTime = tick()
        
        local timer = 0
        local grabTimer = 0
        local sellDebounce = false
        local sellCount = 0
        
        local bedrock = Instance.new("Part")
        bedrock.Anchored = true
        bedrock.Size = Vector3.new(2048, 10, 2048)
        bedrock.Position = Vector3.new(0, -5, 0)
        -- bedrock.Transparency = 1
        bedrock.BrickColor = BrickColor.Black()
        bedrock.Parent = workspace

        local map, chunks = workspace:FindFirstChild("Map"), workspace:FindFirstChild("Chunks")
        if map and chunks then
            map.Parent, chunks.Parent = nil, nil
        end

        local numChunks = 0
        
        local hum,
            root,
            size,
            events,
            eat,
            grab,
            sell,
            sendTrack,
            chunk,
            radius,
            autoConn,
            sizeConn
        
        local function onCharAdd(char)
            numChunks = 0
            
            hum = char:WaitForChild("Humanoid")
            root = char:WaitForChild("HumanoidRootPart")
            size = char:WaitForChild("Size")
            events = char:WaitForChild("Events")
            eat = events:WaitForChild("Eat")
            grab = events:WaitForChild("Grab")
            sell = events:WaitForChild("Sell")
            chunk = char:WaitForChild("CurrentChunk")
            sendTrack = char:WaitForChild("SendTrack")
            radius = char:WaitForChild("Radius")
            autoConn = game["Run Service"].Heartbeat:Connect(function(dt)
                if not autofarm then
                    autoConn:Disconnect()
                    return
                end
                
                local ran = tick() - startTime
                local hours = math.floor(ran / 60 / 60)
                local minutes = math.floor(ran / 60)
                local seconds = math.floor(ran)
                
                local eatMinutes = math.floor(eatTime / 60)
                local eatSeconds = math.floor(eatTime)
                
                local y = bedrock.Position.Y + bedrock.Size.Y / 2 + hum.HipHeight + root.Size.Y / 2

                local sizeAdd = LocalPlayer.Upgrades.Multiplier.Value / 100
                local addAmount = LocalPlayer.Upgrades.MaxSize.Value / sizeAdd
                
                local sellTime = addAmount / 2
                local sellMinutes = math.floor(sellTime / 60)
                local sellSeconds = math.floor(sellTime)
                
                local secondEarn = math.floor(sizeGrowth(LocalPlayer.Upgrades.MaxSize.Value) / sellTime)
                local minuteEarn = secondEarn * 60
                local hourEarn = minuteEarn * 60
                local dayEarn = hourEarn * 24
                
                text.Text = ""
                    .. "\n运行时间: " .. string.format("%ih%im%is", hours, minutes % 60, seconds % 60)
                    .. "\n实际时间: " .. string.format("%im%is", eatMinutes % 60, eatSeconds % 60)
                    .. "\n大约时间: " .. string.format("%im%is", sellMinutes % 60, sellSeconds % 60)
                    .. "\n每天: " .. dayEarn
                    .. "\n块数: " .. numChunks
                
                hum:ChangeState(Enum.HumanoidStateType.Physics)
                grab:FireServer()
                root.Anchored = false
                eat:FireServer()
                sendTrack:FireServer()
                
                if chunk.Value then
                    if timer > 0 then
                        numChunks += 1
                    end
                    timer = 0
                    grabTimer += dt
                else
                    timer += dt
                    grabTimer = 0
                end
                
                if timer > 60 then
                    hum.Health = 0
                    timer = 0
                    numChunks = 0
                end
                
                if grabTimer > 15 then
                    size.Value = LocalPlayer.Upgrades.MaxSize.Value
                end
                
                if (size.Value >= LocalPlayer.Upgrades.MaxSize.Value)
                    or timer > 8
                then
                    if timer < 8 then
                        sell:FireServer()
                        
                        if not sellDebounce then
                            changeMap()
                        end
                        
                        sellDebounce = true
                    else
                        changeMap()
                    end
                    numChunks = 0
                elseif size.Value == 0 then
                    if sellDebounce then
                        local currentEatTime = tick()
                        eatTime = currentEatTime - lastEatTime
                        lastEatTime = currentEatTime
                        
                        sellCount += 1
                    end
                    sellDebounce = false
                end
                
                if farmMoving then
                    local bound = 300
                    local startPos = CFrame.new(-bound/2, y, -bound/2)
                    
                    local r = radius.Value * 1.1
                    local dist = (r * numChunks)
                    local x = dist % bound
                    local z = math.floor(dist / bound) * r
                    local offset = CFrame.new(x, 0, z + r * 2)
                    
                    if z > bound then
                        changeMap()
                        numChunks = 0
                    end
                    
                    root.CFrame = startPos * offset
                    -- root.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, math.atan2(x, z) + math.pi, 0)
                else
                    root.CFrame = CFrame.new(0, y, 0)
                end
            end)
            
            hum.Died:Connect(function()
                autoConn:Disconnect()
                changeMap()
            end)
            
            char:WaitForChild("LocalChunkManager").Enabled = false
            char:WaitForChild("Animate").Enabled = false
        end
        
        if LocalPlayer.Character then
            task.spawn(onCharAdd, LocalPlayer.Character)
        else
            task.spawn(onCharAdd, LocalPlayer.CharacterAdded:Wait())
        end
        local charAddConn = LocalPlayer.CharacterAdded:Connect(onCharAdd)
        while autofarm do
            local dt = task.wait()
            if workspace:FindFirstChild("Loading") then
                workspace.Loading:Destroy()
            end
            if map and chunks then
                if showMap then
                    map.Parent, chunks.Parent = workspace, workspace
                else
                    map.Parent, chunks.Parent = nil, nil
                end
            end
        end
        charAddConn:Disconnect()
        if autoConn then
            autoConn:Disconnect()
        end
        if map and chunks then
            map.Parent, chunks.Parent = workspace, workspace
        end
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        bedrock:Destroy()
        LocalPlayer.Character.LocalChunkManager.Enabled = true
        LocalPlayer.Character.Animate.Enabled = true
        text:Destroy()
    end)()
end)

main:CreateToggle("自动收", function(enabled)
    autoCollectingCubes = enabled
    
    coroutine.wrap(function()
        LocalPlayer.PlayerScripts.CubeVis.Enabled = false
        while autoCollectingCubes do
            task.wait()
            local root = getRoot()
            
            if root then
                for _, v in workspace:GetChildren() do
                    if v.Name == "Cube" and v:FindFirstChild("Owner") and (v.Owner.Value == LocalPlayer.Name or v.Owner.Value == "") then
                        v.CFrame = root.CFrame
                    end
                end
            end
        end
        LocalPlayer.PlayerScripts.CubeVis.Enabled = true
    end)()
end)

main:CreateToggle("自动领", function(enabled)
    autoClaimRewards = enabled
    
    coroutine.wrap(function()
        while autoClaimRewards do
            task.wait(1)
            for _, reward in LocalPlayer.TimedRewards:GetChildren() do
                if reward.Value > 0 then
                    Events.RewardEvent:FireServer(reward)
                end
            end
            
            Events.SpinEvent:FireServer()
        end
    end)()
end)

main:CreateToggle("移动模式", function(enabled)
    farmMoving = enabled
end)

main:CreateToggle("显示地图", function(enabled)
    showMap = enabled
end)

main:CreateToggle("自动吃", function(enabled)
    autoeat = enabled
    
    coroutine.wrap(function()
        while autoeat do
            local dt = task.wait()
            
            if checkLoaded() then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
                LocalPlayer.Character.Events.Grab:FireServer()
                LocalPlayer.Character.Events.Eat:FireServer()
            end
        end
    end)()
end)

upgrades:CreateToggle("大小", function(enabled)
    autoUpgradeSize = enabled
    
    coroutine.wrap(function()
        game.CoreGui.PurchasePromptApp.Enabled = false
        while autoUpgradeSize do
            task.wait(1)
            Events.PurchaseEvent:FireServer("MaxSize")
        end
        game.CoreGui.PurchasePromptApp.Enabled = true
    end)()
end)

upgrades:CreateToggle("移速", function(enabled)
    autoUpgradeSpd = enabled
    
    coroutine.wrap(function()
        game.CoreGui.PurchasePromptApp.Enabled = false
        while autoUpgradeSpd do
            task.wait(1)
            Events.PurchaseEvent:FireServer("Speed")
        end
        game.CoreGui.PurchasePromptApp.Enabled = true
    end)()
end)

upgrades:CreateToggle("乘数", function(enabled)
    autoUpgradeMulti = enabled
    
    coroutine.wrap(function()
        game.CoreGui.PurchasePromptApp.Enabled = false
        while autoUpgradeMulti do
            task.wait(1)
            Events.PurchaseEvent:FireServer("Multiplier")
        end
        game.CoreGui.PurchasePromptApp.Enabled = true
    end)()
end)

upgrades:CreateToggle("吃速", function(enabled)
    autoUpgradeEat = enabled
    
    coroutine.wrap(function()
        game.CoreGui.PurchasePromptApp.Enabled = false
        while autoUpgradeEat do
            task.wait(1)
            Events.PurchaseEvent:FireServer("EatSpeed")
        end
        game.CoreGui.PurchasePromptApp.Enabled = true
    end)()
end)

figure:CreateToggle("取消锚固", function(enabled)
    keepUnanchor = enabled
    
    coroutine.wrap(function()
        while keepUnanchor do
            task.wait()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
        end
    end)()
end)

figure:CreateToggle("边界保护", function(enabled)
    boundProtect = enabled
    
    coroutine.wrap(function()
        while boundProtect do
            task.wait()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local pos = root.Position
                local mapSize = workspace.Map.Bedrock.Size * Vector3.new(1, 0, 1)
                local clampedPos = vector.clamp(pos * Vector3.new(1, 0, 1), -mapSize / 2, mapSize / 2)
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(clampedPos.X, pos.Y, clampedPos.Z) * root.CFrame.Rotation
            end
        end
    end)()
end)

others:CreateButton("查看玩家数据", function()
    local localization = {
        MaxSize = "体积",
        Speed = "移速",
        Multiplier = "乘数",
        EatSpeed = "吃速",
    }
    local growthFunctions = {
        MaxSize = sizeGrowth,
        Speed = speedGrowth,
        Multiplier = multiplierGrowth,
        EatSpeed = eatSpeedGrowth,
    }
    local priceFunctions = {
        MaxSize = sizePrice,
        Speed = speedPrice,
        Multiplier = multiplierPrice,
        EatSpeed = eatSpeedPrice,
    }
    for _, player in Players:GetPlayers() do
        print()
        for _, upg in player.Upgrades:GetChildren() do
            local content = player.Name .. "："
            
            local cost = 0
            for l = 2, upg.Value do
                cost += priceFunctions[upg.Name](l)
            end
            
            content = content .. " " .. `{localization[upg.Name]}：`
            content = content .. " " .. `{upg.Value}级；`
            content = content .. " " .. `{growthFunctions[upg.Name](upg.Value)}值；`
            content = content .. " " .. `{cost}花费；`
            
            print(content)
        end
    end
    
    game.StarterGui:SetCore("DevConsoleVisible", true)
end)

others:CreateToggle("竖屏", function(enabled)
    LocalPlayer.PlayerGui.ScreenOrientation = enabled and Enum.ScreenOrientation.Portrait or Enum.ScreenOrientation.LandscapeRight
end)


-- local args = {
	-- "Mega"
-- }
-- game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("RequestTeleport"):FireServer(unpack(args))

-- game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("SpinEvent"):FireServer()

-- Purchases: MaxSize, Speed, Multiplier, EatSpeed

--[[

-- Decompiler will be improved VERY SOON!
-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/brNTY8nX8t)
-- Decompiled on 2025-07-20 07:47:16
-- Luau version 6, Types version 3
-- Time taken: 0.005614 seconds

local module_8 = {
	GamePasses = {
		["Eat Players"] = 720768665;
		Magnet = 730280015;
		["Explosive Chunks"] = 733742262;
	};
	DevProducts = {
		["Small Cube Pack"] = 1760706156;
		["Medium Cube Pack"] = 1760707045;
		["Large Cube Pack"] = 1760707972;
		["Giant Cube Pack"] = 1760709729;
		["Max Size"] = 1760728424;
		["Small Token Pack"] = 1805507066;
		["Medium Token Pack"] = 1805507931;
		["Large Token Pack"] = 1805509180;
		["Giant Token Pack"] = 1805509730;
		["Starter Pack"] = 1942042820;
		["Holiday Pack 2024"] = 2678435873;
		["Rainbow Pack"] = 2839548304;
	};
	CubePacks = {
		["Small Cube Pack"] = 60000;
		["Medium Cube Pack"] = 150000;
		["Large Cube Pack"] = 600000;
		["Giant Cube Pack"] = 2000000;
	};
	TokenPacks = {
		["Small Token Pack"] = 3;
		["Medium Token Pack"] = 5;
		["Large Token Pack"] = 15;
		["Giant Token Pack"] = 50;
	};
	Bundles = {
		["Starter Pack"] = {
			Tokens = 10;
			Cubes = 150000;
		};
		["Holiday Pack 2024"] = {
			Tokens = 50;
			Cubes = 2000000;
		};
		["Rainbow Pack"] = {
			Tokens = 50;
			Cubes = 2000000;
		};
	};
	LimitedPurchases = {
		["Starter Pack"] = 1;
		["Holiday Pack 2024"] = 0;
		["Rainbow Pack"] = 1;
	};
	Events = {
		["Money Rain"] = {
			name = "Money Rain";
			price = 3;
			image = "rbxassetid://17099910913";
			description = "Rains money from the sky!";
			message = "It's raining money!";
			duration = 60;
		};
		Robot = {
			name = "Money Rain";
			price = 5;
			image = "rbxassetid://17099910828";
			description = "Summon a robot to destroy the map!";
			message = "A robot is attacking!";
			duration = 60;
		};
		Nuke = {
			name = "Money Rain";
			price = 10;
			image = "rbxassetid://17099911657";
			description = "Destroys most of the map!";
			message = "A NUKE IS FALLING! RUN AWAY FROM THE CENTER!";
			duration = 30;
		};
		["Big Food"] = {
			name = "Money Rain";
			price = nil;
			image = "rbxassetid://13902932122";
			description = "Rains giant food that gives extra size!";
			duration = 30;
		};
		Skeletons = {
			name = "Money Rain";
			price = 5;
			image = "rbxassetid://17099910709";
			description = "Summon skeletons to destroy the map!";
			message = "Skeletons are attacking!";
			duration = 60;
		};
		["Low Gravity"] = {
			name = "Low Gravity";
			price = 1;
			image = "rbxassetid://17099910598";
			description = "Make everything float!";
			message = "Low gravity!";
			duration = 40;
		};
	};
}
local tbl = {}
local tbl_3 = {
	price = 10;
	description = "98% chance to get a random color nametag, 2% chance to get a GLOWING color nametag!";
	decal = "rbxassetid://110003088413698";
	possibilities = {"Green", "Cyan", "Purple", "Pink", "Blue", "Orange", "Red", "Yellow", "Glowing Green", "Glowing Cyan", "Glowing Purple", "Glowing Pink", "Glowing Red", "Glowing Yellow"};
}
local function getCrate() -- Line 143
	local module_3 = {"Green", "Cyan", "Purple", "Pink", "Blue", "Orange", "Red", "Yellow"}
	local module_2 = {"Glowing Green", "Glowing Cyan", "Glowing Purple", "Glowing Pink", "Glowing Red", "Glowing Yellow"}
	if 0.98 < math.random() then
		return module_2[math.random(1, #module_2)]
	end
	return module_3[math.random(1, #module_3)]
end
tbl_3.getCrate = getCrate
tbl["Color Crate"] = tbl_3
local tbl_2 = {
	price = 25;
	description = "80% chance to get a common nametag, 18% chance to get an uncommon nametag, 2% chance to get a RARE nametag!";
	color = Color3.new(1, 0.905882, 0.752941);
	possibilities = {"Draw Four", "Velvet", "Mysterious", "Sketchbook", "Viscount", "Lolcats", "3D Movie", "Fruit Salad", "Bubblegum"};
}
local function getCrate() -- Line 185
	local module_6 = {"Draw Four", "Velvet", "Mysterious", "Sketchbook", "Viscount"}
	local module_4 = {"Lolcats", "3D Movie", "Fruit Salad"}
	local module_7 = {"Bubblegum"}
	local seed_2 = math.random()
	if 0.98 < seed_2 then
		return module_7[math.random(1, #module_7)]
	end
	if 0.8 < seed_2 then
		return module_4[math.random(1, #module_4)]
	end
	return module_6[math.random(1, #module_6)]
end
tbl_2.getCrate = getCrate
tbl["Standard Crate"] = tbl_2
tbl["Digital Crate"] = {
	price = 25;
	description = "80% chance to get a common nametag, 18% chance to get an uncommon nametag, 2% chance to get a RARE nametag!";
	decal = "rbxassetid://118112669619148";
	possibilities = {"Vaporwave", "Nostalgia", "Relaxed", "Solar", "Neon", "Wireframe", "Futuristic", "Glitchcore"};
	getCrate = function() -- Line 219, Named "getCrate"
		local module = {"Vaporwave", "Nostalgia", "Relaxed"}
		local module_9 = {"Solar", "Neon", "Wireframe"}
		local module_5 = {"Futuristic", "Glitchcore"}
		local seed = math.random()
		if 0.98 < seed then
			return module_5[math.random(1, #module_5)]
		end
		if 0.8 < seed then
			return module_9[math.random(1, #module_9)]
		end
		return module[math.random(1, #module)]
	end;
}
module_8.Crates = tbl
module_8.Nametags = {
	Green = {
		description = "";
		rarity = 1;
	};
	Cyan = {
		description = "";
		rarity = 1;
	};
	Purple = {
		description = "";
		rarity = 1;
	};
	Pink = {
		description = "";
		rarity = 1;
	};
	Blue = {
		description = "";
		rarity = 1;
	};
	Orange = {
		description = "";
		rarity = 1;
	};
	Red = {
		description = "";
		rarity = 1;
	};
	Yellow = {
		description = "";
		rarity = 1;
	};
	["Glowing Green"] = {
		description = "";
		rarity = 3;
	};
	["Glowing Cyan"] = {
		description = "";
		rarity = 3;
	};
	["Glowing Purple"] = {
		description = "";
		rarity = 3;
	};
	["Glowing Pink"] = {
		description = "";
		rarity = 3;
	};
	["Glowing Orange"] = {
		description = "";
		rarity = 3;
	};
	["Glowing Red"] = {
		description = "";
		rarity = 3;
	};
	["Glowing Yellow"] = {
		description = "";
		rarity = 3;
	};
	["Draw Four"] = {
		description = "";
		rarity = 1;
	};
	Velvet = {
		description = "";
		rarity = 1;
	};
	Mysterious = {
		description = "";
		rarity = 1;
	};
	Sketchbook = {
		description = "";
		rarity = 1;
	};
	Viscount = {
		description = "";
		rarity = 1;
	};
	Diary = {
		description = "";
		rarity = 1;
	};
	Lolcats = {
		description = "";
		rarity = 2;
	};
	["3D Movie"] = {
		description = "";
		rarity = 2;
	};
	["Fruit Salad"] = {
		description = "";
		rarity = 2;
	};
	Bubblegum = {
		description = "";
		rarity = 3;
	};
	Vaporwave = {
		description = "";
		rarity = 1;
	};
	Nostalgia = {
		description = "";
		rarity = 1;
	};
	Relaxed = {
		description = "";
		rarity = 1;
	};
	Solar = {
		description = "";
		rarity = 2;
	};
	Neon = {
		description = "";
		rarity = 2;
	};
	Wireframe = {
		description = "";
		rarity = 2;
	};
	Futuristic = {
		description = "";
		rarity = 3;
	};
	Glitchcore = {
		description = "";
		rarity = 3;
	};
	["Candy Cane"] = {
		description = "Awarded to players who completed the 2024 Holiday Quest!";
		rarity = 4;
	};
	["Festive Gold"] = {
		description = "Awarded to players who purchased the 2024 Holiday Pack!";
		rarity = 5;
	};
	Rainbow = {
		description = "Awarded to players who purchased the Rainbow Pack!";
		rarity = 5;
	};
	["Token Hunter"] = {
		description = "Awarded to players who completed The Hunt: Mega Edition quest!";
		rarity = 4;
	};
}
local tbl_4 = {}
local tbl_6 = {
	name = "Maximum Size";
	order = 1;
	initial = 0.5;
	maxLevel = 10;
	image = "rbxassetid://17151582981";
	color = Color3.new(0.596078, 1, 0.698039);
}
local function priceFunction(arg1) -- Line 407
	return math.floor(arg1 ^ 3 / 2) * 20
end
tbl_6.priceFunction = priceFunction
local function growthFunction(arg1) -- Line 412
	return math.floor(((arg1 + 0.5) ^ 2 - 0.25) / 2 * 100)
end
tbl_6.growthFunction = growthFunction
tbl_4.MaxSize = tbl_6
local tbl_7 = {
	name = "Walk Speed";
	order = 2;
	initial = 0.5;
	maxLevel = 10;
	image = "rbxassetid://17137197155";
	color = Color3.new(0.439216, 0.541176, 1);
}
local function priceFunction(arg1) -- Line 425
	return math.floor((arg1 * 3) ^ 3 / 200) * 1000
end
tbl_7.priceFunction = priceFunction
local function growthFunction(arg1) -- Line 431
	return math.floor(arg1 * 2 + 10)
end
tbl_7.growthFunction = growthFunction
tbl_4.Speed = tbl_7
local tbl_5 = {
	name = "Size Multiplier";
	order = 3;
	initial = 0.5;
	maxLevel = 10;
	image = "rbxassetid://17137197010";
	color = Color3.new(1, 0.384314, 0.396078);
}
local function priceFunction(arg1) -- Line 445
	return math.floor((arg1 * 10) ^ 3 / 200) * 1000
end
tbl_5.priceFunction = priceFunction
local function growthFunction(arg1) -- Line 451
	return math.floor(arg1)
end
tbl_5.growthFunction = growthFunction
tbl_4.Multiplier = tbl_5
tbl_4.EatSpeed = {
	name = "Eat Speed";
	order = 4;
	initial = 0.5;
	maxLevel = 10;
	image = "rbxassetid://16676559094";
	color = Color3.new(1, 0.854902, 0.521569);
	priceFunction = function(arg1) -- Line 465, Named "priceFunction"
		return math.floor((arg1 * 10) ^ 3 / 200) * 2000
	end;
	growthFunction = function(arg1) -- Line 471, Named "growthFunction"
		return math.floor((1 + (arg1 - 1) * 0.2) * 10) / 10
	end;
}
module_8.Upgrades = tbl_4
module_8.Tools = {}
module_8.Descriptions = {
	["Eat Players"] = "Eat players smaller than you to steal their size!";
	Magnet = "Automatically collect money!";
	["Explosive Chunks"] = "Anything you throw explodes on impact, dealing more damage!";
}
return module_8

]]

-- local values = {}
-- local conn conn = game.Players.LocalPlayer.Character.Size.Changed:Connect(function(value)
    -- if value <= 1 then
        -- conn:Disconnect()
        -- toclipboard(table.concat(values, "\n"))
    -- end
    -- table.insert(values, value)
    -- print(value)
-- end)

-- function calculateGiantSize(multiplier, index)
    -- local baseValue = 0.88 * index + 0.015 * index^2 + 0.001 * index^3
    -- return tonumber(string.format("%.2f", baseValue * (multiplier / 45)))
-- end

-- local data = ([[
-- 0
-- 1.8
-- 3.6
-- 4.95
-- 5.85
-- 7.2
-- 9
-- 9.9
-- 10.8
-- 12.15
-- 13.05
-- 14.4
-- 15.75
-- 17.1
-- 18.45
-- 20.25
-- 21.6
-- 22.5
-- 23.85
-- 25.65
-- 26.55
-- 27.9
-- 28.8
-- 30.6
-- 31.5
-- 32.85
-- 34.2
-- 35.55
-- 36.9
-- 38.25
-- 39.15
-- 40.95
-- 42.3
-- 43.65
-- 45.45
-- 46.35
-- 47.25
-- 48.15
-- 49.05
-- 50.849999999999994
-- 52.64999999999999
-- 54.44999999999999
-- 56.249999999999986
-- 58.04999999999998
-- 59.84999999999998
-- 61.64999999999998
-- 62.99999999999998
-- 64.79999999999998
-- 66.59999999999998
-- 68.39999999999998
-- 69.29999999999998
-- 71.09999999999998
-- 72.44999999999997
-- 73.34999999999998
-- 75.14999999999998
-- 76.49999999999997
-- 78.29999999999997
-- 79.64999999999996
-- 80.99999999999996
-- 82.34999999999995
-- 84.14999999999995
-- 85.49999999999994
-- 86.39999999999995
-- 87.29999999999995
-- 88.19999999999996
-- 89.09999999999997
-- 89.99999999999997
-- 91.79999999999997
-- 93.59999999999997
-- 94.94999999999996
-- 96.74999999999996
-- 98.54999999999995
-- 99.44999999999996
-- 101.24999999999996
-- 102.59999999999995
-- 104.39999999999995
-- 105.74999999999994
-- 107.09999999999994
-- 108.44999999999993
-- 109.79999999999993
-- 110.69999999999993
-- 112.04999999999993
-- 113.39999999999992
-- 114.74999999999991
-- 115.64999999999992
-- 116.54999999999993
-- 117.89999999999992
-- 119.24999999999991
-- 120.14999999999992
-- 121.04999999999993
-- 122.84999999999992
-- 124.64999999999992
-- 125.54999999999993
-- 127.34999999999992
-- 129.14999999999992
-- 130.04999999999993
-- 131.84999999999994
-- 133.19999999999993
-- 134.09999999999994
-- 135.44999999999993
-- 136.79999999999993
-- 138.14999999999992
-- 139.94999999999993
-- 141.74999999999994
-- 143.54999999999995
-- 144.44999999999996
-- 145.79999999999995
-- 147.59999999999997
-- 148.94999999999996
-- 150.29999999999995
-- 152.09999999999997
-- 152.99999999999997
-- 154.79999999999998
-- 156.6
-- 158.4
-- 159.75
-- 161.1
-- 162
-- 163.8
-- 165.6
-- 166.95
-- 167.85
-- 168.75
-- 170.55
-- 171.9
-- 172.8
-- 174.6
-- 175.5
-- 176.85
-- 178.2
-- 179.1
-- 180.9
-- 182.25
-- 183.6
-- 184.5
-- 185.85
-- 187.2
-- 188.1
-- 189
-- 190.8
-- 192.15
-- 193.5
-- 194.4
-- 195.3
-- 197.1
-- 198.9
-- 200.7
-- 201.6
-- 202.5]]):split("\n")


-- Decompiler will be improved VERY SOON!
-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/brNTY8nX8t)
-- Decompiled on 2025-08-03 09:44:11
-- Luau version 6, Types version 3
-- Time taken: 0.014768 seconds

-- local LocalPlayer_upvr = game.Players.LocalPlayer
-- local Parent_upvr = script.Parent
-- local Humanoid_upvr = Parent_upvr:WaitForChild("Humanoid")
-- local HumanoidRootPart_upvr = Parent_upvr:WaitForChild("HumanoidRootPart")
-- local tbl_2_upvr = {}
-- local CurrentChunk_upvr = script.Parent:WaitForChild("CurrentChunk")
-- local Radius = script.Parent:WaitForChild("Radius")
-- local Debris_upvr = game:GetService("Debris")
-- local UserGameSettings_upvr = UserSettings():GetService("UserGameSettings")
-- local function shuffle_upvr(arg1) -- Line 16, Named "shuffle"
	-- for i = #arg1, 1, -1 do
		-- local randint_from_1 = math.random(i)
		-- arg1[i] = arg1[randint_from_1]
		-- arg1[randint_from_1] = arg1[i]
	-- end
-- end
-- local var16_upvw = 0
-- local Part_upvr_2 = Instance.new("Part")
-- Part_upvr_2.Name = "Barrier"
-- Part_upvr_2.Massless = true
-- Part_upvr_2.Transparency = 1
-- Part_upvr_2.Size = Vector3.new(HumanoidRootPart_upvr.Size.X, 1, 0.1)
-- local Weld_upvr = Instance.new("Weld")
-- Weld_upvr.Parent = Part_upvr_2
-- Weld_upvr.Part0 = HumanoidRootPart_upvr
-- Weld_upvr.Part1 = Part_upvr_2
-- Weld_upvr.C0 = CFrame.new(0, 0, -1.343)
-- Part_upvr_2.CollisionGroup = "HRP"
-- Part_upvr_2.CanQuery = false
-- Part_upvr_2.CanTouch = false
-- Instance.new("Attachment").Parent = Part_upvr_2
-- Part_upvr_2.Parent = Parent_upvr
-- function setBarrier() -- Line 51
	-- --[[ Upvalues[5]:
		-- [1]: Parent_upvr (readonly)
		-- [2]: HumanoidRootPart_upvr (readonly)
		-- [3]: Part_upvr_2 (readonly)
		-- [4]: Weld_upvr (readonly)
		-- [5]: LocalPlayer_upvr (readonly)
	-- ]]
	-- local LeftElbow = Parent_upvr.LeftLowerArm.LeftElbow
	-- local LeftWrist = Parent_upvr.LeftHand.LeftWrist
	-- local _ = HumanoidRootPart_upvr.CFrame:ToObjectSpace(Parent_upvr.LeftUpperArm.LeftElbowRigAttachment.WorldCFrame).Position
	-- local var23 = ((LeftElbow.C0.Position - LeftElbow.C1.Position).Magnitude + (LeftWrist.C0.Position - LeftWrist.C1.Position).Magnitude + 0.29552020666133955 * ((HumanoidRootPart_upvr.CFrame:ToObjectSpace(Parent_upvr.UpperTorso.LeftShoulderRigAttachment.WorldCFrame).Position - HumanoidRootPart_upvr.CFrame:ToObjectSpace(Parent_upvr.LeftFoot.LeftAnkleRigAttachment.WorldCFrame).Position) * Vector3.new(0, 1, 1)).Magnitude) * 1.1
	-- Part_upvr_2.Size = Vector3.new(HumanoidRootPart_upvr.Size.X * 1.3, 1, var23 + HumanoidRootPart_upvr.Size.Z / 2)
	-- Part_upvr_2.Attachment.Position = Vector3.new(0, 0, -Part_upvr_2.Size.Z / 2 + 0.05)
	-- Weld_upvr.C0 = CFrame.new(0, 0, -var23 + Part_upvr_2.Size.Z / 2)
	-- LocalPlayer_upvr.CameraMaxZoomDistance = math.clamp(HumanoidRootPart_upvr.Size.X * 6, 60, 1000)
-- end
-- script.Parent:WaitForChild("PhysicalSize").Changed:Connect(function() -- Line 77
	-- wait()
	-- setBarrier()
-- end)
-- local Value_upvw_2 = CurrentChunk_upvr.Value
-- local var26_upvw = math.ceil(Radius.Value) + 2
-- Radius.Changed:Connect(function(arg1) -- Line 87
	-- --[[ Upvalues[1]:
		-- [1]: var26_upvw (read and write)
	-- ]]
	-- var26_upvw = math.ceil(arg1) + 2
-- end)
-- local var28_upvw = true
-- local Particles = LocalPlayer_upvr:WaitForChild("Preferences"):FindFirstChild("Particles")
-- if Particles then
	-- var28_upvw = Particles.Value
	-- Particles.Changed:Connect(function(arg1) -- Line 95
		-- --[[ Upvalues[1]:
			-- [1]: var28_upvw (read and write)
		-- ]]
		-- var28_upvw = arg1
	-- end)
-- end
-- function connectMarkers(arg1) -- Line 100
	-- --[[ Upvalues[8]:
		-- [1]: HumanoidRootPart_upvr (readonly)
		-- [2]: Parent_upvr (readonly)
		-- [3]: var28_upvw (read and write)
		-- [4]: Value_upvw_2 (read and write)
		-- [5]: shuffle_upvr (readonly)
		-- [6]: var26_upvw (read and write)
		-- [7]: Debris_upvr (readonly)
		-- [8]: tbl_2_upvr (readonly)
	-- ]]
	-- table.insert(tbl_2_upvr, arg1:GetMarkerReachedSignal("Start"):Connect(function() -- Line 101
		-- --[[ Upvalues[1]:
			-- [1]: HumanoidRootPart_upvr (copied, readonly)
		-- ]]
		-- HumanoidRootPart_upvr.Anchored = true
	-- end))
	-- table.insert(tbl_2_upvr, arg1:GetMarkerReachedSignal("GrabChunk"):Connect(function() -- Line 104
		-- --[[ Upvalues[2]:
			-- [1]: arg1 (readonly)
			-- [2]: Parent_upvr (copied, readonly)
		-- ]]
		-- arg1:AdjustSpeed(Parent_upvr.PullSpeed.Value)
	-- end))
	-- table.insert(tbl_2_upvr, arg1:GetMarkerReachedSignal("PullChunk"):Connect(function() -- Line 109
		-- --[[ Upvalues[6]:
			-- [1]: arg1 (readonly)
			-- [2]: var28_upvw (copied, read and write)
			-- [3]: Value_upvw_2 (copied, read and write)
			-- [4]: shuffle_upvr (copied, readonly)
			-- [5]: var26_upvw (copied, read and write)
			-- [6]: Debris_upvr (copied, readonly)
		-- ]]
		-- arg1:AdjustSpeed(1)
		-- if not var28_upvw then
		-- else
			-- if not Value_upvw_2 then return end
			-- if not Value_upvw_2:FindFirstChild("PullParticles") then return end
			-- for i_4, v_3 in ipairs(Value_upvw_2.PullParticles:GetChildren()) do
				-- if var26_upvw < i_4 then break end
				-- v_3.DustParticle:Emit(5)
				-- local clone_4_upvr = v_3:Clone()
				-- clone_4_upvr:ClearAllChildren()
				-- clone_4_upvr.Size /= 2
				-- clone_4_upvr.Parent = workspace
				-- task.delay(0.2, function() -- Line 124
					-- --[[ Upvalues[1]:
						-- [1]: clone_4_upvr (readonly)
					-- ]]
					-- clone_4_upvr.CanCollide = true
				-- end)
				-- local var41 = ((clone_4_upvr.Position - Value_upvw_2.PrimaryPart.Position) * Vector3.new(1, 0, 1) + Vector3.new(0, 6, 0)) * clone_4_upvr.Mass
				-- clone_4_upvr:ApplyImpulse(var41 * 10)
				-- clone_4_upvr:ApplyAngularImpulse(Vector3.new(var41.Z, 0, var41.X))
				-- Debris_upvr:AddItem(clone_4_upvr, math.random(2, 3))
			-- end
		-- end
	-- end))
	-- table.insert(tbl_2_upvr, arg1.Stopped:Connect(function() -- Line 134
		-- --[[ Upvalues[1]:
			-- [1]: HumanoidRootPart_upvr (copied, readonly)
		-- ]]
		-- HumanoidRootPart_upvr.Anchored = false
	-- end))
-- end
-- local var44_upvw
-- local var45_upvw
-- local var46_upvw
-- var46_upvw = Humanoid_upvr:WaitForChild("Animator").AnimationPlayed:Connect(function(arg1) -- Line 143
	-- --[[ Upvalues[3]:
		-- [1]: var44_upvw (read and write)
		-- [2]: var45_upvw (read and write)
		-- [3]: var46_upvw (read and write)
	-- ]]
	-- if arg1.Priority == Enum.AnimationPriority.Action3 then
		-- var44_upvw = arg1
	-- elseif arg1.Priority == Enum.AnimationPriority.Action4 then
		-- var45_upvw = arg1
	-- end
	-- if var45_upvw and var44_upvw then
		-- var46_upvw:Disconnect()
		-- script.Parent.SendTrack:FireServer()
		-- setBarrier()
		-- connectMarkers(var45_upvw)
		-- connectMarkers(var44_upvw)
	-- end
-- end)
-- local var47_upvw = false
-- local var48_upvw = false
-- local OverlapParams_new_result1_upvr = OverlapParams.new()
-- local tbl = {workspace.Map, Parent_upvr}
-- OverlapParams_new_result1_upvr.FilterDescendantsInstances = tbl
-- tbl = false
-- local var51_upvw = tbl
-- local Gamepasses = LocalPlayer_upvr:WaitForChild("Gamepasses")
-- local Eat_Players_upvw = Gamepasses:FindFirstChild("Eat Players")
-- if Eat_Players_upvw then
	-- var51_upvw = Eat_Players_upvw.Value
	-- if not var51_upvw then
		-- Eat_Players_upvw.Changed:Once(function(arg1) -- Line 178
			-- --[[ Upvalues[1]:
				-- [1]: var51_upvw (read and write)
			-- ]]
			-- var51_upvw = arg1
		-- end)
		-- -- KONSTANTWARNING: GOTO [249] #178
	-- end
-- else
	-- local var56_upvw
	-- var56_upvw = Gamepasses.ChildAdded:Connect(function(arg1) -- Line 184
		-- --[[ Upvalues[3]:
			-- [1]: var56_upvw (read and write)
			-- [2]: Eat_Players_upvw (read and write)
			-- [3]: var51_upvw (read and write)
		-- ]]
		-- if arg1.Name == "Eat Players" then
			-- var56_upvw:Disconnect()
			-- Eat_Players_upvw = arg1
			-- var51_upvw = Eat_Players_upvw.Value
			-- if not var51_upvw then
				-- Eat_Players_upvw.Changed:Once(function(arg1_3) -- Line 190
					-- --[[ Upvalues[1]:
						-- [1]: var51_upvw (copied, read and write)
					-- ]]
					-- var51_upvw = arg1_3
				-- end)
			-- end
		-- end
	-- end)
-- end
-- local tbl_upvr = {
	-- Grab = function(arg1) -- Line 199, Named "Grab"
		-- --[[ Upvalues[7]:
			-- [1]: var48_upvw (read and write)
			-- [2]: var51_upvw (read and write)
			-- [3]: Part_upvr_2 (readonly)
			-- [4]: HumanoidRootPart_upvr (readonly)
			-- [5]: Humanoid_upvr (readonly)
			-- [6]: OverlapParams_new_result1_upvr (readonly)
			-- [7]: var47_upvw (read and write)
		-- ]]
		-- -- KONSTANTERROR: [0] 1. Error Block 1 start (CF ANALYSIS FAILED)
		-- local var60 = var48_upvw
		-- -- KONSTANTERROR: [0] 1. Error Block 1 end (CF ANALYSIS FAILED)
		-- -- KONSTANTERROR: [118] 85. Error Block 16 start (CF ANALYSIS FAILED)
		-- -- KONSTANTWARNING: Failed to evaluate expression, replaced with nil [120.2]
		-- arg1:FireServer(var47_upvw, var60, nil)
		-- -- KONSTANTERROR: [118] 85. Error Block 16 end (CF ANALYSIS FAILED)
		-- -- KONSTANTERROR: [124] 90. Error Block 15 start (CF ANALYSIS FAILED)
		-- -- KONSTANTERROR: [124] 90. Error Block 15 end (CF ANALYSIS FAILED)
	-- end;
	-- Eat = function(arg1) -- Line 231, Named "Eat"
		-- --[[ Upvalues[1]:
			-- [1]: var16_upvw (read and write)
		-- ]]
		-- var16_upvw = 0
		-- arg1:FireServer()
	-- end;
	-- Throw = function(arg1) -- Line 235, Named "Throw"
		-- --[[ Upvalues[2]:
			-- [1]: CurrentChunk_upvr (readonly)
			-- [2]: UserGameSettings_upvr (readonly)
		-- ]]
		-- if CurrentChunk_upvr.Value and (not CurrentChunk_upvr.Value:FindFirstChild("Size") or CurrentChunk_upvr.Value:FindFirstChild("Humanoid")) then
			-- UserGameSettings_upvr.RotationType = Enum.RotationType.CameraRelative
		-- end
		-- arg1:FireServer()
	-- end;
-- }
-- local var62_upvw
-- CurrentChunk_upvr.Changed:Connect(function(arg1) -- Line 245
	-- --[[ Upvalues[7]:
		-- [1]: UserGameSettings_upvr (readonly)
		-- [2]: var62_upvw (read and write)
		-- [3]: var28_upvw (read and write)
		-- [4]: var16_upvw (read and write)
		-- [5]: Value_upvw_2 (read and write)
		-- [6]: Debris_upvr (readonly)
		-- [7]: var26_upvw (read and write)
	-- ]]
	-- UserGameSettings_upvr.RotationType = Enum.RotationType.MovementRelative
	-- if var62_upvw then
		-- var62_upvw:Disconnect()
	-- end
	-- if not arg1 then
	-- else
		-- if not var28_upvw then return end
		-- var16_upvw = 0
		-- Value_upvw_2 = arg1
		-- local var63_upvw
		-- if Value_upvw_2:FindFirstChild("PullParticles") and 2 < #Value_upvw_2.PullParticles:GetChildren() then
			-- var63_upvw = 2
		-- end
		-- if Value_upvw_2.Name ~= "TemplateChunk" then
			-- print("found humanoid!")
			-- var62_upvw = Value_upvw_2.ChildRemoved:Connect(function(arg1_4) -- Line 260
				-- --[[ Upvalues[3]:
					-- [1]: var16_upvw (copied, read and write)
					-- [2]: Value_upvw_2 (copied, read and write)
					-- [3]: Debris_upvr (copied, readonly)
				-- ]]
				-- if 15 < var16_upvw then
				-- else
					-- var16_upvw += 1
					-- if not arg1_4:IsA("BasePart") then return end
					-- if not Value_upvw_2.PrimaryPart then return end
					-- local Part_upvr = Instance.new("Part")
					-- Part_upvr.Size = arg1_4.Size
					-- Part_upvr.Color = arg1_4.Color
					-- Part_upvr.Parent = workspace
					-- Part_upvr.CFrame = arg1_4.CFrame
					-- Part_upvr.Transparency = 0
					-- Debris_upvr:AddItem(Part_upvr, math.random(2, 3))
					-- local clone_3 = game.ReplicatedStorage.BiteParticle:Clone()
					-- Part_upvr.Orientation = Vector3.new(0, 0, 0)
					-- clone_3.Parent = Part_upvr
					-- clone_3.Color = ColorSequence.new(Part_upvr.Color)
					-- clone_3:Emit(7)
					-- Part_upvr.Size /= 2
					-- Part_upvr.CanCollide = false
					-- Part_upvr.CanQuery = false
					-- Part_upvr.CanTouch = false
					-- task.delay(0.2, function() -- Line 287
						-- --[[ Upvalues[1]:
							-- [1]: Part_upvr (readonly)
						-- ]]
						-- Part_upvr.CanCollide = true
					-- end)
					-- local var68 = ((Part_upvr.Position - Value_upvw_2.PrimaryPart.Position) * Vector3.new(1, 0, 1) + Vector3.new(0, 7, 0)) * Part_upvr.Mass
					-- Part_upvr:ApplyImpulse(var68 * 5)
					-- Part_upvr:ApplyAngularImpulse(Vector3.new(var68.Z, 0, var68.X))
				-- end
			-- end)
			-- return
		-- end
		-- var62_upvw = Value_upvw_2.DescendantRemoving:Connect(function(arg1_5) -- Line 297
			-- --[[ Upvalues[5]:
				-- [1]: var16_upvw (copied, read and write)
				-- [2]: var26_upvw (copied, read and write)
				-- [3]: Value_upvw_2 (copied, read and write)
				-- [4]: Debris_upvr (copied, readonly)
				-- [5]: var63_upvw (read and write)
			-- ]]
			-- if not arg1_5:IsA("BasePart") then
			-- else
				-- if var26_upvw < var16_upvw then return end
				-- var16_upvw += 1
				-- local clone_2_upvr = arg1_5:Clone()
				-- clone_2_upvr.Parent = workspace
				-- Debris_upvr:AddItem(clone_2_upvr, math.random(2, 3))
				-- if 0.5 < math.random() and 1 < var63_upvw then
					-- clone_2_upvr:ClearAllChildren()
					-- clone_2_upvr.Size /= 2
					-- task.delay(0.2, function() -- Line 316
						-- --[[ Upvalues[1]:
							-- [1]: clone_2_upvr (readonly)
						-- ]]
						-- clone_2_upvr.CanCollide = true
					-- end)
					-- local var72 = ((clone_2_upvr.Position - Value_upvw_2.PrimaryPart.Position) * Vector3.new(1, 0, 1) + Vector3.new(0, 7, 0)) * clone_2_upvr.Mass
					-- clone_2_upvr:ApplyImpulse(var72 * 5)
					-- clone_2_upvr:ApplyAngularImpulse(Vector3.new(var72.Z, 0, var72.X))
					-- return
				-- end
				-- clone_2_upvr.Transparency = 1
				-- if 0.5 >= math.random() then
				-- else
				-- end
				-- local clone = game.ReplicatedStorage.BiteParticle:Clone()
				-- clone_2_upvr.Orientation = Vector3.new(0, 0, 0)
				-- clone.Parent = clone_2_upvr
				-- clone.Color = ColorSequence.new(clone_2_upvr.Color)
				-- clone:Emit(10)
			-- end
		-- end)
	-- end
-- end)
-- function initEvent(arg1) -- Line 345
	-- --[[ Upvalues[2]:
		-- [1]: tbl_upvr (readonly)
		-- [2]: tbl_2_upvr (readonly)
	-- ]]
	-- local SOME_upvr = script.Parent.Events:FindFirstChild(arg1.Name)
	-- if SOME_upvr then
		-- local var75_upvr = tbl_upvr[arg1.Name]
		-- local var76
		-- if var75_upvr then
			-- var76 = arg1.Event:Connect(function() -- Line 351
				-- --[[ Upvalues[2]:
					-- [1]: var75_upvr (readonly)
					-- [2]: SOME_upvr (readonly)
				-- ]]
				-- var75_upvr(SOME_upvr)
			-- end)
		-- else
			-- var76 = arg1.Event:Connect(function() -- Line 356
				-- --[[ Upvalues[1]:
					-- [1]: SOME_upvr (readonly)
				-- ]]
				-- SOME_upvr:FireServer()
			-- end)
		-- end
		-- table.insert(tbl_2_upvr, var76)
	-- end
-- end
-- for _, v in ipairs(game.ReplicatedStorage.LocalEvents:GetChildren()) do
	-- initEvent(v)
-- end
-- game.ReplicatedStorage.LocalEvents.ChildAdded:Connect(initEvent)
-- local RaycastParams_new_result1_upvr = RaycastParams.new()
-- RaycastParams_new_result1_upvr.FilterType = Enum.RaycastFilterType.Whitelist
-- RaycastParams_new_result1_upvr.FilterDescendantsInstances = {workspace.Map}
-- local OverlapParams_new_result1_upvr_2 = OverlapParams.new()
-- OverlapParams_new_result1_upvr_2.FilterType = Enum.RaycastFilterType.Whitelist
-- OverlapParams_new_result1_upvr_2.FilterDescendantsInstances = {workspace.Map}
-- local Loading_upvw = workspace:FindFirstChild("Loading")
-- local MapTime_upvr = game.ReplicatedStorage.ServerSettings.MapTime
-- workspace.ChildAdded:Connect(function(arg1) -- Line 378
	-- --[[ Upvalues[2]:
		-- [1]: MapTime_upvr (readonly)
		-- [2]: Loading_upvw (read and write)
	-- ]]
	-- if arg1.Name == "Loading" then
		-- wait(MapTime_upvr.Value + 2)
		-- Loading_upvw = arg1
	-- end
-- end)
-- local Value_upvw = game.ReplicatedStorage.ServerSettings.MapDuration.Value
-- game.ReplicatedStorage.ServerSettings.MapDuration.Changed:Connect(function(arg1) -- Line 385
	-- --[[ Upvalues[1]:
		-- [1]: Value_upvw (read and write)
	-- ]]
	-- Value_upvw = arg1
-- end)
-- local var91_upvw = 100
-- local var92_upvw = 100
-- function updateMap(arg1) -- Line 393
	-- --[[ Upvalues[2]:
		-- [1]: var91_upvw (read and write)
		-- [2]: var92_upvw (read and write)
	-- ]]
	-- local Bedrock = workspace.Map:WaitForChild("Bedrock", 10)
	-- if Bedrock then
		-- var91_upvw = Bedrock.Size.X / 2
		-- var92_upvw = Bedrock.Size.Z / 2
	-- end
-- end
-- game.ReplicatedStorage.ServerSettings.MapName.Changed:Connect(updateMap)
-- local var95_upvw
-- game.ReplicatedStorage.ServerSettings.MapTime.Changed:Connect(function(arg1) -- Line 406
	-- --[[ Upvalues[5]:
		-- [1]: var95_upvw (read and write)
		-- [2]: HumanoidRootPart_upvr (readonly)
		-- [3]: Value_upvw (read and write)
		-- [4]: var91_upvw (read and write)
		-- [5]: var92_upvw (read and write)
	-- ]]
	-- var95_upvw = arg1
	-- if HumanoidRootPart_upvr.Position.Y < 0 and (Value_upvw - 15 < arg1 or math.abs(HumanoidRootPart_upvr.Position.X) < var91_upvw and math.abs(HumanoidRootPart_upvr.Position.Z) < var92_upvw) then
		-- HumanoidRootPart_upvr.CFrame = CFrame.new(Vector3.new(0, 100, 0))
	-- end
-- end)
-- local any_Connect_result1_upvw = game["Run Service"].Heartbeat:Connect(function() -- Line 419
	-- --[[ Upvalues[8]:
		-- [1]: Humanoid_upvr (readonly)
		-- [2]: var48_upvw (read and write)
		-- [3]: Part_upvr_2 (readonly)
		-- [4]: RaycastParams_new_result1_upvr (readonly)
		-- [5]: OverlapParams_new_result1_upvr_2 (readonly)
		-- [6]: var47_upvw (read and write)
		-- [7]: HumanoidRootPart_upvr (readonly)
		-- [8]: Loading_upvw (read and write)
	-- ]]
	-- if Humanoid_upvr:GetState() == Enum.HumanoidStateType.Running then
		-- var48_upvw = true
		-- local workspace_Raycast_result1 = workspace:Raycast(Part_upvr_2.Attachment.WorldPosition, Part_upvr_2.CFrame.LookVector, RaycastParams_new_result1_upvr)
		-- if workspace_Raycast_result1 then
			-- if #workspace:GetPartBoundsInBox(Part_upvr_2.Attachment.WorldCFrame, Vector3.new(Part_upvr_2.Size.X, Part_upvr_2.Size.Y, 0.1), OverlapParams_new_result1_upvr_2) == 0 then
				-- Part_upvr_2.CanCollide = true
			-- end
			-- if workspace_Raycast_result1.Distance < 0.2 then
				-- var47_upvw = true
				-- -- KONSTANTWARNING: GOTO [79] #57
			-- end
		-- else
			-- var47_upvw = false
		-- end
	-- else
		-- var48_upvw = false
		-- var47_upvw = false
		-- Part_upvr_2.CanCollide = false
	-- end
	-- if 5000 < HumanoidRootPart_upvr.Position.Magnitude then
		-- HumanoidRootPart_upvr.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		-- HumanoidRootPart_upvr.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		-- HumanoidRootPart_upvr.CFrame = CFrame.new(0, 300, 0)
	-- end
	-- if not Loading_upvw then
	-- else
		-- if not Loading_upvw.Parent then return end
		-- if HumanoidRootPart_upvr.Position.Y < Loading_upvw.Position.Y then
			-- HumanoidRootPart_upvr.CFrame = CFrame.new(Vector3.new(Loading_upvw.Position.X, Loading_upvw.Position.Y + HumanoidRootPart_upvr.Size.Y + Humanoid_upvr.HipHeight, Loading_upvw.Position.Z))
		-- end
	-- end
-- end)
-- function disconnect() -- Line 455
	-- --[[ Upvalues[3]:
		-- [1]: var46_upvw (read and write)
		-- [2]: any_Connect_result1_upvw (read and write)
		-- [3]: tbl_2_upvr (readonly)
	-- ]]
	-- if var46_upvw then
		-- var46_upvw:Disconnect()
	-- end
	-- if any_Connect_result1_upvw then
		-- any_Connect_result1_upvw:Disconnect()
	-- end
	-- for _, v_2 in ipairs(tbl_2_upvr) do
		-- if v_2 then
			-- v_2:Disconnect()
		-- end
	-- end
-- end
-- Humanoid_upvr.Died:Connect(disconnect)
-- Parent_upvr.LowerTorso.ChildAdded:Connect(function(arg1) -- Line 473
	-- --[[ Upvalues[1]:
		-- [1]: HumanoidRootPart_upvr (readonly)
	-- ]]
	-- if arg1:IsA("BallSocketConstraint") then
		-- HumanoidRootPart_upvr.Anchored = false
	-- end
-- end)
-- Parent_upvr.AncestryChanged:Connect(function() -- Line 479
	-- --[[ Upvalues[1]:
		-- [1]: Parent_upvr (readonly)
	-- ]]
	-- if Parent_upvr.Parent ~= workspace then
		-- disconnect()
	-- end
-- end)
-- game.ReplicatedStorage.Events.Teleport.OnClientEvent:Connect(function(arg1) -- Line 485
	-- --[[ Upvalues[1]:
		-- [1]: HumanoidRootPart_upvr (readonly)
	-- ]]
	-- if not arg1 or not HumanoidRootPart_upvr then
	-- else
		-- HumanoidRootPart_upvr.CFrame = arg1
	-- end
-- end)
