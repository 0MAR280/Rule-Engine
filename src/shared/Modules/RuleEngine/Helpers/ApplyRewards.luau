--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnApplyReward = require(Modules.RuleEngine.Helpers.ApplyReward)
local Types = require(Modules.Types.Types)

-- Types
type Reward = Types.Reward

-- Function
--[=[
	Applies every reward, continuing after individual failures.
	@param player The player receiving the rewards
	@param rewards The rewards to apply, or nil when none are defined
	@return Whether every reward was applied successfully, and the first error if any failed
]=]
local function applyRewards(player: Player, rewards: { Reward }?): (boolean, string?)
	if not rewards then
		return true
	end

	local allSucceeded = true
	local firstError: string? = nil
	for _, reward in ipairs(rewards) do
		local success, err = fnApplyReward(player, reward)
		if not success then
			allSucceeded = false
			firstError = firstError or err
		end
	end

	return allSucceeded, firstError
end

return applyRewards
