-- AutoReconnect Script Version: v1
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId
local privateServerId = game.PrivateServerId
local isPrivateServerSession = privateServerId ~= nil and privateServerId ~= ""

local reconnecting = false
local RETRY_DELAY = 5
local SAME_SERVER_ATTEMPTS = 2
local TELEPORT_RESULT_TIMEOUT = 8
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

local attemptLabel = Instance.new("TextLabel")
attemptLabel.Name = "AttemptStatus"
attemptLabel.AnchorPoint = Vector2.new(1, 0)
attemptLabel.Position = UDim2.new(1, -INDICATOR_PADDING_RIGHT, 0, INDICATOR_PADDING_TOP + 32)
attemptLabel.Size = UDim2.new(0, 250, 0, 24)
attemptLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
attemptLabel.BackgroundTransparency = 0.35
attemptLabel.BorderSizePixel = 0
attemptLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
attemptLabel.TextSize = 14
attemptLabel.Font = Enum.Font.Gotham
attemptLabel.TextXAlignment = Enum.TextXAlignment.Center
attemptLabel.Text = "Waiting for network issues..."
attemptLabel.Parent = indicatorGui

local function setIndicator(text, color, attemptText)
	indicatorLabel.Text = text
	indicatorLabel.TextColor3 = color
	if attemptText ~= nil then
		attemptLabel.Text = attemptText
	end
end

local waitingForTeleportResult = false
local teleportFailedSignal = false

TeleportService.TeleportInitFailed:Connect(function(failedPlayer, teleportResult, errorMessage)
	if failedPlayer ~= player then
		return
	end

	waitingForTeleportResult = false
	teleportFailedSignal = true

	local reason = tostring(errorMessage or teleportResult or "Unknown error")
	warn("[AutoReconnect] Teleport init failed:", reason)
	setIndicator(
		"Reconnect failed, retrying...",
		Color3.fromRGB(255, 120, 120),
		"Teleport failed: " .. reason
	)
end)

local function reconnectWithFallback()
	if reconnecting then
		return
	end
	reconnecting = true
	if isPrivateServerSession then
		setIndicator(
			"AutoReconnect: private server",
			Color3.fromRGB(255, 220, 120),
			"Private mode: reconnect only to this private instance"
		)
	else
		setIndicator("AutoReconnect: reconnecting...", Color3.fromRGB(255, 220, 120), "Preparing reconnect attempts...")
	end

	local sameServerAttempts = 0
	local totalAttempts = 0

	while true do
		local ok, err
		totalAttempts = totalAttempts + 1

		if isPrivateServerSession then
			setIndicator(
				"Reconnect attempt: private server",
				Color3.fromRGB(255, 220, 120),
				"Attempt #" .. tostring(totalAttempts) .. ": joining private ID " .. tostring(privateServerId)
			)
			ok, err = pcall(function()
				TeleportService:TeleportToPrivateServer(placeId, privateServerId, { player })
			end)
			if not ok then
				warn("[AutoReconnect] Private-server teleport failed:", err)
			end
		elseif sameServerAttempts < SAME_SERVER_ATTEMPTS then
			sameServerAttempts = sameServerAttempts + 1
			setIndicator(
				"Reconnect attempt: same server",
				Color3.fromRGB(255, 220, 120),
				"Attempt #" .. tostring(totalAttempts) .. ": trying same server"
			)
			ok, err = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
			end)
			if not ok then
				warn("[AutoReconnect] Same-server teleport failed:", err)
			end
		end

		if not ok and not isPrivateServerSession then
			setIndicator(
				"Reconnect attempt: any server",
				Color3.fromRGB(255, 180, 120),
				"Attempt #" .. tostring(totalAttempts) .. ": fallback to any server"
			)
			ok, err = pcall(function()
				TeleportService:Teleport(placeId, player)
			end)
			if not ok then
				warn("[AutoReconnect] Fallback teleport failed:", err)
				setIndicator(
					"Reconnect failed, retrying...",
					Color3.fromRGB(255, 120, 120),
					"Attempt #" .. tostring(totalAttempts) .. " failed, retry in " .. tostring(RETRY_DELAY) .. "s"
				)
			end
		elseif not ok and isPrivateServerSession then
			setIndicator(
				"Private server reconnect",
				Color3.fromRGB(255, 120, 120),
				"Attempt #" .. tostring(totalAttempts) .. " failed, retry same private ID in " .. tostring(RETRY_DELAY) .. "s"
			)
		end

		if ok then
			teleportFailedSignal = false
			waitingForTeleportResult = true
			setIndicator(
				"Reconnect requested...",
				Color3.fromRGB(120, 255, 120),
				"Teleport request sent on attempt #" .. tostring(totalAttempts) .. ", waiting result..."
			)

			local waitStart = os.clock()
			while waitingForTeleportResult and os.clock() - waitStart < TELEPORT_RESULT_TIMEOUT do
				task.wait(0.2)
			end

			if waitingForTeleportResult then
				waitingForTeleportResult = false
				setIndicator(
					"Reconnect timeout, retrying...",
					Color3.fromRGB(255, 120, 120),
					"No teleport response, retry in " .. tostring(RETRY_DELAY) .. "s"
				)
			elseif not teleportFailedSignal then
				setIndicator(
					"Reconnect in progress...",
					Color3.fromRGB(120, 255, 120),
					"Waiting for server transfer..."
				)
			end
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
		setIndicator("Network lost. Reconnecting...", Color3.fromRGB(255, 120, 120), "Starting infinite reconnect loop...")
		reconnectWithFallback()
	end
end)
