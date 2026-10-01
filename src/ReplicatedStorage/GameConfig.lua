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
	"Limited", -- cartes EXCLUSIVES du Pack Limited (boutique Robux) : jamais dans la mine
}

GameConfig.RARITIES = {
	["Commun"] = {Weight = 1000, IndexBonus = 0.05, Color = Color3.fromRGB(185, 190, 200), Color2 = Color3.fromRGB(105, 110, 125)},
	["Rare"] = {Weight = 70, IndexBonus = 0.05, Color = Color3.fromRGB(70, 150, 255), Color2 = Color3.fromRGB(25, 70, 200)},
	["Très Rare"] = {Weight = 11, IndexBonus = 0.075, Color = Color3.fromRGB(0, 230, 200), Color2 = Color3.fromRGB(0, 120, 145)},
	["Épique"] = {Weight = 2.2, IndexBonus = 0.1, Color = Color3.fromRGB(190, 95, 255), Color2 = Color3.fromRGB(95, 25, 185)},
	["Légendaire"] = {Weight = 0.45, IndexBonus = 0.1, Color = Color3.fromRGB(255, 195, 40), Color2 = Color3.fromRGB(235, 105, 0)},
	["Mythique"] = {Weight = 0.09, IndexBonus = 0.125, Color = Color3.fromRGB(255, 70, 120), Color2 = Color3.fromRGB(165, 0, 65)},
	["Abyssal"] = {Weight = 0.018, IndexBonus = 0.15, Color = Color3.fromRGB(40, 120, 255), Color2 = Color3.fromRGB(5, 12, 60)},
	["Enfer"] = {Weight = 0.0038, IndexBonus = 0.15, Color = Color3.fromRGB(255, 95, 0), Color2 = Color3.fromRGB(115, 0, 0)},
	["Cosmique"] = {Weight = 0.0012, IndexBonus = 0.2, Color = Color3.fromRGB(255, 90, 230), Color2 = Color3.fromRGB(40, 0, 110)},
	["God"] = {Weight = 0.0004, IndexBonus = 0.2, Color = Color3.fromRGB(255, 245, 150), Color2 = Color3.fromRGB(255, 175, 0)},
	["Eternal"] = {Weight = 0.0001, IndexBonus = 0.25, Color = Color3.fromRGB(0, 255, 225), Color2 = Color3.fromRGB(145, 0, 255)},
	["Angel"] = {Weight = 0.0000049, IndexBonus = 0.25, Color = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(140, 205, 255)},
	["Secret"] = {Weight = 0.00000078, IndexBonus = 0.3, Color = Color3.fromRGB(70, 70, 80), Color2 = Color3.fromRGB(0, 0, 0)},
	-- Limited : design spécial (cadre doré irisé, fond nuit, « LIMITED » en filigrane, étincelles dorées)
	["Limited"] = {Weight = 0, IndexBonus = 0.3, Limited = true, Color = Color3.fromRGB(255, 205, 80), Color2 = Color3.fromRGB(110, 30, 200)},
	-- OG : chance FIXE en minant (FixedChance), la même avec TOUTES les pioches, à toutes les profondeurs,
	-- avec ou sans potion : 1 minerai brainrot sur 12000
	["OG"] = {Weight = 0.0000000613, FixedChance = 1 / 12000, IndexBonus = 0.5, Color = Color3.fromRGB(255, 225, 90), Color2 = Color3.fromRGB(255, 40, 160)},
}

for index, name in ipairs(GameConfig.RARITY_ORDER) do
	GameConfig.RARITIES[name].Order = index
	GameConfig.RARITIES[name].Name = name
end

-- ============================================================
-- BRAINROTS (35 cartes + 4 cartes LIMITED, toutes différentes)
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
	"rbxassetid://86074379090307", -- ID de cartes4.png (les 4 cartes LIMITED)
	"rbxassetid://94929535403110", -- ID de cartes5.png (les brainrots du monde 2 + Pesciolone)
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
	card("Pesciolone Panciuto", "Très Rare", 36, rgb(60, 80, 110), "Une orque-piano au gros ventre. Elle joue une mélodie en nageant."),
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
	-- OG : Booster Céleste, ou 1 chance sur 12000 par minerai (la même avec toutes les pioches)
	card("Lucky Block Arc-en-ciel", "OG", 25000000, rgb(80, 120, 255), "La légende absolue. Presque introuvable dans la mine."),
}

-- ============================================================
-- CARTES LIMITED : seulement dans le PACK LIMITED (boutique Robux), jamais dans la mine.
-- Leur image est dans assets/cards/cartes4.png (atlas n°4).
-- ============================================================
GameConfig.LIMITED_CARDS = {
	card("Cappuccina Principessa", "Limited", 30000000, rgb(240, 220, 200), "Une tasse de cappuccino de sang royal. Elle ne se réveille que pour les VIP."),
	card("Gattino Smeraldino", "Limited", 60000000, rgb(90, 230, 120), "Un chat-robot entouré d'étincelles d'émeraude. Il porte bonheur."),
	card("Ranapesce Gigante", "Limited", 110000000, rgb(110, 170, 70), "Mi-grenouille, mi-poisson, 100 % légendaire. Il saute plus haut que la mine."),
	card("Gorillo Avocadillo", "Limited", 200000000, rgb(70, 200, 60), "Le roi des Limited : un gorille-avocat au cœur d'or. 1 chance sur 200."),
}
for cell, c in ipairs(GameConfig.LIMITED_CARDS) do
	c.Atlas = 4
	c.Cell = cell - 1
	table.insert(GameConfig.CARDS, c)
end

-- Position de chaque carte dans les images (atlas)
do
	local layout = GameConfig.CARD_ATLAS_LAYOUT
	local perAtlas = layout.Columns * layout.Rows
	for index, c in ipairs(GameConfig.CARDS) do
		if not c.Atlas then -- les cartes Limited ont déjà leur place (atlas n°4)
			c.Atlas = (index - 1) // perAtlas + 1
			c.Cell = (index - 1) % perAtlas
		end
	end
end

-- ============================================================
-- BRAINROTS DU MONDE 2 (NUIT DE CRISTAL) : on les trouve SEULEMENT en minant dans le monde 2
-- (image : assets/cards/cartes5.png = atlas n°5, case "Cell" de 0 à 11)
-- ============================================================
local function worldCard(name, rarity, income, color, desc, cell)
	local c = card(name, rarity, income, color, desc)
	c.Atlas = 5
	c.Cell = cell
	c.World = 2
	return c
