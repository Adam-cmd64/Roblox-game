-- Script principal du serveur.
-- Il construit le monde, crée les joueurs et relie tous les modules entre eux :
--   Remotes, PlayerData (sauvegarde), Loot (tirages), MineManager (la mine), BaseManager (les bases),
--   ShopManager (la boutique : pioches + battes), Monetization (boosters Robux), TradeManager (échanges),
--   WorldBuilder (décor), AdminCommands (commandes chat), PickaxeBuilder (pioche Minecraft + battes),
--   BatManager (coups de batte), WheelManager (la roue de la fortune dans le monde)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CollectionService = game:GetService("CollectionService")

local Remotes = require(script.Remotes)
local PlayerData = require(script.PlayerData)
local Loot = require(script.Loot)
local MineManager = require(script.MineManager)
local BaseManager = require(script.BaseManager)
local ShopManager = require(script.ShopManager)
local Monetization = require(script.Monetization)
local TradeManager = require(script.TradeManager)
local WorldBuilder = require(script.WorldBuilder)
local AdminCommands = require(script.AdminCommands)
local PickaxeBuilder = require(script.PickaxeBuilder)
local BatManager = require(script.BatManager)
local CarpetManager = require(script.CarpetManager)
local GrappleManager = require(script.GrappleManager)
local LeaderboardManager = require(script.LeaderboardManager)
local DailyManager = require(script.DailyManager)
local StarterChest = require(script.StarterChest)
local VipManager = require(script.VipManager)
local WheelManager = require(script.WheelManager)
local FusionManager = require(script.FusionManager)
local World2Builder = require(script.World2Builder)
local PortalManager = require(script.PortalManager)

local PICKAXES = GameConfig.PICKAXES

-- ====== NETTOYAGE DU TEMPLATE ROBLOX ======
if GameConfig.BASE.CleanTemplate then
	for _, name in ipairs({"Baseplate", "SpawnLocation"}) do
		local object = Workspace:FindFirstChild(name)
		if object then
			object:Destroy()
		end
	end
end

-- ====== PIOCHE ======
local function givePickaxe(player)
	local pickaxeData = GameConfig.getPlayerPickaxe(player)

	for _, container in ipairs({player:FindFirstChild("Backpack"), player.Character}) do
		if container then
			local old = container:FindFirstChild("Pioche")
			if old then
				old:Destroy()
			end
		end
	end

	local tool = PickaxeBuilder.build(pickaxeData)
	tool.Parent = player:FindFirstChild("Backpack")

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end
end

-- ====== CARTE TENUE EN MAIN ======
local function buildCardTool(item)
	local tool = Instance.new("Tool")
	tool.Name = item.Value
	tool.ToolTip = "Pose-la sur un emplacement de ta base (touche E)"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -1, 0)
	tool:SetAttribute("ItemId", item.Name)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.6, 2.56, 0.06) -- format 5:8
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Color = Color3.fromRGB(30, 30, 30)
	handle.Parent = tool

	-- La carte est dessinée par chaque client sur les deux faces (voir World.lua)
	handle:SetAttribute("CardName", item.Value)
	handle:SetAttribute("Mutation", item:GetAttribute("Mutation"))
	handle:SetAttribute("Serial", item:GetAttribute("Serial"))
	handle:SetAttribute("FusionIncome", item:GetAttribute("FusionIncome"))
	handle:SetAttribute("FusionLevel", item:GetAttribute("FusionLevel"))
	handle:SetAttribute("DoubleSided", true)
	CollectionService:AddTag(handle, "CardDisplay")

	return tool
end

