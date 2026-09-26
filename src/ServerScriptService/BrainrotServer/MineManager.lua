-- ModuleScript : la zone de minage.
-- C'est un grand trou rempli de blocs, comme dans Minecraft : tu casses le sol et tu descends
-- couche par couche. Seuls les blocs visibles (à côté d'un trou) existent vraiment, pour que le jeu reste fluide.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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
	if j > CONFIG.NoOreLayers and math.random() < oreChance then
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

local function buildPit()
	local totalDepth = DEPTH * BLOCK
	local wallColor = Color3.fromRGB(55, 50, 50)
	local thick = 6

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

	-- ====== TEXTE FLOTTANT AU-DESSUS DE LA MINE ======
	local marker = makeStatic("MineMarker", Vector3.new(1, 1, 1), CFrame.new(CENTER + Vector3.new(0, 30, 0)), Color3.new(1, 1, 1))
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	local title = Instance.new("BillboardGui")
	title.Size = UDim2.new(0, 360, 0, 90)
	title.MaxDistance = 600
	title.LightInfluence = 0
	title.Parent = marker
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⛏ MINE ⛏"
	titleLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	titleLabel.TextStrokeTransparency = 0
	titleLabel.Font = Enum.Font.LuckiestGuy
	titleLabel.TextScaled = true
	titleLabel.Parent = title

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

	-- (les débris et le son sont joués par chaque client : voir Effects.lua)

	return {
		position = position,
		layer = data.layer,
		layerIndex = j,
		ore = data.ore,
		color = data.baseColor,
	}
end

function MineManager.isBlock(instance)
	return blockData[instance] ~= nil
end

function MineManager.init(deps)
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
