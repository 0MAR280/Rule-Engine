--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local BALANCES = require(Modules.Data.BALANCES)
local Types = require(Modules.Types.Types)
local PATHS = require(Modules.Data.PATHS)
local ENUMS = require(Modules.Data.ENUMS)

-- References
local Shared = require(script.Parent._Shared)

-- Variables
local reward = 15 -- Coins Reward
local cap = 100 -- Coins cap

local dataSignal = PATHS.signals.dataService.server.updatePlayerData

-- Types
type GameReward = Types.GameReward

-- Module
return {
	id = 3,
	ruleData = {
		context = ENUMS.ContextTypes.Server,
		conditions = {
			{
				name = "Coins below cap",
				value1 = { param = BALANCES.coins },
				value2 = cap,
				opType = ENUMS.ConditionOpTypes.LessThan,
				onFalse = `Coins cap of {cap} reached!`,
			},
		},
		rewards = {
			Shared.reward("coins", reward, dataSignal),
		},
	},
	attributes = {
		name = `Increment`,
		description = `Get {reward} Coins (cap {cap})`,
		color = Color3.fromRGB(0, 255, 255),
	},
} :: GameReward
