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
	Walks an event payload table by path. Missing payload or path fails closed (nil).
	@param payload Event payload
	@param path Path segments inside the payload
	@return The value at the path, or nil
]=]
local function walkPayload(payload: { [string]: any }?, path: Path?): any
	if typeof(payload) ~= "table" or typeof(path) ~= "table" then
		return nil
	end

	local node: any = payload
	for _, segment in ipairs(path) do
		if typeof(node) ~= "table" then
			return nil
		end
		node = node[segment]
	end

	return node
end

return walkPayload
