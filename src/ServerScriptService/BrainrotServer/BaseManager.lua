-- ModuleScript : les bases des joueurs.
--
-- Rez-de-chaussée : 8 emplacements (4 de chaque côté de l'allée).
-- Les rebirths construisent des ÉTAGES (voir GameConfig.FLOORS) : chaque étage a 6 emplacements,
-- le côté gauche se débloque quand l'étage apparaît, le côté droit à un rebirth suivant.
-- On monte / descend avec les plateformes d'ascenseur au fond de la base.
--
-- Les murs ont des fenêtres (comme dans Steal a Brainrot) et chaque base a sa couleur.
--
-- VERROU : un bouton au sol, juste devant le spawn, allume les lasers pendant 40s (+10s par rebirth).
-- Quand la base est ouverte, les autres joueurs peuvent entrer et VOLER un brainrot (maintenir E),
-- puis doivent le ramener dans leur propre base. Un coup de batte leur fait lâcher.
--
-- Sur chaque emplacement : un podium avec la grande CARTE du brainrot (dessinée côté client),
-- le revenu au-dessus, et un bouton COLLECTER au sol où l'argent s'accumule.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local BaseManager = {}
local carrying = {} -- carrying[voleur] = {item, owner, slot, visual, started, speed}

local W, D = 40, 48 -- largeur, profondeur d'une base
local FH = 15 -- hauteur d'un étage
BaseManager.WIDTH = W
BaseManager.DEPTH = D

local FLOOR = Color3.fromRGB(205, 205, 210)
local WALL = Color3.fromRGB(240, 240, 235)
local GLASS = Color3.fromRGB(170, 215, 255)
local DARK = Color3.fromRGB(45, 48, 58)
local LASER = Color3.fromRGB(255, 35, 35)
-- Chaque base a sa couleur (piliers, toit, tapis)
local ACCENTS = {
	Color3.fromRGB(70, 150, 255), Color3.fromRGB(255, 90, 90), Color3.fromRGB(80, 200, 110), Color3.fromRGB(255, 190, 50),
	Color3.fromRGB(170, 100, 255), Color3.fromRGB(255, 140, 50), Color3.fromRGB(255, 110, 190), Color3.fromRGB(40, 200, 210),
}

local CARD_SIZE = Vector3.new(4.4, 4.4 / (5 / 8), 0.25) -- carte au format 5:8

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
		part.TopSurface = Enum.SurfaceType.Studs
		part.BottomSurface = Enum.SurfaceType.Inlet
	else
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
	end
	part.Parent = parent
	return part
end

local function makeText(parent, value, size, position, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position or UDim2.new()
	label.Text = value
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = parent
	return label
end

local function levelY(level)
	return 1 + level * FH -- hauteur du sol de cet étage
end

-- Un mur avec une rangée de fenêtres (comme dans Steal a Brainrot).
-- cframe = centre du mur au niveau du sol, length = longueur, le mur est le long de l'axe X local.
local function windowWall(parent, cframe, length, accent)
	local sill, windowHeight = 3.5, 8
	local top = FH - sill - windowHeight
	makePart(parent, "WallLow", Vector3.new(length, sill, 1), cframe * CFrame.new(0, sill / 2, 0), WALL)
	makePart(parent, "WallHigh", Vector3.new(length, top, 1), cframe * CFrame.new(0, FH - top / 2, 0), WALL)
	makePart(parent, "Sill", Vector3.new(length, 0.5, 1.6), cframe * CFrame.new(0, sill, 0), accent)
	makePart(parent, "Lintel", Vector3.new(length, 0.5, 1.4), cframe * CFrame.new(0, sill + windowHeight, 0), accent)
	local glass = makePart(parent, "Window", Vector3.new(length, windowHeight, 0.3), cframe * CFrame.new(0, sill + windowHeight / 2, 0), GLASS, Enum.Material.Glass)
	glass.Transparency = 0.6
	glass.CastShadow = false
	local panes = math.max(1, math.floor(length / 8 + 0.5))
	for i = 1, panes - 1 do
		local x = -length / 2 + i * length / panes
		makePart(parent, "Mullion", Vector3.new(0.6, windowHeight, 0.9), cframe * CFrame.new(x, sill + windowHeight / 2, 0), WALL)
	end
end

-- Les murs, les piliers et les lumières douces d'un niveau (rez-de-chaussée ou étage)
local function buildShell(parent, at, y0, accent)
	-- côtés (entre les piliers) et fond
	windowWall(parent, at * CFrame.new(-W / 2 + 0.5, y0, 0) * CFrame.Angles(0, math.rad(90), 0), D - 8, accent)
	windowWall(parent, at * CFrame.new(W / 2 - 0.5, y0, 0) * CFrame.Angles(0, math.rad(-90), 0), D - 8, accent)
	windowWall(parent, at * CFrame.new(0, y0, D / 2 - 0.5), W - 8, accent)
	for _, x in ipairs({-W / 2 + 2, W / 2 - 2}) do
		for _, z in ipairs({-D / 2 + 2, D / 2 - 2}) do
			makePart(parent, "Pillar", Vector3.new(4, FH, 4), at * CFrame.new(x, y0 + FH / 2, z), accent, Enum.Material.SmoothPlastic, true)
		end
	end
	-- lumière douce au plafond (pas de néon)
	for _, z in ipairs({-D / 4, D / 4}) do
		local panel = makePart(parent, "CeilingPanel", Vector3.new(8, 0.2, 3), at * CFrame.new(0, y0 + FH - 0.1, z), Color3.fromRGB(250, 250, 245))
		panel.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 0.6
		light.Shadows = false
		light.Parent = panel
	end
end

-- ============================================================
-- EMPLACEMENT
-- ============================================================
local function buildSlot(plot, index, parent)
	local info = GameConfig.getSlotInfo(index)
	local side = info.Side
	local z = -D / 2 + 14 + (info.Row - 1) * 7.5
	local y0 = levelY(info.Floor)
	local at = plot.cframe
	local podiumX = side * (W / 2 - 7)
	local padX = side * (W / 2 - 13)

	local slot = {index = index, info = info, pending = 0, item = nil, card = nil}

	slot.podium = makePart(parent, "Podium" .. index, Vector3.new(5, 1.2, 5.6), at * CFrame.new(podiumX, y0 + 0.6, z), DARK, Enum.Material.SmoothPlastic)
	slot.podiumRim = makePart(parent, "PodiumRim", Vector3.new(5.3, 0.25, 5.9), at * CFrame.new(podiumX, y0 + 1.25, z), plot.accent)
	slot.podiumRim.CanCollide = false

	-- La carte est debout sur le podium, tournée vers l'allée (dessinée côté client)
	local facing = at:VectorToWorldSpace(Vector3.new(-side, 0, 0))
	local cardPos = (at * CFrame.new(podiumX, y0 + 1.4 + CARD_SIZE.Y / 2, z)).Position
	slot.cardCFrame = CFrame.lookAt(cardPos, cardPos + facing) * CFrame.Angles(math.rad(-5), 0, 0)
	slot.parent = parent

	-- Revenu + nom + mutation au-dessus de la carte
	local infoAnchor = makePart(parent, "InfoAnchor", Vector3.new(0.2, 0.2, 0.2), at * CFrame.new(podiumX, y0 + CARD_SIZE.Y + 3.4, z), Color3.new(), nil)
	infoAnchor.Transparency = 1
	infoAnchor.CanCollide = false
	infoAnchor.CanQuery = false
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 190, 0, 78)
	billboard.MaxDistance = 55
	billboard.Parent = infoAnchor
	slot.incomeLabel = makeText(billboard, "", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 230, 70))
	slot.nameLabel = makeText(billboard, "", UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0.4, 0))
	slot.mutationLabel = makeText(billboard, "", UDim2.new(1, 0, 0.28, 0), UDim2.new(0, 0, 0.71, 0))
	slot.mutationGradient = Instance.new("UIGradient")
	slot.mutationGradient.Enabled = false
	slot.mutationGradient.Parent = slot.mutationLabel

	-- Bouton COLLECTER
	slot.pad = makePart(parent, "CollectPad" .. index, Vector3.new(4.6, 0.3, 5.4), at * CFrame.new(padX, y0 + 0.15, z), Color3.fromRGB(70, 210, 100))
	local padGui = Instance.new("BillboardGui")
	padGui.Size = UDim2.new(0, 120, 0, 50)
	padGui.StudsOffset = Vector3.new(0, 1.6, 0)
	padGui.MaxDistance = 40
	padGui.Parent = slot.pad
	slot.padGui = padGui
	makeText(padGui, "COLLECTER", UDim2.new(1, 0, 0.45, 0))
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

	-- Cadenas
	local lockGui = Instance.new("BillboardGui")
	lockGui.Size = UDim2.new(0, 160, 0, 46)
	lockGui.StudsOffset = Vector3.new(0, 3.2, 0)
	lockGui.MaxDistance = 45
	lockGui.Parent = slot.podium
	slot.lockGui = lockGui
	slot.lockLabel = makeText(lockGui, "🔒 Rebirth " .. info.Required, UDim2.new(1, 0, 1, 0), nil, Color3.fromRGB(255, 110, 110))

	-- Bouton E : poser / reprendre
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Poser un brainrot"
	prompt.ObjectText = "Emplacement " .. index
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Active", true)
	prompt.Parent = slot.podium
	slot.prompt = prompt
	prompt.Triggered:Connect(function(player)
		BaseManager.onSlotPrompt(plot, slot, player)
	end)

	-- Bouton E (maintenir) : voler le brainrot (visible seulement pour les autres joueurs)
	local steal = Instance.new("ProximityPrompt")
	steal.Name = "StealPrompt"
	steal.ActionText = "Voler"
	steal.ObjectText = ""
	steal.KeyboardKeyCode = Enum.KeyCode.E
	steal.HoldDuration = GameConfig.STEAL.HoldDuration
	steal.MaxActivationDistance = 9
	steal.RequiresLineOfSight = false
	steal:SetAttribute("Steal", true)
	steal:SetAttribute("Active", false)
	steal.Parent = slot.podium
	slot.stealPrompt = steal
	steal.Triggered:Connect(function(player)
		BaseManager.startSteal(plot, slot, player)
	end)

	plot.slots[index] = slot
	return slot
