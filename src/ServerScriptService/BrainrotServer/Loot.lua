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

function Loot.rollRarity(luck, potion)
	local exponent = GameConfig.MINE.LuckExponent
	local entries = {}
	for _, name in ipairs(GameConfig.RARITY_ORDER) do
		local rarity = GameConfig.RARITIES[name]
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

function Loot.rollCardOfRarity(rarity)
	local cards = GameConfig.getCardsOfRarity(rarity)
	if #cards == 0 then
		return GameConfig.CARDS[1].Name
	end
	return cards[math.random(1, #cards)].Name
end

function Loot.rollMutation()
	for index = #GameConfig.MUTATION_ORDER, 1, -1 do
		local name = GameConfig.MUTATION_ORDER[index]
		local mutation = GameConfig.MUTATIONS[name]
		if mutation.Chance > 0 and math.random() < mutation.Chance then
			return name
		end
	end
	return "Normal"
end

-- Brainrot trouvé en minant
function Loot.rollMined(pickaxeLuck, layerIndex, potion)
	local luck = pickaxeLuck * (1 + (layerIndex - 1) * GameConfig.MINE.LuckPerLayer)
	local rarity = Loot.rollRarity(luck, potion)
	return Loot.rollCardOfRarity(rarity), Loot.rollMutation()
end

-- Contenu d'un booster
function Loot.rollBooster(booster)
	local results = {}
	for _ = 1, booster.Cards do
		local rarity = weightedPick(booster.Odds)
		table.insert(results, {Name = Loot.rollCardOfRarity(rarity), Mutation = Loot.rollMutation()})
	end
	return results
end

-- Case de la roue de la fortune (renvoie l'index de la case)
function Loot.rollWheel()
	local entries = {}
	for index, prize in ipairs(GameConfig.WHEEL.Prizes) do
		table.insert(entries, {index, prize.Weight})
	end
	return weightedPick(entries)
end

return Loot
