-- ModuleScript : le COFFRE DORÉ du CADEAU DE DÉPART (sur la dalle en pierre, à côté de la roue).
-- On marche dans la zone jaune (ou touche E) : le menu "Cadeau de départ" s'ouvre (voir Daily.lua).
-- Le cadeau (une seule fois) : mettre le jeu en favori + un like => une carte Très Rare + de l'argent.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local StarterChest = {}

local deps
local chestPosition
local GOLD = Color3.fromRGB(255, 200, 60)
local ROYAL = Color3.fromRGB(125, 45, 190)
local YELLOW = Color3.fromRGB(255, 220, 60)

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

local function deco(part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

local function build(position)
	local model = Instance.new("Model")
	model.Name = "StarterChest"
	-- le coffre regarde vers la mine
	local base = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end
	local flat = CFrame.Angles(0, 0, math.rad(90))

	-- la zone jaune au sol (on marche dedans pour ouvrir le menu)
	local radius = GameConfig.STARTER.ZoneRadius
	local zone = deco(makePart(model, "Zone", Vector3.new(0.12, radius * 2, radius * 2), at(0, 0.08, 0) * flat, YELLOW, Enum.Material.Neon))
	zone.Shape = Enum.PartType.Cylinder
	zone.Transparency = 0.55
	local zoneRing = deco(makePart(model, "ZoneRing", Vector3.new(0.1, radius * 2 + 1, radius * 2 + 1), at(0, 0.07, 0) * flat, Color3.fromRGB(255, 170, 30), Enum.Material.Neon))
	zoneRing.Shape = Enum.PartType.Cylinder

	-- le socle en pierre (la dalle) + bord doré
	local pedestal = makePart(model, "Pedestal", Vector3.new(1.2, 8, 8), at(0, 0.6, 0) * flat, Color3.fromRGB(120, 115, 135), Enum.Material.Slate)
	pedestal.Shape = Enum.PartType.Cylinder
	local rim = deco(makePart(model, "PedestalRim", Vector3.new(0.3, 8.4, 8.4), at(0, 1.1, 0) * flat, GOLD, Enum.Material.Metal))
	rim.Shape = Enum.PartType.Cylinder

	-- le coffre : corps violet royal, coins et bandes dorés
	local chestY = 1.2
	local body = makePart(model, "ChestBody", Vector3.new(4.4, 2.4, 3), at(0, chestY + 1.2, 0), ROYAL, Enum.Material.SmoothPlastic)
	for _, x in ipairs({-2.05, 2.05}) do
		makePart(model, "ChestCorner", Vector3.new(0.4, 2.5, 3.1), at(x, chestY + 1.2, 0), GOLD, Enum.Material.Metal)
	end
	for _, x in ipairs({-0.9, 0.9}) do
		deco(makePart(model, "ChestBand", Vector3.new(0.35, 2.5, 3.1), at(x, chestY + 1.2, 0), GOLD, Enum.Material.Metal))
	end
	deco(makePart(model, "ChestTrim", Vector3.new(4.5, 0.3, 3.1), at(0, chestY + 0.15, 0), GOLD, Enum.Material.Metal))

	-- le couvercle (un modèle à part : le client l'ouvre quand le menu est ouvert)
	local lid = Instance.new("Model")
	lid.Name = "Lid"
	lid.Parent = model
	local hinge = deco(makePart(lid, "Hinge", Vector3.new(4.4, 0.3, 0.3), at(0, chestY + 2.4, 1.5), GOLD, Enum.Material.Metal))
	lid.PrimaryPart = hinge
	makePart(lid, "LidTop", Vector3.new(4.4, 1.1, 3), at(0, chestY + 2.95, 0), ROYAL, Enum.Material.SmoothPlastic)
	makePart(lid, "LidRound", Vector3.new(4.4, 0.6, 2.2), at(0, chestY + 3.75, 0), ROYAL, Enum.Material.SmoothPlastic)
	for _, x in ipairs({-2.05, -0.9, 0.9, 2.05}) do
		deco(makePart(lid, "LidBand", Vector3.new(0.38, 1.75, 3.1), at(x, chestY + 3.2, 0), GOLD, Enum.Material.Metal))
	end
	local lock = deco(makePart(lid, "Lock", Vector3.new(0.9, 1.1, 0.4), at(0, chestY + 2.5, -1.6), GOLD, Enum.Material.Metal))
	lock.Name = "Lock"
	local gem = deco(makePart(lid, "Gem", Vector3.new(0.55, 0.55, 0.55), at(0, chestY + 2.6, -1.85) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(90, 230, 255), Enum.Material.Neon))
	gem.Name = "Gem"

	-- la lumière dorée qui sort du coffre + étincelles
	local glow = deco(makePart(model, "Glow", Vector3.new(3.6, 0.2, 2.4), at(0, chestY + 2.45, 0), Color3.fromRGB(255, 230, 120), Enum.Material.Neon))
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 110)
	light.Range = 18
	light.Brightness = 2
	light.Parent = glow
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 160, 240))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.5, 0)
	sparkles.Lifetime = NumberRange.new(1, 2)
	sparkles.Rate = 14
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(35, 35)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = glow

	-- 4 petits cristaux qui tournent autour (animés par le client)
	for i = 0, 3 do
		local angle = math.rad(i * 90)
		local crystal = deco(makePart(model, "OrbitCrystal", Vector3.new(0.7, 1.2, 0.7), at(math.cos(angle) * 4.2, 5.5, math.sin(angle) * 4.2), i % 2 == 0 and YELLOW or Color3.fromRGB(255, 120, 220), Enum.Material.Neon))
		crystal:SetAttribute("Angle", i * 90)
	end

	-- le panneau au-dessus (le client y écrit "dispo !" ou le temps restant)
	local anchor = deco(makePart(model, "Sign", Vector3.new(1, 1, 1), at(0, 8.5, 0), Color3.new(1, 1, 1)))
	anchor.Transparency = 1
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DailyInfo"
	billboard.Size = UDim2.new(0, 360, 0, 90)
	billboard.MaxDistance = 140
	billboard.LightInfluence = 0
	billboard.Parent = anchor
	local function label(name, text, size, position, color)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Size = size
		l.Position = position
		l.Text = text
		l.TextColor3 = color
		l.TextStrokeTransparency = 0
		l.Font = Enum.Font.LuckiestGuy
		l.TextScaled = true
		l.Parent = billboard
		return l
	end
	label("Title", "🎁 CADEAU DE DÉPART", UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0, 0), YELLOW)
	label("Status", "Entre dans la zone jaune !", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.58, 0), Color3.new(1, 1, 1))

	-- touche E aussi (au cas où)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StarterPrompt"
	prompt.ActionText = "Ouvrir"
	prompt.ObjectText = "Cadeau de départ"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		deps.Remotes.OpenStarter:FireClient(player)
	end)

	model:SetAttribute("Radius", radius)
	-- positions de repos (le client anime à partir de là, jamais "au hasard")
	model:SetAttribute("Center", position)
	model:SetAttribute("LidCFrame", hinge.CFrame)
	local lidParts = 0
	for _, part in ipairs(lid:GetDescendants()) do
		if part:IsA("BasePart") then
			lidParts += 1
		end
	end
	model:SetAttribute("LidParts", lidParts)
	-- toujours chargé en entier chez tous les joueurs (le client anime le couvercle et les cristaux)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
	model.Parent = Workspace
	return model
end

-- Le joueur est-il à côté du coffre ?
function StarterChest.isNear(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and chestPosition ~= nil and (root.Position - chestPosition).Magnitude <= GameConfig.STARTER.ZoneRadius + 8
end

function StarterChest.init(dependencies)
	deps = dependencies
	chestPosition = Workspace:GetAttribute("StarterChestPosition") or Vector3.new(105, 0, 22)
	build(chestPosition)
end

return StarterChest
