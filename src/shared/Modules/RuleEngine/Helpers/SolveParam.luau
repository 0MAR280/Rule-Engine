--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnWalkPayload = require(Modules.RuleEngine.Helpers.WalkPayload)
local Types = require(Modules.Types.Types)
local ENUMS = require(Modules.Data.ENUMS)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-SolveParam-Module`)

-- Variables
local currentContext: ContextType = RunService:IsServer() and ENUMS.ContextTypes.Server or ENUMS.ContextTypes.Client

-- Types
type Param = Types.Param
type Path = Types.Path
type ContextType = Types.ContextType

-- Function
--[=[
	Resolves a parameter based on its type, including data, cache, literal, time, and payload values.
	@param player The player to resolve the parameter for
	@param param Parameter data
	@param payload Optional event payload for eventPayload parameters
	@return The resolved parameter value
]=]
local function solveParam(player: Player, param: Param, payload: { [string]: any }?): any
	if param.type == ENUMS.ParamOpTypes.DataPath then
		if currentContext == ENUMS.ContextTypes.Server then
			local ServerScriptService = game:GetService("ServerScriptService")
			local Services = ServerScriptService.Services
			local DataService = require(Services.DataService)

			return DataService.getPlayerData(player, param.path)
		else
			local Services = ReplicatedStorage.Shared.Services
			local DataService = require(Services.DataService)

			return DataService.getData(param.path)
		end
	elseif param.type == ENUMS.ParamOpTypes.CachePath then
		if currentContext == ENUMS.ContextTypes.Server then
			local ServerScriptService = game:GetService("ServerScriptService")
			local Services = ServerScriptService.Services
			local CacheService = require(Services.CacheService)

			return CacheService.getPlayerData(player, param.path)
		else
			local Services = ReplicatedStorage.Shared.Services
			local CacheService = require(Services.CacheService)

			return CacheService.getData(param.path)
		end
	elseif param.type == ENUMS.ParamOpTypes.Value then
		return param.value
	elseif param.type == ENUMS.ParamOpTypes.Now then
		return os.time()
	elseif param.type == ENUMS.ParamOpTypes.EventPayload then
		return fnWalkPayload(payload, param.path)
	end

	Logger:error("solveParam: Unknown param type " .. tostring(param.type))
end

return solveParam
