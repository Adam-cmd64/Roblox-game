-- ModuleScript partagé entre le serveur et le client.
-- TOUS les réglages du jeu sont ici : raretés, brainrots, pioches, mine, rebirths, boutique Robux...

local GameConfig = {}

-- ============================================================
-- RARETES (de la plus commune à la plus rare)
-- Weight : chance de base (avant les bonus de pioche / profondeur)
-- Color / Color2 : dégradé utilisé sur les cartes et l'interface
-- ============================================================
GameConfig.RARITY_ORDER = {
	"Commun", "Rare", "Très Rare", "Épique", "Légendaire", "Mythique",
	"Abyssal", "Enfer", "God", "Eternal", "Angel",
}

GameConfig.RARITIES = {
	["Commun"] = {Weight = 1000, Color = Color3.fromRGB(175, 180, 190), Color2 = Color3.fromRGB(110, 115, 125)},
	["Rare"] = {Weight = 80, Color = Color3.fromRGB(70, 150, 255), Color2 = Color3.fromRGB(30, 80, 200)},
	["Très Rare"] = {Weight = 14, Color = Color3.fromRGB(0, 225, 200), Color2 = Color3.fromRGB(0, 130, 150)},
	["Épique"] = {Weight = 3, Color = Color3.fromRGB(185, 90, 255), Color2 = Color3.fromRGB(100, 30, 190)},
	["Légendaire"] = {Weight = 0.7, Color = Color3.fromRGB(255, 190, 40), Color2 = Color3.fromRGB(230, 110, 0)},
	["Mythique"] = {Weight = 0.15, Color = Color3.fromRGB(255, 70, 120), Color2 = Color3.fromRGB(170, 0, 70)},
	["Abyssal"] = {Weight = 0.035, Color = Color3.fromRGB(40, 110, 255), Color2 = Color3.fromRGB(5, 10, 60)},
	["Enfer"] = {Weight = 0.008, Color = Color3.fromRGB(255, 90, 0), Color2 = Color3.fromRGB(120, 0, 0)},
	["God"] = {Weight = 0.002, Color = Color3.fromRGB(255, 245, 150), Color2 = Color3.fromRGB(255, 180, 0)},
	["Eternal"] = {Weight = 0.0005, Color = Color3.fromRGB(0, 255, 230), Color2 = Color3.fromRGB(150, 0, 255)},
	["Angel"] = {Weight = 0.00012, Color = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(150, 210, 255)},
}

for index, name in ipairs(GameConfig.RARITY_ORDER) do
	GameConfig.RARITIES[name].Order = index
	GameConfig.RARITIES[name].Name = name
end

