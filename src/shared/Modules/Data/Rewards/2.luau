--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)
local PATHS = require(Modules.Data.PATHS)

-- References
local Shared = require(script.Parent._Shared)

-- Variables
local cost = 10 -- Points Charge
local reward = 10 -- Coins Reward

local cacheSignal = PATHS.signals.cacheService.server.updatePlayerData
local dataSignal = PATHS.signals.dataService.server.updatePlayerData

-- Types
type GameReward = Types.GameReward

-- Module
return {
	id = 2,
	ruleData = Shared.balanceRule("points", cost, {
		Shared.cachePayment("points", cost, cacheSignal),
		Shared.reward("coins", reward, dataSignal),
	}),
	attributes = {
		name = `Currency Trade`,
		description = `Get {reward} Coins for {cost} Points`,
		color = Color3.fromRGB(255, 255, 0),
	},
} :: GameReward
