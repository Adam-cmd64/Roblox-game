-- ModuleScript : le décor du MONDE 2, la « NUIT DE CRISTAL ».
--   - dalles bleu nuit avec un quadrillage néon cyan, petits cristaux qui brillent
--   - allées claires bordées de néon, tapis roulants vers la mine de cristal et les 8 bases
--   - arbres de cristal, lampadaires, flèches de cristal géantes, îles qui flottent dans le ciel
--   - STATUES HOLOGRAMMES des brainrots du monde 2
--   - le portail de RETOUR vers le monde 1
-- Le ciel (aurores, lune de cristal...) et la lumière sont faits côté client (Sky.lua).

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WorldBuilder = require(script.Parent.WorldBuilder)

local World2Builder = {}

local WORLD = GameConfig.getWorld(2)
local O = WORLD.Origin
local makePart = WorldBuilder.makePart
local slab = WorldBuilder.slab

local WALL_X, WALL_Z = WorldBuilder.WALL_X, WorldBuilder.WALL_Z
local TILE = 16

local NIGHT = Color3.fromRGB(28, 44, 92)
local NIGHT_LIGHT = Color3.fromRGB(38, 58, 118)
local GRID = Color3.fromRGB(70, 230, 255)
local PATH = Color3.fromRGB(196, 192, 222)
local CYAN = Color3.fromRGB(80, 235, 255)
local PINK = Color3.fromRGB(255, 110, 230)
local VIOLET = Color3.fromRGB(170, 100, 255)
local CRYSTAL_BLUE = Color3.fromRGB(80, 105, 235)
local TRUNK = Color3.fromRGB(70, 60, 80)

-- où le joueur arrive dans le monde 2 (devant le portail de retour)
local RETURN_PORTAL = O + Vector3.new(-185, 0, 0)
World2Builder.RETURN_PORTAL = RETURN_PORTAL
-- la CRISTALLERIE (boutique de pioches du monde 2) : à l'est, tournée vers la mine
local SHOP_POSITION = O + Vector3.new(172, 0, 0)
World2Builder.SHOP_CFRAME = CFrame.lookAt(SHOP_POSITION, Vector3.new(O.X, 0, O.Z))

local function glowCube(parent, position, size, color, range)
	local cube = makePart(parent, "GlowCube", Vector3.new(size, size, size), CFrame.new(position) * CFrame.Angles(0, math.rad(45), 0), color, Enum.Material.Neon)
	cube.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range or 10
	light.Brightness = 1.4
	light.Parent = cube
	return cube
end

