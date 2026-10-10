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
	@param player The player receiving the reward
	@param reward The reward data containing the operation, value, and handler parameters
	@return Whether the reward handler ran successfully, and an optional error message
]=]
local function applyReward(player: Player, reward: Reward): (boolean, string?)
	local fn = `applyReward`

	if typeof(reward) ~= "table" then
		return false, `{fn}: Invalid reward format`
	end

	reward = Sift.Dictionary.copyDeep(reward)
	local opType = reward.opType
	local value = reward.value

	if typeof(value) == "table" then
		reward.value = fnSolveConditionValue(player, value)
	end

	if not RewardCases[opType] then
		local msg = `{fn}: Unknown operation type {opType} for reward {reward.name}`
		Logger:warn(msg)
		return false, msg
	end

	local success, err = pcall(RewardCases[opType], player, reward)

	table.clear(reward)

	if not success then
		local msg = `{fn}: Failed to apply reward {tostring(opType)}: {tostring(err)}`
		Logger:warn(msg)
		return false, msg
	end

	return true
end

return applyReward
