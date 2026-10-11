--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local ENUMS = require(Modules.Data.ENUMS)
local Types = require(Modules.Types.Types)

-- Types
type ContextType = Types.ContextType

-- Variables
local currentContext: ContextType = RunService:IsServer() and ENUMS.ContextTypes.Server or ENUMS.ContextTypes.Client

-- Function
--[=[
	Ensures that the rule is being evaluated in the correct context (Server, Client, or Both).
	@param ruleContext ContextType - The context specified in the rule (Server, Client, Both)
	@return boolean - Whether the context is valid
]=]
local function checkContext(ruleContext: ContextType): boolean
	if ruleContext == nil then
		return true
	end

	if ruleContext == ENUMS.ContextTypes.Both then
		return true
	end

	return ruleContext == currentContext
end

return checkContext
