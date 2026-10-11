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
local setValue = 50 -- Coins to set

local dataSetSignal = PATHS.signals.dataService.server.setPlayerData

-- Types
type GameReward = Types.GameReward

-- Module
return {
	id = 2,
	ruleData = {
		context = ENUMS.ContextTypes.Server,
		conditions = {
			{
				name = "Coins are not already set",
				value1 = { param = BALANCES.coins },
				value2 = setValue,
				opType = ENUMS.ConditionOpTypes.NotEqual,
				onFalse = `Coins are already {setValue}!`,
			},
		},
		rewards = {
			Shared.set("coins", setValue, dataSetSignal),
		},
	},
	attributes = {
		name = `Set`,
		description = `Set Coins to {setValue}`,
		color = Color3.fromRGB(255, 255, 0),
	},
} :: GameReward