-- ============================================================
-- BRAINROTS
-- Income : $ par seconde quand il est posé dans ta base
-- Image : ID d'une image uploadée sur Roblox ("rbxassetid://123456").
--         Laisse "" pour afficher le modèle 3D à la place.
-- ============================================================
GameConfig.CARDS = {
	-- Commun
	{Name = "Lirilì Larilà", Rarity = "Commun", Income = 1, Color = Color3.fromRGB(90, 170, 80), Image = "", Desc = "Un éléphant-cactus en sandales. Il pique mais il est gentil."},
	{Name = "Boneca Ambalabu", Rarity = "Commun", Income = 2, Color = Color3.fromRGB(60, 200, 90), Image = "", Desc = "Une grenouille coincée dans un pneu. Personne ne sait comment."},
	-- Rare
	{Name = "Tung Tung Tung Sahur", Rarity = "Rare", Income = 5, Color = Color3.fromRGB(170, 120, 70), Image = "", Desc = "Il frappe trois fois à ta porte avant le lever du soleil."},
	{Name = "Trippi Troppi", Rarity = "Rare", Income = 6, Color = Color3.fromRGB(255, 150, 60), Image = "", Desc = "Moitié crevette, moitié chat, 100% chaos."},
	-- Très Rare
	{Name = "Tralalero Tralala", Rarity = "Très Rare", Income = 14, Color = Color3.fromRGB(40, 120, 220), Image = "", Desc = "Un requin à trois pattes en baskets. Il court vite."},
	{Name = "Bombardiro Crocodilo", Rarity = "Très Rare", Income = 18, Color = Color3.fromRGB(60, 130, 50), Image = "", Desc = "Un crocodile-bombardier. Attention au décollage."},
	-- Épique
	{Name = "Cappuccino Assassino", Rarity = "Épique", Income = 40, Color = Color3.fromRGB(120, 80, 50), Image = "", Desc = "Un café ninja armé de deux katanas. Serré, sans sucre."},
	{Name = "Brr Brr Patapim", Rarity = "Épique", Income = 50, Color = Color3.fromRGB(40, 150, 40), Image = "", Desc = "Un arbre-singe aux pieds géants. Brr brr."},
	-- Légendaire
	{Name = "Ballerina Cappuccina", Rarity = "Légendaire", Income = 120, Color = Color3.fromRGB(255, 130, 200), Image = "", Desc = "Elle danse avec une tasse de cappuccino à la place de la tête."},
	{Name = "Chimpanzini Bananini", Rarity = "Légendaire", Income = 150, Color = Color3.fromRGB(255, 220, 40), Image = "", Desc = "Un singe caché dans une banane. Ou l'inverse."},
	-- Mythique
	{Name = "Frigo Camelo", Rarity = "Mythique", Income = 400, Color = Color3.fromRGB(200, 230, 255), Image = "", Desc = "Un chameau-frigo. Toujours frais, même dans le désert."},
	{Name = "Glorbo Fruttodrillo", Rarity = "Mythique", Income = 500, Color = Color3.fromRGB(255, 90, 60), Image = "", Desc = "Un crocodile-pastèque qui sent le fruit rouge."},
	-- Abyssal
	{Name = "Blueberrinni Octopusini", Rarity = "Abyssal", Income = 1500, Color = Color3.fromRGB(70, 90, 220), Image = "", Desc = "Une pieuvre-myrtille venue du fond des abysses."},
	{Name = "Bombombini Gusini", Rarity = "Abyssal", Income = 1800, Color = Color3.fromRGB(230, 230, 230), Image = "", Desc = "Une oie-avion de chasse. Honk honk, boum."},
	-- Enfer
	{Name = "Dragon Cannelloni", Rarity = "Enfer", Income = 6000, Color = Color3.fromRGB(255, 80, 20), Image = "", Desc = "Un dragon farci aux pâtes. Il crache de la sauce bolognaise."},
	{Name = "Nuclearo Dinossauro", Rarity = "Enfer", Income = 7500, Color = Color3.fromRGB(120, 255, 60), Image = "", Desc = "Un dinosaure radioactif. Ne pas toucher."},
	-- God
	{Name = "La Vaca Saturno Saturnita", Rarity = "God", Income = 25000, Color = Color3.fromRGB(230, 150, 60), Image = "", Desc = "Une vache-planète entourée d'anneaux. Meuh cosmique."},
	{Name = "Odin Din Din Dun", Rarity = "God", Income = 30000, Color = Color3.fromRGB(200, 200, 255), Image = "", Desc = "Le dieu du tonnerre... version brainrot."},
	-- Eternal
	{Name = "La Grande Combinasion", Rarity = "Eternal", Income = 100000, Color = Color3.fromRGB(80, 220, 255), Image = "", Desc = "La combinaison ultime. Elle fait tout, tout le temps."},
	{Name = "Garama and Madundung", Rarity = "Eternal", Income = 120000, Color = Color3.fromRGB(160, 90, 40), Image = "", Desc = "Deux légendes dans un seul corps. Éternels."},
	-- Angel
	{Name = "Girafa Celestre", Rarity = "Angel", Income = 400000, Color = Color3.fromRGB(255, 240, 200), Image = "", Desc = "Une girafe céleste descendue des nuages."},
	{Name = "Graipuss Medussi", Rarity = "Angel", Income = 500000, Color = Color3.fromRGB(220, 90, 255), Image = "", Desc = "Une méduse-raisin divine. La carte la plus rare du jeu."},
}

