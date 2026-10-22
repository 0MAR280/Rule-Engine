--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local RuleEngine = require(Modules.RuleEngine)
local Rewards = require(Modules.Data.Rewards)
local Harness = require(script.Parent.Harness)

-- Types
type ItFn = Harness.ItFn
type ExpectFn = Harness.ExpectFn

-- Spec
return function(it: ItFn, expect: ExpectFn): ()
	it("sample 1 trades points for coins using Increment and Decrement", function()
		local player = Harness.makePlayer({ coins = 0, points = 20 })
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, Rewards[1].ruleData)

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		expect(Harness.getCoins(player)).toBe(5)
		expect(Harness.getPoints(player)).toBe(10)
		player:Destroy()
	end)

	it("sample 1 rejects a player with too few points", function()
		local player = Harness.makePlayer({ coins = 0, points = 4 })
		local conditionsPassed, rewardsApplied, _, err = RuleEngine.executeRule(player, Rewards[1].ruleData)

		expect(conditionsPassed).toBeFalse()
		expect(rewardsApplied).toBeFalse()
		expect(err).toContain("Not Enough points")
		expect(Harness.getCoins(player)).toBe(0)
		expect(Harness.getPoints(player)).toBe(4)
		player:Destroy()
	end)

	it("sample 2 sets coins with the Set case", function()
		local player = Harness.makePlayer({ coins = 8 })
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, Rewards[2].ruleData)

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		expect(Harness.getCoins(player)).toBe(50)
		player:Destroy()
	end)

	it("sample 2 does not set coins that are already the target value", function()
		local player = Harness.makePlayer({ coins = 50 })
		local conditionsPassed, _, _, err = RuleEngine.executeRule(player, Rewards[2].ruleData)

		expect(conditionsPassed).toBeFalse()
		expect(err).toContain("already 50")
		expect(Harness.getCoins(player)).toBe(50)
		player:Destroy()
	end)

	it("sample 3 grants coins with the Increment case", function()
		local player = Harness.makePlayer({ coins = 10 })
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, Rewards[3].ruleData)

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		expect(Harness.getCoins(player)).toBe(25)
		player:Destroy()
	end)

	it("sample 3 stops incrementing once the cap is reached", function()
		local player = Harness.makePlayer({ coins = 100 })
		local conditionsPassed, _, _, err = RuleEngine.executeRule(player, Rewards[3].ruleData)

		expect(conditionsPassed).toBeFalse()
		expect(err).toContain("cap")
		expect(Harness.getCoins(player)).toBe(100)
		player:Destroy()
	end)

	it("sample 4 fires a signal and charges both currencies", function()
		local player = Harness.makePlayer({ coins = 10, points = 10 })
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, Rewards[4].ruleData)

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		expect(Harness.getCoins(player)).toBe(0)
		expect(Harness.getPoints(player)).toBe(0)
		expect(player.Backpack:FindFirstChild("Fake Sword") ~= nil).toBeTrue()
		player:Destroy()
	end)

	it("sample 4 rejects a player with too few coins", function()
		local player = Harness.makePlayer({ coins = 2, points = 20 })
		local conditionsPassed, _, _, err = RuleEngine.executeRule(player, Rewards[4].ruleData)

		expect(conditionsPassed).toBeFalse()
		expect(err).toContain("Not Enough Coins")
		expect(player.Backpack:FindFirstChild("Fake Sword")).toBeNil()
		player:Destroy()
	end)

	it("sample 5 spends points with the Decrement case", function()
		local player = Harness.makePlayer({ points = 25 })
		local conditionsPassed, rewardsApplied = RuleEngine.executeRule(player, Rewards[5].ruleData)

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeTrue()
		expect(Harness.getPoints(player)).toBe(15)
		player:Destroy()
	end)

	it("sample 5 rejects a player who does not have more than the cost", function()
		local player = Harness.makePlayer({ points = 10 })
		local conditionsPassed, _, _, err = RuleEngine.executeRule(player, Rewards[5].ruleData)

		expect(conditionsPassed).toBeFalse()
		expect(err).toContain("Need more than 10 Points")
		expect(Harness.getPoints(player)).toBe(10)
		player:Destroy()
	end)

	it("sample 6 applies rewards, fails in the middle, and rolls back", function()
		local player = Harness.makePlayer({ coins = 10, points = 20 })
		local conditionsPassed, rewardsApplied, rollbackApplied = RuleEngine.executeRule(player, Rewards[6].ruleData)

		expect(conditionsPassed).toBeTrue()
		expect(rewardsApplied).toBeFalse()
		expect(rollbackApplied).toBeTrue()
		expect(Harness.getCoins(player)).toBe(10)
		expect(Harness.getPoints(player)).toBe(20)
		player:Destroy()
	end)
end
