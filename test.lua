local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId

local reconnecting = false
local RETRY_DELAY = 5
local SAME_SERVER_ATTEMPTS = 2
local INDICATOR_PADDING_RIGHT = 16
local INDICATOR_PADDING_TOP = 16

local playerGui = player:WaitForChild("PlayerGui")
local indicatorGui = Instance.new("ScreenGui")
indicatorGui.Name = "AutoReconnectIndicator"
indicatorGui.ResetOnSpawn = false
indicatorGui.IgnoreGuiInset = false
indicatorGui.DisplayOrder = 10
indicatorGui.Parent = playerGui

local indicatorLabel = Instance.new("TextLabel")
indicatorLabel.Name = "Status"
indicatorLabel.AnchorPoint = Vector2.new(1, 0)
indicatorLabel.Position = UDim2.new(1, -INDICATOR_PADDING_RIGHT, 0, INDICATOR_PADDING_TOP)
indicatorLabel.Size = UDim2.new(0, 250, 0, 28)
indicatorLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
indicatorLabel.BackgroundTransparency = 0.35
indicatorLabel.BorderSizePixel = 0
indicatorLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
indicatorLabel.TextSize = 16
indicatorLabel.Font = Enum.Font.GothamSemibold
indicatorLabel.TextXAlignment = Enum.TextXAlignment.Center
indicatorLabel.Text = "AutoReconnect: ON"
indicatorLabel.Parent = indicatorGui

local function setIndicator(text, color)
	indicatorLabel.Text = text
	indicatorLabel.TextColor3 = color
end

local function reconnectWithFallback()
	if reconnecting then
		return
	end
	reconnecting = true
	setIndicator("AutoReconnect: reconnecting...", Color3.fromRGB(255, 220, 120))

	local sameServerAttempts = 0

	while reconnecting do
		local ok, err

		if sameServerAttempts < SAME_SERVER_ATTEMPTS then
			sameServerAttempts = sameServerAttempts + 1
			setIndicator("Reconnect attempt: same server", Color3.fromRGB(255, 220, 120))
			ok, err = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
			end)
			if not ok then
				warn("[AutoReconnect] Same-server teleport failed:", err)
			end
		end

		if not ok then
			setIndicator("Reconnect attempt: any server", Color3.fromRGB(255, 180, 120))
			ok, err = pcall(function()
				TeleportService:Teleport(placeId, player)
			end)
			if not ok then
				warn("[AutoReconnect] Fallback teleport failed:", err)
				setIndicator("Reconnect failed, retrying...", Color3.fromRGB(255, 120, 120))
			end
		end

		if ok then
			setIndicator("Reconnect started...", Color3.fromRGB(120, 255, 120))
			return
		end

		task.wait(RETRY_DELAY)
	end
end

GuiService.ErrorMessageChanged:Connect(function(message)
	if not message or message == "" then
		return
	end

	local lower = string.lower(message)

	if string.find(lower, "connection")
		or string.find(lower, "disconnected")
		or string.find(lower, "lost")
		or string.find(lower, "internet")
	then
		setIndicator("Network lost. Reconnecting...", Color3.fromRGB(255, 120, 120))
		reconnectWithFallback()
	end
end)