end

-- ============================================================
-- ASCENSEUR (plateformes au fond de chaque étage)
-- ============================================================
local function arrivalCFrame(plot, level)
	return plot.cframe * CFrame.new(0, levelY(level) + 3, D / 2 - 12)
end

local function makeLiftPad(plot, parent, level, direction)
	local x = direction > 0 and -6 or 6
	local color = direction > 0 and Color3.fromRGB(60, 170, 255) or Color3.fromRGB(255, 150, 50)
	local pad = makePart(parent, direction > 0 and "LiftUp" or "LiftDown", Vector3.new(5, 0.4, 5), plot.cframe * CFrame.new(x, levelY(level) + 0.2, D / 2 - 4.5), color)
	local beam = makePart(parent, "LiftBeam", Vector3.new(4.6, 7, 4.6), pad.CFrame * CFrame.new(0, 3.7, 0), color, Enum.Material.ForceField)
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Transparency = 0.3

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 170, 0, 40)
	gui.StudsOffset = Vector3.new(0, 5.2, 0)
	gui.MaxDistance = 50
	gui.Parent = pad
	local target = level + direction
	makeText(gui, (direction > 0 and "⬆ " or "⬇ ") .. (target == 0 and "REZ-DE-CHAUSSÉE" or ("ÉTAGE " .. target)), UDim2.new(1, 0, 1, 0), nil, color)

	local debounce = {}
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or player ~= plot.owner or debounce[player] then return end
		debounce[player] = true
		character:PivotTo(arrivalCFrame(plot, target))
		task.delay(1, function()
			debounce[player] = nil
		end)
	end)
