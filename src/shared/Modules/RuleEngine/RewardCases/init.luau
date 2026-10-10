--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local ENUMS = require(Modules.Data.ENUMS)

-- Module
return {
	[ENUMS.RewardOpTypes.Increment] = require(script.Increment),
	[ENUMS.RewardOpTypes.Decrement] = require(script.Decrement),
	[ENUMS.RewardOpTypes.Set] = require(script.Set),
	[ENUMS.RewardOpTypes.FireSignal] = require(script.FireSignal),
}
