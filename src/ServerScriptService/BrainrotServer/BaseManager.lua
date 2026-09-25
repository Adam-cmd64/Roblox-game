-- ModuleScript : les bases des joueurs.
--
-- Chaque base a jusqu'à 16 emplacements (8 de chaque côté d'une allée). Sur chaque emplacement :
--   - un podium avec la CARTE du brainrot posée dessus (style carte à collectionner)
--   - au-dessus : la mutation, le nom et le revenu
--   - devant : un bouton "COLLECTER" où l'argent s'accumule (marche dessus pour récupérer)
-- Pour poser un brainrot : prends sa carte en main (inventaire) puis appuie sur E devant un podium libre.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))

local BaseManager = {}

local W, D, H = 40, 72, 18 -- largeur, profondeur, hauteur d'une base
local SLOT_COUNT = GameConfig.BASE.MaxSlots

local CONCRETE = Color3.fromRGB(135, 138, 145)
local WALL = Color3.fromRGB(28, 72, 64)
local SIGN = Color3.fromRGB(225, 140, 55)
local LASER = Color3.fromRGB(255, 35, 35)

local plotsFolder
local plots = {}
local deps -- {PlayerData, Remotes}

local function makePart(parent, name, size, cframe, color, material, studs)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if studs then
		for _, face in ipairs({"Top", "Bottom", "Front", "Back", "Left", "Right"}) do
			part[face .. "Surface"] = Enum.SurfaceType.Studs
		end
	else
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
	end
	part.Parent = parent
	return part
end

local function makeText(parent, value, size, position, color, font)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position or UDim2.new()
	label.Text = value
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = font or Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = parent
	return label
end

-- Position de l'emplacement n°i (en local dans la base). Les impairs à gauche, les pairs à droite.
local function slotLayout(index)
	local side = (index % 2 == 1) and -1 or 1
	local n = math.ceil(index / 2)
	local z = -D / 2 + 13 + (n - 1) * 7.3
	return side, z
end

local function buildSlot(plot, index)
	local side, z = slotLayout(index)
	local at = plot.cframe
	local podiumX = side * (W / 2 - 7)
	local padX = side * (W / 2 - 13)
	local facing = Vector3.new(-side, 0, 0) -- la carte regarde vers l'allée

	local slot = {index = index, pending = 0, item = nil, card = nil}

	slot.podium = makePart(plot.model, "Podium" .. index, Vector3.new(5, 1.2, 5.6), at * CFrame.new(podiumX, 1.6, z), Color3.fromRGB(55, 55, 62), Enum.Material.Metal)
	slot.podiumRim = makePart(plot.model, "PodiumRim", Vector3.new(5.3, 0.25, 5.9), at * CFrame.new(podiumX, 2.25, z), Color3.fromRGB(90, 90, 100), Enum.Material.Neon)
	slot.podiumRim.CanCollide = false

	-- Point où la carte se pose
	local cardPos = (at * CFrame.new(podiumX, 5.6, z)).Position
	local worldFacing = at:VectorToWorldSpace(facing)
	slot.cardCFrame = CFrame.lookAt(cardPos, cardPos + worldFacing) * CFrame.Angles(math.rad(-8), 0, 0)

	-- Infos au-dessus (mutation, nom, revenu)
	local infoAnchor = makePart(plot.model, "InfoAnchor", Vector3.new(0.2, 0.2, 0.2), at * CFrame.new(podiumX, 10.4, z), Color3.new(), nil)
	infoAnchor.Transparency = 1
	infoAnchor.CanCollide = false
	infoAnchor.CanQuery = false
	local info = Instance.new("BillboardGui")
	info.Size = UDim2.new(0, 190, 0, 78)
	info.MaxDistance = 60
	info.Parent = infoAnchor
	slot.mutationLabel = makeText(info, "", UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0, 0))
	slot.mutationGradient = Instance.new("UIGradient")
	slot.mutationGradient.Parent = slot.mutationLabel
	slot.nameLabel = makeText(info, "", UDim2.new(1, 0, 0.34, 0), UDim2.new(0, 0, 0.3, 0))
	slot.incomeLabel = makeText(info, "", UDim2.new(1, 0, 0.34, 0), UDim2.new(0, 0, 0.64, 0), Color3.fromRGB(255, 225, 70))

	-- Bouton COLLECTER au sol
	slot.pad = makePart(plot.model, "CollectPad" .. index, Vector3.new(4.6, 0.3, 5.4), at * CFrame.new(padX, 1.15, z), Color3.fromRGB(60, 220, 90), Enum.Material.Neon)
	local padGui = Instance.new("BillboardGui")
	padGui.Size = UDim2.new(0, 120, 0, 50)
	padGui.StudsOffset = Vector3.new(0, 1.6, 0)
	padGui.MaxDistance = 45
	padGui.Parent = slot.pad
	slot.padTitle = makeText(padGui, "COLLECTER", UDim2.new(1, 0, 0.45, 0))
	slot.padAmount = makeText(padGui, "$0", UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0.45, 0), Color3.fromRGB(120, 255, 120))

	local lastTouch = 0
	slot.pad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or player ~= plot.owner then return end
		if os.clock() - lastTouch < 0.4 then return end
		lastTouch = os.clock()
		BaseManager.collectSlot(plot, slot)
	end)

	-- Cadenas pour les emplacements pas encore débloqués
	local lockGui = Instance.new("BillboardGui")
	lockGui.Size = UDim2.new(0, 150, 0, 50)
	lockGui.StudsOffset = Vector3.new(0, 3.2, 0)
	lockGui.MaxDistance = 45
	lockGui.Parent = slot.podium
	slot.lockLabel = makeText(lockGui, "🔒 Rebirth pour débloquer", UDim2.new(1, 0, 1, 0), nil, Color3.fromRGB(255, 120, 120))

	-- Bouton E : poser / reprendre un brainrot
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Poser un brainrot"
	prompt.ObjectText = "Emplacement " .. index
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Active", true)
	prompt.Parent = slot.podium
	CollectionService:AddTag(prompt, "SlotPrompt")
	slot.prompt = prompt
	prompt.Triggered:Connect(function(player)
		BaseManager.onSlotPrompt(plot, slot, player)
	end)

	return slot
