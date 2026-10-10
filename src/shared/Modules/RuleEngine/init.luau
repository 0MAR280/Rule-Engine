--!strict
--[=[
    RuleEngine.luau
    A singleton rule engine module for evaluating conditions and applying rewards, inspired by MarketplaceService's internal rule engine.
    Supports context validation (Server/Client/Both) and type-checked rule data.
]=]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)
local ENUMS = require(Modules.Data.ENUMS)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-Module`)

-- References
local Helpers = Modules.RuleEngine.Helpers
local fnCheckContext = require(Helpers.CheckContext)
local fnApplyRewards = require(Helpers.ApplyRewards)
local fnSolveAllConditions = require(Helpers.SolveAllConditions)

-- Variables
local currentContext: ContextType = RunService:IsServer() and ENUMS.ContextTypes.Server or ENUMS.ContextTypes.Client

-- Types
type ContextType = Types.ContextType
type RuleData = Types.RuleData
type RuleEngine = Types.RuleEngine

-- Module
local RuleEngine = {}

-- Public
--[=[
	Check if the rule conditions are satisfied for a player, and if so, apply the rewards.
    Handles context validation and error reporting.
    @param player The player to evaluate the rule against
    @param rule The rule data containing context, conditions, and rewards
    @return boolean indicating if the rule was successfully applied, and an optional error message
]=]
function RuleEngine.checkAndApplyRule(player: Player, rule: RuleData, payload: { [string]: any }?): (boolean, string?)
	local fn = `checkAndApplyRule`

	if not fnCheckContext(rule.context) then
		local msg = `{fn}: Context mismatch. Expected: {rule.context} Current: {currentContext}`
		Logger:warn(msg)
		return false, msg
	end

	local success, err = RuleEngine.checkRules(player, rule, payload)
	if not success then
		return false, `{fn}: {tostring(err)}`
	end

	local pcallSuccess, applied, applyErr = pcall(function(): (boolean, string?)
		return RuleEngine.applyRewards(player, rule)
	end)
	if not pcallSuccess then
		return false, `{fn}: Failed to apply rewards: {tostring(applied)}`
	end
	if applied == false then
		return false, `{fn}: Failed to apply rewards: {tostring(applyErr)}`
	end

	return true
end

--[=[
	Applies the rewards of a rule to a player, ensuring context validity and handling errors gracefully.
    @param player The player to apply the rewards to
    @param rule The rule data containing context, conditions, and rewards
    @return boolean indicating if the rewards were applied successfully, and an optional error message
]=]
function RuleEngine.applyRewards(player: Player, rule: RuleData): (boolean, string?)
	local fn = `applyRewards`

	if not fnCheckContext(rule.context) then
		local msg = `{fn}: Context mismatch. Expected: {rule.context} Current: {currentContext}`
		Logger:warn(msg)
		return false, msg
	end

	if rule.rewards then
		if typeof(rule.rewards) == "function" then
			local rewardResult, rewardMsg
			local success, err = pcall(function()
				rewardResult, rewardMsg = rule.rewards(player)
			end)

			if not success then
				local msg = `{fn}: Failed to apply reward function: {tostring(err)}`
				Logger:warn(msg)
				return false, msg
			end

			if rewardResult == false then
				return false, rewardMsg
			end

			return true
		elseif typeof(rule.rewards) == "table" then
			return fnApplyRewards(player, rule.rewards)
		end
	end

	local msg = `{fn}: No rewards defined for this rule.`
	Logger:print(msg)
	return true, msg
end

--[=[
	Checks if a player satisfies the conditions of a rule, ensuring context validity and handling errors gracefully.
    @param player The player to check the rule against
    @param rule The rule data containing context, conditions, and rewards
    @return boolean indicating if the rule conditions are satisfied, and an optional error message
]=]
function RuleEngine.checkRules(player: Player, rule: RuleData, payload: { [string]: any }?): (boolean, string?)
	local fn = `checkRules`

	if not fnCheckContext(rule.context) then
		local msg = `{fn}: Context mismatch. Expected: {rule.context} Current: {currentContext}`
		Logger:warn(msg)
		return false, msg
	end

	if rule.conditions then
		if typeof(rule.conditions) == "function" then
			local resullt, reason = false, nil

			local success, err = pcall(function()
				resullt, reason = rule.conditions(player)
			end)

			if not success then
				local msg = `{fn}: Failed to check conditions: {tostring(err)}`
				Logger:warn(msg)
				return false, msg
			else
				return resullt, reason
			end
		elseif typeof(rule.conditions) == "table" then
			return fnSolveAllConditions(player, rule.conditions, payload)
		end
	end

	local msg = `{fn}: No conditions defined for this rule.`
	Logger:print(msg)
	return true, msg
end

return RuleEngine :: RuleEngine