-- ====== SOL : dalles bleu nuit + quadrillage néon (sauf le trou de la mine) ======
local function buildGround(folder, half)
	local ground = Instance.new("Folder")
	ground.Name = "CrystalGround"
	ground.Parent = folder
	local x0, x1, z0, z1 = O.X - WALL_X, O.X + WALL_X, O.Z - WALL_Z, O.Z + WALL_Z
	slab(ground, "Night", x0, x1, O.Z + half, z1, 0, NIGHT)
	slab(ground, "Night", x0, x1, z0, O.Z - half, 0, NIGHT)
	slab(ground, "Night", x0, O.X - half, O.Z - half, O.Z + half, 0, NIGHT)
	slab(ground, "Night", O.X + half, x1, O.Z - half, O.Z + half, 0, NIGHT)
	-- derrière le mur : le vide étoilé (une grande dalle sombre)
	local VOID = Color3.fromRGB(14, 16, 40)
	local far = 130
	slab(ground, "Void", x0 - far, x1 + far, z1, z1 + far, 0, VOID)
	slab(ground, "Void", x0 - far, x1 + far, z0 - far, z0, 0, VOID)
	slab(ground, "Void", x0 - far, x0, z0, z1, 0, VOID)
	slab(ground, "Void", x1, x1 + far, z0, z1, 0, VOID)

	-- quelques dalles plus claires (comme sur l'image de référence)
	local random = Random.new(21)
	for _ = 1, 70 do
		local cx = random:NextInteger(-WALL_X // TILE, WALL_X // TILE - 1)
		local cz = random:NextInteger(-WALL_Z // TILE, WALL_Z // TILE - 1)
		local tx, tz = O.X + cx * TILE, O.Z + cz * TILE
		local inMine = math.abs(tx - O.X + TILE / 2) < half + TILE and math.abs(tz - O.Z + TILE / 2) < half + TILE
		if not inMine then
			slab(ground, "LightTile", tx + 0.4, tx + TILE - 0.4, tz + 0.4, tz + TILE - 0.4, 0.04, NIGHT_LIGHT)
		end
	end

	-- quadrillage néon (des lignes fines, coupées au niveau du trou de la mine)
	local function line(a, b, alongX, at)
		if b - a <= 0 then return end
		local size = alongX and Vector3.new(b - a, 0.08, 0.28) or Vector3.new(0.28, 0.08, b - a)
		local center = alongX and Vector3.new((a + b) / 2, 0.06, at) or Vector3.new(at, 0.06, (a + b) / 2)
		local part = makePart(ground, "GridLine", size, CFrame.new(center), GRID, Enum.Material.Neon)
		part.Transparency = 0.35
		part.CanCollide = false
		part.CanQuery = false
	end
	for z = -WALL_Z, WALL_Z, TILE do
		local crossesMine = math.abs(z) < half
		if crossesMine then
			line(x0, O.X - half, true, O.Z + z)
			line(O.X + half, x1, true, O.Z + z)
		else
			line(x0, x1, true, O.Z + z)
		end
	end
	for x = -WALL_X, WALL_X, TILE do
		local crossesMine = math.abs(x) < half
		if crossesMine then
			line(z0, O.Z - half, false, O.X + x)
			line(O.Z + half, z1, false, O.X + x)
		else
			line(z0, z1, false, O.X + x)
		end
	end
end

-- ====== MUR DE CRISTAL autour de la map ======
local function buildWall(folder)
	local wall = Instance.new("Folder")
	wall.Name = "CrystalWall"
	wall.Parent = folder
	local sides = {
		{Vector3.new(0, 0, WALL_Z), WALL_X * 2, true},
		{Vector3.new(0, 0, -WALL_Z), WALL_X * 2, true},
		{Vector3.new(WALL_X, 0, 0), WALL_Z * 2, false},
		{Vector3.new(-WALL_X, 0, 0), WALL_Z * 2, false},
	}
	for _, side in ipairs(sides) do
		local center, length, alongX = O + side[1], side[2], side[3]
		local function box(x, y, z)
			return alongX and Vector3.new(length + x, y, z) or Vector3.new(z, y, length + x)
		end
		makePart(wall, "Wall", box(4, 9, 3), CFrame.new(center + Vector3.new(0, 4.5, 0)), Color3.fromRGB(34, 36, 80), Enum.Material.SmoothPlastic)
		local strip = makePart(wall, "WallGlow", box(4.4, 0.6, 3.4), CFrame.new(center + Vector3.new(0, 9.2, 0)), CYAN, Enum.Material.Neon)
		strip.CanCollide = false
		local strip2 = makePart(wall, "WallGlow", box(4.4, 0.4, 3.4), CFrame.new(center + Vector3.new(0, 3, 0)), VIOLET, Enum.Material.Neon)
		strip2.CanCollide = false
		-- flèches de cristal le long du mur
		for offset = -length / 2 + 20, length / 2 - 20, 48 do
			local position = center + (alongX and Vector3.new(offset, 0, 0) or Vector3.new(0, 0, offset))
			local spire = makePart(wall, "Spire", Vector3.new(4, 18, 4), CFrame.new(position + Vector3.new(0, 9, 0)) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(60, 70, 160), Enum.Material.Glass)
			spire.Transparency = 0.15
			glowCube(wall, position + Vector3.new(0, 20, 0), 3.2, (math.floor(offset) // 48) % 2 == 0 and CYAN or PINK, 16)
		end
	end
end

-- ====== ARBRE DE CRISTAL (cubes bleus, tronc sombre) ======
local function crystalTree(parent, position, scale, random)
	local model = Instance.new("Model")
	model.Name = "CrystalTree"
	local trunkHeight = 5 * scale
	makePart(model, "Trunk", Vector3.new(1.8 * scale, trunkHeight, 1.8 * scale), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), TRUNK)
	local color = random:NextNumber() < 0.75 and CRYSTAL_BLUE or Color3.fromRGB(150, 90, 240)
	local base = position + Vector3.new(0, trunkHeight, 0)
	makePart(model, "Leaves", Vector3.new(8, 4.5, 8) * scale, CFrame.new(base + Vector3.new(0, 2.25 * scale, 0)), color, Enum.Material.SmoothPlastic)
	makePart(model, "Leaves", Vector3.new(5.5, 3.2, 5.5) * scale, CFrame.new(base + Vector3.new(0, 5.9 * scale, 0)), color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.SmoothPlastic)
	local glow = makePart(model, "LeavesGlow", Vector3.new(8.3, 0.3, 8.3) * scale, CFrame.new(base + Vector3.new(0, 0.2, 0)), CYAN, Enum.Material.Neon)
	glow.CanCollide = false
	for _ = 1, 3 do
		local offset = Vector3.new(random:NextNumber(-3, 3), random:NextNumber(1, 5), random:NextNumber(-3, 3)) * scale
		local gem = makePart(model, "Gem", Vector3.new(0.9, 0.9, 0.9), CFrame.new(base + offset + Vector3.new(0, 0, 4.2 * scale)), random:NextNumber() < 0.5 and PINK or CYAN, Enum.Material.Neon)
		gem.CanCollide = false
	end
	model.Parent = parent
end

-- ====== LAMPADAIRE (poteau sombre + cube cyan) ======
local function lamp(parent, position)
	makePart(parent, "LampPole", Vector3.new(0.9, 7, 0.9), CFrame.new(position + Vector3.new(0, 3.5, 0)), Color3.fromRGB(30, 40, 75))
	glowCube(parent, position + Vector3.new(0, 7.8, 0), 1.8, CYAN, 18)
end

-- ====== ÎLE FLOTTANTE (rocher à l'envers + petit arbre de cristal) ======
local function floatingIsland(parent, position, size, random)
	local model = Instance.new("Model")
	model.Name = "FloatingIsland"
	makePart(model, "IslandTop", Vector3.new(size, 2, size), CFrame.new(position), NIGHT_LIGHT, Enum.Material.SmoothPlastic)
	local glow = makePart(model, "IslandGlow", Vector3.new(size + 0.4, 0.3, size + 0.4), CFrame.new(position + Vector3.new(0, 1.1, 0)), CYAN, Enum.Material.Neon)
	glow.CanCollide = false
	local layers = 4
	for i = 1, layers do
		local s = size * (1 - i / (layers + 1))
		makePart(model, "IslandRock", Vector3.new(s, 2.5, s), CFrame.new(position - Vector3.new(0, 1 + i * 2.5, 0)) * CFrame.Angles(0, math.rad(i * 12), 0), Color3.fromRGB(40, 38, 85), Enum.Material.Slate)
	end
	glowCube(model, position - Vector3.new(0, 1 + layers * 2.5 + 2.5, 0), 2, PINK, 20)
	crystalTree(model, position + Vector3.new(0, 1, 0), size / 14, random)
	model.Parent = parent
end

-- ====== STATUE HOLOGRAMME d'un brainrot du monde 2 ======
local function hologramStatue(parent, position, cardName, facing)
	local card = GameConfig.getCard(cardName)
	if not card then return end
	local rarity = GameConfig.RARITIES[card.Rarity]
	local model = Instance.new("Model")
	model.Name = "HologramStatue"
	local at = CFrame.lookAt(position, position + facing)
	-- projecteur rond
	local base = makePart(model, "Projector", Vector3.new(1.4, 9, 9), at * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 34, 70), Enum.Material.SmoothPlastic)
	base.Shape = Enum.PartType.Cylinder
	local ring = makePart(model, "ProjectorRing", Vector3.new(0.3, 9.6, 9.6), at * CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)), CYAN, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	local lens = makePart(model, "ProjectorLens", Vector3.new(0.2, 6, 6), at * CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), rarity.Color:Lerp(CYAN, 0.5), Enum.Material.Neon)
	lens.Shape = Enum.PartType.Cylinder
	lens.CanCollide = false
	-- le cône de lumière de l'hologramme
	local field = makePart(model, "HoloField", Vector3.new(13, 7.4, 7.4), at * CFrame.new(0, 8, 0) * CFrame.Angles(0, 0, math.rad(90)), CYAN, Enum.Material.Neon)
	field.Shape = Enum.PartType.Cylinder
	field.Transparency = 0.9
	field.CanCollide = false
	field.CanQuery = false
	field.CastShadow = false

	local anchor = makePart(model, "Figure", Vector3.new(1, 1, 1), at * CFrame.new(0, 8.5, 0), CYAN)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	local gui = Instance.new("BillboardGui")
	gui.Name = "HologramGui"
	gui.Size = UDim2.new(11, 0, 12.3, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 400
	gui.Parent = anchor
	local image, offset, size = GameConfig.getCardImage(cardName)
	local art = Instance.new("ImageLabel")
	art.Name = "HoloArt"
	art.Size = UDim2.new(1, 0, 1, 0)
	art.BackgroundTransparency = 1
	art.ScaleType = Enum.ScaleType.Fit
	art.ImageColor3 = Color3.fromRGB(170, 240, 255) -- teinte hologramme
	art.ImageTransparency = 0.12
	if image then
		art.Image = image
		if size.X > 0 then
			art.ImageRectOffset = offset
			art.ImageRectSize = size
		end
	end
	art.Parent = gui
	-- lignes de balayage (effet hologramme)
	local scan = Instance.new("UIGradient")
	local keys = {}
	for i = 0, 10 do
		table.insert(keys, NumberSequenceKeypoint.new(i / 10, i % 2 == 0 and 0 or 0.35))
	end
	scan.Transparency = NumberSequence.new(keys)
	scan.Rotation = 90
	scan.Parent = art
	CollectionService:AddTag(scan, "HoloShine")
	gui:SetAttribute("Phase", position.X * 0.1 + position.Z * 0.07)
	CollectionService:AddTag(gui, "StatueBob")

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(CYAN, Color3.new(1, 1, 1))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0)})
	sparkles.Lifetime = NumberRange.new(1.5, 2.5)
	sparkles.Rate = 8
	sparkles.Speed = NumberRange.new(1.5, 3)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = lens
	local light = Instance.new("PointLight")
	light.Color = CYAN
	light.Range = 18
	light.Brightness = 2
	light.Parent = anchor

	-- nom + rareté devant le projecteur
	local plate = makePart(model, "NamePlate", Vector3.new(7, 1.4, 0.4), at * CFrame.new(0, 0.9, -4.8), Color3.fromRGB(25, 28, 60))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.LightInfluence = 0
	surface.Parent = plate
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = cardName
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = CYAN
	label.TextStrokeTransparency = 0.3
	label.Parent = surface
	local rarityGui = Instance.new("BillboardGui")
	rarityGui.Size = UDim2.new(8, 0, 1.4, 0)
	rarityGui.StudsOffset = Vector3.new(0, -7.2, 0)
	rarityGui.LightInfluence = 0
	rarityGui.MaxDistance = 120
	rarityGui.Parent = anchor
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 1, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = "◆ " .. GameConfig.upper(card.Rarity) .. " ◆"
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.LuckiestGuy
	rarityLabel.TextColor3 = rarity.Color
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.Parent = rarityGui

	model.Parent = parent
	return model
