-- ModuleScript : le décor de la map, style Roblox classique (blocs à picots, couleurs franches).
--   - le sol en Parts (herbe + allées), PAS de Terrain : rien ne dépasse dans les bases
--   - un grand mur en pierre avec des piliers tout autour de la map
--   - les TAPIS ROULANTS (bases <-> mine, mine <-> boutique, mine <-> roue)
--   - haies et jardinières autour des bases, arbres et buissons
--   - lumière de jour propre (pas de bloom, pas de néons)

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local WorldBuilder = {}

local CONVEYOR_SPEED = 38 -- vitesse des tapis (un joueur marche à 16)
local WALL_X, WALL_Z = 232, 208 -- le mur fait le tour de la map (de -232 à 232 et de -208 à 208)
local OUTER = 330 -- l'herbe continue derrière le mur (avec des arbres)

local GRASS = Color3.fromRGB(96, 178, 76)
local PATH = Color3.fromRGB(206, 200, 188)
local STONE = Color3.fromRGB(232, 226, 214)
local STONE_DARK = Color3.fromRGB(165, 158, 150)
local TRIM = Color3.fromRGB(196, 96, 72)

local TO_MINE = Color3.fromRGB(255, 170, 40)
local TO_PLACE = Color3.fromRGB(60, 200, 255)

local function makePart(parent, name, size, cframe, color, material, studs)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = studs and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Une dalle posée au sol (x1..x2, z1..z2), dessus à la hauteur "top"
local function slab(parent, name, x1, x2, z1, z2, top, color)
	local sizeX, sizeZ = math.abs(x2 - x1), math.abs(z2 - z1)
	if sizeX <= 0 or sizeZ <= 0 then return nil end
	return makePart(parent, name, Vector3.new(sizeX, 1, sizeZ), CFrame.new((x1 + x2) / 2, top - 0.5, (z1 + z2) / 2), color, Enum.Material.SmoothPlastic, true)
end

-- ============================================================
-- LUMIERE / CIEL (propre et lumineux)
-- ============================================================
local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(115, 115, 125)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true

	-- On coupe les effets qui "brillent" (bloom, rayons, flou) s'il y en a dans la place
	for _, effect in ipairs(Lighting:GetChildren()) do
		if effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") then
			effect.Enabled = false
		end
	end

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.22
	atmosphere.Offset = 0
	atmosphere.Haze = 0
	atmosphere.Glare = 0
	atmosphere.Color = Color3.fromRGB(205, 225, 255)
	atmosphere.Decay = Color3.fromRGB(150, 175, 215)
	atmosphere.Parent = Lighting

	local color = Lighting:FindFirstChild("BrainrotColor") or Instance.new("ColorCorrectionEffect")
	color.Name = "BrainrotColor"
	color.Saturation = 0.08
	color.Contrast = 0.03
	color.Brightness = 0
	color.Parent = Lighting

	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		clouds.Cover = 0.5
		clouds.Density = 0.55
		clouds.Color = Color3.fromRGB(255, 255, 255)
		clouds.Parent = terrain
	end
end

-- ============================================================
-- SOL
-- ============================================================
local function buildGround(folder, half)
	-- 4 grandes dalles d'herbe autour du trou de la mine
	slab(folder, "Grass", -OUTER, OUTER, half, OUTER, 0, GRASS)
	slab(folder, "Grass", -OUTER, OUTER, -OUTER, -half, 0, GRASS)
	slab(folder, "Grass", -OUTER, -half, -half, half, 0, GRASS)
	slab(folder, "Grass", half, OUTER, -half, half, 0, GRASS)
end

-- ============================================================
-- LE MUR AUTOUR DE LA MAP
-- ============================================================
local function wallSide(folder, center, length, alongX)
	local function box(size)
		return alongX and Vector3.new(length, size.Y, size.X) or Vector3.new(size.X, size.Y, length)
	end
	makePart(folder, "WallPlinth", box(Vector3.new(5, 2.5, 0)), CFrame.new(center + Vector3.new(0, 1.25, 0)), STONE_DARK, Enum.Material.SmoothPlastic)
	makePart(folder, "Wall", box(Vector3.new(4, 14, 0)), CFrame.new(center + Vector3.new(0, 7, 0)), STONE, Enum.Material.SmoothPlastic)
	makePart(folder, "WallStripe", box(Vector3.new(4.3, 1, 0)), CFrame.new(center + Vector3.new(0, 10.5, 0)), TRIM, Enum.Material.SmoothPlastic)
	makePart(folder, "WallCap", box(Vector3.new(5.4, 1.2, 0)), CFrame.new(center + Vector3.new(0, 14.6, 0)), STONE_DARK, Enum.Material.SmoothPlastic, true)

	-- piliers réguliers avec un chapeau et une boule
	local count = math.floor(length / 40)
	for i = 0, count do
		local offset = -length / 2 + i * (length / count)
		local position = center + (alongX and Vector3.new(offset, 0, 0) or Vector3.new(0, 0, offset))
		makePart(folder, "WallPillar", Vector3.new(7, 18, 7), CFrame.new(position + Vector3.new(0, 9, 0)), STONE, Enum.Material.SmoothPlastic)
		makePart(folder, "WallPillarBand", Vector3.new(7.4, 1, 7.4), CFrame.new(position + Vector3.new(0, 10.5, 0)), TRIM, Enum.Material.SmoothPlastic)
		makePart(folder, "WallPillarCap", Vector3.new(8.4, 1.4, 8.4), CFrame.new(position + Vector3.new(0, 18.7, 0)), TRIM, Enum.Material.SmoothPlastic, true)
		local ball = makePart(folder, "WallPillarBall", Vector3.new(3.2, 3.2, 3.2), CFrame.new(position + Vector3.new(0, 20.9, 0)), STONE, Enum.Material.SmoothPlastic)
		ball.Shape = Enum.PartType.Ball
	end
