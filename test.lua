local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local code = TeleportService:ReserveServerAsync(game.PlaceId)

local players = Players:GetPlayers()

-- TeleportService:TeleportToPrivateServer(game.PlaceId, code, players)

local player = Players.LocalPlayer
local GuiService = game:GetService("GuiService")
local function onErrorMessageChanged(errorMessage)
    if errorMessage and errorMessage ~= "" then
        print("Error detected: " .. errorMessage)

        if player then
            wait()
            TeleportService:Teleport(game.PlaceId, player)
        end
    end
end

GuiService.ErrorMessageChanged:Connect(onErrorMessageChanged)
