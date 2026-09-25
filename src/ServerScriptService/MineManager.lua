-- ModuleScript : la zone de minage.
-- C'est un grand trou rempli de blocs, comme dans Minecraft : tu casses le sol et tu descends
-- couche par couche. Seuls les blocs visibles (à côté d'un trou) existent vraiment, pour que le jeu reste fluide.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CONFIG = GameConfig.MINE
local CARDS = GameConfig.CARDS

local MineManager = {}

local BLOCK = CONFIG.BlockSize
local GRID = CONFIG.Grid
local DEPTH = CONFIG.Depth
local HALF = GRID * BLOCK / 2
local CENTER = CONFIG.Center

local mineFolder
local blocksFolder
local cells = {} -- cells[key] = "mined" | Part
local blockData = {} -- blockData[part] = {i, j, k, hp, maxHp, layer, card}

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

-- ====== TIRAGE D'UNE CARTE (plus profond = plus de chance d'avoir du rare) ======
local function pickCard(layerIndex)
	local luck = 1 + (layerIndex - 1) * CONFIG.LuckPerLayer
	local weights = {}
	local total = 0
	for index, card in ipairs(CARDS) do
		local order = GameConfig.RARITIES[card.Rarity].Order
		local weight = card.Weight * luck ^ ((order - 1) * 0.5)
		weights[index] = weight
		total += weight
	end
	local roll = math.random() * total
	for index, card in ipairs(CARDS) do
		roll -= weights[index]
		if roll <= 0 then
			return card
		end
	end
	return CARDS[1]
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
	}

	-- Minerai brainrot : le bloc contient une carte, la couleur des cristaux indique la rareté
	local oreChance = CONFIG.OreChanceBase + (j - 1) * CONFIG.OreChancePerLayer
	if math.random() < oreChance then
		local card = pickCard(j)
		data.card = card
		part.Name = "OreBlock"
		for _ = 1, 5 do
			local crystal = Instance.new("Part")
			crystal.Name = "Crystal"
			crystal.Size = Vector3.new(0.9, 0.9, 0.9)
			crystal.Material = Enum.Material.Neon
			crystal.Color = card.Color
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
		if GameConfig.RARITIES[card.Rarity].Order >= 4 then
			local light = Instance.new("PointLight")
			light.Color = card.Color
			light.Range = 8
			light.Brightness = 1.5
			light.Parent = part
		end
	end

	part:SetAttribute("HP", data.hp)
	part:SetAttribute("MaxHP", data.maxHp)
	part:SetAttribute("LayerName", layer.Name)
	part:SetAttribute("MinTier", layer.MinTier)
	part.Parent = blocksFolder

	cells[key(i, j, k)] = part
	blockData[part] = data
end

-- ====== CONSTRUCTION DU TROU, DES MURS ET DU DECOR ======
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
	part.Parent = parent
	return part
end

