-- Brainrot Bazaar: one place for every tuning number, so the game can be
-- rebalanced without touching the logic. All money is the game's own
-- "Bazaar Coins"; nothing here is a real currency.

local Config = {}

-- Economy
Config.START_CASH = 100
Config.INCOME_TICK_SECONDS = 1
Config.REBIRTH_BASE_COST = 5000
Config.REBIRTH_COST_MULTIPLIER = 5
Config.REBIRTH_INCOME_BONUS = 0.25 -- +25% income per rebirth, forever

-- Conveyor: brainrots ride the belt from west (x = -55) to east (x = +55).
Config.CONVEYOR_Z = -20
Config.CONVEYOR_START_X = -55
Config.CONVEYOR_END_X = 55
Config.CONVEYOR_SPEED = 6 -- studs per second
Config.SPAWN_INTERVAL_SECONDS = 4
Config.MAX_CONVEYOR_BRAINROTS = 8

-- Bases: 8 plots around the plaza, 6 slots each.
Config.BASE_SLOTS = 6
Config.PLOTS = {
	Vector3.new(-66, 1.5, -48),
	Vector3.new(-22, 1.5, -48),
	Vector3.new(22, 1.5, -48),
	Vector3.new(66, 1.5, -48),
	Vector3.new(-66, 1.5, 48),
	Vector3.new(-22, 1.5, 48),
	Vector3.new(22, 1.5, 48),
	Vector3.new(66, 1.5, 48),
}
-- Slot offsets inside a plot, in a 3-by-2 grid.
Config.SLOT_OFFSETS = {
	Vector3.new(-5, 0, -4),
	Vector3.new(0, 0, -4),
	Vector3.new(5, 0, -4),
	Vector3.new(-5, 0, 4),
	Vector3.new(0, 0, 4),
	Vector3.new(5, 0, 4),
}

-- Stealing and defence.
Config.STEAL_COOLDOWN_SECONDS = 60
Config.LOCK_DURATION_SECONDS = 60
Config.LOCK_COOLDOWN_SECONDS = 120
Config.STEAL_VICTIM_LOCK_SECONDS = 30 -- a stolen-from base auto-locks

-- Noodle Tsunami hazard wave.
Config.WAVE_INTERVAL_SECONDS = 90
Config.WAVE_SWEEP_SECONDS = 12
Config.WAVE_CASH_PENALTY = 0.10 -- caught outside your base: lose 10% of cash

-- Mutations: a bought brainrot may come back mutated, worth more per second.
Config.MUTATION_CHANCE = 0.12

return Config
