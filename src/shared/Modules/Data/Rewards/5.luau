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
local cost = 10 -- Points Charge

local cacheSignal = PATHS.signals.cacheService.server.updatePlayerData

-- Types
type GameReward = Types.GameReward

-- Module
return {
	id = 5,
	ruleData = {
		context = ENUMS.ContextTypes.Server,
		conditions = {
			{
				name = "Points above cost",
				value1 = { param = BALANCES.points },
				value2 = cost,
				opType = ENUMS.ConditionOpTypes.GreaterThan,
				onFalse = `Need more than {cost} Points!`,
			},
		},
		rewards = {
			Shared.cachePayment("points", cost, cacheSignal),
		},
	},
	attributes = {
		name = `Decrement`,
		description = `Spend {cost} Points`,
		color = Color3.fromRGB(255, 120, 80),
	},
} :: GameReward
