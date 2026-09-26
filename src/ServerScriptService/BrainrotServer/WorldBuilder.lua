-- ModuleScript : le décor de la map.
--   - le sol en Terrain (vraie herbe), chemins en terre, 2 étangs, nuages
--   - les TAPIS ROULANTS (bases <-> mine, mine <-> boutique, mine <-> armurerie)
--   - haies, fleurs, lampadaires autour des bases, arbres, rochers

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local WorldBuilder = {}

local CONVEYOR_SPEED = 38 -- vitesse des tapis (un joueur marche à 16)
local EXTENT = 240 -- taille de la map (de -240 à 240)

local TO_MINE = Color3.fromRGB(255, 170, 40)
local TO_PLACE = Color3.fromRGB(60, 220, 255)

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- ============================================================
-- LUMIERE / CIEL
-- ============================================================
local function setupLighting()
	Lighting.ClockTime = 14.2
	Lighting.Brightness = 2.4
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 165)
	Lighting.GlobalShadows = true

	local function ensure(className, name)
		local existing = Lighting:FindFirstChild(name)
		if existing then return existing end
		local obj = Instance.new(className)
		obj.Name = name
		obj.Parent = Lighting
		return obj
	end

	local atmosphere = ensure("Atmosphere", "BrainrotAtmosphere")
	atmosphere.Density = 0.3
	atmosphere.Haze = 1.4
	atmosphere.Color = Color3.fromRGB(205, 225, 255)
	atmosphere.Decay = Color3.fromRGB(110, 145, 205)

	local bloom = ensure("BloomEffect", "BrainrotBloom")
	bloom.Intensity = 0.7
	bloom.Size = 30
	bloom.Threshold = 1.3

	local color = ensure("ColorCorrectionEffect", "BrainrotColor")
	color.Saturation = 0.2
	color.Contrast = 0.08
	color.Brightness = 0.02

	local rays = ensure("SunRaysEffect", "BrainrotSunRays")
	rays.Intensity = 0.05
	rays.Spread = 0.7
end

-- ============================================================
-- SOL EN TERRAIN
-- ============================================================
local function setupTerrain(half)
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if not terrain then return nil end

	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(95, 175, 70))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(190, 150, 100))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(230, 210, 160))

	-- Herbe partout sauf le trou de la mine (tout est aligné sur la grille de 4 du Terrain)
	local grass = Enum.Material.Grass
	local depth = EXTENT - half
	terrain:FillBlock(CFrame.new(0, -2, -(half + EXTENT) / 2), Vector3.new(EXTENT * 2, 4, depth), grass)
	terrain:FillBlock(CFrame.new(0, -2, (half + EXTENT) / 2), Vector3.new(EXTENT * 2, 4, depth), grass)
	terrain:FillBlock(CFrame.new(-(half + EXTENT) / 2, -2, 0), Vector3.new(depth, 4, half * 2), grass)
	terrain:FillBlock(CFrame.new((half + EXTENT) / 2, -2, 0), Vector3.new(depth, 4, half * 2), grass)

	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = terrain
	return terrain
end

