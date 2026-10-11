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
	@return boolean - Wether the operation was successfull
	@return string? - Error message in case of failure
]=]
local function fireSignalReward(player: Player, reward: Reward): (boolean, string?)
	local signalPath = reward.path

	if signalPath then
		local signal = fnTraversePath(CommsHub, signalPath)

		if signal then
			local params = reward.params or {}

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

			if reward.unpackParams then
				SignalManager.fireSignal(signal, player, table.unpack(params))
			else
				SignalManager.fireSignal(signal, player, params)
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

return fireSignalReward
