--!strict
-- Module
local ENUMS = {}

-- Data
local ContextTypes = table.freeze({
	Server = 1,
	Client = 2,
	Both = 3,
})

local ParamOpTypes = table.freeze({
	DataPath = 1,
	CachePath = 2,
	Value = 3,
	Now = 4,
	EventPayload = 5,
})

local ConditionOpTypes = table.freeze({
	Equal = 1,
	NotEqual = 2,
	GreaterThanOrEqual = 3,
	GreaterThan = 4,
	LessThanOrEqual = 5,
	LessThan = 6,
})

local RewardOpTypes = table.freeze({
	Increment = 1,
	Decrement = 2,
	Set = 3,
	FireSignal = 4,
})

-- Types
export type ContextTypesEnum = typeof(ContextTypes)
export type ParamOpTypesEnum = typeof(ParamOpTypes)
export type ConditionOpTypesEnum = typeof(ConditionOpTypes)
export type RewardOpTypesEnum = typeof(RewardOpTypes)

-- Optional: If you want an alias for the values themselves
export type ContextTypeValue = number
export type ParamOpTypeValue = number
export type ConditionOpTypeValue = number
export type RewardOpTypeValue = number

-- Setting
ENUMS.ContextTypes = ContextTypes
ENUMS.ParamOpTypes = ParamOpTypes
ENUMS.ConditionOpTypes = ConditionOpTypes
ENUMS.RewardOpTypes = RewardOpTypes

return ENUMS
