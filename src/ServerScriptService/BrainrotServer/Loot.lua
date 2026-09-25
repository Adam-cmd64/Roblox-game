-- ModuleScript : tirages aléatoires (raretés, brainrots, mutations, boosters).
--
-- Principe : chaque rareté a un poids de base (très faible pour les hautes raretés).
-- La "chance" (pioche x profondeur) booste les raretés hautes. Résultat :
--   - Pioche en bois en surface : presque que du Commun, un peu de Rare, et une toute petite chance de carte de ouf.
--   - Pioche en netherite tout au fond : les raretés hautes deviennent vraiment possibles.

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

function Loot.rollRarity(luck)
	local exponent = GameConfig.MINE.LuckExponent
	local entries = {}
	for _, name in ipairs(GameConfig.RARITY_ORDER) do
		local rarity = GameConfig.RARITIES[name]
		table.insert(entries, {name, rarity.Weight * luck ^ (exponent * (rarity.Order - 1))})
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
	-- de la plus rare à la plus commune
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
function Loot.rollMined(pickaxeLuck, layerIndex)
	local luck = pickaxeLuck * (1 + (layerIndex - 1) * GameConfig.MINE.LuckPerLayer)
	local rarity = Loot.rollRarity(luck)
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

return Loot
