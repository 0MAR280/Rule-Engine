--!strict
-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Custom Services
local Services = ServerScriptService.Services
local ToolService = require(Services.ToolService)
local DataService = require(Services.DataService)
local CacheService = require(Services.CacheService)
local RewardService = require(Services.RewardService)
local TestService = require(Services.TestService)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`EntryPoint`)

-- Functions
--[=[
    Boot up the server by initializing important services
]=]
local function boot(): ()
	local fn = `boot`

	Logger:print(`{fn}: Booting up the server...`)

	DataService.init()
	CacheService.init()
	ToolService.init()
	TestService.init()
	RewardService.init()

	Logger:print(`{fn}: Server is up and running!`)
end

-- Setting
boot()
