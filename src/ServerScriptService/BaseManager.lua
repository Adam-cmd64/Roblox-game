-- ModuleScript : les bases des joueurs, façon "Steal a Brainrot".
-- Chaque joueur reçoit une base avec des piliers, un panneau à son nom, des lasers rouges à l'entrée
-- (seul le propriétaire peut passer) et des podiums où ses brainrots s'affichent en 3D.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotModels = require(ReplicatedStorage:WaitForChild("BrainrotModels"))

local BaseManager = {}

local W, D, H = 46, 38, 20 -- largeur, profondeur, hauteur d'une base

local CONCRETE = Color3.fromRGB(125, 125, 130)
local WALL = Color3.fromRGB(25, 70, 60)
local SIGN = Color3.fromRGB(215, 135, 60)
local LASER = Color3.fromRGB(255, 30, 30)

local plotsFolder
local plots = {} -- liste des bases {model, cframe, owner, podiums, sign}

local function makePart(parent, name, size, cframe, color, material, studs)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if studs then
		-- Look "Lego" comme dans Steal a Brainrot
		for _, face in ipairs({"Top", "Bottom", "Front", "Back", "Left", "Right"}) do
			part[face .. "Surface"] = Enum.SurfaceType.Studs
		end
	else
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
	end
	part.Parent = parent
	return part
end

