-- ModuleScript : ambiance de la map (lumière, ciel, chemins, arbres, spawn).

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

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

	local rays = ensure("SunRaysEffect", "BrainrotSunRays")
	rays.Intensity = 0.06
	rays.Spread = 0.8
end

local function tree(parent, position, scale)
	local trunkHeight = 6 * scale
	makePart(parent, "Trunk", Vector3.new(1.4 * scale, trunkHeight, 1.4 * scale), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(95, 65, 40), Enum.Material.Wood)
	-- Sapin en 3 étages
	for level = 0, 2 do
		local size = (6 - level * 1.6) * scale
		local cone = makePart(parent, "Leaves", Vector3.new(size, 3 * scale, size), CFrame.new(position + Vector3.new(0, trunkHeight + level * 2.4 * scale, 0)) * CFrame.Angles(0, math.rad(45 * level), 0), Color3.fromRGB(45, 120 + level * 12, 55), Enum.Material.Grass)
		cone.CanCollide = level == 0
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

function WorldBuilder.init(info)
	setupLighting()

	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = Workspace

	local half = info.MineHalf
	local path = Color3.fromRGB(175, 135, 90)

	-- Anneau de chemin en terre autour de la mine
	local ring = half + 3
	local width = 12
	makePart(folder, "Path", Vector3.new((ring + width) * 2, 0.2, width), CFrame.new(0, 0.1, -(ring + width / 2)), path, Enum.Material.Ground)
	makePart(folder, "Path", Vector3.new((ring + width) * 2, 0.2, width), CFrame.new(0, 0.1, ring + width / 2), path, Enum.Material.Ground)
	makePart(folder, "Path", Vector3.new(width, 0.2, ring * 2), CFrame.new(-(ring + width / 2), 0.1, 0), path, Enum.Material.Ground)
	makePart(folder, "Path", Vector3.new(width, 0.2, ring * 2), CFrame.new(ring + width / 2, 0.1, 0), path, Enum.Material.Ground)

	-- Chemin vers la boutique et vers l'entrée de la mine
	makePart(folder, "Path", Vector3.new(60, 0.2, 10), CFrame.new(-(ring + width + 25), 0.1, 0), path, Enum.Material.Ground)
	makePart(folder, "Path", Vector3.new(40, 0.2, 10), CFrame.new(ring + width + 15, 0.1, 0), path, Enum.Material.Ground)

	-- Arbres tout autour de la map
	local random = Random.new(42)
	for _ = 1, 46 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(165, 190)
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		tree(folder, position, random:NextNumber(0.9, 1.5))
	end
	for _, position in ipairs({
		Vector3.new(-110, 0, -40), Vector3.new(-110, 0, 40), Vector3.new(-150, 0, -25), Vector3.new(-150, 0, 30),
		Vector3.new(110, 0, -45), Vector3.new(115, 0, 45), Vector3.new(150, 0, -20), Vector3.new(145, 0, 25),
	}) do
		tree(folder, position, 1.2)
	end

	-- Lampadaires le long du chemin
	for _, x in ipairs({-40, 0, 40}) do
		lamp(folder, Vector3.new(x, 0, -(ring + width + 1)))
		lamp(folder, Vector3.new(x, 0, ring + width + 1))
	end

	-- Spawn neutre (si toutes les bases sont prises)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "MineSpawn"
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.Anchored = true
	spawnLocation.CFrame = CFrame.new(ring + width + 20, 0.5, 14)
	spawnLocation.Color = Color3.fromRGB(80, 80, 80)
	spawnLocation.Material = Enum.Material.Slate
	spawnLocation.Parent = folder
end

return WorldBuilder
