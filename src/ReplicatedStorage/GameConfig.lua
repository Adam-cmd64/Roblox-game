-- ModuleScript partagé entre le serveur et le client.
-- TOUS les réglages du jeu sont ici : raretés, brainrots, pioches, battes, mine, rebirths, base,
-- boutique Robux, roue de la fortune, bonus d'index, sons...

local GameConfig = {}

-- ============================================================
-- RARETES (de la plus commune à la plus rare)
-- Weight : chance de base en minant (0 = impossible à miner, exclusif)
-- IndexBonus : bonus d'argent quand tu as découvert TOUS les brainrots de cette rareté
-- ============================================================
GameConfig.RARITY_ORDER = {
	"Commun", "Rare", "Très Rare", "Épique", "Légendaire", "Mythique", "Abyssal",
	"Enfer", "Cosmique", "God", "Eternal", "Angel", "Secret", "OG",
}

GameConfig.RARITIES = {
	["Commun"] = {Weight = 1000, IndexBonus = 0.05, Color = Color3.fromRGB(185, 190, 200), Color2 = Color3.fromRGB(105, 110, 125)},
	["Rare"] = {Weight = 80, IndexBonus = 0.05, Color = Color3.fromRGB(70, 150, 255), Color2 = Color3.fromRGB(25, 70, 200)},
	["Très Rare"] = {Weight = 14, IndexBonus = 0.075, Color = Color3.fromRGB(0, 230, 200), Color2 = Color3.fromRGB(0, 120, 145)},
	["Épique"] = {Weight = 3, IndexBonus = 0.1, Color = Color3.fromRGB(190, 95, 255), Color2 = Color3.fromRGB(95, 25, 185)},
	["Légendaire"] = {Weight = 0.7, IndexBonus = 0.1, Color = Color3.fromRGB(255, 195, 40), Color2 = Color3.fromRGB(235, 105, 0)},
	["Mythique"] = {Weight = 0.15, IndexBonus = 0.125, Color = Color3.fromRGB(255, 70, 120), Color2 = Color3.fromRGB(165, 0, 65)},
	["Abyssal"] = {Weight = 0.035, IndexBonus = 0.15, Color = Color3.fromRGB(40, 120, 255), Color2 = Color3.fromRGB(5, 12, 60)},
	["Enfer"] = {Weight = 0.008, IndexBonus = 0.15, Color = Color3.fromRGB(255, 95, 0), Color2 = Color3.fromRGB(115, 0, 0)},
	["Cosmique"] = {Weight = 0.003, IndexBonus = 0.2, Color = Color3.fromRGB(255, 90, 230), Color2 = Color3.fromRGB(40, 0, 110)},
	["God"] = {Weight = 0.001, IndexBonus = 0.2, Color = Color3.fromRGB(255, 245, 150), Color2 = Color3.fromRGB(255, 175, 0)},
	["Eternal"] = {Weight = 0.0003, IndexBonus = 0.25, Color = Color3.fromRGB(0, 255, 225), Color2 = Color3.fromRGB(145, 0, 255)},
	["Angel"] = {Weight = 0.0001, IndexBonus = 0.25, Color = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(140, 205, 255)},
	["Secret"] = {Weight = 0.00003, IndexBonus = 0.3, Color = Color3.fromRGB(70, 70, 80), Color2 = Color3.fromRGB(0, 0, 0)},
	["OG"] = {Weight = 0, IndexBonus = 0.5, Color = Color3.fromRGB(255, 225, 90), Color2 = Color3.fromRGB(255, 40, 160)},
}

for index, name in ipairs(GameConfig.RARITY_ORDER) do
	GameConfig.RARITIES[name].Order = index
	GameConfig.RARITIES[name].Name = name
end

