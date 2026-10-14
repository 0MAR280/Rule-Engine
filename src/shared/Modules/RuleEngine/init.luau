--!strict
--[=[
    RuleEngine.luau
    A singleton rule engine module for evaluating conditions and applying rewards.
    Supports context validation (Server/Client/Both) and type-checked rule data.
]=]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

-- Libraries
local Libraries = ReplicatedStorage.Shared.Libraries
local TypeChecker = require(Libraries.TypeChecker)

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
local failureMessage = "Somthing went wrong!"

-- Functions
-- Private
--[=[
	Sift treats empty tables as non-arrays. Empty condition/reward lists are valid.
	@param value any - The value to check
	@return boolean - Whether the value is an array, including empty
]=]
local function isList(value: any): boolean
	if typeof(value) ~= "table" then
		return false
	end

	if next(value) == nil then
		return true
	end

	return Sift.Array.isArray(value)
end

-- Types
type ContextType = Types.ContextType
type RuleEngine = Types.RuleEngine
type RuleData = Types.RuleData

-- Module
local RuleEngine = {}

-- Public
--[=[
	Check if the rule conditions are satisfied for a player, and if so, apply the rewards.
    Handles context validation and error reporting.
	Handles rolling back on case of rewards applying failure
    @param player Player - The player to evaluate the rule against
    @param rule RuleData - The rule data containing context, conditions, and rewards
    @return boolean - Wether the conditions were satisfied
    @return boolean - Wether the rewards were applied
    @return boolean - Wether the rollback was successfull (In case of rewards failure only)
	@return string? - Error message in case of failure
]=]
function RuleEngine.excuteRule(
	player: Player,
	rule: RuleData,
	payload: { [string]: any }?
): (boolean, boolean, boolean?, string?)
	local fn = `excuteRule`

	if not fnCheckContext(rule.context) then
		local msg = `{fn}: Context mismatch. Expected: {rule.context} Current: {currentContext}`
		Logger:warn(msg)

		return false, false, nil, msg
	end

	-- In case of pcall failure, the "conditionsStatisfied" is the error message!
	local conditionsPcallSuccess, conditionsStatisfied, conditionsErr = pcall(function(): (boolean, string?)
		return RuleEngine.checkConditions(player, rule, payload)
	end)

	if not conditionsPcallSuccess then
		local msg1 = `Failed to check conditions!`
		local msg2 = `A runtime error`
		Logger:warn(`{msg1}\n{msg2}: {tostring(conditionsStatisfied)}`)

		return false, false, nil, failureMessage
	elseif not conditionsStatisfied then
		return false, false, nil, conditionsErr
	end

	-- In case of pcall failure, the "rewardsStatisfied" is the error message!
	local rewardsPcallSuccess, rewardsStatisfied, rewardsErr, rewardsFailureIndex = pcall(
		function(): (boolean, string?, number?)
			return RuleEngine.applyRewards(player, rule)
		end
	)

	if typeof(rewardsFailureIndex) == "number" and rewardsFailureIndex > 1 then
		local msg1 = `Applying operation aborted, rewards applied: {(rewardsFailureIndex or 1) - 1}!`
		local msg2 = `Err: {rewardsErr}`
		local msg3 = `Performing a Rollback...`
		Logger:warn(`{fn}: {msg1}\n{msg2}\n{msg3}`)

		-- In case of pcall failure, the "rollbackApplied" is the error message!
		local rollbackPcallSuccess, rollbackApplied, rollbackErr, rollbackFailureIndex = pcall(
			function(): (boolean, string?, number?)
				return RuleEngine.applyRollback(player, rule, rewardsFailureIndex)
			end
		)

		if not rollbackPcallSuccess then
			msg1 = `Failed to apply rollback at index {rollbackFailureIndex}!`
			msg2 = `A runtime error`
			Logger:warn(`{msg1}\n{msg2}: {tostring(rollbackApplied)}`)

			return true, false, false, failureMessage
		elseif not rollbackApplied then
			msg1 = `Failed to apply rollback!`
			msg2 = `A mal ruledata: {tostring(rollbackErr)}`
			Logger:warn(`{fn}: {msg1}\n{msg2}`)

			return true, false, false, failureMessage
		end

		return true, false, true, failureMessage
	end

	if not rewardsPcallSuccess then
		local msg1 = `Failed to apply rewards!`
		local msg2 = `A runtime error`
		Logger:warn(`{msg1}\n{msg2}: {tostring(rewardsStatisfied)}`)

		return true, false, false, failureMessage
	elseif not rewardsStatisfied then
		local msg1 = `Failed to apply rewards!`
		local msg2 = `A mal ruledata: {tostring(rewardsErr)}`
		Logger:warn(`{fn}: {msg1}\n{msg2}`)

		return true, false, false, failureMessage
	end

	return true, true, nil, nil
end

