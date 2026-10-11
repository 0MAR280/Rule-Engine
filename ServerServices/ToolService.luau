--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local SignalManager = require(Modules.Core.SignalManager)
local CommsHub = require(Modules.Core.CommsHub)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`ToolService`)

-- References
local ToolsFolder: Folder

-- Variables
local Signals = CommsHub.signals.ToolService.server

-- Types
type Path = Types.Path

-- Module
local ToolService = {}
local Private = {}

-- Functions
-- Private
--[=[
	Setup the module signals
]=]
function Private.setupSignals(): ()
	local giveToolSignal = Signals.giveTool

	SignalManager.connectToSignal(giveToolSignal, Private.onGiveToolSignal)
end

--[=[
	Find of make a folder to contain the tools
]=]
function Private.findOrMakeToolsFolder(): ()
	local folder = ServerStorage:FindFirstChild("Tools")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Tools"
		folder.Parent = ServerStorage
	end

	ToolsFolder = folder
end

-- Events
--[=[
    Initialize player data tree
    @param player Player - The player player instance
	@param toolName string - The tool name to give
	@param ... any -- Extra Parameters to print :D
]=]
function Private.onGiveToolSignal(player: Player, toolName: string, ...: any): ()
	local fn = `onGiveToolSignal`

	Logger:print(`{fn}: Received a give tool signal with extra Parameters:`, ...)

	local tool = ToolsFolder:FindFirstChild(toolName) :: Tool

	if tool then
		local clone = tool:Clone()
		clone.Parent = player.Backpack
		Logger:print(`{fn}: Successfully gave tool: {toolName} to player: {player}!`)
		return
	else
		Logger:warn(`{fn}: Could not find tool: {toolName} in the tools folder, creating a palceholder!`)
	end

	local fakeTool = Instance.new("Tool")
	fakeTool.Name = `Fake {toolName}`

	local part = Instance.new("Part", fakeTool)
	part.Size = Vector3.new(1, 5, 1)
	part.Name = "Handle"

	fakeTool.Parent = player.Backpack
	Logger:print(`{fn}: Successfully made a fake tool for player: {player}!`)
end

-- Public
--[=[
	Initialize the module
]=]
function ToolService.init(): ()
	local fn = `init`

	Private.findOrMakeToolsFolder()
	Private.setupSignals()
	Logger:print(`{fn}: Module was initialized!`)

	return ToolService
end

return ToolService
