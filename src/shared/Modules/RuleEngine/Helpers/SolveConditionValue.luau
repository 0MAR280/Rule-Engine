--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnSolveParam = require(Modules.RuleEngine.Helpers.SolveParam)
local Types = require(Modules.Types.Types)

-- Types
type Param = Types.Param

-- Function
--[=[
	Resolves a value that may be dynamic, such as a value based on player data or event parameters.
	@param player The player to resolve the value for
	@param valueData A direct value or a table containing a parameter and optional callback
	@param payload Optional event payload used when resolving eventPayload parameters
	@return The resolved value
]=]
local function solveConditionValue(player: Player, valueData: any, payload: { [string]: any }?): any
	if valueData == nil then
		return nil
	end

	if typeof(valueData) == "table" and valueData.param then
		local param: Param = valueData.param
		local params = fnSolveParam(player, param, payload)
		local returnV = valueData.returnV or 0
		local returnAsTable = valueData.returnAsTable or false
		local result = params

		if valueData.callBack then
			local callBack = valueData.callBack

			if valueData.unpackParams then
				result = { callBack(table.unpack(params)) }
			else
				result = { callBack(params) }
			end
		end

		if returnV == 0 then
			if returnAsTable then
				if typeof(result) == "table" then
					return result
				else
					return { result }
				end
			else
				if typeof(result) == "table" then
					return unpack(result)
				else
					return result
				end
			end
		else
			if typeof(result) == "table" then
				return result[returnV]
			else
				return result
			end
		end
	end

	return valueData
end

return solveConditionValue
