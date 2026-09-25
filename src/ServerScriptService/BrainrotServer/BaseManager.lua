-- ModuleScript : les bases des joueurs.
--
-- Rez-de-chaussée : 8 emplacements (4 de chaque côté de l'allée).
-- Les rebirths construisent des ÉTAGES (voir GameConfig.FLOORS) : chaque étage a 6 emplacements,
-- le côté gauche se débloque quand l'étage apparaît, le côté droit à un rebirth suivant.
-- On monte / descend avec les plateformes d'ascenseur au fond de la base.
--
-- Sur chaque emplacement : un podium avec la CARTE du brainrot (dessinée côté client),
-- le revenu au-dessus, et un bouton COLLECTER au sol où l'argent s'accumule.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local BaseManager = {}

local W, D = 40, 48 -- largeur, profondeur d'une base
local FH = 15 -- hauteur d'un étage
BaseManager.WIDTH = W
BaseManager.DEPTH = D

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
		part.TopSurface = Enum.SurfaceType.Studs
		part.BottomSurface = Enum.SurfaceType.Studs
		part.FrontSurface = Enum.SurfaceType.Studs
		part.BackSurface = Enum.SurfaceType.Studs
		part.LeftSurface = Enum.SurfaceType.Studs
		part.RightSurface = Enum.SurfaceType.Studs
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

	slot.podium = makePart(parent, "Podium" .. index, Vector3.new(5, 1.2, 5.6), at * CFrame.new(podiumX, y0 + 0.6, z), Color3.fromRGB(55, 55, 62), Enum.Material.Metal)
	slot.podiumRim = makePart(parent, "PodiumRim", Vector3.new(5.3, 0.25, 5.9), at * CFrame.new(podiumX, y0 + 1.25, z), Color3.fromRGB(90, 90, 100), Enum.Material.Neon)
	slot.podiumRim.CanCollide = false

	-- La carte regarde vers l'allée, un peu inclinée
	local cardPos = (at * CFrame.new(podiumX, y0 + 4.6, z)).Position
	local facing = at:VectorToWorldSpace(Vector3.new(-side, 0, 0))
	slot.cardCFrame = CFrame.lookAt(cardPos, cardPos + facing) * CFrame.Angles(math.rad(-8), 0, 0)
	slot.parent = parent

	-- Revenu + nom + mutation au-dessus de la carte
	local infoAnchor = makePart(parent, "InfoAnchor", Vector3.new(0.2, 0.2, 0.2), at * CFrame.new(podiumX, y0 + 9.2, z), Color3.new(), nil)
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
	slot.pad = makePart(parent, "CollectPad" .. index, Vector3.new(4.6, 0.3, 5.4), at * CFrame.new(padX, y0 + 0.15, z), Color3.fromRGB(60, 220, 90), Enum.Material.Neon)
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
	local pad = makePart(parent, direction > 0 and "LiftUp" or "LiftDown", Vector3.new(5, 0.4, 5), plot.cframe * CFrame.new(x, levelY(level) + 0.2, D / 2 - 4.5), color, Enum.Material.Neon)
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

	-- Dalle du sol de l'étage
	makePart(model, "Slab", Vector3.new(W, 1, D), at * CFrame.new(0, y0 - 0.5, 0), CONCRETE, Enum.Material.Concrete, true)
	makePart(model, "Aisle", Vector3.new(8, 0.1, D - 8), at * CFrame.new(0, y0 + 0.05, 1), Color3.fromRGB(170, 35, 40), Enum.Material.Fabric)

	-- Murs + piliers
	makePart(model, "WallLeft", Vector3.new(1, FH, D - 4), at * CFrame.new(-W / 2 + 0.5, y0 + FH / 2, 1), WALL)
	makePart(model, "WallRight", Vector3.new(1, FH, D - 4), at * CFrame.new(W / 2 - 0.5, y0 + FH / 2, 1), WALL)
	makePart(model, "WallBack", Vector3.new(W, FH, 1), at * CFrame.new(0, y0 + FH / 2, D / 2 - 0.5), WALL)
	for _, x in ipairs({-W / 2 + 2, W / 2 - 2}) do
		for _, z in ipairs({-D / 2 + 2, D / 2 - 2}) do
			makePart(model, "Pillar", Vector3.new(4, FH, 4), at * CFrame.new(x, y0 + FH / 2, z), CONCRETE, Enum.Material.Concrete, true)
		end
	end

	-- Balcon vitré à l'avant
	local glass = makePart(model, "Railing", Vector3.new(W - 8, 3.5, 0.4), at * CFrame.new(0, y0 + 1.75, -D / 2 + 1), Color3.fromRGB(170, 220, 255), Enum.Material.Glass)
	glass.Transparency = 0.5
	makePart(model, "RailingTop", Vector3.new(W - 8, 0.4, 0.8), at * CFrame.new(0, y0 + 3.6, -D / 2 + 1), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)

	-- Poutre + panneau "ETAGE X" en haut de la façade
	makePart(model, "FrontBeam", Vector3.new(W - 4, 2.5, 3), at * CFrame.new(0, y0 + FH - 1.25, -D / 2 + 2), CONCRETE, Enum.Material.Concrete, true)
	local plate = makePart(model, "FloorSign", Vector3.new(14, 2.2, 0.4), at * CFrame.new(0, y0 + FH - 1.25, -D / 2 + 0.2), SIGN, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = plate
	makeText(gui, "ÉTAGE " .. level, UDim2.new(1, 0, 1, 0))

	-- Néons au plafond
	for z = -D / 2 + 10, D / 2 - 8, 12 do
		local lamp = makePart(model, "CeilingLight", Vector3.new(10, 0.3, 1.2), at * CFrame.new(0, y0 + FH - 0.4, z), Color3.new(1, 1, 1), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 0.9
		light.Parent = lamp
	end

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

	local plot = {index = index, model = model, cframe = cframe, owner = nil, slots = {}, levels = {}}

	local function at(x, y, z)
		return cframe * CFrame.new(x, y, z)
	end

	makePart(model, "Floor", Vector3.new(W, 1, D), at(0, 0.5, 0), CONCRETE, Enum.Material.Concrete, true)
	makePart(model, "Aisle", Vector3.new(8, 0.1, D - 6), at(0, 1.05, 1), Color3.fromRGB(170, 35, 40), Enum.Material.Fabric)
	for _, side in ipairs({-1, 1}) do
		makePart(model, "AisleLine", Vector3.new(0.3, 0.12, D - 6), at(side * 4.2, 1.06, 1), Color3.new(1, 1, 1), Enum.Material.Neon)
	end

	makePart(model, "WallLeft", Vector3.new(1, FH, D - 4), at(-W / 2 + 0.5, 1 + FH / 2, 1), WALL)
	makePart(model, "WallRight", Vector3.new(1, FH, D - 4), at(W / 2 - 0.5, 1 + FH / 2, 1), WALL)
	makePart(model, "WallBack", Vector3.new(W, FH, 1), at(0, 1 + FH / 2, D / 2 - 0.5), WALL)
	for _, x in ipairs({-W / 2 + 2, W / 2 - 2}) do
		for _, z in ipairs({-D / 2 + 2, D / 2 - 2}) do
			makePart(model, "Pillar", Vector3.new(4, FH, 4), at(x, 1 + FH / 2, z), CONCRETE, Enum.Material.Concrete, true)
		end
	end

	plot.roof = makePart(model, "Roof", Vector3.new(W + 2, 2, D + 2), at(0, levelY(1) + 1, 0), CONCRETE, Enum.Material.Concrete, true)

	for z = -D / 2 + 10, D / 2 - 8, 12 do
		local lamp = makePart(model, "CeilingLight", Vector3.new(10, 0.3, 1.2), at(0, FH - 0.4, z), Color3.new(1, 1, 1), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1
		light.Parent = lamp
	end

	-- Façade : poutre + panneau avec le nom et le revenu total
	makePart(model, "FrontBeam", Vector3.new(W - 4, 3, 3), at(0, FH - 0.5, -D / 2 + 2), CONCRETE, Enum.Material.Concrete, true)
	local border = makePart(model, "SignBorder", Vector3.new(W - 12, 5.6, 0.4), at(0, FH - 1, -D / 2 + 0.3), Color3.fromRGB(150, 85, 35), Enum.Material.SmoothPlastic, true)
	border.CanCollide = false
	local sign = makePart(model, "Sign", Vector3.new(W - 13, 4.8, 0.4), at(0, FH - 1, -D / 2 - 0.05), SIGN, Enum.Material.SmoothPlastic)
	sign.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = sign
	plot.signName = makeText(gui, "Base libre", UDim2.new(0.94, 0, 0.58, 0), UDim2.new(0.03, 0, 0.04, 0))
	plot.signIncome = makeText(gui, "", UDim2.new(0.94, 0, 0.34, 0), UDim2.new(0.03, 0, 0.62, 0), Color3.fromRGB(255, 250, 200))

	-- Lasers : seul le propriétaire passe (géré côté client)
	local laserFolder = Instance.new("Folder")
	laserFolder.Name = "Lasers"
	laserFolder.Parent = model
	makePart(model, "LaserBase", Vector3.new(W - 8, 0.6, 1.2), at(0, 1.3, -D / 2 + 2), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	makePart(model, "LaserTop", Vector3.new(W - 8, 0.8, 1.2), at(0, FH - 2.4, -D / 2 + 2), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	local laserHeight = FH - 4.4
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

	makePart(model, "WelcomeMat", Vector3.new(14, 0.3, 4), at(0, 0.15, -D / 2 - 2.5), Color3.fromRGB(60, 220, 90), Enum.Material.Neon)

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

-- Le serveur pose une plaque ; chaque client dessine la carte dessus (voir World.lua)
local function showCard(slot, cardName, mutation)
	local key = cardName .. "|" .. mutation
	if slot.shownKey == key then return end
	clearCard(slot)
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
	part:SetAttribute("CardName", cardName)
	part:SetAttribute("Mutation", mutation)

	if rarity.Order >= 4 then
		local glow = Instance.new("PointLight")
		glow.Color = rarity.Color
		glow.Range = 10
		glow.Brightness = 1.5
		glow.Parent = part
	end

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

	CollectionService:AddTag(part, "CardDisplay")
	part.Parent = slot.parent
	slot.card = part
end

-- Met à jour toute la base d'un joueur. Renvoie true si un nouvel étage vient d'être construit.
function BaseManager.refresh(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return false end
	local rebirths = player.leaderstats.Rebirths.Value
	local multiplier = GameConfig.getIncomeMultiplier(rebirths)

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
		slot.podiumRim.Color = unlocked and Color3.fromRGB(90, 200, 255) or Color3.fromRGB(120, 40, 40)
		slot.pad.Color = unlocked and Color3.fromRGB(60, 220, 90) or Color3.fromRGB(70, 70, 70)
		slot.pad.Material = unlocked and Enum.Material.Neon or Enum.Material.SmoothPlastic
		slot.padGui.Enabled = unlocked
		slot.prompt:SetAttribute("Active", unlocked) -- le client n'affiche le bouton E que dans SA base

		if item then
			local mutation = item:GetAttribute("Mutation") or "Normal"
			local income = GameConfig.getItemIncome(item.Value, mutation) * multiplier
			totalIncome += income
			showCard(slot, item.Value, mutation)
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
		if owner and owner.Parent then
			local multiplier = GameConfig.getIncomeMultiplier(owner.leaderstats.Rebirths.Value)
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
	local spacing = W + 12
	local distance = dependencies.MineHalf + 3 + 58 + D / 2
	for index = 1, count do
		local row = index <= perRow and -1 or 1
		local col = (index - 1) % perRow
		local x = (col - (perRow - 1) / 2) * spacing
		local position = Vector3.new(x, 0, row * distance)
		local cframe = CFrame.lookAt(position, Vector3.new(x, 0, 0)) -- l'entrée regarde vers la mine
		table.insert(plots, buildPlot(index, cframe))
	end
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
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	BaseManager.collectAll(player)
	plot.owner = nil
	plot.model:SetAttribute("OwnerId", 0)
	plot.model:SetAttribute("Pending", 0)
	plot.signName.Text = "Base libre"
	plot.signIncome.Text = ""
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
