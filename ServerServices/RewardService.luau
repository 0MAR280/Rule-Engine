--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local fnIsAPlayerCharacter = require(Modules.fn.isAPlayerCharacter)
local RuleEngine = require(Modules.RuleEngine)
local Rewards = require(Modules.Data.Rewards)
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(`RewardService`)

-- Variables
local startPosition = Vector3.new(0, 0.5, -15)
local padding = Vector3.zAxis * -10
local partsCount = 0

-- Types
type GameReward = Types.GameReward

-- Module
local RewardService = {}
local Private = {}

-- Functions
-- Private
--[=[
    Make a reward part
    @param part BasePart - The part to use for touch detection
    @param reward GameReward - The game reward to use its data
]=]
function Private.setupRewardPart(part: BasePart, reward: GameReward): ()
	local fn = `setupRewardPart`
	local cd = false

	part.Touched:Connect(function(hit: BasePart): ()
		if cd then
			return
		end

		cd = true

		task.delay(1, function()
			cd = false
		end)

		local player = fnIsAPlayerCharacter(hit)

		if player then
			local conditionsPassed, rewardsApplied, rollbackApplied, err =
				RuleEngine.excuteRule(player, reward.ruleData)

			if not conditionsPassed then
				local msg1 = `{fn}: Conditions were not satisfied!`
				local msg2 = `Reason: {err}`
				Logger:warn(`{msg1}\n{msg2}`)
			elseif not rewardsApplied then
				local msg1 = `{fn}: Rewards were not applied!`
				local msg2 = `Reason: {err}`

				if typeof(rollbackApplied) == "boolean" then
					if rollbackApplied then
						msg1 = `Rewards were not applied, and Rollback was successfull!`
					else
						msg1 = `Rewards were not applied, and Rollback failed!`
					end
				end

				Logger:warn(`{msg1}\n{msg2}`)
			else
				Logger:print(`{fn}: Conditions were satisfied and Rewards were applied!`)
			end
		end
	end)
end

--[=[
    Make a reward part
    @param reward GameReward - The game reward to use its data
    @return Basepart - The reward part
]=]
function Private.makeRewardPart(reward: GameReward): BasePart
	local part = Instance.new("Part")
	part.Size = Vector3.new(5, 1, 2)
	part.Position = startPosition + padding * partsCount
	part.Anchored = true

	local attributes = reward.attributes
	part.Color = attributes.color

	local billboard = Instance.new("BillboardGui", part)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	billboard.Size = UDim2.fromScale(5, 1)
	billboard.AlwaysOnTop = true
	billboard.Adornee = part

	local textLabel = Instance.new("TextLabel", billboard)
	textLabel.TextScaled = true
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Text = `<b>{attributes.description}</b>`
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.RichText = true

	part.Parent = workspace

	return part
end

--[=[
    Set up the reward parts
]=]
function Private.setupRewardParts(): ()
	for id, reward in ipairs(Rewards) do
		local rewardPart = Private.makeRewardPart(reward)
		Private.setupRewardPart(rewardPart, reward)
		partsCount += 1
	end
end

-- Public
--[=[
	Initialize the module
]=]
function RewardService.init(): ()
	local fn = `init`

	Private.setupRewardParts()
	Logger:print(`{fn}: Module was initialized!`)

	return RewardService
end

return RewardService
