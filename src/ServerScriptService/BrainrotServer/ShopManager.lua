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

local WALL = Color3.fromRGB(245, 238, 225)
local TRIM = Color3.fromRGB(70, 130, 220)
local FLOOR = Color3.fromRGB(190, 150, 105)
local DARK = Color3.fromRGB(60, 50, 45)
local RED = Color3.fromRGB(230, 70, 70)

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
local function display(tool, cframe, parent)
	local model = Instance.new("Model")
	model.Name = tool.Name
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

function ShopManager.init(dependencies)
	local PickaxeBuilder = dependencies.PickaxeBuilder
	local Remotes = dependencies.Remotes

	-- La boutique est à l'ouest de la mine et regarde vers elle
	local position = Vector3.new(-(dependencies.MineHalf + 110), 0, 0)
	shopCFrame = CFrame.lookAt(position, Vector3.new(0, 0, 0))

	local model = Instance.new("Model")
	model.Name = "Shop"

	local function at(x, y, z)
		return shopCFrame * CFrame.new(x, y, z)
	end

	local width, depth, height = 40, 26, 16

	-- Sol, murs, toit plat avec rebord
	makePart(model, "Floor", Vector3.new(width, 1, depth), at(0, 0.5, 0), FLOOR, Enum.Material.WoodPlanks)
	makePart(model, "BackWall", Vector3.new(width, height, 1), at(0, 1 + height / 2, depth / 2 - 0.5), WALL)
	makePart(model, "LeftWall", Vector3.new(1, height, depth), at(-width / 2 + 0.5, 1 + height / 2, 0), WALL)
	makePart(model, "RightWall", Vector3.new(1, height, depth), at(width / 2 - 0.5, 1 + height / 2, 0), WALL)
	makePart(model, "Roof", Vector3.new(width + 2, 1.5, depth + 2), at(0, height + 1.75, 0), TRIM, Enum.Material.SmoothPlastic, true)
	for _, x in ipairs({-width / 2 + 1, width / 2 - 1}) do
		makePart(model, "Pillar", Vector3.new(2.4, height, 2.4), at(x, 1 + height / 2, -depth / 2 + 1), TRIM, Enum.Material.SmoothPlastic, true)
	end

	-- Façade : le nom de la boutique + un auvent rayé
	local facade = makePart(model, "Facade", Vector3.new(width - 2, 4, 1), at(0, height - 1, -depth / 2 + 0.5), WALL)
	surfaceText(facade, Enum.NormalId.Front, "BOUTIQUE", TRIM)
	local stripes = 10
	for i = 0, stripes - 1 do
		local stripeWidth = (width - 2) / stripes
		makePart(model, "Awning", Vector3.new(stripeWidth, 0.4, 5), at(-width / 2 + 1 + stripeWidth * (i + 0.5), height - 3.6, -depth / 2 - 2.2) * CFrame.Angles(math.rad(-20), 0, 0), i % 2 == 0 and RED or Color3.new(1, 1, 1), Enum.Material.Fabric)
	end

	-- Comptoir (un seul : E = pioches, F = battes)
	local counter = makePart(model, "Counter", Vector3.new(20, 3.4, 3), at(0, 2.7, 3), DARK, Enum.Material.Wood)
	makePart(model, "CounterTop", Vector3.new(20.6, 0.4, 3.6), at(0, 4.6, 3), FLOOR, Enum.Material.WoodPlanks)
	counterPosition = counter.Position
	local labelLeft = makePart(model, "CounterLabel", Vector3.new(8, 2, 0.2), at(-5, 2.8, 1.4), DARK)
	labelLeft.CanCollide = false
	surfaceText(labelLeft, Enum.NormalId.Front, "[E] PIOCHES", Color3.fromRGB(255, 225, 120), Enum.Font.FredokaOne)
	local labelRight = makePart(model, "CounterLabel", Vector3.new(8, 2, 0.2), at(5, 2.8, 1.4), DARK)
	labelRight.CanCollide = false
	surfaceText(labelRight, Enum.NormalId.Front, "[F] BATTES", Color3.fromRGB(255, 140, 140), Enum.Font.FredokaOne)

	-- Marchand (petit personnage en blocs)
	local skin = Color3.fromRGB(235, 190, 150)
	makePart(model, "KeeperLegs", Vector3.new(2, 2.6, 1), at(0, 2.3, 7), Color3.fromRGB(50, 60, 110))
	makePart(model, "KeeperBody", Vector3.new(2.4, 2.6, 1.2), at(0, 4.9, 7), Color3.fromRGB(70, 130, 220))
	makePart(model, "KeeperHead", Vector3.new(1.6, 1.6, 1.6), at(0, 7.0, 7), skin)
	makePart(model, "KeeperHat", Vector3.new(2.2, 0.5, 2.2), at(0, 8.0, 7), Color3.fromRGB(230, 180, 40))

	-- Les pioches à gauche, les battes à droite (les vrais objets du jeu)
	for index, pickaxeData in ipairs(GameConfig.PICKAXES) do
		local x = -17 + (index - 1) * 2.6
		display(PickaxeBuilder.build(pickaxeData), at(x, 9, depth / 2 - 1.2) * CFrame.Angles(0, math.rad(90), 0), model)
	end
	for index, batData in ipairs(GameConfig.BATS) do
		local x = 4 + (index - 1) * 3
		display(PickaxeBuilder.buildBat(batData), at(x, 8.5, depth / 2 - 1.2) * CFrame.Angles(0, 0, math.rad(-20)), model)
	end

	-- Lumière douce à l'intérieur (cachée dans le plafond)
	local ceiling = makePart(model, "CeilingLight", Vector3.new(1, 1, 1), at(0, height - 1, 3), WALL)
	ceiling.Transparency = 1
	ceiling.CanCollide = false
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 0.8
	light.Shadows = false
	light.Parent = ceiling

	-- E = pioches
	local pickaxePrompt = Instance.new("ProximityPrompt")
	pickaxePrompt.Name = "PickaxePrompt"
	pickaxePrompt.ActionText = "Pioches"
	pickaxePrompt.ObjectText = "Boutique"
	pickaxePrompt.KeyboardKeyCode = Enum.KeyCode.E
	pickaxePrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	pickaxePrompt.MaxActivationDistance = 12
	pickaxePrompt.RequiresLineOfSight = false
	pickaxePrompt.Parent = counter
	pickaxePrompt.Triggered:Connect(function(player)
		Remotes.OpenShop:FireClient(player)
	end)

	-- F = battes
	local batPrompt = Instance.new("ProximityPrompt")
	batPrompt.Name = "BatPrompt"
	batPrompt.ActionText = "Battes"
	batPrompt.ObjectText = "Boutique"
	batPrompt.KeyboardKeyCode = Enum.KeyCode.F
	batPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	batPrompt.MaxActivationDistance = 12
	batPrompt.RequiresLineOfSight = false
	batPrompt.UIOffset = Vector2.new(0, 80)
	batPrompt.Parent = counter
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
	return (shopCFrame * CFrame.new(0, 0, -16)).Position
end

function ShopManager.getVisitCFrame()
	return shopCFrame * CFrame.new(0, 4, -6) * CFrame.Angles(0, math.rad(180), 0)
end

return ShopManager
