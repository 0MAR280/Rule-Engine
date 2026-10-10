--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local SignalManager = require(Modules.Core.SignalManager)
local fnTraversePath = require(Modules.fn.traversePath)
local CommsHub = require(Modules.Core.CommsHub)
local Types = require(Modules.Types.Types)

-- Class
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-FireSignal-Module`)

-- Types
type Reward = Types.Reward

-- Function
--[=[
	Fires the signal addressed by the reward path for the player.
	Passes reward parameters as a tuple when unpackParams is true, or as a table otherwise.
	@param player Player - The player receiving the reward
	@param reward Reward - The reward configuration containing the signal path, decrement amount, and parameters
	@return nil - Invalid paths or parameters are reported through the logger.
]=]
local function fireSignalReward(player: Player, reward: Reward): ()
	local fn = `FireSignal-RewardCase`
	local signalPath = reward.path

	if signalPath then
		local signal = fnTraversePath(CommsHub, signalPath)

		if signal then
			local params = reward.params or {}

			if reward.unpackParams then
				SignalManager.fireSignal(signal, player, table.unpack(params))
			else
				SignalManager.fireSignal(signal, player, params)
			end
		else
			Logger:warn(`{fn}: Provided signal path is invalid!`)
		end
	else
		Logger:warn(`{fn}: Signal path is nil!`)
	end
end

return fireSignalReward
