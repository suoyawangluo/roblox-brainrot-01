-- Brainrot Bazaar: builds the 3D model of one brainrot from its catalog entry.
-- A model is a colored body cube with a hat, two eyes, and a billboard label
-- that reads its name, rarity and money-per-second, so a player can judge a
-- brainrot at a glance while it rides the conveyor.

local BrainrotFactory = {}

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local function makePart(name, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

-- Build the hat for a brainrot: a top hat, a crown, a beanie, or nothing.
local function addHat(entry, body, bodySize)
	if entry.hat == "TopHat" then
		local brim = makePart("HatBrim", Vector3.new(bodySize * 0.9, 0.3, bodySize * 0.9), Color3.fromRGB(30, 30, 30), body.Parent)
		brim.CFrame = body.CFrame * CFrame.new(0, bodySize / 2 + 0.15, 0)
		local top = makePart("HatTop", Vector3.new(bodySize * 0.5, bodySize * 0.6, bodySize * 0.5), Color3.fromRGB(30, 30, 30), body.Parent)
		top.CFrame = body.CFrame * CFrame.new(0, bodySize / 2 + 0.3 + bodySize * 0.3, 0)
	elseif entry.hat == "Crown" then
		local crown = makePart("Crown", Vector3.new(bodySize * 0.7, bodySize * 0.35, bodySize * 0.7), Color3.fromRGB(255, 215, 0), body.Parent)
		crown.Material = Enum.Material.Neon
		crown.CFrame = body.CFrame * CFrame.new(0, bodySize / 2 + bodySize * 0.17, 0)
	elseif entry.hat == "Beanie" then
		local beanie = makePart("Beanie", Vector3.new(bodySize * 0.7, bodySize * 0.7, bodySize * 0.7), Color3.fromRGB(200, 60, 60), body.Parent)
		beanie.Shape = Enum.PartType.Ball
		beanie.CFrame = body.CFrame * CFrame.new(0, bodySize / 2 + bodySize * 0.2, 0)
	end
end

-- Two googly eyes on the body's front face, so the brainrot looks alive.
local function addEyes(body, bodySize)
	local eyeSize = Vector3.new(bodySize * 0.22, bodySize * 0.28, 0.2)
	local pupilSize = Vector3.new(bodySize * 0.1, bodySize * 0.14, 0.2)
	local front = bodySize / 2 + 0.1
	for _, side in { -1, 1 } do
		local eye = makePart("Eye", eyeSize, Color3.fromRGB(255, 255, 255), body.Parent)
		eye.CFrame = body.CFrame * CFrame.new(side * bodySize * 0.2, bodySize * 0.08, front)
		local pupil = makePart("Pupil", pupilSize, Color3.fromRGB(20, 20, 20), body.Parent)
		pupil.CFrame = body.CFrame * CFrame.new(side * bodySize * 0.2, bodySize * 0.08, front + 0.05)
	end
end

-- The floating label: name, rarity, income, and a mutation tag when mutated.
local function addLabel(model, body, entry, mutation, income)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(220, 84)
	gui.StudsOffsetWorldSpace = Vector3.new(0, entry.bodySize + 2.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local text = Instance.new("TextLabel")
	text.Name = "Label"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 0.35
	text.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansBold
	text.Parent = gui

	local line = entry.name .. "\n" .. entry.rarity .. "  $" .. income .. "/s"
	if mutation ~= nil then
		line = mutation .. " " .. line
	end
	text.Text = line
end

-- Build one brainrot model at a position, facing along +X (the conveyor's way).
function BrainrotFactory.buildBrainrotModel(entry, mutation, income, position)
	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. entry.id

	local bodyColor = entry.color
	if mutation ~= nil then
		local mut = BrainrotData.MUTATIONS[mutation]
		if mut ~= nil then
			bodyColor = mut.color
		end
	end

	local body = makePart("Body", Vector3.new(entry.bodySize, entry.bodySize, entry.bodySize), bodyColor, model)
	body.CFrame = CFrame.new(position)
	body.CanCollide = false

	addHat(entry, body, entry.bodySize)
	addEyes(body, entry.bodySize)
	addLabel(model, body, entry, mutation, income)

	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Mutation", mutation or "")
	model:SetAttribute("Price", entry.cost)
	model:SetAttribute("Income", income)
	model.PrimaryPart = body
	return model
end

-- The buy prompt on a conveyor brainrot: walk up and hold nothing, just press.
function BrainrotFactory.attachBuyPrompt(model, entry, income)
	local body = model.PrimaryPart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy $" .. entry.cost
	prompt.ObjectText = entry.name .. " ($" .. income .. "/s)"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	return prompt
end

-- The steal prompt on a brainrot owned by someone else's base.
function BrainrotFactory.attachStealPrompt(model, entry, income)
	local body = model.PrimaryPart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal!"
	prompt.ObjectText = entry.name .. " ($" .. income .. "/s)"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	return prompt
end

return BrainrotFactory
