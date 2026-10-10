--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Custom Services
local Services = ReplicatedStorage.Shared.Services
local DataService = require(Services.DataService)
local CacheService = require(Services.CacheService)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`EntryPoint`)

-- UI
local UI = require(ReplicatedStorage.UI)

-- Functions
--[=[
    Boot up the client by initializing important services
]=]
local function boot(): ()
	local fn = `boot`

	Logger:print(`{fn}: Booting up the client...`)

	DataService.init()
	CacheService.init()

	UI.init()

	Logger:print(`{fn}: Client is up and running!`)
end

-- Setting
boot()
