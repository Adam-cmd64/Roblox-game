local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PICKAXES = GameConfig.PICKAXES
local CARDS = GameConfig.CARDS

-- ====== REMOTE EVENTS (créés automatiquement, rien à faire à la main) ======
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
local CardFound = getRemote("CardFound") -- serveur -> client : affiche la carte obtenue
local Notify = getRemote("Notify") -- serveur -> client : message d'erreur / info

local rockFolder = Instance.new("Folder")
rockFolder.Name = "Rocks"
rockFolder.Parent = Workspace

local currentRockCount = 0

-- ====== SETUP JOUEUR ======
local function givePickaxeTool(player, tier)
	local pickaxeData = PICKAXES[tier] or PICKAXES[1]

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		local old = backpack:FindFirstChild("Pioche")
		if old then old:Destroy() end
	end
	if player.Character then
		local old = player.Character:FindFirstChild("Pioche")
		if old then old:Destroy() end
	end

	-- Petite pioche visuelle (manche + tête) pour le style Minecraft
	local tool = Instance.new("Tool")
	tool.Name = "Pioche"
	tool.ToolTip = pickaxeData.Name
	tool.CanBeDropped = false
	tool.GripPos = Vector3.new(0, -1, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 3, 0.3)
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(120, 80, 40)
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.4, 0.4, 0.4)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = pickaxeData.Color
	head.CanCollide = false
	head.Massless = true
	head.CFrame = handle.CFrame * CFrame.new(0, 1.4, 0)
	head.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = handle

	tool.Parent = backpack
end

Players.PlayerAdded:Connect(function(player)
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
		countValue.Parent = cardsFolder
	end
	cardsFolder.Parent = player

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		givePickaxeTool(player, pickaxeTier.Value)
	end)
	if player.Character then
		givePickaxeTool(player, pickaxeTier.Value)
	end
end)

-- ====== TIRAGE ALEATOIRE D'UNE CARTE ======
local function pickRandomCard()
	local totalWeight = 0
	for _, c in ipairs(CARDS) do
		totalWeight += c.Weight
	end
	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, c in ipairs(CARDS) do
		cumulative += c.Weight
		if roll <= cumulative then
			return c
		end
	end
	return CARDS[1]
end

local function randomPosition()
	return Vector3.new(math.random(-40, 40), 2.5, math.random(-40, 40))
end

-- Petit effet visuel quand un rocher explose : des débris qui volent
local function spawnDebris(position, color)
	for _ = 1, 6 do
		local chunk = Instance.new("Part")
		chunk.Size = Vector3.new(1, 1, 1)
		chunk.Material = Enum.Material.Slate
		chunk.Color = color
		chunk.CanCollide = false
		chunk.Position = position
		chunk.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), math.random(20, 35), math.random(-20, 20))
		chunk.Parent = Workspace
		Debris:AddItem(chunk, 1.5)
	end
end

-- ====== SPAWN D'UN ROCHER MINABLE ======
local function spawnRock()
	if currentRockCount >= GameConfig.MAX_ROCKS then return end

	local maxHp = GameConfig.ROCK_MAX_HP

	local part = Instance.new("Part")
	part.Name = "Rock"
	part.Size = Vector3.new(5, 5, 5)
	part.Anchored = true
	part.CanCollide = true
	part.Material = Enum.Material.Slate
	part.Color = Color3.fromRGB(120, 120, 120)
	part.Position = randomPosition()
	part:SetAttribute("HP", maxHp)

	-- Pépites colorées pour que le rocher ressemble à un minerai
	for _ = 1, 4 do
		local ore = Instance.new("Part")
		ore.Size = Vector3.new(1, 1, 1)
		ore.Anchored = true
		ore.CanCollide = false
		ore.Material = Enum.Material.Neon
		ore.Color = CARDS[math.random(1, #CARDS)].Color
		local face = Vector3.new(math.random(-1, 1), math.random(0, 1), math.random(-1, 1)).Unit
		if face ~= face then face = Vector3.new(0, 1, 0) end -- NaN si vecteur nul
		ore.Position = part.Position + face * 2.5
		ore.Parent = part
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 60
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "⛏️ " .. maxHp .. "/" .. maxHp
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = GameConfig.MINE_DISTANCE
	clickDetector.Parent = part

	part.Parent = rockFolder
	currentRockCount += 1

	local broken = false
	clickDetector.MouseClick:Connect(function(player)
		if broken then return end

		local pickaxeTier = player:FindFirstChild("PickaxeTier")
		local pickaxeData = PICKAXES[pickaxeTier and pickaxeTier.Value or 1] or PICKAXES[1]

		local hp = part:GetAttribute("HP") - pickaxeData.Damage
		part:SetAttribute("HP", hp)

		if hp > 0 then
			label.Text = "⛏️ " .. hp .. "/" .. maxHp
			return
		end

		-- Rocher détruit : on donne une carte au joueur
		broken = true
		local card = pickRandomCard()
		local cardsFolder = player:FindFirstChild("Cards")
		local countValue = cardsFolder and cardsFolder:FindFirstChild(card.Name)
		if countValue then
			countValue.Value += 1
		end
		CardFound:FireClient(player, card.Name)

		spawnDebris(part.Position, part.Color)
		part:Destroy()
		currentRockCount -= 1

		task.delay(GameConfig.ROCK_RESPAWN_TIME, spawnRock)
	end)
end

-- Spawn initial des rochers
task.spawn(function()
	for _ = 1, GameConfig.MAX_ROCKS do
		spawnRock()
		task.wait(0.2)
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
	local multiplier = 1 + leaderstats.Rebirths.Value * GameConfig.REBIRTH_INCOME_MULT_BONUS
	return math.floor(income * multiplier)
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
	givePickaxeTool(player, pickaxeTier.Value)
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
	Notify:FireClient(player, "REBIRTH ! Revenu x" .. (1 + leaderstats.Rebirths.Value * GameConfig.REBIRTH_INCOME_MULT_BONUS))
end)
