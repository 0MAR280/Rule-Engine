--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local ENUMS = require(Modules.Data.ENUMS)
local PATHS = require(Modules.Data.PATHS)

-- References
local userDataPaths = PATHS.userData
local userCachePaths = PATHS.userCache

-- Module
local BALANCES = {
	coins = {
		type = ENUMS.ParamOpTypes.DataPath,
		path = userDataPaths.coins,
	},

	points = {
		type = ENUMS.ParamOpTypes.CachePath,
		path = userCachePaths.points,
	},

	playtime = {
		type = ENUMS.ParamOpTypes.CachePath,
		path = userCachePaths.playtime,
	},
}

return BALANCES
