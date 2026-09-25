-- ModuleScript partagé entre le serveur et le client.
-- Toutes les valeurs d'équilibrage du jeu sont ici : modifie-les à un seul endroit.

local GameConfig = {}

-- ====== PIOCHES ======
-- Damage : dégâts par coup sur un rocher
-- Cost : prix en Cash
-- RequiredRebirths : nombre de rebirths nécessaires pour pouvoir l'acheter
GameConfig.PICKAXES = {
	{Name = "Pioche en Bois", Damage = 1, Cost = 0, RequiredRebirths = 0, Color = Color3.fromRGB(150, 100, 50)},
	{Name = "Pioche en Pierre", Damage = 3, Cost = 250, RequiredRebirths = 1, Color = Color3.fromRGB(130, 130, 130)},
	{Name = "Pioche en Fer", Damage = 8, Cost = 1000, RequiredRebirths = 2, Color = Color3.fromRGB(220, 220, 220)},
	{Name = "Pioche en Or", Damage = 20, Cost = 5000, RequiredRebirths = 3, Color = Color3.fromRGB(255, 200, 0)},
	{Name = "Pioche en Diamant", Damage = 50, Cost = 20000, RequiredRebirths = 4, Color = Color3.fromRGB(0, 230, 230)},
}

-- ====== CARTES BRAINROT ======
-- Income : Cash rapporté par seconde par carte
-- Weight : chance relative d'apparition (plus c'est haut, plus c'est commun)
GameConfig.CARDS = {
	{Name = "Tralalero Tralala", Rarity = "Commune", Income = 1, Weight = 50, Color = Color3.fromRGB(0, 170, 255), Emoji = "🦈"},
	{Name = "Bombardiro Crocodilo", Rarity = "Rare", Income = 3, Weight = 30, Color = Color3.fromRGB(0, 200, 0), Emoji = "🐊"},
	{Name = "Tung Tung Tung Sahur", Rarity = "Épique", Income = 8, Weight = 15, Color = Color3.fromRGB(150, 75, 0), Emoji = "🪵"},
	{Name = "Brr Brr Patapim", Rarity = "Légendaire", Income = 20, Weight = 4, Color = Color3.fromRGB(255, 0, 200), Emoji = "🌳"},
	{Name = "Chimpanzini Bananini", Rarity = "Mythique", Income = 60, Weight = 1, Color = Color3.fromRGB(255, 215, 0), Emoji = "🍌"},
}

-- ====== REBIRTH ======
GameConfig.REBIRTH_COST = 1000
GameConfig.REBIRTH_CARD_REQUIRED = "Tung Tung Tung Sahur"
GameConfig.REBIRTH_INCOME_MULT_BONUS = 0.5 -- +50% de revenu par rebirth

-- ====== ROCHERS ======
GameConfig.ROCK_MAX_HP = 20
GameConfig.MAX_ROCKS = 10
GameConfig.ROCK_RESPAWN_TIME = 5
GameConfig.MINE_DISTANCE = 15

function GameConfig.getCard(name)
	for _, card in ipairs(GameConfig.CARDS) do
		if card.Name == name then
			return card
		end
	end
	return nil
end

return GameConfig
