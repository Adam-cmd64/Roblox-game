-- ModuleScript : la roue de la fortune, une VRAIE roue dans le monde (à l'est de la mine).
--   touche E : tourner la roue (1 tour gratuit toutes les 24h, sinon un tour acheté)
--   touche F : ouvrir la fenêtre pour acheter des tours (1, 3 ou 10 tours en Robux)
-- 6 cases : argent, jackpot, brainrot Épique, brainrot Légendaire, potion de chance, Booster Galaxie.
--
-- La roue tourne pour tout le monde en même temps : le serveur choisit le résultat et le met
-- dans des attributs du modèle, chaque client anime la roue jusqu'à ce résultat (voir Wheel.lua).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local WheelManager = {}

WheelManager.SPIN_TIME = 5 -- durée de l'animation (doit être la même que dans Wheel.lua)
local RADIUS = 11
local USE_RANGE = 22

local deps
local wheelModel
local wheelCFrame
local groundCFrame
local busy = false

-- ============================================================
-- CONSTRUCTION
-- ============================================================
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

local function wedge(parent, color)
	local part = Instance.new("WedgePart")
	part.Name = "Segment"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Un triangle plein (a, b, c) fait avec 2 WedgeParts
local function triangle(parent, a, b, c, thickness, color)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local w1 = wedge(parent, color)
	w1.Size = Vector3.new(thickness, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	local w2 = wedge(parent, color)
	w2.Size = Vector3.new(thickness, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
end

-- Un morceau de bois entre deux points (pieds de la roue)
local function beam(parent, from, to, thickness, color)
	local length = (to - from).Magnitude
	return makePart(parent, "Leg", Vector3.new(thickness, thickness, length), CFrame.lookAt((from + to) / 2, to), color)
end

local function textLabel(parent, text, size, position, color, font)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = font or Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = parent
	return label
end

local function buildWheel()
	local prizes = GameConfig.WHEEL.Prizes
	local segment = 360 / #prizes

	local model = Instance.new("Model")
	model.Name = "FortuneWheel"

	-- Sol : plateforme ronde
	local function flat(cframe)
		return cframe * CFrame.Angles(0, 0, math.rad(90))
	end
	local platform = makePart(model, "Platform", Vector3.new(0.8, 34, 34), flat(groundCFrame * CFrame.new(0, 0.4, 0)), Color3.fromRGB(240, 232, 215))
	platform.Shape = Enum.PartType.Cylinder
	local ring = makePart(model, "PlatformRing", Vector3.new(0.6, 36, 36), flat(groundCFrame * CFrame.new(0, 0.3, 0)), Color3.fromRGB(220, 70, 70))
	ring.Shape = Enum.PartType.Cylinder

	-- Pieds (en A derrière la roue)
	local wood = Color3.fromRGB(150, 100, 60)
	local axle = wheelCFrame.Position
	for _, side in ipairs({-1, 1}) do
		local foot = (groundCFrame * CFrame.new(side * 7, 0.8, 1.8)).Position
		beam(model, foot, axle + wheelCFrame.LookVector * -1.8, 1.4, wood)
	end
	makePart(model, "AxleBar", Vector3.new(1.2, 1.2, 3), wheelCFrame * CFrame.new(0, 0, 1.2), Color3.fromRGB(90, 90, 100), Enum.Material.Metal)

	-- La flèche fixe en haut
	local pointer = makePart(model, "Pointer", Vector3.new(1.8, 1.8, 0.8), wheelCFrame * CFrame.new(0, RADIUS + 1.15, -1.1) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(230, 50, 50))
	pointer.CanCollide = false

	-- ===== LA PARTIE QUI TOURNE =====
	local disc = Instance.new("Model")
	disc.Name = "Disc"
	disc.Parent = model

	local center = makePart(disc, "Axle", Vector3.new(0.5, 0.5, 0.5), wheelCFrame, Color3.new(1, 1, 1))
	center.Transparency = 1
	center.CanCollide = false
	center.CanQuery = false
	disc.PrimaryPart = center

	local function point(angle, radius, z)
		local rad = math.rad(angle)
		return wheelCFrame:PointToWorldSpace(Vector3.new(-math.sin(rad) * radius, math.cos(rad) * radius, z))
	end

	-- dos de la roue (cercle sombre)
	local backing = makePart(disc, "Backing", Vector3.new(1, (RADIUS + 0.8) * 2, (RADIUS + 0.8) * 2), wheelCFrame * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(45, 40, 60))
	backing.Shape = Enum.PartType.Cylinder
	backing.CanCollide = false

	for index, prize in ipairs(prizes) do
		local middle = (index - 1) * segment
		local color = prize.Color
		-- la case : 4 triangles pour que le bord soit bien rond
		local steps = 4
		for s = 0, steps - 1 do
			local a1 = middle - segment / 2 + s * segment / steps
			local a2 = a1 + segment / steps
			local shade = (s == 0 or s == steps - 1) and color:Lerp(Color3.new(0, 0, 0), 0.08) or color
			triangle(disc, point(0, 0, -0.62), point(a1, RADIUS, -0.62), point(a2, RADIUS, -0.62), 0.2, shade)
		end
		-- séparation dorée
		local edge = middle + segment / 2
		local divider = makePart(disc, "Divider", Vector3.new(0.35, RADIUS, 0.3), wheelCFrame * CFrame.Angles(0, 0, math.rad(edge)) * CFrame.new(0, RADIUS / 2, -0.85), Color3.fromRGB(255, 215, 90))
		divider.CanCollide = false
		-- icône + nom de la case
		local label = makePart(disc, "Label", Vector3.new(5.4, 4.2, 0.1), wheelCFrame * CFrame.Angles(0, 0, math.rad(middle)) * CFrame.new(0, RADIUS * 0.62, -0.8), Color3.new(1, 1, 1))
		label.Transparency = 1
		label.CanCollide = false
		label.CanQuery = false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.2
		gui.Parent = label
		textLabel(gui, prize.Icon, UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0, 0), Color3.new(1, 1, 1), Enum.Font.GothamBold)
		textLabel(gui, prize.Name, UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.58, 0), Color3.new(1, 1, 1))
	end

	-- ampoules autour (plastique, pas de néon)
	for i = 0, 23 do
		local bulb = makePart(disc, "Bulb", Vector3.new(0.8, 0.8, 0.8), CFrame.new(point(i * 15 + 7.5, RADIUS + 0.4, -0.7)), i % 2 == 0 and Color3.fromRGB(255, 240, 200) or Color3.fromRGB(255, 200, 60))
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
	end

	-- moyeu au centre
	local hub = makePart(disc, "Hub", Vector3.new(1, 4.4, 4.4), wheelCFrame * CFrame.new(0, 0, -1) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 200, 60))
	hub.Shape = Enum.PartType.Cylinder
	hub.CanCollide = false
	local cap = makePart(disc, "HubCap", Vector3.new(2, 2, 2), wheelCFrame * CFrame.new(0, 0, -1.4), Color3.fromRGB(255, 245, 220))
	cap.Shape = Enum.PartType.Ball
	cap.CanCollide = false

	-- ===== TITRE + INFOS (le client écrit ses infos à lui : tour gratuit, nombre de tours) =====
	local board = makePart(model, "InfoAnchor", Vector3.new(1, 1, 1), wheelCFrame * CFrame.new(0, RADIUS + 5.5, 0), Color3.new(1, 1, 1))
	board.Transparency = 1
	board.CanCollide = false
	board.CanQuery = false
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WheelInfo"
	billboard.Size = UDim2.new(0, 420, 0, 130)
	billboard.MaxDistance = 160
	billboard.LightInfluence = 0
	billboard.Parent = board
	textLabel(billboard, "ROUE DE LA FORTUNE", UDim2.new(1, 0, 0.44, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 220, 90), Enum.Font.LuckiestGuy).Name = "Title"
	textLabel(billboard, "", UDim2.new(1, 0, 0.26, 0), UDim2.new(0, 0, 0.46, 0), Color3.fromRGB(120, 255, 140)).Name = "FreeLabel"
	textLabel(billboard, "[E] Tourner   •   [F] Acheter des tours", UDim2.new(1, 0, 0.22, 0), UDim2.new(0, 0, 0.76, 0), Color3.fromRGB(235, 235, 245)).Name = "HintLabel"

	-- ===== LE PUPITRE AVEC LES BOUTONS E / F =====
	local console = makePart(model, "Console", Vector3.new(3, 3.4, 3), groundCFrame * CFrame.new(0, 2.5, -10), Color3.fromRGB(45, 40, 60))
	makePart(model, "ConsoleTop", Vector3.new(3.4, 0.4, 3.4), groundCFrame * CFrame.new(0, 4.4, -10), Color3.fromRGB(255, 200, 60))

	local spinPrompt = Instance.new("ProximityPrompt")
	spinPrompt.Name = "SpinPrompt"
	spinPrompt.ActionText = "Tourner la roue"
	spinPrompt.ObjectText = "Roue de la fortune"
	spinPrompt.KeyboardKeyCode = Enum.KeyCode.E
	spinPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	spinPrompt.MaxActivationDistance = 14
	spinPrompt.RequiresLineOfSight = false
	spinPrompt.Parent = console
	spinPrompt.Triggered:Connect(function(player)
		WheelManager.onSpin(player)
	end)

	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.Name = "BuyPrompt"
	buyPrompt.ActionText = "Acheter des tours"
	buyPrompt.ObjectText = "Roue de la fortune"
	buyPrompt.KeyboardKeyCode = Enum.KeyCode.F
	buyPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	buyPrompt.MaxActivationDistance = 14
	buyPrompt.RequiresLineOfSight = false
	buyPrompt.UIOffset = Vector2.new(0, 80)
	buyPrompt.Parent = console
	buyPrompt.Triggered:Connect(function(player)
		deps.Remotes.OpenWheel:FireClient(player)
	end)

	-- État de la roue (lu par les clients pour l'animer)
	model:SetAttribute("DiscCFrame", wheelCFrame)
	model:SetAttribute("Result", 1)
	model:SetAttribute("Jitter", 0)
	model:SetAttribute("SpinId", 0)
	model:SetAttribute("SpinTime", WheelManager.SPIN_TIME)
	model.Parent = Workspace
	return model
end

-- ============================================================
-- GAINS
-- ============================================================
-- Revenu par seconde actuel du joueur (brainrots posés)
local function getIncome(player)
	local total = 0
	for _, item in ipairs(deps.PlayerData.getItems(player)) do
		if (item:GetAttribute("Slot") or 0) > 0 then
			total += GameConfig.getItemIncome(item.Value, item:GetAttribute("Mutation"))
		end
	end
	return total * GameConfig.getPlayerMultiplier(player)
end

local function grant(player, prize)
	local details = {}
	if prize.IncomeSeconds then
		local amount = math.floor(math.max(prize.Min, getIncome(player) * prize.IncomeSeconds))
		player.leaderstats.Cash.Value += amount
		details.Cash = amount
	elseif prize.Rarity then
		local cardName = deps.Loot.rollCardOfRarity(prize.Rarity)
		local mutation = deps.Loot.rollMutation()
		local item = deps.PlayerData.addItem(player, cardName, mutation, 0, nil, "a gagné à la roue")
		details.Card = cardName
		details.Mutation = mutation
		details.Serial = item and item:GetAttribute("Serial") or 0
	elseif prize.Minutes then
		deps.PlayerData.addLuckMinutes(player, prize.Minutes)
		details.Minutes = prize.Minutes
	elseif prize.Id == "BoosterGalaxie" then
		local booster
		for _, b in ipairs(GameConfig.BOOSTERS) do
			if b.Id == "Galaxie" then
				booster = b
			end
		end
		local cards = deps.Loot.rollBooster(booster)
		for _, result in ipairs(cards) do
			local item = deps.PlayerData.addItem(player, result.Name, result.Mutation, 0, nil, "a pack")
			result.Serial = item and item:GetAttribute("Serial") or 0
		end
		details.Booster = "Galaxie"
		details.Cards = cards
	end
	return details
end

local function isNear(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - groundCFrame.Position).Magnitude <= USE_RANGE + 12
end

function WheelManager.onSpin(player)
	if not isNear(player) then
		deps.Remotes.notify(player, "Va à la ROUE DE LA FORTUNE pour tourner (touche E)", "error")
		return
	end
	if busy then
		deps.Remotes.notify(player, "La roue tourne déjà, attends un peu !", "info")
		return
	end
	local now = os.time()
	local lastFree = player:GetAttribute("LastFreeSpin") or 0
	if now - lastFree >= GameConfig.WHEEL.FreeCooldown then
		player:SetAttribute("LastFreeSpin", now)
	elseif player.Spins.Value > 0 then
		player.Spins.Value -= 1
	else
		deps.Remotes.notify(player, "Plus de tours ! Reviens plus tard ou achète des tours (touche F)", "error")
		return
	end

	busy = true
	local index = deps.Loot.rollWheel()
	local prize = GameConfig.WHEEL.Prizes[index]
	-- Tous les clients animent la roue jusqu'à cette case
	wheelModel:SetAttribute("Result", index)
	wheelModel:SetAttribute("Jitter", math.floor((math.random() - 0.5) * 36))
	wheelModel:SetAttribute("Spinner", player.DisplayName)
	wheelModel:SetAttribute("SpinId", (wheelModel:GetAttribute("SpinId") or 0) + 1)

	-- Le gain arrive quand la roue s'arrête
	task.delay(WheelManager.SPIN_TIME + 0.2, function()
		busy = false
		if not player.Parent then return end
		local details = grant(player, prize)
		deps.Remotes.WheelResult:FireClient(player, index, details)
		deps.Remotes.Effect:FireAllClients("WheelWin", {Position = wheelCFrame.Position, Color = prize.Color})
		task.spawn(deps.PlayerData.save, player)
	end)
end

function WheelManager.addSpins(player, amount)
	player.Spins.Value += amount
end

-- Devant la roue (pour les tapis roulants)
function WheelManager.getFrontPosition()
	return (groundCFrame * CFrame.new(0, 0, -20)).Position
end

function WheelManager.getVisitCFrame()
	return groundCFrame * CFrame.new(0, 4, -14) * CFrame.Angles(0, math.rad(180), 0)
end

function WheelManager.init(dependencies)
	deps = dependencies
	-- À l'est de la mine, tournée vers elle
	local position = Vector3.new(deps.MineHalf + 110, 0, 0)
	groundCFrame = CFrame.lookAt(position, Vector3.new(0, 0, 0))
	wheelCFrame = groundCFrame * CFrame.new(0, 3.2 + RADIUS, 0)
	wheelModel = buildWheel()
	deps.Remotes.SpinWheel.OnServerEvent:Connect(WheelManager.onSpin)
end

return WheelManager
