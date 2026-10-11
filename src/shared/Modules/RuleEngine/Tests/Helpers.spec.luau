--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnCheckContext = require(Modules.RuleEngine.Helpers.CheckContext)
local fnWalkPayload = require(Modules.RuleEngine.Helpers.WalkPayload)
local fnSolveParam = require(Modules.RuleEngine.Helpers.SolveParam)
local ENUMS = require(Modules.Data.ENUMS)
local Harness = require(script.Parent.Harness)

-- Types
type ItFn = Harness.ItFn
type ExpectFn = Harness.ExpectFn

-- Spec
return function(it: ItFn, expect: ExpectFn): ()
	it("allows Server and Both context on the server", function()
		expect(fnCheckContext(ENUMS.ContextTypes.Server)).toBeTrue()
		expect(fnCheckContext(ENUMS.ContextTypes.Both)).toBeTrue()
	end)

	it("rejects Client context on the server", function()
		expect(fnCheckContext(ENUMS.ContextTypes.Client)).toBeFalse()
	end)

	it("allows a missing context", function()
		expect(fnCheckContext(nil :: any)).toBeTrue()
	end)

	it("walks a nested payload path", function()
		expect(fnWalkPayload({
			order = {
				item = {
					id = "sword",
				},
			},
		}, { "order", "item", "id" })).toBe("sword")
	end)

	it("returns nil when the payload path is missing", function()
		expect(fnWalkPayload({ order = {} }, { "order", "item", "id" })).toBeNil()
	end)

	it("fails closed when payload or path is not a table", function()
		expect(fnWalkPayload(nil, { "a" })).toBeNil()
		expect(fnWalkPayload({ a = 1 }, nil)).toBeNil()
		expect(fnWalkPayload("nope" :: any, { "a" })).toBeNil()
	end)

	it("stops walking when a payload node is not a table", function()
		expect(fnWalkPayload({ a = 1 }, { "a", "b" })).toBeNil()
	end)

	it("resolves Value and EventPayload params", function()
		local player = Harness.makePlayer()
		expect(fnSolveParam(player, {
			type = ENUMS.ParamOpTypes.Value,
			value = "literal",
		})).toBe("literal")
		expect(fnSolveParam(player, {
			type = ENUMS.ParamOpTypes.EventPayload,
			path = { "tier" },
		}, { tier = "gold" })).toBe("gold")
		player:Destroy()
	end)

	it("resolves Now as os.time", function()
		local player = Harness.makePlayer()
		local now = fnSolveParam(player, { type = ENUMS.ParamOpTypes.Now })
		expect(typeof(now)).toBe("number")
		expect((now :: number) >= os.time() - 1).toBeTrue()
		player:Destroy()
	end)

	it("resolves DataPath and CachePath from the player tree", function()
		local player = Harness.makePlayer({ coins = 9, points = 2 })
		expect(fnSolveParam(player, {
			type = ENUMS.ParamOpTypes.DataPath,
			path = { "leaderstats", "Coins" },
		})).toBe(9)
		expect(fnSolveParam(player, {
			type = ENUMS.ParamOpTypes.CachePath,
			path = { "SessionStats", "Points" },
		})).toBe(2)
		player:Destroy()
	end)
end