end

-- ====== LE PORTAIL DE RETOUR (vers le monde 1) ======
local function buildReturnPortal(parent)
	local model = Instance.new("Model")
	model.Name = "ReturnPortal"
	local facing = (Vector3.new(O.X, 0, O.Z) - Vector3.new(RETURN_PORTAL.X, 0, RETURN_PORTAL.Z)).Unit
	local base = CFrame.lookAt(RETURN_PORTAL, RETURN_PORTAL + facing)
	local radius = 9
	local center = base * CFrame.new(0, radius + 3, 0)
	local platform = makePart(model, "Platform", Vector3.new(1.2, 26, 26), base * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 34, 80))
	platform.Shape = Enum.PartType.Cylinder
	local glow = makePart(model, "PlatformGlow", Vector3.new(0.3, 27, 27), base * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), CYAN, Enum.Material.Neon)
	glow.Shape = Enum.PartType.Cylinder
	glow.CanCollide = false
	local stones = 20
	for i = 0, stones - 1 do
		local angle = i / stones * math.pi * 2
		local piece = makePart(model, "ArchCrystal", Vector3.new(2.6, 3.4, 2.6), center * CFrame.Angles(0, 0, angle) * CFrame.new(0, radius + 1.2, 0), i % 2 == 0 and Color3.fromRGB(70, 90, 210) or Color3.fromRGB(120, 80, 230), Enum.Material.Glass)
		piece.Transparency = 0.1
		if i % 2 == 0 then
			local tip = makePart(model, "ArchGem", Vector3.new(1, 1, 1), center * CFrame.Angles(0, 0, angle) * CFrame.new(0, radius + 3.4, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), i % 4 == 0 and CYAN or PINK, Enum.Material.Neon)
			tip.CanCollide = false
		end
	end
	local vortex = makePart(model, "Vortex", Vector3.new(0.4, radius * 2, radius * 2), center * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(70, 200, 255), Enum.Material.Neon)
	vortex.Shape = Enum.PartType.Cylinder
	vortex.Transparency = 0.25
	vortex.CanCollide = false
	for i, ring in ipairs({{radius * 1.7, PINK, 1.6}, {radius * 1.25, Color3.fromRGB(255, 255, 255), -2.4}, {radius * 0.8, VIOLET, 3}}) do
		local part = makePart(model, "VortexRing", Vector3.new(0.5 + i * 0.1, ring[1], ring[1]), center * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(-0.1 * i, 0, 0), ring[2], Enum.Material.Neon)
		part.Shape = Enum.PartType.Cylinder
		part.Transparency = 0.55
		part.CanCollide = false
		part:SetAttribute("SpinSpeed", ring[3])
		CollectionService:AddTag(part, "PortalSpin")
	end
	local swirl = Instance.new("ParticleEmitter")
	swirl.Texture = "rbxasset://textures/particles/smoke_main.dds"
	swirl.Color = ColorSequence.new(CYAN, PINK)
	swirl.LightEmission = 1
	swirl.Size = NumberSequence.new(3.5, 0)
	swirl.Transparency = NumberSequence.new(0.4, 1)
	swirl.Lifetime = NumberRange.new(1.2, 2)
	swirl.Rate = 25
	swirl.RotSpeed = NumberRange.new(-120, 120)
	swirl.SpreadAngle = Vector2.new(180, 180)
	swirl.Parent = vortex
	local light = Instance.new("PointLight")
	light.Color = CYAN
	light.Range = 40
	light.Brightness = 3
	light.Parent = vortex

	local anchor = makePart(model, "PortalTitle", Vector3.new(1, 1, 1), center * CFrame.new(0, radius + 6, 0), CYAN)
	anchor.Transparency = 1
	anchor.CanCollide = false
	local gui = Instance.new("BillboardGui")
	gui.Name = "ReturnSign"
	gui.Size = UDim2.new(12, 120, 3.2, 32)
	gui.LightInfluence = 0
	gui.MaxDistance = 150
	gui.Parent = anchor
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.BackgroundTransparency = 1
	title.Text = "↩ RETOUR AU MONDE 1"
	title.TextColor3 = Color3.fromRGB(150, 240, 255)
	title.TextStrokeTransparency = 0
	title.Font = Enum.Font.LuckiestGuy
	title.TextScaled = true
	title.Parent = gui
	local caption = title:Clone()
	caption.Name = "Caption"
	caption.Position = UDim2.new(0.1, 0, 0.62, 0)
	caption.Size = UDim2.new(0.8, 0, 0.36, 0)
	caption.Text = "Touche E"
	caption.TextColor3 = Color3.new(1, 1, 1)
	caption.Parent = gui

	model.Parent = parent
	return model, vortex
