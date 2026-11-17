-- Brainrot Bazaar: the Noodle Tsunami. Every so often a wall of noodles
-- sweeps the plaza from west to east. Players caught outside their own base
-- are knocked back to it and lose a share of their cash. The wall is a real
-- moving part, and the catch check runs while it sweeps.

local Waves = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

-- Is a position inside the given player's base plot (an 18-by-18 square)?
local function isInsideBase(position, plotCenter)
	local dx = math.abs(position.X - plotCenter.X)
	local dz = math.abs(position.Z - plotCenter.Z)
	return dx <= 9 and dz <= 9
end

-- Build the wave wall: a tall translucent red slab spanning the plaza.
local function buildWall()
	local wall = Instance.new("Part")
	wall.Name = "NoodleTsunami"
	wall.Size = Vector3.new(4, 30, 170)
	wall.Color = Color3.fromRGB(220, 60, 60)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.45
	wall.Anchored = true
	wall.CanCollide = false
	wall.CFrame = CFrame.new(-85, 15, 0)
	wall.Parent = Workspace
	return wall
end

-- Run one wave. onPlayerCaught is called once per player caught outside
-- their base, with the player; the caller decides the penalty.
-- Returns the wall part so the caller can watch it if it likes.
function Waves.runWave(onPlayerCaught, getPlayerPlot)
	local wall = buildWall()
	local caught = {}

	local sweep = TweenService:Create(wall, TweenInfo.new(Config.WAVE_SWEEP_SECONDS, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(85, 15, 0),
	})
	sweep:Play()

	local checkConnection
	checkConnection = RunService.Heartbeat:Connect(function()
		if wall.Parent == nil then
			checkConnection:Disconnect()
			return
		end
		local wallX = wall.Position.X
		for _, player in Players:GetPlayers() do
			if caught[player] == nil then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root ~= nil then
					local plot = getPlayerPlot(player)
					local inside = plot ~= nil and isInsideBase(root.Position, plot)
					-- Caught when the wall has passed the player and they are
					-- standing outside their base.
					if not inside and root.Position.X < wallX + 2 then
						caught[player] = true
						onPlayerCaught(player)
					end
				end
			end
		end
	end)

	sweep.Completed:Connect(function()
		checkConnection:Disconnect()
		wall:Destroy()
	end)
	return wall
end

return Waves
