-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`Apply Props-fn`)

-- Function
--[=[
	Apply properties from a config table to an instance safely
    @param instance Instance - The instance to apply properties to
    @param props { [string]: any } - A table of properties to apply
]=]
local function applyProps(instance: Instance, props: { [string]: any }): ()
	for propName, propValue in pairs(props) do
		local success, errorMessage = pcall(function()
			instance[propName] = propValue
		end)

		if not success then
			local msg = `ApplyProps: Failed to set '{propName}' on '{instance.ClassName}'. Reason: {errorMessage}`
			Logger:warn(msg)
		end
	end
end

return applyProps
