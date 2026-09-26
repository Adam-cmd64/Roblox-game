-- ModuleScript : achats Robux (boosters, potion de chance, tours de roue).
--
-- Pour activer un produit en vrai :
--   1. Creator Dashboard > ton jeu > Monétisation > Produits développeur > Créer (ex : "Booster Commun", 149 Robux)
--   2. Copie l'ID du produit dans GameConfig (ProductId = ...) : BOOSTERS et PRODUCTS
-- Tant que ProductId vaut 0 : gratuit dans Studio (pour tester), désactivé en jeu.

local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Monetization = {}

local deps

local function getBooster(id)
	for _, booster in ipairs(GameConfig.BOOSTERS) do
		if booster.Id == id then
			return booster
		end
	end
	return nil
end

-- Ce que donne chaque achat
local function grantBooster(player, booster)
	local results = deps.Loot.rollBooster(booster)
	for _, result in ipairs(results) do
		local item = deps.PlayerData.addItem(player, result.Name, result.Mutation, 0)
		result.Serial = item and item:GetAttribute("Serial") or 0
	end
	deps.Remotes.BoosterOpened:FireClient(player, booster.Id, results)
	task.spawn(deps.PlayerData.save, player)
end

local function grantProduct(player, key)
	local product = GameConfig.PRODUCTS[key]
	if product.Minutes then
		deps.PlayerData.addLuckMinutes(player, product.Minutes)
		deps.Remotes.notify(player, "Potion Chance x2 activée pour " .. product.Minutes .. " minutes !", "success")
	elseif product.Spins then
		deps.WheelManager.addSpins(player, product.Spins)
		deps.Remotes.notify(player, "+" .. product.Spins .. " tour(s) de roue !", "success")
	end
	task.spawn(deps.PlayerData.save, player)
end

-- Achat : vrai produit Robux, ou gratuit en test dans Studio
local function purchase(player, productId, onGrant)
	if productId ~= 0 then
		MarketplaceService:PromptProductPurchase(player, productId)
	elseif RunService:IsStudio() then
		deps.Remotes.notify(player, "Mode test Studio : offert", "info")
		onGrant()
	else
		deps.Remotes.notify(player, "Bientôt disponible !", "info")
	end
end

function Monetization.init(dependencies)
	deps = dependencies

	deps.Remotes.BuyBooster.OnServerEvent:Connect(function(player, boosterId)
		local booster = getBooster(boosterId)
		if not booster then return end
		purchase(player, booster.ProductId, function()
			grantBooster(player, booster)
		end)
	end)

	deps.Remotes.BuyProduct.OnServerEvent:Connect(function(player, key)
		local product = typeof(key) == "string" and GameConfig.PRODUCTS[key]
		if not product then return end
		purchase(player, product.ProductId, function()
			grantProduct(player, key)
		end)
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		for _, booster in ipairs(GameConfig.BOOSTERS) do
			if booster.ProductId ~= 0 and booster.ProductId == receipt.ProductId then
				grantBooster(player, booster)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		for key, product in pairs(GameConfig.PRODUCTS) do
			if product.ProductId ~= 0 and product.ProductId == receipt.ProductId then
				grantProduct(player, key)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return Monetization
