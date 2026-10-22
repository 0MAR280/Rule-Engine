--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local SharedRewards = require(Modules.Data.Rewards._Shared)
local RuleEngine = require(Modules.RuleEngine)
local PATHS = require(Modules.Data.PATHS)
local ENUMS = require(Modules.Data.ENUMS)
local Harness = require(script.Parent.Harness)

-- Types
type ItFn = Harness.ItFn
type ExpectFn = Harness.ExpectFn

-- Variables
local dataUpdateSignal = PATHS.signals.dataService.server.updatePlayerData

-- Spec
return function(it: ItFn, expect: ExpectFn): ()
	it("passes a rule with no conditions and no rewards", function()
		local player = Harness.makePlayer()
		local conditionsPassed, rewardsApplied, rollbackApplied, err = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		expect(rollbackApplied).toBeNil()
		expect(err).toBeNil()
		player:Destroy()
	end)

	it("passes a rule with empty condition and reward lists", function()
		local player = Harness.makePlayer()
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			conditions = {},
			rewards = {},
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		player:Destroy()
	end)

	it("passes Both context on the server", function()
		local player = Harness.makePlayer()
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Both,
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		player:Destroy()
	end)

	it("rejects Client context on the server", function()
		local player = Harness.makePlayer()
		local conditionsPassed, rewardsApplied, rollbackApplied, err = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Client,
			conditions = {
				{
					name = "Always",
					value1 = 1,
					value2 = 1,
					opType = ENUMS.ConditionOpTypes.Equal,
				},
			},
		})

		expect(conditionsPassed).toBeFalse()
		expect(rewardsApplied).toBeFalse()
		expect(rollbackApplied).toBeNil()
		expect(err).toContain("Context mismatch")
		player:Destroy()
	end)

	it("applies function rewards when function conditions pass", function()
		local player = Harness.makePlayer()
		local rewarded = false
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			conditions = function(_player: Player): (boolean, string?)
				return true, nil
			end,
			rewards = function(_player: Player): (boolean, string?)
				rewarded = true
				return true, nil
			end,
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		expect(rewarded).toBeTrue()
		player:Destroy()
	end)

	it("does not apply rewards when function conditions fail", function()
		local player = Harness.makePlayer()
		local rewarded = false
		local conditionsPassed, rewardsApplied, _, err = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			conditions = function(_player: Player): (boolean, string?)
				return false, "nope"
			end,
			rewards = function(_player: Player): (boolean, string?)
				rewarded = true
				return true, nil
			end,
		})

		expect(conditionsPassed).toBeFalse()
		expect(rewardsApplied).toBeFalse()
		expect(rewarded).toBeFalse()
		expect(err).toBe("nope")
		player:Destroy()
	end)

	it("returns a runtime error when function conditions throw", function()
		local player = Harness.makePlayer()
		local conditionsPassed, rewardsApplied, _, err = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			conditions = function(_player: Player): (boolean, string?)
				error("condition boom")
			end,
		})

		expect(conditionsPassed).toBeFalse()
		expect(rewardsApplied).toBeFalse()
		expect(err).toContain("condition boom")
		player:Destroy()
	end)

	it("rejects conditions that are neither a function nor an array", function()
		local player = Harness.makePlayer()
		local ok, err = RuleEngine.checkConditions(player, {
			context = ENUMS.ContextTypes.Server,
			conditions = { name = "dictionary" } :: any,
		})

		expect(ok).toBeFalse()
		expect(err).toContain("function")
		player:Destroy()
	end)

	it("rejects rewards that are neither a function nor an array", function()
		local player = Harness.makePlayer()
		local ok, err = RuleEngine.applyRewards(player, {
			context = ENUMS.ContextTypes.Server,
			rewards = { name = "dictionary" } :: any,
		})

		expect(ok).toBeFalse()
		expect(err).toContain("function")
		player:Destroy()
	end)

	it("fails function rewards that return false", function()
		local player = Harness.makePlayer()
		local ok, err = RuleEngine.applyRewards(player, {
			context = ENUMS.ContextTypes.Server,
			rewards = function(_player: Player): (boolean, string?)
				return false, "reward refused"
			end,
		})

		expect(ok).toBeFalse()
		expect(err).toBe("reward refused")
		player:Destroy()
	end)

	it("rolls back applied rewards when a later reward fails", function()
		local player = Harness.makePlayer({ coins = 5 })
		local conditionsPassed, rewardsApplied, rollbackApplied = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			rewards = {
				SharedRewards.reward("coins", 10, dataUpdateSignal),
				{
					name = "Broken",
					opType = 999,
					value = 0,
					path = dataUpdateSignal,
					params = { PATHS.userData.coins },
				},
			},
			rollbackRewards = {
				SharedRewards.payment("coins", 10, dataUpdateSignal),
			},
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeFalse()
		expect(rollbackApplied).toBeTrue()
		expect(Harness.getCoins(player)).toBe(5)
		player:Destroy()
	end)

	it("does not roll back when the first reward is the one that fails", function()
		local player = Harness.makePlayer({ coins = 5 })
		local rolledBack = false
		local conditionsPassed, rewardsApplied, rollbackApplied = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			rewards = {
				{
					name = "Broken",
					opType = 999,
					value = 0,
					path = dataUpdateSignal,
					params = { PATHS.userData.coins },
				},
			},
			rollbackRewards = function(_player: Player): (boolean, string?)
				rolledBack = true
				return true, nil
			end,
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeFalse()
		expect(rollbackApplied).toBeFalse()
		expect(rolledBack).toBeFalse()
		expect(Harness.getCoins(player)).toBe(5)
		player:Destroy()
	end)

	it("treats a missing rollback list as a successful rollback", function()
		local player = Harness.makePlayer({ coins = 5 })
		local conditionsPassed, rewardsApplied, rollbackApplied = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			rewards = {
				SharedRewards.reward("coins", 10, dataUpdateSignal),
				{
					name = "Broken",
					opType = 999,
					value = 0,
					path = dataUpdateSignal,
					params = { PATHS.userData.coins },
				},
			},
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeFalse()
		expect(rollbackApplied).toBeTrue()
		expect(Harness.getCoins(player)).toBe(15)
		player:Destroy()
	end)

	it("fails rollback when the rollback function returns false", function()
		local player = Harness.makePlayer({ coins = 5 })
		local conditionsPassed, rewardsApplied, rollbackApplied, err = RuleEngine.executeRule(player, {
			context = ENUMS.ContextTypes.Server,
			rewards = {
				SharedRewards.reward("coins", 10, dataUpdateSignal),
				{
					name = "Broken",
					opType = 999,
					value = 0,
					path = dataUpdateSignal,
					params = { PATHS.userData.coins },
				},
			},
			rollbackRewards = function(_player: Player): (boolean, string?)
				return false, "rollback refused"
			end,
		})

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeFalse()
		expect(rollbackApplied).toBeFalse()
		expect(err).toBe("Something went wrong!")
		expect(Harness.getCoins(player)).toBe(15)
		player:Destroy()
	end)

	it("passes event payload values into array conditions", function()
		local player = Harness.makePlayer()
		local ok, err = RuleEngine.checkConditions(player, {
			context = ENUMS.ContextTypes.Server,
			conditions = {
				{
					name = "Payload amount",
					value1 = {
						param = {
							type = ENUMS.ParamOpTypes.EventPayload,
							path = { "amount" },
						},
					},
					value2 = 10,
					opType = ENUMS.ConditionOpTypes.Equal,
					onFalse = "amount mismatch",
				},
			},
		}, { amount = 10 })

		expect(ok).toBeTrue()
		expect(err).toBeNil()
		player:Destroy()
	end)
end