-- ============================================================
-- MUTATIONS (affichées au-dessus des cartes avec des effets)
-- Chance : chance qu'un brainrot miné soit muté (0 = admin seulement)
-- ============================================================
GameConfig.MUTATION_ORDER = {"Normal", "Or", "Diamant", "Arc-en-ciel", "Lave", "Galaxie", "Radioactif"}

GameConfig.MUTATIONS = {
	["Normal"] = {Multiplier = 1, Chance = 0},
	["Or"] = {Multiplier = 1.5, Chance = 0.03, Colors = {Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 180, 0)}},
	["Diamant"] = {Multiplier = 2, Chance = 0.01, Colors = {Color3.fromRGB(200, 255, 255), Color3.fromRGB(40, 190, 255)}},
	["Arc-en-ciel"] = {Multiplier = 3, Chance = 0.003, Rainbow = true, Colors = {Color3.fromRGB(255, 60, 60), Color3.fromRGB(60, 120, 255)}},
	["Lave"] = {Multiplier = 4, Chance = 0.001, Colors = {Color3.fromRGB(255, 200, 0), Color3.fromRGB(200, 20, 0)}},
	["Galaxie"] = {Multiplier = 6, Chance = 0, Colors = {Color3.fromRGB(230, 120, 255), Color3.fromRGB(30, 0, 90)}},
	["Radioactif"] = {Multiplier = 8, Chance = 0, Colors = {Color3.fromRGB(200, 255, 80), Color3.fromRGB(20, 120, 0)}},
}

-- ============================================================
-- PIOCHES (style Minecraft)
-- Luck : multiplie les chances d'avoir des brainrots rares
-- ============================================================
GameConfig.PICKAXES = {
	{Name = "Pioche en Bois", Damage = 1, Cooldown = 0.32, Cost = 0, RequiredRebirths = 0, Luck = 1, HeadColor = Color3.fromRGB(160, 120, 70)},
	{Name = "Pioche en Pierre", Damage = 3, Cooldown = 0.29, Cost = 500, RequiredRebirths = 1, Luck = 1.6, HeadColor = Color3.fromRGB(140, 140, 140)},
	{Name = "Pioche en Fer", Damage = 8, Cooldown = 0.26, Cost = 7500, RequiredRebirths = 2, Luck = 2.5, HeadColor = Color3.fromRGB(230, 230, 230)},
	{Name = "Pioche en Or", Damage = 20, Cooldown = 0.22, Cost = 60000, RequiredRebirths = 3, Luck = 4, HeadColor = Color3.fromRGB(255, 215, 40)},
	{Name = "Pioche en Diamant", Damage = 50, Cooldown = 0.19, Cost = 450000, RequiredRebirths = 4, Luck = 6, HeadColor = Color3.fromRGB(70, 230, 220)},
	{Name = "Pioche en Netherite", Damage = 120, Cooldown = 0.16, Cost = 3000000, RequiredRebirths = 5, Luck = 9, HeadColor = Color3.fromRGB(80, 70, 78)},
}

-- ============================================================
-- MINE
-- ============================================================
GameConfig.MINE = {
	Center = Vector3.new(0, 0, 0), -- centre du dessus de la mine (le sol est à Y = 0)
	BlockSize = 4,
	Grid = 20, -- 20 x 20 blocs de large
	Depth = 38, -- 38 couches de profondeur
	MineRange = 14, -- distance max pour miner un bloc
	ResetInterval = 600, -- la mine se régénère toutes les 10 minutes
	OreChanceBase = 0.06, -- 6% de minerai brainrot en surface...
	OreChancePerLayer = 0.003, -- ... +0.3% par couche
	LuckPerLayer = 0.03, -- +3% de chance par couche de profondeur
	LuckExponent = 0.35, -- à quel point la chance favorise les raretés hautes
}