end

-- ====== GRAND PANNEAU DU MONDE (au-dessus de l'entrée) ======
local function worldSign(parent)
	local anchor = makePart(parent, "WorldTitle", Vector3.new(1, 1, 1), CFrame.new(RETURN_PORTAL + Vector3.new(40, 34, 0)), CYAN)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	local gui = Instance.new("BillboardGui")
	gui.Name = "WorldSign"
	gui.Size = UDim2.new(26, 160, 6, 40)
	gui.LightInfluence = 0
	gui.MaxDistance = 300
	gui.Parent = anchor
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.7, 0)
	title.BackgroundTransparency = 1
	title.Text = "🌌 NUIT DE CRISTAL 🌌"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(30, 10, 80)
	title.Font = Enum.Font.LuckiestGuy
	title.TextScaled = true
	title.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CYAN),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 225, 255)),
		ColorSequenceKeypoint.new(1, PINK),
	})
	gradient.Parent = title
	CollectionService:AddTag(gradient, "SpinGradient")
	local caption = title:Clone()
	caption.Name = "Caption"
	caption.Position = UDim2.new(0, 0, 0.7, 0)
	caption.Size = UDim2.new(1, 0, 0.3, 0)
	caption.Text = "MONDE 2 • blocs x2000 • brainrots exclusifs • mutation GALAXIE"
	caption.TextColor3 = Color3.fromRGB(255, 220, 110)
	caption.Parent = gui
