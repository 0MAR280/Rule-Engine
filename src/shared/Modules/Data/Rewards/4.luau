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
local coinsCost = 10 -- Coins Charge
local pointsCost = 10 -- Points Charge

local cacheSignal = PATHS.signals.cacheService.server.updatePlayerData
local dataSignal = PATHS.signals.dataService.server.updatePlayerData
local toolSignal = PATHS.signals.toolService.server.giveTool

-- Types
type GameReward = Types.GameReward

-- Module
return {
	id = 4,
	ruleData = {
		context = ENUMS.ContextTypes.Server,
		conditions = {
			{
				name = "Check Coins Balance",
				value1 = { param = BALANCES.coins },
				value2 = coinsCost,
				opType = ENUMS.ConditionOpTypes.GreaterThanOrEqual,
				onFalse = `Not Enough Coins!`,
			},
			{
				name = "Check Points Balance",
				value1 = { param = BALANCES.points },
				value2 = pointsCost,
				opType = ENUMS.ConditionOpTypes.GreaterThanOrEqual,
				onFalse = `Not Enough Points!`,
			},
		},
		rewards = {
			Shared.payment("coins", coinsCost, dataSignal),
			Shared.cachePayment("points", pointsCost, cacheSignal),
			Shared.fireSignal("sword", toolSignal, {
				"Sword", -- Will be received as "toolName"
				"Supppp, This is an extra param!!!", -- Will be received as ...
			}, true),
		},
	},

	attributes = {
		name = `Currency Trade`,
		description = `Get a Sword for {coinsCost} Coins & {pointsCost} Points`,
		color = Color3.fromRGB(0, 255, 150),
	},
} :: GameReward
