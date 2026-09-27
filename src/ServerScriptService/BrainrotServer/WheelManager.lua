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
local RADIUS = 12
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

local GOLD = Color3.fromRGB(255, 200, 70)
local DEEP = Color3.fromRGB(40, 24, 70)
local CYAN = Color3.fromRGB(70, 230, 255)
local PINK = Color3.fromRGB(255, 90, 210)

local function noCollide(part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- Un anneau fait de petits blocs (bord doré, halo néon...)
local function ring(parent, name, cframe, radius, count, size, color, material, z)
	local parts = {}
	for i = 0, count - 1 do
		local angle = i * 360 / count
		local length = 2 * math.pi * radius / count + 0.08
		local part = makePart(parent, name, Vector3.new(length, size.X, size.Y), cframe * CFrame.Angles(0, 0, math.rad(angle)) * CFrame.new(0, radius, z), typeof(color) == "function" and color(i) or color, material)
		noCollide(part)
		table.insert(parts, part)
	end
	return parts
end

local function sparkles(parent, color, rate, size)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new(size or 0.5, 0)
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(0.5, 2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = parent
	return emitter
end

local function buildWheel()
	local prizes = GameConfig.WHEEL.Prizes
	local segment = 360 / #prizes

	local model = Instance.new("Model")
	model.Name = "FortuneWheel"

	-- ===== LA SCÈNE : plateforme ronde en 2 étages, anneau néon, runes =====
	local function flat(cframe)
		return cframe * CFrame.Angles(0, 0, math.rad(90))
	end
	local base = makePart(model, "Platform", Vector3.new(1, 40, 40), flat(groundCFrame * CFrame.new(0, 0.5, 0)), Color3.fromRGB(55, 40, 90), Enum.Material.Marble)
	base.Shape = Enum.PartType.Cylinder
	local top = makePart(model, "PlatformTop", Vector3.new(1, 30, 30), flat(groundCFrame * CFrame.new(0, 1.2, 0)), Color3.fromRGB(75, 55, 125), Enum.Material.Marble)
	top.Shape = Enum.PartType.Cylinder
	local glow = makePart(model, "PlatformGlow", Vector3.new(0.9, 40.6, 40.6), flat(groundCFrame * CFrame.new(0, 0.45, 0)), CYAN, Enum.Material.Neon)
	glow.Shape = Enum.PartType.Cylinder
	noCollide(glow)
	local glow2 = makePart(model, "PlatformGlow", Vector3.new(0.9, 30.6, 30.6), flat(groundCFrame * CFrame.new(0, 1.15, 0)), GOLD, Enum.Material.Neon)
	glow2.Shape = Enum.PartType.Cylinder
	noCollide(glow2)
	-- petites runes lumineuses sur le sol
	for i = 0, 11 do
		local rune = makePart(model, "Rune", Vector3.new(1.2, 0.1, 1.2), groundCFrame * CFrame.Angles(0, math.rad(i * 30), 0) * CFrame.new(0, 1.72, -12.5) * CFrame.Angles(0, math.rad(45), 0), i % 2 == 0 and PINK or CYAN, Enum.Material.Neon)
		noCollide(rune)
	end

	-- ===== LE SUPPORT : un pied violet et or =====
	local axle = wheelCFrame.Position
	local standHeight = axle.Y - groundCFrame.Position.Y - 1.7
	local stand = makePart(model, "Stand", Vector3.new(5, standHeight, 3), groundCFrame * CFrame.new(0, 1.7 + standHeight / 2, 1.6), DEEP, Enum.Material.SmoothPlastic)
	stand.CanCollide = true
	for _, x in ipairs({-2.6, 2.6}) do
		makePart(model, "StandTrim", Vector3.new(0.35, standHeight, 3.2), groundCFrame * CFrame.new(x, 1.7 + standHeight / 2, 1.6), GOLD, Enum.Material.Metal)
	end
	for _, side in ipairs({-1, 1}) do
		local foot = (groundCFrame * CFrame.new(side * 8, 1.7, 2.2)).Position
		beam(model, foot, axle + wheelCFrame.LookVector * -1.8, 1.1, GOLD).Material = Enum.Material.Metal
	end
	makePart(model, "AxleBar", Vector3.new(1.4, 1.4, 3), wheelCFrame * CFrame.new(0, 0, 1.2), Color3.fromRGB(90, 90, 100), Enum.Material.Metal)

	-- ===== LE HALO DERRIÈRE LA ROUE (anneau néon + rayons qui tournent doucement) =====
	ring(model, "HaloRing", wheelCFrame, RADIUS + 2.6, 48, Vector2.new(0.5, 0.3), function(i)
		return i % 2 == 0 and CYAN or PINK
	end, Enum.Material.Neon, 1.4)
	local halo = Instance.new("Model")
	halo.Name = "Halo"
	halo.Parent = model
	local haloCenter = noCollide(makePart(halo, "HaloCenter", Vector3.new(0.4, 0.4, 0.4), wheelCFrame * CFrame.new(0, 0, 1.8), Color3.new(1, 1, 1)))
	haloCenter.Transparency = 1
	halo.PrimaryPart = haloCenter
	for i = 0, 15 do
		local length = i % 2 == 0 and 6 or 3.5
		local ray = makePart(halo, "Ray", Vector3.new(i % 2 == 0 and 0.7 or 0.45, length, 0.2), wheelCFrame * CFrame.Angles(0, 0, math.rad(i * 22.5 + 11.25)) * CFrame.new(0, RADIUS + 1.2 + length / 2, 1.8), i % 2 == 0 and GOLD or Color3.fromRGB(255, 240, 180), Enum.Material.Neon)
		ray.Transparency = 0.25
		noCollide(ray)
	end
	sparkles(haloCenter, Color3.fromRGB(255, 230, 150), 0) -- (activé par le client quand la roue gagne)

	-- ===== LA FLÈCHE (en haut, elle claque sur les picots) =====
	local pointerModel = Instance.new("Model")
	pointerModel.Name = "PointerModel"
	pointerModel.Parent = model
	local pivot = noCollide(makePart(pointerModel, "PointerPivot", Vector3.new(0.6, 0.6, 0.6), wheelCFrame * CFrame.new(0, RADIUS + 3.4, -2.2), GOLD, Enum.Material.Metal))
	pointerModel.PrimaryPart = pivot
	local pointer = noCollide(makePart(pointerModel, "Pointer", Vector3.new(2.2, 2.2, 0.9), wheelCFrame * CFrame.new(0, RADIUS + 2.1, -2.2) * CFrame.Angles(0, 0, math.rad(45)), GOLD, Enum.Material.Metal))
	pointer.Name = "Pointer"
	noCollide(makePart(pointerModel, "PointerTip", Vector3.new(0.9, 0.9, 1), wheelCFrame * CFrame.new(0, RADIUS + 0.9, -2.2) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(230, 40, 70), Enum.Material.Neon))
	local gem = noCollide(makePart(pointerModel, "PointerGem", Vector3.new(1, 1, 1), wheelCFrame * CFrame.new(0, RADIUS + 2.1, -2.8), Color3.fromRGB(230, 40, 70), Enum.Material.Neon))
	gem.Shape = Enum.PartType.Ball
	local gemLight = Instance.new("PointLight")
	gemLight.Color = Color3.fromRGB(255, 80, 120)
	gemLight.Range = 10
	gemLight.Parent = gem

	-- ===== L'ENSEIGNE LUMINEUSE AU-DESSUS =====
	local sign = makePart(model, "Marquee", Vector3.new(24, 4.2, 0.8), wheelCFrame * CFrame.new(0, RADIUS + 7.4, 0.4), DEEP)
	noCollide(sign)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 40
	signGui.LightInfluence = 0
	signGui.Parent = sign
	local title = textLabel(signGui, "✦ ROUE DE LA FORTUNE ✦", UDim2.new(0.94, 0, 0.8, 0), UDim2.new(0.03, 0, 0.1, 0), GOLD, Enum.Font.LuckiestGuy)
	title.TextStrokeColor3 = Color3.fromRGB(90, 30, 10)
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 170, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 150)),
	})
	titleGradient.Rotation = 90
	titleGradient.Parent = title
	for _, y in ipairs({-2.25, 2.25}) do
		noCollide(makePart(model, "MarqueeTrim", Vector3.new(24.6, 0.35, 1), wheelCFrame * CFrame.new(0, RADIUS + 7.4 + y, 0.4), GOLD, Enum.Material.Metal))
	end
	local signBulbs = 0
	for i = 0, 15 do
		for _, y in ipairs({-2.25, 2.25}) do
			local bulb = noCollide(makePart(model, "SignBulb", Vector3.new(0.45, 0.45, 0.45), wheelCFrame * CFrame.new(-11.25 + i * 1.5, RADIUS + 7.4 + y, -0.2), GOLD, Enum.Material.Neon))
			bulb.Shape = Enum.PartType.Ball
			bulb:SetAttribute("Index", i)
			signBulbs += 1
		end
	end

	-- ===== LES 2 PILIERS DE CRISTAL =====
	for _, side in ipairs({-1, 1}) do
		local x = side * (RADIUS + 6.5)
		local pillarBase = groundCFrame * CFrame.new(x, 0, 1)
		makePart(model, "PillarBase", Vector3.new(3.4, 1.4, 3.4), pillarBase * CFrame.new(0, 2.4, 0), DEEP, Enum.Material.Marble)
		makePart(model, "Pillar", Vector3.new(2, 16, 2), pillarBase * CFrame.new(0, 11, 0), Color3.fromRGB(75, 55, 125), Enum.Material.Marble)
		noCollide(makePart(model, "PillarGlow", Vector3.new(2.2, 0.3, 2.2), pillarBase * CFrame.new(0, 6, 0), CYAN, Enum.Material.Neon))
		noCollide(makePart(model, "PillarGlow", Vector3.new(2.2, 0.3, 2.2), pillarBase * CFrame.new(0, 15, 0), PINK, Enum.Material.Neon))
		makePart(model, "PillarCap", Vector3.new(3, 0.8, 3), pillarBase * CFrame.new(0, 19.4, 0), GOLD, Enum.Material.Metal)
		local crystal = noCollide(makePart(model, "PillarCrystal", Vector3.new(1.8, 3.2, 1.8), pillarBase * CFrame.new(0, 21.8, 0) * CFrame.Angles(0, math.rad(45), 0), side < 0 and CYAN or PINK, Enum.Material.Neon))
		crystal:SetAttribute("BobPhase", side)
		local light = Instance.new("PointLight")
		light.Color = crystal.Color
		light.Range = 22
		light.Brightness = 1.4
		light.Parent = crystal
		sparkles(crystal, crystal.Color, 6, 0.6)
	end

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
	local backing = makePart(disc, "Backing", Vector3.new(1, (RADIUS + 1.4) * 2, (RADIUS + 1.4) * 2), wheelCFrame * CFrame.Angles(0, math.rad(90), 0), DEEP)
	backing.Shape = Enum.PartType.Cylinder
	backing.CanCollide = false

	-- bord doré
	ring(disc, "Rim", wheelCFrame, RADIUS + 0.7, 40, Vector2.new(1.4, 1.5), GOLD, Enum.Material.Metal, -0.55)

	for index, prize in ipairs(prizes) do
		local middle = (index - 1) * segment
		local color = prize.Color
		-- la case : couleur vive sur le bord, plus claire vers le centre (effet bombé)
		local steps = 4
		for s = 0, steps - 1 do
			local a1 = middle - segment / 2 + s * segment / steps
			local a2 = a1 + segment / steps
			triangle(disc, point(0, 0, -0.62), point(a1, RADIUS, -0.62), point(a2, RADIUS, -0.62), 0.2, color:Lerp(Color3.new(0, 0, 0), 0.18))
			triangle(disc, point(0, 0, -0.68), point(a1, RADIUS * 0.9, -0.68), point(a2, RADIUS * 0.9, -0.68), 0.2, color)
			triangle(disc, point(0, 0, -0.74), point(a1, RADIUS * 0.45, -0.74), point(a2, RADIUS * 0.45, -0.74), 0.2, color:Lerp(Color3.new(1, 1, 1), 0.3))
		end
		-- séparation dorée + picot sur le bord (la flèche claque dessus)
		local edge = middle + segment / 2
		local divider = makePart(disc, "Divider", Vector3.new(0.35, RADIUS, 0.3), wheelCFrame * CFrame.Angles(0, 0, math.rad(edge)) * CFrame.new(0, RADIUS / 2, -0.9), GOLD, Enum.Material.Metal)
		noCollide(divider)
		local peg = noCollide(makePart(disc, "Peg", Vector3.new(0.7, 0.7, 1.4), wheelCFrame * CFrame.Angles(0, 0, math.rad(edge)) * CFrame.new(0, RADIUS - 0.4, -1.2), Color3.fromRGB(255, 245, 220), Enum.Material.Metal))
		peg.Shape = Enum.PartType.Cylinder
		-- icône + nom de la case
		local label = makePart(disc, "Label", Vector3.new(5.6, 4.6, 0.1), wheelCFrame * CFrame.Angles(0, 0, math.rad(middle)) * CFrame.new(0, RADIUS * 0.63, -0.9), Color3.new(1, 1, 1))
		label.Transparency = 1
		label.CanCollide = false
		label.CanQuery = false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = label
		if GameConfig.WHEEL_ICONS ~= "" and prize.IconIndex then
			-- belle icône dessinée (une case de l'image roue.png)
			local layout = GameConfig.WHEEL_ICON_LAYOUT
			local cell = prize.IconIndex - 1
			local image = Instance.new("ImageLabel")
			image.Name = "Icon"
			image.BackgroundTransparency = 1
			image.Image = GameConfig.WHEEL_ICONS
			image.ImageRectOffset = Vector2.new((cell % layout.Columns) * layout.Size, math.floor(cell / layout.Columns) * layout.Size)
			image.ImageRectSize = Vector2.new(layout.Size, layout.Size)
			image.ScaleType = Enum.ScaleType.Fit
			image.Size = UDim2.new(1, 0, 0.62, 0)
			image.Parent = gui
		else
			textLabel(gui, prize.Icon, UDim2.new(1, 0, 0.58, 0), UDim2.new(0, 0, 0, 0), Color3.new(1, 1, 1), Enum.Font.GothamBold)
		end
		local name = textLabel(gui, string.upper(prize.Name), UDim2.new(1, 0, 0.34, 0), UDim2.new(0, 0, 0.64, 0), Color3.new(1, 1, 1), Enum.Font.LuckiestGuy)
		name.TextStrokeColor3 = color:Lerp(Color3.new(0, 0, 0), 0.6)
	end

	-- ampoules tout autour (le client les fait défiler, plus vite quand la roue tourne)
	for i = 0, 23 do
		local bulb = makePart(disc, "Bulb", Vector3.new(0.75, 0.75, 0.75), CFrame.new(point(i * 15 + 7.5, RADIUS + 0.7, -1.4)), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
		bulb:SetAttribute("Index", i)
		bulb.Shape = Enum.PartType.Ball
		noCollide(bulb)
	end

	-- moyeu : disque doré, gemme, étoile
	local hub = makePart(disc, "Hub", Vector3.new(1, 5.4, 5.4), wheelCFrame * CFrame.new(0, 0, -1) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal)
	hub.Shape = Enum.PartType.Cylinder
	hub.CanCollide = false
	local hubRing = makePart(disc, "HubRing", Vector3.new(1.1, 4, 4), wheelCFrame * CFrame.new(0, 0, -1.1) * CFrame.Angles(0, math.rad(90), 0), DEEP)
	hubRing.Shape = Enum.PartType.Cylinder
	hubRing.CanCollide = false
	local cap = makePart(disc, "HubCap", Vector3.new(2.6, 2.6, 2.6), wheelCFrame * CFrame.new(0, 0, -1.5), Color3.fromRGB(170, 90, 255), Enum.Material.Neon)
	cap.Shape = Enum.PartType.Ball
	cap.CanCollide = false
	local hubLight = Instance.new("PointLight")
	hubLight.Color = Color3.fromRGB(200, 140, 255)
	hubLight.Range = 16
	hubLight.Brightness = 1.2
	hubLight.Parent = cap

	-- ===== TITRE + INFOS (le client écrit ses infos à lui : tour gratuit, nombre de tours) =====
	local board = makePart(model, "InfoAnchor", Vector3.new(1, 1, 1), wheelCFrame * CFrame.new(0, RADIUS + 11.5, 0), Color3.new(1, 1, 1))
	board.Transparency = 1
	board.CanCollide = false
	board.CanQuery = false
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WheelInfo"
	billboard.Size = UDim2.new(0, 420, 0, 70)
	billboard.MaxDistance = 160
	billboard.LightInfluence = 0
	billboard.Parent = board
	textLabel(billboard, "", UDim2.new(1, 0, 0.52, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(120, 255, 140)).Name = "FreeLabel"
	textLabel(billboard, "[E] Tourner   •   [F] Acheter des tours", UDim2.new(1, 0, 0.42, 0), UDim2.new(0, 0, 0.56, 0), Color3.fromRGB(235, 235, 245)).Name = "HintLabel"

	-- ===== LE PUPITRE AVEC LES BOUTONS E / F =====
	local console = makePart(model, "Console", Vector3.new(3, 3.4, 3), groundCFrame * CFrame.new(0, 3.3, -10), DEEP, Enum.Material.Marble)
	makePart(model, "ConsoleTop", Vector3.new(3.6, 0.4, 3.6), groundCFrame * CFrame.new(0, 5.2, -10), GOLD, Enum.Material.Metal)
	local button = makePart(model, "ConsoleButton", Vector3.new(0.6, 2, 2), groundCFrame * CFrame.new(0, 5.6, -10) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 40, 70), Enum.Material.Neon)
	button.Shape = Enum.PartType.Cylinder
	noCollide(button)

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
			total += GameConfig.getItemIncome(item.Value, item:GetAttribute("Mutation")) * GameConfig.getMineralMultiplier(item:GetAttribute("Mineral"))
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
	wheelCFrame = groundCFrame * CFrame.new(0, 5 + RADIUS, 0)
	wheelModel = buildWheel()
	deps.Remotes.SpinWheel.OnServerEvent:Connect(WheelManager.onSpin)
end

return WheelManager
