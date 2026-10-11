--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnSolveCondition = require(Modules.RuleEngine.Helpers.SolveCondition)
local Types = require(Modules.Types.Types)

-- Types
type Condition = Types.Condition

-- Function
--[=[
	Evaluates conditions in order, returning on the first condition that fails.
	@param player Player - The player to evaluate the conditions against
	@param conditions { Conditions } - The conditions to evaluate, or nil
	@param payload { [string]: any } Optional event payload for dynamic values
	@return boolean - Whether all conditions are satisfied
	@return string? - The first error if any (In case of failure only)
]=]
local function solveAllConditions(
	player: Player,
	conditions: { Condition }?,
	payload: { [string]: any }?
): (boolean, string?)
	if not conditions then
		return true
	end

	for _, condition in ipairs(conditions) do
		local conditionMet = fnSolveCondition(player, condition, payload)
		if not conditionMet then
			return false, condition.onFalse or `Condition "{condition.name}" is not met`
		end
	end

	return true
end

return solveAllConditions