end

-- ============================================================
-- ETAGES
-- ============================================================
local function buildLevel(plot, level)
	local model = Instance.new("Model")
	model.Name = "Level" .. level
	local at = plot.cframe
	local y0 = levelY(level)

	-- Dalle du sol de l'étage + tapis
	makePart(model, "Slab", Vector3.new(W, 1, D), at * CFrame.new(0, y0 - 0.5, 0), FLOOR, Enum.Material.SmoothPlastic, true)
	makePart(model, "Aisle", Vector3.new(8, 0.1, D - 8), at * CFrame.new(0, y0 + 0.05, 1), plot.accent:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.Fabric)

	buildShell(model, at, y0, plot.accent)

	-- Balcon vitré à l'avant
	local glass = makePart(model, "Railing", Vector3.new(W - 8, 3.5, 0.4), at * CFrame.new(0, y0 + 1.75, -D / 2 + 1), GLASS, Enum.Material.Glass)
	glass.Transparency = 0.5
	makePart(model, "RailingTop", Vector3.new(W - 8, 0.4, 0.8), at * CFrame.new(0, y0 + 3.6, -D / 2 + 1), plot.accent)
	makePart(model, "FrontBeam", Vector3.new(W - 4, 2.5, 3), at * CFrame.new(0, y0 + FH - 1.25, -D / 2 + 2), WALL)

	-- Ascenseur : on monte depuis l'étage du dessous, on redescend depuis celui-ci
	makeLiftPad(plot, model, level - 1, 1)
	makeLiftPad(plot, model, level, -1)

	model.Parent = plot.model

	local perFloor = GameConfig.BASE.FloorSlotsPerSide * 2
	local first = GameConfig.BASE.GroundSlots + (level - 1) * perFloor + 1
	for index = first, first + perFloor - 1 do
		buildSlot(plot, index, model)
	end

	plot.levels[level] = model
	plot.roof.CFrame = at * CFrame.new(0, levelY(level + 1) + 1, 0)
end

