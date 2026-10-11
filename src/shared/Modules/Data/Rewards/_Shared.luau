--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local BALANCES = require(Modules.Data.BALANCES)
local Types = require(Modules.Types.Types)
local PATHS = require(Modules.Data.PATHS)
local ENUMS = require(Modules.Data.ENUMS)

-- References
local userDataPaths = PATHS.userData
local userCachePaths = PATHS.userCache

-- Types
type Path = Types.Path
type RuleData = Types.RuleData
type Condition = Types.Condition
type Reward = Types.Reward

-- Module
local Shared = {}

-- Functions
-- Public
--[=[
	Builds the common server-side balance validation rule for a product.
	@param currency string - The currency required by the product
	@param price number - The amount of currency required by the product
	@param rewards { Reward } - The rewards to apply after validation succeeds
	@return RuleData - The server-side balance validation rule
]=]
function Shared.balanceRule(currency: string, price: number, rewards: { Reward }): RuleData
	return {
		context = ENUMS.ContextTypes.Server,
		conditions = {
			{
				name = "Check Balance",
				value1 = { param = BALANCES[currency] },
				value2 = price,
				opType = ENUMS.ConditionOpTypes.GreaterThanOrEqual,
				onFalse = `Not Enough {currency}!`,
			} :: Condition,
		},
		rewards = rewards,
	}
end

--[=[
	Builds the reward that charges the player in the selected currency.
	@param currency string - The currency to charge
	@param price number - The amount to charge
	@param path Path - The signal path relative to CommsHub
	@return Reward - The currency payment reward
]=]
function Shared.payment(currency: string, price: number, path: Path): Reward
	return {
		name = "Payment",
		path = path,
		value = price,
		opType = ENUMS.RewardOpTypes.Decrement,
		params = {
			userDataPaths[currency],
		},
	}
end

--[=[
	Builds the reward that charges the player in the selected currency (Cache Profile).
	@param currency string - The currency to charge
	@param price number - The amount to charge
	@param path Path - The signal path relative to CommsHub
	@return Reward - The currency payment reward
]=]
function Shared.cachePayment(currency: string, price: number, path: Path): Reward
	return {
		name = "Payment",
		path = path,
		value = price,
		opType = ENUMS.RewardOpTypes.Decrement,
		params = {
			userCachePaths[currency],
		},
	}
end

--[=[
	Builds the reward that rewards the player in the selected currency.
	@param currency string - The currency to reward
	@param price number - The amount to reward
	@param path Path - The signal path relative to CommsHub
	@return Reward - The currency reward
]=]
function Shared.reward(currency: string, price: number, path: Path): Reward
	return {
		name = "Reward",
		path = path,
		value = price,
		opType = ENUMS.RewardOpTypes.Increment,
		params = {
			userDataPaths[currency],
		},
	}
end

--[=[
	Builds the reward that rewards the player in the selected currency (Cache Profile).
	@param currency string - The currency to reward
	@param price number - The amount to reward
	@param path Path - The signal path relative to CommsHub
	@return Reward - The currency reward
]=]
function Shared.cacheReward(currency: string, price: number, path: Path): Reward
	return {
		name = "Reward",
		path = path,
		value = price,
		opType = ENUMS.RewardOpTypes.Increment,
		params = {
			userCachePaths[currency],
		},
	}
end

--[=[
	Builds a signal reward.
	@param rewardName string - The reward name
	@param path Path - The signal path relative to CommsHub
	@param signalParams { any } - An array of params to provide to the signal callback
	@param unpackParams boolean - Wether the engine will unpack the params array or not
	@return Reward - The signal reward
]=]
function Shared.fireSignal(rewardName: string, path: Path, signalParams: { any }, unpackParams: boolean): Reward
	return {
		name = rewardName,
		path = path,
		params = signalParams,
		unpackParams = unpackParams,
		opType = ENUMS.RewardOpTypes.FireSignal,
	}
end

--[=[
	Builds the reward that sets player data in the selected currency.
	@param currency string - The currency to set
	@param value number - The value to set
	@param path Path - The signal path relative to CommsHub
	@return Reward - The set reward
]=]
function Shared.set(currency: string, value: number, path: Path): Reward
	return {
		name = "Set",
		path = path,
		value = value,
		opType = ENUMS.RewardOpTypes.Set,
		params = {
			userDataPaths[currency],
		},
	}
end

--[=[
	Builds the reward that sets cache data in the selected currency.
	@param currency string - The currency to set
	@param value number - The value to set
	@param path Path - The signal path relative to CommsHub
	@return Reward - The set reward
]=]
function Shared.cacheSet(currency: string, value: number, path: Path): Reward
	return {
		name = "Set",
		path = path,
		value = value,
		opType = ENUMS.RewardOpTypes.Set,
		params = {
			userCachePaths[currency],
		},
	}
end

return Shared
