-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)

-- Types
type Path = Types.Path

-- Function
--[=[
	Check if a path is valid
	@param path Path? Path to validate
	@return boolean whether the path is valid, string|nil error message if any
]=]
local function isValidPath(path: Path?): (boolean, string?)
	local fn = `isValidPath`

	if path == nil or typeof(path) == "string" then
		return true
	end
	if typeof(path) == "table" then
		for index, v in pairs(path) do
			if typeof(index) ~= "number" then
				local msg = `{fn}: Path array must only contain sequential indices!`
				return false, msg
			end
			if typeof(v) ~= "string" then
				local msg = `{fn}: Path array must only contain strings!`
				return false, msg
			end
		end

		return true
	end

	local msg = `{fn}: Path must be a string, nil, or array of strings!`
	return false, msg
end

return isValidPath