end

local function buildPlot(index, cframe)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("OwnerId", 0)
	model:SetAttribute("Pending", 0)

	local plot = {index = index, model = model, cframe = cframe, owner = nil, slots = {}}

	local function at(x, y, z)
		return cframe * CFrame.new(x, y, z)
	end

	-- Sol + allée rouge
	makePart(model, "Floor", Vector3.new(W, 1, D), at(0, 0.5, 0), CONCRETE, Enum.Material.Concrete, true)
	makePart(model, "Aisle", Vector3.new(8, 0.1, D - 6), at(0, 1.05, 1), Color3.fromRGB(170, 35, 40), Enum.Material.Fabric)
	for _, side in ipairs({-1, 1}) do
		makePart(model, "AisleLine", Vector3.new(0.3, 0.12, D - 6), at(side * 4.2, 1.06, 1), Color3.new(1, 1, 1), Enum.Material.Neon)
	end

	-- Murs
	makePart(model, "WallLeft", Vector3.new(1, H + 3, D - 4), at(-W / 2 + 0.5, (H + 3) / 2 + 1, 1), WALL)
	makePart(model, "WallRight", Vector3.new(1, H + 3, D - 4), at(W / 2 - 0.5, (H + 3) / 2 + 1, 1), WALL)
	makePart(model, "WallBack", Vector3.new(W, H + 3, 1), at(0, (H + 3) / 2 + 1, D / 2 - 0.5), WALL)

	-- Piliers en béton
	for _, x in ipairs({-W / 2 + 2, W / 2 - 2}) do
		for _, z in ipairs({-D / 2 + 2, 0, D / 2 - 2}) do
			makePart(model, "Pillar", Vector3.new(4, H + 4, 4), at(x, (H + 4) / 2 + 1, z), CONCRETE, Enum.Material.Concrete, true)
		end
	end

	makePart(model, "Roof", Vector3.new(W + 2, 2, D + 2), at(0, H + 5, 0), CONCRETE, Enum.Material.Concrete, true)

	-- Néons au plafond
	for z = -D / 2 + 12, D / 2 - 8, 14 do
		local lamp = makePart(model, "CeilingLight", Vector3.new(10, 0.3, 1.2), at(0, H + 3.8, z), Color3.new(1, 1, 1), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1.1
		light.Parent = lamp
	end

	-- Façade : poutre + panneau orange avec le nom et le revenu
	makePart(model, "FrontBeam", Vector3.new(W - 4, 5, 3), at(0, H + 1.5, -D / 2 + 2), CONCRETE, Enum.Material.Concrete, true)
	local border = makePart(model, "SignBorder", Vector3.new(W - 10, 6.4, 0.4), at(0, H - 2.2, -D / 2 + 0.9), Color3.fromRGB(150, 85, 35), Enum.Material.SmoothPlastic, true)
	border.CanCollide = false
	local sign = makePart(model, "Sign", Vector3.new(W - 11, 5.4, 0.6), at(0, H - 2.2, -D / 2 + 0.5), SIGN, Enum.Material.SmoothPlastic)
	sign.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = sign
	plot.signName = makeText(gui, "Base libre", UDim2.new(0.94, 0, 0.58, 0), UDim2.new(0.03, 0, 0.04, 0))
	plot.signIncome = makeText(gui, "", UDim2.new(0.94, 0, 0.34, 0), UDim2.new(0.03, 0, 0.62, 0), Color3.fromRGB(255, 250, 200))

	-- Lasers rouges : seul le propriétaire peut passer (géré côté client)
	local laserFolder = Instance.new("Folder")
	laserFolder.Name = "Lasers"
	laserFolder.Parent = model
	makePart(model, "LaserBase", Vector3.new(W - 8, 0.6, 1.2), at(0, 1.3, -D / 2 + 2), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	makePart(model, "LaserTop", Vector3.new(W - 8, 0.8, 1.2), at(0, H - 5.8, -D / 2 + 2), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	local laserHeight = H - 7.8
	for x = -W / 2 + 5, W / 2 - 5, 2 do
		local laser = makePart(laserFolder, "Laser", Vector3.new(0.35, laserHeight, 0.35), at(x, 1.6 + laserHeight / 2, -D / 2 + 2), LASER, Enum.Material.Neon)
		laser.CastShadow = false
	end
	local glow = makePart(model, "LaserGlow", Vector3.new(1, 1, 1), at(0, 6, -D / 2 + 3), LASER)
	glow.Transparency = 1
	glow.CanCollide = false
	glow.CanQuery = false
	local light = Instance.new("PointLight")
	light.Color = LASER
	light.Range = 16
	light.Brightness = 2
	light.Parent = glow

	-- Tapis vert devant l'entrée
	makePart(model, "WelcomeMat", Vector3.new(14, 0.3, 4), at(0, 0.15, -D / 2 - 2.5), Color3.fromRGB(60, 220, 90), Enum.Material.Neon)

	model.Parent = plotsFolder

	for slotIndex = 1, SLOT_COUNT do
		plot.slots[slotIndex] = buildSlot(plot, slotIndex)
	end

	return plot
end

-- ====== CARTE POSEE SUR UN PODIUM ======
local function clearSlotVisual(slot)
	if slot.card then
		slot.card:Destroy()
		slot.card = nil
	end
	slot.shownKey = nil
end

local function showCard(slot, cardName, mutation)
	local key = cardName .. "|" .. mutation
	if slot.shownKey == key then return end
	clearSlotVisual(slot)
	slot.shownKey = key

	local card = GameConfig.getCard(cardName)
	local rarity = GameConfig.RARITIES[card.Rarity]

	local part = Instance.new("Part")
	part.Name = "CardDisplay"
	part.Size = Vector3.new(4.3, 6.02, 0.2)
	part.CFrame = slot.cardCFrame
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Color = rarity.Color2
	part.Material = Enum.Material.SmoothPlastic

	local front = Instance.new("SurfaceGui")
	front.Face = Enum.NormalId.Front
	front.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	front.PixelsPerStud = 60
	front.LightInfluence = 0
	front.Parent = part
	CardRenderer.create(cardName, mutation, front)

	-- Petite lumière de la couleur de la rareté pour les cartes rares
	if rarity.Order >= 4 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 10
		light.Brightness = 1.5
		light.Parent = part
	end

	-- Effet de la mutation : particules autour de la carte
	local mutationData = GameConfig.MUTATIONS[mutation]
	if mutationData and mutationData.Colors then
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(mutationData.Colors[1], mutationData.Colors[2])
		particles.LightEmission = 1
		particles.Size = NumberSequence.new(0.35, 0)
		particles.Lifetime = NumberRange.new(0.8, 1.4)
		particles.Rate = 14
		particles.Speed = NumberRange.new(1, 2.5)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Parent = part
	end

	part.Parent = slot.podium.Parent
	slot.card = part
end

-- Met à jour toute la base d'un joueur (appelé quand ses brainrots / rebirths changent)
function BaseManager.refresh(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	local rebirths = player.leaderstats.Rebirths.Value
	local unlocked = GameConfig.getSlotCount(rebirths)
	local multiplier = GameConfig.getIncomeMultiplier(rebirths)

	local placed = {}
	for _, item in ipairs(deps.PlayerData.getItems(player)) do
		local slotIndex = item:GetAttribute("Slot") or 0
		if slotIndex > 0 then
			placed[slotIndex] = item
		end
	end

	local totalIncome = 0
	for index, slot in ipairs(plot.slots) do
		local item = placed[index]
		slot.item = item
		local isUnlocked = index <= unlocked
		slot.lockLabel.Parent.Enabled = not isUnlocked
		slot.podiumRim.Color = isUnlocked and Color3.fromRGB(90, 200, 255) or Color3.fromRGB(90, 40, 40)
		slot.pad.Color = isUnlocked and Color3.fromRGB(60, 220, 90) or Color3.fromRGB(70, 70, 70)
		slot.pad.Material = isUnlocked and Enum.Material.Neon or Enum.Material.SmoothPlastic
		slot.padTitle.Parent.Enabled = isUnlocked

		if item then
			local mutation = item:GetAttribute("Mutation") or "Normal"
			local income = GameConfig.getItemIncome(item.Value, mutation) * multiplier
			totalIncome += income
			showCard(slot, item.Value, mutation)
			local card = GameConfig.getCard(item.Value)
			local rarity = GameConfig.RARITIES[card.Rarity]
			slot.nameLabel.Text = item.Value
			slot.nameLabel.TextColor3 = rarity.Color
			slot.incomeLabel.Text = "$" .. GameConfig.format(income) .. "/s"
			local mutationSeq = CardRenderer.mutationSequence(mutation)
			if mutation ~= "Normal" and mutationSeq then
				slot.mutationLabel.Text = "✦ " .. mutation .. " ✦"
				slot.mutationLabel.TextColor3 = Color3.new(1, 1, 1)
				slot.mutationGradient.Color = mutationSeq
				slot.mutationGradient.Enabled = true
				if GameConfig.MUTATIONS[mutation].Rainbow then
					CollectionService:AddTag(slot.mutationGradient, "RainbowGradient")
				end
			else
				slot.mutationLabel.Text = card.Rarity
				slot.mutationLabel.TextColor3 = rarity.Color
				slot.mutationGradient.Enabled = false
				CollectionService:RemoveTag(slot.mutationGradient, "RainbowGradient")
			end
			slot.prompt.ActionText = "Reprendre"
			slot.prompt.ObjectText = item.Value
		else
			clearSlotVisual(slot)
			slot.nameLabel.Text = ""
			slot.incomeLabel.Text = ""
			slot.mutationLabel.Text = ""
			slot.mutationGradient.Enabled = false
			slot.prompt.ActionText = isUnlocked and "Poser un brainrot" or "Verrouillé"
			slot.prompt.ObjectText = "Emplacement " .. index
		end
		slot.prompt:SetAttribute("Active", isUnlocked) -- le client affiche le bouton seulement dans SA base
	end

	plot.signIncome.Text = "💰 $" .. GameConfig.format(totalIncome) .. "/s"
end

-- ====== POSER / REPRENDRE ======
function BaseManager.onSlotPrompt(plot, slot, player)
	if plot.owner ~= player then return end
	local PlayerData = deps.PlayerData
	local unlocked = GameConfig.getSlotCount(player.leaderstats.Rebirths.Value)
	if slot.index > unlocked then
		deps.Remotes.notify(player, "🔒 Cet emplacement se débloque avec un rebirth", "error")
		return
	end

	local placed = PlayerData.getPlacedItem(player, slot.index)
	if placed then
		-- Reprendre : l'argent en attente est collecté, la carte retourne dans l'inventaire
		BaseManager.collectSlot(plot, slot)
		placed:SetAttribute("Slot", 0)
		deps.Remotes.notify(player, "↩️ " .. placed.Value .. " est retourné dans ton inventaire", "info")
		BaseManager.refresh(player)
		return
	end

	-- Poser : il faut tenir une carte en main
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local itemId = tool and tool:GetAttribute("ItemId")
	local item = itemId and PlayerData.findItem(player, itemId)
	if not item or item:GetAttribute("Slot") ~= 0 then
		deps.Remotes.notify(player, "Prends d'abord une carte en main depuis ton 🎒 Inventaire", "error")
		return
	end

	item:SetAttribute("Slot", slot.index)
	PlayerData.destroyHeldTool(player, item.Name)
	deps.Remotes.notify(player, "✅ " .. item.Value .. " posé dans ta base !", "success")
	BaseManager.refresh(player)
end

-- ====== ARGENT ======
function BaseManager.collectSlot(plot, slot)
	local owner = plot.owner
	if not owner then return end
	local amount = math.floor(slot.pending)
	if amount <= 0 then return end
	slot.pending -= amount
	owner.leaderstats.Cash.Value += amount
	slot.padAmount.Text = "$0"
	deps.Remotes.Collected:FireClient(owner, amount, slot.pad.Position)
end

function BaseManager.collectAll(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	for _, slot in ipairs(plot.slots) do
		BaseManager.collectSlot(plot, slot)
	end
end

function BaseManager.clearPending(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	for _, slot in ipairs(plot.slots) do
		slot.pending = 0
		slot.padAmount.Text = "$0"
	end
	plot.model:SetAttribute("Pending", 0)
end

-- Appelé chaque seconde : l'argent s'accumule sur chaque bouton COLLECTER
function BaseManager.tick()
	for _, plot in ipairs(plots) do
		local owner = plot.owner
		if owner and owner.Parent then
			local multiplier = GameConfig.getIncomeMultiplier(owner.leaderstats.Rebirths.Value)
			local total = 0
			for _, slot in ipairs(plot.slots) do
				local item = slot.item
				if item and item.Parent then
					slot.pending += GameConfig.getItemIncome(item.Value, item:GetAttribute("Mutation")) * multiplier
					slot.padAmount.Text = "$" .. GameConfig.format(slot.pending)
				end
				total += slot.pending
			end
			plot.model:SetAttribute("Pending", math.floor(total))
		end
	end
end

-- ====== ATTRIBUTION DES BASES ======
function BaseManager.init(dependencies)
	deps = dependencies
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace

	-- 2 rangées de bases face à face, la mine au milieu
	local count = GameConfig.BASE.PlotCount
	local perRow = math.ceil(count / 2)
	local spacing = W + 12
	local distance = dependencies.MineHalf + 3 + 26 + D / 2
	for index = 1, count do
		local row = index <= perRow and -1 or 1
		local col = (index - 1) % perRow
		local x = (col - (perRow - 1) / 2) * spacing
		local position = Vector3.new(x, 0, row * distance)
		local cframe = CFrame.lookAt(position, Vector3.new(x, 0, 0)) -- l'entrée regarde vers la mine
		table.insert(plots, buildPlot(index, cframe))
	end
end

function BaseManager.getPlot(player)
	for _, plot in ipairs(plots) do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

function BaseManager.assign(player)
	for _, plot in ipairs(plots) do
		if not plot.owner then
			plot.owner = player
			plot.model:SetAttribute("OwnerId", player.UserId)
			plot.signName.Text = "Base de " .. player.DisplayName
			for _, slot in ipairs(plot.slots) do
				slot.pending = 0
			end
			return plot
		end
	end
	return nil
end

function BaseManager.release(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	BaseManager.collectAll(player)
	plot.owner = nil
	plot.model:SetAttribute("OwnerId", 0)
	plot.model:SetAttribute("Pending", 0)
	plot.signName.Text = "Base libre"
	plot.signIncome.Text = ""
	for _, slot in ipairs(plot.slots) do
		slot.item = nil
		slot.pending = 0
		slot.padAmount.Text = "$0"
		clearSlotVisual(slot)
		slot.nameLabel.Text = ""
		slot.incomeLabel.Text = ""
		slot.mutationLabel.Text = ""
	end
end

-- Point d'apparition dans la base (derrière les lasers, tourné vers l'intérieur)
function BaseManager.getSpawnCFrame(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return nil end
	return plot.cframe * CFrame.new(0, 4, -D / 2 + 7) * CFrame.Angles(0, math.rad(180), 0)
end

return BaseManager
