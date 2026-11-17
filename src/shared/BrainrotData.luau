-- Brainrot Bazaar: the cast. Every character is an original absurd invention
-- of this game, on a six-rung rarity ladder. A brainrot earns its income
-- every second while it sits on its owner's base. Prices and incomes are
-- the game's own Bazaar Coins.

local BrainrotData = {}

BrainrotData.RARITIES = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God" }

-- How often each rarity rolls off the conveyor (weights, not percents).
BrainrotData.RARITY_WEIGHTS = {
	Common = 45,
	Rare = 28,
	Epic = 15,
	Legendary = 8,
	Mythic = 3,
	["Brainrot God"] = 1,
}

-- Mutations: a lucky buy comes back shinier and earns a multiple.
BrainrotData.MUTATIONS = {
	Golden = { multiplier = 2, color = Color3.fromRGB(255, 215, 0) },
	Diamond = { multiplier = 3, color = Color3.fromRGB(185, 242, 255) },
	Rainbow = { multiplier = 5, color = Color3.fromRGB(255, 105, 180) },
}
BrainrotData.MUTATION_WEIGHTS = {
	Golden = 70,
	Diamond = 22,
	Rainbow = 8,
}

-- The catalog. bodySize is the body cube's edge in studs; hat is one of
-- "TopHat", "Crown", "Beanie" or "None".
BrainrotData.CATALOG = {
	{ id = "bananaphone", name = "Sir Bananaphone", rarity = "Common", cost = 50, income = 2, color = Color3.fromRGB(255, 220, 60), bodySize = 3, hat = "TopHat", blurb = "A banana in a suit. Answers every call." },
	{ id = "cucumber-carl", name = "Cucumber Carl", rarity = "Common", cost = 120, income = 5, color = Color3.fromRGB(80, 200, 90), bodySize = 3, hat = "None", blurb = "Cool as a cucumber. Literally." },
	{ id = "noodlebeard", name = "Captain Noodlebeard", rarity = "Rare", cost = 350, income = 12, color = Color3.fromRGB(240, 180, 80), bodySize = 3.5, hat = "Beanie", blurb = "Sails the seven seas of spaghetti." },
	{ id = "dj-washer", name = "DJ Washing Machine", rarity = "Rare", cost = 600, income = 20, color = Color3.fromRGB(120, 160, 255), bodySize = 3.5, hat = "None", blurb = "Spins records. And socks." },
	{ id = "prof-pickles", name = "Professor Pickles", rarity = "Epic", cost = 1200, income = 38, color = Color3.fromRGB(90, 180, 70), bodySize = 4, hat = "TopHat", blurb = "Holds three PhDs in brine." },
	{ id = "grandma-turbo", name = "Grandma Turbo", rarity = "Epic", cost = 2000, income = 60, color = Color3.fromRGB(200, 120, 200), bodySize = 4, hat = "Beanie", blurb = "Bakes cookies at 200 miles per hour." },
	{ id = "mocha-moth", name = "Mocha the Moth", rarity = "Legendary", cost = 4500, income = 130, color = Color3.fromRGB(150, 100, 60), bodySize = 4.5, hat = "Crown", blurb = "Drawn to every lamp in the bazaar." },
	{ id = "reginald-pigeon", name = "Sir Reginald Pigeon", rarity = "Legendary", cost = 8000, income = 220, color = Color3.fromRGB(140, 140, 160), bodySize = 4.5, hat = "TopHat", blurb = "Coos in four languages. Judges in all of them." },
	{ id = "almighty-sock", name = "The Almighty Sock", rarity = "Mythic", cost = 15000, income = 400, color = Color3.fromRGB(255, 255, 255), bodySize = 5, hat = "Crown", blurb = "The left one. The right one was never found." },
	{ id = "cactus-jackpot", name = "Cactus Jackpot", rarity = "Mythic", cost = 25000, income = 650, color = Color3.fromRGB(60, 180, 90), bodySize = 5, hat = "None", blurb = "Pays out in spikes. Do not hug." },
	{ id = "toilet-tornado", name = "Toilet Tornado Supreme", rarity = "Brainrot God", cost = 50000, income = 1200, color = Color3.fromRGB(180, 220, 255), bodySize = 6, hat = "Crown", blurb = "Flushes fortunes. Swirls legends." },
	{ id = "spaghetti-yeti", name = "Spaghetti Yeti Prime", rarity = "Brainrot God", cost = 100000, income = 2500, color = Color3.fromRGB(245, 220, 170), bodySize = 6, hat = "Beanie", blurb = "Half yeti, half dinner. All profit." },
}

local byId = {}
for _, entry in BrainrotData.CATALOG do
	byId[entry.id] = entry
end

-- Look a brainrot up by its id, or nil when there is none.
function BrainrotData.getById(id)
	return byId[id]
end

-- Roll a rarity from the weights above.
function BrainrotData.rollRarity()
	local total = 0
	for _, weight in BrainrotData.RARITY_WEIGHTS do
		total += weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, rarity in BrainrotData.RARITIES do
		running += BrainrotData.RARITY_WEIGHTS[rarity]
		if roll <= running then
			return rarity
		end
	end
	return "Common"
end

-- Pick one random brainrot of the given rarity.
function BrainrotData.pickOfRarity(rarity)
	local pool = {}
	for _, entry in BrainrotData.CATALOG do
		if entry.rarity == rarity then
			table.insert(pool, entry)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll one brainrot for the conveyor: rarity first, then a character of it.
function BrainrotData.pickRandom()
	return BrainrotData.pickOfRarity(BrainrotData.rollRarity())
end

-- Roll a mutation name, or nil when the buy comes back plain.
function BrainrotData.rollMutation(chance)
	if math.random() >= chance then
		return nil
	end
	local total = 0
	for _, weight in BrainrotData.MUTATION_WEIGHTS do
		total += weight
	end
	local roll = math.random(1, total)
	local running = 0
	for name, weight in BrainrotData.MUTATION_WEIGHTS do
		running += weight
		if roll <= running then
			return name
		end
	end
	return "Golden"
end

-- A brainrot's income per second with its mutation applied.
function BrainrotData.incomeOf(entry, mutation)
	local income = entry.income
	if mutation ~= nil then
		local mut = BrainrotData.MUTATIONS[mutation]
		if mut ~= nil then
			income *= mut.multiplier
		end
	end
	return income
end

return BrainrotData
