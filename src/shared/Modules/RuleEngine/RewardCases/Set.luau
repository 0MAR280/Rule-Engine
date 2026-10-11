--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

-- Libraries
local Libraries = ReplicatedStorage.Shared.Libraries
local TypeChecker = require(Libraries.TypeChecker)

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local SignalManager = require(Modules.Core.SignalManager)
local fnTraversePath = require(Modules.fn.traversePath)
local fnIsValidPath = require(Modules.fn.isValidPath)
local CommsHub = require(Modules.Core.CommsHub)
local Types = require(Modules.Types.Types)

-- Class
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-Set-Module`)

-- Types
type Reward = Types.Reward

-- Function
--[=[
	Sets a value through the signal addressed by the reward path.
	The first reward parameter must be the target value path; remaining parameters
	are passed to the signal as a tuple when unpackParams is true, or as a table otherwise.
	@param player Player - The player receiving the reward
	@param reward Reward - The reward configuration containing the signal path, decrement amount, and parameters
	@return boolean - Wether the operation was successfull
	@return string? - Error message in case of failure
]=]
local function setReward(player: Player, reward: Reward): (boolean, string?)
	local signalPath = reward.path

	if signalPath then
		local signal = fnTraversePath(CommsHub, signalPath)

		if signal then
			local params = reward.params

			if type(params) ~= "table" then
				local msg = `Expected reward.params to be an array, got: {TypeChecker.getType(params)}!`
				Logger:warn(msg)

				return false, msg
			end

			if next(params) ~= nil and not Sift.Array.isArray(params) then
				local msg = `Expected reward.params to be an array, got: a "dictionary"!`
				Logger:warn(msg)

				return false, msg
			end

			local valuePath = params[1]

			if valuePath == nil or not fnIsValidPath(valuePath) then
				local msg = `Expected at least one path Parameter in reward.params for the target value!`
				Logger:warn(msg)

				return false, msg
			end

			table.remove(params, 1)
			local newValue = reward.value

			if reward.unpackParams then
				SignalManager.fireSignal(signal, player, valuePath, newValue, table.unpack(params))
			else
				SignalManager.fireSignal(signal, player, valuePath, newValue, params)
			end

			return true, nil
		else
			local msg = `Provided signal path is invalid!`
			Logger:warn(msg)

			return false, msg
		end
	else
		local msg = `Signal path is nil!`
		Logger:warn(msg)

		return false, msg
	end
end

return setReward
