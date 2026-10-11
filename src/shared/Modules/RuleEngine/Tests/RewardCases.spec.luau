--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local SharedRewards = require(Modules.Data.Rewards._Shared)
local SignalManager = require(Modules.Core.SignalManager)
local fnApplyReward = require(Modules.RuleEngine.Helpers.ApplyReward)
local fnApplyRewards = require(Modules.RuleEngine.Helpers.ApplyRewards)
local RuleEngine = require(Modules.RuleEngine)
local CommsHub = require(Modules.Core.CommsHub)
local PATHS = require(Modules.Data.PATHS)
local ENUMS = require(Modules.Data.ENUMS)
local Harness = require(script.Parent.Harness)

-- Types
type ItFn = Harness.ItFn
type ExpectFn = Harness.ExpectFn

-- Variables
local dataUpdateSignal = PATHS.signals.dataService.server.updatePlayerData
local dataSetSignal = PATHS.signals.dataService.server.setPlayerData
local cacheUpdateSignal = PATHS.signals.cacheService.server.updatePlayerData
local cacheSetSignal = PATHS.signals.cacheService.server.setPlayerData

-- Spec
return function(it: ItFn, expect: ExpectFn): ()
	it("increments player data", function()
		local player = Harness.makePlayer({ coins = 4 })
		local ok, err = fnApplyReward(player, SharedRewards.reward("coins", 6, dataUpdateSignal))

		expect(ok).toBeTrue()
		expect(err).toBeNil()
		expect(Harness.getCoins(player)).toBe(10)
		player:Destroy()
	end)

	it("decrements cache data", function()
		local player = Harness.makePlayer({ points = 20 })
		local ok = fnApplyReward(player, SharedRewards.cachePayment("points", 7, cacheUpdateSignal))

		expect(ok).toBeTrue()
		expect(Harness.getPoints(player)).toBe(13)
		player:Destroy()
	end)

	it("sets player data", function()
		local player = Harness.makePlayer({ coins = 3 })
		local ok = fnApplyReward(player, SharedRewards.set("coins", 50, dataSetSignal))

		expect(ok).toBeTrue()
		expect(Harness.getCoins(player)).toBe(50)
		player:Destroy()
	end)

	it("sets cache data", function()
		local player = Harness.makePlayer({ points = 3 })
		local ok = fnApplyReward(player, SharedRewards.cacheSet("points", 1, cacheSetSignal))

		expect(ok).toBeTrue()
		expect(Harness.getPoints(player)).toBe(1)
		player:Destroy()
	end)

	it("resolves a dynamic increment value", function()
		local player = Harness.makePlayer({ coins = 1 })
		local ok = fnApplyReward(player, {
			name = "Dynamic increment",
			opType = ENUMS.RewardOpTypes.Increment,
			value = {
				param = {
					type = ENUMS.ParamOpTypes.Value,
					value = 4,
				},
			},
			path = dataUpdateSignal,
			params = { PATHS.userData.coins },
		})

		expect(ok).toBeTrue()
		expect(Harness.getCoins(player)).toBe(5)
		player:Destroy()
	end)

	it("does not mutate the original reward params array", function()
		local player = Harness.makePlayer({ coins = 0 })
		local params = { PATHS.userData.coins }
		local ok = fnApplyReward(player, {
			name = "Increment",
			opType = ENUMS.RewardOpTypes.Increment,
			value = 1,
			path = dataUpdateSignal,
			params = params,
		})

		expect(ok).toBeTrue()
		expect(#params).toBe(1)
		player:Destroy()
	end)

	it("fires a signal with unpacked params", function()
		CommsHub.signals.TestHarness = {
			ping = "TestHarness:Ping",
		}

		local received: { any } = {}
		local connection = SignalManager.connectToSignal("TestHarness:Ping", function(...: any)
			received = { ... }
		end)

		local player = Harness.makePlayer()
		local ok = fnApplyReward(player, SharedRewards.fireSignal("ping", { "signals", "TestHarness", "ping" }, {
			"Sword",
			"extra",
		}, true))

		expect(ok).toBeTrue()
		expect(received[1]).toBe(player)
		expect(received[2]).toBe("Sword")
		expect(received[3]).toBe("extra")

		if connection then
			connection:Disconnect()
		end
		player:Destroy()
	end)

	it("fires a signal with packed params", function()
		CommsHub.signals.TestHarness = {
			packed = "TestHarness:Packed",
		}

		local received: { any } = {}
		local connection = SignalManager.connectToSignal("TestHarness:Packed", function(...: any)
			received = { ... }
		end)

		local player = Harness.makePlayer()
		local ok = fnApplyReward(player, SharedRewards.fireSignal("packed", { "signals", "TestHarness", "packed" }, {
			"Sword",
			"extra",
		}, false))

		expect(ok).toBeTrue()
		expect(received[1]).toBe(player)
		expect(typeof(received[2])).toBe("table")
		expect((received[2] :: { any })[1]).toBe("Sword")
		expect((received[2] :: { any })[2]).toBe("extra")

		if connection then
			connection:Disconnect()
		end
		player:Destroy()
	end)

	it("rejects an unknown reward operation", function()
		local player = Harness.makePlayer()
		local ok, err = fnApplyReward(player, {
			name = "Unknown",
			opType = 999,
			value = 1,
			path = dataUpdateSignal,
			params = { PATHS.userData.coins },
		})

		expect(ok).toBeFalse()
		expect(err).toContain("Unknown operation type")
		player:Destroy()
	end)

	it("rejects increment without a target path", function()
		local player = Harness.makePlayer()
		local ok, err = fnApplyReward(player, {
			name = "Increment",
			opType = ENUMS.RewardOpTypes.Increment,
			value = 1,
			path = dataUpdateSignal,
			params = {},
		})

		expect(ok).toBeFalse()
		expect(err).toContain("path Parameter")
		player:Destroy()
	end)

	it("rejects increment when the value is not a number", function()
		local player = Harness.makePlayer()
		local ok, err = fnApplyReward(player, {
			name = "Increment",
			opType = ENUMS.RewardOpTypes.Increment,
			value = "nope",
			path = dataUpdateSignal,
			params = { PATHS.userData.coins },
		})

		expect(ok).toBeFalse()
		expect(err).toContain("number")
		player:Destroy()
	end)

	it("rejects a nil signal path", function()
		local player = Harness.makePlayer()
		local ok, err = fnApplyReward(player, {
			name = "Fire",
			opType = ENUMS.RewardOpTypes.FireSignal,
			value = nil,
			path = nil,
			params = {},
		})

		expect(ok).toBeFalse()
		expect(err).toContain("Signal path is nil")
		player:Destroy()
	end)

	it("fires a signal when params are omitted", function()
		CommsHub.signals.TestHarness = {
			empty = "TestHarness:Empty",
		}

		local fired = false
		local connection = SignalManager.connectToSignal("TestHarness:Empty", function()
			fired = true
		end)

		local player = Harness.makePlayer()
		local ok = fnApplyReward(player, {
			name = "empty",
			opType = ENUMS.RewardOpTypes.FireSignal,
			value = nil,
			path = { "signals", "TestHarness", "empty" },
		})

		expect(ok).toBeTrue()
		expect(fired).toBeTrue()

		if connection then
			connection:Disconnect()
		end
		player:Destroy()
	end)

	it("rejects an invalid signal path", function()
		local player = Harness.makePlayer()
		local ok, err = fnApplyReward(player, {
			name = "Fire",
			opType = ENUMS.RewardOpTypes.FireSignal,
			value = nil,
			path = { "signals", "DoesNotExist" },
			params = {},
		})

		expect(ok).toBeFalse()
		expect(err).toContain("invalid")
		player:Destroy()
	end)

	it("rejects params that are not an array", function()
		local player = Harness.makePlayer()
		local ok, err = fnApplyReward(player, {
			name = "Fire",
			opType = ENUMS.RewardOpTypes.FireSignal,
			value = nil,
			path = dataUpdateSignal,
			params = { extra = true } :: any,
		})

		expect(ok).toBeFalse()
		expect(err).toContain("array")
		player:Destroy()
	end)

	it("stops applying rewards at the first failure and reports the index", function()
		local player = Harness.makePlayer({ coins = 0 })
		local ok, err, index = fnApplyRewards(player, {
			SharedRewards.reward("coins", 4, dataUpdateSignal),
			{
				name = "Broken",
				opType = 999,
				value = 0,
				path = dataUpdateSignal,
				params = { PATHS.userData.coins },
			},
			SharedRewards.reward("coins", 4, dataUpdateSignal),
		})

		expect(ok).toBeFalse()
		expect(err).toContain("Unknown operation type")
		expect(index).toBe(2)
		expect(Harness.getCoins(player)).toBe(4)
		player:Destroy()
	end)

	it("applies rollback rewards only up to the failed index", function()
		local player = Harness.makePlayer({ coins = 0 })
		local ok, _, index = RuleEngine.applyRollback(player, {
			context = ENUMS.ContextTypes.Server,
			rollbackRewards = {
				SharedRewards.reward("coins", 1, dataUpdateSignal),
				SharedRewards.reward("coins", 10, dataUpdateSignal),
				SharedRewards.reward("coins", 100, dataUpdateSignal),
			},
		}, 2)

		expect(ok).toBeTrue()
		expect(index).toBe(1)
		expect(Harness.getCoins(player)).toBe(1)
		player:Destroy()
	end)
end
