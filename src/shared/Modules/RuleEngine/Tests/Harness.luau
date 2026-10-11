--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnTraversePath = require(Modules.fn.traversePath)
local PATHS = require(Modules.Data.PATHS)

-- Types
export type Expectation = {
	toBe: (expected: any) -> (),
	toBeNil: () -> (),
	toBeTrue: () -> (),
	toBeFalse: () -> (),
	toContain: (needle: string) -> (),
}

export type ItFn = (name: string, fn: () -> ()) -> ()
export type ExpectFn = (actual: any) -> Expectation
export type SpecFn = (it: ItFn, expect: ExpectFn) -> ()

export type PlayerStats = {
	coins: number?,
	points: number?,
	playtime: number?,
}

-- Module
local Harness = {}

-- Functions
-- Private
local function stringify(value: any): string
	if typeof(value) == "string" then
		return `"{value}"`
	end

	return tostring(value)
end

-- Public
--[=[
	Build an expectation object for a value
	@param actual any - The value under test
	@return Expectation
]=]
function Harness.expect(actual: any): Expectation
	local expectation = {}

	function expectation.toBe(expected: any): ()
		if actual ~= expected then
			error(`Expected {stringify(expected)}, got {stringify(actual)}`, 2)
		end
	end

	function expectation.toBeNil(): ()
		if actual ~= nil then
			error(`Expected nil, got {stringify(actual)}`, 2)
		end
	end

	function expectation.toBeTrue(): ()
		if actual ~= true then
			error(`Expected true, got {stringify(actual)}`, 2)
		end
	end

	function expectation.toBeFalse(): ()
		if actual ~= false then
			error(`Expected false, got {stringify(actual)}`, 2)
		end
	end

	function expectation.toContain(needle: string): ()
		if typeof(actual) ~= "string" or string.find(actual, needle, 1, true) == nil then
			error(`Expected {stringify(actual)} to contain {stringify(needle)}`, 2)
		end
	end

	return expectation
end

--[=[
	Create a folder that mimics the player data tree used by Data/Cache services
	@param stats PlayerStats? - Starting currency values
	@return any - The fake player tree
]=]
function Harness.makePlayer(stats: PlayerStats?): any
	local values = stats or {} :: PlayerStats

	local player = Instance.new("Folder")
	player.Name = "TestPlayer"

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Value = values.coins or 0
	coins.Parent = leaderstats

	local sessionStats = Instance.new("Folder")
	sessionStats.Name = "SessionStats"
	sessionStats.Parent = player

	local points = Instance.new("NumberValue")
	points.Name = "Points"
	points.Value = values.points or 0
	points.Parent = sessionStats

	local playtime = Instance.new("NumberValue")
	playtime.Name = "Playtime"
	playtime.Value = values.playtime or 0
	playtime.Parent = sessionStats

	local backpack = Instance.new("Folder")
	backpack.Name = "Backpack"
	backpack.Parent = player

	return player
end

--[=[
	Read a NumberValue at a path under the fake player
	@param player any - Fake player tree
	@param path { string } - Path segments
	@return number
]=]
function Harness.getNumber(player: any, path: { string }): number
	local instance = fnTraversePath(player, path)
	if typeof(instance) ~= "Instance" or not instance:IsA("NumberValue") then
		error(`Expected a NumberValue at path {table.concat(path, ".")}`, 2)
	end

	return instance.Value
end

--[=[
	Read the fake player's coins
	@param player any - Fake player tree
	@return number
]=]
function Harness.getCoins(player: any): number
	return Harness.getNumber(player, PATHS.userData.coins)
end

--[=[
	Read the fake player's points
	@param player any - Fake player tree
	@return number
]=]
function Harness.getPoints(player: any): number
	return Harness.getNumber(player, PATHS.userCache.points)
end

return Harness
