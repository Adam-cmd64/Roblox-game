-- ModuleScript : les CLASSEMENTS (2 grands panneaux dans le monde, voir GameConfig.LEADERBOARDS).
--   💰 LES PLUS RICHES   : top 10 de l'argent
--   ⚡ MEILLEURE BASE    : top 10 de l'argent gagné par seconde par la base
-- Les scores sont envoyés dans un OrderedDataStore : le top 10 regroupe TOUS les serveurs.
-- Si les DataStores ne marchent pas (Studio sans l'accès API), on classe les joueurs du serveur.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local LeaderboardManager = {}

local ROWS = 10
local GOLD = Color3.fromRGB(255, 200, 70)
local DEEP = Color3.fromRGB(30, 20, 55)
local RANK_COLORS = {Color3.fromRGB(255, 205, 60), Color3.fromRGB(205, 215, 230), Color3.fromRGB(215, 140, 80)}

local boards = {} -- boards[id] = {config, rows, stamp}
local names = {} -- cache userId -> nom

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

local function text(parent, value, size, position, color, font, alignment)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Text = value
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(15, 10, 30)
	label.Font = font or Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextXAlignment = alignment or Enum.TextXAlignment.Center
	label.Parent = parent
	return label
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function buildBoard(folder, config)
	local model = Instance.new("Model")
	model.Name = "Leaderboard_" .. config.Id
	local base = CFrame.lookAt(config.Position, Vector3.new(0, config.Position.Y, 0))
	local width, height = 14, 19
	local accent = config.Color

	-- socle + 2 piliers + fronton doré
	makePart(model, "Base", Vector3.new(width + 4, 1.2, 5), base * CFrame.new(0, 0.6, 0), DEEP, Enum.Material.Marble)
	for _, x in ipairs({-(width / 2 + 1), width / 2 + 1}) do
		makePart(model, "Pillar", Vector3.new(1.6, height + 3, 1.6), base * CFrame.new(x, 1.2 + (height + 3) / 2, 0), Color3.fromRGB(60, 45, 100), Enum.Material.Marble)
		local glow = makePart(model, "PillarGlow", Vector3.new(0.3, height + 3, 0.3), base * CFrame.new(x, 1.2 + (height + 3) / 2, -0.85), accent, Enum.Material.Neon)
		glow.CanCollide = false
		local orb = makePart(model, "PillarOrb", Vector3.new(1.8, 1.8, 1.8), base * CFrame.new(x, height + 5.2, 0), accent, Enum.Material.Neon)
		orb.Shape = Enum.PartType.Ball
		orb.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 16
		light.Brightness = 1.2
		light.Parent = orb
	end
	local panel = makePart(model, "Panel", Vector3.new(width, height, 0.6), base * CFrame.new(0, 2.2 + height / 2, 0), DEEP)
	for _, y in ipairs({2.2, 2.2 + height}) do
		makePart(model, "Frame", Vector3.new(width + 0.4, 0.5, 0.9), base * CFrame.new(0, y, 0), GOLD, Enum.Material.Metal).CanCollide = false
	end
	local crown = makePart(model, "Crown", Vector3.new(width + 3.6, 1.4, 1.2), base * CFrame.new(0, 3 + height, 0), GOLD, Enum.Material.Metal)
	crown.CanCollide = false
	local neon = makePart(model, "CrownGlow", Vector3.new(width + 3.8, 0.25, 0.25), base * CFrame.new(0, 3 + height, -0.65), accent, Enum.Material.Neon)
	neon.CanCollide = false

	-- l'écran
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Screen"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 36
	gui.LightInfluence = 0
	gui.Parent = panel
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(22, 14, 42)
	background.BorderSizePixel = 0
	background.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(60, 30, 110), Color3.fromRGB(15, 10, 30))
	gradient.Rotation = 90
	gradient.Parent = background
	local title = text(background, config.Title, UDim2.new(0.94, 0, 0.1, 0), UDim2.new(0.03, 0, 0.015, 0), accent, Enum.Font.LuckiestGuy)
	title.Name = "Title"
	local stamp = text(background, "Top 10 de tous les serveurs", UDim2.new(0.9, 0, 0.035, 0), UDim2.new(0.05, 0, 0.115, 0), Color3.fromRGB(190, 180, 220))

	local rows = {}
	for i = 1, ROWS do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.Size = UDim2.new(0.94, 0, 0.074, 0)
		row.Position = UDim2.new(0.03, 0, 0.16 + (i - 1) * 0.082, 0)
		row.BackgroundColor3 = i <= 3 and RANK_COLORS[i]:Lerp(Color3.fromRGB(40, 25, 70), 0.72) or Color3.fromRGB(45, 30, 80)
		row.BorderSizePixel = 0
		row.Parent = background
		corner(row, 14)
		local stroke = Instance.new("UIStroke")
		stroke.Color = i <= 3 and RANK_COLORS[i] or Color3.fromRGB(90, 70, 140)
		stroke.Thickness = i <= 3 and 3 or 1.5
		stroke.Parent = row
		local rank = text(row, "#" .. i, UDim2.new(0.12, 0, 0.8, 0), UDim2.new(0.01, 0, 0.1, 0), i <= 3 and RANK_COLORS[i] or Color3.new(1, 1, 1), Enum.Font.LuckiestGuy)
		rank.Name = "Rank"
		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.BackgroundColor3 = Color3.fromRGB(25, 18, 45)
		avatar.Size = UDim2.new(0, 58, 0, 58)
		avatar.AnchorPoint = Vector2.new(0, 0.5)
		avatar.Position = UDim2.new(0.14, 0, 0.5, 0)
		avatar.Image = ""
		avatar.Parent = row
		corner(avatar, 29)
		local nameLabel = text(row, "—", UDim2.new(0.43, 0, 0.62, 0), UDim2.new(0.27, 0, 0.19, 0), Color3.new(1, 1, 1), Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
		nameLabel.Name = "PlayerName"
		local valueLabel = text(row, "", UDim2.new(0.28, 0, 0.62, 0), UDim2.new(0.7, 0, 0.19, 0), Color3.fromRGB(120, 255, 140), Enum.Font.FredokaOne, Enum.TextXAlignment.Right)
		valueLabel.Name = "Value"
		rows[i] = {frame = row, avatar = avatar, name = nameLabel, value = valueLabel}
	end

	model.Parent = folder
	boards[config.Id] = {config = config, rows = rows, stamp = stamp}
end

-- ============================================================
-- SCORES
-- ============================================================
local function scoreOf(player, id)
	if id == "Cash" then
		local stats = player:FindFirstChild("leaderstats")
		local cash = stats and stats:FindFirstChild("Cash")
		return cash and cash.Value or 0
	end
	return player:GetAttribute("Income") or 0
end

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.DisplayName
		return names[userId]
	end
	local ok, result = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(result) == "string" then
		names[userId] = result
		return result
	end
	return "Joueur " .. userId
end

local function getStore(board)
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(board.config.Store)
	end)
	return ok and store or nil
