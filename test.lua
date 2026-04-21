local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId

local reconnecting = false
local RETRY_DELAY = 5
local SAME_SERVER_ATTEMPTS = 2

local function reconnectWithFallback()
	if reconnecting then
		return
	end
	reconnecting = true

	local sameServerAttempts = 0

	while reconnecting do
		local ok, err

		if sameServerAttempts < SAME_SERVER_ATTEMPTS then
			sameServerAttempts = sameServerAttempts + 1
			ok, err = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
			end)
			if not ok then
				warn("[AutoReconnect] Same-server teleport failed:", err)
			end
		end

		if not ok then
			ok, err = pcall(function()
				TeleportService:Teleport(placeId, player)
			end)
			if not ok then
				warn("[AutoReconnect] Fallback teleport failed:", err)
			end
		end

		if ok then
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
		reconnectWithFallback()
	end
end)