-- ====== CONSTRUCTION DU MONDE ======
local deps = {
	Remotes = Remotes,
	PlayerData = PlayerData,
	Loot = Loot,
	BaseManager = BaseManager,
	ShopManager = ShopManager,
	WheelManager = WheelManager,
	PickaxeBuilder = PickaxeBuilder,
	GrappleManager = GrappleManager,
	BatManager = BatManager,
	MineHalf = MineManager.HALF,
	MineManager = MineManager,
	givePickaxe = givePickaxe,
}
MineManager.init(deps)
BaseManager.init(deps)
ShopManager.init(deps)
BatManager.init(deps)
CarpetManager.init(deps)
GrappleManager.init(deps)
WheelManager.init(deps)
LeaderboardManager.init()
deps.ShopFront = ShopManager.getFrontPosition()
deps.WheelFront = WheelManager.getFrontPosition()
WorldBuilder.init(deps)
-- le MONDE 2 (Nuit de Cristal) et les portails pour y aller / revenir
World2Builder.init(deps)
ShopManager.initCrystal(deps, World2Builder.SHOP_CFRAME)
deps.ReturnVortex = World2Builder.returnVortex
deps.ReturnPortalPosition = World2Builder.RETURN_PORTAL
deps.PortalPosition = WorldBuilder.PORTAL_POSITION
PortalManager.init(deps)
DailyManager.init(deps)
StarterChest.init(deps)
deps.StarterChest = StarterChest
Monetization.init(deps)
VipManager.init(deps)
TradeManager.init(deps)
deps.TradeManager = TradeManager
FusionManager.init(deps)
AdminCommands.init(deps)
PlayerData.startAutosave()

-- ====== ARRIVEE D'UN JOUEUR ======
local addGiftPrompt -- (définie plus bas : "DONNER UNE CARTE")

