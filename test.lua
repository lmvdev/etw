local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local code = TeleportService:ReserveServerAsync(game.PlaceId)

local players = Players:GetPlayers()

TeleportService:TeleportToPrivateServer(game.PlaceId, code, players)
-- You could add extra arguments to this function: spawnName, teleportData and customLoadingScreen
