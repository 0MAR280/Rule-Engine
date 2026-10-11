--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)

-- Types
type GameReward = Types.GameReward

-- Module
local rewards = {
	[1] = require(script["1"]),
	[2] = require(script["2"]),
	[3] = require(script["3"]),
	[4] = require(script["4"]),
	[5] = require(script["5"]),
	[6] = require(script["6"]),
} :: { [number]: GameReward }

return rewards