local function removeLevels(plot)
	for level, model in pairs(plot.levels) do
		model:Destroy()
		plot.levels[level] = nil
	end
	for index, slot in pairs(plot.slots) do
		if slot.info.Floor > 0 then
			plot.slots[index] = nil
		end
	end
	plot.roof.CFrame = plot.cframe * CFrame.new(0, levelY(1) + 1, 0)
end

local function ensureLevels(plot, count)
	local built = false
	for level = 1, count do
		if not plot.levels[level] then
			buildLevel(plot, level)
			built = true
		end
	end
	return built
end

-- ============================================================
-- REZ-DE-CHAUSSEE (toujours présent)
-- ============================================================
local function buildPlot(index, cframe)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("OwnerId", 0)
	model:SetAttribute("Pending", 0)

	local accent = ACCENTS[(index - 1) % #ACCENTS + 1]
	local plot = {index = index, model = model, cframe = cframe, owner = nil, slots = {}, levels = {}, accent = accent}

	local function at(x, y, z)
		return cframe * CFrame.new(x, y, z)
	end

	makePart(model, "Floor", Vector3.new(W, 1, D), at(0, 0.5, 0), FLOOR, Enum.Material.SmoothPlastic, true)
	makePart(model, "Aisle", Vector3.new(8, 0.1, D - 6), at(0, 1.05, 1), accent:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.Fabric)
	for _, side in ipairs({-1, 1}) do
		makePart(model, "AisleLine", Vector3.new(0.3, 0.12, D - 6), at(side * 4.2, 1.06, 1), Color3.new(1, 1, 1))
	end

	buildShell(model, cframe, 1, accent)
	plot.roof = makePart(model, "Roof", Vector3.new(W + 2, 2, D + 2), at(0, levelY(1) + 1, 0), accent, Enum.Material.SmoothPlastic, true)

	-- Façade : le nom du propriétaire et le revenu, écrits sur la poutre au-dessus de l'entrée
	local beam = makePart(model, "FrontBeam", Vector3.new(W - 4, 3, 3), at(0, FH - 0.5, -D / 2 + 2), WALL)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = beam
	plot.signName = makeText(gui, "Base libre", UDim2.new(0.8, 0, 0.56, 0), UDim2.new(0.1, 0, 0.04, 0), accent)
	plot.signName.TextStrokeColor3 = Color3.fromRGB(30, 30, 40)
	plot.signIncome = makeText(gui, "", UDim2.new(0.8, 0, 0.36, 0), UDim2.new(0.1, 0, 0.6, 0), Color3.fromRGB(60, 170, 70))
	plot.signIncome.TextStrokeTransparency = 1

	-- Lasers : seul le propriétaire passe (géré côté client)
	local laserFolder = Instance.new("Folder")
	laserFolder.Name = "Lasers"
	laserFolder.Parent = model
	makePart(model, "LaserBase", Vector3.new(W - 8, 0.6, 1.2), at(0, 1.3, -D / 2 + 2), DARK, Enum.Material.Metal)
	makePart(model, "LaserTop", Vector3.new(W - 8, 0.8, 1.2), at(0, FH - 2.4, -D / 2 + 2), DARK, Enum.Material.Metal)
	local laserHeight = FH - 4.4
	for x = -W / 2 + 5, W / 2 - 5, 2 do
		local laser = makePart(laserFolder, "Laser", Vector3.new(0.35, laserHeight, 0.35), at(x, 1.6 + laserHeight / 2, -D / 2 + 2), LASER, Enum.Material.Neon)
		laser.CastShadow = false
		-- éteints par défaut : chaque client les allume selon l'attribut LockedUntil (voir World.lua)
		laser.Transparency = 1
		laser.CanCollide = false
	end
	local glow = makePart(model, "LaserGlow", Vector3.new(1, 1, 1), at(0, 6, -D / 2 + 3), LASER)
	glow.Transparency = 1
	glow.CanCollide = false
	glow.CanQuery = false
	local light = Instance.new("PointLight")
	light.Color = LASER
	light.Range = 16
	light.Brightness = 2
	light.Enabled = false
	light.Parent = glow
	plot.laserLight = light

	-- Bouton de verrouillage : au sol, juste devant le joueur quand il apparaît dans sa base.
	-- On marche dessus (ou touche E) pour allumer les lasers.
	local lockZ = -D / 2 + 12
	local pedestal = makePart(model, "LockPedestal", Vector3.new(0.3, 6.4, 6.4), at(0, 1.15, lockZ) * CFrame.Angles(0, 0, math.rad(90)), DARK)
	pedestal.Shape = Enum.PartType.Cylinder
	local lockButton = makePart(model, "LockButton", Vector3.new(0.4, 4.8, 4.8), at(0, 1.4, lockZ) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 220, 90))
	lockButton.Shape = Enum.PartType.Cylinder
	plot.lockButton = lockButton
	local lockGui = Instance.new("BillboardGui")
	lockGui.Size = UDim2.new(0, 220, 0, 70)
	lockGui.StudsOffset = Vector3.new(0, 3.6, 0)
	lockGui.MaxDistance = 60
	lockGui.Parent = lockButton
	plot.lockLabel = makeText(lockGui, "", UDim2.new(1, 0, 0.62, 0))
	plot.lockHint = makeText(lockGui, "", UDim2.new(1, 0, 0.34, 0), UDim2.new(0, 0, 0.64, 0), Color3.fromRGB(230, 230, 240))
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.Name = "LockPrompt"
	lockPrompt.ActionText = "Verrouiller la base"
	lockPrompt.ObjectText = "Lasers"
	lockPrompt.KeyboardKeyCode = Enum.KeyCode.E
	lockPrompt.HoldDuration = 0
	lockPrompt.MaxActivationDistance = 8
	lockPrompt.RequiresLineOfSight = false
	lockPrompt:SetAttribute("Active", true)
	lockPrompt.Parent = lockButton
	lockPrompt.Triggered:Connect(function(player)
		BaseManager.lock(plot, player)
	end)
	lockButton.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and player == plot.owner and not BaseManager.isLocked(plot) then
			BaseManager.lock(plot, player)
		end
	end)
	model:SetAttribute("LockedUntil", 0)

	model.Parent = plotsFolder

	for slotIndex = 1, GameConfig.BASE.GroundSlots do
		buildSlot(plot, slotIndex, model)
	end

	return plot
