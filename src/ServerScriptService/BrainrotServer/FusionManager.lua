-- ModuleScript : la MACHINE DE FUSION.
--   - une grande machine majestueuse à l'ouest de la mine (bouton E : ouvre la fenêtre)
--   - on met 3 brainrots du sac -> on garde le meilleur des 3 (nom, mutation, numéro)
--     et il devient FUSIONNÉ : il rapporte la somme des 3 + 10 % (GameConfig.FUSION)
--   - les minerais des 3 cartes sont comptés dans le revenu (puis retirés de la carte gardée)
--   - on peut refusionner une carte fusionnée (FUSION ++, +++...)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local CONFIG = GameConfig.FUSION

local FusionManager = {}

local deps
local busy = {}
local core -- la sphère d'énergie au centre (elle flashe à chaque fusion)

local VIOLET = Color3.fromRGB(160, 70, 255)
local CYAN = Color3.fromRGB(70, 225, 255)
local PINK = Color3.fromRGB(255, 90, 220)
local GOLD = Color3.fromRGB(255, 210, 80)
local STONE = Color3.fromRGB(46, 40, 66)
local STONE_LIGHT = Color3.fromRGB(78, 70, 104)

local function makePart(parent, name, size, cframe, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

-- Cylindre debout (les cylindres Roblox sont couchés sur l'axe X)
local function disc(parent, name, diameter, height, cframe, color, material)
	local part = makePart(parent, name, Vector3.new(height, diameter, diameter), cframe * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
	return part
end

local function light(parent, color, range, brightness)
	local pointLight = Instance.new("PointLight")
	pointLight.Color = color
	pointLight.Range = range
	pointLight.Brightness = brightness
	pointLight.Parent = parent
	return pointLight
end

local function sparkles(parent, color, rate)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "FusionSparkles"
	particles.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	particles.LightEmission = 1
	particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
	particles.Lifetime = NumberRange.new(0.8, 1.6)
	particles.Rate = rate
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = parent
	return particles
end

local function beam(from, to, color)
	local a0 = Instance.new("Attachment")
	a0.Parent = from
	local a1 = Instance.new("Attachment")
	a1.Parent = to
	local ray = Instance.new("Beam")
	ray.Attachment0 = a0
	ray.Attachment1 = a1
	ray.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	ray.LightEmission = 1
	ray.Width0 = 0.7
	ray.Width1 = 0.35
	ray.FaceCamera = true
	ray.Transparency = NumberSequence.new(0.15)
	ray.TextureSpeed = 2
	ray.Parent = from
	return ray
end

-- ====== LA MACHINE ======
local function buildMachine()
	local position = CONFIG.Position
	local facing = Vector3.new(-position.X, 0, -position.Z).Unit
	local base = CFrame.lookAt(position, position + facing) -- l'avant (-Z) regarde le centre de la map

	local model = Instance.new("Model")
	model.Name = "FusionMachine"

	-- Socle en 3 marches rondes, avec des anneaux de néon
	local steps = {{34, 0}, {28, 1.2}, {22, 2.4}}
	for index, step in ipairs(steps) do
		disc(model, "Platform", step[1], 1.2, base * CFrame.new(0, step[2] + 0.6, 0), index % 2 == 1 and STONE or STONE_LIGHT)
		disc(model, "PlatformRing", step[1] + 0.6, 0.3, base * CFrame.new(0, step[2] + 1.05, 0), index == 2 and CYAN or VIOLET, Enum.Material.Neon)
	end
	local top = 3.6
	-- escalier devant
	for i = 1, 3 do
		makePart(model, "Stair", Vector3.new(8, 1.2 * i, 2.4), base * CFrame.new(0, 0.6 * i, -17.6 + (i - 1) * 2.4), STONE_LIGHT)
	end

	-- Cœur : cuve en verre + sphère d'énergie + anneaux qui tournent (effet gyroscope)
	local coreCenter = base * CFrame.new(0, top + 7.5, 0)
	disc(model, "CoreBase", 9, 1.6, base * CFrame.new(0, top + 0.8, 0), STONE_LIGHT)
	disc(model, "CoreBaseGlow", 9.6, 0.4, base * CFrame.new(0, top + 1.5, 0), PINK, Enum.Material.Neon)
	local glass = disc(model, "CoreGlass", 7, 11, base * CFrame.new(0, top + 7, 0), Color3.fromRGB(190, 170, 255), Enum.Material.Glass)
	glass.Transparency = 0.6
	glass.CanCollide = false
	core = makePart(model, "Core", Vector3.new(4, 4, 4), coreCenter, VIOLET, Enum.Material.Neon, Enum.PartType.Ball)
	core.CanCollide = false
	light(core, VIOLET, 28, 3)
	sparkles(core, VIOLET, 18)
	for index, ring in ipairs({{9.5, CYAN, 1.3, 60}, {11, PINK, -0.9, -50}, {12.5, GOLD, 0.6, 80}}) do
		local part = disc(model, "CoreRing", ring[1], 0.25, coreCenter * CFrame.Angles(math.rad(ring[4]), 0, 0), ring[2], Enum.Material.Neon)
		part.Transparency = 0.55
		part.CanCollide = false
		part:SetAttribute("SpinSpeed", ring[3])
		CollectionService:AddTag(part, "PortalSpin")
		if index == 1 then
			light(part, CYAN, 16, 1.5)
		end
	end
	-- couronne au-dessus de la cuve
	disc(model, "Crown", 8.4, 1.2, base * CFrame.new(0, top + 13.1, 0), STONE_LIGHT)
	disc(model, "CrownGlow", 8.8, 0.35, base * CFrame.new(0, top + 12.6, 0), CYAN, Enum.Material.Neon)
	for i = 0, 5 do
		local angle = math.rad(i * 60)
		local prong = base * CFrame.new(0, top + 13.7, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 1.6, -3.4) * CFrame.Angles(math.rad(-18), 0, 0)
		makePart(model, "CrownProng", Vector3.new(0.9, 3.4, 0.9), prong, GOLD, Enum.Material.Metal)
		makePart(model, "CrownGem", Vector3.new(0.9, 0.9, 0.9), prong * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), i % 2 == 0 and PINK or CYAN, Enum.Material.Neon)
	end
	local topGem = makePart(model, "CrownStar", Vector3.new(2.2, 2.2, 2.2), base * CFrame.new(0, top + 16.4, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), GOLD, Enum.Material.Neon)
	topGem:SetAttribute("SpinSpeed", 1.6)
	CollectionService:AddTag(topGem, "PortalSpin")
	light(topGem, GOLD, 18, 2)

	-- 3 socles autour du cœur, chacun avec un cristal qui tourne relié au cœur par un rayon
	local slotColors = {CYAN, PINK, GOLD}
	for index = 1, CONFIG.Cards do
		local angle = math.rad(-60 + (index - 1) * 120) -- deux devant, un derrière
		local at = base * CFrame.Angles(0, angle, 0) * CFrame.new(0, top, -8.2)
		makePart(model, "Pedestal", Vector3.new(3, 3.2, 3), at * CFrame.new(0, 1.6, 0), STONE_LIGHT)
		makePart(model, "PedestalTrim", Vector3.new(3.4, 0.4, 3.4), at * CFrame.new(0, 3.3, 0), slotColors[index], Enum.Material.Neon)
		makePart(model, "PedestalTop", Vector3.new(3.8, 0.6, 3.8), at * CFrame.new(0, 3.8, 0), STONE)
		local crystal = makePart(model, "SlotCrystal", Vector3.new(1.8, 3, 1.8), at * CFrame.new(0, 6.6, 0) * CFrame.Angles(0, math.rad(45), 0), slotColors[index], Enum.Material.Neon)
		crystal.CanCollide = false
		crystal:SetAttribute("SpinSpeed", 1.2)
		CollectionService:AddTag(crystal, "PortalSpin")
		light(crystal, slotColors[index], 12, 1.5)
		beam(crystal, core, slotColors[index])
	end

	-- 2 grands obélisques derrière
	for _, side in ipairs({-1, 1}) do
		local at = base * CFrame.new(side * 13, top, 6)
		makePart(model, "Obelisk", Vector3.new(3, 16, 3), at * CFrame.new(0, 8, 0), STONE_LIGHT)
		for band = 1, 3 do
			makePart(model, "ObeliskBand", Vector3.new(3.3, 0.5, 3.3), at * CFrame.new(0, band * 4, 0), band == 2 and CYAN or VIOLET, Enum.Material.Neon)
		end
		makePart(model, "ObeliskTip", Vector3.new(2.2, 2.2, 2.2), at * CFrame.new(0, 17.4, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), PINK, Enum.Material.Neon)
	end

	-- Pupitre devant (bouton E)
	local console = makePart(model, "Console", Vector3.new(6, 3.4, 2.4), base * CFrame.new(0, top + 1.7, -12.4), STONE_LIGHT)
	local screen = makePart(model, "ConsoleScreen", Vector3.new(5.4, 0.3, 2.6), base * CFrame.new(0, top + 3.6, -12.6) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(25, 15, 45), Enum.Material.Neon)
	local screenGui = Instance.new("SurfaceGui")
	screenGui.Face = Enum.NormalId.Top
	screenGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	screenGui.PixelsPerStud = 40
	screenGui.LightInfluence = 0
	screenGui.Parent = screen
	local screenText = Instance.new("TextLabel")
	screenText.Size = UDim2.new(1, 0, 1, 0)
	screenText.BackgroundTransparency = 1
	screenText.Text = "⚡ FUSION ⚡"
	screenText.TextScaled = true
	screenText.Font = Enum.Font.FredokaOne
	screenText.TextColor3 = CYAN
	screenText.Parent = screenGui

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FusionPrompt"
	prompt.ActionText = "Fusionner"
	prompt.ObjectText = "Machine de Fusion"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = console
	prompt.Triggered:Connect(function(player)
		deps.Remotes.OpenFusion:FireClient(player)
	end)

	-- Grand panneau au-dessus
	local anchor = makePart(model, "FusionTitle", Vector3.new(1, 1, 1), base * CFrame.new(0, top + 22, 0), VIOLET)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	local sign = Instance.new("BillboardGui")
	sign.Name = "FusionSign"
	sign.Size = UDim2.new(16, 0, 5, 0)
	sign.MaxDistance = 150
	sign.LightInfluence = 0
	sign.AlwaysOnTop = false
	sign.Parent = anchor
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.62, 0)
	title.BackgroundTransparency = 1
	title.Text = "⚗️ MACHINE DE FUSION ⚗️"
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(40, 10, 70)
	title.Parent = sign
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CYAN),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 220, 255)),
		ColorSequenceKeypoint.new(1, PINK),
	})
	titleGradient.Parent = title
	local caption = Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.Position = UDim2.new(0, 0, 0.64, 0)
	caption.Size = UDim2.new(1, 0, 0.36, 0)
	caption.BackgroundTransparency = 1
	caption.Text = "3 brainrots = 1 brainrot FUSIONNÉ (+10 %)"
	caption.TextScaled = true
	caption.Font = Enum.Font.GothamBold
	caption.TextColor3 = GOLD
	caption.TextStrokeTransparency = 0.2
	caption.Parent = sign

	model.Parent = Workspace
	return model
