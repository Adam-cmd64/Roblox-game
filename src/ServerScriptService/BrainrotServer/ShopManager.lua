-- ModuleScript : LA BOUTIQUE (un seul bâtiment, à l'ouest de la mine).
-- Au comptoir : touche E = les pioches, touche F = les battes.
-- (plus tard on pourra ajouter d'autres rayons avec d'autres touches)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local ShopManager = {}

local SHOP_RANGE = 30
local shopCFrame
local counterPosition

-- Style "boutique magique de mineur" : murs violet nuit, bois foncé, dorures et néons
local WALL = Color3.fromRGB(52, 38, 92)
local WAINSCOT = Color3.fromRGB(58, 38, 30)
local GOLD = Color3.fromRGB(255, 200, 70)
local CYAN = Color3.fromRGB(70, 230, 255)
local PINK = Color3.fromRGB(255, 90, 210)
local TILE_A = Color3.fromRGB(38, 30, 60)
local TILE_B = Color3.fromRGB(70, 55, 110)
local DARK = Color3.fromRGB(30, 24, 40)

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

local function surfaceText(part, face, text, color, font)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(30, 30, 40)
	label.Font = font or Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Parent = gui
	return label
end

-- Transforme un Tool (pioche ou batte) en objet exposé au mur
local function display(tool, cframe, parent, name)
	local model = Instance.new("Model")
	model.Name = name or tool.Name
	for _, part in ipairs(tool:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	for _, child in ipairs(tool:GetChildren()) do
		child.Parent = model
	end
	tool:Destroy()
	model.PrimaryPart = model:FindFirstChild("Handle")
	if model.PrimaryPart then
		model:PivotTo(cframe)
	end
	model.Parent = parent
end

-- Une niche lumineuse au mur : fond sombre, cadre néon, petite plaque avec le nom
local function niche(parent, cframe, size, glow, name)
	local back = makePart(parent, "NicheBack", Vector3.new(size.X, size.Y, 0.3), cframe, DARK, Enum.Material.Slate)
	back.CanCollide = false
	local bars = {
		{Vector3.new(size.X + 0.3, 0.2, 0.2), CFrame.new(0, size.Y / 2, -0.2)},
		{Vector3.new(size.X + 0.3, 0.2, 0.2), CFrame.new(0, -size.Y / 2, -0.2)},
		{Vector3.new(0.2, size.Y, 0.2), CFrame.new(-size.X / 2, 0, -0.2)},
		{Vector3.new(0.2, size.Y, 0.2), CFrame.new(size.X / 2, 0, -0.2)},
	}
	for _, bar in ipairs(bars) do
		makePart(parent, "NicheGlow", bar[1], cframe * bar[2], glow, Enum.Material.Neon).CanCollide = false
	end
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 7
	light.Brightness = 0.7
	light.Parent = back
	if name then
		local plaque = makePart(parent, "Plaque", Vector3.new(size.X, 0.9, 0.2), cframe * CFrame.new(0, -size.Y / 2 - 0.75, -0.2), WAINSCOT, Enum.Material.Wood)
		plaque.CanCollide = false
		surfaceText(plaque, Enum.NormalId.Front, name, GOLD, Enum.Font.FredokaOne)
	end
end

-- Une lampe-cristal suspendue au plafond
local function hangingLamp(parent, cframe, color)
	makePart(parent, "LampChain", Vector3.new(0.15, 3, 0.15), cframe * CFrame.new(0, 1.5, 0), DARK, Enum.Material.Metal).CanCollide = false
	local crystal = makePart(parent, "LampCrystal", Vector3.new(1.2, 1.8, 1.2), cframe * CFrame.Angles(0, math.rad(45), 0), color, Enum.Material.Neon)
	crystal.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = color:Lerp(Color3.new(1, 1, 1), 0.5)
	light.Range = 26
	light.Brightness = 1.1
	light.Shadows = false
	light.Parent = crystal
end

function ShopManager.init(dependencies)
	local PickaxeBuilder = dependencies.PickaxeBuilder
	local GrappleManager = dependencies.GrappleManager
	local Remotes = dependencies.Remotes

	-- La boutique est à l'ouest de la mine et regarde vers elle
	local position = Vector3.new(-(dependencies.MineHalf + 110), 0, 0)
	shopCFrame = CFrame.lookAt(position, Vector3.new(0, 0, 0))

	local model = Instance.new("Model")
	model.Name = "Shop"

	local function at(x, y, z)
		return shopCFrame * CFrame.new(x, y, z)
	end

	local width, depth, height = 48, 28, 18

	-- Sol en damier violet
	local tile = 4
	for ix = 0, width / tile - 1 do
		for iz = 0, depth / tile - 1 do
			local color = (ix + iz) % 2 == 0 and TILE_A or TILE_B
			makePart(model, "Floor", Vector3.new(tile, 1, tile), at(-width / 2 + tile * (ix + 0.5), 0.5, -depth / 2 + tile * (iz + 0.5)), color, Enum.Material.Marble)
		end
	end

	-- Murs : bas en bois foncé, haut violet nuit, une ligne néon entre les deux
	local low = 5
	local walls = {
		{"BackWall", Vector3.new(width, 0, 1), CFrame.new(0, 0, depth / 2 - 0.5)},
		{"LeftWall", Vector3.new(1, 0, depth), CFrame.new(-width / 2 + 0.5, 0, 0)},
		{"RightWall", Vector3.new(1, 0, depth), CFrame.new(width / 2 - 0.5, 0, 0)},
	}
	for _, wall in ipairs(walls) do
		local size, offset = wall[2], wall[3]
		makePart(model, wall[1], Vector3.new(size.X, height - low, size.Z), at(0, 1 + low + (height - low) / 2, 0) * offset, WALL)
		makePart(model, wall[1] .. "Low", Vector3.new(size.X, low, size.Z), at(0, 1 + low / 2, 0) * offset, WAINSCOT, Enum.Material.WoodPlanks)
		local glowSize = Vector3.new(math.max(size.X - 0.4, 0.3), 0.25, math.max(size.Z - 0.4, 0.3))
		local glow = makePart(model, "WallGlow", glowSize + Vector3.new(size.X > 1 and 0 or 0.2, 0, size.Z > 1 and 0 or 0.2), at(0, 1 + low, 0) * offset, CYAN, Enum.Material.Neon)
		glow.CanCollide = false
	end

	-- Toit sombre avec une bordure dorée
	makePart(model, "Roof", Vector3.new(width + 2, 1.5, depth + 2), at(0, height + 1.75, 0), DARK, Enum.Material.Slate)
	for _, z in ipairs({-depth / 2 - 1, depth / 2 + 1}) do
		makePart(model, "RoofTrim", Vector3.new(width + 2.4, 0.5, 0.4), at(0, height + 2.5, z), GOLD, Enum.Material.Metal).CanCollide = false
	end
	for _, x in ipairs({-width / 2 - 1, width / 2 + 1}) do
		makePart(model, "RoofTrim", Vector3.new(0.4, 0.5, depth + 2.4), at(x, height + 2.5, 0), GOLD, Enum.Material.Metal).CanCollide = false
	end

	-- Piliers de l'entrée en pierre + néon rose
	for _, x in ipairs({-width / 2 + 1.2, width / 2 - 1.2}) do
		makePart(model, "Pillar", Vector3.new(2.4, height, 2.4), at(x, 1 + height / 2, -depth / 2 + 1.2), Color3.fromRGB(80, 70, 100), Enum.Material.Cobblestone)
		makePart(model, "PillarGlow", Vector3.new(0.35, height, 0.35), at(x, 1 + height / 2, -depth / 2 - 0.1), PINK, Enum.Material.Neon).CanCollide = false
		makePart(model, "PillarCap", Vector3.new(3, 0.8, 3), at(x, height + 0.6, -depth / 2 + 1.2), GOLD, Enum.Material.Metal)
	end

	-- Façade : grande enseigne dorée
	local facade = makePart(model, "Facade", Vector3.new(width - 2, 4.5, 1), at(0, height - 1.25, -depth / 2 + 0.5), Color3.fromRGB(70, 40, 120))
	surfaceText(facade, Enum.NormalId.Front, "⛏  BOUTIQUE  ⛏", GOLD)
	for _, y in ipairs({height - 3.6, height + 1.1}) do
		makePart(model, "FacadeGlow", Vector3.new(width - 1, 0.35, 0.35), at(0, y, -depth / 2 - 0.1), CYAN, Enum.Material.Neon).CanCollide = false
	end
	-- auvent violet et or
	local stripes = 12
	for i = 0, stripes - 1 do
		local stripeWidth = (width - 4) / stripes
		makePart(model, "Awning", Vector3.new(stripeWidth, 0.4, 5), at(-width / 2 + 2 + stripeWidth * (i + 0.5), height - 4.1, -depth / 2 - 2.2) * CFrame.Angles(math.rad(-20), 0, 0), i % 2 == 0 and Color3.fromRGB(130, 60, 200) or GOLD, Enum.Material.Fabric)
	end
	-- deux lanternes-cristal devant l'entrée
	for _, x in ipairs({-width / 2 - 2, width / 2 + 2}) do
		makePart(model, "LanternPost", Vector3.new(0.8, 7, 0.8), at(x, 4.5, -depth / 2 - 1), DARK, Enum.Material.Metal)
		local crystal = makePart(model, "LanternCrystal", Vector3.new(1.4, 2.2, 1.4), at(x, 9, -depth / 2 - 1) * CFrame.Angles(0, math.rad(45), 0), CYAN, Enum.Material.Neon)
		crystal.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = CYAN
		light.Range = 16
		light.Brightness = 1
		light.Parent = crystal
	end

	-- Tapis rouge et or de l'entrée jusqu'au comptoir
	makePart(model, "Rug", Vector3.new(10, 0.1, depth - 10), at(0, 1.05, -4), Color3.fromRGB(150, 30, 60), Enum.Material.Fabric).CanCollide = false
	for _, x in ipairs({-5, 5}) do
		makePart(model, "RugTrim", Vector3.new(0.4, 0.12, depth - 10), at(x, 1.06, -4), GOLD, Enum.Material.Fabric).CanCollide = false
	end

	-- Comptoir vitré : socle en bois, bord néon, vitrine avec des gemmes
	local counter = makePart(model, "Counter", Vector3.new(24, 3.4, 3), at(0, 2.7, 3), WAINSCOT, Enum.Material.Wood)
	makePart(model, "CounterTop", Vector3.new(24.6, 0.4, 3.6), at(0, 4.6, 3), GOLD, Enum.Material.Metal)
	makePart(model, "CounterGlow", Vector3.new(24.8, 0.2, 0.2), at(0, 4.4, 1.2), PINK, Enum.Material.Neon).CanCollide = false
	local glass = makePart(model, "CounterGlass", Vector3.new(22, 1.6, 2.6), at(0, 5.6, 3), Color3.fromRGB(180, 230, 255), Enum.Material.Glass)
	glass.Transparency = 0.7
	local gemColors = {CYAN, PINK, GOLD, Color3.fromRGB(80, 255, 140), Color3.fromRGB(170, 90, 255)}
	for i = 0, 8 do
		local gem = makePart(model, "Gem", Vector3.new(0.7, 0.7, 0.7), at(-9 + i * 2.25, 5.2, 3) * CFrame.Angles(math.rad(45), math.rad(45), 0), gemColors[i % #gemColors + 1], Enum.Material.Neon)
		gem.CanCollide = false
	end
	counterPosition = counter.Position
	-- les touches : E à gauche (pioches), F à droite (battes & grappins)
	local labelLeft = makePart(model, "CounterLabel", Vector3.new(9, 2, 0.2), at(-6, 2.8, 1.4), DARK)
	labelLeft.CanCollide = false
	surfaceText(labelLeft, Enum.NormalId.Front, "[E] PIOCHES", GOLD, Enum.Font.FredokaOne)
	local labelRight = makePart(model, "CounterLabel", Vector3.new(9, 2, 0.2), at(6, 2.8, 1.4), DARK)
	labelRight.CanCollide = false
	surfaceText(labelRight, Enum.NormalId.Front, "[F] BATTES & GRAPPINS", Color3.fromRGB(255, 140, 200), Enum.Font.FredokaOne)

	-- Le marchand : un petit robot mineur (visière néon, antenne)
	local metal = Color3.fromRGB(150, 160, 180)
	makePart(model, "RobotBase", Vector3.new(2.4, 2.4, 1.6), at(0, 2.2, 7.5), DARK, Enum.Material.Metal)
	makePart(model, "RobotBody", Vector3.new(3, 3, 2), at(0, 5, 7.5), metal, Enum.Material.Metal)
	makePart(model, "RobotCore", Vector3.new(1, 1, 0.2), at(0, 5.2, 6.45), CYAN, Enum.Material.Neon).CanCollide = false
	makePart(model, "RobotHead", Vector3.new(2.4, 2, 2), at(0, 7.6, 7.5), metal, Enum.Material.Metal)
	makePart(model, "RobotVisor", Vector3.new(2, 0.6, 0.2), at(0, 7.8, 6.45), CYAN, Enum.Material.Neon).CanCollide = false
	makePart(model, "RobotHelmet", Vector3.new(2.6, 0.5, 2.2), at(0, 8.85, 7.5), GOLD, Enum.Material.Metal)
	makePart(model, "RobotLamp", Vector3.new(0.6, 0.6, 0.3), at(0, 8.85, 6.3), Color3.fromRGB(255, 250, 200), Enum.Material.Neon).CanCollide = false
	makePart(model, "RobotAntenna", Vector3.new(0.15, 1.2, 0.15), at(0.7, 9.7, 7.5), DARK, Enum.Material.Metal).CanCollide = false
	local tip = makePart(model, "RobotAntennaTip", Vector3.new(0.45, 0.45, 0.45), at(0.7, 10.4, 7.5), PINK, Enum.Material.Neon)
	tip.Shape = Enum.PartType.Ball
	tip.CanCollide = false
	for _, x in ipairs({-1.9, 1.9}) do
		makePart(model, "RobotArm", Vector3.new(0.7, 2.6, 0.7), at(x, 4.9, 7.3) * CFrame.Angles(math.rad(-25), 0, 0), metal, Enum.Material.Metal).CanCollide = false
	end

	-- Mur du fond : toutes les pioches, chacune dans sa niche lumineuse
	local count = #GameConfig.PICKAXES
	local spacing = math.min(4.3, (width - 4) / count)
	for index, pickaxeData in ipairs(GameConfig.PICKAXES) do
		local x = -spacing * (count - 1) / 2 + (index - 1) * spacing
		local glow = pickaxeData.HeadColor
		if glow.R + glow.G + glow.B < 0.6 then
			glow = Color3.fromRGB(150, 80, 255) -- les pioches très sombres brillent en violet
		end
		local shortName = pickaxeData.Name:gsub("^Pioche en ", ""):gsub("^Pioche ", "")
		niche(model, at(x, 10, depth / 2 - 1.15), Vector2.new(spacing - 0.6, 6), glow, shortName)
		display(PickaxeBuilder.build(pickaxeData), at(x, 10, depth / 2 - 1.6) * CFrame.Angles(0, math.rad(90), 0), model, pickaxeData.Name)
	end

	-- Mur de droite : les battes (en haut) et les grappins (en bas)
	local side = width / 2 - 1.15
	local sign = makePart(model, "ArmorySign", Vector3.new(0.2, 2, 14), at(side - 0.1, height - 1.5, 2), DARK)
	sign.CanCollide = false
	surfaceText(sign, Enum.NormalId.Left, "BATTES & GRAPPINS", Color3.fromRGB(255, 140, 200))
	local wallFacing = CFrame.Angles(0, math.rad(90), 0) -- tourné vers l'intérieur
	for index, batData in ipairs(GameConfig.BATS) do
		local z = -6 + (index - 1) * 4
		niche(model, at(side, 12, z) * wallFacing, Vector2.new(3.4, 4.6), batData.Color)
		display(PickaxeBuilder.buildBat(batData), at(side - 0.5, 12, z) * CFrame.Angles(math.rad(20), 0, 0), model)
	end
	if GrappleManager and GrappleManager.buildTool then
		for index, grappleData in ipairs(GameConfig.GRAPPLES) do
			local z = -2 + (index - 1) * 4
			niche(model, at(side, 6.8, z) * wallFacing, Vector2.new(3.4, 3), grappleData.Color)
			display(GrappleManager.buildTool(grappleData), at(side - 0.6, 6.8, z) * CFrame.Angles(0, math.rad(90), 0), model)
		end
	end

	-- Mur de gauche : un tas de cristaux qui brillent + un wagonnet de mine
	local wallX = -width / 2 + 1
	local crystalColors = {CYAN, PINK, Color3.fromRGB(170, 90, 255)}
	for i = 1, 7 do
		local h = 2 + (i % 3) * 1.4
		local crystal = makePart(model, "WallCrystal", Vector3.new(1.1, h, 1.1), at(wallX + 1 + (i % 2) * 0.8, 1 + h / 2, 3 + i * 1.1) * CFrame.Angles(math.rad((i % 3 - 1) * 14), 0, math.rad((i % 2 == 0) and 10 or -12)), crystalColors[i % 3 + 1], Enum.Material.Neon)
		crystal.CanCollide = false
	end
	local cart = makePart(model, "MineCart", Vector3.new(3.6, 2.2, 5), at(wallX + 2.6, 2.4, -6), Color3.fromRGB(90, 80, 75), Enum.Material.DiamondPlate)
	cart.CanCollide = true
	for _, z in ipairs({-7.6, -4.4}) do
		for _, x in ipairs({wallX + 0.8, wallX + 4.4}) do
			local wheel = makePart(model, "CartWheel", Vector3.new(0.4, 1.2, 1.2), at(x, 1.4, z), DARK, Enum.Material.Metal)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CanCollide = false
		end
	end
	for i = 0, 5 do
		local ore = makePart(model, "CartOre", Vector3.new(0.9, 0.9, 0.9), at(wallX + 1.8 + (i % 2) * 1.6, 3.7, -7.6 + math.floor(i / 2) * 1.6) * CFrame.Angles(math.rad(i * 30), math.rad(i * 20), 0), gemColors[i % #gemColors + 1], Enum.Material.Neon)
		ore.CanCollide = false
	end
	local cartLabel = makePart(model, "CartSign", Vector3.new(0.2, 2.6, 10), at(wallX + 0.2, 10, -2), DARK)
	cartLabel.CanCollide = false
	surfaceText(cartLabel, Enum.NormalId.Right, "✦ Mine plus profond ✦", CYAN)

	-- Lampes-cristal suspendues
	hangingLamp(model, at(-12, height - 3, -2), CYAN)
	hangingLamp(model, at(0, height - 3, -4), GOLD)
	hangingLamp(model, at(12, height - 3, -2), PINK)

	-- Les invites : chacune à son bout du comptoir (elles ne se cachent plus)
	local pickaxeSpot = Instance.new("Attachment")
	pickaxeSpot.Name = "PickaxeSpot"
	pickaxeSpot.Position = Vector3.new(-6, 2.2, -1.5)
	pickaxeSpot.Parent = counter
	local armorySpot = Instance.new("Attachment")
	armorySpot.Name = "ArmorySpot"
	armorySpot.Position = Vector3.new(6, 2.2, -1.5)
	armorySpot.Parent = counter

	-- E = pioches
	local pickaxePrompt = Instance.new("ProximityPrompt")
	pickaxePrompt.Name = "PickaxePrompt"
	pickaxePrompt.ActionText = "Pioches"
	pickaxePrompt.ObjectText = "Boutique"
	pickaxePrompt.KeyboardKeyCode = Enum.KeyCode.E
	pickaxePrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	pickaxePrompt.MaxActivationDistance = 14
	pickaxePrompt.RequiresLineOfSight = false
	pickaxePrompt.Parent = pickaxeSpot
	pickaxePrompt.Triggered:Connect(function(player)
		Remotes.OpenShop:FireClient(player)
	end)

	-- F = battes & grappins
	local batPrompt = Instance.new("ProximityPrompt")
	batPrompt.Name = "BatPrompt"
	batPrompt.ActionText = "Battes & Grappins"
	batPrompt.ObjectText = "Boutique"
	batPrompt.KeyboardKeyCode = Enum.KeyCode.F
	batPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	batPrompt.MaxActivationDistance = 14
	batPrompt.RequiresLineOfSight = false
	batPrompt.Parent = armorySpot
	batPrompt.Triggered:Connect(function(player)
		Remotes.OpenBatShop:FireClient(player)
	end)

	model.Parent = Workspace
end

-- Le joueur est-il assez près du comptoir pour acheter ?
function ShopManager.isNear(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and counterPosition ~= nil and (root.Position - counterPosition).Magnitude <= SHOP_RANGE
end

-- Devant l'entrée de la boutique (pour les tapis roulants)
function ShopManager.getFrontPosition()
	return (shopCFrame * CFrame.new(0, 0, -19)).Position
end

function ShopManager.getVisitCFrame()
	return shopCFrame * CFrame.new(0, 4, -6) * CFrame.Angles(0, math.rad(180), 0)
end

return ShopManager
