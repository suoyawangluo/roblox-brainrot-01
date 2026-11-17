-- Brainrot Bazaar: the server. It owns every player's cash, brainrots and
-- base, runs the conveyor, the income tick, stealing, base locks, rebirths
-- and the Noodle Tsunami. The client only draws the HUD and asks; every
-- decision that moves money or a brainrot is made here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local Economy = require(script.Parent.Economy)
local Waves = require(script.Parent.Waves)

local HudEvent = ReplicatedStorage:WaitForChild("HudEvent")
local LockBaseEvent = ReplicatedStorage:WaitForChild("LockBaseEvent")
local RebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent")

-- One record per player. owned[slot] = { id, mutation, income, model }.
local playerData = {}
local plotOwner = {} -- plotIndex -> Player
local conveyor = {} -- { model, entry, income, mutation, x }

local function now()
	return os.clock()
end

local function sendNotify(player, text)
	HudEvent:FireClient(player, { type = "notify", text = text })
end

local function sendWaveWarning(seconds)
	for _, player in Players:GetPlayers() do
		HudEvent:FireClient(player, { type = "wave", seconds = seconds })
	end
end

-- The plot center this player owns, or nil.
local function getPlayerPlot(player)
	local data = playerData[player]
	if data == nil then
		return nil
	end
	return Config.PLOTS[data.plotIndex]
end

-- Where a brainrot sits on a base slot: plot center plus the slot offset.
local function slotPosition(plotIndex, slotIndex, bodySize)
	local plot = Config.PLOTS[plotIndex]
	local offset = Config.SLOT_OFFSETS[slotIndex]
	return plot + offset + Vector3.new(0, bodySize / 2, 0)
end

local function setLeaderstats(player, data)
	local stats = player:FindFirstChild("leaderstats")
	if stats == nil then
		return
	end
	local cash = stats:FindFirstChild("Cash")
	local income = stats:FindFirstChild("Income")
	local rebirths = stats:FindFirstChild("Rebirths")
	if cash ~= nil then
		cash.Value = data.cash
	end
	if income ~= nil then
		income.Value = Economy.incomePerSecond(data.owned, data.rebirths)
	end
	if rebirths ~= nil then
		rebirths.Value = data.rebirths
	end
end

-- Give a joining player a free plot and starting cash.
local function setupPlayer(player)
	local plotIndex = nil
	for index = 1, #Config.PLOTS do
		if plotOwner[index] == nil then
			plotIndex = index
			break
		end
	end
	if plotIndex == nil then
		plotIndex = 1 -- the bazaar is full; share plot one
	end
	plotOwner[plotIndex] = player

	local data = {
		cash = Config.START_CASH,
		owned = {},
		rebirths = 0,
		plotIndex = plotIndex,
		lockedUntil = 0,
		lockReadyAt = 0,
		stealReadyAt = 0,
	}
	playerData[player] = data

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = data.cash
	cashValue.Parent = stats
	local incomeValue = Instance.new("IntValue")
	incomeValue.Name = "Income"
	incomeValue.Value = 0
	incomeValue.Parent = stats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = stats
	stats.Parent = player

	sendNotify(player, "Welcome to Brainrot Bazaar! Buy brainrots off the belt, park them on your base.")
end

-- Clean a leaving player's plot and brainrots.
local function teardownPlayer(player)
	local data = playerData[player]
	if data ~= nil then
		for _, slot in data.owned do
			if slot ~= nil and slot.model ~= nil then
				slot.model:Destroy()
			end
		end
		plotOwner[data.plotIndex] = nil
		playerData[player] = nil
	end
end

