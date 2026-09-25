-- Script principal du serveur : joueurs, argent, pioches, rebirth.
-- La mine est gérée par MineManager, les bases par BaseManager, la pioche par PickaxeBuilder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MineManager = require(script.Parent:WaitForChild("MineManager"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local PickaxeBuilder = require(script.Parent:WaitForChild("PickaxeBuilder"))

local PICKAXES = GameConfig.PICKAXES
local CARDS = GameConfig.CARDS

-- ====== NETTOYAGE DU TEMPLATE ROBLOX ======
-- La Baseplate et le SpawnLocation par défaut boucheraient le trou de la mine
if GameConfig.BASE.CleanTemplate then
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then baseplate:Destroy() end
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if spawnLocation then spawnLocation:Destroy() end
end

-- ====== REMOTE EVENTS (créés automatiquement) ======
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local function getRemote(name)
	local remote = RemoteEvents:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = RemoteEvents
	end
	return remote
end

local BuyPickaxe = getRemote("BuyPickaxe")
local Rebirth = getRemote("Rebirth")
local MineBlock = getRemote("MineBlock") -- client -> serveur : "je frappe ce bloc"
local Teleport = getRemote("Teleport") -- client -> serveur : "base" ou "mine"
local CardFound = getRemote("CardFound") -- serveur -> client : carte obtenue
local BlockBroken = getRemote("BlockBroken") -- serveur -> client : bloc cassé (+cash)
local Notify = getRemote("Notify") -- serveur -> client : message

-- ====== CONSTRUCTION DU MONDE ======
MineManager.init()
BaseManager.init()

-- Spawn neutre au bord de la mine (au cas où toutes les bases sont prises)
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "MineSpawn"
spawnLocation.Size = Vector3.new(8, 1, 8)
spawnLocation.Anchored = true
spawnLocation.CFrame = MineManager.getSurfaceCFrame() * CFrame.new(0, -3.5, 4)
spawnLocation.Color = Color3.fromRGB(80, 80, 80)
spawnLocation.Material = Enum.Material.Slate
spawnLocation.Transparency = 0
spawnLocation.Parent = Workspace

-- ====== PIOCHE ======
local function givePickaxe(player)
	local tierValue = player:FindFirstChild("PickaxeTier")
	local pickaxeData = PICKAXES[tierValue and tierValue.Value or 1] or PICKAXES[1]

	local backpack = player:FindFirstChild("Backpack")
	for _, container in ipairs({backpack, player.Character}) do
		if container then
			local old = container:FindFirstChild("Pioche")
			if old then old:Destroy() end
		end
	end

	local tool = PickaxeBuilder.build(pickaxeData)
	tool.Parent = backpack

	-- On l'équipe direct pour que le joueur puisse miner tout de suite
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end
end

-- ====== SETUP JOUEUR ======
local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	leaderstats.Parent = player

	local pickaxeTier = Instance.new("IntValue")
	pickaxeTier.Name = "PickaxeTier"
	pickaxeTier.Value = 1
	pickaxeTier.Parent = player

	-- On remplit le dossier AVANT de le parenter pour que le client voie tout d'un coup
	local cardsFolder = Instance.new("Folder")
	cardsFolder.Name = "Cards"
	for _, card in ipairs(CARDS) do
		local countValue = Instance.new("IntValue")
		countValue.Name = card.Name
		countValue.Value = 0
		countValue.Changed:Connect(function()
			BaseManager.refresh(player)
		end)
		countValue.Parent = cardsFolder
	end
	cardsFolder.Parent = player

	BaseManager.assign(player)
	BaseManager.refresh(player)

	local function onCharacter(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then return end
		task.wait(0.1)
		local spawnCFrame = BaseManager.getSpawnCFrame(player)
		if spawnCFrame then
			character:PivotTo(spawnCFrame)
		end
		givePickaxe(player)
	end

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	BaseManager.release(player)
end)

-- ====== MINAGE ======
local lastHit = {} -- anti-triche : temps du dernier coup par joueur

MineBlock.OnServerEvent:Connect(function(player, block)
	if typeof(block) ~= "Instance" or not MineManager.isBlock(block) then return end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not character:FindFirstChild("Pioche") then return end
	if (root.Position - block.Position).Magnitude > GameConfig.MINE.MineRange + 4 then return end

	local tierValue = player:FindFirstChild("PickaxeTier")
	local tier = tierValue and tierValue.Value or 1
	local pickaxeData = PICKAXES[tier] or PICKAXES[1]

	local now = os.clock()
	if lastHit[player] and now - lastHit[player] < pickaxeData.Cooldown * 0.8 then return end
	lastHit[player] = now

	local result, errorMessage = MineManager.hit(block, pickaxeData.Damage, tier)
	if errorMessage then
		Notify:FireClient(player, errorMessage)
		return
	end
	if not result then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	-- Cash du bloc
	local cashGain = result.layer.Cash
	leaderstats.Cash.Value += cashGain
	BlockBroken:FireClient(player, result.position, cashGain, result.layerIndex)

	-- Carte brainrot si c'était un minerai
	if result.card then
		local countValue = player.Cards:FindFirstChild(result.card.Name)
		if countValue then
			countValue.Value += 1
		end
		CardFound:FireClient(player, result.card.Name)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastHit[player] = nil
end)

-- ====== TELEPORTATION (boutons "Ma base" / "Mine") ======
Teleport.OnServerEvent:Connect(function(player, destination)
	local character = player.Character
	if not character then return end
	if destination == "base" then
		local spawnCFrame = BaseManager.getSpawnCFrame(player)
		if spawnCFrame then
			character:PivotTo(spawnCFrame)
		end
	elseif destination == "mine" then
		character:PivotTo(MineManager.getSurfaceCFrame())
	end
end)

-- ====== REVENU PASSIF DES CARTES (toutes les secondes) ======
local function getIncomePerSecond(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cardsFolder = player:FindFirstChild("Cards")
	if not leaderstats or not cardsFolder then return 0 end

	local income = 0
	for _, card in ipairs(CARDS) do
		local countValue = cardsFolder:FindFirstChild(card.Name)
		if countValue then
			income += countValue.Value * card.Income
		end
	end
	return math.floor(income * GameConfig.getIncomeMultiplier(leaderstats.Rebirths.Value))
end

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				leaderstats.Cash.Value += getIncomePerSecond(player)
			end
		end
	end
end)

-- ====== ACHAT DE PIOCHE ======
BuyPickaxe.OnServerEvent:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local pickaxeTier = player:FindFirstChild("PickaxeTier")
	if not leaderstats or not pickaxeTier then return end

	local nextPickaxe = PICKAXES[pickaxeTier.Value + 1]
	if not nextPickaxe then
		Notify:FireClient(player, "Tu as déjà la meilleure pioche !")
		return
	end
	if leaderstats.Rebirths.Value < nextPickaxe.RequiredRebirths then
		Notify:FireClient(player, "Il faut " .. nextPickaxe.RequiredRebirths .. " rebirth(s) pour la " .. nextPickaxe.Name)
		return
	end
	if leaderstats.Cash.Value < nextPickaxe.Cost then
		Notify:FireClient(player, "Pas assez de Cash (" .. nextPickaxe.Cost .. " requis)")
		return
	end

	leaderstats.Cash.Value -= nextPickaxe.Cost
	pickaxeTier.Value += 1
	givePickaxe(player)
	Notify:FireClient(player, "Nouvelle pioche : " .. nextPickaxe.Name .. " !")
end)

-- ====== REBIRTH ======
Rebirth.OnServerEvent:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cardsFolder = player:FindFirstChild("Cards")
	if not leaderstats or not cardsFolder then return end

	local sahurCard = cardsFolder:FindFirstChild(GameConfig.REBIRTH_CARD_REQUIRED)
	if leaderstats.Cash.Value < GameConfig.REBIRTH_COST then
		Notify:FireClient(player, "Il faut " .. GameConfig.REBIRTH_COST .. " Cash pour rebirth")
		return
	end
	if not sahurCard or sahurCard.Value < 1 then
		Notify:FireClient(player, "Il faut 1 carte " .. GameConfig.REBIRTH_CARD_REQUIRED .. " pour rebirth")
		return
	end

	leaderstats.Cash.Value = 0
	sahurCard.Value -= 1
	leaderstats.Rebirths.Value += 1
	Notify:FireClient(player, "REBIRTH ! Revenu x" .. GameConfig.getIncomeMultiplier(leaderstats.Rebirths.Value))
end)

-- ====== ANNONCE AVANT LA REGENERATION DE LA MINE ======
task.spawn(function()
	local announced = false
	while true do
		task.wait(1)
		local remaining = (Workspace:GetAttribute("MineResetAt") or 0) - Workspace:GetServerTimeNow()
		if remaining <= 15 and remaining > 0 and not announced then
			announced = true
			Notify:FireAllClients("⚠️ La mine se régénère dans 15 secondes !")
		elseif remaining > 15 then
			announced = false
		end
	end
end)
