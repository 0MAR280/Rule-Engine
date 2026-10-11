--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Tests = require(Modules.RuleEngine.Tests)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`TestService`)

-- Module
local TestService = {}

-- Public
--[=[
	Run the Rule Engine test suite
]=]
function TestService.init(): typeof(TestService)
	local fn = `init`
	local ran, allPassed, passed, failed = pcall(Tests.run)

	if not ran then
		Logger:warn(`{fn}: Test suite crashed: {tostring(allPassed)}`)
		return TestService
	end

	local total = (passed or 0) + (failed or 0)

	if allPassed then
		Logger:print(`{fn}: {passed}/{total} passed`)
	else
		Logger:warn(`{fn}: {passed}/{total} passed, {failed} failed`)
	end

	return TestService
end

return TestService
