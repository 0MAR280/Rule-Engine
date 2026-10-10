--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)

-- Types
type Path = Types.Path

-- Function
--[=[
	Whether two paths have the same segments.
	@param a Path First path
	@param b Path Second path
	@return boolean True if equal
]=]
local function pathEquals(a: Path, b: Path): boolean
	local pathA = if typeof(a) == "string" then { a } else a
	local pathB = if typeof(b) == "string" then { b } else b

	if #pathA ~= #pathB then
		return false
	end
	for i = 1, #pathA do
		if pathA[i] ~= pathB[i] then
			return false
		end
	end
	return true
end

return pathEquals