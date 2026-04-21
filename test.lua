local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId

local reconnecting = false
local RETRY_DELAY = 5

local function reconnectToSameServer()
	if reconnecting then
		return
	end
	reconnecting = true

	while reconnecting do
		local ok, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
		end)

		if ok then
			return
		end

		warn("[AutoReconnect] Teleport failed, retrying:", err)
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
		reconnectToSameServer()
	end
end)
