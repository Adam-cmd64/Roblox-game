-- ModuleScript : l'armurerie (à l'est de la mine) et les battes.
-- Un coup de batte fait tomber le joueur touché pendant 2 secondes
-- et lui fait lâcher le brainrot qu'il était en train de voler.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local BatManager = {}

local SHOP_RANGE = 28
local deps
local shopCFrame
local counterPosition
local lastSwing = {}
local stunned = {}

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
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Parent = gui
end

-- ====== BATIMENT ======
local function buildShop()
	local position = Vector3.new(deps.MineHalf + 113, 0, 0)
	shopCFrame = CFrame.lookAt(position, Vector3.new(0, 0, 0))
	local function at(x, y, z)
		return shopCFrame * CFrame.new(x, y, z)
	end

	local model = Instance.new("Model")
	model.Name = "BatShop"

	local dark = Color3.fromRGB(45, 40, 55)
	local accent = Color3.fromRGB(230, 60, 70)

	makePart(model, "Floor", Vector3.new(30, 1, 22), at(0, 0.5, 0), Color3.fromRGB(70, 70, 80), Enum.Material.DiamondPlate)
	makePart(model, "BackWall", Vector3.new(30, 14, 1), at(0, 7.5, 10.5), dark, Enum.Material.Brick)
	makePart(model, "LeftWall", Vector3.new(1, 14, 22), at(-14.5, 7.5, 0), dark, Enum.Material.Brick)
	makePart(model, "RightWall", Vector3.new(1, 14, 22), at(14.5, 7.5, 0), dark, Enum.Material.Brick)
	makePart(model, "Roof", Vector3.new(32, 1.5, 24), at(0, 15.2, 0), Color3.fromRGB(30, 30, 35), Enum.Material.Metal)
	-- Auvent rayé
	for i = 0, 7 do
		makePart(model, "Awning", Vector3.new(3.75, 0.4, 5), at(-13.1 + i * 3.75, 13.2, -13) * CFrame.Angles(math.rad(-18), 0, 0), i % 2 == 0 and accent or Color3.new(1, 1, 1), Enum.Material.Fabric)
	end

	local board = makePart(model, "SignBoard", Vector3.new(20, 4, 0.6), at(0, 17.8, -10.8), Color3.fromRGB(25, 25, 30), Enum.Material.Metal)
	sign(board, Enum.NormalId.Front, "ARMURERIE", Color3.fromRGB(255, 90, 90))

	local counter = makePart(model, "Counter", Vector3.new(16, 3.4, 3), at(0, 2.7, 2), Color3.fromRGB(60, 55, 70), Enum.Material.Metal)
	makePart(model, "CounterTop", Vector3.new(16.6, 0.4, 3.6), at(0, 4.6, 2), accent, Enum.Material.SmoothPlastic)
	counterPosition = counter.Position

	-- Vendeur
	makePart(model, "KeeperLegs", Vector3.new(2, 2.6, 1), at(0, 2.3, 6), Color3.fromRGB(30, 30, 35))
	makePart(model, "KeeperBody", Vector3.new(2.4, 2.6, 1.2), at(0, 4.9, 6), Color3.fromRGB(200, 40, 50))
	makePart(model, "KeeperHead", Vector3.new(1.6, 1.6, 1.6), at(0, 7.0, 6), Color3.fromRGB(235, 190, 150))
	makePart(model, "KeeperCap", Vector3.new(1.8, 0.5, 2.4), at(0, 7.9, 5.8), Color3.fromRGB(30, 30, 35))

	-- Les battes exposées au mur
	for index, batData in ipairs(GameConfig.BATS) do
		local tool = deps.PickaxeBuilder.buildBat(batData)
		local display = Instance.new("Model")
		display.Name = batData.Name
		for _, child in ipairs(tool:GetChildren()) do
			if child:IsA("BasePart") then
				child.Anchored = true
			end
			child.Parent = display
		end
		tool:Destroy()
		display.PrimaryPart = display:FindFirstChild("Handle")
		display:PivotTo(at(-10 + (index - 1) * 5, 7.5, 9.6) * CFrame.Angles(0, 0, math.rad(-20)))
		display.Parent = model
	end

	for _, x in ipairs({-10, 10}) do
		local lamp = makePart(model, "Lamp", Vector3.new(1, 1.4, 1), at(x, 11, -9.6), Color3.fromRGB(255, 120, 120), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 150)
		light.Range = 22
		light.Brightness = 1.4
		light.Parent = lamp
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ouvrir l'armurerie"
	prompt.ObjectText = "Battes"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	prompt.Triggered:Connect(function(player)
		deps.Remotes.OpenBatShop:FireClient(player)
	end)

	model.Parent = Workspace