end

-- ============================================================
-- AFFICHAGE
-- ============================================================
local function clearCard(slot)
	if slot.card then
		slot.card:Destroy()
		slot.card = nil
	end
	slot.shownKey = nil
end

-- Petites particules aux couleurs de la mutation autour d'une carte
local function decorateCard(part, mutation)
	local mutationData = GameConfig.MUTATIONS[mutation]
	if not mutationData or not mutationData.Colors then return end
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(mutationData.Colors[1], mutationData.Colors[2])
	particles.LightEmission = 0.6
	particles.Size = NumberSequence.new(0.35, 0)
	particles.Lifetime = NumberRange.new(0.8, 1.6)
	particles.Rate = 10
	particles.Speed = NumberRange.new(0.5, 1.5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = part
end

-- Une carte au format 5:8 dessinée par les clients (voir World.lua), visible des deux côtés
local function makeCardPart(name, size, cardName, mutation, serial)
	local card = GameConfig.getCard(cardName)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = card and GameConfig.RARITIES[card.Rarity].Color2 or DARK
	part.Material = Enum.Material.SmoothPlastic
	part:SetAttribute("CardName", cardName)
	part:SetAttribute("Mutation", mutation)
	part:SetAttribute("Serial", serial or 0)
	part:SetAttribute("DoubleSided", true)
	decorateCard(part, mutation)
	CollectionService:AddTag(part, "CardDisplay")
	return part
end

-- La grande carte debout sur le podium
local function showCard(slot, cardName, mutation, serial)
	local key = cardName .. "|" .. mutation .. "|" .. tostring(serial)
	if slot.shownKey == key then return end
	clearCard(slot)
	slot.shownKey = key

	local part = makeCardPart("CardDisplay", CARD_SIZE, cardName, mutation, serial)
	part.Anchored = true
	part.CFrame = slot.cardCFrame
	local stand = makePart(part, "CardStand", Vector3.new(CARD_SIZE.X + 0.6, 0.5, 1.4), slot.cardCFrame * CFrame.new(0, -CARD_SIZE.Y / 2 - 0.05, 0), DARK)
	stand.CanCollide = false
	stand.CanQuery = false
	part.Parent = slot.parent
	slot.card = part
end

-- Met à jour toute la base d'un joueur. Renvoie true si un nouvel étage vient d'être construit.
function BaseManager.refresh(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return false end
	local rebirths = player.leaderstats.Rebirths.Value
	local multiplier = GameConfig.getPlayerMultiplier(player)

	local newFloor = ensureLevels(plot, GameConfig.getFloorCount(rebirths))

	local placed = {}
	for _, item in ipairs(deps.PlayerData.getItems(player)) do
		local slotIndex = item:GetAttribute("Slot") or 0
		if slotIndex > 0 then
			placed[slotIndex] = item
		end
	end

	local totalIncome = 0
	for index, slot in pairs(plot.slots) do
		local item = placed[index]
		slot.item = item
		local unlocked = GameConfig.isSlotUnlocked(index, rebirths)
		slot.lockGui.Enabled = not unlocked
		slot.podiumRim.Color = unlocked and plot.accent or Color3.fromRGB(120, 40, 40)
		slot.pad.Color = unlocked and Color3.fromRGB(70, 210, 100) or Color3.fromRGB(90, 90, 95)
		slot.padGui.Enabled = unlocked
		slot.prompt:SetAttribute("Active", unlocked) -- le client n'affiche le bouton E que dans SA base
		slot.stealPrompt:SetAttribute("Active", item ~= nil)
		slot.stealPrompt.ObjectText = item and item.Value or ""

		if item then
			local mutation = item:GetAttribute("Mutation") or "Normal"
			local income = GameConfig.getItemIncome(item.Value, mutation) * multiplier
			totalIncome += income
			showCard(slot, item.Value, mutation, item:GetAttribute("Serial"))
			local card = GameConfig.getCard(item.Value)
			local rarity = GameConfig.RARITIES[card.Rarity]
			slot.incomeLabel.Text = "$" .. GameConfig.format(income) .. "/s"
			slot.nameLabel.Text = item.Value
			local mutationData = GameConfig.MUTATIONS[mutation]
			if mutation ~= "Normal" and mutationData and mutationData.Colors then
				slot.mutationLabel.Text = "✦ " .. GameConfig.upper(mutation) .. " ✦"
				slot.mutationLabel.TextColor3 = Color3.new(1, 1, 1)
				slot.mutationGradient.Color = ColorSequence.new(mutationData.Colors[1], mutationData.Colors[2])
				slot.mutationGradient.Enabled = true
			else
				slot.mutationLabel.Text = card.Rarity
				slot.mutationLabel.TextColor3 = rarity.Color
				slot.mutationGradient.Enabled = false
			end
			slot.prompt.ActionText = "Reprendre"
			slot.prompt.ObjectText = item.Value
		else
			clearCard(slot)
			slot.incomeLabel.Text = ""
			slot.nameLabel.Text = ""
			slot.mutationLabel.Text = ""
			slot.mutationGradient.Enabled = false
			slot.prompt.ActionText = "Poser un brainrot"
			slot.prompt.ObjectText = "Emplacement " .. index
		end
	end

	plot.signIncome.Text = "$" .. GameConfig.format(totalIncome) .. "/s"
	return newFloor
end

-- ============================================================
-- POSER / REPRENDRE
-- ============================================================
function BaseManager.onSlotPrompt(plot, slot, player)
	if plot.owner ~= player then return end
	local PlayerData = deps.PlayerData
	if not GameConfig.isSlotUnlocked(slot.index, player.leaderstats.Rebirths.Value) then
		deps.Remotes.notify(player, "Débloqué au rebirth " .. slot.info.Required, "error")
		return
	end

	local placed = PlayerData.getPlacedItem(player, slot.index)
	if placed then
		BaseManager.collectSlot(plot, slot)
		placed:SetAttribute("Slot", 0)
		deps.Remotes.notify(player, placed.Value .. " est retourné dans ton sac", "info")
		return
	end

	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local itemId = tool and tool:GetAttribute("ItemId")
	local item = itemId and PlayerData.findItem(player, itemId)
	if not item or item:GetAttribute("Slot") ~= 0 then
		deps.Remotes.notify(player, "Prends d'abord une carte dans ton sac", "error")
		return
	end

	item:SetAttribute("Slot", slot.index)
	PlayerData.destroyHeldTool(player, item.Name)
	deps.Remotes.notify(player, item.Value .. " posé !", "success")
end

-- ============================================================
-- VERROU (lasers)
-- ============================================================
function BaseManager.isLocked(plot)
	return (plot.model:GetAttribute("LockedUntil") or 0) > Workspace:GetServerTimeNow()
end

function BaseManager.lock(plot, player)
	if plot.owner ~= player then return end
	if BaseManager.isLocked(plot) then
		deps.Remotes.notify(player, "Ta base est déjà verrouillée", "info")
		return
	end
	local duration = GameConfig.getLockDuration(player.leaderstats.Rebirths.Value)
	plot.model:SetAttribute("LockedUntil", Workspace:GetServerTimeNow() + duration)
	deps.Remotes.notify(player, "Base verrouillée pendant " .. duration .. " secondes", "success")
	BaseManager.updateLockDisplay(plot)
end

function BaseManager.updateLockDisplay(plot)
	if not plot.owner then
		plot.lockLabel.Text = ""
		plot.lockHint.Text = ""
		plot.laserLight.Enabled = false
		return
	end
	local remaining = (plot.model:GetAttribute("LockedUntil") or 0) - Workspace:GetServerTimeNow()
	if remaining > 0 then
		plot.lockLabel.Text = "🔒 " .. GameConfig.formatTime(remaining)
		plot.lockLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
		plot.lockHint.Text = "Base verrouillée"
		plot.lockButton.Color = Color3.fromRGB(255, 50, 50)
		plot.laserLight.Enabled = true
	else
		plot.lockLabel.Text = "🔓 OUVERTE"
		plot.lockLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
		plot.lockHint.Text = "Marche sur le bouton pour verrouiller"
		plot.lockButton.Color = Color3.fromRGB(60, 220, 90)
		plot.laserLight.Enabled = false
	end
end

-- ============================================================
-- VOL DE BRAINROTS
-- ============================================================
local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

function BaseManager.isCarrying(player)
	return carrying[player] ~= nil
end

function BaseManager.startSteal(plot, slot, thief)
	local owner = plot.owner
	if not owner or owner == thief then return end
	if BaseManager.isLocked(plot) then
		deps.Remotes.notify(thief, "Cette base est verrouillée !", "error")
		return
	end
	if carrying[thief] then
		deps.Remotes.notify(thief, "Tu portes déjà un brainrot !", "error")
		return
	end
	if not BaseManager.getPlot(thief) then return end
	local item = deps.PlayerData.getPlacedItem(owner, slot.index)
	local root, humanoid = getRoot(thief)
	if not item or not root or not humanoid or humanoid.Health <= 0 then return end
	if (root.Position - slot.podium.Position).Magnitude > 15 then return end -- il faut être à côté du podium

	BaseManager.collectSlot(plot, slot) -- le propriétaire garde l'argent déjà gagné
	item:SetAttribute("StolenBy", thief.UserId)
	item:SetAttribute("Slot", -1)

	-- La carte flotte au-dessus de la tête du voleur
	local visual = makeCardPart("StolenBrainrot", Vector3.new(2.2, 3.52, 0.12), item.Value, item:GetAttribute("Mutation") or "Normal", item:GetAttribute("Serial"))
	visual.Massless = true
	visual.CFrame = root.CFrame * CFrame.new(0, 4.6, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = visual
	weld.Parent = visual
	visual.Parent = thief.Character

	local carry = {item = item, owner = owner, slot = slot.index, visual = visual, started = os.clock(), speed = humanoid.WalkSpeed}
	carry.diedConnection = humanoid.Died:Connect(function()
		BaseManager.dropStolen(thief, "died")
	end)
	carrying[thief] = carry
	humanoid.WalkSpeed = GameConfig.STEAL.CarrySpeed
	thief:SetAttribute("Carrying", item.Value)

	deps.Remotes.notify(owner, "⚠️ " .. thief.DisplayName .. " vole ton " .. item.Value .. " ! Frappe-le avec ta batte !", "warning")
	deps.Remotes.notify(thief, "Ramène " .. item.Value .. " dans ta base !", "success")
	deps.Remotes.Effect:FireAllClients("Steal", {Position = slot.podium.Position})
end

local function endCarry(thief, carry)
	carrying[thief] = nil
	if carry.visual then
		carry.visual:Destroy()
	end
	if carry.diedConnection then
		carry.diedConnection:Disconnect()
	end
	local _, humanoid = getRoot(thief)
	if humanoid then
		humanoid.WalkSpeed = carry.speed or 16
	end
	if thief.Parent then
		thief:SetAttribute("Carrying", nil)
	end
end

-- Le voleur lâche le brainrot : il retourne chez son propriétaire
function BaseManager.dropStolen(thief, reason)
	local carry = carrying[thief]
	if not carry then return end
	endCarry(thief, carry)
	local item, owner = carry.item, carry.owner
	if not item.Parent then return end
	item:SetAttribute("StolenBy", nil)
	local originalFree = deps.PlayerData.getPlacedItem(owner, carry.slot) == nil
	item:SetAttribute("Slot", originalFree and carry.slot or 0)
	if owner.Parent then
		deps.Remotes.notify(owner, item.Value .. " est revenu dans ta base !", "success")
	end
	if thief.Parent then
		deps.Remotes.notify(thief, reason == "timeout" and "Trop tard ! Le brainrot est reparti" or ("Tu as lâché " .. item.Value .. " !"), "error")
	end
end

-- Le voleur est arrivé dans sa base : le brainrot est à lui
function BaseManager.deliver(thief)
	local carry = carrying[thief]
	if not carry then return end
	endCarry(thief, carry)
	local item, owner = carry.item, carry.owner
	if not item.Parent then return end
	item:SetAttribute("StolenBy", nil)
	item:SetAttribute("Slot", 0)
	deps.PlayerData.destroyHeldTool(owner, item.Name)
	item.Parent = thief.Brainrots
	item:SetAttribute("Slot", deps.PlayerData.getFreeSlot(thief) or 0)
	deps.PlayerData.discover(thief, item.Value)
	deps.Remotes.notify(thief, "Tu as volé " .. item.Value .. " !", "success")
	if owner.Parent then
		deps.Remotes.notify(owner, thief.DisplayName .. " t'a volé " .. item.Value .. "...", "error")
		task.spawn(deps.PlayerData.save, owner)
	end
	task.spawn(deps.PlayerData.save, thief)
end

local function isInsidePlot(plot, position)
	local rel = plot.cframe:PointToObjectSpace(position)
	return math.abs(rel.X) < W / 2 and math.abs(rel.Z) < D / 2 + 1 and rel.Y > -5 and rel.Y < 80
end

local function watchCarries()
	while true do
		task.wait(0.2)
		for thief, carry in pairs(carrying) do
			local root = getRoot(thief)
			local plot = BaseManager.getPlot(thief)
			if not thief.Parent or not root or not plot then
				BaseManager.dropStolen(thief, "lost")
			elseif os.clock() - carry.started > GameConfig.STEAL.Timeout then
				BaseManager.dropStolen(thief, "timeout")
			elseif isInsidePlot(plot, root.Position) then
				BaseManager.deliver(thief)
			end
		end
	end
end

-- ============================================================
-- ARGENT
-- ============================================================
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
	for _, slot in pairs(plot.slots) do
		BaseManager.collectSlot(plot, slot)
	end
end

function BaseManager.clearPending(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	for _, slot in pairs(plot.slots) do
		slot.pending = 0
		slot.padAmount.Text = "$0"
	end
	plot.model:SetAttribute("Pending", 0)
end

-- Chaque seconde, l'argent s'accumule sur les boutons COLLECTER
function BaseManager.tick()
	for _, plot in ipairs(plots) do
		local owner = plot.owner
		BaseManager.updateLockDisplay(plot)
		if owner and owner.Parent then
			local multiplier = GameConfig.getPlayerMultiplier(owner)
			local total = 0
			for _, slot in pairs(plot.slots) do
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

-- ============================================================
-- ATTRIBUTION
-- ============================================================
function BaseManager.init(dependencies)
	deps = dependencies
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace

	-- 2 rangées de bases face à face, la mine au milieu
	local count = GameConfig.BASE.PlotCount
	local perRow = math.ceil(count / 2)
	local spacing = W + 14
	local distance = dependencies.MineHalf + 3 + 64 + D / 2
	for index = 1, count do
		local row = index <= perRow and -1 or 1
		local col = (index - 1) % perRow
		local x = (col - (perRow - 1) / 2) * spacing
		local position = Vector3.new(x, 0, row * distance)
		local cframe = CFrame.lookAt(position, Vector3.new(x, 0, 0)) -- l'entrée regarde vers la mine
		table.insert(plots, buildPlot(index, cframe))
	end
	task.spawn(watchCarries)
end

function BaseManager.getPlotCFrames()
	local list = {}
	for _, plot in ipairs(plots) do
		table.insert(list, plot.cframe)
	end
	return list
end

-- Devant l'entrée de chaque base (pour les tapis roulants)
function BaseManager.getEntrances()
	local list = {}
	for _, plot in ipairs(plots) do
		table.insert(list, (plot.cframe * CFrame.new(0, 0, -D / 2 - 5)).Position)
	end
	return list
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
			return plot
		end
	end
	return nil
end

function BaseManager.release(player)
	-- s'il volait : le brainrot retourne chez son propriétaire
	BaseManager.dropStolen(player, "left")
	-- si on lui volait quelque chose : le voleur le garde (sinon il serait perdu)
	for thief, carry in pairs(carrying) do
		if carry.owner == player then
			BaseManager.deliver(thief)
		end
	end
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	BaseManager.collectAll(player)
	plot.owner = nil
	plot.model:SetAttribute("OwnerId", 0)
	plot.model:SetAttribute("Pending", 0)
	plot.signName.Text = "Base libre"
	plot.signIncome.Text = ""
	plot.model:SetAttribute("LockedUntil", 0)
	BaseManager.updateLockDisplay(plot)
	removeLevels(plot)
	for _, slot in pairs(plot.slots) do
		slot.item = nil
		slot.pending = 0
		slot.padAmount.Text = "$0"
		clearCard(slot)
		slot.incomeLabel.Text = ""
		slot.nameLabel.Text = ""
		slot.mutationLabel.Text = ""
	end
end

function BaseManager.getSpawnCFrame(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return nil end
	return plot.cframe * CFrame.new(0, 4, -D / 2 + 7) * CFrame.Angles(0, math.rad(180), 0)
end

return BaseManager
