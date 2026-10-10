--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local ENUMS = require(Modules.Data.ENUMS)

-- Module
return {
	[ENUMS.ConditionOpTypes.Equal] = require(script.Equal),
	[ENUMS.ConditionOpTypes.NotEqual] = require(script.NotEqual),
	[ENUMS.ConditionOpTypes.GreaterThanOrEqual] = require(script.GreaterThanOrEqual),
	[ENUMS.ConditionOpTypes.GreaterThan] = require(script.GreaterThan),
	[ENUMS.ConditionOpTypes.LessThanOrEqual] = require(script.LessThanOrEqual),
	[ENUMS.ConditionOpTypes.LessThan] = require(script.LessThan),
}
