-- ModuleScript : RÉCOMPENSES QUOTIDIENNES + CADEAU DE DÉPART + MINERAIS.
--   - Récompenses quotidiennes : un pop-up s'ouvre quand on arrive (voir Daily.lua côté client).
--     Une récompense toutes les 24 h, 7 jours d'affilée (jour 7 = minerai de diamant).
--     Si on attend plus de 48 h, la série repart au jour 1.
--   - CADEAU DE DÉPART (une seule fois, au coffre doré : voir StarterChest.lua) : une carte Très Rare
--     + de l'argent, pour ceux qui mettent le jeu en favori et un like.
--   - Les minerais se donnent à un brainrot : il gagne plus d'argent pour toujours.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local DailyManager = {}

local deps

-- ============================================================
-- RÉCOMPENSES
-- ============================================================
local function grant(player, reward)
	local details = {}
	if reward.IncomeSeconds then
		local income = player:GetAttribute("Income") or 0
		local amount = math.floor(math.max(reward.Min or 0, income * reward.IncomeSeconds))
		player.leaderstats.Cash.Value += amount
		details.Cash = amount
	elseif reward.Spins then
		player.Spins.Value += reward.Spins
		details.Spins = reward.Spins
	elseif reward.Potion then
		deps.PlayerData.addLuckMinutes(player, reward.Potion)
		details.Minutes = reward.Potion
	elseif reward.Mineral then
		deps.PlayerData.addMineral(player, reward.Mineral, 1)
		details.Mineral = reward.Mineral
	elseif reward.Rarity then
		local cardName = deps.Loot.rollCardOfRarity(reward.Rarity)
		local mutation = deps.Loot.rollMutation()
		local item = deps.PlayerData.addItem(player, cardName, mutation, 0, nil, "a reçu en cadeau")
		details.Card = cardName
		details.Mutation = mutation
		details.Serial = item and item:GetAttribute("Serial") or 0
	end
	return details
end

function DailyManager.claim(player)
	local now = os.time()
	local day, wait, streak = GameConfig.getDailyState(player:GetAttribute("DailyStreak"), player:GetAttribute("DailyLast"), now)
	if wait > 0 then
		deps.Remotes.notify(player, "Prochaine récompense dans " .. GameConfig.formatTime(wait), "error")
		return
	end
	local reward = GameConfig.DAILY.Rewards[day]
	player:SetAttribute("DailyStreak", streak + 1)
	player:SetAttribute("DailyLast", now)
	local details = grant(player, reward)
	deps.Remotes.DailyResult:FireClient(player, day, details)
	if details.Mineral then
		deps.Remotes.MineralFound:FireClient(player, details.Mineral, "daily")
	end
	task.spawn(deps.PlayerData.save, player)
end

-- ============================================================
-- CADEAU DE DÉPART (une seule fois) : il faut avoir mis le jeu en favori et un like
-- (le client vérifie le favori avec Roblox ; le like, Roblox ne permet pas de le vérifier)
-- ============================================================
function DailyManager.claimStarter(player, favorited, liked)
	if player:GetAttribute("StarterClaimed") then
		deps.Remotes.notify(player, "Tu as déjà ouvert ton cadeau de départ !", "info")
		return
	end
	if deps.StarterChest and not deps.StarterChest.isNear(player) then
		deps.Remotes.notify(player, "Va au COFFRE DORÉ à côté de la roue", "error")
		return
	end
	if favorited ~= true or liked ~= true then
		deps.Remotes.notify(player, "Mets le jeu en favori ⭐ et un like 👍 pour ouvrir le coffre !", "error")
		return
	end
	local config = GameConfig.STARTER
	player:SetAttribute("StarterClaimed", true)
	player.leaderstats.Cash.Value += config.Cash
	local cardName = deps.Loot.rollCardOfRarity(config.Rarity)
	local mutation = deps.Loot.rollMutation()
	local item = deps.PlayerData.addItem(player, cardName, mutation, 0, nil, "a ouvert son cadeau de départ")
	deps.Remotes.DailyResult:FireClient(player, 0, {
		Cash = config.Cash,
		Card = cardName,
		Mutation = mutation,
		Serial = item and item:GetAttribute("Serial") or 0,
	})
	task.spawn(deps.PlayerData.save, player)
end

-- ============================================================
-- DONNER UN MINERAI À UN BRAINROT
-- ============================================================
function DailyManager.applyMineral(player, itemId, mineralId)
	if typeof(itemId) ~= "string" or typeof(mineralId) ~= "string" then return end
	local mineral, rank = GameConfig.getMineral(mineralId)
	local item = deps.PlayerData.findItem(player, itemId)
	if not mineral or not item then return end
	if (item:GetAttribute("Slot") or 0) < 0 or item:GetAttribute("StolenBy") or item:GetAttribute("OnGround") then
		deps.Remotes.notify(player, "Impossible : ce brainrot est en train d'être volé !", "error")
		return
	end
	if deps.PlayerData.getMineralCount(player, mineral.Id) < 1 then
		deps.Remotes.notify(player, "Tu n'as pas de minerai " .. mineral.Name, "error")
		return
	end
	local _, currentRank = GameConfig.getMineral(item:GetAttribute("Mineral"))
	if currentRank >= rank then
		deps.Remotes.notify(player, item.Value .. " a déjà un minerai aussi fort (ou plus fort)", "error")
		return
	end
	deps.PlayerData.addMineral(player, mineral.Id, -1)
	item:SetAttribute("Mineral", mineral.Id)
	deps.BaseManager.refresh(player)
	deps.Remotes.notify(player, "◆ " .. item.Value .. " + " .. mineral.Name .. " : +" .. math.floor(mineral.Boost * 100) .. " % d'argent pour toujours !", "success")
	task.spawn(deps.PlayerData.save, player)
end

function DailyManager.init(dependencies)
	deps = dependencies
	deps.Remotes.ClaimDaily.OnServerEvent:Connect(DailyManager.claim)
	deps.Remotes.ClaimStarter.OnServerEvent:Connect(DailyManager.claimStarter)
	deps.Remotes.ApplyMineral.OnServerEvent:Connect(DailyManager.applyMineral)
end

return DailyManager
