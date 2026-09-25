-- ModuleScript partagé entre le serveur et le client.
-- Toutes les valeurs d'équilibrage du jeu sont ici : modifie-les à un seul endroit.

local GameConfig = {}

-- ====== RARETES ======
GameConfig.RARITIES = {
	["Commune"] = {Order = 1, Color = Color3.fromRGB(200, 200, 200)},
	["Rare"] = {Order = 2, Color = Color3.fromRGB(60, 140, 255)},
	["Épique"] = {Order = 3, Color = Color3.fromRGB(170, 70, 255)},
	["Légendaire"] = {Order = 4, Color = Color3.fromRGB(255, 170, 0)},
	["Mythique"] = {Order = 5, Color = Color3.fromRGB(255, 50, 50)},
	["Secret"] = {Order = 6, Color = Color3.fromRGB(20, 20, 20)},
}

-- ====== PIOCHES ======
-- Damage : dégâts par coup sur un bloc
-- Cooldown : temps (secondes) entre deux coups
-- Cost : prix en Cash
-- RequiredRebirths : nombre de rebirths nécessaires pour pouvoir l'acheter
-- HeadColor : couleur de la tête de la pioche (style Minecraft)
GameConfig.PICKAXES = {
	{Name = "Pioche en Bois", Damage = 1, Cooldown = 0.3, Cost = 0, RequiredRebirths = 0, HeadColor = Color3.fromRGB(160, 120, 70)},
	{Name = "Pioche en Pierre", Damage = 3, Cooldown = 0.27, Cost = 250, RequiredRebirths = 1, HeadColor = Color3.fromRGB(140, 140, 140)},
	{Name = "Pioche en Fer", Damage = 8, Cooldown = 0.24, Cost = 1000, RequiredRebirths = 2, HeadColor = Color3.fromRGB(230, 230, 230)},
	{Name = "Pioche en Or", Damage = 20, Cooldown = 0.2, Cost = 5000, RequiredRebirths = 3, HeadColor = Color3.fromRGB(255, 215, 40)},
	{Name = "Pioche en Diamant", Damage = 50, Cooldown = 0.16, Cost = 20000, RequiredRebirths = 4, HeadColor = Color3.fromRGB(70, 230, 220)},
}

-- ====== CARTES BRAINROT ======
-- Income : Cash rapporté par seconde par carte
-- Weight : chance relative d'apparition (plus c'est haut, plus c'est commun)
-- Color : couleur du minerai et de la carte
GameConfig.CARDS = {
	{Name = "Tralalero Tralala", Rarity = "Commune", Income = 1, Weight = 40, Color = Color3.fromRGB(40, 120, 220)},
	{Name = "Lirilì Larilà", Rarity = "Commune", Income = 2, Weight = 30, Color = Color3.fromRGB(90, 170, 80)},
	{Name = "Boneca Ambalabu", Rarity = "Rare", Income = 4, Weight = 18, Color = Color3.fromRGB(60, 200, 90)},
	{Name = "Bombardiro Crocodilo", Rarity = "Rare", Income = 6, Weight = 14, Color = Color3.fromRGB(60, 130, 50)},
	{Name = "Tung Tung Tung Sahur", Rarity = "Épique", Income = 12, Weight = 9, Color = Color3.fromRGB(170, 120, 70)},
	{Name = "Cappuccino Assassino", Rarity = "Épique", Income = 18, Weight = 6, Color = Color3.fromRGB(120, 80, 50)},
	{Name = "Brr Brr Patapim", Rarity = "Légendaire", Income = 40, Weight = 3, Color = Color3.fromRGB(40, 150, 40)},
	{Name = "Ballerina Cappuccina", Rarity = "Légendaire", Income = 60, Weight = 2, Color = Color3.fromRGB(255, 130, 200)},
	{Name = "Chimpanzini Bananini", Rarity = "Mythique", Income = 150, Weight = 0.7, Color = Color3.fromRGB(255, 220, 40)},
	{Name = "La Vaca Saturno Saturnita", Rarity = "Secret", Income = 500, Weight = 0.15, Color = Color3.fromRGB(230, 150, 60)},
}

-- ====== REBIRTH ======
GameConfig.REBIRTH_COST = 1000
GameConfig.REBIRTH_CARD_REQUIRED = "Tung Tung Tung Sahur"
GameConfig.REBIRTH_INCOME_MULT_BONUS = 0.5 -- +50% de revenu par rebirth

-- ====== MINE ======
-- La mine est un grand trou rempli de blocs (comme Minecraft).
-- Plus tu creuses profond, plus les blocs sont durs... mais plus tu as de chances d'avoir des cartes rares.
GameConfig.MINE = {
	Center = Vector3.new(0, 0, 0), -- centre du dessus de la mine (le sol est à Y = 0)
	BlockSize = 4,
	Grid = 14, -- 14 x 14 blocs de large
	Depth = 30, -- 30 couches de profondeur
	MineRange = 14, -- distance max pour miner un bloc
	ResetInterval = 480, -- la mine se régénère toutes les 8 minutes
	OreChanceBase = 0.10, -- 10% de minerai brainrot en surface...
	OreChancePerLayer = 0.006, -- ... +0.6% par couche
	LuckPerLayer = 0.08, -- bonus de chance pour les cartes rares par couche
}

-- Couches de la mine (du haut vers le bas)
-- MinTier : niveau de pioche minimum pour casser ce bloc
GameConfig.LAYERS = {
	{From = 1, To = 1, Name = "Herbe", Material = Enum.Material.Grass, Color = Color3.fromRGB(90, 170, 60), HP = 2, Cash = 1, MinTier = 1},
	{From = 2, To = 4, Name = "Terre", Material = Enum.Material.Ground, Color = Color3.fromRGB(125, 90, 60), HP = 2, Cash = 1, MinTier = 1},
	{From = 5, To = 10, Name = "Pierre", Material = Enum.Material.Slate, Color = Color3.fromRGB(125, 125, 125), HP = 5, Cash = 3, MinTier = 1},
	{From = 11, To = 17, Name = "Roche profonde", Material = Enum.Material.Basalt, Color = Color3.fromRGB(70, 70, 80), HP = 12, Cash = 8, MinTier = 2},
	{From = 18, To = 24, Name = "Magma", Material = Enum.Material.CrackedLava, Color = Color3.fromRGB(110, 45, 30), HP = 30, Cash = 20, MinTier = 3},
	{From = 25, To = 30, Name = "Obsidienne", Material = Enum.Material.Slate, Color = Color3.fromRGB(45, 25, 70), HP = 70, Cash = 50, MinTier = 4},
}

-- ====== BASES ======
GameConfig.BASE = {
	PlotCount = 8,
	CleanTemplate = true, -- supprime la Baseplate et le SpawnLocation du template Roblox (ils gênent la mine)
}

function GameConfig.getCard(name)
	for _, card in ipairs(GameConfig.CARDS) do
		if card.Name == name then
			return card
		end
	end
	return nil
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

return GameConfig
