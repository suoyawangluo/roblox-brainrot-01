-- Brainrot Bazaar: tiny client-side feedback helpers. No sounds here: the
-- game ships no audio assets, so feedback is visual only.

local Effects = {}

local TweenService = game:GetService("TweenService")

-- A quick scale pop on a button when it is pressed.
function Effects.popButton(button)
	local original = button.Size
	local big = UDim2.new(original.X.Scale, original.X.Offset + 8, original.Y.Scale, original.Y.Offset + 4)
	local popOut = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = big })
	local popBack = TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = original })
	popOut.Completed:Connect(function()
		popBack:Play()
	end)
	popOut:Play()
end

-- Show a notification line, then fade it out after a few seconds.
function Effects.showNotification(label, text)
	label.Text = text
	label.TextTransparency = 0
	label.Visible = true
	local fade = TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 })
	task.delay(4, function()
		if label.Parent ~= nil then
			fade:Play()
		end
	end)
end

-- Flash the wave banner's background twice to catch the eye.
function Effects.flashBanner(banner)
	local original = banner.BackgroundColor3
	local flash = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(255, 220, 60) })
	local back = TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = original })
	flash.Completed:Connect(function()
		back:Play()
	end)
	flash:Play()
end

return Effects
