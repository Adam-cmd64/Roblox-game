-- ModuleScript : le TAPIS VOLANT (Game Pass, voir GameConfig.GAMEPASSES.FlyingCarpet).
-- Le joueur reçoit un outil "Tapis volant". Quand il le prend en main, le tapis apparaît sous ses pieds
-- (tout le monde le voit) et le client le fait voler (voir Carpet.lua côté client).
-- Impossible de voler en portant un brainrot volé.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local CarpetManager = {}

local TOOL_NAME = "Tapis volant"
local deps

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Fabric
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Le tapis : tissu violet, motifs dorés, bordure néon, pompons, étincelles et traînée
local function buildCarpet(cframe)
	local model = Instance.new("Model")
	model.Name = "FlyingCarpet"
	local base = makePart(model, "Base", Vector3.new(6, 0.3, 9), cframe, Color3.fromRGB(110, 40, 170))
	model.PrimaryPart = base
	local gold = Color3.fromRGB(255, 205, 70)
	local neon = Color3.fromRGB(80, 230, 255)
	-- motif : losange central + bandes
	makePart(model, "Pattern", Vector3.new(3, 0.32, 3), cframe * CFrame.Angles(0, math.rad(45), 0), gold)
	makePart(model, "PatternInner", Vector3.new(1.6, 0.34, 1.6), cframe * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(230, 60, 120))
	for _, z in ipairs({-3.2, 3.2}) do
		makePart(model, "Band", Vector3.new(5.4, 0.32, 0.5), cframe * CFrame.new(0, 0, z), gold)
	end
	-- bordure qui brille
	for _, x in ipairs({-3, 3}) do
		makePart(model, "Trim", Vector3.new(0.25, 0.36, 9), cframe * CFrame.new(x, 0, 0), neon, Enum.Material.Neon)
	end
	for _, z in ipairs({-4.5, 4.5}) do
		makePart(model, "Trim", Vector3.new(6, 0.36, 0.25), cframe * CFrame.new(0, 0, z), neon, Enum.Material.Neon)
	end
	-- pompons aux 4 coins
	for _, x in ipairs({-2.8, 2.8}) do
		for _, z in ipairs({-4.7, 4.7}) do
			local tassel = makePart(model, "Tassel", Vector3.new(0.5, 0.5, 0.5), cframe * CFrame.new(x, -0.2, z), gold, Enum.Material.Neon)
			tassel.Shape = Enum.PartType.Ball
		end
	end
	-- soudure de toutes les pièces sur la base
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= base then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = base
			weld.Part1 = part
			weld.Parent = part
		end
	end
	-- étincelles + traînée de lumière
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(neon, Color3.fromRGB(255, 150, 240))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.35, 0)
	sparkles.Lifetime = NumberRange.new(0.6, 1.2)
	sparkles.Rate = 25
	sparkles.Speed = NumberRange.new(0.5, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = base
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(-2.8, 0, 4.4)
	a0.Parent = base
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(2.8, 0, 4.4)
	a1.Parent = base
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.5
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(neon, Color3.fromRGB(200, 90, 255))
	trail.Transparency = NumberSequence.new(0.4, 1)
	trail.Parent = base
	local light = Instance.new("PointLight")
	light.Color = neon
	light.Range = 12
	light.Brightness = 1.2
	light.Parent = base
	return model
end

local function removeCarpet(character)
	local old = character and character:FindFirstChild("FlyingCarpet")
	if old then
		old:Destroy()
	end
end

-- Le client dit "je vole" / "j'arrête" : on met ou on enlève le tapis sous ses pieds
local function onCarpet(player, flying)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	removeCarpet(character)
	if flying ~= true or player:GetAttribute("FlyingCarpet") ~= true or player:GetAttribute("Carrying") then return end
	-- le joueur est assis : le tapis est juste sous ses fesses
	local height = root.Size.Y / 2 + 0.85
	local carpet = buildCarpet(root.CFrame * CFrame.new(0, -height, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = carpet.PrimaryPart
	weld.Parent = carpet.PrimaryPart
	carpet.Parent = character
end

function CarpetManager.giveCarpet(player)
	if player:GetAttribute("FlyingCarpet") ~= true then return end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	for _, container in ipairs({backpack, player.Character}) do
		if container and container:FindFirstChild(TOOL_NAME) then
			return
		end
	end
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = "Prends-le en main pour voler ! (Espace = monter, Ctrl = descendre)"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute("FlyingCarpet", true)
	tool.Parent = backpack
end

function CarpetManager.init(dependencies)
	deps = dependencies
	deps.Remotes.Carpet.OnServerEvent:Connect(onCarpet)
	local function watch(player)
		player:GetAttributeChangedSignal("FlyingCarpet"):Connect(function()
			CarpetManager.giveCarpet(player)
		end)
		-- s'il vole un brainrot, le tapis disparaît
		player:GetAttributeChangedSignal("Carrying"):Connect(function()
			if player:GetAttribute("Carrying") then
				removeCarpet(player.Character)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
end

CarpetManager.TOOL_NAME = TOOL_NAME
CarpetManager.SPEED = GameConfig.GAMEPASSES.FlyingCarpet.Speed

return CarpetManager
