-- Brainrot Bazaar: the money math, kept pure so it can be reasoned about
-- without a running game. Cash, income and rebirths are the server's state;
-- this module only computes with them.

local Economy = {}

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

-- A player's income per second: every owned brainrot's rate, times the
-- permanent rebirth bonus.
function Economy.incomePerSecond(owned, rebirths)
	local total = 0
	for _, slot in owned do
		if slot ~= nil then
			local entry = BrainrotData.getById(slot.id)
			if entry ~= nil then
				total += BrainrotData.incomeOf(entry, slot.mutation)
			end
		end
	end
	return math.floor(total * (1 + Config.REBIRTH_INCOME_BONUS * rebirths) + 0.5)
end

-- The price of the next rebirth: it grows fivefold every time.
function Economy.rebirthCost(rebirths)
	return Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_MULTIPLIER ^ rebirths)
end

-- Roll a mutation for a fresh buy, using the configured chance.
function Economy.rollMutation()
	return BrainrotData.rollMutation(Config.MUTATION_CHANCE)
end

-- How many base slots are still free for this player.
function Economy.freeSlotIndex(owned)
	for index = 1, Config.BASE_SLOTS do
		if owned[index] == nil then
			return index
		end
	end
	return nil
end

-- Cash lost to a wave: a flat share of what the player holds.
function Economy.waveLoss(cash)
	return math.floor(cash * Config.WAVE_CASH_PENALTY)
end

return Economy