end

function World2Builder.init(deps)
	local folder = Instance.new("Folder")
	folder.Name = "World2"
	folder.Parent = Workspace

	local half = deps.MineHalf
	local ringInner, ringOuter = half + 3, half + 19
	buildGround(folder, half)
	buildWall(folder)

	-- allées autour de la mine + parvis + tapis roulants vers chaque base
	local paths = Instance.new("Folder")
	paths.Name = "Paths"
	paths.Parent = folder
	local top = 0.12
	local entrances = deps.BaseManager.getEntrances(2)
	local maxX = 0
	for _, entrance in ipairs(entrances) do
		maxX = math.max(maxX, math.abs(entrance.X - O.X))
	end
	local width = deps.BaseManager.WIDTH
	local spanX = math.max(ringOuter, maxX + 9)
	local function pathSlab(name, xa, xb, za, zb)
		slab(paths, name, O.X + xa, O.X + xb, O.Z + za, O.Z + zb, top, PATH)
	end
	pathSlab("Path", -spanX, spanX, ringInner, ringOuter)
	pathSlab("Path", -spanX, spanX, -ringOuter, -ringInner)
	pathSlab("Path", -ringOuter, -ringInner, -ringInner, ringInner)
	pathSlab("Path", ringInner, ringOuter, -ringInner, ringInner)
	-- bordures néon de l'allée
	for _, sz in ipairs({-1, 1}) do
		for _, edgeZ in ipairs({ringInner, ringOuter}) do
			local edge = makePart(paths, "PathGlow", Vector3.new(spanX * 2, 0.1, 0.4), CFrame.new(O + Vector3.new(0, top + 0.05, sz * edgeZ)), CYAN, Enum.Material.Neon)
			edge.CanCollide = false
		end
	end
	local conveyors = Instance.new("Folder")
	conveyors.Name = "Conveyors"
	conveyors.Parent = folder
	for _, rowSign in ipairs({-1, 1}) do
		local frontZ
		for _, entrance in ipairs(entrances) do
			if math.sign(entrance.Z - O.Z) == rowSign then
				frontZ = entrance.Z - O.Z
			end
		end
		if frontZ then
			local edge = frontZ + rowSign * 5
			pathSlab("Plaza", -maxX - width / 2 - 6, maxX + width / 2 + 6, edge - rowSign * 16, edge)
		end
	end
	for _, entrance in ipairs(entrances) do
		local rel = entrance - O
		local minePoint = O + Vector3.new(rel.X, 0, math.sign(rel.Z) * (ringOuter + 1))
		local startZ = rel.Z - math.sign(rel.Z) * 11
		pathSlab("Path", rel.X - 7, rel.X + 7, math.min(startZ, minePoint.Z - O.Z), math.max(startZ, minePoint.Z - O.Z))
		WorldBuilder.doubleConveyor(conveyors, entrance, minePoint)
	end
	-- l'allée vers le portail de retour (à l'ouest)
	pathSlab("Path", RETURN_PORTAL.X - O.X + 13, -ringOuter, -8, 8)
	-- l'allée + les tapis vers la Cristallerie (à l'est)
	pathSlab("Path", ringOuter, SHOP_POSITION.X - O.X - 15, -8, 8)
	WorldBuilder.doubleConveyor(conveyors, SHOP_POSITION - Vector3.new(19, 0, 0), O + Vector3.new(ringOuter + 1, 0, 0))

	-- décors
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = folder
	local random = Random.new(42)
	local basesHalfX = maxX + width / 2 + 10
	local statueSpots = {}
	local function isFree(rel)
		local x, z = math.abs(rel.X), math.abs(rel.Z)
		if x < spanX + 10 and z < ringOuter + 10 then return false end
		if x < basesHalfX and z > ringOuter - 5 then return false end
		if (rel - (RETURN_PORTAL - O)).Magnitude < 26 then return false end
		if math.abs(rel.X - (SHOP_POSITION.X - O.X)) < 30 and math.abs(rel.Z) < 32 then return false end -- la Cristallerie
		if math.abs(rel.Z) < 12 and rel.X > 0 then return false end -- allée de la Cristallerie
		if math.abs(rel.Z) < 12 and rel.X < 0 then return false end -- allée du portail
		for _, spot in ipairs(statueSpots) do
			if (rel - spot).Magnitude < 14 then return false end
		end
		return x < WALL_X - 8 and z < WALL_Z - 8
	end

	-- STATUES HOLOGRAMMES des brainrots du monde 2 (de chaque côté de la map)
	local statues = Instance.new("Folder")
	statues.Name = "Holograms"
	statues.Parent = folder
	local names = {}
	for _, c in ipairs(GameConfig.CARDS) do
		if c.World == 2 then
			table.insert(names, c.Name)
		end
	end
	local spots = {}
	for _, z in ipairs({-170, -120, -70, 70, 120, 170}) do
		table.insert(spots, Vector3.new(-160, 0, z))
	end
	for _, z in ipairs({-160, -100, -40, 40, 100, 160}) do
		table.insert(spots, Vector3.new(160, 0, z))
	end
	for index, name in ipairs(names) do
		local rel = spots[index]
		if rel then
			table.insert(statueSpots, rel)
			local facing = Vector3.new(-rel.X, 0, -rel.Z).Unit
			hologramStatue(statues, O + rel, name, facing)
		end
	end

	-- arbres de cristal, lampadaires et petits cristaux
	local placed, attempts = 0, 0
	while placed < 40 and attempts < 3000 do
		attempts += 1
		local rel = Vector3.new(random:NextNumber(-WALL_X, WALL_X), 0, random:NextNumber(-WALL_Z, WALL_Z))
		if isFree(rel) then
			crystalTree(decor, O + rel, random:NextNumber(0.9, 1.4), random)
			table.insert(statueSpots, rel)
			placed += 1
		end
	end
	for _, sz in ipairs({-1, 1}) do
		for x = -spanX + 6, spanX - 6, 24 do
			lamp(decor, O + Vector3.new(x, top, sz * (ringOuter + 2)))
		end
	end
	local cubes, tries = 0, 0
	while cubes < 90 and tries < 4000 do
		tries += 1
		local rel = Vector3.new(random:NextNumber(-WALL_X + 4, WALL_X - 4), 0, random:NextNumber(-WALL_Z + 4, WALL_Z - 4))
		local x, z = math.abs(rel.X), math.abs(rel.Z)
		local onMine = x < ringOuter + 2 and z < ringOuter + 2
		local onBases = x < basesHalfX and z > ringOuter - 5
		local onShop = math.abs(rel.X - (SHOP_POSITION.X - O.X)) < 30 and math.abs(rel.Z) < 32
		local onPortal = (rel - (RETURN_PORTAL - O)).Magnitude < 22
		if not onMine and not onBases and not onShop and not onPortal then
			glowCube(decor, O + rel + Vector3.new(0, 0.9, 0), random:NextNumber(0.9, 1.5), random:NextNumber() < 0.55 and VIOLET or CYAN, 8)
			cubes += 1
		end
	end

	-- îles flottantes et grands cristaux qui tournent dans le ciel
	local sky = Instance.new("Folder")
	sky.Name = "SkyIslands"
	sky.Parent = folder
	for index, spot in ipairs({
		{-180, 70, -120, 26}, {190, 85, -40, 30}, {-60, 110, 230, 34}, {120, 95, 210, 24},
		{-230, 120, 160, 28}, {40, 130, -240, 36}, {250, 75, 170, 22},
	}) do
		floatingIsland(sky, O + Vector3.new(spot[1], spot[2], spot[3]), spot[4], Random.new(index))
	end
	for index, spot in ipairs({{0, 70, 0, 14}, {-120, 90, 0, 8}, {120, 90, 0, 8}}) do
		local shard = makePart(sky, "SkyCrystal", Vector3.new(spot[4], spot[4] * 2.6, spot[4]), CFrame.new(O + Vector3.new(spot[1], spot[2], spot[3])) * CFrame.Angles(0, 0, math.rad(index == 1 and 0 or 15)), index == 1 and VIOLET or CYAN, Enum.Material.Neon)
		shard.Transparency = 0.25
		shard.CanCollide = false
		shard.CanQuery = false
		shard:SetAttribute("SpinSpeed", index == 1 and 0.4 or -0.6)
		CollectionService:AddTag(shard, "PortalSpin")
		local light = Instance.new("PointLight")
		light.Color = shard.Color
		light.Range = 60
		light.Brightness = 2
		light.Parent = shard
	end

	local _, returnVortex = buildReturnPortal(folder)
	worldSign(folder)
	World2Builder.returnVortex = returnVortex
	return folder
end

return World2Builder
