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
-- BRAINROTS
-- Income : $ par seconde quand il est posé dans ta base
-- Image : ID d'une image uploadée sur Roblox ("rbxassetid://123456").
--         Laisse "" pour afficher le modèle 3D.
-- ============================================================
local function card(name, rarity, income, color, desc)
	return {Name = name, Rarity = rarity, Income = income, Color = color, Image = "", Desc = desc}
end
local rgb = Color3.fromRGB

GameConfig.CARDS = {
	-- Commun
	card("Lirilì Larilà", "Commun", 1, rgb(90, 170, 80), "Un éléphant-cactus en sandales. Il pique mais il est gentil."),
	card("Boneca Ambalabu", "Commun", 2, rgb(60, 200, 90), "Une grenouille coincée dans un pneu. Personne ne sait comment."),
	card("Pipi Kiwi", "Commun", 2, rgb(140, 170, 60), "Un kiwi qui court partout. Il ne s'arrête jamais."),
	card("Tim Cheese", "Commun", 3, rgb(255, 210, 70), "Une souris faite en fromage. Elle se mange elle-même."),
	card("Fluriflura", "Commun", 3, rgb(255, 150, 200), "Une fleur qui danse toute seule quand personne ne regarde."),
	-- Rare
	card("Tung Tung Tung Sahur", "Rare", 6, rgb(170, 120, 70), "Il frappe trois fois à ta porte avant le lever du soleil."),
	card("Trippi Troppi", "Rare", 7, rgb(255, 150, 60), "Moitié crevette, moitié chat, 100% chaos."),
	card("Talpa di Ferro", "Rare", 8, rgb(120, 120, 135), "Une taupe en fer qui creuse plus vite que toi."),
	card("Svinino Bombondino", "Rare", 9, rgb(255, 150, 170), "Un cochon-bombe. Ne le fais pas rire."),
	card("Frulli Frulla", "Rare", 10, rgb(120, 200, 255), "Un oiseau à lunettes accro au café."),
	-- Très Rare
	card("Tralalero Tralala", "Très Rare", 20, rgb(40, 120, 220), "Un requin à trois pattes en baskets. Il court vite."),
	card("Bombardiro Crocodilo", "Très Rare", 24, rgb(60, 130, 50), "Un crocodile-bombardier. Attention au décollage."),
	card("Cocofanto Elefanto", "Très Rare", 28, rgb(150, 100, 60), "Un éléphant dans une noix de coco. Très lourd."),
	card("Gattatino Nyanino", "Très Rare", 32, rgb(255, 180, 90), "Un chat-arc-en-ciel qui miaule en musique."),
	-- Épique
	card("Cappuccino Assassino", "Épique", 60, rgb(120, 80, 50), "Un café ninja armé de deux katanas. Serré, sans sucre."),
	card("Brr Brr Patapim", "Épique", 70, rgb(40, 150, 40), "Un arbre-singe aux pieds géants. Brr brr."),
	card("Orangutini Ananassini", "Épique", 80, rgb(230, 130, 40), "Un orang-outan déguisé en ananas."),
	card("Rhino Toasterino", "Épique", 90, rgb(170, 170, 180), "Un rhinocéros-grille-pain. Toujours chaud."),
	-- Légendaire
	card("Ballerina Cappuccina", "Légendaire", 180, rgb(255, 130, 200), "Elle danse avec une tasse de cappuccino à la place de la tête."),
	card("Chimpanzini Bananini", "Légendaire", 210, rgb(255, 220, 40), "Un singe caché dans une banane. Ou l'inverse."),
	card("Trulimero Trulicina", "Légendaire", 240, rgb(90, 180, 220), "Un poisson avec des jambes de chat. Il nage sur terre."),
	card("Espresso Signora", "Légendaire", 270, rgb(110, 60, 40), "Une dame-expresso très élégante et très énergique."),
	-- Mythique
	card("Frigo Camelo", "Mythique", 600, rgb(200, 230, 255), "Un chameau-frigo. Toujours frais, même dans le désert."),
	card("Glorbo Fruttodrillo", "Mythique", 700, rgb(255, 90, 60), "Un crocodile-pastèque qui sent le fruit rouge."),
	card("Tigrrullini Watermellini", "Mythique", 800, rgb(255, 140, 40), "Un tigre-pastèque. Il rugit en pépins."),
	card("Burbaloni Loliloli", "Mythique", 900, rgb(160, 110, 70), "Un capybara dans une noix de coco. Zen absolu."),
	-- Abyssal
	card("Blueberrinni Octopusini", "Abyssal", 2200, rgb(70, 90, 220), "Une pieuvre-myrtille venue du fond des abysses."),
	card("Bombombini Gusini", "Abyssal", 2600, rgb(230, 230, 230), "Une oie-avion de chasse. Honk honk, boum."),
	card("Piccione Macchina", "Abyssal", 3000, rgb(150, 150, 170), "Un pigeon-voiture. Il se gare n'importe où."),
	-- Enfer
	card("Dragon Cannelloni", "Enfer", 8000, rgb(255, 80, 20), "Un dragon farci aux pâtes. Il crache de la sauce bolognaise."),
	card("Nuclearo Dinossauro", "Enfer", 9500, rgb(120, 255, 60), "Un dinosaure radioactif. Ne pas toucher."),
	card("Chef Crabracadabra", "Enfer", 11000, rgb(255, 90, 70), "Un crabe cuisinier et magicien. Abracadabra, les pinces !"),
	-- Cosmique
	card("La Vaca Saturno Saturnita", "Cosmique", 30000, rgb(230, 150, 60), "Une vache-planète entourée d'anneaux. Meuh cosmique."),
	card("Sammyni Spyderini", "Cosmique", 36000, rgb(60, 40, 90), "Une araignée de l'espace qui tisse des galaxies."),
	card("Strawberrelli Flamingelli", "Cosmique", 42000, rgb(255, 80, 120), "Un flamant rose en fraise. Il tient sur une patte... en orbite."),
	-- God
	card("Odin Din Din Dun", "God", 110000, rgb(200, 200, 255), "Le dieu du tonnerre... version brainrot."),
	card("Trenostruzzo Turbo 3000", "God", 130000, rgb(90, 90, 110), "Une autruche-train turbo. 3000 km/h."),
	card("Los Tralaleritos", "God", 150000, rgb(50, 140, 240), "Toute la famille Tralalero. Ils courent ensemble."),
	-- Eternal
	card("La Grande Combinasion", "Eternal", 450000, rgb(80, 220, 255), "La combinaison ultime. Elle fait tout, tout le temps."),
	card("Garama and Madundung", "Eternal", 520000, rgb(160, 90, 40), "Deux légendes dans un seul corps. Éternels."),
	card("Pot Hotspot", "Eternal", 600000, rgb(90, 200, 255), "Une marmite qui partage sa connexion avec tout le monde."),
	-- Angel
	card("Girafa Celestre", "Angel", 1500000, rgb(255, 240, 200), "Une girafe céleste descendue des nuages."),
	card("Graipuss Medussi", "Angel", 1800000, rgb(220, 90, 255), "Une méduse-raisin divine."),
	-- Secret
	card("Ketupat Kepat", "Secret", 6000000, rgb(90, 160, 60), "Un gâteau de riz tressé... qui te regarde."),
	card("Esok Sekolah", "Secret", 7500000, rgb(240, 240, 240), "Il va à l'école demain. Tous les jours."),
	-- OG (exclusif : Booster OG et roue de la fortune uniquement)
	card("Los Combinasionas", "OG", 25000000, rgb(255, 200, 60), "La légende absolue. Introuvable dans la mine."),
}

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
-- BATTES (armurerie) : une frappe fait tomber le joueur 2 secondes
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
	{Cash = 2500, Cards = {"Pipi Kiwi", "Tim Cheese", "Lirilì Larilà"}},
	{Cash = 20000, Cards = {"Tung Tung Tung Sahur", "Trippi Troppi", "Boneca Ambalabu"}},
	{Cash = 150000, Cards = {"Tralalero Tralala", "Bombardiro Crocodilo", "Talpa di Ferro"}},
	{Cash = 1000000, Cards = {"Cappuccino Assassino", "Brr Brr Patapim", "Gattatino Nyanino"}},
	{Cash = 8000000, Cards = {"Ballerina Cappuccina", "Orangutini Ananassini", "Cocofanto Elefanto"}},
	{Cash = 60000000, Cards = {"Frigo Camelo", "Chimpanzini Bananini", "Espresso Signora"}},
	{Cash = 400000000, Cards = {"Blueberrinni Octopusini", "Glorbo Fruttodrillo", "Tigrrullini Watermellini"}},
	{Cash = 3000000000, Cards = {"Dragon Cannelloni", "Piccione Macchina", "Burbaloni Loliloli"}},
	{Cash = 25000000000, Cards = {"La Vaca Saturno Saturnita", "Nuclearo Dinossauro", "Chef Crabracadabra"}},
	{Cash = 200000000000, Cards = {"Odin Din Din Dun", "Sammyni Spyderini", "Strawberrelli Flamingelli"}},
}

-- ============================================================
-- BASES
-- ============================================================
GameConfig.BASE = {
	PlotCount = 6,
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
-- SONS (tu peux les remplacer par des sons du Creator Store : "rbxassetid://...")
-- ============================================================
GameConfig.SOUNDS = {
	Swing = {Id = "rbxasset://sounds/swordslash.wav", Volume = 0.25, Pitch = 1.35},
	Hit = {Id = "rbxasset://sounds/collide.wav", Volume = 0.55, Pitch = 0.9},
	Break = {Id = "rbxasset://sounds/snap.wav", Volume = 0.45, Pitch = 0.75},
	OreBreak = {Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.45, Pitch = 1.25},
	Card = {Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 1},
	RareCard = {Id = "rbxasset://sounds/victory.wav", Volume = 0.5, Pitch = 1},
	Coin = {Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.3, Pitch = 1.8},
	Tick = {Id = "rbxasset://sounds/clickfast.wav", Volume = 0.35, Pitch = 1.2},
	Win = {Id = "rbxasset://sounds/victory.wav", Volume = 0.55, Pitch = 1},
	BatHit = {Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.6, Pitch = 0.8},
	Click = {Id = "rbxasset://sounds/button.wav", Volume = 0.35, Pitch = 1},
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
