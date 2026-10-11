--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`RuleEngineTests`)

-- References
local Harness = require(script.Harness)

-- Types
type SpecFn = Harness.SpecFn

-- Variables
local suites: { { name: string, spec: SpecFn } } = {
	{ name = "Engine", spec = require(script["Engine.spec"]) },
	{ name = "Conditions", spec = require(script["Conditions.spec"]) },
	{ name = "RewardCases", spec = require(script["RewardCases.spec"]) },
	{ name = "Helpers", spec = require(script["Helpers.spec"]) },
	{ name = "Samples", spec = require(script["Samples.spec"]) },
}

-- Module
local Tests = {}

-- Public
--[=[
	Run every Rule Engine spec and log a pass/fail summary
	@return boolean - Whether every test passed
	@return number - Passed count
	@return number - Failed count
]=]
function Tests.run(): (boolean, number, number)
	local passed = 0
	local failed = 0
	local failures: { string } = {}

	Logger:print("Running Rule Engine tests...")

	for _, suite in ipairs(suites) do
		Logger:print(`[{suite.name}]`)

		local function it(name: string, fn: () -> ()): ()
			local ok, err = pcall(fn)
			if ok then
				passed += 1
				Logger:print(`  PASS  {name}`)
			else
				failed += 1
				local message = `{suite.name} / {name}: {tostring(err)}`
				table.insert(failures, message)
				Logger:warn(`  FAIL  {name}\n    {tostring(err)}`)
			end
		end

		local specOk, specErr = pcall(function()
			suite.spec(it, Harness.expect)
		end)

		if not specOk then
			failed += 1
			local message = `{suite.name}: suite error: {tostring(specErr)}`
			table.insert(failures, message)
			Logger:warn(`  FAIL  suite could not run\n    {tostring(specErr)}`)
		end
	end

	local total = passed + failed

	if failed == 0 then
		Logger:print(`Rule Engine tests: {passed}/{total} passed`)
	else
		Logger:warn(`Rule Engine tests: {passed}/{total} passed, {failed} failed`)
		for _, message in ipairs(failures) do
			Logger:warn(`  - {message}`)
		end
	end

	return failed == 0, passed, failed
end

return Tests
