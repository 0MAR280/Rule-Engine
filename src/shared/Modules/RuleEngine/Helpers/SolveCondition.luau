--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnSolveConditionValue = require(Modules.RuleEngine.Helpers.SolveConditionValue)
local conditionCases = require(Modules.Math.ConditionCases)
local Types = require(Modules.Types.Types)

-- Types
type Condition = Types.Condition

-- Function
--[=[
	Evaluates a single condition, resolving dynamic values and applying the configured operator.
	@param player The player to evaluate the condition against
	@param condition The condition data containing values and an operator
	@param payload Optional event payload for dynamic values
	@return Whether the condition is satisfied
]=]
local function solveCondition(player: Player, condition: Condition, payload: { [string]: any }?): boolean
	if condition == nil then
		return true
	end

	condition = Sift.Dictionary.copyDeep(condition)

	local value1 = condition.value1
	local value2 = condition.value2
	local opType = condition.opType

	if typeof(value1) == "table" then
		value1 = fnSolveConditionValue(player, value1, payload)
	end
	if typeof(value2) == "table" then
		value2 = fnSolveConditionValue(player, value2, payload)
	end

	local comparator = conditionCases[opType]
	if not comparator then
		return false
	end

	local ok, result = pcall(comparator, value1, value2)
	if not ok then
		return false
	end

	return result == true
end

return solveCondition
