--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local SignalManager = require(Modules.Core.SignalManager)
local fnTraversePath = require(Modules.fn.traversePath)
local fnIsValidPath = require(Modules.fn.isValidPath)
local CommsHub = require(Modules.Core.CommsHub)
local Types = require(Modules.Types.Types)

-- Class
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-Increment-Module`)

-- Types
type Reward = Types.Reward

-- Function
--[=[
	Increments a value through the signal addressed by the reward path.
	The first reward parameter must be the target value path; the reward value
	is added to the current value, and remaining parameters are forwarded to the signal.
	@param player Player - The player receiving the reward
	@param reward Reward - The reward configuration containing the signal path, decrement amount, and parameters
	@return nil - Invalid paths or parameters are reported through the logger.
]=]
local function incrementReward(player: Player, reward: Reward): ()
	local fn = `Increment-RewardCase`
	local signalPath = reward.path

	if signalPath then
		local signal = fnTraversePath(CommsHub, signalPath)

		if signal then
			local params = reward.params

			if type(params) ~= "table" then
				Logger:warn(`{fn}: Expected reward.params to be an array!`)
				return
			end

			local valuePath = params[1]

			if not fnIsValidPath(valuePath) then
				Logger:warn(`{fn}: Expected at least one path paramter in reward.params for the target value!`)
				return
			end

			table.remove(params, 1)

			local valueType = type(reward.value)
			local value = 0

			if valueType == "number" then
				value = reward.value :: number
			else
				Logger:warn(`{fn}: Expected reward.value as 'string' but got '{valueType}'!`)
			end

			local newValue = function(currentValue: number): number
				return currentValue + value
			end

			if reward.unpackParams then
				SignalManager.fireSignal(signal, player, valuePath, newValue, table.unpack(params))
			else
				SignalManager.fireSignal(signal, player, valuePath, newValue, params)
			end
		else
			Logger:warn(`{fn}: Provided signal path is invalid!`)
		end
	else
		Logger:warn(`{fn}: Signal path is nil!`)
	end
end

return incrementReward