-- Buy the brainrot riding the belt: cash and a free slot, then it is yours.
local function buyBrainrot(player, conveyorItem)
	local data = playerData[player]
	if data == nil or conveyorItem.model.Parent == nil then
		return
	end
	local entry = conveyorItem.entry
	if data.cash < entry.cost then
		sendNotify(player, "Not enough cash for " .. entry.name .. " ($" .. entry.cost .. ").")
		return
	end
	local slotIndex = Economy.freeSlotIndex(data.owned)
	if slotIndex == nil then
		sendNotify(player, "Your base is full! Rebirth to earn more, or sell nothing yet.")
		return
	end

	data.cash -= entry.cost
	local mutation = Economy.rollMutation()
	local income = BrainrotData.incomeOf(entry, mutation)

	-- Take it off the belt.
	for index, item in conveyor do
		if item == conveyorItem then
			table.remove(conveyor, index)
			break
		end
	end

	local model = conveyorItem.model
	local prompt = model:FindFirstChild("BuyPrompt", true)
	if prompt ~= nil then
		prompt:Destroy()
	end
	model:PivotTo(CFrame.new(slotPosition(data.plotIndex, slotIndex, entry.bodySize)))
	model.Parent = Workspace
	BrainrotFactory.attachStealPrompt(model, entry, income)

	data.owned[slotIndex] = { id = entry.id, mutation = mutation, income = income, model = model }
	setLeaderstats(player, data)

	if mutation ~= nil then
		sendNotify(player, "MUTATION! You bought a " .. mutation .. " " .. entry.name .. " earning $" .. income .. "/s!")
	else
		sendNotify(player, "Bought " .. entry.name .. " for $" .. entry.cost .. ". It earns $" .. income .. "/s on your base.")
	end
end

-- Steal a brainrot off someone else's base, if their base is unlocked and
-- your own steal is off cooldown. The victim's base auto-locks afterwards.
local function attemptSteal(thief, model)
	local thiefData = playerData[thief]
	if thiefData == nil then
		return
	end
	local owner = nil
	local ownerData = nil
	local ownerSlot = nil
	for player, data in playerData do
		for slotIndex, slot in data.owned do
			if slot ~= nil and slot.model == model then
				owner = player
				ownerData = data
				ownerSlot = slotIndex
				break
			end
		end
		if owner ~= nil then
			break
		end
	end
	if owner == nil or owner == thief then
		return
	end
	if now() < ownerData.lockedUntil then
		sendNotify(thief, owner.Name .. "'s base is locked. Try another base!")
		return
	end
	if now() < thiefData.stealReadyAt then
		sendNotify(thief, "Your steal is on cooldown. Wait a little!")
		return
	end
	local slotIndex = Economy.freeSlotIndex(thiefData.owned)
	if slotIndex == nil then
		sendNotify(thief, "Your base is full! No room for a stolen brainrot.")
		return
	end

	local slot = ownerData.owned[ownerSlot]
	ownerData.owned[ownerSlot] = nil
	ownerData.lockedUntil = now() + Config.STEAL_VICTIM_LOCK_SECONDS
	thiefData.stealReadyAt = now() + Config.STEAL_COOLDOWN_SECONDS

	local entry = BrainrotData.getById(slot.id)
	model:PivotTo(CFrame.new(slotPosition(thiefData.plotIndex, slotIndex, entry.bodySize)))
	thiefData.owned[slotIndex] = slot
	setLeaderstats(thief, thiefData)
	setLeaderstats(owner, ownerData)

	sendNotify(thief, "Stole " .. entry.name .. " from " .. owner.Name .. "! Run home!")
	sendNotify(owner, thief.Name .. " stole your " .. entry.name .. "! Your base locked for " .. Config.STEAL_VICTIM_LOCK_SECONDS .. "s.")
end

-- Lock your base so nobody can steal from it for a while.
local function lockBase(player)
	local data = playerData[player]
	if data == nil then
		return
	end
	if now() < data.lockReadyAt then
		sendNotify(player, "Base lock is on cooldown.")
		return
	end
	data.lockedUntil = now() + Config.LOCK_DURATION_SECONDS
	data.lockReadyAt = now() + Config.LOCK_COOLDOWN_SECONDS
	sendNotify(player, "Base locked for " .. Config.LOCK_DURATION_SECONDS .. " seconds. Nobody can steal from you!")
end

