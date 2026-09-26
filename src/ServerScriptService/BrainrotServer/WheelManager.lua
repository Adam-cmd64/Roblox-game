-- ModuleScript : la roue de la fortune.
-- 1 tour gratuit toutes les 24h + des tours achetables en Robux (voir Monetization).
-- 6 cases : argent, jackpot, brainrot Épique, brainrot Légendaire, potion de chance, Booster OG.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local WheelManager = {}

local deps
local spinning = {}

-- Revenu par seconde actuel du joueur (brainrots posés)
local function getIncome(player)
	local total = 0
	for _, item in ipairs(deps.PlayerData.getItems(player)) do
		if (item:GetAttribute("Slot") or 0) > 0 then
			total += GameConfig.getItemIncome(item.Value, item:GetAttribute("Mutation"))
		end
	end
	return total * GameConfig.getPlayerMultiplier(player)
end

local function grant(player, prize)
	local details = {}
	if prize.IncomeSeconds then
		local amount = math.floor(math.max(prize.Min, getIncome(player) * prize.IncomeSeconds))
		player.leaderstats.Cash.Value += amount
		details.Cash = amount
	elseif prize.Rarity then
		local cardName = deps.Loot.rollCardOfRarity(prize.Rarity)
		local mutation = deps.Loot.rollMutation()
		deps.PlayerData.addItem(player, cardName, mutation, 0)
		details.Card = cardName
		details.Mutation = mutation
	elseif prize.Minutes then
		deps.PlayerData.addLuckMinutes(player, prize.Minutes)
		details.Minutes = prize.Minutes
	elseif prize.Id == "BoosterOG" then
		local booster
		for _, b in ipairs(GameConfig.BOOSTERS) do
			if b.Id == "OG" then
				booster = b
			end
		end
		local cards = deps.Loot.rollBooster(booster)
		for _, result in ipairs(cards) do
			deps.PlayerData.addItem(player, result.Name, result.Mutation, 0)
		end
		details.Booster = "OG"
		details.Cards = cards
	end
	return details
end

local function onSpin(player)
	if spinning[player] then return end
	local now = os.time()
	local lastFree = player:GetAttribute("LastFreeSpin") or 0
	if now - lastFree >= GameConfig.WHEEL.FreeCooldown then
		player:SetAttribute("LastFreeSpin", now)
	elseif player.Spins.Value > 0 then
		player.Spins.Value -= 1
	else
		deps.Remotes.notify(player, "Plus de tours ! Reviens plus tard ou achète des tours", "error")
		return
	end

	spinning[player] = true
	local index = deps.Loot.rollWheel()
	local prize = GameConfig.WHEEL.Prizes[index]
	local details = grant(player, prize)
	deps.Remotes.WheelResult:FireClient(player, index, details)
	task.spawn(deps.PlayerData.save, player)
	-- le temps que l'animation se termine
	task.delay(4.5, function()
		spinning[player] = nil
	end)
end

function WheelManager.addSpins(player, amount)
	player.Spins.Value += amount
end

function WheelManager.init(dependencies)
	deps = dependencies
	deps.Remotes.SpinWheel.OnServerEvent:Connect(onSpin)
end

return WheelManager