end

-- Envoie les scores des joueurs du serveur, puis lit le top 10 de tous les serveurs
local function fetchTop(board)
	local id = board.config.Id
	local entries = {}
	local store = getStore(board)
	local fromStore = false
	if store then
		for _, player in ipairs(Players:GetPlayers()) do
			if player.UserId > 0 then
				local score = math.floor(scoreOf(player, id))
				pcall(function()
					store:SetAsync(tostring(player.UserId), score)
				end)
			end
		end
		local ok, page = pcall(function()
			return store:GetSortedAsync(false, ROWS):GetCurrentPage()
		end)
		if ok and type(page) == "table" then
			fromStore = true
			for _, entry in ipairs(page) do
				local userId = tonumber(entry.key)
				if userId then
					entries[userId] = entry.value
				end
			end
		end
	end
	-- les joueurs présents : leur score le plus récent
	for _, player in ipairs(Players:GetPlayers()) do
		entries[player.UserId] = math.floor(scoreOf(player, id))
	end
	local list = {}
	for userId, score in pairs(entries) do
		table.insert(list, {userId = userId, score = score})
	end
	table.sort(list, function(a, b)
		return a.score > b.score
	end)
	return list, fromStore
end

local function render(board, list, fromStore)
	for i, row in ipairs(board.rows) do
		local entry = list[i]
		if entry then
			row.name.Text = nameOf(entry.userId)
			row.value.Text = "$" .. GameConfig.format(entry.score) .. board.config.Unit
			row.avatar.Image = entry.userId > 0 and ("rbxthumb://type=AvatarHeadShot&id=" .. entry.userId .. "&w=150&h=150") or ""
		else
			row.name.Text = "—"
			row.value.Text = ""
			row.avatar.Image = ""
		end
	end
	board.stamp.Text = fromStore and "Top 10 de tous les serveurs  •  mis à jour chaque minute" or "Top 10 du serveur"
end

function LeaderboardManager.update()
	for _, config in ipairs(GameConfig.LEADERBOARDS) do
		local board = boards[config.Id]
		if board then
			local list, fromStore = fetchTop(board)
			render(board, list, fromStore)
		end
	end
end

function LeaderboardManager.init()
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	for _, config in ipairs(GameConfig.LEADERBOARDS) do
		buildBoard(folder, config)
	end
	folder.Parent = Workspace
	task.spawn(function()
		task.wait(3)
		while true do
			local ok, err = pcall(LeaderboardManager.update)
			if not ok then
				warn("[Classements] " .. tostring(err))
			end
			task.wait(GameConfig.LEADERBOARD_REFRESH)
		end
	end)
end

return LeaderboardManager