end

-- Petit flash de la sphère quand quelqu'un fusionne
local function flash()
	if not core or not core.Parent then return end
	local emitter = core:FindFirstChild("FusionSparkles")
	if emitter then
		emitter:Emit(60)
	end
	core.Color = Color3.new(1, 1, 1)
	core.Size = Vector3.new(6, 6, 6)
	TweenService:Create(core, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = VIOLET, Size = Vector3.new(4, 4, 4)}):Play()
end

local function isNear(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local offset = root.Position - CONFIG.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= CONFIG.MaxDistance
end

-- Fusionne 3 cartes du sac. Renvoie la carte gardée (ou nil + raison).
function FusionManager.fuse(player, itemIds)
	if type(itemIds) ~= "table" or #itemIds ~= CONFIG.Cards then
		return nil, "Il faut " .. CONFIG.Cards .. " brainrots"
	end
	if not isNear(player) then
		return nil, "Approche-toi de la Machine de Fusion"
	end
	if deps.TradeManager and deps.TradeManager.isTrading(player) then
		return nil, "Termine ton échange d'abord"
	end
	local items = {}
	for _, itemId in ipairs(itemIds) do
		local item = deps.PlayerData.findItem(player, itemId)
		if not item then
			return nil, "Carte introuvable"
		end
		if (item:GetAttribute("Slot") or 0) ~= 0 then
			return nil, "Les cartes doivent être dans ton sac"
		end
		if table.find(items, item) then
			return nil, "Choisis 3 cartes différentes"
		end
		table.insert(items, item)
	end

	local income, level, best = GameConfig.getFusionResult(items)
	for _, item in ipairs(items) do
		if item ~= best then
			deps.PlayerData.removeItem(player, item)
		end
	end
	deps.PlayerData.destroyHeldTool(player, best.Name) -- la carte en main n'est plus à jour
	best:SetAttribute("FusionIncome", income)
	best:SetAttribute("FusionLevel", level)
	best:SetAttribute("Mineral", nil) -- déjà compté dans le revenu
	return best
end

function FusionManager.init(dependencies)
	deps = dependencies
	buildMachine()

	deps.Remotes.Fuse.OnServerEvent:Connect(function(player, itemIds)
		if busy[player] then return end
		busy[player] = true
		local ok, result, reason = pcall(FusionManager.fuse, player, itemIds)
		busy[player] = nil
		if not ok then
			warn("[Fusion] " .. tostring(result))
			return
		end
		if not result then
			deps.Remotes.notify(player, "⚗️ " .. reason, "error")
			return
		end
		local fusion = GameConfig.getFusion(result)
		deps.Remotes.FusionResult:FireClient(player, {
			Id = result.Name,
			Name = result.Value,
			Mutation = result:GetAttribute("Mutation") or "Normal",
			Serial = result:GetAttribute("Serial") or 0,
			Fusion = fusion,
		})
		flash()
		task.spawn(deps.PlayerData.save, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return FusionManager
