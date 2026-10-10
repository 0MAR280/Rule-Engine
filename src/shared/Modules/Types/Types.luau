--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local ENUMS = require(Modules.Data.ENUMS)

-- Module
local mod = {}

-- Types
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
export type ParamOpType = ENUMS.ParamOpTypeValue
export type ConditionOpType = ENUMS.ConditionOpTypeValue
export type RewardOpType = ENUMS.RewardOpTypeValue
export type ContextType = ENUMS.ContextTypeValue
export type Param = {
	type: ParamOpType,
	path: Path?,
	value: any?,
}
export type Value = any | { param: Param }
export type Condition = {
	name: string?,
	value1: any,
	value2: any,
	opType: ConditionOpType,
	onFalse: any?, -- Optional value to return or action to take if the condition fails
}
export type Reward = {
	name: string?,
	opType: RewardOpType,
	value: Value,
	path: Path?,
	params: { any }?,
	unpackParams: boolean?,
}
export type RuleData = {
	context: ContextType,
	conditions: ({ Condition } | ((Player) -> (boolean, string?)))?,
	rewards: ({ Reward } | ((Player) -> (boolean, string?)))?,
}
export type RuleEngine = {
	checkAndApplyRule: (player: Player, rule: RuleData, payload: { [string]: any }?) -> (boolean, string?),
	applyRewards: (player: Player, rule: RuleData) -> (boolean, string?),
	checkRules: (player: Player, rule: RuleData, payload: { [string]: any }?) -> (boolean, string?),
}

-- Rewards
export type GameReward = {
	id: number,
	ruleData: RuleData,
	attributes: { [string]: any },
}

return mod
