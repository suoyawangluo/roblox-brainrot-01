-- Brainrot Bazaar: the HUD. Cash, income and rebirths across the top
-- (kept clear of Roblox's own top-left menu buttons), a wave banner under
-- them, a notification line in the middle, and two buttons at the bottom:
-- lock your base, and rebirth. The server owns every number; this script
-- only draws it and asks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local HudEvent = ReplicatedStorage:WaitForChild("HudEvent")
local LockBaseEvent = ReplicatedStorage:WaitForChild("LockBaseEvent")
local RebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local function makeLabel(name, parent, anchor, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = anchor
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = false
	label.Parent = parent
	return label
end

-- Top-center money readouts.
local cashLabel = makeLabel("CashLabel", gui, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 12), UDim2.new(0, 320, 0, 44), 28, Color3.fromRGB(255, 220, 60))
cashLabel.Text = "Cash: $100"
local incomeLabel = makeLabel("IncomeLabel", gui, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 62), UDim2.new(0, 320, 0, 32), 20, Color3.fromRGB(140, 230, 140))
incomeLabel.Text = "Income: $0/s"
local rebirthLabel = makeLabel("RebirthLabel", gui, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 100), UDim2.new(0, 320, 0, 28), 18, Color3.fromRGB(200, 170, 255))
rebirthLabel.Text = "Rebirths: 0  (+0% income)"

-- The wave banner, hidden until a wave is coming.
local waveBanner = makeLabel("WaveBanner", gui, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 140), UDim2.new(0, 460, 0, 40), 22, Color3.fromRGB(255, 255, 255))
waveBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
waveBanner.Text = "NOODLE TSUNAMI INCOMING - GET TO YOUR BASE!"
waveBanner.Visible = false

-- One line of news in the middle of the screen.
local notifyLabel = makeLabel("NotifyLabel", gui, Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.35, 0), UDim2.new(0, 560, 0, 36), 20, Color3.fromRGB(255, 255, 255))
notifyLabel.Visible = false

-- Bottom-center action buttons.
local function makeButton(name, text, offsetX)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, offsetX, 1, -16)
	button.Size = UDim2.new(0, 220, 0, 52)
	button.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 22
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.Parent = gui
	return button
end

local lockButton = makeButton("LockButton", "Lock Base (60s)", -120)
local rebirthButton = makeButton("RebirthButton", "Rebirth", 120)
rebirthButton.BackgroundColor3 = Color3.fromRGB(140, 60, 180)

lockButton.MouseButton1Click:Connect(function()
	Effects.popButton(lockButton)
	LockBaseEvent:FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	Effects.popButton(rebirthButton)
	RebirthEvent:FireServer()
end)

-- Keep the readouts in step with the server's leaderstats.
local stats = player:WaitForChild("leaderstats")
local cashValue = stats:WaitForChild("Cash")
local incomeValue = stats:WaitForChild("Income")
local rebirthValue = stats:WaitForChild("Rebirths")

local function refreshMoney()
	cashLabel.Text = "Cash: $" .. cashValue.Value
	incomeLabel.Text = "Income: $" .. incomeValue.Value .. "/s"
	rebirthLabel.Text = "Rebirths: " .. rebirthValue.Value .. "  (+" .. math.floor(rebirthValue.Value * 25 + 0.5) .. "% income)"
end

cashValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
incomeValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
rebirthValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
refreshMoney()

-- Server news: notifications and wave warnings.
HudEvent.OnClientEvent:Connect(function(payload)
	if payload.type == "notify" then
		Effects.showNotification(notifyLabel, payload.text)
	elseif payload.type == "wave" then
		waveBanner.Visible = true
		Effects.flashBanner(waveBanner)
		task.delay(17, function()
			waveBanner.Visible = false
		end)
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