-- Chemin de terre (remplace l'herbe du Terrain)
local function dirtPath(terrain, center, size)
	if terrain then
		terrain:FillBlock(CFrame.new(center.X, -2, center.Z), Vector3.new(size.X, 4, size.Z), Enum.Material.Ground)
	end
end

local function pond(terrain, folder, center, radius)
	if not terrain then return end
	local up = CFrame.new(center)
	terrain:FillCylinder(up * CFrame.new(0, -2, 0), 4, radius + 4, Enum.Material.Sand)
	terrain:FillCylinder(up * CFrame.new(0, -5, 0), 2, radius, Enum.Material.Sand)
	terrain:FillCylinder(up * CFrame.new(0, -1, 0), 6, radius, Enum.Material.Air)
	terrain:FillCylinder(up * CFrame.new(0, -2.4, 0), 3.2, radius, Enum.Material.Water)
	-- Quelques rochers au bord
	local random = Random.new(math.floor(math.abs(center.X)))
	for i = 1, 7 do
		local angle = i / 7 * math.pi * 2 + random:NextNumber(-0.3, 0.3)
		local position = center + Vector3.new(math.cos(angle) * (radius + 2.5), 0.6, math.sin(angle) * (radius + 2.5))
		local size = random:NextNumber(1.6, 3.2)
		makePart(folder, "Rock", Vector3.new(size, size * 0.7, size), CFrame.new(position) * CFrame.Angles(random:NextNumber(0, 1), random:NextNumber(0, 6), 0), Color3.fromRGB(130, 130, 140), Enum.Material.Slate)
	end
end

-- ============================================================
-- TAPIS ROULANT
-- ============================================================
local function signGui(part, face, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Parent = gui
end

local function conveyor(parent, from, to, color, label)
	local offset = to - from
	local length = offset.Magnitude
	local direction = offset.Unit
	local middle = (from + to) / 2 + Vector3.new(0, 0.3, 0)
	local cframe = CFrame.lookAt(middle, middle + direction)

	local model = Instance.new("Model")
	model.Name = "Conveyor"

	-- La bande (c'est elle qui pousse les joueurs)
	local belt = makePart(model, "Belt", Vector3.new(4.4, 0.6, length), cframe, Color3.fromRGB(32, 34, 42), Enum.Material.Rubber)
	belt.AssemblyLinearVelocity = direction * CONVEYOR_SPEED

	-- Bords en métal avec une bande lumineuse
	for _, side in ipairs({-1, 1}) do
		makePart(model, "Skirt", Vector3.new(0.6, 1.1, length), cframe * CFrame.new(side * 2.5, 0.25, 0), Color3.fromRGB(80, 85, 100), Enum.Material.DiamondPlate)
		local strip = makePart(model, "Strip", Vector3.new(0.25, 0.15, length), cframe * CFrame.new(side * 2.5, 0.85, 0), color, Enum.Material.Neon)
		strip.CanCollide = false
	end

	-- Rouleaux aux deux bouts
	for _, z in ipairs({-length / 2, length / 2}) do
		local roller = makePart(model, "Roller", Vector3.new(5.6, 0.9, 0.9), cframe * CFrame.new(0, -0.05, z), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
		roller.Shape = Enum.PartType.Cylinder
		roller.CanCollide = false
	end

	-- Arche avec la destination, au départ du tapis
	local start = cframe * CFrame.new(0, 0, length / 2 - 1)
	for _, side in ipairs({-1, 1}) do
		makePart(model, "ArchPost", Vector3.new(0.5, 6, 0.5), start * CFrame.new(side * 2.6, 3, 0), Color3.fromRGB(50, 52, 62), Enum.Material.Metal)
	end
	local bar = makePart(model, "ArchSign", Vector3.new(5.8, 1.4, 0.4), start * CFrame.new(0, 6.2, 0), Color3.fromRGB(28, 30, 38), Enum.Material.Metal)
	signGui(bar, Enum.NormalId.Front, label, color)
	signGui(bar, Enum.NormalId.Back, label, color)
	local glow = makePart(model, "ArchGlow", Vector3.new(5.8, 0.15, 0.45), start * CFrame.new(0, 5.45, 0), color, Enum.Material.Neon)
	glow.CanCollide = false

	-- Flèches ">" qui s'allument les unes après les autres (animées côté client)
	local arrowAngle = math.rad(38)
	local step = 3
	local count = math.floor((length - 2) / step)
	for i = 0, count - 1 do
		local z = length / 2 - 1.5 - i * step
		for _, side in ipairs({-1, 1}) do
			local arm = makePart(model, "Chevron", Vector3.new(0.3, 0.1, 1.6), cframe * CFrame.new(side * 0.45, 0.33, z) * CFrame.Angles(0, side * arrowAngle, 0), color, Enum.Material.Neon)
			arm.CanCollide = false
			arm.CanQuery = false
			arm.CanTouch = false
			arm:SetAttribute("Phase", i / math.max(count, 1))
			CollectionService:AddTag(arm, "ConveyorChevron")
		end
	end

	model.Parent = parent
	return model
end

-- Deux tapis côte à côte : aller vers la mine, retour vers l'autre endroit
local function doubleConveyor(parent, placePoint, minePoint, placeLabel)
	local direction = (minePoint - placePoint).Unit
	local sideways = direction:Cross(Vector3.new(0, 1, 0)) * 2.9
	conveyor(parent, placePoint + sideways, minePoint + sideways, TO_MINE, "⛏ MINE")
	conveyor(parent, minePoint - sideways, placePoint - sideways, TO_PLACE, placeLabel)
end

-- ============================================================
-- DECORS
-- ============================================================
local function pine(parent, position, scale)
	local trunkHeight = 6 * scale
	makePart(parent, "Trunk", Vector3.new(1.4 * scale, trunkHeight, 1.4 * scale), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(95, 65, 40), Enum.Material.Wood)
	for level = 0, 2 do
		local size = (6 - level * 1.6) * scale
		local leaves = makePart(parent, "Leaves", Vector3.new(size, 3 * scale, size), CFrame.new(position + Vector3.new(0, trunkHeight + level * 2.4 * scale, 0)) * CFrame.Angles(0, math.rad(45 * level), 0), Color3.fromRGB(45, 120 + level * 12, 55), Enum.Material.Grass)
		leaves.CanCollide = level == 0
	end
end

local function roundTree(parent, position, scale)
	local trunkHeight = 5 * scale
	makePart(parent, "Trunk", Vector3.new(1.2 * scale, trunkHeight, 1.2 * scale), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
	local colors = {Color3.fromRGB(80, 170, 70), Color3.fromRGB(100, 190, 80), Color3.fromRGB(70, 150, 60)}
	for i, offset in ipairs({Vector3.new(0, 0, 0), Vector3.new(1.6, -0.8, 0.8), Vector3.new(-1.4, -0.6, -1)}) do
		local ball = makePart(parent, "Leaves", Vector3.new(6, 6, 6) * scale * (i == 1 and 1 or 0.7), CFrame.new(position + Vector3.new(0, trunkHeight + 2 * scale, 0) + offset * scale), colors[i], Enum.Material.Grass)
		ball.Shape = Enum.PartType.Ball
		ball.CanCollide = false
	end
end

local function lamp(parent, position)
	makePart(parent, "LampPost", Vector3.new(0.6, 9, 0.6), CFrame.new(position + Vector3.new(0, 4.5, 0)), Color3.fromRGB(45, 45, 52), Enum.Material.Metal)
	makePart(parent, "LampArm", Vector3.new(0.4, 0.4, 2), CFrame.new(position + Vector3.new(0, 9, 0.8)), Color3.fromRGB(45, 45, 52), Enum.Material.Metal)
	local bulb = makePart(parent, "LampBulb", Vector3.new(1.2, 0.9, 1.2), CFrame.new(position + Vector3.new(0, 8.5, 1.6)), Color3.fromRGB(255, 225, 160), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 215, 160)
	light.Range = 26
	light.Brightness = 1.1
	light.Parent = bulb
end

local FLOWER_COLORS = {
	Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 210, 60), Color3.fromRGB(180, 110, 255),
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 60),
}
local function planter(parent, cframe, random)
	makePart(parent, "Planter", Vector3.new(4, 1.4, 3), cframe * CFrame.new(0, 0.7, 0), Color3.fromRGB(120, 80, 50), Enum.Material.WoodPlanks)
	makePart(parent, "Soil", Vector3.new(3.6, 0.2, 2.6), cframe * CFrame.new(0, 1.45, 0), Color3.fromRGB(80, 55, 35), Enum.Material.Ground)
	for i = 1, 6 do
		local x = -1.4 + ((i - 1) % 3) * 1.4
		local z = i <= 3 and -0.6 or 0.6
		local stem = makePart(parent, "Stem", Vector3.new(0.15, 1, 0.15), cframe * CFrame.new(x, 2, z), Color3.fromRGB(60, 160, 60), Enum.Material.Grass)
		stem.CanCollide = false
		local flower = makePart(parent, "Flower", Vector3.new(0.7, 0.7, 0.7), cframe * CFrame.new(x, 2.6, z), FLOWER_COLORS[random:NextInteger(1, #FLOWER_COLORS)], Enum.Material.SmoothPlastic)
		flower.Shape = Enum.PartType.Ball
		flower.CanCollide = false
	end
end

local function decorateBase(folder, cframe, width, depth, random)
	-- Haies sur les côtés et à l'arrière
	for _, side in ipairs({-1, 1}) do
		makePart(folder, "Hedge", Vector3.new(2, 3.5, depth + 4), cframe * CFrame.new(side * (width / 2 + 2.5), 1.75, 0), Color3.fromRGB(55, 140, 55), Enum.Material.Grass)
	end
	makePart(folder, "Hedge", Vector3.new(width + 7, 3.5, 2), cframe * CFrame.new(0, 1.75, depth / 2 + 3), Color3.fromRGB(55, 140, 55), Enum.Material.Grass)
	-- Jardinières + lampadaires à l'entrée
	for _, side in ipairs({-1, 1}) do
		planter(folder, cframe * CFrame.new(side * (width / 2 - 3), 0, -depth / 2 - 5), random)
		lamp(folder, (cframe * CFrame.new(side * 10, 0, -depth / 2 - 8)).Position)
	end
end

function WorldBuilder.init(deps)
	setupLighting()

	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = Workspace

	local half = deps.MineHalf
	local terrain = setupTerrain(half)
	local ringOuter = half + 16 -- chemin de terre autour de la mine

	-- Chemin autour de la mine
	dirtPath(terrain, Vector3.new(0, 0, -(half + 8)), Vector3.new(ringOuter * 2, 0, 16))
	dirtPath(terrain, Vector3.new(0, 0, half + 8), Vector3.new(ringOuter * 2, 0, 16))
	dirtPath(terrain, Vector3.new(-(half + 8), 0, 0), Vector3.new(16, 0, half * 2))
	dirtPath(terrain, Vector3.new(half + 8, 0, 0), Vector3.new(16, 0, half * 2))

	local conveyors = Instance.new("Folder")
	conveyors.Name = "Conveyors"
	conveyors.Parent = folder

	-- Tapis de chaque base jusqu'à la mine
	for _, entrance in ipairs(deps.BaseManager.getEntrances()) do
		local minePoint = Vector3.new(entrance.X, 0, math.sign(entrance.Z) * (ringOuter + 1))
		dirtPath(terrain, (entrance + minePoint) / 2, Vector3.new(16, 0, math.abs(entrance.Z - minePoint.Z) + 8))
		doubleConveyor(conveyors, entrance, minePoint, "🏠 BASES")
	end

	-- Tapis vers la boutique (ouest) et l'armurerie (est)
	for _, info in ipairs({
		{deps.ShopFront, "⛏ BOUTIQUE"},
		{deps.BatShopFront, "⚔ ARMURERIE"},
	}) do
		local front = info[1]
		local sign = math.sign(front.X)
		local placePoint = Vector3.new(front.X - sign * 4, 0, 0)
		local minePoint = Vector3.new(sign * (ringOuter + 1), 0, 0)
		dirtPath(terrain, (Vector3.new(front.X, 0, 0) + minePoint) / 2, Vector3.new(math.abs(front.X - minePoint.X) + 8, 0, 16))
		doubleConveyor(conveyors, placePoint, minePoint, info[2])
	end

	-- Décors autour de chaque base
	local random = Random.new(7)
	for _, cframe in ipairs(deps.BaseManager.getPlotCFrames()) do
		decorateBase(folder, cframe, deps.BaseManager.WIDTH, deps.BaseManager.DEPTH, random)
	end

	-- Étangs
	pond(terrain, folder, Vector3.new(-125, 0, -80), 16)
	pond(terrain, folder, Vector3.new(125, 0, 80), 16)

	-- Arbres et rochers (pas sur les bases, les tapis ou les magasins)
	local function isFree(position)
		if math.abs(position.X) < 95 and math.abs(position.Z) > 60 then return false end
		if math.abs(position.X) > 60 and math.abs(position.Z) < 30 then return false end
		if (position - Vector3.new(-125, 0, -80)).Magnitude < 24 or (position - Vector3.new(125, 0, 80)).Magnitude < 24 then return false end
		return math.abs(position.X) < EXTENT - 6 and math.abs(position.Z) < EXTENT - 6
	end
	local planted = 0
	local attempts = 0
	while planted < 70 and attempts < 2000 do
		attempts += 1
		local position = Vector3.new(random:NextNumber(-EXTENT, EXTENT), 0, random:NextNumber(-EXTENT, EXTENT))
		if position.Magnitude > 95 and isFree(position) then
			if random:NextNumber() < 0.5 then
				pine(folder, position, random:NextNumber(0.9, 1.6))
			else
				roundTree(folder, position, random:NextNumber(0.9, 1.4))
			end
			if random:NextNumber() < 0.35 then
				local size = random:NextNumber(1.5, 3.5)
				makePart(folder, "Rock", Vector3.new(size, size * 0.7, size), CFrame.new(position + Vector3.new(4, size * 0.3, 2)) * CFrame.Angles(0, random:NextNumber(0, 6), random:NextNumber(0, 0.5)), Color3.fromRGB(125, 125, 135), Enum.Material.Slate)
			end
			planted += 1
		end
	end

	-- Lampadaires autour de la mine
	for _, x in ipairs({-78, -26, 26, 78}) do
		lamp(folder, Vector3.new(x, 0, -(ringOuter + 3)))
		lamp(folder, Vector3.new(x, 0, ringOuter + 3))
	end

	-- Spawn neutre (si toutes les bases sont prises)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "MineSpawn"
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.Anchored = true
	spawnLocation.CFrame = CFrame.new(ringOuter + 20, 0.5, 18)
	spawnLocation.Color = Color3.fromRGB(80, 80, 80)
	spawnLocation.Material = Enum.Material.Slate
	spawnLocation.Parent = folder
end

return WorldBuilder
