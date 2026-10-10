--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)

-- Types
type LoggerMod = Types.LoggerMod
type Logger = Types.Logger

-- Setting
local LoggerMod = {}
local Logger = {}
Logger.__index = Logger

-- Functions
-- Private
--[=[
	Internal output function
	@param outputFunc function - The output function to use (print, warn, etc.)
	@param ... The messages to output
]=]
function output(self: Logger, outputFunc: (...any) -> (), ...: any): ()
	outputFunc(`[{self.instanceName}]:`, ...)
end

--[=[
	Output a message using print
	@param ... The message to output
]=]
function Logger:print(...: any): nil
	output(self, print, ...)
	return nil
end

--[=[
	Output a message using warn
	@param ... The message to output
]=]
function Logger:warn(...: any): nil
	output(self, warn, ...)
	return nil
end

--[=[
	Output a message using error
	@param message string - The error message
	@param errorLevel number - The level of the error (optional)
	@param ... Additional messages to output before the error
]=]
function Logger:error(message: string, errorLevel: number, ...: any): nil
	errorLevel = errorLevel or 2
	output(self, warn, ...)
	error(`{self.instanceName}: {message}`, errorLevel)
end

-- Public
--[=[
	Create a new Logger
	@param instanceName string - The name of the instance
	@return Logger
]=]
function LoggerMod.new(instanceName: string): Logger
	if typeof(instanceName) ~= "string" then
		error(`instanceName expected to be a string, got {type(instanceName)}!`)
	end

	local newOutputter = setmetatable({}, Logger)
	newOutputter.instanceName = instanceName .. "-" .. (RunService:IsServer() and "Server" or "Client")

	return newOutputter :: Logger
end

return LoggerMod :: LoggerMod
