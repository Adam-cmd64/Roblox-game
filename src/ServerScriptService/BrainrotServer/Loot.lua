-- ModuleScript : tirages aléatoires (raretés, brainrots, mutations, boosters, roue).
--
-- Chaque rareté a un poids de base (très faible pour les hautes raretés).
-- La "chance" (pioche x profondeur) booste les raretés hautes :
--   - Pioche en bois près de la surface : presque que du Commun, un peu de Rare, une toute petite chance de carte de ouf.
--   - Pioche en netherite tout au fond : les raretés hautes deviennent vraiment possibles.
-- La potion Chance x2 rend toutes les raretés au-dessus de Commun deux fois plus probables.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Loot = {}

local function weightedPick(entries)
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry[2]
	end
	local roll = math.random() * total
	for _, entry in ipairs(entries) do
		roll -= entry[2]
		if roll <= 0 then
			return entry[1]
		end
	end
	return entries[#entries][1]
end
Loot.weightedPick = weightedPick

-- only : nil, ou {[rareté] = true} pour ne tirer que parmi ces raretés (monde 2)
function Loot.rollRarity(luck, potion, only)
	local exponent = GameConfig.MINE.LuckExponent
	local entries = {}
	for _, name in ipairs(GameConfig.RARITY_ORDER) do
		local rarity = GameConfig.RARITIES[name]
		if only and not only[name] then
			continue
		end
		local weight = rarity.Weight * luck ^ (exponent * (rarity.Order - 1))
		if potion and rarity.Order > 1 then
			weight *= GameConfig.LUCK_POTION_MULTIPLIER
		end
		if weight > 0 then
			table.insert(entries, {name, weight})
		end
	end
	return weightedPick(entries)
end

-- source : "Mine", "Booster", "Wheel" ou "Gift" ; world : le monde où on mine (1 par défaut)
-- Dans le monde 2, on tombe d'abord sur les brainrots du monde 2 (s'il y en a de cette rareté)
function Loot.rollCardOfRarity(rarity, source, world)
	local cards, worldCards = {}, {}
	for _, c in ipairs(GameConfig.getCardsOfRarity(rarity)) do
		if GameConfig.canDrop(c, source or "Mine", world or 1) then
			table.insert(cards, c)
			if c.World == world then
				table.insert(worldCards, c)
			end
		end
	end
	if world == 2 and #worldCards > 0 then
		cards = worldCards
	end
	if #cards == 0 then
		return GameConfig.CARDS[1].Name
	end
	return cards[math.random(1, #cards)].Name
end

-- Mutation : plus de chance (pioche x profondeur) et la potion rendent les mutations plus fréquentes
-- world : Galaxie n'existe que dans le monde 2, et les mutations "Retired" (Lave) ne sortent plus
function Loot.rollMutation(luck, potion, world)
	local boost = math.sqrt(math.max(1, luck or 1)) * (potion and GameConfig.LUCK_POTION_MULTIPLIER or 1)
	for index = #GameConfig.MUTATION_ORDER, 1, -1 do
		local name = GameConfig.MUTATION_ORDER[index]
		local mutation = GameConfig.MUTATIONS[name]
		local chance = math.min(mutation.Chance * boost, GameConfig.MUTATION_MAX_CHANCE)
		local allowed = not mutation.Retired and (not mutation.Worlds or table.find(mutation.Worlds, world or 1) ~= nil)
		if allowed and mutation.Chance > 0 and math.random() < chance then
			return name
		end
	end
	return "Normal"
end

-- Les raretés qui ont des brainrots du monde 2 (dans le monde 2 on ne tire que celles-là)
local world2Rarities
local function getWorld2Rarities()
	if not world2Rarities then
		world2Rarities = {}
		for _, c in ipairs(GameConfig.CARDS) do
			if c.World == 2 then
				world2Rarities[c.Rarity] = true
			end
		end
	end
	return world2Rarities
end

-- Brainrot trouvé en minant (world : 1 ou 2)
-- Monde 2 : la chance de la pioche est divisée (LuckDivisor) pour que ce soit aussi dur que le monde 1
function Loot.rollMined(pickaxeLuck, layerIndex, potion, world)
	world = world or 1
	local config = GameConfig.getWorld(world)
	local pickaxe = math.max(1, pickaxeLuck / (config.LuckDivisor or 1))
	local luck = pickaxe * (1 + (layerIndex - 1) * GameConfig.MINE.LuckPerLayer) * (config.LuckMultiplier or 1)
	local rarity = Loot.rollRarity(luck, potion, world == 2 and getWorld2Rarities() or nil)
	return Loot.rollCardOfRarity(rarity, "Mine", world), Loot.rollMutation(luck, potion, world)
end

-- Contenu d'un booster
function Loot.rollBooster(booster)
	local results = {}
	for _ = 1, booster.Cards do
		local rarity = weightedPick(booster.Odds)
		table.insert(results, {Name = Loot.rollCardOfRarity(rarity, "Booster"), Mutation = Loot.rollMutation()})
	end
	return results
end

-- Pack Limited : une carte Limited selon ses chances (50 / 35 / 14 / 1 %)
function Loot.rollLimited()
	return weightedPick(GameConfig.LIMITED_PACK.Cards)
end

-- Case de la roue de la fortune (renvoie l'index de la case)
function Loot.rollWheel()
	local entries = {}
	for index, prize in ipairs(GameConfig.WHEEL.Prizes) do
		table.insert(entries, {index, prize.Weight})
	end
	return weightedPick(entries)
end

-- Minerai trouvé dans un coffre de la mine (selon GameConfig.MINERALS[].ChestWeight)
function Loot.rollMineral()
	local total = 0
	for _, mineral in ipairs(GameConfig.MINERALS) do
		total += mineral.ChestWeight
	end
	local roll = math.random() * total
	for _, mineral in ipairs(GameConfig.MINERALS) do
		roll -= mineral.ChestWeight
		if roll <= 0 then
			return mineral.Id
		end
	end
	return GameConfig.MINERALS[1].Id
end

return Loot