-- Couches de la mine (du haut vers le bas)
-- MinTier : niveau de pioche minimum pour casser ce bloc
GameConfig.LAYERS = {
	{From = 1, To = 1, Name = "Herbe", Material = Enum.Material.Grass, Color = Color3.fromRGB(90, 170, 60), HP = 3, Cash = 1, MinTier = 1},
	{From = 2, To = 5, Name = "Terre", Material = Enum.Material.Ground, Color = Color3.fromRGB(125, 90, 60), HP = 4, Cash = 1, MinTier = 1},
	{From = 6, To = 12, Name = "Pierre", Material = Enum.Material.Slate, Color = Color3.fromRGB(125, 125, 125), HP = 10, Cash = 3, MinTier = 1},
	{From = 13, To = 20, Name = "Roche profonde", Material = Enum.Material.Basalt, Color = Color3.fromRGB(70, 70, 80), HP = 30, Cash = 10, MinTier = 2},
	{From = 21, To = 27, Name = "Magma", Material = Enum.Material.CrackedLava, Color = Color3.fromRGB(110, 45, 30), HP = 90, Cash = 35, MinTier = 3},
	{From = 28, To = 33, Name = "Obsidienne", Material = Enum.Material.Slate, Color = Color3.fromRGB(45, 25, 70), HP = 260, Cash = 120, MinTier = 4},
	{From = 34, To = 38, Name = "Débris antiques", Material = Enum.Material.Rock, Color = Color3.fromRGB(95, 60, 50), HP = 700, Cash = 400, MinTier = 5},
}

-- ============================================================
-- REBIRTHS
-- Chaque rebirth : +50% de revenu, +1 emplacement dans la base, la pioche suivante débloquée dans la boutique.
-- Tu perds ton Cash et les brainrots demandés.
-- ============================================================
GameConfig.REBIRTH_INCOME_MULT_BONUS = 0.5
GameConfig.REBIRTHS = {
	{Cash = 1000, Cards = {"Tung Tung Tung Sahur"}},
	{Cash = 10000, Cards = {"Tralalero Tralala"}},
	{Cash = 80000, Cards = {"Cappuccino Assassino"}},
	{Cash = 600000, Cards = {"Ballerina Cappuccina"}},
	{Cash = 4000000, Cards = {"Frigo Camelo"}},
	{Cash = 25000000, Cards = {"Blueberrinni Octopusini"}},
	{Cash = 150000000, Cards = {"Dragon Cannelloni"}},
	{Cash = 1000000000, Cards = {"La Vaca Saturno Saturnita"}},
}

-- ============================================================
-- BASES
-- ============================================================
GameConfig.BASE = {
	PlotCount = 6,
	StartSlots = 6, -- emplacements débloqués au début
	MaxSlots = 16, -- +1 emplacement par rebirth jusqu'à ce maximum
	CleanTemplate = true, -- supprime la Baseplate et le SpawnLocation du template Roblox
}

-- ============================================================
-- ECHANGES
-- ============================================================
GameConfig.TRADE = {
	MaxRebirthDifference = 3, -- on ne peut échanger qu'avec un joueur à 3 rebirths d'écart max
	MaxItems = 8,
	CountdownSeconds = 3,
}

