-- ModuleScript : les données de chaque joueur + la sauvegarde (DataStore).
--
-- player.Brainrots : un StringValue par brainrot possédé
--   Name = identifiant unique, Value = nom du brainrot
--   Attributs : Mutation, Slot (0 = dans le sac, >0 = posé dans la base, -1 = en train d'être volé),
--               Serial (numéro de tirage : #1 = la première carte de ce brainrot trouvée dans le jeu)
-- player.Index : un BoolValue par brainrot déjà découvert (pour les bonus d'index)
-- player.PickaxeTier, player.BatTier, player.GrappleTier (0 = pas de grappin), player.Spins (tours de roue payés)
-- Attributs du joueur : LuckUntil (fin de la potion), LastFreeSpin (dernier tour gratuit), DoubleCash (Game Pass argent x2)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Serials = require(script.Parent.Serials)
local Remotes = require(script.Parent.Remotes)

local PlayerData = {}

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore indisponible (active 'Enable Studio Access to API Services' pour sauvegarder en test) :", result)
	end
end

local function newId()
	return string.sub(HttpService:GenerateGUID(false), 1, 13)
end

function PlayerData.getFolder(player)
	return player:FindFirstChild("Brainrots")
end

-- Récompenses de l'Index (paliers de découvertes), données une seule fois
function PlayerData.checkDexRewards(player)
	local index = player:FindFirstChild("Index")
	local leaderstats = player:FindFirstChild("leaderstats")
	if not index or not leaderstats then return end
	local count = #index:GetChildren()
	local claimed = player:GetAttribute("DexClaimed") or 0
	for number = claimed + 1, #GameConfig.DEX_REWARDS do
		local reward = GameConfig.DEX_REWARDS[number]
		if count < reward.Count then break end
		player:SetAttribute("DexClaimed", number)
		local parts = {}
		if reward.Cash then
			leaderstats.Cash.Value += reward.Cash
			table.insert(parts, "$" .. GameConfig.format(reward.Cash))
		end
		if reward.Spins and player:FindFirstChild("Spins") then
			player.Spins.Value += reward.Spins
			table.insert(parts, reward.Spins .. " tour(s) de roue")
		end
		if reward.PotionMinutes then
			PlayerData.addLuckMinutes(player, reward.PotionMinutes)
			table.insert(parts, "potion " .. reward.PotionMinutes .. " min")
		end
		Remotes.notify(player, "📖 INDEX : " .. reward.Count .. " brainrots découverts ! +" .. table.concat(parts, " + "), "success")
	end
end

-- Marque un brainrot comme découvert (index)
function PlayerData.discover(player, cardName)
	local index = player:FindFirstChild("Index")
	if index and not index:FindFirstChild(cardName) and GameConfig.getCard(cardName) then
		local entry = Instance.new("BoolValue")
		entry.Name = cardName
		entry.Value = true
		entry.Parent = index
		PlayerData.checkDexRewards(player)
	end
end

-- Index des MUTATIONS : on retient chaque couple "carte|mutation" déjà obtenu (Sahur Or, Sahur Galaxie...)
function PlayerData.discoverMutation(player, cardName, mutation)
	if not mutation or mutation == "Normal" or not GameConfig.MUTATIONS[mutation] or not GameConfig.getCard(cardName) then return end
	local folder = player:FindFirstChild("IndexMutations")
	local key = cardName .. "|" .. mutation
	if folder and not folder:FindFirstChild(key) then
		local entry = Instance.new("BoolValue")
		entry.Name = key
		entry.Value = true
		entry.Parent = folder
	end
end

-- Ajoute une carte. Sans "serial", c'est une nouvelle carte : elle reçoit le prochain numéro de tirage,
-- et si elle est très rare, tout le serveur le voit dans le chat ("verb" : "a pack", "a miné"...).
function PlayerData.addItem(player, cardName, mutation, slot, serial, verb)
	local isNew = serial == nil
	local folder = PlayerData.getFolder(player)
	if not folder or not GameConfig.getCard(cardName) then return nil end
	if serial == nil then
		serial = Serials.next(cardName)
		if not folder.Parent then return nil end -- le joueur est parti pendant l'attente
	end
	local item = Instance.new("StringValue")
	item.Name = newId()
	item.Value = cardName
	item:SetAttribute("Mutation", mutation or "Normal")
	item:SetAttribute("Slot", slot or 0)
	item:SetAttribute("Serial", serial)
	item.Parent = folder
	PlayerData.discover(player, cardName)
	PlayerData.discoverMutation(player, cardName, mutation)
	local card = GameConfig.getCard(cardName)
	local threshold = GameConfig.RARITIES[GameConfig.ANNOUNCE_FROM_RARITY]
	if isNew and card and threshold and GameConfig.RARITIES[card.Rarity].Order >= threshold.Order then
		Remotes.Announce:FireAllClients(player.DisplayName, verb or "a obtenu", cardName, mutation or "Normal", serial)
	end
	return item
end

function PlayerData.findItem(player, itemId)
	local folder = PlayerData.getFolder(player)
	if not folder or typeof(itemId) ~= "string" then return nil end
	local item = folder:FindFirstChild(itemId)
	if item and item:IsA("StringValue") then
		return item
	end
	return nil
end

function PlayerData.getItems(player)
	local folder = PlayerData.getFolder(player)
	return folder and folder:GetChildren() or {}
end

function PlayerData.getPlacedItem(player, slot)
	for _, item in ipairs(PlayerData.getItems(player)) do
		if item:GetAttribute("Slot") == slot then
			return item
		end
	end
	return nil
end

-- Premier emplacement libre et débloqué de la base (ou nil)
function PlayerData.getFreeSlot(player)
	local rebirths = player.leaderstats.Rebirths.Value
	local used = {}
	for _, item in ipairs(PlayerData.getItems(player)) do
		used[item:GetAttribute("Slot") or 0] = true
	end
	for index = 1, GameConfig.getTotalSlots() do
		if not used[index] and GameConfig.isSlotUnlocked(index, rebirths) then
			return index
		end
	end
	return nil
end

-- Supprime la carte tenue en main qui correspond à cet objet (s'il y en a une)
function PlayerData.destroyHeldTool(player, itemId)
	for _, container in ipairs({player:FindFirstChild("Backpack"), player.Character}) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("ItemId") == itemId then
					tool:Destroy()
				end
			end
		end
	end
end

function PlayerData.removeItem(player, item)
	PlayerData.destroyHeldTool(player, item.Name)
	item:Destroy()
end

-- Multiplicateur de chance de la potion (x2 tant qu'elle est active)
function PlayerData.hasLuckPotion(player)
	return (player:GetAttribute("LuckUntil") or 0) > os.time()
end

-- Minerais (dossier "Minerals" : un IntValue par minerai)
function PlayerData.addMineral(player, id, amount)
	local folder = player:FindFirstChild("Minerals")
	local value = folder and folder:FindFirstChild(id)
	if not value then return false end
	value.Value = math.max(0, value.Value + (amount or 1))
	return true
end

function PlayerData.getMineralCount(player, id)
	local folder = player:FindFirstChild("Minerals")
	local value = folder and folder:FindFirstChild(id)
	return value and value.Value or 0
end

function PlayerData.addLuckMinutes(player, minutes)
	local now = os.time()
	local current = math.max(player:GetAttribute("LuckUntil") or 0, now)
	player:SetAttribute("LuckUntil", current + minutes * 60)
end

-- ====== CREATION + CHARGEMENT ======
local function newValue(className, name, value, parent)
	local obj = Instance.new(className)
	obj.Name = name
	obj.Value = value
	obj.Parent = parent
	return obj
end

function PlayerData.setup(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	-- NumberValue (et pas IntValue) : un IntValue déborde à 9,2 Qi et devient NÉGATIF
	local cash = newValue("NumberValue", "Cash", 0, leaderstats)
	local rebirths = newValue("IntValue", "Rebirths", 0, leaderstats)

	for key, default in pairs(GameConfig.SETTINGS) do
		player:SetAttribute("Setting_" .. key, default)
	end
	local pickaxeTier = newValue("IntValue", "PickaxeTier", 1, nil)
	local batTier = newValue("IntValue", "BatTier", 1, nil)
	local grappleTier = newValue("IntValue", "GrappleTier", 0, nil)
	local spins = newValue("IntValue", "Spins", 0, nil)

	local folder = Instance.new("Folder")
	folder.Name = "Brainrots"
	local index = Instance.new("Folder")
	index.Name = "Index"
	local indexMutations = Instance.new("Folder")
	indexMutations.Name = "IndexMutations"
	local minerals = Instance.new("Folder")
	minerals.Name = "Minerals"
	for _, mineral in ipairs(GameConfig.MINERALS) do
		newValue("IntValue", mineral.Id, 0, minerals)
	end

	-- Chargement de la sauvegarde
	local data
	if store then
		local ok, result = pcall(function()
			return store:GetAsync("u_" .. player.UserId)
		end)
		if ok then
			data = result
			player:SetAttribute("DataLoaded", true)
		else
			warn("[PlayerData] Chargement impossible pour", player.Name, result)
			player:SetAttribute("DataLoaded", false) -- on ne sauvegardera pas pour ne rien écraser
		end
	end

	if type(data) == "table" then
		local savedCash = tonumber(data.Cash) or 0
		if savedCash < 0 then
			-- ancienne sauvegarde qui a débordé (argent devenu négatif) : on remet le bon montant
			savedCash += 2 ^ 64
		end
		cash.Value = math.max(0, savedCash)
		rebirths.Value = tonumber(data.Rebirths) or 0
		pickaxeTier.Value = math.clamp(tonumber(data.PickaxeTier) or 1, 1, #GameConfig.PICKAXES)
		batTier.Value = math.clamp(tonumber(data.BatTier) or 1, 1, #GameConfig.BATS)
		grappleTier.Value = math.clamp(tonumber(data.GrappleTier) or 0, 0, #GameConfig.GRAPPLES)
		spins.Value = math.max(0, tonumber(data.Spins) or 0)
		player:SetAttribute("LuckUntil", tonumber(data.LuckUntil) or 0)
		player:SetAttribute("LastFreeSpin", tonumber(data.LastFreeSpin) or 0)
		player:SetAttribute("DexClaimed", tonumber(data.DexClaimed) or 0)
		player:SetAttribute("DailyStreak", tonumber(data.DailyStreak) or 0)
		player:SetAttribute("LastSeen", tonumber(data.LastSeen) or 0)
		-- temps de jeu total (les anciens joueurs qui ont déjà fait un rebirth n'ont plus besoin du guide)
		local playTime = tonumber(data.PlayTime) or 0
		if (tonumber(data.Rebirths) or 0) > 0 then
			playTime = math.max(playTime, GameConfig.GUIDE_MINUTES * 60)
		end
		player:SetAttribute("PlayTime", playTime)
		if type(data.Settings) == "table" then
			for key, value in pairs(data.Settings) do
				if GameConfig.SETTINGS[key] ~= nil and type(value) == "boolean" then
					player:SetAttribute("Setting_" .. key, value)
				end
			end
		end
		player:SetAttribute("DailyLast", tonumber(data.DailyLast) or 0)
		-- quêtes du jour (RewardsManager)
		if type(data.Quests) == "table" then
			player:SetAttribute("QuestDay", tonumber(data.Quests.Day) or 0)
			for i = 1, #GameConfig.QUESTS.List do
				player:SetAttribute("Quest" .. i, tonumber(type(data.Quests.P) == "table" and data.Quests.P[i]) or 0)
			end
			player:SetAttribute("QuestClaimed", tonumber(data.Quests.C) or 0)
		end
		if type(data.IndexMut) == "table" then
			for _, key in ipairs(data.IndexMut) do
				local cardName, mutation = string.match(tostring(key), "^(.+)|(.+)$")
				if cardName and GameConfig.getCard(cardName) and GameConfig.MUTATIONS[mutation] and not indexMutations:FindFirstChild(key) then
					newValue("BoolValue", key, true, indexMutations)
				end
			end
		end
		if type(data.Minerals) == "table" then
			for id, count in pairs(data.Minerals) do
				local value = minerals:FindFirstChild(tostring(id))
				if value then
					value.Value = math.max(0, math.floor(tonumber(count) or 0))
				end
			end
		end
		for _, key in ipairs({"DoubleCash", "FlyingCarpet", "StarterClaimed", "VIP", "VIPMinerals", "DivinePickaxe", "AutoCollect"}) do
			if data[key] == true then
				player:SetAttribute(key, true)
			end
		end
		if type(data.Index) == "table" then
			for _, name in ipairs(data.Index) do
				if GameConfig.getCard(name) and not index:FindFirstChild(name) then
					newValue("BoolValue", name, true, index)
				end
			end
		end
	else
		player:SetAttribute("LuckUntil", 0)
		player:SetAttribute("LastFreeSpin", 0)
	end
	-- le monde où se trouve sa base (1 = monde Brainrot, 2 = Nuit de Cristal)
	-- (il faut être rebirth 10 pour le monde 2 : sinon on revient dans le monde 1)
	local inWorld2 = type(data) == "table" and data.World == 2 and rebirths.Value >= (GameConfig.getWorld(2).RequiredRebirths or 0)
	player:SetAttribute("World", inWorld2 and 2 or 1)

	leaderstats.Parent = player
	pickaxeTier.Parent = player
	batTier.Parent = player
	grappleTier.Parent = player
	spins.Parent = player
	index.Parent = player
	indexMutations.Parent = player
	minerals.Parent = player
	folder.Parent = player

	if type(data) == "table" and type(data.Items) == "table" then
		local usedSlots = {}
		for _, entry in ipairs(data.Items) do
			local slot = tonumber(entry.s) or 0
			if slot < 1 or not GameConfig.isSlotUnlocked(slot, rebirths.Value) or usedSlots[slot] then
				slot = 0
			end
			if slot > 0 then
				usedSlots[slot] = true
			end
			local mutation = GameConfig.MUTATIONS[entry.m] and entry.m or "Normal"
			local item = PlayerData.addItem(player, entry.c, mutation, slot, tonumber(entry.n) or 0)
			if item and entry.o and GameConfig.getMineral(entry.o) then
				item:SetAttribute("Mineral", entry.o)
			end
			if item and tonumber(entry.fl) and tonumber(entry.fi) and tonumber(entry.fl) > 0 then
				item:SetAttribute("FusionIncome", tonumber(entry.fi))
				item:SetAttribute("FusionLevel", tonumber(entry.fl))
			end
		end
	end
	PlayerData.checkDexRewards(player)
end

-- ====== SAUVEGARDE ======
function PlayerData.save(player)
	if not store or player:GetAttribute("DataLoaded") ~= true then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local items = {}
	for _, item in ipairs(PlayerData.getItems(player)) do
		local slot = item:GetAttribute("Slot") or 0
		table.insert(items, {c = item.Value, m = item:GetAttribute("Mutation"), s = math.max(slot, 0), n = item:GetAttribute("Serial") or 0, o = item:GetAttribute("Mineral"), fi = item:GetAttribute("FusionIncome"), fl = item:GetAttribute("FusionLevel")})
	end
	local discoveredMutations = {}
	local mutationFolder = player:FindFirstChild("IndexMutations")
	if mutationFolder then
		for _, entry in ipairs(mutationFolder:GetChildren()) do
			table.insert(discoveredMutations, entry.Name)
		end
	end
	local discovered = {}
	local indexFolder = player:FindFirstChild("Index")
	if indexFolder then
		for _, entry in ipairs(indexFolder:GetChildren()) do
			table.insert(discovered, entry.Name)
		end
	end

	local settings = {}
	for key, default in pairs(GameConfig.SETTINGS) do
		local value = player:GetAttribute("Setting_" .. key)
		if value == nil then
			value = default
		end
		settings[key] = value
	end
	local mineralCounts = {}
	local mineralFolder = player:FindFirstChild("Minerals")
	if mineralFolder then
		for _, value in ipairs(mineralFolder:GetChildren()) do
			mineralCounts[value.Name] = value.Value
		end
	end

	local data = {
		Cash = leaderstats.Cash.Value,
		Rebirths = leaderstats.Rebirths.Value,
		PickaxeTier = player.PickaxeTier.Value,
		BatTier = player.BatTier.Value,
		GrappleTier = player.GrappleTier.Value,
		Spins = player.Spins.Value,
		LuckUntil = player:GetAttribute("LuckUntil") or 0,
		LastFreeSpin = player:GetAttribute("LastFreeSpin") or 0,
		DoubleCash = player:GetAttribute("DoubleCash") == true,
		FlyingCarpet = player:GetAttribute("FlyingCarpet") == true,
		StarterClaimed = player:GetAttribute("StarterClaimed") == true,
		VIP = player:GetAttribute("VIP") == true,
		VIPMinerals = player:GetAttribute("VIPMinerals") == true,
		DivinePickaxe = player:GetAttribute("DivinePickaxe") == true,
		PlayTime = player:GetAttribute("PlayTime") or 0,
		AutoCollect = player:GetAttribute("AutoCollect") == true,
		World = player:GetAttribute("World") or 1,
		LastSeen = os.time(),
		Settings = settings,
		DexClaimed = player:GetAttribute("DexClaimed") or 0,
		DailyStreak = player:GetAttribute("DailyStreak") or 0,
		DailyLast = player:GetAttribute("DailyLast") or 0,
		Quests = {
			Day = player:GetAttribute("QuestDay") or 0,
			P = {player:GetAttribute("Quest1") or 0, player:GetAttribute("Quest2") or 0, player:GetAttribute("Quest3") or 0},
			C = player:GetAttribute("QuestClaimed") or 0,
		},
		Minerals = mineralCounts,
		Index = discovered,
		IndexMut = discoveredMutations,
		Items = items,
	}
	local ok, err = pcall(function()
		store:SetAsync("u_" .. player.UserId, data)
	end)
	if not ok then
		warn("[PlayerData] Sauvegarde impossible pour", player.Name, err)
	end
end

function PlayerData.startAutosave()
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(PlayerData.save, player)
			end
		end
	end)
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerData.save(player)
		end
	end)
end

return PlayerData
