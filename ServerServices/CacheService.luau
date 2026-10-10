--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local SignalManager = require(Modules.Core.SignalManager)
local fnTraversePath = require(Modules.fn.traversePath)
local fnApplyProps = require(Modules.fn.applyProps)
local CommsHub = require(Modules.Core.CommsHub)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`CacheService`)

-- Variables
local Signals = CommsHub.signals.CacheService.server

-- Types
type Path = Types.Path

-- Module
local CacheService = {}
local Private = {}

-- Functions
-- Private
--[=[
	Setup the module signals
]=]
function Private.setupSignals(): ()
	local setSignal = Signals.setPlayerData
	local updateSignal = Signals.updatePlayerData

	SignalManager.connectToSignal(updateSignal, Private.onUpdateSignal)
	SignalManager.connectToSignal(setSignal, Private.onSetSignal)
	Players.PlayerAdded:Connect(Private.onPlayerJoin)
end

-- Events
--[=[
    Initialize player data tree
    @param player Player - The player player instance
]=]
function Private.onPlayerJoin(player: Player): ()
	local cacheDataFolder = Instance.new("Folder")
	cacheDataFolder.Name = "SessionStats"

	local pointsValue = Instance.new("NumberValue", cacheDataFolder)
	pointsValue.Name = "Points"

	local playtimeValue = Instance.new("NumberValue", cacheDataFolder)
	playtimeValue.Name = "Playtime"

	task.spawn(function()
		while player and player.Parent == Players do
			task.wait(1)
			playtimeValue.Value += 1
			pointsValue.Value += 1
		end
	end)

	cacheDataFolder.Parent = player
end

--[=[
    Handle a set signal being fired
    @param player Player - The target player instance
    @param path Path - The data path to manipulate
    @param newValue any - The new value to set
]=]
function Private.onSetSignal(player: Player, path: Path, newValue: any): ()
	local fn = `onSetSignal`

	local instance = fnTraversePath(player, path)
	local props = { Value = newValue }

	if instance then
		fnApplyProps(instance, props)
	else
		Logger:warn(`{fn}: Could not fetch value object for player: {player} at path: {path}!`)
	end
end

--[=[
    Handle a update signal being fired
    @param player Player - The target player instance
    @param path Path - The data path to manipulate
    @param newValue any - The new value to update
]=]
function Private.onUpdateSignal(player: Player, path: Path, callback: (currentValue: number) -> number): ()
	local fn = `onUpdateSignal`

	local instance: NumberValue? = fnTraversePath(player, path)

	if instance and instance:IsA("NumberValue") then
		local currentValue = instance.Value
		local newValue = callback(currentValue)
		local props = { Value = newValue }

		fnApplyProps(instance, props)
	else
		Logger:warn(`{fn}: Could not fetch value object for player: {player} at path: {path}!`)
	end
end

-- Public
--[=[
	Initialize the module
]=]
function CacheService.init(): ()
	local fn = `init`

	Private.setupSignals()
	Logger:print(`{fn}: Module was initialized!`)

	return CacheService
end

--[=[
	Get a player data at a specfic path
	@param player Player - The target player to fetch data for
	@param path Path - The data path to follow
	@return any - The data value at the path if any
]=]
function CacheService.getPlayerData(player: Player, path: Path): any
	local fn = `getPlayerData`

	local instance: NumberValue? = fnTraversePath(player, path)

	if instance then
		return instance.Value
	else
		Logger:warn(`{fn}: Could not fetch value object for player: {player} at path: {path}!`)
	end

	return nil
end

return CacheService
