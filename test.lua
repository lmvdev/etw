local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local TARGET_PLACE_ID = 16480898254
local reconnecting = false

local function onErrorMessageChanged(errorMessage)
	if not errorMessage or errorMessage == "" then
		return
	end

	print("Error detected: " .. errorMessage)

	if player and not reconnecting then
		reconnecting = true
		task.wait(1)
		-- TeleportService:Teleport(TARGET_PLACE_ID, player)
		TeleportService:Teleport(game.PlaceId, player)
	end
end

GuiService.ErrorMessageChanged:Connect(onErrorMessageChanged)
