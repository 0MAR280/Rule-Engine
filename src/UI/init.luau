--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnTraversePath = require(Modules.fn.traversePath)
local PATHS = require(Modules.Data.PATHS)

-- References
local player = Players.LocalPlayer

-- Types
type Counter = {
	name: string,
	path: { string },
	label: TextLabel,
	valueObject: ValueBase?,
	valueConnection: RBXScriptConnection?,
}

-- Module
local UI = {}
local screenGui: ScreenGui? = nil
local counters: { Counter } = {}
local hierarchyConnections: { RBXScriptConnection } = {}

local counterDefinitions = {
	{ name = "Coins", path = PATHS.userData.coins },
	{ name = "Points", path = PATHS.userCache.points },
	{ name = "Playtime", path = PATHS.userCache.playtime },
}

-- Functions
-- Private
--[=[
	Resolve the counter's configured path and keep its label and value listener current
	@param counter Counter The counter to update
]=]
local function updateCounter(counter: Counter): ()
	local resolvedValue = fnTraversePath(player, counter.path)
	local valueObject: ValueBase? = nil

	if typeof(resolvedValue) == "Instance" and resolvedValue:IsA("ValueBase") then
		valueObject = resolvedValue
	end

	if counter.valueObject ~= valueObject then
		if counter.valueConnection then
			counter.valueConnection:Disconnect()
			counter.valueConnection = nil
		end

		counter.valueObject = valueObject
		if valueObject then
			local watchedValue = valueObject
			--[=[
				Update the label when the bound ValueBase changes
			]=]
			counter.valueConnection = watchedValue:GetPropertyChangedSignal("Value"):Connect(function(): ()
				counter.label.Text = `{counter.name}: {tostring(watchedValue.Value)}`
			end)
		end
	end

	counter.label.Text = if valueObject then `{counter.name}: {tostring(valueObject.Value)}` else `{counter.name}: --`
end

--[=[
	Re-resolve every counter after the player's data hierarchy changes
]=]
local function refreshCounters(): ()
	for _, counter in ipairs(counters) do
		updateCounter(counter)
	end
end

--[=[
	Create and configure a text label for the UI panel
	@param parent Instance The parent for the label
	@param name string The label's name
	@param text string The label's initial text
	@param height number The label's height in pixels
	@param order number The label's layout order
	@return TextLabel The created label
]=]
local function makeLabel(parent: Instance, name: string, text: string, height: number, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(235, 239, 245)
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.Parent = parent

	return label
end

-- Public
--[=[
	Create the player data ScreenGui and start tracking the configured values
	@return ScreenGui The created or existing ScreenGui
]=]
function UI.init(): ScreenGui
	if screenGui and screenGui.Parent then
		return screenGui
	end

	local playerGui = player:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui") :: ScreenGui
	screenGui.Name = "RuleEngineDataGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.Size = UDim2.fromOffset(240, 0)
	panel.Position = UDim2.fromOffset(16, 16)
	panel.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	makeLabel(panel, "Title", "Player Data", 30, 0).Font = Enum.Font.GothamBold

	for index, definition in ipairs(counterDefinitions) do
		local label = makeLabel(panel, definition.name, `{definition.name}: --`, 28, index)
		table.insert(counters, {
			name = definition.name,
			path = definition.path,
			label = label,
			valueObject = nil,
			valueConnection = nil,
		})
	end

	refreshCounters()
	--[=[
		Defer a counter refresh until Roblox finishes adding the descendant
	]=]
	table.insert(
		hierarchyConnections,
		player.DescendantAdded:Connect(function(): ()
			task.defer(refreshCounters)
		end)
	)
	--[=[
		Defer a counter refresh until Roblox finishes removing the descendant
	]=]
	table.insert(
		hierarchyConnections,
		player.DescendantRemoving:Connect(function(): ()
			task.defer(refreshCounters)
		end)
	)

	return screenGui :: ScreenGui
end

return UI
