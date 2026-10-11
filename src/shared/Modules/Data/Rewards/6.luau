--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)
local PATHS = require(Modules.Data.PATHS)
local ENUMS = require(Modules.Data.ENUMS)

-- References
local Shared = require(script.Parent._Shared)

-- Variables
local coinsGrant = 25
local pointsGrant = 10

local dataSignal = PATHS.signals.dataService.server.updatePlayerData
local cacheSignal = PATHS.signals.cacheService.server.updatePlayerData

-- Types
type GameReward = Types.GameReward

-- Module
return {
	id = 6,
	ruleData = {
		context = ENUMS.ContextTypes.Server,
		rewards = {
			Shared.reward("coins", coinsGrant, dataSignal),
			Shared.cacheReward("points", pointsGrant, cacheSignal),
			{
				name = "Intentional Failure",
				opType = 999,
				value = 0,
				path = dataSignal,
				params = { PATHS.userData.coins },
			},
		},
		rollbackRewards = {
			Shared.payment("coins", coinsGrant, dataSignal),
			Shared.cachePayment("points", pointsGrant, cacheSignal),
		},
	},
	attributes = {
		name = `Rollback`,
		description = `Grant {coinsGrant} Coins & {pointsGrant} Points, then fail and roll back`,
		color = Color3.fromRGB(200, 80, 255),
	},
} :: GameReward