--[=[
	Applies the rewards of a rule to a player.
    @param player Player - The player to apply the rewards to
    @param rule RuleData - The rule data containing context, conditions, and rewards
	@param failureIndex number? - The index from where to start reversing the rewards
    @return boolean - Wether the rewards were applied successfully
	@return string - Optional error message in case of failure
	@return number? - The failed reward index (In case of failure only)
]=]
function RuleEngine.applyRewards(player: Player, rule: RuleData): (boolean, string?, number?)
	local fn = `applyRewards`

	if not fnCheckContext(rule.context) then
		local msg = `{fn}: Context mismatch. Expected: {rule.context} Current: {currentContext}`
		Logger:warn(msg)

		return false, msg, nil
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

				return false, msg, nil
			end

			if rewardResult == false then
				return false, rewardMsg, nil
			end

			return true
		elseif isList(rule.rewards) then
			-- In case of pcall failure, the "rewardsStatisfied" is the error message!
			local rewardsPcallSuccess, rewardsStatisfied, rewardsErr, rewardsFailureIndex = pcall(
				function(): (boolean, string?, number?)
					return fnApplyRewards(player, rule.rewards)
				end
			)

			if not rewardsPcallSuccess then
				local msg1 = `Failed to apply rewards!`
				local msg2 = `A runtime error`
				Logger:warn(`{msg1}\n{msg2}: {tostring(rewardsStatisfied)}`)

				return false, failureMessage, rewardsFailureIndex
			elseif not rewardsStatisfied then
				local msg1 = `Failed to apply rewards!`
				local msg2 = `A mal ruledata`
				Logger:warn(`{fn}: {msg1}\n{msg2}: : {tostring(rewardsErr)}`)

				return false, failureMessage, rewardsFailureIndex
			end

			return true, nil, nil
		else
			local msg =
				`rule.rewards is expected as a "function" or an array, got: {TypeChecker.getType(rule.rewards)}!`
			Logger:warn(`{fn}: {msg}`)

			return false, msg, nil
		end
	end

	local msg = `{fn}: No rewards were defined for this rule.`
	Logger:print(msg)

	return true, msg, nil
end

--[=[
	Reverse the applied rewards to a player
    @param player Player - The player to apply the rewards to
    @param rule RuleData - The rule data containing context, conditions, and rewards
	@param failureIndex number? - The index from where to start reversing the rewards
    @return boolean - Wether the rewards were applied successfully
	@return string - Optional error message in case of failure
	@return number? - The failed reward index (In case of failure only)
]=]
function RuleEngine.applyRollback(player: Player, rule: RuleData, failureIndex: number?): (boolean, string?, number?)
	local fn = `applyRollback`

	if not fnCheckContext(rule.context) then
		local msg = `{fn}: Context mismatch. Expected: {rule.context} Current: {currentContext}`
		Logger:warn(msg)

		return false, msg, nil
	end

	if rule.rollbackRewards then
		if typeof(rule.rollbackRewards) == "function" then
			local rewardResult, rewardMsg
			local success, err = pcall(function()
				rewardResult, rewardMsg = rule.rollbackRewards(player)
			end)

			if not success then
				local msg = `{fn}: Failed to apply reward reverse function: {tostring(err)}`
				Logger:warn(msg)

				return false, msg, nil
			end

			if rewardResult == false then
				return false, rewardMsg
			end

			return true
		elseif isList(rule.rollbackRewards) then
			-- In case of pcall failure, the "rollbackStatisfied" is the error message!
			local rollbackPcallSuccess, rollbackStatisfied, rollbackErr, rewardsFailureIndex = pcall(
				function(): (boolean, string?, number?)
					return fnApplyRewards(player, rule.rollbackRewards, failureIndex)
				end
			)

			if not rollbackPcallSuccess then
				local msg1 = `Failed to apply rewards rollback!`
				local msg2 = `A runtime error`
				Logger:warn(`{msg1}\n{msg2}: {tostring(rollbackStatisfied)}`)

				return false, failureMessage, rewardsFailureIndex
			elseif not rollbackStatisfied then
				local msg1 = `Failed to apply rewards rollback!`
				local msg2 = `A mal ruledata: {tostring(rollbackErr)}`
				Logger:warn(`{fn}: {msg1}\n{msg2}`)

				return false, failureMessage, rewardsFailureIndex
			end

			return true, nil, nil
		else
			local msg = `rule.rollbackRewards is expected as a "function" or an array, got: {TypeChecker.getType(
				rule.rollbackRewards
			)}!`
			Logger:warn(`{fn}: {msg}`)

			return false, msg, nil
		end
	end

	local msg = `{fn}: No rollbackRewards were defined for this rule.`
	Logger:print(msg)

	return true, msg, nil
end

--[=[
	Checks if a player satisfies the conditions of a rule.
    @param player Player - The player to apply the rewards to
    @param rule RuleData - The rule data containing context, conditions, and rewards
	@param failureIndex number? - The index from where to start reversing the rewards
    @return boolean - Wether the conditions were satisfied
	@return string - Optional error message in case of failure
]=]
function RuleEngine.checkConditions(player: Player, rule: RuleData, payload: { [string]: any }?): (boolean, string?)
	local fn = `checkConditions`

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
		elseif isList(rule.conditions) then
			-- In case of pcall failure, the "conditionsStatisfied" is the error message!
			local conditionsPcallSuccess, conditionsStatisfied, conditionsErr = pcall(function(): (boolean, string?)
				return fnSolveAllConditions(player, rule.conditions, payload)
			end)

			if not conditionsPcallSuccess then
				local msg1 = `Failed to check conditions!`
				local msg2 = `A runtime error`
				Logger:warn(`{msg1}\n{msg2}: {tostring(conditionsStatisfied)}`)

				return false, failureMessage
			elseif not conditionsStatisfied then
				return false, conditionsErr
			end

			return true, nil
		else
			local msg =
				`rule.conditions is expected as a "function" or an array, got: {TypeChecker.getType(rule.conditions)}!`
			Logger:warn(`{fn}: {msg}`)

			return false, msg
		end
	end

	local msg = `{fn}: No conditions were defined for this rule.`
	Logger:print(msg)

	return true, msg
end

return RuleEngine :: RuleEngine