end

local function buildWall(folder)
	local wall = Instance.new("Folder")
	wall.Name = "Wall"
	wall.Parent = folder
	wallSide(wall, Vector3.new(0, 0, WALL_Z), WALL_X * 2, true)
	wallSide(wall, Vector3.new(0, 0, -WALL_Z), WALL_X * 2, true)
	wallSide(wall, Vector3.new(WALL_X, 0, 0), WALL_Z * 2, false)
	wallSide(wall, Vector3.new(-WALL_X, 0, 0), WALL_Z * 2, false)
end

-- ============================================================
-- TAPIS ROULANT (propre : bande sombre, rebords clairs, flèches colorées)
-- ============================================================
local function conveyor(parent, from, to, color)
	local offset = to - from
	local length = offset.Magnitude
	local direction = offset.Unit
	local middle = (from + to) / 2 + Vector3.new(0, 0.35, 0)
	local cframe = CFrame.lookAt(middle, middle + direction)

	local model = Instance.new("Model")
	model.Name = "Conveyor"

	-- La bande (c'est elle qui pousse les joueurs)
	local belt = makePart(model, "Belt", Vector3.new(4.4, 0.6, length), cframe, Color3.fromRGB(48, 50, 58), Enum.Material.SmoothPlastic)
	belt.AssemblyLinearVelocity = direction * CONVEYOR_SPEED

	for _, side in ipairs({-1, 1}) do
		makePart(model, "Rail", Vector3.new(0.6, 1, length), cframe * CFrame.new(side * 2.5, 0.2, 0), Color3.fromRGB(235, 235, 240), Enum.Material.SmoothPlastic)
	end

	-- Flèches ">" qui s'allument les unes après les autres (animées côté client)
	local arrowAngle = math.rad(38)
	local step = 3
	local count = math.floor((length - 2) / step)
	for i = 0, count - 1 do
		local z = length / 2 - 1.5 - i * step
		for _, side in ipairs({-1, 1}) do
			local arm = makePart(model, "Chevron", Vector3.new(0.35, 0.1, 1.6), cframe * CFrame.new(side * 0.45, 0.33, z) * CFrame.Angles(0, side * arrowAngle, 0), color, Enum.Material.SmoothPlastic)
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
local function doubleConveyor(parent, placePoint, minePoint)
	local direction = (minePoint - placePoint).Unit
	local sideways = direction:Cross(Vector3.new(0, 1, 0)) * 2.9
	conveyor(parent, placePoint + sideways, minePoint + sideways, TO_MINE)
	conveyor(parent, minePoint - sideways, placePoint - sideways, TO_PLACE)
end

-- ============================================================
-- DECORS
-- ============================================================
local LEAVES = {Color3.fromRGB(75, 160, 65), Color3.fromRGB(95, 185, 75), Color3.fromRGB(65, 140, 60)}

local function roundTree(parent, position, scale, random)
	local trunkHeight = 5 * scale
	makePart(parent, "Trunk", Vector3.new(1.4 * scale, trunkHeight, 1.4 * scale), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(120, 82, 50))
	for i, offset in ipairs({Vector3.new(0, 0, 0), Vector3.new(1.8, -1, 0.8), Vector3.new(-1.6, -0.8, -1)}) do
		local ball = makePart(parent, "Leaves", Vector3.new(6.5, 6.5, 6.5) * scale * (i == 1 and 1 or 0.7), CFrame.new(position + Vector3.new(0, trunkHeight + 2.2 * scale, 0) + offset * scale), LEAVES[random:NextInteger(1, #LEAVES)])
		ball.Shape = Enum.PartType.Ball
		ball.CanCollide = false
	end
end

local function pine(parent, position, scale, random)
	local trunkHeight = 4 * scale
	makePart(parent, "Trunk", Vector3.new(1.3 * scale, trunkHeight, 1.3 * scale), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(110, 75, 45))
	local green = LEAVES[random:NextInteger(1, #LEAVES)]
	for level = 0, 2 do
		local size = (7 - level * 2) * scale
		local leaves = makePart(parent, "Leaves", Vector3.new(size, 2.6 * scale, size), CFrame.new(position + Vector3.new(0, trunkHeight + 1 + level * 2.4 * scale, 0)) * CFrame.Angles(0, math.rad(45 * level), 0), green:Lerp(Color3.new(0, 0, 0), level * 0.06))
		leaves.CanCollide = level == 0
	end
end

local function bush(parent, position, scale, random)
	local ball = makePart(parent, "Bush", Vector3.new(4, 3, 4) * scale, CFrame.new(position + Vector3.new(0, 1.2 * scale, 0)), LEAVES[random:NextInteger(1, #LEAVES)])
	ball.Shape = Enum.PartType.Ball
end

local FLOWER_COLORS = {
	Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 210, 60), Color3.fromRGB(180, 110, 255),
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 60),
}
local function planter(parent, cframe, random)
	makePart(parent, "Planter", Vector3.new(4, 1.4, 3), cframe * CFrame.new(0, 0.7, 0), Color3.fromRGB(150, 100, 65))
	makePart(parent, "Soil", Vector3.new(3.6, 0.2, 2.6), cframe * CFrame.new(0, 1.45, 0), Color3.fromRGB(95, 65, 40))
	for i = 1, 6 do
		local x = -1.4 + ((i - 1) % 3) * 1.4
		local z = i <= 3 and -0.6 or 0.6
		local stem = makePart(parent, "Stem", Vector3.new(0.15, 1, 0.15), cframe * CFrame.new(x, 2, z), Color3.fromRGB(60, 160, 60))
		stem.CanCollide = false
		local flower = makePart(parent, "Flower", Vector3.new(0.7, 0.7, 0.7), cframe * CFrame.new(x, 2.6, z), FLOWER_COLORS[random:NextInteger(1, #FLOWER_COLORS)])
		flower.Shape = Enum.PartType.Ball
		flower.CanCollide = false
	end
end

local function decorateBase(folder, cframe, width, depth, random)
	-- Haies basses sur les côtés et à l'arrière
	for _, side in ipairs({-1, 1}) do
		makePart(folder, "Hedge", Vector3.new(2, 3, depth + 4), cframe * CFrame.new(side * (width / 2 + 2.5), 1.5, 0), Color3.fromRGB(70, 150, 60), Enum.Material.SmoothPlastic, true)
	end
	makePart(folder, "Hedge", Vector3.new(width + 7, 3, 2), cframe * CFrame.new(0, 1.5, depth / 2 + 3), Color3.fromRGB(70, 150, 60), Enum.Material.SmoothPlastic, true)
	-- Jardinières de chaque côté de l'entrée
	for _, side in ipairs({-1, 1}) do
		planter(folder, cframe * CFrame.new(side * (width / 2 - 3), 0, -depth / 2 - 5), random)
	end
end

function WorldBuilder.init(deps)
	setupLighting()

	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = Workspace

	local half = deps.MineHalf
	local ringInner, ringOuter = half + 3, half + 19 -- allée autour de la mine
	buildGround(folder, half)
	buildWall(folder)

	local entrances = deps.BaseManager.getEntrances()
	local minX, maxX = math.huge, -math.huge
	for _, entrance in ipairs(entrances) do
		minX = math.min(minX, entrance.X)
		maxX = math.max(maxX, entrance.X)
	end
	local width = deps.BaseManager.WIDTH

	-- Allée autour de la mine (un peu au-dessus de l'herbe), assez large pour les tapis des bases
	local paths = Instance.new("Folder")
	paths.Name = "Paths"
	paths.Parent = folder
	local top = 0.05
	local spanX = math.max(ringOuter, maxX + 9)
	slab(paths, "Path", -spanX, spanX, ringInner, ringOuter, top, PATH)
	slab(paths, "Path", -spanX, spanX, -ringOuter, -ringInner, top, PATH)
	slab(paths, "Path", -ringOuter, -ringInner, -ringInner, ringInner, top, PATH)
	slab(paths, "Path", ringInner, ringOuter, -ringInner, ringInner, top, PATH)

	local conveyors = Instance.new("Folder")
	conveyors.Name = "Conveyors"
	conveyors.Parent = folder

	-- Parvis devant chaque rangée de bases + tapis de chaque base jusqu'à la mine
	for _, rowSign in ipairs({-1, 1}) do
		local frontZ
		for _, entrance in ipairs(entrances) do
			if math.sign(entrance.Z) == rowSign then
				frontZ = entrance.Z
			end
		end
		if frontZ then
			local edge = frontZ + rowSign * 5 -- le bord des bases
			slab(paths, "Plaza", minX - width / 2 - 6, maxX + width / 2 + 6, edge, edge - rowSign * 16, top, PATH)
		end
	end
	for _, entrance in ipairs(entrances) do
		local minePoint = Vector3.new(entrance.X, 0, math.sign(entrance.Z) * (ringOuter + 1))
		local startZ = entrance.Z - math.sign(entrance.Z) * 11
		slab(paths, "Path", entrance.X - 7, entrance.X + 7, startZ, minePoint.Z, top, PATH)
		doubleConveyor(conveyors, entrance, minePoint)
	end

	-- Tapis vers la boutique (ouest) et la roue de la fortune (est)
	for _, front in ipairs({deps.ShopFront, deps.WheelFront}) do
		if front then
			local sign = math.sign(front.X)
			local placePoint = Vector3.new(front.X - sign * 2, 0, 0)
			local minePoint = Vector3.new(sign * (ringOuter + 1), 0, 0)
			slab(paths, "Path", front.X + sign * 4, minePoint.X, -8, 8, top, PATH)
			doubleConveyor(conveyors, placePoint, minePoint)
		end
	end

	-- Décors autour de chaque base
	local random = Random.new(7)
	for _, cframe in ipairs(deps.BaseManager.getPlotCFrames()) do
		decorateBase(folder, cframe, deps.BaseManager.WIDTH, deps.BaseManager.DEPTH, random)
	end

	-- Arbres et buissons dans la map (pas sur la mine, les bases, les tapis, la boutique ou la roue)
	local basesHalfX = maxX + width / 2 + 10
	local function isFree(position)
		local x, z = math.abs(position.X), math.abs(position.Z)
		if x < spanX + 10 and z < ringOuter + 10 then return false end
		if x < basesHalfX and z > ringOuter - 5 and z < WALL_Z - 20 then return false end
		if x > ringOuter and z < 34 then return false end
		return x < WALL_X - 10 and z < WALL_Z - 10
	end
	local nature = Instance.new("Folder")
	nature.Name = "Nature"
	nature.Parent = folder
	local planted, attempts = 0, 0
	while planted < 45 and attempts < 3000 do
		attempts += 1
		local position = Vector3.new(random:NextNumber(-WALL_X, WALL_X), 0, random:NextNumber(-WALL_Z, WALL_Z))
		if isFree(position) then
			local roll = random:NextNumber()
			if roll < 0.45 then
				roundTree(nature, position, random:NextNumber(0.9, 1.4), random)
			elseif roll < 0.75 then
				pine(nature, position, random:NextNumber(0.9, 1.5), random)
			else
				bush(nature, position, random:NextNumber(0.8, 1.3), random)
			end
			planted += 1
		end
	end

	-- Buissons le long du mur (côté intérieur)
	for x = -WALL_X + 20, WALL_X - 20, 24 do
		for _, sz in ipairs({-1, 1}) do
			bush(nature, Vector3.new(x + random:NextNumber(-4, 4), 0, sz * (WALL_Z - 7)), random:NextNumber(0.9, 1.3), random)
		end
	end
	for z = -WALL_Z + 20, WALL_Z - 20, 24 do
		for _, sx in ipairs({-1, 1}) do
			bush(nature, Vector3.new(sx * (WALL_X - 7), 0, z + random:NextNumber(-4, 4)), random:NextNumber(0.9, 1.3), random)
		end
	end

	-- Une forêt derrière le mur (pour que l'horizon ne soit pas vide)
	planted, attempts = 0, 0
	while planted < 90 and attempts < 4000 do
		attempts += 1
		local position = Vector3.new(random:NextNumber(-OUTER + 8, OUTER - 8), 0, random:NextNumber(-OUTER + 8, OUTER - 8))
		if math.abs(position.X) > WALL_X + 12 or math.abs(position.Z) > WALL_Z + 12 then
			if random:NextNumber() < 0.5 then
				pine(nature, position, random:NextNumber(1.3, 2.2), random)
			else
				roundTree(nature, position, random:NextNumber(1.2, 1.9), random)
			end
			planted += 1
		end
	end

	-- Spawn neutre (si toutes les bases sont prises)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "MineSpawn"
	spawnLocation.Size = Vector3.new(6, 0.2, 6)
	spawnLocation.Anchored = true
	spawnLocation.CFrame = CFrame.new(ringOuter + 22, 0.1, 22)
	spawnLocation.Color = PATH
	spawnLocation.Material = Enum.Material.SmoothPlastic
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.Parent = folder
end

return WorldBuilder
