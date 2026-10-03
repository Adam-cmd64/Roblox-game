-- ModuleScript serveur : 🎁 CADEAUX DE SESSION + 📜 QUÊTES DU JOUR.
--
-- Cadeaux de session (GameConfig.PLAYTIME_GIFTS) : plus on reste connecté, plus on gagne.
--   Attributs du joueur : SessionStart (os.time() de son arrivée), GiftsClaimed (bits : cadeau 1 = 1, cadeau 2 = 2, 3 = 4...).
-- Quêtes du jour (GameConfig.QUESTS) : 3 quêtes qui changent à minuit (UTC) + un bonus si on fait les 3.
--   Attributs : QuestDay, Quest1 / Quest2 / Quest3 (progression), QuestClaimed (bits, 8 = le bonus).
--   Sauvegardés par PlayerData (data.Quests).
-- Les récompenses sont données comme celles du coffre quotidien (DailyManager.grant).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local QUESTS = GameConfig.QUESTS

local RewardsManager = {}

local deps

local function hasBit(mask, index)
	return math.floor((mask or 0) / 2 ^ (index - 1)) % 2 == 1
end
RewardsManager.hasBit = hasBit

local function addBit(mask, index)
	if hasBit(mask, index) then
		return mask
	end
	return (mask or 0) + 2 ^ (index - 1)
end

-- Donne la récompense et l'affiche (carte trouvée, minerai, message)
local function give(player, reward, title)
	local details = deps.DailyManager.grant(player, reward)
	if details.Card then
		deps.Remotes.CardFound:FireClient(player, details.Card, details.Mutation, details.Serial)
	end
	if details.Mineral then
		deps.Remotes.MineralFound:FireClient(player, details.Mineral, "daily")
	end
	local text = reward.Icon .. " " .. title .. " : " .. reward.Name
	if details.Cash then
		text = text .. " (+$" .. GameConfig.format(details.Cash) .. ")"
	end
	deps.Remotes.notify(player, text, "success")
	task.spawn(deps.PlayerData.save, player)
	return details
end

-- ============================================================
-- 🎁 CADEAUX DE SESSION
-- ============================================================
function RewardsManager.claimGift(player, index)
	local gift = typeof(index) == "number" and GameConfig.PLAYTIME_GIFTS[index]
	if not gift then return end
	local mask = player:GetAttribute("GiftsClaimed") or 0
	if hasBit(mask, index) then return end
	local played = os.time() - (player:GetAttribute("SessionStart") or os.time())
	if played < gift.Minutes * 60 then
		deps.Remotes.notify(player, "🎁 Ce cadeau sera prêt dans " .. GameConfig.formatTime(gift.Minutes * 60 - played), "error")
		return
	end
	player:SetAttribute("GiftsClaimed", addBit(mask, index))
	return give(player, gift, "Cadeau")
end

-- ============================================================
-- 📜 QUÊTES DU JOUR
-- ============================================================
-- Nouveau jour : les quêtes repartent à zéro
local function checkDay(player)
	local today = GameConfig.getQuestDay()
	if player:GetAttribute("QuestDay") ~= today then
		player:SetAttribute("QuestDay", today)
		for i = 1, #QUESTS.List do
			player:SetAttribute("Quest" .. i, 0)
		end
		player:SetAttribute("QuestClaimed", 0)
	end
	return today
end
RewardsManager.checkDay = checkDay

-- Le minage fait avancer les quêtes : progress(player, "Mine") / ("Find") / ("Rare", rareté de la carte)
function RewardsManager.progress(player, questId, rarity)
	local today = checkDay(player)
	for i, quest in ipairs(QUESTS.List) do
		if quest.Id == questId then
			local ok = true
			if quest.MinRarity then
				local r = rarity and GameConfig.RARITIES[rarity]
				ok = r ~= nil and r.Order >= GameConfig.RARITIES[quest.MinRarity].Order
			end
			local key = "Quest" .. i
			local current = player:GetAttribute(key) or 0
			local target = GameConfig.getQuestTarget(i, today)
			if ok and current < target then
				player:SetAttribute(key, current + 1)
				if current + 1 == target then
					deps.Remotes.notify(player, "📜 Quête terminée ! Va prendre ta récompense (bouton 🎁)", "success")
				end
			end
		end
	end
end

function RewardsManager.claimQuest(player, index)
	if typeof(index) ~= "number" then return end
	local today = checkDay(player)
	local mask = player:GetAttribute("QuestClaimed") or 0
	local count = #QUESTS.List
	if hasBit(mask, index) then return end
	if index == count + 1 then
		-- le bonus : les 3 quêtes récupérées
		for i = 1, count do
			if not hasBit(mask, i) then
				deps.Remotes.notify(player, "🏆 Termine les 3 quêtes du jour pour le bonus !", "error")
				return
			end
		end
		player:SetAttribute("QuestClaimed", addBit(mask, index))
		return give(player, QUESTS.Bonus, "Bonus des quêtes")
	end
	local quest = QUESTS.List[index]
	if not quest then return end
	if (player:GetAttribute("Quest" .. index) or 0) < GameConfig.getQuestTarget(index, today) then
		deps.Remotes.notify(player, "📜 Cette quête n'est pas encore finie", "error")
		return
	end
	player:SetAttribute("QuestClaimed", addBit(mask, index))
	return give(player, quest.Reward, "Quête")
end

-- À l'arrivée d'un joueur (après le chargement de sa sauvegarde)
function RewardsManager.setup(player)
	player:SetAttribute("SessionStart", os.time())
	player:SetAttribute("GiftsClaimed", 0)
	checkDay(player)
end

function RewardsManager.init(dependencies)
	deps = dependencies
	deps.Remotes.ClaimGift.OnServerEvent:Connect(RewardsManager.claimGift)
	deps.Remotes.ClaimQuest.OnServerEvent:Connect(RewardsManager.claimQuest)
end

return RewardsManager