-- Rebirth: give up your cash and brainrots for a permanent income bonus.
local function doRebirth(player)
	local data = playerData[player]
	if data == nil then
		return
	end
	local cost = Economy.rebirthCost(data.rebirths)
	if data.cash < cost then
		sendNotify(player, "Rebirth costs $" .. cost .. ". You have $" .. data.cash .. ".")
		return
	end
	for _, slot in data.owned do
		if slot ~= nil and slot.model ~= nil then
			slot.model:Destroy()
		end
	end
	data.owned = {}
	data.cash = Config.START_CASH
	data.rebirths += 1
	setLeaderstats(player, data)
	sendNotify(player, "REBIRTH #" .. data.rebirths .. "! All income is now +" .. math.floor(data.rebirths * Config.REBIRTH_INCOME_BONUS * 100 + 0.5) .. "%.")
end

-- Spawn one brainrot on the west end of the belt and set it walking east.
local function spawnConveyorBrainrot()
	if #conveyor >= Config.MAX_CONVEYOR_BRAINROTS then
		return
	end
	local entry = BrainrotData.pickRandom()
	local income = entry.income
	local startX = Config.CONVEYOR_START_X
	local y = 2 + entry.bodySize / 2
	local model = BrainrotFactory.buildBrainrotModel(entry, nil, income, Vector3.new(startX, y, Config.CONVEYOR_Z))
	model.Parent = Workspace
	local prompt = BrainrotFactory.attachBuyPrompt(model, entry, income)
	prompt.Triggered:Connect(function(player)
		for _, item in conveyor do
			if item.model == model then
				buyBrainrot(player, item)
				break
			end
		end
	end)
	table.insert(conveyor, { model = model, entry = entry, income = income, mutation = nil, x = startX })
end

-- Walk every belt brainrot east, one step per frame; drop it at the east end.
local function stepConveyor(dt)
	for index = #conveyor, 1, -1 do
		local item = conveyor[index]
		if item.model.Parent == nil then
			table.remove(conveyor, index)
		else
			item.x += Config.CONVEYOR_SPEED * dt
			local y = 2 + item.entry.bodySize / 2
			item.model:PivotTo(CFrame.new(item.x, y, Config.CONVEYOR_Z))
			if item.x >= Config.CONVEYOR_END_X then
				item.model:Destroy()
				table.remove(conveyor, index)
			end
		end
	end
end

-- Pay every player's income once a second.
local function tickIncome()
	while true do
		task.wait(Config.INCOME_TICK_SECONDS)
		for player, data in playerData do
			data.cash += Economy.incomePerSecond(data.owned, data.rebirths)
			setLeaderstats(player, data)
		end
	end
end

-- Keep the belt fed with fresh brainrots.
local function runSpawner()
	while true do
		task.wait(Config.SPAWN_INTERVAL_SECONDS)
		spawnConveyorBrainrot()
	end
end

-- The Noodle Tsunami cycle: warn, then sweep, then wait for the next one.
local function runWaves()
	while true do
		task.wait(Config.WAVE_INTERVAL_SECONDS)
		sendWaveWarning(5)
		task.wait(5)
		Waves.runWave(function(caughtPlayer)
			local data = playerData[caughtPlayer]
			if data == nil then
				return
			end
			local loss = Economy.waveLoss(data.cash)
			data.cash -= loss
			setLeaderstats(caughtPlayer, data)
			local character = caughtPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root ~= nil then
				local plot = Config.PLOTS[data.plotIndex]
				root.CFrame = CFrame.new(plot.X, plot.Y + 4, plot.Z)
			end
			sendNotify(caughtPlayer, "The Noodle Tsunami caught you! Lost $" .. loss .. ". Get back to your base next time!")
		end, getPlayerPlot)
	end
end

-- Hook a steal prompt the moment a model is placed on a base.
local function watchStealPrompts()
	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") and descendant.Name == "StealPrompt" then
			descendant.Triggered:Connect(function(player)
				local model = descendant:FindFirstAncestorOfClass("Model")
				if model ~= nil then
					attemptSteal(player, model)
				end
			end)
		end
	end)
end

LockBaseEvent.OnServerEvent:Connect(lockBase)
RebirthEvent.OnServerEvent:Connect(doRebirth)
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(teardownPlayer)
RunService.Heartbeat:Connect(stepConveyor)
watchStealPrompts()

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

task.spawn(tickIncome)
task.spawn(runSpawner)
task.spawn(runWaves)