end

-- ====== BATTE EN MAIN ======
function BatManager.giveBat(player)
	local tierValue = player:FindFirstChild("BatTier")
	local batData = GameConfig.BATS[tierValue and tierValue.Value or 1] or GameConfig.BATS[1]
	for _, container in ipairs({player:FindFirstChild("Backpack"), player.Character}) do
		if container then
			local old = container:FindFirstChild("Batte")
			if old then
				old:Destroy()
			end
		end
	end
	local tool = deps.PickaxeBuilder.buildBat(batData)
	tool.Parent = player:FindFirstChild("Backpack")
end

-- ====== COUP DE BATTE ======
local function stun(target, attacker, direction)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or stunned[target] then return end
	stunned[target] = true
	humanoid.PlatformStand = true
	deps.Remotes.Stunned:FireClient(target, direction)
	deps.BaseManager.dropStolen(target, "bat")
	deps.Remotes.notify(target, attacker.DisplayName .. " t'a mis un coup de batte !", "error")
	task.delay(GameConfig.STUN_TIME, function()
		stunned[target] = nil
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
end

local function onSwing(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local tool = character and character:FindFirstChild("Batte")
	if not root or not tool or stunned[player] then return end

	local batData = GameConfig.BATS[player.BatTier.Value] or GameConfig.BATS[1]
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < batData.Cooldown * 0.85 then return end
	lastSwing[player] = now

	local look = root.CFrame.LookVector
	for _, other in ipairs(Players:GetPlayers()) do
		local otherRoot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if otherRoot then
			local offset = otherRoot.Position - root.Position
			local distance = offset.Magnitude
			if distance <= batData.Range and distance > 0 and offset.Unit:Dot(look) > 0.25 then
				stun(other, player, look)
				deps.Remotes.Effect:FireAllClients("BatHit", {Position = otherRoot.Position})
			end
		end
	end
end

-- ====== ACHAT ======
local function isNear(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and counterPosition ~= nil and (root.Position - counterPosition).Magnitude <= SHOP_RANGE
end

local function onBuy(player, tier)
	if typeof(tier) ~= "number" then return end
	local batTier = player.BatTier
	local batData = GameConfig.BATS[tier]
	if not batData then return end
	if not isNear(player) then
		deps.Remotes.notify(player, "Va à l'ARMURERIE pour acheter une batte", "error")
		return
	end
	if tier ~= batTier.Value + 1 then
		deps.Remotes.notify(player, "Achète d'abord la batte précédente", "error")
		return
	end
	local cash = player.leaderstats.Cash
	if cash.Value < batData.Cost then
		deps.Remotes.notify(player, "Pas assez d'argent ($" .. GameConfig.format(batData.Cost) .. ")", "error")
		return
	end
	cash.Value -= batData.Cost
	batTier.Value = tier
	BatManager.giveBat(player)
	deps.Remotes.notify(player, "Nouvelle arme : " .. batData.Name .. " !", "success")
	task.spawn(deps.PlayerData.save, player)
end

function BatManager.getVisitCFrame()
	return shopCFrame * CFrame.new(0, 4, -7) * CFrame.Angles(0, math.rad(180), 0)
end

function BatManager.getFrontPosition()
	return (shopCFrame * CFrame.new(0, 0, -11)).Position
end

function BatManager.init(dependencies)
	deps = dependencies
	buildShop()
	deps.Remotes.BatSwing.OnServerEvent:Connect(onSwing)
	deps.Remotes.BuyBat.OnServerEvent:Connect(onBuy)
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		stunned[player] = nil
	end)
end

return BatManager