end
GameConfig.NEW_CARDS = {
	-- (bien plus forts que ceux du monde 1, le SECRET dépasse même l'OG !)
	worldCard("Bidone Zebrato", "Commun", 5000, rgb(70, 75, 90), "Une poubelle rayée qui avale tout. Même les pioches.", 8),
	worldCard("Cubotto Rossiccio", "Rare", 15000, rgb(150, 60, 40), "Un cube en brique avec une oreille. Il écoute tout ce que tu dis.", 1),
	worldCard("Orsetto Galeotto", "Très Rare", 45000, rgb(150, 100, 60), "Un ours en costume rayé et lunettes de soleil. Il s'est évadé de la mine.", 9),
	worldCard("Bananito Lunare", "Épique", 120000, rgb(250, 220, 60), "Une banane qui ne sort que la nuit. Elle a un croissant de lune sur la tête.", 4),
	worldCard("Aranciotto Baffuto", "Légendaire", 350000, rgb(240, 150, 50), "Une orange-robot à moustache. Elle roule plus vite qu'elle ne marche.", 7),
	worldCard("Maialino Mattoncino", "Mythique", 900000, rgb(235, 140, 100), "Un cochon en briques avec deux têtes. Il mange deux fois plus.", 2),
	worldCard("Granchiobot Arancino", "Abyssal", 2500000, rgb(210, 100, 40), "Un crabe-robot en métal brûlant. Ses pinces coupent les pioches.", 3),
	worldCard("Tartina Zuccherina", "Enfer", 7000000, rgb(255, 150, 220), "Une tartine rose couverte de vermicelles. Elle brille dans le noir.", 5),
	worldCard("Cactusello Fiorito", "Cosmique", 20000000, rgb(90, 200, 90), "Un cactus couvert de roses. Il pique, mais avec amour.", 11),
	worldCard("Bombardino Grigio", "God", 60000000, rgb(120, 130, 150), "Un avion gris qui largue des cristaux sur la Nuit de Cristal.", 10),
	worldCard("Rana Pneumatica", "Secret", 500000000, rgb(80, 170, 70), "Une grenouille coincée dans un pneu. Personne ne sait comment elle est arrivée là.", 6),
}
-- Rangés dans la liste avec les cartes de la même rareté (pour l'Index)
for _, c in ipairs(GameConfig.NEW_CARDS) do
	local position = #GameConfig.CARDS + 1
	for index, other in ipairs(GameConfig.CARDS) do
		if other.Rarity == c.Rarity then
			position = index + 1
		end
	end
	table.insert(GameConfig.CARDS, position, c)
end
-- Le Pesciolone Panciuto a une nouvelle image (avant, c'était la même que la Limited « Ranapesce Gigante »)
for _, c in ipairs(GameConfig.CARDS) do
	if c.Name == "Pesciolone Panciuto" then
		c.Atlas = 5
		c.Cell = 0
	end
end

-- BIENTÔT : brainrots déjà dans l'Index (silhouette + cadenas) mais PAS encore obtenables.
-- {Name, Rarity, Atlas, Cell} : pour en débloquer un, mets-le dans une liste de cartes avec sa case d'image.
GameConfig.COMING_SOON = {}
GameConfig.COMING_SOON_PLACEHOLDERS = 4 -- cases "BIENTÔT" sans image (le monde 3 !)
function GameConfig.getComingSoon(name)
	for _, c in ipairs(GameConfig.COMING_SOON) do
		if c.Name == name then
			return c
		end
	end
	return nil
end

-- ============================================================
-- LES MONDES : le Portail Mystère (touche E) emmène dans le MONDE 2
-- Le monde 2 est construit loin du monde 1 (Origin), avec sa mine, ses 8 bases, son ciel et ses décors.
-- ============================================================
GameConfig.WORLDS = {
	{Id = 1, Name = "Monde Brainrot", Origin = Vector3.new(0, 0, 0), CashMultiplier = 1, LuckMultiplier = 1},
	-- Monde 2 : il faut être REBIRTH 10. Sa mine a SES PROPRES COUCHES (GameConfig.LAYERS_W2, plus profonde : 72),
	-- une couche par pioche de cristal, et la chance de la pioche est divisée par 22 (même difficulté que le monde 1).
	{Id = 2, Name = "Nuit de Cristal", Origin = Vector3.new(0, 0, 4000), RequiredRebirths = 10,
		CashMultiplier = 1, LuckMultiplier = 1, LuckDivisor = 22, Layers = "LAYERS_W2", Depth = 72},
}
GameConfig.WORLD_BORDER_Z = 2000 -- plus loin que ça (en Z) : on est dans le monde 2
function GameConfig.getWorldAt(position)
	return position.Z > GameConfig.WORLD_BORDER_Z and 2 or 1
end
function GameConfig.getWorld(id)
	return GameConfig.WORLDS[id] or GameConfig.WORLDS[1]
end

-- Cette carte peut-elle sortir de cette source ? ("Mine", "Booster", "Wheel", "Gift") et dans quel monde ?
-- Les brainrots du monde 2 ne sortent QUE de la mine du monde 2.
function GameConfig.canDrop(c, source, world)
	if c.Rarity == "Limited" then return false end
	if c.World == 2 then
		return source == "Mine" and world == 2
	end
	return true
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
	-- Lave : plus obtenable nulle part (les cartes Lave déjà trouvées restent, et l'Index la garde)
	["Lave"] = {Multiplier = 4, Chance = 0, Retired = true, Sparkles = 6, Colors = {rgb(255, 200, 0), rgb(220, 30, 0)}},
	-- Galaxie : seulement dans le MONDE 2
	["Galaxie"] = {Multiplier = 6, Chance = 0.0005, Worlds = {2}, Sparkles = 12, Colors = {rgb(230, 130, 255), rgb(40, 0, 110)}},
	["Radioactif"] = {Multiplier = 8, Chance = 0.0002, Sparkles = 7, Colors = {rgb(200, 255, 80), rgb(20, 140, 0)}},
}
-- Annonce dans le chat quand quelqu'un obtient une carte de cette rareté ou plus
GameConfig.ANNOUNCE_FROM_RARITY = "Abyssal"
GameConfig.MUTATION_MAX_CHANCE = 0.35 -- jamais plus de 35 % de chance d'avoir une mutation

-- ============================================================
-- PIOCHES (style Minecraft) : il faut le bon nombre de rebirths ET l'argent
-- Luck : multiplie les chances d'avoir des brainrots rares
-- IconGlow : couleur du halo derrière l'icône du shop (sinon la couleur de la tête)
-- ============================================================
GameConfig.PICKAXES = {
	{Name = "Pioche en Bois", Damage = 1, Cooldown = 0.32, Cost = 0, RequiredRebirths = 0, Luck = 1, HeadColor = rgb(160, 120, 70)},
	{Name = "Pioche en Pierre", Damage = 3, Cooldown = 0.29, Cost = 1500, RequiredRebirths = 1, Luck = 1.5, HeadColor = rgb(140, 140, 140)},
	{Name = "Pioche en Fer", Damage = 8, Cooldown = 0.26, Cost = 15000, RequiredRebirths = 2, Luck = 2, HeadColor = rgb(230, 230, 230)},
	{Name = "Pioche en Or", Damage = 20, Cooldown = 0.22, Cost = 120000, RequiredRebirths = 3, Luck = 3, HeadColor = rgb(255, 215, 40)},
	{Name = "Pioche en Diamant", Damage = 50, Cooldown = 0.19, Cost = 1000000, RequiredRebirths = 4, Luck = 4.5, HeadColor = rgb(70, 230, 220)},
	{Name = "Pioche en Netherite", Damage = 120, Cooldown = 0.16, Cost = 8000000, RequiredRebirths = 5, Luck = 6.5, HeadColor = rgb(80, 70, 78), IconGlow = rgb(255, 120, 40)},
	{Name = "Pioche en Émeraude", Damage = 300, Cooldown = 0.14, Cost = 60000000, RequiredRebirths = 6, Luck = 9, HeadColor = rgb(60, 220, 110)},
	{Name = "Pioche en Rubis", Damage = 750, Cooldown = 0.13, Cost = 450000000, RequiredRebirths = 7, Luck = 12, HeadColor = rgb(230, 40, 70)},
	{Name = "Pioche Cosmique", Damage = 1800, Cooldown = 0.12, Cost = 3000000000, RequiredRebirths = 8, Luck = 16, HeadColor = rgb(170, 90, 255)},
	{Name = "Pioche du Vide", Damage = 4500, Cooldown = 0.11, Cost = 25000000000, RequiredRebirths = 9, Luck = 22, HeadColor = rgb(35, 20, 50), IconGlow = rgb(170, 90, 255)},
	-- ===== PIOCHES DE CRISTAL : vendues à la CRISTALLERIE du monde 2 (une par rebirth : 11 à 18) =====
	-- Chaque pioche ouvre une nouvelle couche de la mine du monde 2 (LAYERS_W2) ; la chance y est divisée par 22 :
	-- la Pioche de Cristal y vaut la Pioche en Pierre du monde 1, l'Astrale y vaut la Cosmique...
	-- mais dans le monde 1, elles sont ÉNORMES (chance jusqu'à x352 !)
	{Name = "Pioche de Cristal", World = 2, Damage = 13500, Cooldown = 0.105, Cost = 30000000, RequiredRebirths = 11, Luck = 33, HeadColor = rgb(90, 225, 255), IconGlow = rgb(140, 245, 255)},
	{Name = "Pioche Aurore", World = 2, Damage = 36000, Cooldown = 0.1, Cost = 300000000, RequiredRebirths = 12, Luck = 44, HeadColor = rgb(70, 255, 190), IconGlow = rgb(120, 255, 220)},
	{Name = "Pioche Saphir", World = 2, Damage = 90000, Cooldown = 0.095, Cost = 2400000000, RequiredRebirths = 13, Luck = 66, HeadColor = rgb(60, 110, 255), IconGlow = rgb(110, 170, 255)},
	{Name = "Pioche Néon", World = 2, Damage = 225000, Cooldown = 0.09, Cost = 20000000000, RequiredRebirths = 14, Luck = 99, HeadColor = rgb(255, 80, 210), IconGlow = rgb(255, 140, 235)},
	{Name = "Pioche Nébuleuse", World = 2, Damage = 540000, Cooldown = 0.085, Cost = 160000000000, RequiredRebirths = 15, Luck = 143, HeadColor = rgb(150, 80, 255), IconGlow = rgb(200, 140, 255)},
	{Name = "Pioche Prismatique", World = 2, Damage = 1350000, Cooldown = 0.08, Cost = 1200000000000, RequiredRebirths = 16, Luck = 198, HeadColor = rgb(235, 245, 255), IconGlow = rgb(120, 240, 255), Rainbow = true},
	{Name = "Pioche Supernova", World = 2, Damage = 3375000, Cooldown = 0.075, Cost = 9000000000000, RequiredRebirths = 17, Luck = 264, HeadColor = rgb(255, 170, 50), IconGlow = rgb(255, 230, 120)},
	{Name = "Pioche Astrale", World = 2, Damage = 8100000, Cooldown = 0.07, Cost = 60000000000000, RequiredRebirths = 18, Luck = 352, HeadColor = rgb(255, 255, 255), IconGlow = rgb(255, 120, 240), Rainbow = true},
}
for _, pickaxe in ipairs(GameConfig.PICKAXES) do
	if pickaxe.World == 2 then
		pickaxe.Crystal = true -- design « cristal » (lueurs + particules) : voir PickaxeBuilder
	end
end

-- PIOCHE DIVINE : seulement avec la commande admin /pioche (pas vendue à la boutique).
-- Elle casse N'IMPORTE QUEL bloc en 1 coup, même les couches que tu ajouteras plus tard
-- (dégâts infinis + elle ignore la pioche minimum des couches).
GameConfig.DIVINE_PICKAXE = {
	Name = "Pioche Divine", Damage = math.huge, Cooldown = 0.1, Cost = 0, RequiredRebirths = 0,
	Luck = 400, HeadColor = rgb(255, 214, 90), IconGlow = rgb(110, 235, 255), Divine = true,
}

-- La pioche qu'a vraiment ce joueur (la Pioche Divine passe avant tout)
function GameConfig.getPlayerPickaxe(player)
	if player:GetAttribute("DivinePickaxe") then
		return GameConfig.DIVINE_PICKAXE
	end
	local tier = player:FindFirstChild("PickaxeTier")
	return GameConfig.PICKAXES[tier and tier.Value or 1] or GameConfig.PICKAXES[1]
end

-- ============================================================
-- GRAPPINS (boutique, touche F) : vise un endroit et clique pour t'y envoler.
-- Impossible de s'en servir en portant un brainrot volé.
-- ============================================================
-- RequiredRebirths : il faut ce nombre de rebirths pour l'acheter (comme les pioches)
GameConfig.GRAPPLES = {
	{Name = "Grappin", Cost = 5000, RequiredRebirths = 1, Range = 60, Cooldown = 4, Speed = 70, Color = rgb(200, 200, 210)},
	{Name = "Grappin renforcé", Cost = 300000, RequiredRebirths = 3, Range = 90, Cooldown = 3, Speed = 85, Color = rgb(255, 200, 60)},
	{Name = "Grappin laser", Cost = 30000000, RequiredRebirths = 6, Range = 130, Cooldown = 2, Speed = 100, Color = rgb(80, 230, 255)},
}

-- ============================================================
-- BATTES (à la boutique, touche F) : une frappe fait tomber le joueur 2 secondes
-- et lui fait lâcher le brainrot qu'il est en train de voler.
-- ============================================================
-- RequiredRebirths : il faut ce nombre de rebirths pour l'acheter (comme les pioches)
GameConfig.BATS = {
	{Name = "Batte en bois", Cost = 0, RequiredRebirths = 0, Cooldown = 1.6, Range = 8, Color = rgb(170, 120, 70), Material = Enum.Material.Wood},
	{Name = "Batte en métal", Cost = 25000, RequiredRebirths = 1, Cooldown = 1.3, Range = 9.5, Color = rgb(170, 175, 185), Material = Enum.Material.Metal},
	{Name = "Batte en or", Cost = 750000, RequiredRebirths = 3, Cooldown = 1.0, Range = 11, Color = rgb(255, 200, 40), Material = Enum.Material.Metal},
	{Name = "Batte en diamant", Cost = 20000000, RequiredRebirths = 5, Cooldown = 0.8, Range = 12.5, Color = rgb(80, 230, 255), Material = Enum.Material.Glass},
	{Name = "Batte cosmique", Cost = 500000000, RequiredRebirths = 7, Cooldown = 0.6, Range = 14, Color = rgb(200, 80, 255), Material = Enum.Material.Neon},
}
GameConfig.STUN_TIME = 2

-- ============================================================
-- MINE
-- ============================================================
GameConfig.MINE = {
	Center = Vector3.new(0, 0, 0), -- centre du dessus de la mine (le sol est à Y = 0)
	BlockSize = 4,
	Grid = 32, -- 32 x 32 blocs de large
	Depth = 60, -- 60 couches de profondeur
	MineRange = 14, -- distance max pour miner un bloc
	ResetInterval = 300, -- la mine se régénère toutes les 5 minutes
	NoOreLayers = 2, -- pas de minerai dans les 2 premières couches : il faut creuser !
	-- COFFRES (ils donnent un minerai à coup sûr) : très rares !
	-- À chaque régénération de la mine, on tire au sort combien de coffres il y aura dans ce cycle :
	ChestsPerCycle = {55, 45}, -- chances (en %) d'avoir 0 ou 1 coffre (1 MAXIMUM, et souvent aucun : il faut attendre le cycle d'après)
	ChestChance = 0.003, -- tant qu'il reste un coffre à placer : 0,3 % de chance par bloc qui apparaît
	ChestFromLayer = 4, -- pas de coffre dans les 3 premières couches
	OreChanceBase = 0.055, -- 5,5 % de minerai (blocs avec un brainrot)...
	OreChancePerLayer = 0.003, -- ... +0,3 % par couche
	LuckPerLayer = 0.03, -- +3% de chance par couche de profondeur
	LuckExponent = 0.28, -- à quel point la chance favorise les raretés hautes
}

GameConfig.LAYERS = {
	{From = 1, To = 1, Name = "Herbe", Material = Enum.Material.Grass, Color = rgb(90, 170, 60), HP = 5, Cash = 1, MinTier = 1},
	{From = 2, To = 5, Name = "Terre", Material = Enum.Material.Ground, Color = rgb(125, 90, 60), HP = 7, Cash = 1, MinTier = 1},
	{From = 6, To = 12, Name = "Pierre", Material = Enum.Material.Slate, Color = rgb(125, 125, 125), HP = 16, Cash = 3, MinTier = 1},
	{From = 13, To = 20, Name = "Roche profonde", Material = Enum.Material.Basalt, Color = rgb(70, 70, 80), HP = 48, Cash = 10, MinTier = 2},
	{From = 21, To = 27, Name = "Magma", Material = Enum.Material.CrackedLava, Color = rgb(110, 45, 30), HP = 145, Cash = 35, MinTier = 3},
	{From = 28, To = 33, Name = "Obsidienne", Material = Enum.Material.Slate, Color = rgb(45, 25, 70), HP = 420, Cash = 120, MinTier = 4},
	{From = 34, To = 38, Name = "Débris antiques", Material = Enum.Material.Rock, Color = rgb(95, 60, 50), HP = 1100, Cash = 400, MinTier = 5},
	{From = 39, To = 45, Name = "Cristal", Material = Enum.Material.Glass, Color = rgb(120, 200, 255), HP = 2900, Cash = 1200, MinTier = 6},
	{From = 46, To = 52, Name = "Néant", Material = Enum.Material.Slate, Color = rgb(40, 20, 60), HP = 7200, Cash = 3500, MinTier = 7},
	{From = 53, To = 57, Name = "Cœur cosmique", Material = Enum.Material.Glass, Color = rgb(200, 80, 255), HP = 17600, Cash = 9000, MinTier = 8},
	{From = 58, To = 60, Name = "Noyau", Material = Enum.Material.CrackedLava, Color = rgb(255, 120, 40), HP = 40000, Cash = 25000, MinTier = 9},
}

-- ============================================================
-- COUCHES DE LA MINE DU MONDE 2 (Nuit de Cristal) : 72 couches, aucune comme dans le monde 1.
-- MinTier = la pioche minimum (10 = Pioche du Vide, 11 = Pioche de Cristal ... 18 = Pioche Astrale).
-- ============================================================
GameConfig.LAYERS_W2 = {
	{From = 1, To = 4, Name = "Poussière d'étoiles", Material = Enum.Material.Sand, Color = rgb(170, 160, 230), HP = 22500, Cash = 2000, MinTier = 10},
	{From = 5, To = 10, Name = "Quartz bleu", Material = Enum.Material.Glass, Color = rgb(90, 150, 255), HP = 36000, Cash = 6000, MinTier = 10},
	{From = 11, To = 17, Name = "Glace lunaire", Material = Enum.Material.Ice, Color = rgb(170, 230, 255), HP = 81000, Cash = 20000, MinTier = 11},
	{From = 18, To = 24, Name = "Améthyste", Material = Enum.Material.Glass, Color = rgb(160, 80, 230), HP = 216000, Cash = 70000, MinTier = 12},
	{From = 25, To = 31, Name = "Saphir des abysses", Material = Enum.Material.Glacier, Color = rgb(40, 70, 200), HP = 540000, Cash = 240000, MinTier = 13},
	{From = 32, To = 38, Name = "Néon fossile", Material = Enum.Material.Neon, Color = rgb(255, 70, 190), HP = 1350000, Cash = 800000, MinTier = 14},
	{From = 39, To = 45, Name = "Nébuleuse", Material = Enum.Material.Glass, Color = rgb(110, 40, 180), HP = 3240000, Cash = 2400000, MinTier = 15},
	{From = 46, To = 52, Name = "Prisme", Material = Enum.Material.Foil, Color = rgb(225, 235, 255), HP = 8100000, Cash = 7000000, MinTier = 16},
	{From = 53, To = 59, Name = "Cœur de supernova", Material = Enum.Material.CrackedLava, Color = rgb(255, 150, 40), HP = 20250000, Cash = 20000000, MinTier = 17},
	{From = 60, To = 66, Name = "Voile astral", Material = Enum.Material.Glass, Color = rgb(255, 200, 245), HP = 48600000, Cash = 50000000, MinTier = 18},
	{From = 67, To = 72, Name = "Singularité", Material = Enum.Material.Slate, Color = rgb(20, 10, 40), HP = 97200000, Cash = 120000000, MinTier = 18},
}

-- ============================================================
-- REBIRTHS : de l'argent + plusieurs brainrots précis (ils sont consommés)
-- Chaque rebirth : +50% de revenu, verrou de base plus long, étages, pioche suivante à la boutique.
-- ============================================================
GameConfig.REBIRTH_INCOME_MULT_BONUS = 0.5
GameConfig.MAX_REBIRTHS = 18 -- 10 rebirths dans le monde 1 + 8 dans le monde 2 (une pioche de cristal par rebirth)
GameConfig.REBIRTHS = {
	{Cash = 15000, Cards = {"Cartonino Scatolino", "Sassolino Maculato", "Teierina Camminina"}},
	{Cash = 150000, Cards = {"Tung Tung Tung Sahur", "Bottiglione Zuppone", "Riccio Paffutello"}},
	{Cash = 1500000, Cards = {"Topolino Occhialino", "Fragolone Cubone", "Squalo Cubetto"}},
	{Cash = 12000000, Cards = {"Piccione Aviatore", "Gufo Pinetto", "Pesciolone Panciuto"}},
	{Cash = 100000000, Cards = {"Tralalero Tralala", "Cappuccino Assassino", "Tazzina Fiammante"}},
	{Cash = 800000000, Cards = {"Canguro Coccolino", "Zuccone Sneakerone", "Bruno Scarpone"}},
	{Cash = 6000000000, Cards = {"Orangutini Ananassini", "Leonelli Cactuselli", "Tartaruga Anguria"}},
	{Cash = 50000000000, Cards = {"Pandaccini Bananini", "Anguriello Furioso", "Spiderino Rossino"}},
	{Cash = 400000000000, Cards = {"Blueberrinni Octopusini", "Pot Hotspot", "Tigrrullini Watermellini"}},
	{Cash = 3000000000000, Cards = {"La Vaca Saturno Saturnita", "Perochello Lemonchello", "Tigre Imperiale"}},
	-- REBIRTHS 11 à 18 : avec des brainrots du MONDE 2. Chacun débloque une pioche de cristal (Cristallerie).
	{Cash = 500000000, Cards = {"Bidone Zebrato", "Cubotto Rossiccio", "Orsetto Galeotto"}},
	{Cash = 5000000000, Cards = {"Cubotto Rossiccio", "Orsetto Galeotto", "Bananito Lunare"}},
	{Cash = 50000000000, Cards = {"Orsetto Galeotto", "Bananito Lunare", "Aranciotto Baffuto"}},
	{Cash = 400000000000, Cards = {"Bananito Lunare", "Aranciotto Baffuto", "Maialino Mattoncino"}},
	{Cash = 3000000000000, Cards = {"Aranciotto Baffuto", "Maialino Mattoncino", "Granchiobot Arancino"}},
	{Cash = 25000000000000, Cards = {"Maialino Mattoncino", "Granchiobot Arancino", "Tartina Zuccherina"}},
	{Cash = 200000000000000, Cards = {"Granchiobot Arancino", "Tartina Zuccherina", "Cactusello Fiorito"}},
	{Cash = 1500000000000000, Cards = {"Tartina Zuccherina", "Cactusello Fiorito", "Bombardino Grigio"}},
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

-- Récompenses de l'Index : quand tu as découvert X brainrots différents (une seule fois)
GameConfig.DEX_REWARDS = {
	{Count = 5, Cash = 5000},
	{Count = 10, Cash = 75000, Spins = 1},
	{Count = 20, Cash = 2000000, Spins = 2},
	{Count = 30, Cash = 100000000, Spins = 3, PotionMinutes = 15},
	{Count = 35, Cash = 5000000000, Spins = 5, PotionMinutes = 30},
}

-- Piratage des lasers (mini-jeu des fils, au panneau à droite de l'entrée des bases)
GameConfig.HACK = {
	Time = 10, -- secondes pour réussir (pareil contre tout le monde)
	-- RÉUSSI : les lasers restent allumés, mais on enlève un morceau du temps de verrouillage
	SuccessCut = 0.25, -- part du temps de verrouillage TOTAL qui est enlevée (0.25 = un quart)
	SuccessCooldown = 60, -- réussi : 1 minute avant de pouvoir repirater CETTE base
	Wires = 6, -- nombre de fils
	Cuts = 4, -- fils à couper dans l'ordre
	FailCooldown = 120, -- raté : 2 minutes avant de pouvoir repirater CETTE base
	Memorize = false, -- true : l'ordre des fils disparaît après MemorizeTime (il faut le retenir)
	MemorizeTime = 2.5,
	Shuffle = false, -- true : les fils changent de place après chaque bonne coupe
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
	{Id = "Commun", Name = "Booster Commun", Price = 49, ProductId = 3715324815, Cards = 3, Color = rgb(110, 170, 255),
		Odds = {{"Commun", 70}, {"Rare", 25}, {"Très Rare", 5}}},
	{Id = "Epique", Name = "Booster Épique", Price = 129, ProductId = 3715325062, Cards = 3, Color = rgb(185, 90, 255),
		Odds = {{"Rare", 50}, {"Très Rare", 35}, {"Épique", 13}, {"Légendaire", 2}}},
	{Id = "Legendaire", Name = "Booster Légendaire", Price = 299, ProductId = 3715325143, Cards = 3, Color = rgb(255, 180, 30),
		Odds = {{"Épique", 55}, {"Légendaire", 35}, {"Mythique", 9}, {"Abyssal", 1}}},
	{Id = "Divin", Name = "Booster Divin", Price = 649, ProductId = 3715325217, Cards = 3, Color = rgb(255, 80, 60),
		Odds = {{"Légendaire", 50}, {"Mythique", 32}, {"Abyssal", 11}, {"Enfer", 5}, {"Cosmique", 1.5}, {"God", 0.5}}},
	{Id = "Galaxie", Name = "Booster Galaxie", Price = 999, ProductId = 3715325258, Cards = 3, Color = rgb(255, 210, 60), Exclusive = true,
		Odds = {{"Mythique", 38}, {"Abyssal", 25}, {"Enfer", 17}, {"Cosmique", 11}, {"God", 6}, {"Eternal", 2}, {"Angel", 1}}},
	-- 1 seule carte, mais au minimum un Angel !
	{Id = "Celeste", Name = "Booster Céleste", Price = 1499, ProductId = 3715325306, Cards = 1, Color = rgb(150, 220, 255), Exclusive = true,
		Odds = {{"Angel", 69.8}, {"Secret", 29.95}, {"OG", 0.25}}},
}

-- ============================================================
-- PACK LIMITED : 1 pack = 1 carte Limited (avec son numéro de tirage #)
-- Cards : {carte, chance en %}   Offers : les 3 offres de la boutique (1, 5 ou 10 packs)
-- ProductId : ID du "Produit développeur" de chaque offre (0 = gratuit dans Studio, désactivé en jeu)
-- ============================================================
GameConfig.LIMITED_PACK = {
	Id = "Limited",
	Name = "Pack Limited",
	Color = rgb(255, 200, 70),
	Cards = {
		{"Cappuccina Principessa", 50},
		{"Gattino Smeraldino", 35},
		{"Ranapesce Gigante", 14.5},
		{"Gorillo Avocadillo", 0.5},
	},
	Offers = {
		{Id = "Limited1", Packs = 1, Price = 80, ProductId = 3715667623},
		{Id = "Limited5", Packs = 5, Price = 450, ProductId = 3715668038},
		{Id = "Limited10", Packs = 10, Price = 699, OldPrice = 800, ProductId = 3715668208},
	},
}
function GameConfig.getLimitedOffer(id)
	for _, offer in ipairs(GameConfig.LIMITED_PACK.Offers) do
		if offer.Id == id then
			return offer
		end
	end
	return nil
end

-- ============================================================
-- GAME PASS (achetés une seule fois, gardés à vie)
-- GamePassId : l'ID du Game Pass (Creator Dashboard > Monétisation > Passes).
-- Tant qu'il vaut 0 : GRATUIT dans Roblox Studio (pour tester), désactivé en jeu.
-- ============================================================
GameConfig.GAMEPASSES = {
	DoubleCash = {Name = "Argent x2", Price = 30, GamePassId = 1999701304, Multiplier = 2, Description = "Tout ton argent x2, pour toujours !"},
	-- Speed : vitesse en vol (un joueur marche à 16)
	FlyingCarpet = {Name = "Tapis volant", Price = 349, GamePassId = 1999581355, Speed = 42, Description = "Vole partout, 2,5x plus vite !"},
	-- Collecte auto : l'argent des brainrots de ta base arrive tout seul (plus besoin des boutons COLLECTER)
	AutoCollect = {Name = "Collecte auto", Price = 149, GamePassId = 1998495358, Description = "L'argent de ta base arrive tout seul !"},
	-- VIP : tag VIP au-dessus de la tête + [VIP] et message en vert dans le chat,
	-- + tapis volant + argent x2 + collecte auto + 1 minerai de diamant + 1 minerai de netherite (le tout en un seul achat)
	VIP = {Name = "Pack VIP", Price = 499, GamePassId = 1998357389, Description = "Le pack ultime !"},
}

GameConfig.PRODUCTS = {
	LuckPotion = {Name = "Potion Chance x2", Price = 50, ProductId = 3715325414, Minutes = 15},
	Spin1 = {Name = "1 tour de roue", Price = 40, ProductId = 3715325519, Spins = 1},
	Spin3 = {Name = "3 tours de roue", Price = 100, ProductId = 3715325631, Spins = 3},
	Spin10 = {Name = "10 tours de roue", Price = 299, ProductId = 3715325687, Spins = 10},
	MineralDiamant = {Name = "Minerai de Diamant", Price = 149, ProductId = 3715325741, Mineral = "Diamant"},
	MineralNetherite = {Name = "Minerai de Netherite", Price = 299, ProductId = 3715325805, Mineral = "Netherite"},
}

-- Les chances de chaque case de la roue, en texte (obligatoire chez Roblox : les objets aléatoires
-- payants doivent montrer leurs chances AVANT l'achat)
function GameConfig.getWheelOddsText()
	local total = 0
	for _, prize in ipairs(GameConfig.WHEEL.Prizes) do
		total += prize.Weight
	end
	local parts = {}
	for _, prize in ipairs(GameConfig.WHEEL.Prizes) do
		local percent = math.floor(prize.Weight / total * 1000 + 0.5) / 10
		table.insert(parts, prize.Name .. " " .. string.gsub(tostring(percent), "%.0$", "") .. " %")
	end
	return "Chances : " .. table.concat(parts, "  •  ")
end

-- Ce que vaut le Pack VIP si on achète tout séparément (affiché barré dans le shop)
function GameConfig.getVipValue()
	local passes, products = GameConfig.GAMEPASSES, GameConfig.PRODUCTS
	return passes.FlyingCarpet.Price + passes.DoubleCash.Price + passes.AutoCollect.Price + products.MineralDiamant.Price + products.MineralNetherite.Price
end
-- PORTAIL MYSTÈRE : compte à rebours au-dessus du portail jusqu'à cette heure (temps Unix, en UTC).
-- 1790838000 = jeudi 1er octobre 2026 à 07:00 UTC (9 h du matin en France).
-- Pour changer : https://www.epochconverter.com (ou demande-moi).
GameConfig.PORTAL_OPENS_AT = 1790838000
GameConfig.PORTAL_FORCE_OPEN = false -- true : le portail est ouvert tout de suite (pour tester)

-- Le guide des débutants (bannière en haut) disparaît pour toujours après ce temps de jeu total
GameConfig.GUIDE_MINUTES = 5
GameConfig.LUCK_POTION_MULTIPLIER = 2 -- toutes les raretés au-dessus de Commun deviennent 2x plus probables

-- ============================================================
-- ROUE DE LA FORTUNE (1 tour gratuit toutes les 24h)
-- Weight : plus c'est rare, plus c'est bas
-- ============================================================
-- Icônes de la roue : importe assets/icons/roue.png (Gestionnaire de ressources > Images)
-- et colle son ID ici. Tant que c'est vide, la roue affiche des emojis.
-- L'image = 3 colonnes x 2 lignes de 256 px ; IconIndex = la case (1 à 6, de gauche à droite puis ligne 2).
GameConfig.WHEEL_ICONS = "rbxassetid://114385988045707"
GameConfig.WHEEL_ICON_LAYOUT = {Columns = 3, Size = 256}

GameConfig.WHEEL = {
	FreeCooldown = 24 * 60 * 60,
	Prizes = {
		{Id = "Cash", Name = "Argent", Icon = "💰", IconIndex = 1, Weight = 32, Color = rgb(80, 210, 90), IncomeSeconds = 120, Min = 1000},
		{Id = "BigCash", Name = "Jackpot", Icon = "💎", IconIndex = 2, Weight = 20, Color = rgb(40, 160, 255), IncomeSeconds = 600, Min = 10000},
		{Id = "Epic", Name = "Brainrot Épique", Icon = "🃏", IconIndex = 3, Weight = 22, Color = rgb(190, 95, 255), Rarity = "Épique"},
		{Id = "Legendary", Name = "Brainrot Légendaire", Icon = "🌟", IconIndex = 4, Weight = 14, Color = rgb(255, 180, 30), Rarity = "Légendaire"},
		{Id = "Potion", Name = "Chance x2", Icon = "🍀", IconIndex = 5, Weight = 9, Color = rgb(60, 220, 160), Minutes = 15},
		{Id = "BoosterGalaxie", Name = "Booster Galaxie", Icon = "👑", IconIndex = 6, Weight = 3, Color = rgb(255, 60, 150)},
	},
}

-- ============================================================
-- SONS : tous les bruitages sont dans UN SEUL fichier audio : assets/sounds/sons.ogg
-- Importe-le dans Studio (Gestionnaire de ressources > Audio) et colle son ID dans SOUND_FILE.
-- Tant que SOUND_FILE est vide, le jeu utilise des sons de base de Roblox (Fallback) : moins beaux, mais pas de silence.
-- Start / Length : où se trouve chaque son dans le fichier (en secondes).
-- Tu peux aussi donner à un son son propre fichier : Id = "rbxassetid://..." (il remplace la case du fichier).
-- ============================================================
GameConfig.SOUND_FILE = "rbxassetid://139895760862780"
GameConfig.SOUNDS = {
	Swing = {Start = 0, Length = 0.22, Volume = 0.15, Pitch = 1, Fallback = "rbxasset://sounds/swordslash.wav"}, -- coup de pioche dans le vide
	Hit = {Start = 1.5, Length = 0.14, Volume = 0.45, Pitch = 1, Fallback = "rbxasset://sounds/collide.wav"}, -- la pioche tape le bloc
	Break = {Start = 3, Length = 0.45, Volume = 0.6, Pitch = 1, Fallback = "rbxasset://sounds/action_jump_land.mp3", FallbackPitch = 1.35, FallbackVolume = 0.9}, -- le bloc casse
	OreBreak = {Start = 4.5, Length = 0.8, Volume = 0.55, Pitch = 1, Fallback = "rbxasset://sounds/action_jump_land.mp3", FallbackPitch = 1.1, FallbackVolume = 0.9}, -- bloc avec un brainrot
	Card = {Start = 6, Length = 0.7, Volume = 0.5, Pitch = 1, Fallback = "rbxasset://sounds/electronicpingshort.wav"}, -- carte trouvée
	RareCard = {Start = 7.5, Length = 1.4, Volume = 0.55, Pitch = 1, Fallback = "rbxasset://sounds/electronicpingshort.wav"}, -- carte rare trouvée
	Coin = {Start = 9, Length = 0.5, Volume = 0.35, Pitch = 1, Fallback = "rbxasset://sounds/electronicpingshort.wav"}, -- argent collecté
	Tick = {Start = 10.5, Length = 0.05, Volume = 0.4, Pitch = 1, Fallback = "rbxasset://sounds/clickfast.wav"}, -- cliquet de la roue
	Win = {Start = 12, Length = 1.4, Volume = 0.55, Pitch = 1, Fallback = "rbxasset://sounds/electronicpingshort.wav"}, -- gain à la roue
	BatHit = {Start = 13.5, Length = 0.35, Volume = 0.6, Pitch = 1, Fallback = "rbxasset://sounds/swordlunge.wav"}, -- coup de batte
	Click = {Start = 15, Length = 0.06, Volume = 0.3, Pitch = 1, Fallback = "rbxasset://sounds/button.wav"}, -- bouton
	Alarm = {Start = 16.5, Length = 2, Volume = 0.5, Pitch = 1, Fallback = "rbxasset://sounds/electronicpingshort.wav"}, -- alarme : on te vole un brainrot !
	Grapple = {Start = 18.6, Length = 0.45, Volume = 0.5, Pitch = 1, Fallback = "rbxasset://sounds/unsheath.wav"}, -- grappin
}

-- ============================================================
-- MINERAIS : on les trouve dans les COFFRES de la mine et dans les récompenses quotidiennes.
-- On donne un minerai à un brainrot : il gagne plus d'argent POUR TOUJOURS (Boost = +x %).
-- Un brainrot n'a qu'un minerai : on ne peut que le remplacer par un meilleur.
-- ChestWeight : chance de le trouver dans un coffre de la mine.
-- ============================================================
GameConfig.MINERALS = {
	{Id = "Argent", Name = "Argent", Boost = 0.25, Color = rgb(215, 225, 240), ChestWeight = 56},
	{Id = "Or", Name = "Or", Boost = 0.5, Color = rgb(255, 200, 50), ChestWeight = 30},
	{Id = "Emeraude", Name = "Émeraude", Boost = 0.8, Color = rgb(60, 225, 110), ChestWeight = 11},
	{Id = "Diamant", Name = "Diamant", Boost = 1.2, Color = rgb(90, 230, 255), ChestWeight = 2.7},
	{Id = "Netherite", Name = "Netherite", Boost = 2, Color = rgb(120, 85, 110), ChestWeight = 0.3},
}

function GameConfig.getMineral(id)
	for index, mineral in ipairs(GameConfig.MINERALS) do
		if mineral.Id == id then
			return mineral, index
		end
	end
	return nil, 0
end

-- Multiplicateur d'argent d'un brainrot avec son minerai (1 s'il n'en a pas)
function GameConfig.getMineralMultiplier(id)
	local mineral = GameConfig.getMineral(id)
	return mineral and (1 + mineral.Boost) or 1
end

-- ============================================================
-- RÉCOMPENSES QUOTIDIENNES : un pop-up s'ouvre quand on arrive dans le jeu (et le bouton 🎁 Cadeaux)
-- Une récompense toutes les 24 h. Si tu attends plus de 48 h, la série repart au jour 1.
-- Après le jour 7, on recommence au jour 1.
-- ============================================================
GameConfig.DAILY = {
	Cooldown = 24 * 60 * 60,
	StreakExpire = 48 * 60 * 60,
	Rewards = {
		{Name = "Argent", Icon = "💰", Color = rgb(80, 210, 90), IncomeSeconds = 300, Min = 5000},
		{Name = "2 tours de roue", Icon = "🎡", Color = rgb(255, 120, 60), Spins = 2},
		{Name = "Minerai d'argent", Icon = "🥈", Color = rgb(200, 210, 230), Mineral = "Argent"},
		{Name = "Potion Chance x2 (20 min)", Icon = "🍀", Color = rgb(60, 220, 160), Potion = 20},
		{Name = "Minerai d'or", Icon = "🥇", Color = rgb(255, 200, 50), Mineral = "Or"},
		{Name = "Brainrot Légendaire", Icon = "🌟", Color = rgb(255, 170, 30), Rarity = "Légendaire"},
		{Name = "MINERAI DE DIAMANT", Icon = "💎", Color = rgb(90, 230, 255), Mineral = "Diamant"},
	},
}

-- ============================================================
-- RÉCOMPENSE DE DÉPART (le coffre doré à côté de la roue, une seule fois par joueur)
-- Pour l'ouvrir : mettre le jeu en FAVORI et mettre un LIKE.
-- ============================================================
GameConfig.STARTER = {
	Cash = 15000,
	Rarity = "Très Rare", -- une carte Très Rare au hasard
	ZoneRadius = 7, -- la zone jaune au sol : on marche dedans pour ouvrir le menu
}

-- Quel jour (1 à 7) le joueur peut récupérer, et dans combien de secondes (0 = maintenant)
function GameConfig.getDailyState(streak, last, now)
	streak = streak or 0
	last = last or 0
	if last > 0 and now - last >= GameConfig.DAILY.StreakExpire then
		streak = 0 -- série perdue
	end
	local wait = math.max(0, (last + GameConfig.DAILY.Cooldown) - now)
	if last == 0 then
		wait = 0
	end
	return (streak % #GameConfig.DAILY.Rewards) + 1, wait, streak
end

-- ============================================================
-- MUSIQUE DE FOND : importe assets/sounds/musique.ogg (Gestionnaire de ressources > Audio)
-- et colle son ID ici. On peut la couper dans les ⚙️ Paramètres.
-- ============================================================
GameConfig.MUSIC_FILE = "rbxassetid://103268961782042"
GameConfig.MUSIC_VOLUME = 0.25

-- Paramètres du joueur (bouton ⚙️ en haut à droite), sauvegardés
GameConfig.SETTINGS = {
	Music = true, -- musique de fond
	LowGraphics = false, -- graphismes allégés (moins d'effets, pour les petits PC / téléphones)
	FriendsCanEnter = false, -- mes amis peuvent passer mes lasers
}

-- Gains hors-ligne : quand tu reviens, ta base t'a rapporté une partie de son argent pendant ton absence
GameConfig.OFFLINE = {
	Rate = 0.25, -- 25 % de l'argent par seconde de ta base
	MaxHours = 3, -- au maximum 3 heures
	MinSeconds = 120, -- il faut être parti au moins 2 minutes
}


-- ============================================================
-- CLASSEMENTS (les 2 grands panneaux entre la mine et la roue) : top 10 de TOUS les serveurs
-- ============================================================
GameConfig.LEADERBOARDS = {
	{Id = "Cash", Title = "💰 LES PLUS RICHES", Unit = "", Position = Vector3.new(118, 0, -46), Color = rgb(255, 200, 60), Store = "BrainrotTopCash_v1"},
	{Id = "Income", Title = "⚡ MEILLEURE BASE", Unit = "/s", Position = Vector3.new(118, 0, 46), Color = rgb(80, 230, 255), Store = "BrainrotTopIncome_v1"},
}
GameConfig.LEADERBOARD_REFRESH = 60 -- secondes entre deux mises à jour

-- ============================================================
-- ADMINS (commandes dans le chat : /all, /give, /cash, /rebirths, /pickaxe, /mutation, /spins, /potion)
-- Dans Roblox Studio, tout le monde est admin pour tester.
-- ============================================================
GameConfig.ADMINS = {806753726} -- ridaadam34

-- Version du jeu (affichée en bas à droite de l'écran) : pratique pour vérifier que Studio a bien le dernier code
GameConfig.VERSION = "v23.1 - minage dans le monde 2"

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
	local c = GameConfig.getCard(cardName) or GameConfig.getComingSoon(cardName)
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

function GameConfig.getLayer(layerIndex, world)
	local layers = GameConfig[GameConfig.getWorld(world or 1).Layers or "LAYERS"] or GameConfig.LAYERS
	for _, layer in ipairs(layers) do
		if layerIndex >= layer.From and layerIndex <= layer.To then
			return layer
		end
	end
	return layers[#layers]
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
	-- Game Pass "Argent x2" (compris dans le VIP)
	if player:GetAttribute("DoubleCash") == true or player:GetAttribute("VIP") == true then
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

-- ============================================================
-- MACHINE DE FUSION : 3 brainrots -> 1 brainrot FUSIONNÉ qui rapporte la somme des 3 + 10 %
-- (la carte gardée est la meilleure des 3, avec son nom, sa mutation et son numéro)
-- ============================================================
GameConfig.FUSION = {
	Cards = 3, -- nombre de cartes à mettre dans la machine
	Bonus = 0.10, -- +10 % d'argent en plus
	MaxDistance = 30, -- il faut être à côté de la machine (en studs, depuis son centre)
	Position = Vector3.new(-112, 0, 42), -- à l'ouest de la mine, entre la boutique et les bases
}

-- Infos de fusion d'un objet (StringValue du sac, Part d'une carte...) : nil ou {Income, Level}
function GameConfig.getFusion(object)
	local level = object:GetAttribute("FusionLevel")
	local income = object:GetAttribute("FusionIncome")
	if type(level) == "number" and level > 0 and type(income) == "number" then
		return {Income = income, Level = level}
	end
	return nil
end

-- Revenu d'un objet SANS le minerai (carte fusionnée comprise)
function GameConfig.getItemBaseIncome(item)
	local fusion = GameConfig.getFusion(item)
	if fusion then
		return fusion.Income
	end
	return GameConfig.getItemIncome(item.Value, item:GetAttribute("Mutation"))
end

-- Revenu réel d'un objet par seconde (fusion + minerai compris)
function GameConfig.getItemValue(item)
	return GameConfig.getItemBaseIncome(item) * GameConfig.getMineralMultiplier(item:GetAttribute("Mineral"))
end

function GameConfig.getItemSellPrice(item)
	return math.floor(GameConfig.getItemBaseIncome(item) * GameConfig.SELL_SECONDS)
end

-- Ce que donnent ces cartes dans la machine : revenu, niveau de fusion, et la carte gardée (la meilleure)
function GameConfig.getFusionResult(items)
	local total, level, best = 0, 0, nil
	for _, item in ipairs(items) do
		local value = GameConfig.getItemValue(item)
		total += value
		local fusion = GameConfig.getFusion(item)
		level = math.max(level, fusion and fusion.Level or 0)
		if not best or GameConfig.compareItems(item, best) then
			best = item
		end
	end
	return math.floor(total * (1 + GameConfig.FUSION.Bonus)), level + 1, best
end

-- Tri des cartes : la rareté la plus haute d'abord, puis celle qui rapporte le plus
function GameConfig.compareItems(a, b)
	local cardA, cardB = GameConfig.getCard(a.Value), GameConfig.getCard(b.Value)
	local orderA = cardA and GameConfig.RARITIES[cardA.Rarity].Order or 0
	local orderB = cardB and GameConfig.RARITIES[cardB.Rarity].Order or 0
	if orderA ~= orderB then
		return orderA > orderB
	end
	local valueA, valueB = GameConfig.getItemValue(a), GameConfig.getItemValue(b)
	if valueA ~= valueB then
		return valueA > valueB
	end
	return a.Name < b.Name
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