-- ============================================================
-- BRAINROTS (35 cartes, toutes différentes)
-- Income : $ par seconde quand il est posé dans ta base
--
-- IMAGES : les personnages (détourés, fond transparent) sont rangés dans 3 grandes images ("atlas") :
--   assets/cards/cartes1.png, cartes2.png, cartes3.png (12 cartes chacune, dans l'ordre de cette liste).
-- Importe ces 3 images dans Studio et colle leurs ID dans CARD_ATLASES (voir le README).
-- ⚠️ Ne change pas l'ordre de la liste : la position d'une carte = sa place dans les images.
-- Pour ajouter une carte : mets-la à la FIN et donne-lui sa propre image (Image = "rbxassetid://...").
-- ============================================================
GameConfig.CARD_ATLASES = {
	"rbxassetid://121758728514110", -- ID de cartes1.png
	"rbxassetid://107637097962431", -- ID de cartes2.png
	"rbxassetid://123101595479089", -- ID de cartes3.png
}
GameConfig.CARD_ATLAS_LAYOUT = {Columns = 4, Rows = 3, CellWidth = 250, CellHeight = 280}

local function card(name, rarity, income, color, desc)
	return {Name = name, Rarity = rarity, Income = income, Color = color, Image = "", Desc = desc}
end
local rgb = Color3.fromRGB

GameConfig.CARDS = {
	-- Commun
	card("Cartonino Scatolino", "Commun", 1, rgb(215, 150, 80), "Un carton en baskets. Il déménage tout le temps."),
	card("Sassolino Maculato", "Commun", 2, rgb(140, 160, 200), "Un caillou en short léopard. Très à la mode."),
	card("Teierina Camminina", "Commun", 2, rgb(150, 70, 60), "Une théière qui se promène. Attention, elle est brûlante."),
	card("Bottiglione Zuppone", "Commun", 3, rgb(110, 70, 50), "Une bouteille qui porte toujours sa soupe."),
	card("Riccio Paffutello", "Commun", 4, rgb(150, 100, 70), "Un hérisson tout rond. Il pique un tout petit peu."),
	-- Rare
	card("Tung Tung Tung Sahur", "Rare", 6, rgb(190, 120, 70), "Il frappe trois fois à ta porte avant le lever du soleil."),
	card("Topolino Occhialino", "Rare", 8, rgb(110, 100, 90), "Une souris à lunettes. Elle a tout lu."),
	card("Fragolone Cubone", "Rare", 10, rgb(220, 70, 70), "Une fraise carrée. Personne ne sait pourquoi."),
	card("Squalo Cubetto", "Rare", 12, rgb(70, 130, 230), "Un requin en forme de cube. Il nage de travers."),
	-- Très Rare
	card("Tazzina Fiammante", "Très Rare", 20, rgb(230, 170, 70), "Une tasse de café qui prend feu. Serré et brûlant."),
	card("Piccione Aviatore", "Très Rare", 25, rgb(120, 110, 100), "Un pigeon pilote avec ses lunettes d'aviateur."),
	card("Gufo Pinetto", "Très Rare", 30, rgb(110, 180, 80), "Un hibou qui vit dans un sapin. Il ne dort jamais."),
	card("Pesciolone Panciuto", "Très Rare", 36, rgb(150, 170, 70), "Un poisson avec un gros ventre. Il a trop mangé."),
	-- Épique
	card("Bruno Scarpone", "Épique", 60, rgb(150, 85, 50), "Un grand costaud en chaussures neuves. Ne marche pas dessus."),
	card("Tralalero Tralala", "Épique", 75, rgb(50, 120, 230), "Un requin sur pattes en baskets. Il court très vite."),
	card("Cappuccino Assassino", "Épique", 90, rgb(60, 60, 70), "Un café ninja armé de deux katanas. Serré, sans sucre."),
	card("Zuccone Sneakerone", "Épique", 100, rgb(200, 110, 50), "Une citrouille géante en baskets de luxe."),
	-- Légendaire
	card("Canguro Coccolino", "Légendaire", 180, rgb(210, 170, 120), "Un kangourou tout doux. Il saute plus haut que les nuages."),
	card("Orangutini Ananassini", "Légendaire", 240, rgb(120, 150, 60), "Un orang-outan déguisé en ananas."),
	card("Leonelli Cactuselli", "Légendaire", 300, rgb(230, 190, 60), "Un lion-cactus. Sa crinière pique."),
	-- Mythique
	card("Pandaccini Bananini", "Mythique", 600, rgb(235, 235, 200), "Un panda avec des ailes en banane."),
	card("Tartaruga Anguria", "Mythique", 750, rgb(70, 150, 70), "Une tortue-pastèque. Lente mais délicieuse."),
	card("Anguriello Furioso", "Mythique", 900, rgb(230, 70, 70), "Une pastèque en colère. Elle crache des pépins."),
	-- Abyssal
	card("Blueberrinni Octopusini", "Abyssal", 2200, rgb(140, 90, 230), "Une pieuvre-myrtille venue du fond des abysses."),
	card("Spiderino Rossino", "Abyssal", 3000, rgb(220, 40, 50), "Une araignée rouge qui sourit. C'est pire."),
	-- Enfer
	card("Tigrrullini Watermellini", "Enfer", 8000, rgb(140, 210, 70), "Un tigre-pastèque. Il rugit en pépins."),
	card("Pot Hotspot", "Enfer", 11000, rgb(80, 150, 230), "Un squelette qui partage sa connexion avec tout le monde."),
	-- Cosmique
	card("La Vaca Saturno Saturnita", "Cosmique", 30000, rgb(150, 210, 230), "Une vache-planète entourée d'anneaux. Meuh cosmique."),
	card("Perochello Lemonchello", "Cosmique", 42000, rgb(250, 220, 50), "Un oiseau-citron. Il répète tout, en plus acide."),
	-- God
	card("Tigre Imperiale", "God", 110000, rgb(230, 150, 60), "Le roi des tigres, avec sa couronne en or."),
	card("Tartarughina Fiorita", "God", 150000, rgb(230, 150, 220), "Une tortue divine couverte de pousses magiques."),
	-- Eternal
	card("La Idra Dorata", "Eternal", 500000, rgb(250, 190, 60), "Un dragon d'or à plusieurs têtes. Il crache du feu éternel."),
	-- Angel
	card("Lucky Block", "Angel", 1800000, rgb(230, 60, 60), "Un lucky block avec des ailes d'ange. Que va-t-il en sortir ?"),
	-- Secret
	card("Lucky Block Secret", "Secret", 7000000, rgb(40, 40, 70), "Le lucky block le plus mystérieux du jeu."),
	-- OG (exclusif : Booster Céleste uniquement)
	card("Lucky Block Arc-en-ciel", "OG", 25000000, rgb(80, 120, 255), "La légende absolue. Introuvable dans la mine."),
}

-- Position de chaque carte dans les images (atlas)
do
	local layout = GameConfig.CARD_ATLAS_LAYOUT
	local perAtlas = layout.Columns * layout.Rows
	for index, c in ipairs(GameConfig.CARDS) do
		c.Atlas = (index - 1) // perAtlas + 1
		c.Cell = (index - 1) % perAtlas
	end
end

-- Prix de vente d'un brainrot = X secondes de son revenu
GameConfig.SELL_SECONDS = 30

-- ============================================================
-- MUTATIONS : une carte mutée a un effet spécial sur la carte et rapporte plus d'argent.
-- Chance : chance de base qu'une carte trouvée soit mutée.
-- Plus tu as de chance (meilleure pioche, plus profond, potion), plus les mutations sont fréquentes :
-- la chance est multipliée par racine(chance de la pioche x profondeur), et x2 avec la potion.
-- Sparkles : nombre d'étincelles animées sur la carte.
-- ============================================================
GameConfig.MUTATION_ORDER = {"Normal", "Or", "Diamant", "Arc-en-ciel", "Lave", "Galaxie", "Radioactif"}

GameConfig.MUTATIONS = {
	["Normal"] = {Multiplier = 1, Chance = 0},
	["Or"] = {Multiplier = 1.5, Chance = 0.02, Sparkles = 6, Colors = {rgb(255, 240, 150), rgb(255, 180, 0)}},
	["Diamant"] = {Multiplier = 2, Chance = 0.008, Sparkles = 8, Colors = {rgb(210, 255, 255), rgb(40, 190, 255)}},
	["Arc-en-ciel"] = {Multiplier = 3, Chance = 0.003, Sparkles = 8, Rainbow = true, Colors = {rgb(255, 60, 60), rgb(60, 120, 255)}},
	["Lave"] = {Multiplier = 4, Chance = 0.0012, Sparkles = 6, Colors = {rgb(255, 200, 0), rgb(220, 30, 0)}},
	["Galaxie"] = {Multiplier = 6, Chance = 0.0005, Sparkles = 12, Colors = {rgb(230, 130, 255), rgb(40, 0, 110)}},
	["Radioactif"] = {Multiplier = 8, Chance = 0.0002, Sparkles = 7, Colors = {rgb(200, 255, 80), rgb(20, 140, 0)}},
}
-- Annonce dans le chat quand quelqu'un obtient une carte de cette rareté ou plus
GameConfig.ANNOUNCE_FROM_RARITY = "Abyssal"
GameConfig.MUTATION_MAX_CHANCE = 0.35 -- jamais plus de 35 % de chance d'avoir une mutation

-- ============================================================
-- PIOCHES (style Minecraft) : il faut le bon nombre de rebirths ET l'argent
-- Luck : multiplie les chances d'avoir des brainrots rares
-- ============================================================
GameConfig.PICKAXES = {
	{Name = "Pioche en Bois", Damage = 1, Cooldown = 0.32, Cost = 0, RequiredRebirths = 0, Luck = 1, HeadColor = rgb(160, 120, 70)},
	{Name = "Pioche en Pierre", Damage = 3, Cooldown = 0.29, Cost = 1500, RequiredRebirths = 1, Luck = 1.6, HeadColor = rgb(140, 140, 140)},
	{Name = "Pioche en Fer", Damage = 8, Cooldown = 0.26, Cost = 15000, RequiredRebirths = 2, Luck = 2.5, HeadColor = rgb(230, 230, 230)},
	{Name = "Pioche en Or", Damage = 20, Cooldown = 0.22, Cost = 120000, RequiredRebirths = 3, Luck = 4, HeadColor = rgb(255, 215, 40)},
	{Name = "Pioche en Diamant", Damage = 50, Cooldown = 0.19, Cost = 1000000, RequiredRebirths = 4, Luck = 6, HeadColor = rgb(70, 230, 220)},
	{Name = "Pioche en Netherite", Damage = 120, Cooldown = 0.16, Cost = 8000000, RequiredRebirths = 5, Luck = 9, HeadColor = rgb(80, 70, 78)},
}

-- ============================================================
-- BATTES (à la boutique, touche F) : une frappe fait tomber le joueur 2 secondes
-- et lui fait lâcher le brainrot qu'il est en train de voler.
-- ============================================================
GameConfig.BATS = {
	{Name = "Batte en bois", Cost = 0, Cooldown = 1.6, Range = 8, Color = rgb(170, 120, 70), Material = Enum.Material.Wood},
	{Name = "Batte en métal", Cost = 25000, Cooldown = 1.3, Range = 9.5, Color = rgb(170, 175, 185), Material = Enum.Material.Metal},
	{Name = "Batte en or", Cost = 750000, Cooldown = 1.0, Range = 11, Color = rgb(255, 200, 40), Material = Enum.Material.Metal},
	{Name = "Batte en diamant", Cost = 20000000, Cooldown = 0.8, Range = 12.5, Color = rgb(80, 230, 255), Material = Enum.Material.Glass},
	{Name = "Batte cosmique", Cost = 500000000, Cooldown = 0.6, Range = 14, Color = rgb(200, 80, 255), Material = Enum.Material.Neon},
}
GameConfig.STUN_TIME = 2

-- ============================================================
-- MINE
-- ============================================================
GameConfig.MINE = {
	Center = Vector3.new(0, 0, 0), -- centre du dessus de la mine (le sol est à Y = 0)
	BlockSize = 4,
	Grid = 26, -- 26 x 26 blocs de large
	Depth = 38, -- 38 couches de profondeur
	MineRange = 14, -- distance max pour miner un bloc
	ResetInterval = 600, -- la mine se régénère toutes les 10 minutes
	NoOreLayers = 2, -- pas de minerai dans les 2 premières couches : il faut creuser !
	OreChanceBase = 0.045, -- 4.5% de minerai...
	OreChancePerLayer = 0.0025, -- ... +0.25% par couche
	LuckPerLayer = 0.03, -- +3% de chance par couche de profondeur
	LuckExponent = 0.35, -- à quel point la chance favorise les raretés hautes
}

GameConfig.LAYERS = {
	{From = 1, To = 1, Name = "Herbe", Material = Enum.Material.Grass, Color = rgb(90, 170, 60), HP = 3, Cash = 1, MinTier = 1},
	{From = 2, To = 5, Name = "Terre", Material = Enum.Material.Ground, Color = rgb(125, 90, 60), HP = 4, Cash = 1, MinTier = 1},
	{From = 6, To = 12, Name = "Pierre", Material = Enum.Material.Slate, Color = rgb(125, 125, 125), HP = 10, Cash = 3, MinTier = 1},
	{From = 13, To = 20, Name = "Roche profonde", Material = Enum.Material.Basalt, Color = rgb(70, 70, 80), HP = 30, Cash = 10, MinTier = 2},
	{From = 21, To = 27, Name = "Magma", Material = Enum.Material.CrackedLava, Color = rgb(110, 45, 30), HP = 90, Cash = 35, MinTier = 3},
	{From = 28, To = 33, Name = "Obsidienne", Material = Enum.Material.Slate, Color = rgb(45, 25, 70), HP = 260, Cash = 120, MinTier = 4},
	{From = 34, To = 38, Name = "Débris antiques", Material = Enum.Material.Rock, Color = rgb(95, 60, 50), HP = 700, Cash = 400, MinTier = 5},
}

-- ============================================================
-- REBIRTHS : de l'argent + plusieurs brainrots précis (ils sont consommés)
-- Chaque rebirth : +50% de revenu, verrou de base plus long, étages, pioche suivante à la boutique.
-- ============================================================
GameConfig.REBIRTH_INCOME_MULT_BONUS = 0.5
GameConfig.REBIRTHS = {
	{Cash = 2500, Cards = {"Cartonino Scatolino", "Sassolino Maculato", "Teierina Camminina"}},
	{Cash = 20000, Cards = {"Tung Tung Tung Sahur", "Bottiglione Zuppone", "Riccio Paffutello"}},
	{Cash = 150000, Cards = {"Topolino Occhialino", "Fragolone Cubone", "Squalo Cubetto"}},
	{Cash = 1000000, Cards = {"Piccione Aviatore", "Gufo Pinetto", "Pesciolone Panciuto"}},
	{Cash = 8000000, Cards = {"Tralalero Tralala", "Cappuccino Assassino", "Tazzina Fiammante"}},
	{Cash = 60000000, Cards = {"Canguro Coccolino", "Zuccone Sneakerone", "Bruno Scarpone"}},
	{Cash = 400000000, Cards = {"Orangutini Ananassini", "Leonelli Cactuselli", "Tartaruga Anguria"}},
	{Cash = 3000000000, Cards = {"Pandaccini Bananini", "Anguriello Furioso", "Spiderino Rossino"}},
	{Cash = 25000000000, Cards = {"Blueberrinni Octopusini", "Pot Hotspot", "Tigrrullini Watermellini"}},
	{Cash = 200000000000, Cards = {"La Vaca Saturno Saturnita", "Perochello Lemonchello", "Tigre Imperiale"}},
}

-- ============================================================
-- BASES
-- ============================================================
GameConfig.BASE = {
	PlotCount = 8, -- 2 rangées de 4 bases
	GroundSlots = 8,
	FloorSlotsPerSide = 3,
	LockDuration = 40, -- les lasers restent 40 secondes quand tu appuies sur le bouton...
	LockPerRebirth = 10, -- ... +10 secondes par rebirth
	CleanTemplate = true, -- supprime la Baseplate et le SpawnLocation du template Roblox
}

-- Étages : l'étage apparaît au rebirth "Left" (côté gauche), le côté droit se débloque au rebirth "Right"
GameConfig.FLOORS = {
	{Left = 1, Right = 3},
	{Left = 4, Right = 5},
	{Left = 6, Right = 7},
}

-- ============================================================
-- VOL DE BRAINROTS
-- ============================================================
GameConfig.STEAL = {
	HoldDuration = 1.5, -- temps pour voler (maintenir E)
	CarrySpeed = 12, -- vitesse quand tu portes un brainrot volé (normal = 16)
	Timeout = 90, -- au bout de 90s sans l'avoir ramené, il retourne chez son propriétaire
}

-- ============================================================
-- ECHANGES
-- ============================================================
GameConfig.TRADE = {
	MaxRebirthDifference = 3,
	MaxItems = 8,
	CountdownSeconds = 3,
}

-- ============================================================
-- BOUTIQUE ROBUX
-- ProductId : l'ID du "Developer Product" (Creator Dashboard > Monétisation).
-- Tant qu'il vaut 0 : GRATUIT dans Roblox Studio (pour tester), désactivé en jeu.
-- ============================================================
GameConfig.BOOSTERS = {
	{Id = "Commun", Name = "Booster Commun", Price = 149, ProductId = 0, Cards = 3, Color = rgb(110, 170, 255),
		Odds = {{"Commun", 70}, {"Rare", 25}, {"Très Rare", 5}}},
	{Id = "Epique", Name = "Booster Épique", Price = 399, ProductId = 0, Cards = 3, Color = rgb(185, 90, 255),
		Odds = {{"Rare", 50}, {"Très Rare", 35}, {"Épique", 13}, {"Légendaire", 2}}},
	{Id = "Legendaire", Name = "Booster Légendaire", Price = 999, ProductId = 0, Cards = 3, Color = rgb(255, 180, 30),
		Odds = {{"Épique", 55}, {"Légendaire", 35}, {"Mythique", 9}, {"Abyssal", 1}}},
	{Id = "Divin", Name = "Booster Divin", Price = 2499, ProductId = 0, Cards = 3, Color = rgb(255, 80, 60),
		Odds = {{"Légendaire", 50}, {"Mythique", 32}, {"Abyssal", 11}, {"Enfer", 5}, {"Cosmique", 1.5}, {"God", 0.5}}},
	{Id = "Galaxie", Name = "Booster Galaxie", Price = 3999, ProductId = 0, Cards = 3, Color = rgb(255, 210, 60), Exclusive = true,
		Odds = {{"Mythique", 38}, {"Abyssal", 25}, {"Enfer", 17}, {"Cosmique", 11}, {"God", 6}, {"Eternal", 2}, {"Angel", 1}}},
	-- 1 seule carte, mais au minimum un Angel !
	{Id = "Celeste", Name = "Booster Céleste", Price = 5999, ProductId = 0, Cards = 1, Color = rgb(150, 220, 255), Exclusive = true,
		Odds = {{"Angel", 70}, {"Secret", 29.9999}, {"OG", 0.0001}}},
}

-- ============================================================
-- GAME PASS (achetés une seule fois, gardés à vie)
-- GamePassId : l'ID du Game Pass (Creator Dashboard > Monétisation > Passes).
-- Tant qu'il vaut 0 : GRATUIT dans Roblox Studio (pour tester), désactivé en jeu.
-- ============================================================
GameConfig.GAMEPASSES = {
	DoubleCash = {Name = "Argent x2", Price = 30, GamePassId = 0, Multiplier = 2, Description = "Tout ton argent x2, pour toujours !"},
}

GameConfig.PRODUCTS = {
	LuckPotion = {Name = "Potion Chance x2", Price = 50, ProductId = 0, Minutes = 15},
	Spin1 = {Name = "1 tour de roue", Price = 100, ProductId = 0, Spins = 1},
	Spin3 = {Name = "3 tours de roue", Price = 250, ProductId = 0, Spins = 3},
	Spin10 = {Name = "10 tours de roue", Price = 850, ProductId = 0, Spins = 10},
}
GameConfig.LUCK_POTION_MULTIPLIER = 2 -- toutes les raretés au-dessus de Commun deviennent 2x plus probables

-- ============================================================
-- ROUE DE LA FORTUNE (1 tour gratuit toutes les 24h)
-- Weight : plus c'est rare, plus c'est bas
-- ============================================================
GameConfig.WHEEL = {
	FreeCooldown = 24 * 60 * 60,
	Prizes = {
		{Id = "Cash", Name = "Argent", Icon = "💰", Weight = 32, Color = rgb(80, 210, 90), IncomeSeconds = 120, Min = 1000},
		{Id = "BigCash", Name = "Jackpot", Icon = "💎", Weight = 20, Color = rgb(40, 160, 255), IncomeSeconds = 600, Min = 10000},
		{Id = "Epic", Name = "Brainrot Épique", Icon = "🃏", Weight = 22, Color = rgb(190, 95, 255), Rarity = "Épique"},
		{Id = "Legendary", Name = "Brainrot Légendaire", Icon = "🌟", Weight = 14, Color = rgb(255, 180, 30), Rarity = "Légendaire"},
		{Id = "Potion", Name = "Chance x2", Icon = "🍀", Weight = 9, Color = rgb(60, 220, 160), Minutes = 15},
		{Id = "BoosterGalaxie", Name = "Booster Galaxie", Icon = "👑", Weight = 3, Color = rgb(255, 60, 150)},
	},
}

-- ============================================================
-- SONS : tous les bruitages sont dans UN SEUL fichier audio : assets/sounds/sons.ogg
-- Importe-le dans Studio (Gestionnaire de ressources > Audio) et colle son ID dans SOUND_FILE.
-- Tant que SOUND_FILE est vide, le jeu est silencieux.
-- Start / Length : où se trouve chaque son dans le fichier (en secondes).
-- Tu peux aussi donner à un son son propre fichier : Id = "rbxassetid://..." (il remplace la case du fichier).
-- ============================================================
GameConfig.SOUND_FILE = "" -- exemple : "rbxassetid://123456789"
GameConfig.SOUNDS = {
	Swing = {Start = 0, Length = 0.22, Volume = 0.15, Pitch = 1}, -- coup de pioche dans le vide
	Hit = {Start = 1.5, Length = 0.14, Volume = 0.45, Pitch = 1}, -- la pioche tape le bloc
	Break = {Start = 3, Length = 0.38, Volume = 0.6, Pitch = 1}, -- le bloc casse (style Minecraft)
	OreBreak = {Start = 4.5, Length = 0.8, Volume = 0.55, Pitch = 1}, -- bloc avec un brainrot
	Card = {Start = 6, Length = 0.7, Volume = 0.5, Pitch = 1}, -- carte trouvée
	RareCard = {Start = 7.5, Length = 1.4, Volume = 0.55, Pitch = 1}, -- carte rare trouvée
	Coin = {Start = 9, Length = 0.5, Volume = 0.35, Pitch = 1}, -- argent collecté
	Tick = {Start = 10.5, Length = 0.05, Volume = 0.4, Pitch = 1}, -- cliquet de la roue
	Win = {Start = 12, Length = 1.4, Volume = 0.55, Pitch = 1}, -- gain à la roue
	BatHit = {Start = 13.5, Length = 0.35, Volume = 0.6, Pitch = 1}, -- coup de batte
	Click = {Start = 15, Length = 0.06, Volume = 0.3, Pitch = 1}, -- bouton
}

-- ============================================================
-- ADMINS (commandes dans le chat : /give, /cash, /rebirths, /pickaxe, /mutation, /spins, /potion)
-- Dans Roblox Studio, tout le monde est admin pour tester.
-- ============================================================
GameConfig.ADMINS = {}

-- Version du jeu (affichée en bas à droite de l'écran) : pratique pour vérifier que Studio a bien le dernier code
GameConfig.VERSION = "v8 - annonces + boosters"

GameConfig.DATASTORE_NAME = "BrainrotMine_v1"
-- Numéro de tirage des cartes (#1 = la toute première carte de ce brainrot trouvée dans le jeu, #2 la suivante...)
GameConfig.SERIAL_STORE_NAME = "BrainrotSerials_v1"

-- ============================================================
-- FONCTIONS UTILES
-- ============================================================
function GameConfig.getCard(name)
	for index, c in ipairs(GameConfig.CARDS) do
		if c.Name == name then
			return c, index
		end
	end
	return nil
end

-- "123456" ou "rbxassetid://123456" -> "rbxassetid://123456" ("" si vide)
function GameConfig.assetId(value)
	value = tostring(value or "")
	if string.match(value, "^%d+$") then
		return "rbxassetid://" .. value
	end
	return value
end

-- Illustration d'une carte : image, position et taille du morceau à afficher (nil si pas d'image)
function GameConfig.getCardImage(cardName)
	local c = GameConfig.getCard(cardName)
	if not c then return nil end
	local own = GameConfig.assetId(c.Image)
	if own ~= "" then
		return own, Vector2.zero, Vector2.zero
	end
	local atlas = GameConfig.assetId(GameConfig.CARD_ATLASES[c.Atlas or 0])
	if atlas == "" then return nil end
	local layout = GameConfig.CARD_ATLAS_LAYOUT
	local column, row = c.Cell % layout.Columns, c.Cell // layout.Columns
	return atlas, Vector2.new(column * layout.CellWidth, row * layout.CellHeight), Vector2.new(layout.CellWidth, layout.CellHeight)
end

function GameConfig.getCardsOfRarity(rarity)
	local list = {}
	for _, c in ipairs(GameConfig.CARDS) do
		if c.Rarity == rarity then
			table.insert(list, c)
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

-- Bonus d'index : somme des bonus des raretés entièrement découvertes
function GameConfig.getIndexBonus(discovered)
	local bonus = 0
	for _, rarity in ipairs(GameConfig.RARITY_ORDER) do
		local cards = GameConfig.getCardsOfRarity(rarity)
		local complete = #cards > 0
		for _, c in ipairs(cards) do
			if not discovered[c.Name] then
				complete = false
				break
			end
		end
		if complete then
			bonus += GameConfig.RARITIES[rarity].IndexBonus
		end
	end
	return bonus
end

-- Liste des brainrots découverts d'un joueur (dossier player.Index)
function GameConfig.getDiscovered(player)
	local set = {}
	local folder = player:FindFirstChild("Index")
	if folder then
		for _, entry in ipairs(folder:GetChildren()) do
			set[entry.Name] = true
		end
	end
	return set
end

function GameConfig.getIncomeMultiplier(rebirths, indexBonus)
	return (1 + rebirths * GameConfig.REBIRTH_INCOME_MULT_BONUS) * (1 + (indexBonus or 0))
end

-- Multiplicateur total d'un joueur (rebirths + index)
function GameConfig.getPlayerMultiplier(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local multiplier = GameConfig.getIncomeMultiplier(rebirths and rebirths.Value or 0, GameConfig.getIndexBonus(GameConfig.getDiscovered(player)))
	-- Game Pass "Argent x2"
	if player:GetAttribute("DoubleCash") == true then
		multiplier *= GameConfig.GAMEPASSES.DoubleCash.Multiplier
	end
	return multiplier
end

function GameConfig.getItemIncome(cardName, mutation)
	local c = GameConfig.getCard(cardName)
	if not c then return 0 end
	local mut = GameConfig.MUTATIONS[mutation or "Normal"] or GameConfig.MUTATIONS.Normal
	return c.Income * mut.Multiplier
end

function GameConfig.getSellPrice(cardName, mutation)
	return math.floor(GameConfig.getItemIncome(cardName, mutation) * GameConfig.SELL_SECONDS)
end

function GameConfig.getLockDuration(rebirths)
	return GameConfig.BASE.LockDuration + rebirths * GameConfig.BASE.LockPerRebirth
end

-- Prix du prochain rebirth (au-delà de la liste : x8 à chaque fois)
function GameConfig.getRebirth(number)
	local list = GameConfig.REBIRTHS
	if list[number] then
		return list[number]
	end
	local last = list[#list]
	return {Cash = last.Cash * 8 ^ (number - #list), Cards = last.Cards}
end

-- ====== EMPLACEMENTS DE LA BASE ======
function GameConfig.getTotalSlots()
	return GameConfig.BASE.GroundSlots + #GameConfig.FLOORS * GameConfig.BASE.FloorSlotsPerSide * 2
end

-- Infos d'un emplacement : étage (0 = rez-de-chaussée), côté (-1 gauche / 1 droite), rangée, rebirth requis
function GameConfig.getSlotInfo(index)
	local ground = GameConfig.BASE.GroundSlots
	if index <= ground then
		local perSide = ground / 2
		local side = index <= perSide and -1 or 1
		local row = side == -1 and index or index - perSide
		return {Floor = 0, Side = side, Row = row, Required = 0}
	end
	local perSide = GameConfig.BASE.FloorSlotsPerSide
	local localIndex = index - ground - 1
	local floor = localIndex // (perSide * 2) + 1
	local inFloor = localIndex % (perSide * 2) + 1
	local floorData = GameConfig.FLOORS[floor]
	if not floorData then return nil end
	local side = inFloor <= perSide and -1 or 1
	local row = side == -1 and inFloor or inFloor - perSide
	return {Floor = floor, Side = side, Row = row, Required = side == -1 and floorData.Left or floorData.Right}
end

function GameConfig.isSlotUnlocked(index, rebirths)
	local info = GameConfig.getSlotInfo(index)
	return info ~= nil and rebirths >= info.Required
end

function GameConfig.getUnlockedSlotCount(rebirths)
	local count = 0
	for index = 1, GameConfig.getTotalSlots() do
		if GameConfig.isSlotUnlocked(index, rebirths) then
			count += 1
		end
	end
	return count
end

function GameConfig.getFloorCount(rebirths)
	local count = 0
	for index, floor in ipairs(GameConfig.FLOORS) do
		if rebirths >= floor.Left then
			count = index
		end
	end
	return count
end

-- string.upper qui gère aussi les accents ("Très Rare" -> "TRÈS RARE")
local ACCENTS = {["é"] = "É", ["è"] = "È", ["ê"] = "Ê", ["à"] = "À", ["â"] = "Â", ["ç"] = "Ç", ["ô"] = "Ô", ["î"] = "Î", ["ï"] = "Ï", ["û"] = "Û", ["ù"] = "Ù", ["ë"] = "Ë", ["ì"] = "Ì"}
function GameConfig.upper(text)
	text = string.upper(text)
	for lower, upper in pairs(ACCENTS) do
		text = string.gsub(text, lower, upper)
	end
	return text
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

-- 3725 -> "1:02:05"
function GameConfig.formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h, m, s = seconds // 3600, (seconds % 3600) // 60, seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

return GameConfig
