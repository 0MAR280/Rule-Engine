--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnSolveConditionValue = require(Modules.RuleEngine.Helpers.SolveConditionValue)
local RewardCases = require(Modules.RuleEngine.RewardCases)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-ApplyReward-Module`)

-- Types
type Reward = Types.Reward

-- Function
--[=[
	Applies a single reward, resolving a dynamic value and dispatching to its operation handler.
	@param player Player - The player receiving the reward
	@param reward Reward - The reward data containing the operation, value, and handler parameters
	@return boolean - Whether every reward was applied successfully
	@return string? - The first error if any (In case of failure only)
]=]
local function applyReward(player: Player, reward: Reward): (boolean, string?)
	if typeof(reward) ~= "table" then
		return false, `applyReward: Invalid reward format`
	end

	reward = Sift.Dictionary.copyDeep(reward)
	local opType = reward.opType
	local value = reward.value

	if typeof(value) == "table" then
		reward.value = fnSolveConditionValue(player, value)
	end

	if not RewardCases[opType] then
		local msg = `Unknown operation type {opType} for reward {reward.name}`
		Logger:warn(msg)

		return false, msg
	end

	-- In case of pcall failure, the "rewardSuccess" is the error message!
	local pcallSuccess, rewardSuccess, err = pcall(RewardCases[opType], player, reward)

	table.clear(reward)

	if not pcallSuccess then
		local msg1 = `Failed to apply reward with operation: {tostring(opType)}!`
		local msg2 = `A runtime error`
		Logger:warn(`{msg1}\n{msg2}: {tostring(rewardSuccess)}`)

		return false, msg2
	end

	if not rewardSuccess then
		local msg1 = `Failed to apply reward with operation: {tostring(opType)}!`
		local msg2 = `A mal reward format`
		Logger:warn(`{msg1}\n{msg2}: {tostring(err)}`)

		return false, msg2
	end

	return true
end

return applyReward
