-- ModuleScript : le décor de la map (lumière, chemins, TAPIS ROULANTS, arbres, spawn).

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local WorldBuilder = {}

local CONVEYOR_SPEED = 38 -- vitesse des tapis roulants (un joueur marche à 16)

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

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
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
	atmosphere.Density = 0.28
	atmosphere.Haze = 1.2
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	atmosphere.Decay = Color3.fromRGB(120, 150, 200)

	local bloom = ensure("BloomEffect", "BrainrotBloom")
	bloom.Intensity = 0.6
	bloom.Size = 28
	bloom.Threshold = 1.4

	local color = ensure("ColorCorrectionEffect", "BrainrotColor")
	color.Saturation = 0.15
	color.Contrast = 0.06
	color.Brightness = 0.02
end

-- ====== TAPIS ROULANT ======
-- Une bande qui pousse les joueurs dans une direction (comme à l'aéroport), avec des flèches lumineuses.
local function conveyor(parent, from, to)
	local offset = to - from
	local length = offset.Magnitude
	local direction = offset.Unit
	local middle = (from + to) / 2 + Vector3.new(0, 0.3, 0)
	local cframe = CFrame.lookAt(middle, middle + direction)

	local model = Instance.new("Model")
	model.Name = "Conveyor"

	local belt = makePart(model, "Belt", Vector3.new(4.4, 0.6, length), cframe, Color3.fromRGB(40, 42, 50), Enum.Material.DiamondPlate)
	belt.AssemblyLinearVelocity = direction * CONVEYOR_SPEED -- c'est ça qui fait avancer les joueurs

	for _, side in ipairs({-1, 1}) do
		makePart(model, "Rail", Vector3.new(0.5, 1, length), cframe * CFrame.new(side * 2.45, 0.2, 0), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
	end
	-- Rouleaux aux deux bouts
	for _, z in ipairs({-length / 2, length / 2}) do
		local roller = makePart(model, "Roller", Vector3.new(5.2, 0.9, 0.9), cframe * CFrame.new(0, -0.05, z), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
		roller.Shape = Enum.PartType.Cylinder
		roller.CanCollide = false
	end

	-- Flèches (">") qui s'allument les unes après les autres (animées côté client)
	local arrowAngle = math.rad(38)
	local step = 3
	local count = math.floor((length - 2) / step)
	for i = 0, count - 1 do
		local z = length / 2 - 1.5 - i * step -- de l'arrière vers l'avant
		for _, side in ipairs({-1, 1}) do
			local arm = makePart(
				model,
				"Chevron",
				Vector3.new(0.3, 0.1, 1.6),
				cframe * CFrame.new(side * 0.45, 0.33, z) * CFrame.Angles(0, side * arrowAngle, 0),
				Color3.fromRGB(255, 230, 90),
				Enum.Material.Neon
			)
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

-- Deux tapis côte à côte : un pour l'aller, un pour le retour
local function doubleConveyor(parent, a, b)
	local direction = (b - a).Unit
	local sideways = direction:Cross(Vector3.new(0, 1, 0)) * 2.7
	conveyor(parent, a + sideways, b + sideways)
	conveyor(parent, b - sideways, a - sideways)
end

local function tree(parent, position, scale)
	local trunkHeight = 6 * scale
	makePart(parent, "Trunk", Vector3.new(1.4 * scale, trunkHeight, 1.4 * scale), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(95, 65, 40), Enum.Material.Wood)
	for level = 0, 2 do
		local size = (6 - level * 1.6) * scale
		local leaves = makePart(parent, "Leaves", Vector3.new(size, 3 * scale, size), CFrame.new(position + Vector3.new(0, trunkHeight + level * 2.4 * scale, 0)) * CFrame.Angles(0, math.rad(45 * level), 0), Color3.fromRGB(45, 120 + level * 12, 55), Enum.Material.Grass)
		leaves.CanCollide = level == 0
	end
end

local function lamp(parent, position)
	makePart(parent, "LampPost", Vector3.new(0.6, 9, 0.6), CFrame.new(position + Vector3.new(0, 4.5, 0)), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	local bulb = makePart(parent, "LampBulb", Vector3.new(1.4, 1.4, 1.4), CFrame.new(position + Vector3.new(0, 9.4, 0)), Color3.fromRGB(255, 220, 150), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Range = 26
	light.Brightness = 1.2
	light.Parent = bulb
end

function WorldBuilder.init(deps)
	setupLighting()

	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = Workspace

	local ring = deps.MineHalf + 3
	local width = 12
	local outer = ring + width
	local path = Color3.fromRGB(175, 135, 90)

	-- Chemin en terre autour de la mine
	makePart(folder, "Path", Vector3.new(outer * 2, 0.2, width), CFrame.new(0, 0.1, -(ring + width / 2)), path, Enum.Material.Ground)
	makePart(folder, "Path", Vector3.new(outer * 2, 0.2, width), CFrame.new(0, 0.1, ring + width / 2), path, Enum.Material.Ground)
	makePart(folder, "Path", Vector3.new(width, 0.2, ring * 2), CFrame.new(-(ring + width / 2), 0.1, 0), path, Enum.Material.Ground)
	makePart(folder, "Path", Vector3.new(width, 0.2, ring * 2), CFrame.new(ring + width / 2, 0.1, 0), path, Enum.Material.Ground)

	-- Tapis roulants : de chaque base jusqu'à la mine (aller + retour)
	local conveyors = Instance.new("Folder")
	conveyors.Name = "Conveyors"
	conveyors.Parent = folder
	for _, entrance in ipairs(deps.BaseManager.getEntrances()) do
		local mineSide = Vector3.new(entrance.X, 0, math.sign(entrance.Z) * (outer + 1))
		local length = (entrance - mineSide).Magnitude
		makePart(folder, "Path", Vector3.new(12, 0.2, length), CFrame.new((entrance + mineSide) / 2 + Vector3.new(0, 0.1, 0)), path, Enum.Material.Ground)
		doubleConveyor(conveyors, entrance, mineSide)
	end

	-- Tapis roulants vers la boutique (à l'ouest)
	local shopFront = deps.ShopFront
	local shopStart = Vector3.new(-(outer + 1), 0, 0)
	local shopEnd = Vector3.new(shopFront.X + 4, 0, 0)
	makePart(folder, "Path", Vector3.new((shopStart - shopFront).Magnitude, 0.2, 12), CFrame.new((shopStart + shopFront) / 2 + Vector3.new(0, 0.1, 0)), path, Enum.Material.Ground)
	doubleConveyor(conveyors, shopStart, shopEnd)

	-- Arbres tout autour (pas sur les bases, les tapis ou la boutique)
	local function isFree(position)
		if math.abs(position.X) < 90 and math.abs(position.Z) > 55 then return false end
		if position.X < -50 and math.abs(position.Z) < 30 then return false end
		if position.X > 40 and math.abs(position.Z) < 25 then return false end
		return true
	end
	local random = Random.new(42)
	local planted = 0
	while planted < 46 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(160, 192)
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if isFree(position) then
			tree(folder, position, random:NextNumber(0.9, 1.5))
			planted += 1
		end
	end
	for _, position in ipairs({
		Vector3.new(-110, 0, -40), Vector3.new(-110, 0, 40), Vector3.new(-95, 0, -70), Vector3.new(-95, 0, 70),
		Vector3.new(110, 0, -45), Vector3.new(115, 0, 45), Vector3.new(150, 0, -30), Vector3.new(145, 0, 35),
	}) do
		tree(folder, position, 1.2)
	end

	-- Lampadaires entre les bases
	for _, x in ipairs({-78, -26, 26, 78}) do
		lamp(folder, Vector3.new(x, 0, -(outer + 2)))
		lamp(folder, Vector3.new(x, 0, outer + 2))
	end

	-- Spawn neutre (si toutes les bases sont prises)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "MineSpawn"
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.Anchored = true
	spawnLocation.CFrame = CFrame.new(outer + 20, 0.5, 14)
	spawnLocation.Color = Color3.fromRGB(80, 80, 80)
	spawnLocation.Material = Enum.Material.Slate
	spawnLocation.Parent = folder
end

return WorldBuilder
