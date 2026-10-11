--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnSolveAllConditions = require(Modules.RuleEngine.Helpers.SolveAllConditions)
local fnSolveCondition = require(Modules.RuleEngine.Helpers.SolveCondition)
local RuleEngine = require(Modules.RuleEngine)
local ENUMS = require(Modules.Data.ENUMS)
local Harness = require(script.Parent.Harness)

-- Types
type ItFn = Harness.ItFn
type ExpectFn = Harness.ExpectFn

-- Spec
return function(it: ItFn, expect: ExpectFn): ()
	local function check(opType: number, value1: any, value2: any): boolean
		local player = Harness.makePlayer()
		local ok = fnSolveCondition(player, {
			name = "op",
			value1 = value1,
			value2 = value2,
			opType = opType,
		})
		player:Destroy()
		return ok
	end

	it("evaluates Equal", function()
		expect(check(ENUMS.ConditionOpTypes.Equal, 4, 4)).toBeTrue()
		expect(check(ENUMS.ConditionOpTypes.Equal, 4, 5)).toBeFalse()
	end)

	it("evaluates NotEqual", function()
		expect(check(ENUMS.ConditionOpTypes.NotEqual, 4, 5)).toBeTrue()
		expect(check(ENUMS.ConditionOpTypes.NotEqual, 4, 4)).toBeFalse()
	end)

	it("evaluates GreaterThan", function()
		expect(check(ENUMS.ConditionOpTypes.GreaterThan, 5, 4)).toBeTrue()
		expect(check(ENUMS.ConditionOpTypes.GreaterThan, 4, 4)).toBeFalse()
	end)

	it("evaluates GreaterThanOrEqual", function()
		expect(check(ENUMS.ConditionOpTypes.GreaterThanOrEqual, 4, 4)).toBeTrue()
		expect(check(ENUMS.ConditionOpTypes.GreaterThanOrEqual, 3, 4)).toBeFalse()
	end)

	it("evaluates LessThan", function()
		expect(check(ENUMS.ConditionOpTypes.LessThan, 3, 4)).toBeTrue()
		expect(check(ENUMS.ConditionOpTypes.LessThan, 4, 4)).toBeFalse()
	end)

	it("evaluates LessThanOrEqual", function()
		expect(check(ENUMS.ConditionOpTypes.LessThanOrEqual, 4, 4)).toBeTrue()
		expect(check(ENUMS.ConditionOpTypes.LessThanOrEqual, 5, 4)).toBeFalse()
	end)

	it("treats a nil condition as satisfied", function()
		local player = Harness.makePlayer()
		expect(fnSolveCondition(player, nil :: any)).toBeTrue()
		player:Destroy()
	end)

	it("fails closed on an unknown operator", function()
		expect(check(999, 1, 1)).toBeFalse()
	end)

	it("stops on the first failing condition and returns onFalse", function()
		local player = Harness.makePlayer()
		local ok, err = fnSolveAllConditions(player, {
			{
				name = "first",
				value1 = 1,
				value2 = 1,
				opType = ENUMS.ConditionOpTypes.Equal,
			},
			{
				name = "second",
				value1 = 1,
				value2 = 2,
				opType = ENUMS.ConditionOpTypes.Equal,
				onFalse = "second failed",
			},
			{
				name = "third",
				value1 = 1,
				value2 = 1,
				opType = ENUMS.ConditionOpTypes.Equal,
				onFalse = "third failed",
			},
		})

		expect(ok).toBeFalse()
		expect(err).toBe("second failed")
		player:Destroy()
	end)

	it("uses the condition name when onFalse is omitted", function()
		local player = Harness.makePlayer()
		local ok, err = fnSolveAllConditions(player, {
			{
				name = "Need five",
				value1 = 1,
				value2 = 5,
				opType = ENUMS.ConditionOpTypes.Equal,
			},
		})

		expect(ok).toBeFalse()
		expect(err).toContain("Need five")
		player:Destroy()
	end)

	it("resolves a literal Value param", function()
		local player = Harness.makePlayer()
		local ok = fnSolveCondition(player, {
			name = "value param",
			value1 = {
				param = {
					type = ENUMS.ParamOpTypes.Value,
					value = 8,
				},
			},
			value2 = 8,
			opType = ENUMS.ConditionOpTypes.Equal,
		})

		expect(ok).toBeTrue()
		player:Destroy()
	end)

	it("resolves a Now param as a timestamp", function()
		local player = Harness.makePlayer()
		local ok = fnSolveCondition(player, {
			name = "now",
			value1 = {
				param = {
					type = ENUMS.ParamOpTypes.Now,
				},
			},
			value2 = os.time() - 1,
			opType = ENUMS.ConditionOpTypes.GreaterThanOrEqual,
		})

		expect(ok).toBeTrue()
		player:Destroy()
	end)

	it("runs a callback over resolved params", function()
		local player = Harness.makePlayer()
		local ok = fnSolveCondition(player, {
			name = "callback",
			value1 = {
				param = {
					type = ENUMS.ParamOpTypes.Value,
					value = { 10, 20 },
				},
				callBack = function(values: { number }): number
					return values[1] + values[2]
				end,
				unpackParams = false,
			},
			value2 = 30,
			opType = ENUMS.ConditionOpTypes.Equal,
		})

		expect(ok).toBeTrue()
		player:Destroy()
	end)

	it("unpacks params into a callback when requested", function()
		local player = Harness.makePlayer()
		local ok = fnSolveCondition(player, {
			name = "unpack callback",
			value1 = {
				param = {
					type = ENUMS.ParamOpTypes.Value,
					value = { 2, 3 },
				},
				callBack = function(a: number, b: number): number
					return a * b
				end,
				unpackParams = true,
			},
			value2 = 6,
			opType = ENUMS.ConditionOpTypes.Equal,
		})

		expect(ok).toBeTrue()
		player:Destroy()
	end)

	it("returns a callback result by index", function()
		local player = Harness.makePlayer()
		local ok = fnSolveCondition(player, {
			name = "returnIndex",
			value1 = {
				param = {
					type = ENUMS.ParamOpTypes.Value,
					value = 9,
				},
				callBack = function(value: number): (number, number)
					return value, value * 2
				end,
				returnIndex = 2,
			},
			value2 = 18,
			opType = ENUMS.ConditionOpTypes.Equal,
		})

		expect(ok).toBeTrue()
		player:Destroy()
	end)

	it("reads player data and cache params", function()
		local player = Harness.makePlayer({ coins = 12, points = 7 })
		local ok, err = RuleEngine.checkConditions(player, {
			context = ENUMS.ContextTypes.Server,
			conditions = {
				{
					name = "coins",
					value1 = { param = { type = ENUMS.ParamOpTypes.DataPath, path = { "leaderstats", "Coins" } } },
					value2 = 12,
					opType = ENUMS.ConditionOpTypes.Equal,
					onFalse = "coins mismatch",
				},
				{
					name = "points",
					value1 = { param = { type = ENUMS.ParamOpTypes.CachePath, path = { "SessionStats", "Points" } } },
					value2 = 7,
					opType = ENUMS.ConditionOpTypes.Equal,
					onFalse = "points mismatch",
				},
			},
		})

		expect(ok).toBeTrue()
		expect(err).toBeNil()
		player:Destroy()
	end)

	it("passes an empty condition list", function()
		local player = Harness.makePlayer()
		local ok = fnSolveAllConditions(player, {})
		expect(ok).toBeTrue()
		player:Destroy()
	end)
end
