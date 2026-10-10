-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnIsValidPath = require(Modules.fn.isValidPath)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Traverse Path-fn`)

-- Types
type Path = Types.Path

-- Function
--[=[
	Follow the path in data and return value
	@param startPoint The point to start following path from
	@param path Path The path to follow
	@return The value at the end of the path, or the startPoint if no path is provided
]=]
local function traversePath(startPoint: any, path: Path): any
	local isValid, err = fnIsValidPath(path)

	if not isValid then
		Logger:warn(`Provided path is not valid! Error: {err}`)
		return startPoint
	end

	if typeof(path) == "string" then
		path = { path }
	end

	local result = startPoint
	for _, key in ipairs(path) do
		if result == nil then
			return nil
		end

		local success, nextResult = pcall(function(): any
			return result[key]
		end)

		if not success then
			Logger:warn(`Failed to index key '{tostring(key)}' during path traversal: {tostring(nextResult)}`)
			return nil
		end

		result = nextResult
	end

	return result
end

return traversePath