local function buildPlot(index, cframe)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("OwnerId", 0)

	local function at(x, y, z)
		return cframe * CFrame.new(x, y, z)
	end

	-- Sol
	makePart(model, "Floor", Vector3.new(W, 1, D), at(0, 0.5, 0), CONCRETE, Enum.Material.Concrete, true)
	makePart(model, "InnerFloor", Vector3.new(W - 8, 0.2, D - 6), at(0, 1.1, 2), Color3.fromRGB(200, 200, 205), Enum.Material.SmoothPlastic)

	-- Murs
	makePart(model, "WallLeft", Vector3.new(1, H + 3, D - 4), at(-W / 2 + 2.5, (H + 3) / 2 + 1, 1), WALL)
	makePart(model, "WallRight", Vector3.new(1, H + 3, D - 4), at(W / 2 - 2.5, (H + 3) / 2 + 1, 1), WALL)
	makePart(model, "WallBack", Vector3.new(W - 4, H + 3, 1), at(0, (H + 3) / 2 + 1, D / 2 - 1.5), WALL)

	-- Gros piliers en béton aux 4 coins
	for _, x in ipairs({-W / 2 + 2, W / 2 - 2}) do
		for _, z in ipairs({-D / 2 + 2, D / 2 - 2}) do
			makePart(model, "Pillar", Vector3.new(4, H + 4, 4), at(x, (H + 4) / 2 + 1, z), CONCRETE, Enum.Material.Concrete, true)
		end
	end

	-- Toit
	makePart(model, "Roof", Vector3.new(W + 2, 2, D + 2), at(0, H + 5, 0), CONCRETE, Enum.Material.Concrete, true)

	-- Poutre au-dessus de l'entrée + panneau orange avec le nom du joueur
	makePart(model, "FrontBeam", Vector3.new(W - 4, 4, 3), at(0, H + 2, -D / 2 + 2), CONCRETE, Enum.Material.Concrete, true)
	local sign = makePart(model, "Sign", Vector3.new(W - 14, 5, 0.6), at(0, H - 1.5, -D / 2 + 0.3), SIGN, Enum.Material.SmoothPlastic)
	local border = makePart(model, "SignBorder", Vector3.new(W - 13, 6, 0.4), at(0, H - 1.5, -D / 2 + 0.7), Color3.fromRGB(150, 85, 35), Enum.Material.SmoothPlastic, true)
	border.CanCollide = false

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(640, 100)
	gui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "Base libre"
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.TextStrokeTransparency = 0
	signText.Font = Enum.Font.FredokaOne
	signText.TextScaled = true
	signText.Parent = gui

	-- Néons blancs au plafond
	for _, x in ipairs({-8, 8}) do
		local lamp = makePart(model, "CeilingLight", Vector3.new(3, 0.3, 1.5), at(x, H + 3.8, 0), Color3.new(1, 1, 1), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1.2
		light.Parent = lamp
	end
	local frame = makePart(model, "NeonFrame", Vector3.new(W - 10, 0.4, 0.4), at(0, H - 4.5, -D / 2 + 3.2), Color3.new(1, 1, 1), Enum.Material.Neon)
	frame.CanCollide = false

	-- Lasers rouges à l'entrée
	local laserFolder = Instance.new("Folder")
	laserFolder.Name = "Lasers"
	laserFolder.Parent = model
	makePart(model, "LaserBase", Vector3.new(W - 8, 0.6, 1.2), at(0, 1.3, -D / 2 + 2), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	makePart(model, "LaserTop", Vector3.new(W - 8, 0.6, 1.2), at(0, H - 4.9, -D / 2 + 2), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	local laserHeight = H - 6.5
	for x = -W / 2 + 5, W / 2 - 5, 2 do
		local laser = makePart(laserFolder, "Laser", Vector3.new(0.35, laserHeight, 0.35), at(x, 1.6 + laserHeight / 2, -D / 2 + 2), LASER, Enum.Material.Neon)
		laser.CastShadow = false
	end
	local laserLight = makePart(model, "LaserGlow", Vector3.new(1, 1, 1), at(0, 6, -D / 2 + 3), LASER)
	laserLight.Transparency = 1
	laserLight.CanCollide = false
	laserLight.CanQuery = false
	local glow = Instance.new("PointLight")
	glow.Color = LASER
	glow.Range = 16
	glow.Brightness = 2
	glow.Parent = laserLight

	-- Tapis vert devant l'entrée
	makePart(model, "WelcomeMat", Vector3.new(14, 0.3, 4), at(0, 0.15, -D / 2 - 2.5), Color3.fromRGB(60, 220, 90), Enum.Material.Neon)

	-- Podiums : un par brainrot (2 rangées de 5)
	local podiums = {}
	local cards = GameConfig.CARDS
	for index, card in ipairs(cards) do
		local row = index <= 5 and 0 or 1
		local col = (index - 1) % 5
		local x = -16 + col * 8
		local z = row == 0 and 13 or 3
		local podiumCFrame = at(x, 1.2, z)

		local podium = makePart(model, "Podium", Vector3.new(5.5, 1, 5.5), podiumCFrame * CFrame.new(0, 0.5, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
		local rim = makePart(model, "PodiumRim", Vector3.new(5.8, 0.25, 5.8), podiumCFrame * CFrame.new(0, 1.05, 0), GameConfig.RARITIES[card.Rarity].Color, Enum.Material.Neon)
		rim.CanCollide = false

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 160, 0, 60)
		billboard.StudsOffset = Vector3.new(0, 9, 0)
		billboard.MaxDistance = 70
		billboard.Parent = podium

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "???"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextStrokeTransparency = 0
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextScaled = true
		nameLabel.Parent = billboard

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
		infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = card.Rarity
		infoLabel.TextColor3 = GameConfig.RARITIES[card.Rarity].Color
		infoLabel.TextStrokeTransparency = 0
		infoLabel.Font = Enum.Font.GothamBold
		infoLabel.TextScaled = true
		infoLabel.Parent = billboard

		podiums[card.Name] = {
			cframe = podiumCFrame * CFrame.new(0, 1.2, 0),
			nameLabel = nameLabel,
			infoLabel = infoLabel,
			card = card,
			figure = nil,
		}
	end

	model.Parent = plotsFolder

	return {
		index = index,
		model = model,
		cframe = cframe,
		owner = nil,
		podiums = podiums,
		signText = signText,
	}
end

function BaseManager.init()
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace

	-- 2 rangées de bases qui se font face, avec la mine au milieu
	local count = GameConfig.BASE.PlotCount
	local perRow = math.ceil(count / 2)
	local spacing = 64
	for index = 1, count do
		local row = index <= perRow and -1 or 1
		local col = (index - 1) % perRow
		local x = (col - (perRow - 1) / 2) * spacing
		local z = row * 120
		local position = Vector3.new(x, 0, z)
		-- l'entrée (-Z local) regarde vers le centre de la map
		local cframe = CFrame.lookAt(position, Vector3.new(x, 0, 0))
		table.insert(plots, buildPlot(index, cframe))
	end
end

function BaseManager.getPlot(player)
	for _, plot in ipairs(plots) do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

function BaseManager.assign(player)
	for _, plot in ipairs(plots) do
		if not plot.owner then
			plot.owner = player
			plot.model:SetAttribute("OwnerId", player.UserId)
			plot.signText.Text = "Base de " .. player.DisplayName
			return plot
		end
	end
	return nil
end

function BaseManager.release(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return end
	plot.owner = nil
	plot.model:SetAttribute("OwnerId", 0)
	plot.signText.Text = "Base libre"
	for _, podium in pairs(plot.podiums) do
		if podium.figure then
			podium.figure:Destroy()
			podium.figure = nil
		end
		podium.nameLabel.Text = "???"
		podium.infoLabel.Text = podium.card.Rarity
	end
end

-- Point d'apparition du joueur dans sa base (juste derrière les lasers, tourné vers la mine)
function BaseManager.getSpawnCFrame(player)
	local plot = BaseManager.getPlot(player)
	if not plot then return nil end
	return plot.cframe * CFrame.new(0, 4, -D / 2 + 7)
end

-- Met à jour les podiums selon les cartes du joueur
function BaseManager.refresh(player)
	local plot = BaseManager.getPlot(player)
	local cardsFolder = player:FindFirstChild("Cards")
	if not plot or not cardsFolder then return end

	for name, podium in pairs(plot.podiums) do
		local countValue = cardsFolder:FindFirstChild(name)
		local count = countValue and countValue.Value or 0

		if count > 0 then
			if not podium.figure then
				local figure = BrainrotModels.build(name, 0.8)
				-- le brainrot regarde vers l'entrée de la base
				figure:PivotTo(podium.cframe)
				figure.Parent = plot.model
				podium.figure = figure
			end
			podium.nameLabel.Text = name .. "  x" .. count
			podium.infoLabel.Text = podium.card.Rarity .. " • " .. podium.card.Income * count .. " $/s"
		else
			if podium.figure then
				podium.figure:Destroy()
				podium.figure = nil
			end
			podium.nameLabel.Text = "???"
			podium.infoLabel.Text = podium.card.Rarity
		end
	end
end

return BaseManager
