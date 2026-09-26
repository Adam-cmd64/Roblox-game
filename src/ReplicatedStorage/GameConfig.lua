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
-- BRAINROTS (52 cartes, toutes différentes)
-- Income : $ par seconde quand il est posé dans ta base
--
-- IMAGES : les illustrations sont rangées dans 3 grandes images ("atlas") :
--   assets/cards/cartes1.png, cartes2.png, cartes3.png (18 cartes chacune, dans l'ordre de cette liste).
-- Importe ces 3 images dans Studio et colle leurs ID dans CARD_ATLASES (voir le README).
-- ⚠️ Ne change pas l'ordre de la liste : la position d'une carte = sa place dans les images.
-- Pour ajouter une carte : mets-la à la FIN et donne-lui sa propre image (Image = "rbxassetid://...").
-- ============================================================
GameConfig.CARD_ATLASES = {
	"", -- ID de cartes1.png (exemple : "rbxassetid://123456789")
	"", -- ID de cartes2.png
	"", -- ID de cartes3.png
}
GameConfig.CARD_ATLAS_LAYOUT = {Columns = 6, Rows = 3, CellWidth = 170, CellHeight = 340}

local function card(name, rarity, income, color, desc)
	return {Name = name, Rarity = rarity, Income = income, Color = color, Image = "", Desc = desc}
end
local rgb = Color3.fromRGB

GameConfig.CARDS = {
	-- Commun
	card("Lirilì Larilà", "Commun", 1, rgb(90, 170, 80), "Un éléphant-cactus en sandales. Il pique mais il est gentil."),
	card("Boneca Ambalabu", "Commun", 2, rgb(60, 200, 90), "Une grenouille coincée dans un pneu. Personne ne sait comment."),
	card("Pesciolone Panciuto", "Commun", 2, rgb(70, 160, 210), "Un poisson avec un gros ventre. Il a trop mangé de pâtes."),
	card("Cetriolino Piedone", "Commun", 3, rgb(110, 180, 70), "Un concombre aux pieds géants. Il marche très lentement."),
	card("Caffettino Sneakerino", "Commun", 3, rgb(150, 95, 60), "Un petit café en baskets. Toujours pressé."),
	card("Teierina Camminina", "Commun", 4, rgb(200, 120, 70), "Une théière qui se promène. Attention, elle est brûlante."),
	-- Rare
	card("Tung Tung Tung Sahur", "Rare", 6, rgb(170, 120, 70), "Il frappe trois fois à ta porte avant le lever du soleil."),
	card("Ta Ta Ta Ta Sahur", "Rare", 7, rgb(200, 130, 60), "Le cousin de Tung Tung. Lui, il a un tambour."),
	card("Riccio Ananassino", "Rare", 8, rgb(230, 190, 60), "Un hérisson caché dans un ananas. Ça pique deux fois."),
	card("Procione Anguriello", "Rare", 9, rgb(220, 70, 70), "Un raton laveur qui habite dans une pastèque."),
	card("Piccione Detectivo", "Rare", 10, rgb(140, 150, 170), "Un pigeon détective. Il résout les enquêtes en mangeant du pain."),
	card("Il Cacto Hipopotamo", "Rare", 12, rgb(90, 170, 90), "Un hippopotame-cactus. Personne n'ose le câliner."),
	-- Très Rare
	card("Tralalero Tralala", "Très Rare", 20, rgb(40, 120, 220), "Un requin à trois pattes en baskets. Il court vite."),
	card("Bombardiro Crocodilo", "Très Rare", 24, rgb(90, 130, 90), "Un crocodile-bombardier. Attention au décollage."),
	card("Cocofanto Elefanto", "Très Rare", 28, rgb(150, 100, 60), "Un éléphant dans une noix de coco. Très lourd."),
	card("Svinino Bombondino", "Très Rare", 32, rgb(255, 150, 170), "Un cochon-bombe. Ne le fais pas rire."),
	card("Canguro Coccolino", "Très Rare", 36, rgb(220, 160, 90), "Un kangourou tout doux avec un bébé dans la poche."),
	-- Épique
	card("Cappuccino Assassino", "Épique", 60, rgb(120, 80, 50), "Un café ninja armé de deux katanas. Serré, sans sucre."),
	card("Brr Brr Patapim", "Épique", 70, rgb(40, 150, 40), "Un arbre-singe aux pieds géants. Brr brr."),
	card("Orangutini Ananassini", "Épique", 80, rgb(230, 130, 40), "Un orang-outan déguisé en ananas."),
	card("Rhino Toasterino", "Épique", 90, rgb(60, 120, 220), "Un rhinocéros-grille-pain. Toujours chaud."),
	card("Cappuccinetta", "Épique", 100, rgb(240, 150, 40), "La petite sœur de Cappuccino Assassino. Encore plus rapide."),
	-- Légendaire
	card("Ballerina Cappuccina", "Légendaire", 180, rgb(255, 130, 200), "Elle danse avec une tasse de cappuccino à la place de la tête."),
	card("Chimpanzini Bananini", "Légendaire", 210, rgb(255, 220, 40), "Un singe caché dans une banane. Ou l'inverse."),
	card("Trulimero Trulicina", "Légendaire", 240, rgb(90, 180, 220), "Un poisson avec des jambes de chat. Il nage sur terre."),
	card("Espresso Signora", "Légendaire", 270, rgb(110, 60, 40), "Une dame-expresso très élégante et très énergique."),
	card("Arancino Muscolino", "Légendaire", 300, rgb(230, 120, 30), "Une boulette de riz très musclée. Elle soulève des montagnes."),
	-- Mythique
	card("Frigo Camelo", "Mythique", 600, rgb(200, 230, 255), "Un chameau-frigo. Toujours frais, même dans le désert."),
	card("Glorbo Fruttodrillo", "Mythique", 700, rgb(255, 90, 60), "Un crocodile-fruit qui sent la fraise."),
	card("Zibra Zubra Zibralini", "Mythique", 800, rgb(230, 230, 230), "Un zèbre qui a trop de rayures. Il en perd partout."),
	card("Gorillo Watermelondrillo", "Mythique", 900, rgb(80, 170, 70), "Un gorille-pastèque. Il crache des pépins à 200 km/h."),
	-- Abyssal
	card("Gattino Medusino", "Abyssal", 2200, rgb(210, 130, 200), "Un chaton-méduse venu des abysses. Il brille dans le noir."),
	card("Bombombini Gusini", "Abyssal", 2600, rgb(170, 190, 210), "Une oie-avion de chasse. Honk honk, boum."),
	card("Arachidino Trattorino", "Abyssal", 3000, rgb(200, 150, 70), "Une cacahuète qui conduit un tracteur. Rien ne l'arrête."),
	-- Enfer
	card("Ananasso Crocodillo", "Enfer", 8000, rgb(220, 170, 40), "Un crocodile-ananas. Il mord ET il pique."),
	card("Arancio Nocciolone", "Enfer", 9500, rgb(255, 120, 20), "Une orange-noisette tout droit sortie des enfers."),
	card("Job Job Job Sahur", "Enfer", 11000, rgb(170, 110, 50), "Il travaille jour et nuit. Même le Sahur a peur de lui."),
	-- Cosmique
	card("La Vaca Saturno Saturnita", "Cosmique", 30000, rgb(120, 180, 160), "Une vache-planète entourée d'anneaux. Meuh cosmique."),
	card("Avocadorilla", "Cosmique", 36000, rgb(150, 220, 60), "Un gorille-avocat arrivé en soucoupe volante."),
	card("Perochello Lemonchello", "Cosmique", 42000, rgb(255, 220, 40), "Un perroquet-citron. Il répète tout, en plus acide."),
	-- God
	card("Los Tungtungtungcitos", "God", 110000, rgb(180, 120, 60), "Toute la famille Sahur réunie. Tung tung tung x10."),
	card("Ballerino Lololo", "God", 130000, rgb(250, 200, 190), "Deux danseurs divins. Ils ne s'arrêtent jamais de tourner."),
	card("Scimmio Bananino", "God", 150000, rgb(240, 200, 60), "Le dieu-singe des bananes. Il les multiplie."),
	-- Eternal
	card("La Grande Combinasion", "Eternal", 450000, rgb(80, 220, 255), "La combinaison ultime. Elle fait tout, tout le temps."),
	card("Garama and Madundung", "Eternal", 520000, rgb(160, 90, 40), "Deux légendes dans un seul corps. Éternels."),
	card("Pot Hotspot", "Eternal", 600000, rgb(90, 200, 255), "Un squelette qui partage sa connexion avec tout le monde."),
	-- Angel
	card("Graipuss Medussi", "Angel", 1500000, rgb(150, 90, 255), "Une méduse-raisin divine."),
	card("Cappuccina Lettrice", "Angel", 1800000, rgb(230, 140, 110), "Elle lit au coin du feu. Un ange au goût de café."),
	card("Los Espressos", "Angel", 2100000, rgb(120, 80, 60), "Une bande d'expressos venus du paradis. Ultra serrés."),
	-- Secret
	card("La Supreme Combinasion", "Secret", 6000000, rgb(255, 215, 90), "Encore plus forte que La Grande Combinasion. Chut..."),
	card("Tung Tung Ballerina", "Secret", 7500000, rgb(240, 170, 120), "Le Sahur a pris des cours de danse. Terrifiant."),
	-- OG (exclusif : Booster OG et roue de la fortune uniquement)
	card("Los Combinasionas", "OG", 25000000, rgb(255, 200, 60), "La légende absolue. Introuvable dans la mine."),
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
-- MUTATIONS (affichées au-dessus des brainrots avec des effets)
-- Chance : chance qu'un brainrot miné soit muté (0 = admin seulement)
-- ============================================================
GameConfig.MUTATION_ORDER = {"Normal", "Or", "Diamant", "Arc-en-ciel", "Lave", "Galaxie", "Radioactif"}

GameConfig.MUTATIONS = {
	["Normal"] = {Multiplier = 1, Chance = 0},
	["Or"] = {Multiplier = 1.5, Chance = 0.03, Colors = {rgb(255, 240, 150), rgb(255, 180, 0)}},
	["Diamant"] = {Multiplier = 2, Chance = 0.01, Colors = {rgb(200, 255, 255), rgb(40, 190, 255)}},
	["Arc-en-ciel"] = {Multiplier = 3, Chance = 0.003, Rainbow = true, Colors = {rgb(255, 60, 60), rgb(60, 120, 255)}},
	["Lave"] = {Multiplier = 4, Chance = 0.001, Colors = {rgb(255, 200, 0), rgb(200, 20, 0)}},
	["Galaxie"] = {Multiplier = 6, Chance = 0, Colors = {rgb(230, 120, 255), rgb(30, 0, 90)}},
	["Radioactif"] = {Multiplier = 8, Chance = 0, Colors = {rgb(200, 255, 80), rgb(20, 120, 0)}},
}

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
	{Cash = 2500, Cards = {"Lirilì Larilà", "Boneca Ambalabu", "Pesciolone Panciuto"}},
	{Cash = 20000, Cards = {"Tung Tung Tung Sahur", "Riccio Ananassino", "Caffettino Sneakerino"}},
	{Cash = 150000, Cards = {"Tralalero Tralala", "Piccione Detectivo", "Teierina Camminina"}},
	{Cash = 1000000, Cards = {"Cappuccino Assassino", "Bombardiro Crocodilo", "Il Cacto Hipopotamo"}},
	{Cash = 8000000, Cards = {"Ballerina Cappuccina", "Brr Brr Patapim", "Cocofanto Elefanto"}},
	{Cash = 60000000, Cards = {"Frigo Camelo", "Chimpanzini Bananini", "Rhino Toasterino"}},
	{Cash = 400000000, Cards = {"Gattino Medusino", "Glorbo Fruttodrillo", "Espresso Signora"}},
	{Cash = 3000000000, Cards = {"Ananasso Crocodillo", "Bombombini Gusini", "Zibra Zubra Zibralini"}},
	{Cash = 25000000000, Cards = {"La Vaca Saturno Saturnita", "Job Job Job Sahur", "Arachidino Trattorino"}},
	{Cash = 200000000000, Cards = {"Los Tungtungtungcitos", "Avocadorilla", "Arancio Nocciolone"}},
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
	{Id = "OG", Name = "Booster OG", Price = 4999, ProductId = 0, Cards = 3, Color = rgb(255, 210, 60), Exclusive = true,
		Odds = {{"Mythique", 38}, {"Abyssal", 25}, {"Enfer", 17}, {"Cosmique", 11}, {"God", 6}, {"Eternal", 2}, {"Angel", 0.7}, {"Secret", 0.25}, {"OG", 0.05}}},
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
		{Id = "BoosterOG", Name = "Booster OG", Icon = "👑", Weight = 3, Color = rgb(255, 60, 150)},
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

GameConfig.DATASTORE_NAME = "BrainrotMine_v1"

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
	return GameConfig.getIncomeMultiplier(rebirths and rebirths.Value or 0, GameConfig.getIndexBonus(GameConfig.getDiscovered(player)))
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
