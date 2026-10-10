--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local ENUMS = require(Modules.Data.ENUMS)

-- Module
local mod = {}

-- Types
-- A normal path, can a string or an array of strings
export type Path = string | { string }

-- Logger
export type LoggerMod = {
	new: (instanceName: string) -> Logger,
}

export type Logger = {
	print: (...any) -> (),
	warn: (...any) -> (),
	error: (...any) -> (),

	instanceName: string,
}

-- Signal Manager
export type SignalManager = {
	getSignal: (name: string) -> Signal?,
	fireSignal: (name: string, ...any) -> (),
	connectToSignal: (name: string, listener: (...any) -> ()) -> RBXScriptConnection?,

	isRegistered: (name: string) -> boolean,

	cleanSignal: (name: string) -> (),
	destroySignal: (name: string) -> (),
}
export type Signal = {
	Connect: (self: Signal, listener: (...any) -> ()) -> RBXScriptConnection,
	Fire: (self: Signal, ...any) -> (),
	DisconnectAll: (self: Signal) -> (),
	Destroy: (self: Signal) -> (),
}

-- Rule Engine Types
-- DataPath | CachePath | Value | Now — Type of operation on the condition params
export type ParamOpType = ENUMS.ParamOpTypeValue -- Custom Enum

-- == | ~= | > | >= | < | <= — Equality Operations
export type ConditionOpType = ENUMS.ConditionOpTypeValue -- Custom Enum

-- Increment | Decrement | Set | FireSignal — The Reward data manipulation operation type
export type RewardOpType = ENUMS.RewardOpTypeValue -- Custom Enum

-- Server | Client | Both — What environment this rule can be evaluated on
export type ContextType = ENUMS.ContextTypeValue -- Custom Enum

-- A table that contains the evaluation and reward data
export type RuleData = {
	-- Where this rule must be evaluated — Server, Client or Both
	context: ContextType,
	-- A table of conditions—or a function—to evluate.
	conditions: ({ Condition } | ((Player) -> (boolean, string?)))?,
	-- A table of rewards—or a function—to reward if the conditions passed.
	rewards: ({ Reward } | ((Player) -> (boolean, string?)))?,
}

-- any (2, 4, or "Sowrd", can be anything) or a table that has "param" entry
export type Value = any | { param: Param }

-- A paramter is usually used to write/read user data with Data/Cache Services
export type Param = {
	type: ParamOpType,
	path: Path?,
	value: any?,
}

-- A table to compare 2 values against each other
export type Condition = {
	name: string?, -- Condition name to use in the logs

	--[[
        If params were provided instead of normal values, the engine will resolve
        the values before comparsion operation.
    ]]
	value1: Value,
	value2: Value,

	opType: ConditionOpType,
	onFalse: any?, -- Optional value to return or action to take if the condition fails
}

-- A table that contains the reward data
export type Reward = {
	name: string?, -- Reward name to use in the logs

	--[[
        -- Increment | Decrement | Set for quick data manipulation
        -- FireSignal for custom rewards (Giving a tool for example)
    ]]
	opType: RewardOpType,

	-- The value to send, or the param to resolve into a value.
	value: Value,

	--[[
        Path to the signal to fire.
        A system must be listening to this signal to handle giving rewards.
    ]]
	path: Path?,

	-- An array of optional extra paramters to send to the receiving end
	params: { any }?,

	--[[
        Wether to use table.unpack(params) to send as a tuble,
        or just send it as an array to the receiving end
    ]]
	unpackParams: boolean?,
}

-- Rewards
export type GameReward = {
	id: number,
	ruleData: RuleData,
	attributes: { [string]: any },
}

return mod
