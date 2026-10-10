--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Libraries
local Libraries = ReplicatedStorage.Shared.Libraries
local TypeCheckerLib = require(Libraries.TypeChecker)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Is A Player Character-fn`)

-- Function
--[=[
	Check if the given instance belongs to a player character, and return the player instance if true
	@param instance Instance - The instance to check
	@return Player? - The player instance if the instance belongs to a player character, nil otherwise
]=]
local function isAPlayerCharacter(instance: Instance): Player?
	if not TypeCheckerLib.isInstance(instance) then
		Logger:warn(`Part should be a Instance!`)
		return nil
	end

	-- Traverse up the hierarchy safely to find a Model containing a Humanoid
	local current: Instance? = instance

	while current and current ~= workspace and current ~= game do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			local player = Players:GetPlayerFromCharacter(current)
			if player then
				return player
			end
		end
		current = current.Parent
	end

	return nil
end

return isAPlayerCharacter
