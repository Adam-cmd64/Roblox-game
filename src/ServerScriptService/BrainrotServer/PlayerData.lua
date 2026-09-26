-- ModuleScript : les données de chaque joueur + la sauvegarde (DataStore).
--
-- player.Brainrots : un StringValue par brainrot possédé
--   Name = identifiant unique, Value = nom du brainrot
--   Attributs : Mutation, Slot (0 = dans le sac, >0 = posé dans la base, -1 = en train d'être volé),
--               Serial (numéro de tirage : #1 = la première carte de ce brainrot trouvée dans le jeu)
-- player.Index : un BoolValue par brainrot déjà découvert (pour les bonus d'index)
-- player.PickaxeTier, player.BatTier, player.Spins (tours de roue payés)
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

-- Marque un brainrot comme découvert (index)
function PlayerData.discover(player, cardName)
	local index = player:FindFirstChild("Index")
	if index and not index:FindFirstChild(cardName) and GameConfig.getCard(cardName) then
		local entry = Instance.new("BoolValue")
		entry.Name = cardName
		entry.Value = true
		entry.Parent = index
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
	local cash = newValue("IntValue", "Cash", 0, leaderstats)
	local rebirths = newValue("IntValue", "Rebirths", 0, leaderstats)

	local pickaxeTier = newValue("IntValue", "PickaxeTier", 1, nil)
	local batTier = newValue("IntValue", "BatTier", 1, nil)
	local spins = newValue("IntValue", "Spins", 0, nil)

	local folder = Instance.new("Folder")
	folder.Name = "Brainrots"
	local index = Instance.new("Folder")
	index.Name = "Index"

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
		cash.Value = tonumber(data.Cash) or 0
		rebirths.Value = tonumber(data.Rebirths) or 0
		pickaxeTier.Value = math.clamp(tonumber(data.PickaxeTier) or 1, 1, #GameConfig.PICKAXES)
		batTier.Value = math.clamp(tonumber(data.BatTier) or 1, 1, #GameConfig.BATS)
		spins.Value = math.max(0, tonumber(data.Spins) or 0)
		player:SetAttribute("LuckUntil", tonumber(data.LuckUntil) or 0)
		player:SetAttribute("LastFreeSpin", tonumber(data.LastFreeSpin) or 0)
		for _, key in ipairs({"DoubleCash", "FlyingCarpet"}) do
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

	leaderstats.Parent = player
	pickaxeTier.Parent = player
	batTier.Parent = player
	spins.Parent = player
	index.Parent = player
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
			PlayerData.addItem(player, entry.c, mutation, slot, tonumber(entry.n) or 0)
		end
	end
end

-- ====== SAUVEGARDE ======
function PlayerData.save(player)
	if not store or player:GetAttribute("DataLoaded") ~= true then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local items = {}
	for _, item in ipairs(PlayerData.getItems(player)) do
		local slot = item:GetAttribute("Slot") or 0
		table.insert(items, {c = item.Value, m = item:GetAttribute("Mutation"), s = math.max(slot, 0), n = item:GetAttribute("Serial") or 0})
	end
	local discovered = {}
	local indexFolder = player:FindFirstChild("Index")
	if indexFolder then
		for _, entry in ipairs(indexFolder:GetChildren()) do
			table.insert(discovered, entry.Name)
		end
	end

	local data = {
		Cash = leaderstats.Cash.Value,
		Rebirths = leaderstats.Rebirths.Value,
		PickaxeTier = player.PickaxeTier.Value,
		BatTier = player.BatTier.Value,
		Spins = player.Spins.Value,
		LuckUntil = player:GetAttribute("LuckUntil") or 0,
		LastFreeSpin = player:GetAttribute("LastFreeSpin") or 0,
		DoubleCash = player:GetAttribute("DoubleCash") == true,
		FlyingCarpet = player:GetAttribute("FlyingCarpet") == true,
		Index = discovered,
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