-- ============================================================
-- BOUTIQUE ROBUX (boosters de cartes)
-- ProductId : l'ID du "Developer Product" créé sur le Creator Dashboard.
-- Tant qu'il vaut 0, le booster est GRATUIT dans Roblox Studio (pour tester) et désactivé en jeu.
-- ============================================================
GameConfig.BOOSTERS = {
	{
		Id = "Commun", Name = "Booster Commun", Price = 149, ProductId = 0, Cards = 3,
		Color = Color3.fromRGB(110, 170, 255),
		Odds = {{"Commun", 70}, {"Rare", 25}, {"Très Rare", 5}},
	},
	{
		Id = "Epique", Name = "Booster Épique", Price = 399, ProductId = 0, Cards = 3,
		Color = Color3.fromRGB(185, 90, 255),
		Odds = {{"Rare", 50}, {"Très Rare", 35}, {"Épique", 13}, {"Légendaire", 2}},
	},
	{
		Id = "Legendaire", Name = "Booster Légendaire", Price = 999, ProductId = 0, Cards = 3,
		Color = Color3.fromRGB(255, 180, 30),
		Odds = {{"Épique", 55}, {"Légendaire", 35}, {"Mythique", 9}, {"Abyssal", 1}},
	},
	{
		Id = "Divin", Name = "Booster Divin", Price = 2499, ProductId = 0, Cards = 3,
		Color = Color3.fromRGB(255, 80, 60),
		Odds = {{"Légendaire", 50}, {"Mythique", 35}, {"Abyssal", 11}, {"Enfer", 3.5}, {"God", 0.5}},
	},
}

-- ============================================================
-- ADMINS (commandes dans le chat : /give, /cash, /rebirths, /pickaxe)
-- Mets ici les UserId des admins. Dans Roblox Studio, tout le monde est admin pour tester.
-- ============================================================
GameConfig.ADMINS = {}

GameConfig.DATASTORE_NAME = "BrainrotMine_v1"

-- ============================================================
-- FONCTIONS UTILES
-- ============================================================
function GameConfig.getCard(name)
	for index, card in ipairs(GameConfig.CARDS) do
		if card.Name == name then
			return card, index
		end
	end
	return nil
end

function GameConfig.getCardsOfRarity(rarity)
	local list = {}
	for _, card in ipairs(GameConfig.CARDS) do
		if card.Rarity == rarity then
			table.insert(list, card)
		end
	end
	return list
end

function GameConfig.getLayer(layerIndex)
	for _, layer in ipairs(GameConfig.LAYERS) do
		if layerIndex >= layer.From and layerIndex <= layer.To then
			return layer
		end
	end
	return GameConfig.LAYERS[#GameConfig.LAYERS]
end

function GameConfig.getIncomeMultiplier(rebirths)
	return 1 + rebirths * GameConfig.REBIRTH_INCOME_MULT_BONUS
end

function GameConfig.getSlotCount(rebirths)
	return math.min(GameConfig.BASE.StartSlots + rebirths, GameConfig.BASE.MaxSlots)
end

-- Prix du prochain rebirth (au-delà de la liste, le prix est multiplié par 6 à chaque fois)
function GameConfig.getRebirth(number)
	local list = GameConfig.REBIRTHS
	if list[number] then
		return list[number]
	end
	local last = list[#list]
	return {
		Cash = last.Cash * 6 ^ (number - #list),
		Cards = last.Cards,
	}
end

-- Revenu d'un brainrot (avec sa mutation)
function GameConfig.getItemIncome(cardName, mutation)
	local card = GameConfig.getCard(cardName)
	if not card then return 0 end
	local mut = GameConfig.MUTATIONS[mutation or "Normal"] or GameConfig.MUTATIONS.Normal
	return card.Income * mut.Multiplier
end

-- 25680 -> "25.6K", 3400000 -> "3.4M"
local SUFFIXES = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx"}
function GameConfig.format(number)
	number = tonumber(number) or 0
	local negative = number < 0
	number = math.abs(number)
	local index = 1
	while number >= 1000 and index < #SUFFIXES do
		number /= 1000
		index += 1
	end
	local text
	if index == 1 then
		if number % 1 ~= 0 and number < 100 then
			text = string.format("%.1f", math.floor(number * 10) / 10)
		else
			text = tostring(math.floor(number))
		end
	elseif number >= 100 then
		text = string.format("%d%s", math.floor(number), SUFFIXES[index])
	else
		text = string.format("%.1f%s", math.floor(number * 10) / 10, SUFFIXES[index])
		text = text:gsub("%.0" .. SUFFIXES[index] .. "$", SUFFIXES[index])
	end
	return (negative and "-" or "") .. text
end

return GameConfig