local function onPlayerAdded(player)
	PlayerData.setup(player)
	if not player.Parent then return end

	BaseManager.assign(player)

	-- (plusieurs changements dans la même image = UNE seule mise à jour de la base : beaucoup moins de lag
	-- quand on a plein de cartes)
	local refreshPending = false
	local function refresh()
		if refreshPending then return end
		refreshPending = true
		task.defer(function()
			refreshPending = false
			if player.Parent then
				BaseManager.refresh(player)
			end
		end)
	end
	local folder = PlayerData.getFolder(player)
	local function watchItem(item)
		item.AttributeChanged:Connect(refresh)
		-- nouvelle mutation (admin /mutation...) : elle entre dans l'index des mutations
		item:GetAttributeChangedSignal("Mutation"):Connect(function()
			PlayerData.discoverMutation(player, item.Value, item:GetAttribute("Mutation"))
		end)
	end
	for _, item in ipairs(folder:GetChildren()) do
		watchItem(item)
	end
	folder.ChildAdded:Connect(function(item)
		watchItem(item)
		PlayerData.discover(player, item.Value) -- échange / vol : la carte entre dans l'index
		PlayerData.discoverMutation(player, item.Value, item:GetAttribute("Mutation"))
		refresh()
	end)
	player.Index.ChildAdded:Connect(refresh) -- un nouveau bonus d'index peut changer le revenu
	folder.ChildRemoved:Connect(refresh)
	player.leaderstats.Rebirths.Changed:Connect(refresh)
	player:GetAttributeChangedSignal("DoubleCash"):Connect(refresh)
	BaseManager.refresh(player) -- tout de suite (les gains hors-ligne ont besoin du revenu)
	VipManager.watch(player)

	-- Gains hors-ligne : la base a travaillé pendant ton absence
	local lastSeen = player:GetAttribute("LastSeen") or 0
	local away = os.time() - lastSeen
	if lastSeen > 0 and away >= GameConfig.OFFLINE.MinSeconds then
		local seconds = math.min(away, GameConfig.OFFLINE.MaxHours * 3600)
		local amount = math.floor((player:GetAttribute("Income") or 0) * seconds * GameConfig.OFFLINE.Rate)
		if amount > 0 then
			player.leaderstats.Cash.Value += amount
			task.delay(4, function()
				if player.Parent then
					Remotes.OfflineEarnings:FireClient(player, amount, seconds)
				end
			end)
		end
	end

	local function onCharacter(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then return end
		task.wait(0.1)
		local spawnCFrame = BaseManager.getSpawnCFrame(player)
		if spawnCFrame then
			character:PivotTo(spawnCFrame)
		end
		addGiftPrompt(player, character)
		BatManager.giveBat(player)
		CarpetManager.giveCarpet(player)
		GrappleManager.giveGrapple(player)
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

local lastHit = {}

Players.PlayerRemoving:Connect(function(player)
	BaseManager.release(player) -- l'argent en attente est collecté avant la sauvegarde
	PlayerData.save(player)
	lastHit[player] = nil
end)

-- ====== PARAMÈTRES DU JOUEUR (bouton ⚙️) ======
Remotes.SetSetting.OnServerEvent:Connect(function(player, key, value)
	if typeof(key) ~= "string" or GameConfig.SETTINGS[key] == nil or typeof(value) ~= "boolean" then return end
	player:SetAttribute("Setting_" .. key, value)
end)

-- ====== MINAGE ======
Remotes.MineBlock.OnServerEvent:Connect(function(player, block)
	if typeof(block) ~= "Instance" or not MineManager.isBlock(block) then return end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not character:FindFirstChild("Pioche") then return end
	if (root.Position - block.Position).Magnitude > GameConfig.MINE.MineRange + 4 then return end

	local pickaxeData = GameConfig.getPlayerPickaxe(player)
	-- la Pioche Divine passe partout (même les couches qui demandent la meilleure pioche)
	local tier = pickaxeData.Divine and math.huge or player.PickaxeTier.Value

	local now = os.clock()
	if lastHit[player] and now - lastHit[player] < pickaxeData.Cooldown * 0.8 then return end
	lastHit[player] = now

	local result, errorMessage = MineManager.hit(block, pickaxeData.Damage, tier)
	if errorMessage then
		Remotes.notify(player, errorMessage, "error")
		return
	end
	if not result then return end

	local cash = result.layer.Cash * GameConfig.getWorld(result.world).CashMultiplier * GameConfig.getStarterBoost(player)
	player.leaderstats.Cash.Value += cash
	-- Effet de casse (débris + son) pour tous les joueurs, "+$" pour le mineur
	Remotes.Effect:FireAllClients("Break", {
		Position = result.position,
		Color = result.color,
		Ore = result.ore,
		Chest = result.chest,
		Miner = player.UserId,
		Cash = cash,
	})

	-- Coffre de la mine : un minerai à coup sûr
	if result.chest then
		local mineralId = Loot.rollMineral()
		PlayerData.addMineral(player, mineralId, 1)
		Remotes.MineralFound:FireClient(player, mineralId, "chest")
		task.spawn(PlayerData.save, player)
	end

	-- Minerai brainrot : la carte va dans le SAC (il faut aller la poser dans la base)
	if result.ore then
		local cardName, mutation = Loot.rollMined(pickaxeData.Luck, result.layerIndex, PlayerData.hasLuckPotion(player), result.world)
		local item = PlayerData.addItem(player, cardName, mutation, 0, nil, "a miné")
		if item then
			Remotes.CardFound:FireClient(player, cardName, mutation, item:GetAttribute("Serial"))
		end
	end
end)

-- ====== PRENDRE UNE CARTE EN MAIN ======
local function equipCard(player, item)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not item or not humanoid or item:GetAttribute("Slot") ~= 0 then return end

	-- Une seule carte en main à la fois
	for _, container in ipairs({player:FindFirstChild("Backpack"), character}) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("ItemId") then
					tool:Destroy()
				end
			end
		end
	end

	local tool = buildCardTool(item)
	tool.Parent = player.Backpack
	humanoid:EquipTool(tool)
end
deps.equipCard = equipCard

Remotes.EquipBrainrot.OnServerEvent:Connect(function(player, itemId)
	equipCard(player, PlayerData.findItem(player, itemId))
end)

-- ====== TOUCHE G : REMETTRE LA CARTE TENUE EN MAIN DANS LE SAC ======
local function heldCard(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local item = tool and tool:GetAttribute("ItemId") and PlayerData.findItem(player, tool:GetAttribute("ItemId"))
	return item, tool
end

Remotes.StoreCard.OnServerEvent:Connect(function(player)
	local item = heldCard(player)
	if not item then return end
	PlayerData.destroyHeldTool(player, item.Name)
	Remotes.notify(player, "🎒 " .. item.Value .. " est rangé dans ton sac", "info")
end)

-- ====== DONNER UNE CARTE : carte en main + maintenir E 3 secondes sur un joueur ======
-- (max 3 rebirths d'écart, comme pour les échanges)
local function giveCard(giver, receiver)
	if giver == receiver or not receiver.Parent or not receiver:FindFirstChild("Brainrots") then return end
	local item = heldCard(giver)
	if not item or (item:GetAttribute("Slot") or 0) ~= 0 or item:GetAttribute("StolenBy") then
		Remotes.notify(giver, "Prends d'abord une carte en main (Sac → PRENDRE)", "error")
		return
	end
	local difference = math.abs(giver.leaderstats.Rebirths.Value - receiver.leaderstats.Rebirths.Value)
	if difference > GameConfig.TRADE.MaxRebirthDifference then
		Remotes.notify(giver, "🔒 Trop d'écart de rebirths avec " .. receiver.DisplayName .. " (max " .. GameConfig.TRADE.MaxRebirthDifference .. ")", "error")
		return
	end
	local a = giver.Character and giver.Character:FindFirstChild("HumanoidRootPart")
	local b = receiver.Character and receiver.Character:FindFirstChild("HumanoidRootPart")
	if not a or not b or (a.Position - b.Position).Magnitude > 16 then return end
	PlayerData.destroyHeldTool(giver, item.Name)
	item:SetAttribute("Slot", 0)
	item.Parent = receiver.Brainrots -- la carte garde sa mutation, son numéro et son minerai
	Remotes.notify(giver, "🎁 Tu as donné " .. item.Value .. " à " .. receiver.DisplayName, "success")
	Remotes.notify(receiver, "🎁 " .. giver.DisplayName .. " t'a donné " .. item.Value .. " !", "success")
	Remotes.Effect:FireAllClients("WheelWin", {Position = b.Position, Color = Color3.fromRGB(120, 255, 160)})
	task.spawn(PlayerData.save, giver)
	task.spawn(PlayerData.save, receiver)
end

function addGiftPrompt(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or root:FindFirstChild("GiftPrompt") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GiftPrompt"
	prompt.ActionText = "Donner la carte"
	prompt.ObjectText = player.DisplayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false -- chaque client l'allume quand IL tient une carte (voir Gift.lua)
	prompt.Parent = root
	prompt.Triggered:Connect(function(giver)
		giveCard(giver, player)
	end)
end
deps.addGiftPrompt = addGiftPrompt

-- ====== VENTE DE CARTES ======
local function sell(player, item)
	if not item or item:GetAttribute("Slot") ~= 0 then return 0 end
	local price = GameConfig.getItemSellPrice(item)
	PlayerData.removeItem(player, item)
	player.leaderstats.Cash.Value += price
	return price
end

Remotes.SellBrainrot.OnServerEvent:Connect(function(player, itemId)
	local item = PlayerData.findItem(player, itemId)
	local name = item and item.Value
	local price = sell(player, item)
	if price > 0 then
		Remotes.notify(player, name .. " vendu pour $" .. GameConfig.format(price), "success")
	end
end)

Remotes.SellAll.OnServerEvent:Connect(function(player, rarity)
	if typeof(rarity) ~= "string" or not GameConfig.RARITIES[rarity] then return end
	if GameConfig.RARITIES[rarity].Limited then return end -- les cartes Limited (payantes) ne se vendent pas en lot
	local total, count = 0, 0
	for _, item in ipairs(PlayerData.getItems(player)) do
		local card = GameConfig.getCard(item.Value)
		if card and card.Rarity == rarity and item:GetAttribute("Slot") == 0 then
			total += sell(player, item)
			count += 1
		end
	end
	if count > 0 then
		Remotes.notify(player, count .. " carte(s) vendue(s) pour $" .. GameConfig.format(total), "success")
	end
end)

-- ====== METTRE LES MEILLEURS EN BASE ======
local lastPlaceBest = {}
Remotes.PlaceBest.OnServerEvent:Connect(function(player)
	if lastPlaceBest[player] and os.clock() - lastPlaceBest[player] < 1 then return end
	lastPlaceBest[player] = os.clock()
	BaseManager.placeBest(player)
end)
Players.PlayerRemoving:Connect(function(player)
	lastPlaceBest[player] = nil
end)

-- ====== TELEPORTATION ======
Remotes.Teleport.OnServerEvent:Connect(function(player, destination)
	local character = player.Character
	if not character then return end
	-- avec un brainrot VOLÉ en main : pas de téléportation (sinon le vol est gagné d'avance)
	if BaseManager.isCarrying(player) then
		Remotes.notify(player, "🚫 Pas de téléportation avec un brainrot volé : ramène-le à pied !", "error")
		return
	end
	local target
	if destination == "base" then
		target = BaseManager.getSpawnCFrame(player)
	elseif destination == "mine" then
		target = MineManager.getSurfaceCFrame(player:GetAttribute("World") or 1)
	elseif destination == "shop" then
		target = (player:GetAttribute("World") == 2 and ShopManager.getCrystalVisitCFrame()) or ShopManager.getVisitCFrame()
	elseif destination == "wheel" then
		target = WheelManager.getVisitCFrame()
	end
	if target then
		character:PivotTo(target)
	end
end)

-- ====== REVENU DES BASES (toutes les secondes) ======
task.spawn(function()
	while true do
		task.wait(1)
		BaseManager.tick()
		-- temps de jeu total (sauvegardé) : le guide des débutants disparaît après 5 minutes
		for _, player in ipairs(Players:GetPlayers()) do
			if player:GetAttribute("DataLoaded") ~= false then
				player:SetAttribute("PlayTime", (player:GetAttribute("PlayTime") or 0) + 1)
			end
		end
	end
end)

-- ====== ACHAT DE PIOCHE (seulement à la boutique) ======
Remotes.BuyPickaxe.OnServerEvent:Connect(function(player, tier)
	local pickaxeTier = player.PickaxeTier
	local cash = player.leaderstats.Cash
	if typeof(tier) ~= "number" then return end
	local shopWorld = (PICKAXES[tier] and PICKAXES[tier].World) or 1
	if not ShopManager.isNear(player, shopWorld) then
		Remotes.notify(player, shopWorld == 2 and "Va à la CRISTALLERIE du monde 2 (touche E au comptoir) pour acheter une pioche de cristal" or "Va à la BOUTIQUE (touche E au comptoir) pour acheter une pioche", "error")
		return
	end
	if tier ~= pickaxeTier.Value + 1 then
		Remotes.notify(player, "Achète d'abord la pioche précédente", "error")
		return
	end
	local pickaxeData = PICKAXES[tier]
	if not pickaxeData then return end
	if player.leaderstats.Rebirths.Value < pickaxeData.RequiredRebirths then
		Remotes.notify(player, "🔒 Il faut " .. pickaxeData.RequiredRebirths .. " rebirth(s) pour la " .. pickaxeData.Name, "error")
		return
	end
	if cash.Value < pickaxeData.Cost then
		Remotes.notify(player, "Pas assez d'argent ($" .. GameConfig.format(pickaxeData.Cost) .. ")", "error")
		return
	end

	cash.Value -= pickaxeData.Cost
	pickaxeTier.Value = tier
	givePickaxe(player)
	Remotes.notify(player, "⛏️ Nouvelle pioche : " .. pickaxeData.Name .. " !", "success")
	task.spawn(PlayerData.save, player)
end)

-- ====== REBIRTH ======
Remotes.Rebirth.OnServerEvent:Connect(function(player)
	local leaderstats = player.leaderstats
	if leaderstats.Rebirths.Value >= GameConfig.MAX_REBIRTHS then
		Remotes.notify(player, "🏆 Rebirth MAX (" .. GameConfig.MAX_REBIRTHS .. ") ! Tu as tout débloqué", "success")
		return
	end
	local requirement = GameConfig.getRebirth(leaderstats.Rebirths.Value + 1)

	if leaderstats.Cash.Value < requirement.Cash then
		Remotes.notify(player, "Il te faut $" .. GameConfig.format(requirement.Cash) .. " pour rebirth", "error")
		return
	end

	-- On trouve les brainrots demandés (en priorité ceux de l'inventaire)
	local chosen = {}
	for _, cardName in ipairs(requirement.Cards) do
		local found
		-- (les cartes fusionnées sont prises en dernier)
		for _, preferFused in ipairs({false, true}) do
			for _, preferInventory in ipairs({true, false}) do
				for _, item in ipairs(PlayerData.getItems(player)) do
					local slot = item:GetAttribute("Slot") or 0
					local inInventory = slot == 0
					local fused = GameConfig.getFusion(item) ~= nil
					if not found and slot >= 0 and item.Value == cardName and inInventory == preferInventory and fused == preferFused and not table.find(chosen, item) then
						found = item
					end
				end
			end
		end
		if not found then
			Remotes.notify(player, "Il te manque : " .. cardName, "error")
			return
		end
		table.insert(chosen, found)
	end

	for _, item in ipairs(chosen) do
		PlayerData.removeItem(player, item)
	end
	leaderstats.Cash.Value = 0
	BaseManager.clearPending(player)
	leaderstats.Rebirths.Value += 1
	BaseManager.refresh(player)

	local rebirths = leaderstats.Rebirths.Value
	Remotes.notify(player, "REBIRTH " .. rebirths .. " ! Revenu x" .. GameConfig.getIncomeMultiplier(rebirths) .. " • Verrou " .. GameConfig.getLockDuration(rebirths) .. "s", "success")
	local before = GameConfig.getUnlockedSlotCount(rebirths - 1)
	local after = GameConfig.getUnlockedSlotCount(rebirths)
	if GameConfig.getFloorCount(rebirths) > GameConfig.getFloorCount(rebirths - 1) then
		Remotes.notify(player, "Nouvel étage construit dans ta base !", "success")
	elseif after > before then
		Remotes.notify(player, "+" .. (after - before) .. " emplacements débloqués dans ta base", "success")
	end
	local nextPickaxe = PICKAXES[player.PickaxeTier.Value + 1]
	if nextPickaxe and nextPickaxe.RequiredRebirths == rebirths then
		Remotes.notify(player, nextPickaxe.Name .. " dispo à la boutique", "info")
	end
	task.spawn(PlayerData.save, player)
end)

-- ====== ANNONCE AVANT LA REGENERATION DE LA MINE ======
task.spawn(function()
	local announced = false
	while true do
		task.wait(1)
		local remaining = (Workspace:GetAttribute("MineResetAt") or 0) - Workspace:GetServerTimeNow()
		if remaining <= 15 and remaining > 0 and not announced then
			announced = true
			Remotes.Notify:FireAllClients("⚠️ La mine se régénère dans 15 secondes !", "warning")
		elseif remaining > 15 then
			announced = false
		end
	end
end)
