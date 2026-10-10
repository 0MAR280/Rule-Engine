--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnTraversePath = require(Modules.fn.traversePath)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`DataService`)

-- References
local player = Players.LocalPlayer

-- Types
type Path = Types.Path

-- Module
local DataService = {}

-- Functions
-- Private

-- Public
--[=[
	Initialize the module
]=]
function DataService.init(): ()
	local fn = `init`

	Logger:print(`{fn}: Module was initialized!`)

	return DataService
end

--[=[
	Get the client data at a specfic path
	@param path Path - The data path to follow
	@return any - The data value at the path if any
]=]
function DataService.getData(path: Path): any
	local fn = `getData`

	local instance: NumberValue? = fnTraversePath(player, path)

	if instance then
		return instance.Value
	else
		Logger:warn(`{fn}: Could not fetch value object for player: {player} at path: {path}!`)
	end

	return nil
end

return DataService
