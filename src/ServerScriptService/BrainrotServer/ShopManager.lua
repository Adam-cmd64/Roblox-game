-- ModuleScript : la boutique de pioches (un vrai bâtiment dans la map).
-- On doit s'y rendre et appuyer sur E au comptoir pour ouvrir la boutique.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local ShopManager = {}

local SHOP_RANGE = 28
local shopCFrame
local counterPosition

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

local function sign(part, face, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = gui
end

function ShopManager.init(dependencies)
	local PickaxeBuilder = dependencies.PickaxeBuilder
	local Remotes = dependencies.Remotes

	-- La boutique est à l'ouest de la mine et regarde vers elle
	local position = Vector3.new(-(dependencies.MineHalf + 70), 0, 0)
	shopCFrame = CFrame.lookAt(position, Vector3.new(0, 0, 0))

	local model = Instance.new("Model")
	model.Name = "PickaxeShop"

	local function at(x, y, z)
		return shopCFrame * CFrame.new(x, y, z)
	end

	local wood = Color3.fromRGB(120, 80, 48)
	local darkWood = Color3.fromRGB(80, 52, 32)
	local plank = Color3.fromRGB(165, 115, 70)

	-- Sol, murs, toit (style chalet en bois)
	makePart(model, "Floor", Vector3.new(30, 1, 22), at(0, 0.5, 0), plank, Enum.Material.WoodPlanks)
	makePart(model, "BackWall", Vector3.new(30, 14, 1), at(0, 7.5, 10.5), wood, Enum.Material.WoodPlanks)
	makePart(model, "LeftWall", Vector3.new(1, 14, 22), at(-14.5, 7.5, 0), wood, Enum.Material.WoodPlanks)
	makePart(model, "RightWall", Vector3.new(1, 14, 22), at(14.5, 7.5, 0), wood, Enum.Material.WoodPlanks)
	for _, x in ipairs({-14.5, 14.5}) do
		for _, z in ipairs({-10.5, 10.5}) do
			makePart(model, "Beam", Vector3.new(1.6, 15, 1.6), at(x, 7.5, z), darkWood, Enum.Material.Wood)
		end
	end
	local roofL = makePart(model, "RoofL", Vector3.new(17, 1, 26), at(-7.5, 16.5, 0) * CFrame.Angles(0, 0, math.rad(22)), Color3.fromRGB(150, 50, 40), Enum.Material.Slate)
	local roofR = makePart(model, "RoofR", Vector3.new(17, 1, 26), at(7.5, 16.5, 0) * CFrame.Angles(0, 0, math.rad(-22)), Color3.fromRGB(150, 50, 40), Enum.Material.Slate)
	roofL.CanCollide = true
	roofR.CanCollide = true
	makePart(model, "RoofFill", Vector3.new(30, 3.5, 1), at(0, 15.6, 10.5), wood, Enum.Material.WoodPlanks)

	-- Enseigne
	local board = makePart(model, "SignBoard", Vector3.new(18, 4, 0.6), at(0, 16.2, -11.4), darkWood, Enum.Material.Wood)
	sign(board, Enum.NormalId.Front, "⛏️ BOUTIQUE", Color3.fromRGB(255, 220, 120))

	-- Comptoir
	local counter = makePart(model, "Counter", Vector3.new(16, 3.4, 3), at(0, 2.7, 2), darkWood, Enum.Material.Wood)
	makePart(model, "CounterTop", Vector3.new(16.6, 0.4, 3.6), at(0, 4.6, 2), plank, Enum.Material.WoodPlanks)
	counterPosition = counter.Position

	-- Marchand (petit personnage en blocs)
	local skin = Color3.fromRGB(235, 190, 150)
	makePart(model, "KeeperLegs", Vector3.new(2, 2.6, 1), at(0, 2.3, 6), Color3.fromRGB(50, 60, 110))
	makePart(model, "KeeperBody", Vector3.new(2.4, 2.6, 1.2), at(0, 4.9, 6), Color3.fromRGB(120, 60, 30))
	makePart(model, "KeeperHead", Vector3.new(1.6, 1.6, 1.6), at(0, 7.0, 6), skin)
	makePart(model, "KeeperHat", Vector3.new(2.2, 0.5, 2.2), at(0, 8.0, 6), Color3.fromRGB(230, 180, 40), Enum.Material.Metal)
	makePart(model, "KeeperBeard", Vector3.new(1.4, 0.7, 0.3), at(0, 6.5, 5.1), Color3.fromRGB(150, 90, 50))

	-- Pioches exposées au mur (les vraies pioches du jeu)
	for index, pickaxeData in ipairs(GameConfig.PICKAXES) do
		local tool = PickaxeBuilder.build(pickaxeData)
		local display = Instance.new("Model")
		display.Name = pickaxeData.Name
		for _, child in ipairs(tool:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Anchored = true
			end
		end
		for _, child in ipairs(tool:GetChildren()) do
			child.Parent = display
		end
		tool:Destroy()
		display.PrimaryPart = display:FindFirstChild("Handle")
		local x = -11 + (index - 1) * 4.4
		display:PivotTo(at(x, 8.5, 9.6) * CFrame.Angles(0, math.rad(90), 0))
		display.Parent = model
	end

	-- Lanternes
	for _, x in ipairs({-10, 10}) do
		local lamp = makePart(model, "Lamp", Vector3.new(1, 1.4, 1), at(x, 11, -9.6), Color3.fromRGB(255, 200, 110), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 110)
		light.Range = 22
		light.Brightness = 1.6
		light.Parent = lamp
	end

	-- Bouton E pour ouvrir la boutique
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ouvrir la boutique"
	prompt.ObjectText = "Marchand de pioches"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	prompt.Triggered:Connect(function(player)
		Remotes.OpenShop:FireClient(player)
	end)

	model.Parent = Workspace
end

-- Le joueur est-il assez près de la boutique pour acheter ?
function ShopManager.isNear(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and counterPosition ~= nil and (root.Position - counterPosition).Magnitude <= SHOP_RANGE
end

function ShopManager.getVisitCFrame()
	return shopCFrame * CFrame.new(0, 4, -18) * CFrame.Angles(0, math.rad(180), 0)
end

return ShopManager
