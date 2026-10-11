--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnApplyReward = require(Modules.RuleEngine.Helpers.ApplyReward)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-ApplyRewards-Module`)

-- Types
type Reward = Types.Reward

-- Function
--[=[
	Applies every reward, aborting operations on the first failure.
	@param player Player - The player receiving the rewards
	@param rewards { Reward }? - The rewards to apply, or nil when none are defined
	@param stopIndex number? - What index to stop at (Wont be applied)
	@return boolean - Whether every reward was applied successfully
	@return string? - The first error if any (In case of failure only)
	@return number? - The failed reward index (In case of failure only)
]=]
local function applyRewards(player: Player, rewards: { Reward }?, stopIndex: number?): (boolean, string?, number?)
	if not rewards then
		return true, nil, nil
	end

	local allSucceeded = true
	local firstError: string? = nil

	local operationIndex = 1
	local rewardName = "Unknown"

	if typeof(stopIndex) ~= "number" then
		stopIndex = #rewards + 1
	end

	for index, reward in ipairs(rewards) do
		if index == stopIndex then
			break
		end

		local success, err = fnApplyReward(player, reward)
		if not success then
			allSucceeded = false
			firstError = firstError or err

			operationIndex = index
			rewardName = reward.name or "Unknown"

			break
		end
	end

	if not allSucceeded then
		local msg1 = `Reward "{rewardName}" No. {operationIndex} has failed!`
		local msg2 = `Err: {firstError}.`
		Logger:warn(`{msg1}\n{msg2}`)
	end

	return allSucceeded, firstError, operationIndex
end

return applyRewards
