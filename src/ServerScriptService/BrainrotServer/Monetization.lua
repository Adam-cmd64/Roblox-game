-- ModuleScript : boutique Robux (boosters de cartes).
--
-- Pour activer un booster en vrai :
--   1. Creator Dashboard > ton jeu > Monétisation > Developer Products > Créer un produit (ex : "Booster Commun", 149 Robux)
--   2. Copie l'ID du produit dans GameConfig.BOOSTERS (ProductId = ...)
-- Tant que ProductId vaut 0, le booster est gratuit dans Studio (pour tester l'animation) et désactivé en jeu.

local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Monetization = {}

local deps

local function getBoosterById(id)
	for _, booster in ipairs(GameConfig.BOOSTERS) do
		if booster.Id == id then
			return booster
		end
	end
	return nil
end

local function getBoosterByProduct(productId)
	for _, booster in ipairs(GameConfig.BOOSTERS) do
		if booster.ProductId ~= 0 and booster.ProductId == productId then
			return booster
		end
	end
	return nil
end

-- Donne les cartes du booster au joueur (dans son inventaire)
local function grantBooster(player, booster)
	local results = deps.Loot.rollBooster(booster)
	for _, result in ipairs(results) do
		deps.PlayerData.addItem(player, result.Name, result.Mutation, 0)
	end
	deps.Remotes.BoosterOpened:FireClient(player, booster.Id, results)
	task.spawn(deps.PlayerData.save, player)
end

function Monetization.init(dependencies)
	deps = dependencies

	deps.Remotes.BuyBooster.OnServerEvent:Connect(function(player, boosterId)
		local booster = getBoosterById(boosterId)
		if not booster then return end

		if booster.ProductId ~= 0 then
			MarketplaceService:PromptProductPurchase(player, booster.ProductId)
		elseif RunService:IsStudio() then
			deps.Remotes.notify(player, "🧪 Mode test Studio : booster offert", "info")
			grantBooster(player, booster)
		else
			deps.Remotes.notify(player, "Ce booster arrive bientôt !", "info")
		end
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local booster = getBoosterByProduct(receipt.ProductId)
		if not booster then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		grantBooster(player, booster)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Monetization
