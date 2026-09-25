-- ModuleScript : les données de chaque joueur + la sauvegarde (DataStore).
--
-- Chaque brainrot possédé est un StringValue dans player.Brainrots :
--   Name  = identifiant unique
--   Value = nom du brainrot
--   Attributs : Mutation (texte), Slot (0 = dans l'inventaire, 1..16 = posé dans la base)
-- Ces objets sont automatiquement visibles par le client (pour l'inventaire, l'index, etc).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

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

function PlayerData.addItem(player, cardName, mutation, slot)
	local folder = PlayerData.getFolder(player)
	if not folder or not GameConfig.getCard(cardName) then return nil end
	local item = Instance.new("StringValue")
	item.Name = newId()
	item.Value = cardName
	item:SetAttribute("Mutation", mutation or "Normal")
	item:SetAttribute("Slot", slot or 0)
	item.Parent = folder
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

-- ====== CREATION + CHARGEMENT ======
function PlayerData.setup(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats

	local pickaxeTier = Instance.new("IntValue")
	pickaxeTier.Name = "PickaxeTier"
	pickaxeTier.Value = 1

	local folder = Instance.new("Folder")
	folder.Name = "Brainrots"

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
	end

	leaderstats.Parent = player
	pickaxeTier.Parent = player
	folder.Parent = player

	if type(data) == "table" and type(data.Items) == "table" then
		local maxSlot = GameConfig.getSlotCount(rebirths.Value)
		local usedSlots = {}
		for _, entry in ipairs(data.Items) do
			local slot = tonumber(entry.s) or 0
			if slot < 1 or slot > maxSlot or usedSlots[slot] then
				slot = 0
			end
			if slot > 0 then
				usedSlots[slot] = true
			end
			local mutation = GameConfig.MUTATIONS[entry.m] and entry.m or "Normal"
			PlayerData.addItem(player, entry.c, mutation, slot)
		end
	end
end

-- ====== SAUVEGARDE ======
function PlayerData.save(player)
	if not store or player:GetAttribute("DataLoaded") ~= true then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	local pickaxeTier = player:FindFirstChild("PickaxeTier")
	if not leaderstats or not pickaxeTier then return end

	local items = {}
	for _, item in ipairs(PlayerData.getItems(player)) do
		table.insert(items, {c = item.Value, m = item:GetAttribute("Mutation"), s = item:GetAttribute("Slot")})
	end

	local data = {
		Cash = leaderstats.Cash.Value,
		Rebirths = leaderstats.Rebirths.Value,
		PickaxeTier = pickaxeTier.Value,
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
