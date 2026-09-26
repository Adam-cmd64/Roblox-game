-- ModuleScript client : le ciel animé (seulement chez le joueur, rien ne passe par le réseau).
--   - des aurores (rubans de lumière violet / cyan / rose) qui ondulent dans le ciel
--   - de grosses étoiles qui scintillent
--   - des étoiles filantes de temps en temps
--   - des petites particules brillantes qui flottent autour du joueur
-- Le ciel étoilé et la couleur de l'horizon sont réglés par le serveur (WorldBuilder).

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local Sky = {}

local folder
local auroras = {}

local function anchorPart(name, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Parent = folder
	return part
end

-- ====== AURORES ======
local AURORA_COLORS = {
	{Color3.fromRGB(80, 255, 220), Color3.fromRGB(120, 120, 255), Color3.fromRGB(255, 90, 230)},
	{Color3.fromRGB(255, 80, 220), Color3.fromRGB(170, 90, 255), Color3.fromRGB(60, 200, 255)},
	{Color3.fromRGB(90, 180, 255), Color3.fromRGB(80, 255, 200), Color3.fromRGB(200, 120, 255)},
}

local function makeAurora(index, center, length, height, width)
	local holder = anchorPart("Aurora", center + Vector3.new(0, height, 0))
	local turn = CFrame.Angles(0, math.rad(index * 55), 0)
	local a0 = Instance.new("Attachment")
	-- l'axe X des attachments pointe vers le haut : les courbes font onduler le ruban de haut en bas
	a0.CFrame = turn * CFrame.new(-length / 2, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	a0.Parent = holder
	local a1 = Instance.new("Attachment")
	a1.CFrame = turn * CFrame.new(length / 2, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	a1.Parent = holder

	local colors = AURORA_COLORS[(index - 1) % #AURORA_COLORS + 1]
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colors[1]),
		ColorSequenceKeypoint.new(0.5, colors[2]),
		ColorSequenceKeypoint.new(1, colors[3]),
	})
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.55),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.8, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 40
	beam.Width0 = width
	beam.Width1 = width * 0.6
	beam.Parent = holder
	table.insert(auroras, {beam = beam, phase = index * 1.7, size = length * 0.25})
end

-- ====== GROSSES ETOILES QUI SCINTILLENT ======
local STAR_COLORS = {
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 230, 255), Color3.fromRGB(255, 190, 245), Color3.fromRGB(170, 255, 235),
}

local function makeStars(count)
	local random = Random.new(12)
	for i = 1, count do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(150, 900)
		local position = Vector3.new(math.cos(angle) * distance, random:NextNumber(260, 620), math.sin(angle) * distance)
		local holder = anchorPart("Star", position)
		local gui = Instance.new("BillboardGui")
		local size = random:NextInteger(18, 46)
		gui.Size = UDim2.new(0, size, 0, size)
		gui.LightInfluence = 0
		gui.Parent = holder
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = i % 4 == 0 and "✧" or "✦"
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = STAR_COLORS[random:NextInteger(1, #STAR_COLORS)]
		label.TextStrokeTransparency = 1
		label.Parent = gui
		label:SetAttribute("Phase", random:NextNumber(0, 10))
		CollectionService:AddTag(label, "Sparkle") -- scintillement animé par World.lua
	end
end

-- ====== ETOILES FILANTES ======
local function shootingStar()
	local random = Random.new()
	local angle = random:NextNumber(0, math.pi * 2)
	local start = Vector3.new(math.cos(angle) * random:NextNumber(100, 500), random:NextNumber(280, 450), math.sin(angle) * random:NextNumber(100, 500))
	local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-0.35, -0.15), random:NextNumber(-1, 1)).Unit
	local finish = start + direction * random:NextNumber(260, 420)

	local star = Instance.new("Part")
	star.Name = "ShootingStar"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.new(2.5, 2.5, 2.5)
	star.Material = Enum.Material.Neon
	star.Color = Color3.fromRGB(230, 245, 255)
	star.Anchored = true
	star.CanCollide = false
	star.CanQuery = false
	star.CanTouch = false
	star.CastShadow = false
	star.Position = start
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.5, 0)
	a0.Parent = star
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1.5, 0)
	a1.Parent = star
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.55
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 200, 255))
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.FaceCamera = true
	trail.Parent = star
	star.Parent = folder

	local duration = random:NextNumber(0.9, 1.5)
	TweenService:Create(star, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = finish}):Play()
	TweenService:Create(star, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
	Debris:AddItem(star, duration + 0.8)
end

-- ====== PARTICULES QUI FLOTTENT AUTOUR DU JOUEUR ======
local function makeFloatingParticles()
	local box = anchorPart("FloatingParticles", Vector3.new(0, 10, 0))
	box.Size = Vector3.new(110, 30, 110)
	local particles = Instance.new("ParticleEmitter")
	particles.Shape = Enum.ParticleEmitterShape.Box
	particles.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	particles.Rate = 30
	particles.Lifetime = NumberRange.new(5, 9)
	particles.Speed = NumberRange.new(0.2, 1)
	particles.Acceleration = Vector3.new(0, 0.35, 0)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.35),
		NumberSequenceKeypoint.new(0.8, 0.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 230, 255)),
	})
	particles.LightEmission = 1
	particles.LightInfluence = 0
	particles.Parent = box
	return box
end

function Sky.init()
	folder = Instance.new("Folder")
	folder.Name = "SkyFX"
	folder.Parent = Workspace

	makeAurora(1, Vector3.new(0, 0, -250), 1300, 420, 140)
	makeAurora(2, Vector3.new(150, 0, 200), 1100, 480, 110)
	makeAurora(3, Vector3.new(-250, 0, 60), 1000, 380, 90)
	makeStars(45)
	local particleBox = makeFloatingParticles()

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, aurora in ipairs(auroras) do
			aurora.beam.CurveSize0 = math.sin(t * 0.25 + aurora.phase) * aurora.size
			aurora.beam.CurveSize1 = math.cos(t * 0.2 + aurora.phase) * aurora.size
		end
		local camera = Workspace.CurrentCamera
		if camera then
			particleBox.Position = camera.CFrame.Position
		end
	end)

	task.spawn(function()
		while true do
			task.wait(math.random(15, 40) / 10)
			shootingStar()
		end
	end)
end

return Sky