local function buildPit()
	local totalDepth = DEPTH * BLOCK
	local wallColor = Color3.fromRGB(55, 50, 50)
	local thick = 6

	-- Le sol de toute la map, avec un trou au milieu pour la mine
	local extent = 190
	local groundColor = Color3.fromRGB(80, 160, 70)
	local grounds = {
		{Vector3.new(extent * 2, 4, extent - HALF), Vector3.new(0, -2, -(HALF + extent) / 2)},
		{Vector3.new(extent * 2, 4, extent - HALF), Vector3.new(0, -2, (HALF + extent) / 2)},
		{Vector3.new(extent - HALF, 4, HALF * 2), Vector3.new(-(HALF + extent) / 2, -2, 0)},
		{Vector3.new(extent - HALF, 4, HALF * 2), Vector3.new((HALF + extent) / 2, -2, 0)},
	}
	for _, g in ipairs(grounds) do
		makeStatic("Ground", g[1], CFrame.new(CENTER + g[2]), groundColor, Enum.Material.Grass, mineFolder)
	end

	-- Murs du trou (on les voit seulement quand on creuse jusqu'au bord) du trou (on les voit seulement quand on creuse jusqu'au bord)
	local walls = {
		{Vector3.new(GRID * BLOCK + thick * 2, totalDepth, thick), Vector3.new(0, -totalDepth / 2, -HALF - thick / 2)},
		{Vector3.new(GRID * BLOCK + thick * 2, totalDepth, thick), Vector3.new(0, -totalDepth / 2, HALF + thick / 2)},
		{Vector3.new(thick, totalDepth, GRID * BLOCK), Vector3.new(-HALF - thick / 2, -totalDepth / 2, 0)},
		{Vector3.new(thick, totalDepth, GRID * BLOCK), Vector3.new(HALF + thick / 2, -totalDepth / 2, 0)},
	}
	for _, wall in ipairs(walls) do
		makeStatic("PitWall", wall[1], CFrame.new(CENTER + wall[2]), wallColor, Enum.Material.Slate, mineFolder)
	end

	-- Bedrock tout en bas
	makeStatic(
		"Bedrock",
		Vector3.new(GRID * BLOCK + thick * 2, 4, GRID * BLOCK + thick * 2),
		CFrame.new(CENTER + Vector3.new(0, -totalDepth - 2, 0)),
		Color3.fromRGB(25, 25, 25),
		Enum.Material.Slate,
		mineFolder
	)

	-- Bordure du trou (petite marche en pierre) + arche "ZONE DE MINAGE"
	local rimColor = Color3.fromRGB(110, 110, 110)
	local rim = 3
	local rims = {
		{Vector3.new(GRID * BLOCK + rim * 2, 0.6, rim), Vector3.new(0, 0.3, -HALF - rim / 2)},
		{Vector3.new(GRID * BLOCK + rim * 2, 0.6, rim), Vector3.new(0, 0.3, HALF + rim / 2)},
		{Vector3.new(rim, 0.6, GRID * BLOCK), Vector3.new(-HALF - rim / 2, 0.3, 0)},
		{Vector3.new(rim, 0.6, GRID * BLOCK), Vector3.new(HALF + rim / 2, 0.3, 0)},
	}
	for _, r in ipairs(rims) do
		local part = makeStatic("Rim", r[1], CFrame.new(CENTER + r[2]), rimColor, Enum.Material.Cobblestone, mineFolder)
		part.TopSurface = Enum.SurfaceType.Studs
	end

	for _, side in ipairs({-1, 1}) do
		local pillar = makeStatic(
			"ArchPillar",
			Vector3.new(3, 16, 3),
			CFrame.new(CENTER + Vector3.new(side * 12, 8, -HALF - rim - 2)),
			Color3.fromRGB(100, 70, 40),
			Enum.Material.Wood,
			mineFolder
		)
		local torch = Instance.new("PointLight")
		torch.Color = Color3.fromRGB(255, 180, 90)
		torch.Range = 20
		torch.Brightness = 2
		torch.Parent = pillar
		local fire = Instance.new("Fire")
		fire.Size = 3
		fire.Heat = 4
		local fireHolder = makeStatic(
			"Torch",
			Vector3.new(1, 1, 1),
			CFrame.new(CENTER + Vector3.new(side * 12, 16.5, -HALF - rim - 2)),
			Color3.fromRGB(60, 40, 20),
			Enum.Material.Wood,
			mineFolder
		)
		fire.Parent = fireHolder
	end

	local beam = makeStatic(
		"ArchBeam",
		Vector3.new(30, 4, 3),
		CFrame.new(CENTER + Vector3.new(0, 16, -HALF - rim - 2)),
		Color3.fromRGB(100, 70, 40),
		Enum.Material.Wood,
		mineFolder
	)
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(600, 80)
		gui.Parent = beam
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = "⛏️ ZONE DE MINAGE ⛏️"
		text.TextColor3 = Color3.fromRGB(255, 220, 120)
		text.TextStrokeTransparency = 0
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.Parent = gui
	end

	-- Lumière au fond de la mine pour qu'on voie quelque chose
	local glow = makeStatic(
		"DeepGlow",
		Vector3.new(1, 1, 1),
		CFrame.new(CENTER + Vector3.new(0, -totalDepth / 2, 0)),
		Color3.new(1, 1, 1),
		nil,
		mineFolder
	)
	glow.Transparency = 1
	glow.CanCollide = false
	glow.CanQuery = false
	local deepLight = Instance.new("PointLight")
	deepLight.Range = 60
	deepLight.Brightness = 0.6
	deepLight.Color = Color3.fromRGB(255, 200, 150)
	deepLight.Parent = glow
end

-- Position au bord de la mine (pour remonter)
function MineManager.getSurfaceCFrame()
	return CFrame.new(CENTER + Vector3.new(0, 4, -HALF - 8)) * CFrame.Angles(0, math.rad(180), 0)
end

function MineManager.isInsidePit(position)
	local rel = position - CENTER
	return math.abs(rel.X) < HALF and math.abs(rel.Z) < HALF and rel.Y < -1
end

-- ====== REGENERATION DE LA MINE ======
function MineManager.reset()
	-- Remonte les joueurs qui sont dans le trou
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

	Workspace:SetAttribute("MineResetAt", Workspace:GetServerTimeNow() + CONFIG.ResetInterval)
end

-- ====== FRAPPER UN BLOC ======
-- Renvoie nil si rien n'est cassé, sinon une table {position, layer, card}
-- Renvoie aussi un message d'erreur éventuel (pioche trop faible, etc.)
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
		chunk.Color = data.card and data.card.Color or data.baseColor
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
		card = data.card,
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

	-- Régénération automatique de la mine
	task.spawn(function()
		while true do
			local resetAt = Workspace:GetAttribute("MineResetAt")
			local remaining = resetAt - Workspace:GetServerTimeNow()
			if remaining <= 0 then
				MineManager.reset()
			end
			task.wait(1)
		end
	end)
end

MineManager.HALF = HALF

return MineManager
