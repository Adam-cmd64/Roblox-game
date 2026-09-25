-- ModuleScript : la zone de minage.
-- C'est un grand trou rempli de blocs, comme dans Minecraft : tu casses le sol et tu descends
-- couche par couche. Seuls les blocs visibles (à côté d'un trou) existent vraiment, pour que le jeu reste fluide.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CONFIG = GameConfig.MINE

local MineManager = {}

local BLOCK = CONFIG.BlockSize
local GRID = CONFIG.Grid
local DEPTH = CONFIG.Depth
local HALF = GRID * BLOCK / 2
local CENTER = CONFIG.Center
local RIM = 3

MineManager.HALF = HALF

local mineFolder
local blocksFolder
local cells = {} -- cells[key] = "mined" | Part
local blockData = {} -- blockData[part] = {i, j, k, hp, maxHp, layer, ore}

-- Couleurs des cristaux de minerai brainrot
local ORE_COLORS = {
	Color3.fromRGB(255, 80, 200),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(60, 220, 255),
}

local function key(i, j, k)
	return i .. "," .. j .. "," .. k
end

local function cellPosition(i, j, k)
	return CENTER + Vector3.new(
		(i - 0.5) * BLOCK - HALF,
		-(j - 0.5) * BLOCK,
		(k - 0.5) * BLOCK - HALF
	)
end

-- ====== CREATION D'UN BLOC ======
local function spawnBlock(i, j, k)
	if i < 1 or i > GRID or k < 1 or k > GRID or j < 1 or j > DEPTH then return end
	if cells[key(i, j, k)] then return end

	local layer = GameConfig.getLayer(j)

	local part = Instance.new("Part")
	part.Name = "Block"
	part.Size = Vector3.new(BLOCK, BLOCK, BLOCK)
	part.Position = cellPosition(i, j, k)
	part.Anchored = true
	part.Material = layer.Material
	part.Color = layer.Color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	local data = {
		i = i, j = j, k = k,
		hp = layer.HP,
		maxHp = layer.HP,
		layer = layer,
		baseColor = layer.Color,
		ore = false,
	}

	-- Minerai brainrot : le bloc contient une carte (tirée au sort au moment où on le casse)
	local oreChance = CONFIG.OreChanceBase + (j - 1) * CONFIG.OreChancePerLayer
	if math.random() < oreChance then
		data.ore = true
		part.Name = "OreBlock"
		local oreColor = ORE_COLORS[math.random(1, #ORE_COLORS)]
		for _ = 1, 5 do
			local crystal = Instance.new("Part")
			crystal.Name = "Crystal"
			crystal.Size = Vector3.new(0.9, 0.9, 0.9)
			crystal.Material = Enum.Material.Neon
			crystal.Color = oreColor
			crystal.Anchored = true
			crystal.CanCollide = false
			crystal.CanQuery = false
			crystal.CanTouch = false
			local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * (BLOCK - 1.2)
			-- colle chaque cristal sur une face du bloc
			local axis = math.random(1, 3)
			local sign = math.random(0, 1) == 0 and -1 or 1
			if axis == 1 then
				offset = Vector3.new(sign * (BLOCK / 2 - 0.35), offset.Y, offset.Z)
			elseif axis == 2 then
				offset = Vector3.new(offset.X, sign * (BLOCK / 2 - 0.35), offset.Z)
			else
				offset = Vector3.new(offset.X, offset.Y, sign * (BLOCK / 2 - 0.35))
			end
			crystal.CFrame = CFrame.new(part.Position + offset) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
			crystal.Parent = part
		end
		local light = Instance.new("PointLight")
		light.Color = oreColor
		light.Range = 7
		light.Brightness = 1.2
		light.Parent = part
	end

	part:SetAttribute("HP", data.hp)
	part:SetAttribute("MaxHP", data.maxHp)
	part:SetAttribute("LayerName", layer.Name)
	part:SetAttribute("MinTier", layer.MinTier)
	part:SetAttribute("Ore", data.ore)
	part.Parent = blocksFolder

	cells[key(i, j, k)] = part
	blockData[part] = data
end

-- ====== CONSTRUCTION ======
local function makeStatic(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or mineFolder
	return part
end

local function addLight(part, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = part
	return light
end

local function signText(part, face, value, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextColor3 = color or Color3.fromRGB(255, 240, 220)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = gui
	return label
end

local function buildPit()
	local totalDepth = DEPTH * BLOCK
	local wallColor = Color3.fromRGB(55, 50, 50)
	local thick = 6

	-- Le sol de toute la map, avec un trou au milieu pour la mine
	local extent = 200
	local groundColor = Color3.fromRGB(85, 165, 70)
	local grounds = {
		{Vector3.new(extent * 2, 4, extent - HALF), Vector3.new(0, -2, -(HALF + extent) / 2)},
		{Vector3.new(extent * 2, 4, extent - HALF), Vector3.new(0, -2, (HALF + extent) / 2)},
		{Vector3.new(extent - HALF, 4, HALF * 2), Vector3.new(-(HALF + extent) / 2, -2, 0)},
		{Vector3.new(extent - HALF, 4, HALF * 2), Vector3.new((HALF + extent) / 2, -2, 0)},
	}
	for _, g in ipairs(grounds) do
		makeStatic("Ground", g[1], CFrame.new(CENTER + g[2]), groundColor, Enum.Material.Grass)
	end

	-- Murs du trou (visibles quand on creuse jusqu'au bord)
	local walls = {
		{Vector3.new(GRID * BLOCK + thick * 2, totalDepth, thick), Vector3.new(0, -totalDepth / 2, -HALF - thick / 2)},
		{Vector3.new(GRID * BLOCK + thick * 2, totalDepth, thick), Vector3.new(0, -totalDepth / 2, HALF + thick / 2)},
		{Vector3.new(thick, totalDepth, GRID * BLOCK), Vector3.new(-HALF - thick / 2, -totalDepth / 2, 0)},
		{Vector3.new(thick, totalDepth, GRID * BLOCK), Vector3.new(HALF + thick / 2, -totalDepth / 2, 0)},
	}
	for _, wall in ipairs(walls) do
		makeStatic("PitWall", wall[1], CFrame.new(CENTER + wall[2]), wallColor, Enum.Material.Slate)
	end

	makeStatic(
		"Bedrock",
		Vector3.new(GRID * BLOCK + thick * 2, 4, GRID * BLOCK + thick * 2),
		CFrame.new(CENTER + Vector3.new(0, -totalDepth - 2, 0)),
		Color3.fromRGB(25, 25, 25),
		Enum.Material.Slate
	)

	-- Bordure en pavés autour du trou
	local rims = {
		{Vector3.new(GRID * BLOCK + RIM * 2, 0.6, RIM), Vector3.new(0, 0.3, -HALF - RIM / 2)},
		{Vector3.new(GRID * BLOCK + RIM * 2, 0.6, RIM), Vector3.new(0, 0.3, HALF + RIM / 2)},
		{Vector3.new(RIM, 0.6, GRID * BLOCK), Vector3.new(-HALF - RIM / 2, 0.3, 0)},
		{Vector3.new(RIM, 0.6, GRID * BLOCK), Vector3.new(HALF + RIM / 2, 0.3, 0)},
	}
	for _, r in ipairs(rims) do
		makeStatic("Rim", r[1], CFrame.new(CENTER + r[2]), Color3.fromRGB(115, 115, 115), Enum.Material.Cobblestone)
	end

	-- Lanternes aux 4 coins
	for _, sx in ipairs({-1, 1}) do
		for _, sz in ipairs({-1, 1}) do
			local base = CENTER + Vector3.new(sx * (HALF + RIM / 2), 0, sz * (HALF + RIM / 2))
			makeStatic("LanternPost", Vector3.new(0.8, 7, 0.8), CFrame.new(base + Vector3.new(0, 3.5, 0)), Color3.fromRGB(80, 55, 35), Enum.Material.Wood)
			local lamp = makeStatic("Lantern", Vector3.new(1.4, 1.4, 1.4), CFrame.new(base + Vector3.new(0, 7.6, 0)), Color3.fromRGB(255, 190, 90), Enum.Material.Neon)
			addLight(lamp, Color3.fromRGB(255, 180, 90), 24, 1.6)
		end
	end

	-- ====== ENTREE DE LA MINE (portique en bois + rails + wagonnet) ======
	local wood = Color3.fromRGB(110, 75, 45)
	local darkWood = Color3.fromRGB(75, 50, 30)
	local gateX = HALF + RIM + 10
	for _, z in ipairs({-8, 8}) do
		makeStatic("GatePost", Vector3.new(2.4, 16, 2.4), CFrame.new(CENTER + Vector3.new(gateX, 8, z)), wood, Enum.Material.Wood)
		local lamp = makeStatic("GateLamp", Vector3.new(1.2, 1.6, 1.2), CFrame.new(CENTER + Vector3.new(gateX - 1.6, 11, z)), Color3.fromRGB(255, 200, 100), Enum.Material.Neon)
		addLight(lamp, Color3.fromRGB(255, 180, 90), 20, 1.8)
	end
	makeStatic("GateBeam", Vector3.new(2.6, 2.4, 20), CFrame.new(CENTER + Vector3.new(gateX, 16.5, 0)), darkWood, Enum.Material.Wood)
	makeStatic("GateBrace", Vector3.new(1.4, 1.4, 16), CFrame.new(CENTER + Vector3.new(gateX, 13.6, 0)), wood, Enum.Material.Wood)
	local sign = makeStatic("GateSign", Vector3.new(0.6, 4, 13), CFrame.new(CENTER + Vector3.new(gateX - 1.5, 19.6, 0)), Color3.fromRGB(60, 40, 25), Enum.Material.Wood)
	signText(sign, Enum.NormalId.Left, "⛏️ MINE", Color3.fromRGB(255, 235, 200))
	signText(sign, Enum.NormalId.Right, "⛏️ MINE", Color3.fromRGB(255, 235, 200))

	-- Rails qui partent vers le trou
	local railStart, railEnd = HALF + RIM + 1, gateX + 18
	local railLength = railEnd - railStart
	local railCenter = (railStart + railEnd) / 2
	for _, z in ipairs({-1.4, 1.4}) do
		makeStatic("Rail", Vector3.new(railLength, 0.3, 0.3), CFrame.new(CENTER + Vector3.new(railCenter, 0.45, z)), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
	end
	for x = railStart + 1, railEnd - 1, 2 do
		makeStatic("Sleeper", Vector3.new(0.7, 0.25, 4.2), CFrame.new(CENTER + Vector3.new(x, 0.15, 0)), darkWood, Enum.Material.Wood)
	end

	-- Wagonnet
	local cartX = gateX + 7
	makeStatic("Cart", Vector3.new(4.5, 2.2, 3.2), CFrame.new(CENTER + Vector3.new(cartX, 1.9, 0)), Color3.fromRGB(95, 95, 100), Enum.Material.DiamondPlate)
	makeStatic("CartRim", Vector3.new(4.8, 0.3, 3.5), CFrame.new(CENTER + Vector3.new(cartX, 3.05, 0)), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
	makeStatic("CartLoad", Vector3.new(3.8, 0.8, 2.6), CFrame.new(CENTER + Vector3.new(cartX, 3.0, 0)), Color3.fromRGB(255, 90, 200), Enum.Material.Neon)
	for _, dx in ipairs({-1.4, 1.4}) do
		for _, z in ipairs({-1.4, 1.4}) do
			local wheel = makeStatic("Wheel", Vector3.new(0.4, 1.2, 1.2), CFrame.new(CENTER + Vector3.new(cartX + dx, 0.75, z)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end

	-- Lumière douce au fond de la mine
	local glow = makeStatic("DeepGlow", Vector3.new(1, 1, 1), CFrame.new(CENTER + Vector3.new(0, -totalDepth / 2, 0)), Color3.new(1, 1, 1))
	glow.Transparency = 1
	glow.CanCollide = false
	glow.CanQuery = false
	addLight(glow, Color3.fromRGB(255, 200, 150), 60, 0.6)
end

-- Position au bord de la mine, devant le portique (pour y aller / remonter)
function MineManager.getSurfaceCFrame()
	local position = CENTER + Vector3.new(HALF + RIM + 5, 4, 0)
	return CFrame.lookAt(position, position - Vector3.new(1, 0, 0))
end

function MineManager.isInsidePit(position)
	local rel = position - CENTER
	return math.abs(rel.X) < HALF and math.abs(rel.Z) < HALF and rel.Y < -1
end

-- ====== REGENERATION DE LA MINE ======
function MineManager.reset()
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and MineManager.isInsidePit(root.Position) then
			player.Character:PivotTo(MineManager.getSurfaceCFrame())
		end
	end

	blocksFolder:ClearAllChildren()
	table.clear(cells)
	table.clear(blockData)

	for i = 1, GRID do
		for k = 1, GRID do
			spawnBlock(i, 1, k)
		end
	end

	local now = Workspace:GetServerTimeNow()
	Workspace:SetAttribute("MineResetStart", now)
	Workspace:SetAttribute("MineResetAt", now + CONFIG.ResetInterval)
end

-- ====== FRAPPER UN BLOC ======
-- Renvoie nil si rien n'est cassé, sinon {position, layer, layerIndex, ore}
-- Renvoie aussi un message d'erreur éventuel (pioche trop faible)
function MineManager.hit(block, damage, pickaxeTier)
	local data = blockData[block]
	if not data then return nil end

	if pickaxeTier < data.layer.MinTier then
		local needed = GameConfig.PICKAXES[data.layer.MinTier]
		return nil, "Il te faut au moins une " .. needed.Name .. " pour casser : " .. data.layer.Name
	end

	data.hp -= damage
	block:SetAttribute("HP", math.max(data.hp, 0))

	if data.hp > 0 then
		-- Le bloc s'assombrit au fur et à mesure qu'il se fissure
		local ratio = data.hp / data.maxHp
		block.Color = data.baseColor:Lerp(Color3.new(0, 0, 0), (1 - ratio) * 0.55)
		return nil
	end

	-- Bloc cassé : on le retire et on fait apparaître les blocs autour (on creuse vers le bas !)
	local position = block.Position
	local i, j, k = data.i, data.j, data.k
	cells[key(i, j, k)] = "mined"
	blockData[block] = nil
	block:Destroy()

	spawnBlock(i + 1, j, k)
	spawnBlock(i - 1, j, k)
	spawnBlock(i, j + 1, k)
	spawnBlock(i, j - 1, k)
	spawnBlock(i, j, k + 1)
	spawnBlock(i, j, k - 1)

	-- Débris qui volent
	for _ = 1, 6 do
		local chunk = Instance.new("Part")
		chunk.Size = Vector3.new(0.8, 0.8, 0.8)
		chunk.Material = data.layer.Material
		chunk.Color = data.ore and ORE_COLORS[math.random(1, #ORE_COLORS)] or data.baseColor
		chunk.CanCollide = false
		chunk.CanQuery = false
		chunk.CanTouch = false
		chunk.Position = position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2
		chunk.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), math.random(18, 30), math.random(-15, 15))
		chunk.Parent = Workspace
		Debris:AddItem(chunk, 1.2)
	end

	return {
		position = position,
		layer = data.layer,
		layerIndex = j,
		ore = data.ore,
	}
end

function MineManager.isBlock(instance)
	return blockData[instance] ~= nil
end

function MineManager.init()
	mineFolder = Instance.new("Folder")
	mineFolder.Name = "Mine"
	mineFolder.Parent = Workspace

	blocksFolder = Instance.new("Folder")
	blocksFolder.Name = "Blocks"
	blocksFolder.Parent = mineFolder

	buildPit()
	MineManager.reset()

	-- Régénération automatique
	task.spawn(function()
		while true do
			task.wait(1)
			if Workspace:GetAttribute("MineResetAt") - Workspace:GetServerTimeNow() <= 0 then
				MineManager.reset()
			end
		end
	end)
end

return MineManager
