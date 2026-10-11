--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Sift = require(Packages.Sift)

-- Libraries
local Libraries = ReplicatedStorage.Shared.Libraries
local TypeChecker = require(Libraries.TypeChecker)

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnSolveParam = require(Modules.RuleEngine.Helpers.SolveParam)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Rule Engine-SolveConditionValue-Module`)

-- Types
type Param = Types.Param
type Value = Types.Value

-- Function
--[=[
	Resolves a value that may be dynamic, such as a value based on player data or event parameters.
	@param player Player - The player to resolve the value for
	@param valueData Value - A direct value or a table containing a parameter and optional callback
	@param payload { [string]: any} - Optional event payload used when resolving eventPayload parameters
	@return any - The resolved value
]=]
local function solveConditionValue(player: Player, valueData: Value, payload: { [string]: any }?): any
	if valueData == nil then
		return nil
	end

	if typeof(valueData) == "table" and valueData.param then
		local param: Param = valueData.param
		local params = fnSolveParam(player, param, payload)
		local returnIndex = valueData.returnIndex or nil
		local result = params
		local resultWasWrapped = false

		local callBack = valueData.callBack

		if callBack then
			if typeof(callBack) == "function" then
				if valueData.unpackParams then
					if Sift.Array.isArray(result) then
						result = { callBack(table.unpack(params)) }
						resultWasWrapped = true
					else
						local msg1 = `Epxected result as an array, but got "{TypeChecker.getType(result)}"!`
						local msg2 = `Did you forget to set "unpackParams" to false?`
						Logger:error(`{msg1}\n{msg2}`)
					end
				else
					result = { callBack(params) }
					resultWasWrapped = true
				end
			else
				local msg1 = `Epxected "callback" as a callback, got "{TypeChecker.getType(callBack)}"!`
				local msg2 = `Did you forget to set "callback" to a proper function callback?`
				Logger:error(`{msg1}\n{msg2}`)
			end
		end

		if typeof(returnIndex) == "number" then
			if Sift.Array.isArray(result) then
				return result[returnIndex]
			else
				local msg1 = `Epxected result as an array, but got "{TypeChecker.getType(result)}"!`
				local msg2 = `Did you forget to set "returnIndex" to nil?`
				Logger:error(`{msg1}\n{msg2}`)
			end
		else
			if resultWasWrapped then
				return unpack(result)
			else
				return result
			end
		end
	end

	return valueData
end

return solveConditionValue
