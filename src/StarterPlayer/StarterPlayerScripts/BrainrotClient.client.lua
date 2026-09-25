-- Script client : interface, animation de minage, effets visuels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotModels = require(ReplicatedStorage:WaitForChild("BrainrotModels"))
local PICKAXES = GameConfig.PICKAXES
local CARDS = GameConfig.CARDS

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyPickaxe = RemoteEvents:WaitForChild("BuyPickaxe")
local Rebirth = RemoteEvents:WaitForChild("Rebirth")
local MineBlock = RemoteEvents:WaitForChild("MineBlock")
local Teleport = RemoteEvents:WaitForChild("Teleport")
local CardFound = RemoteEvents:WaitForChild("CardFound")
local BlockBroken = RemoteEvents:WaitForChild("BlockBroken")
local Notify = RemoteEvents:WaitForChild("Notify")

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local rebirths = leaderstats:WaitForChild("Rebirths")
local pickaxeTier = player:WaitForChild("PickaxeTier")
local cardsFolder = player:WaitForChild("Cards")

local blocksFolder = Workspace:WaitForChild("Mine"):WaitForChild("Blocks")

-- ============================================================
-- SONS (sons intégrés à Roblox, pas besoin d'ID)
-- ============================================================
local function makeSound(id, volume, speed)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.PlaybackSpeed = speed or 1
	sound.Parent = SoundService
	return sound
end

local swingSound = makeSound("rbxasset://sounds/swordslash.wav", 0.35, 1.4)
local cardSound = makeSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1)

-- ============================================================
-- INTERFACE
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function makeLabel(parent, text, height)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height or 22)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, text, color, height)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, height or 34)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.AutoButtonColor = true
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, Color3.new(0, 0, 0), 2)
	return button
end

-- ====== PANNEAU PRINCIPAL (haut gauche) ======
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 270, 0, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.Position = UDim2.new(0, 16, 0, 16)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
panel.BackgroundTransparency = 0.15
panel.Parent = screenGui
addCorner(panel, 12)
addStroke(panel, Color3.fromRGB(255, 200, 60), 2)

local panelLayout = Instance.new("UIListLayout")
panelLayout.Padding = UDim.new(0, 4)
panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
panelLayout.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 8)
panelPadding.PaddingBottom = UDim.new(0, 10)
panelPadding.PaddingLeft = UDim.new(0, 10)
panelPadding.PaddingRight = UDim.new(0, 10)
panelPadding.Parent = panel

local title = makeLabel(panel, "⛏️ Mine Brainrot", 30)
title.Font = Enum.Font.FredokaOne
title.TextColor3 = Color3.fromRGB(255, 210, 70)
local cashLabel = makeLabel(panel, "💰 Cash: 0")
local incomeLabel = makeLabel(panel, "📈 Revenu: 0 /s")
local rebirthsLabel = makeLabel(panel, "🔁 Rebirths: 0")
local pickaxeLabel = makeLabel(panel, "⛏️ Pioche en Bois")
local depthLabel = makeLabel(panel, "📍 Surface", 20)
local resetLabel = makeLabel(panel, "", 18)
resetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)

local buyButton = makeButton(panel, "Acheter pioche suivante", Color3.fromRGB(0, 150, 220))
local rebirthButton = makeButton(
	panel,
	"🔁 Rebirth (" .. GameConfig.REBIRTH_COST .. " Cash + 1 Sahur)",
	Color3.fromRGB(200, 60, 200)
)

local navRow = Instance.new("Frame")
navRow.Size = UDim2.new(1, 0, 0, 34)
navRow.BackgroundTransparency = 1
navRow.Parent = panel
local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.Padding = UDim.new(0, 6)
navLayout.Parent = navRow

local baseButton = makeButton(navRow, "🏠 Base", Color3.fromRGB(60, 170, 80))
baseButton.Size = UDim2.new(0.32, -4, 1, 0)
local mineButton = makeButton(navRow, "⛏️ Mine", Color3.fromRGB(150, 100, 50))
mineButton.Size = UDim2.new(0.32, -4, 1, 0)
local collectionButton = makeButton(navRow, "📦 Cartes", Color3.fromRGB(230, 140, 30))
collectionButton.Size = UDim2.new(0.36, -4, 1, 0)

buyButton.MouseButton1Click:Connect(function()
	BuyPickaxe:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	Rebirth:FireServer()
end)
baseButton.MouseButton1Click:Connect(function()
	Teleport:FireServer("base")
end)
mineButton.MouseButton1Click:Connect(function()
	Teleport:FireServer("mine")
end)

-- ====== COLLECTION DE CARTES (avec les brainrots en 3D) ======
local collection = Instance.new("Frame")
collection.Size = UDim2.new(0, 5 * 118 + 30, 0, 2 * 158 + 70)
collection.AnchorPoint = Vector2.new(0.5, 0.5)
collection.Position = UDim2.new(0.5, 0, 0.5, 0)
collection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
collection.BackgroundTransparency = 0.05
collection.Visible = false
collection.Parent = screenGui
addCorner(collection, 14)
addStroke(collection, Color3.fromRGB(255, 200, 60), 3)

local collectionTitle = makeLabel(collection, "📦 Ta collection de brainrots", 30)
collectionTitle.Position = UDim2.new(0, 14, 0, 10)
collectionTitle.Size = UDim2.new(1, -60, 0, 30)
collectionTitle.Font = Enum.Font.FredokaOne

local closeButton = makeButton(collection, "X", Color3.fromRGB(200, 50, 50))
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.Position = UDim2.new(1, -44, 0, 10)
closeButton.MouseButton1Click:Connect(function()
	collection.Visible = false
end)
collectionButton.MouseButton1Click:Connect(function()
	collection.Visible = not collection.Visible
end)

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, -20, 1, -60)
grid.Position = UDim2.new(0, 10, 0, 52)
grid.BackgroundTransparency = 1
grid.Parent = collection
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 110, 0, 150)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = grid

-- Carte avec le brainrot en 3D dedans
local function buildCard(card, parent)
	local rarity = GameConfig.RARITIES[card.Rarity]
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = card.Color
	frame.Parent = parent
	addCorner(frame, 10)
	addStroke(frame, rarity.Color, 3)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(90, 90, 90))
	gradient.Rotation = 90
	gradient.Parent = frame

	local viewHolder = Instance.new("Frame")
	viewHolder.Size = UDim2.new(1, 0, 0.62, 0)
	viewHolder.BackgroundTransparency = 1
	viewHolder.Parent = frame
	local _, model = BrainrotModels.viewport(card.Name, viewHolder)

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.92, 0, 0.2, 0)
	name.Position = UDim2.new(0.04, 0, 0.62, 0)
	name.BackgroundTransparency = 1
	name.Text = card.Name
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextWrapped = true
	name.Parent = frame

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(0.92, 0, 0.13, 0)
	info.Position = UDim2.new(0.04, 0, 0.83, 0)
	info.BackgroundTransparency = 1
	info.Text = card.Rarity .. " • " .. card.Income .. "$/s"
	info.TextColor3 = rarity.Color
	info.TextStrokeTransparency = 0
	info.Font = Enum.Font.GothamBold
	info.TextScaled = true
	info.Parent = frame

	return frame, model
end

local cardSlots = {}
for index, card in ipairs(CARDS) do
	local slot = buildCard(card, grid)
	slot.LayoutOrder = index

	local countBadge = Instance.new("TextLabel")
	countBadge.Size = UDim2.new(0, 38, 0, 22)
	countBadge.AnchorPoint = Vector2.new(1, 0)
	countBadge.Position = UDim2.new(1, -4, 0, 4)
	countBadge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	countBadge.TextColor3 = Color3.new(1, 1, 1)
	countBadge.Font = Enum.Font.GothamBold
	countBadge.TextScaled = true
	countBadge.Text = "x0"
	countBadge.ZIndex = 3
	countBadge.Parent = slot
	addCorner(countBadge, 6)

	-- Voile noir tant que la carte n'a pas été trouvée
	local lock = Instance.new("TextLabel")
	lock.Size = UDim2.new(1, 0, 1, 0)
	lock.BackgroundColor3 = Color3.new(0, 0, 0)
	lock.BackgroundTransparency = 0.15
	lock.Text = "❓"
	lock.TextScaled = true
	lock.ZIndex = 5
	lock.Parent = slot
	addCorner(lock, 10)

	cardSlots[card.Name] = {badge = countBadge, lock = lock}
end

-- ====== NOTIFICATIONS ======
local notifyLabel = Instance.new("TextLabel")
notifyLabel.Size = UDim2.new(0, 460, 0, 40)
notifyLabel.AnchorPoint = Vector2.new(0.5, 0)
notifyLabel.Position = UDim2.new(0.5, 0, 0, 16)
notifyLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
notifyLabel.BackgroundTransparency = 0.2
notifyLabel.TextColor3 = Color3.new(1, 1, 1)
notifyLabel.Font = Enum.Font.GothamBold
notifyLabel.TextScaled = true
notifyLabel.Visible = false
notifyLabel.Parent = screenGui
addCorner(notifyLabel, 10)

local notifyToken = 0
local function showNotification(text)
	notifyToken += 1
	local myToken = notifyToken
	notifyLabel.Text = text
	notifyLabel.Visible = true
	task.delay(2.5, function()
		if notifyToken == myToken then
			notifyLabel.Visible = false
		end
	end)
end
Notify.OnClientEvent:Connect(showNotification)

-- ====== POPUP "CARTE TROUVEE" (le brainrot tourne en 3D) ======
CardFound.OnClientEvent:Connect(function(cardName)
	local card = GameConfig.getCard(cardName)
	if not card then return end

	SoundService:PlayLocalSound(cardSound)

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.42, 0)
	holder.Size = UDim2.new(0, 0, 0, 0)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 10
	holder.Parent = screenGui

	local popup, model = buildCard(card, holder)
	popup.Size = UDim2.new(1, 0, 1, 0)

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1.6, 0, 0.18, 0)
	rarityLabel.AnchorPoint = Vector2.new(0.5, 1)
	rarityLabel.Position = UDim2.new(0.5, 0, 0, -6)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = "✨ " .. string.upper(card.Rarity) .. " ✨"
	rarityLabel.TextColor3 = GameConfig.RARITIES[card.Rarity].Color
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.Font = Enum.Font.FredokaOne
	rarityLabel.TextScaled = true
	rarityLabel.Parent = holder

	-- Rotation du modèle 3D
	local angle = 0
	local spin = RunService.RenderStepped:Connect(function(dt)
		angle += dt * 2.5
		model:PivotTo(CFrame.Angles(0, angle, 0))
	end)

	TweenService:Create(
		holder,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 170, 0, 230)}
	):Play()

	task.delay(2, function()
		local tweenOut = TweenService:Create(
			holder,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		tweenOut:Play()
		tweenOut.Completed:Wait()
		spin:Disconnect()
		holder:Destroy()
	end)
end)

-- ====== "+X $" QUI S'ENVOLE QUAND UN BLOC CASSE ======
BlockBroken.OnClientEvent:Connect(function(position, cashGain)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 90, 0, 36)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. cashGain .. " $"
	label.TextColor3 = Color3.fromRGB(120, 255, 120)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = billboard

	TweenService:Create(anchor, TweenInfo.new(1), {Position = position + Vector3.new(0, 4, 0)}):Play()
	TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	Debris:AddItem(anchor, 1.1)
end)

-- ============================================================
-- MINAGE : viser un bloc, animation de la pioche, particules
-- ============================================================

-- Contour du bloc visé (comme dans Minecraft)
local selection = Instance.new("SelectionBox")
selection.Color3 = Color3.new(0, 0, 0)
selection.LineThickness = 0.06
selection.SurfaceTransparency = 1
selection.Parent = player.PlayerGui

-- Barre de vie du bloc visé
local hpGui = Instance.new("BillboardGui")
hpGui.Size = UDim2.new(0, 110, 0, 30)
hpGui.StudsOffset = Vector3.new(0, 2.8, 0)
hpGui.AlwaysOnTop = true
hpGui.Enabled = false
hpGui.Parent = player.PlayerGui

local hpBack = Instance.new("Frame")
hpBack.Size = UDim2.new(1, 0, 0.4, 0)
hpBack.Position = UDim2.new(0, 0, 0.6, 0)
hpBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
hpBack.Parent = hpGui
addCorner(hpBack, 4)
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(90, 220, 90)
hpFill.Parent = hpBack
addCorner(hpFill, 4)
local hpName = Instance.new("TextLabel")
hpName.Size = UDim2.new(1, 0, 0.6, 0)
hpName.BackgroundTransparency = 1
hpName.TextColor3 = Color3.new(1, 1, 1)
hpName.TextStrokeTransparency = 0
hpName.Font = Enum.Font.GothamBold
hpName.TextScaled = true
hpName.Parent = hpGui

local targetBlock = nil
local mouseDown = false
local lastSwing = 0

local function getTool()
	local character = player.Character
	return character and character:FindFirstChild("Pioche")
end

local function getTarget()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = Workspace.CurrentCamera
	if not root or not camera then return nil end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {blocksFolder}
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 100, params)
	if not result then return nil end

	local block = result.Instance
	if block.Parent ~= blocksFolder then return nil end
	if (block.Position - root.Position).Magnitude > GameConfig.MINE.MineRange then return nil end
	return block
end

-- Trouve l'épaule droite pour faire l'animation de coup de pioche (R15 et R6)
local function getShoulder()
	local character = player.Character
	if not character then return nil end
	local upperArm = character:FindFirstChild("RightUpperArm")
	if upperArm and upperArm:FindFirstChild("RightShoulder") then
		return upperArm.RightShoulder, "R15"
	end
	local torso = character:FindFirstChild("Torso")
	if torso and torso:FindFirstChild("Right Shoulder") then
		return torso["Right Shoulder"], "R6"
	end
	return nil
end

local swinging = false
local function playSwing(cooldown)
	if swinging then return end
	local shoulder, rigType = getShoulder()
	if not shoulder then return end
	swinging = true

	local original = shoulder:GetAttribute("OriginalC0")
	if not original then
		original = shoulder.C0
		shoulder:SetAttribute("OriginalC0", original)
	end

	local function rotation(degrees)
		if rigType == "R15" then
			return original * CFrame.Angles(math.rad(degrees), 0, 0)
		end
		return original * CFrame.Angles(0, 0, math.rad(degrees))
	end

	-- Lève la pioche, frappe fort vers le bas, puis revient
	local total = math.clamp(cooldown * 0.9, 0.14, 0.3)
	local up = TweenService:Create(shoulder, TweenInfo.new(total * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = rotation(70)})
	local down = TweenService:Create(shoulder, TweenInfo.new(total * 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {C0 = rotation(-45)})
	local back = TweenService:Create(shoulder, TweenInfo.new(total * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = original})
	up:Play()
	up.Completed:Wait()
	down:Play()
	down.Completed:Wait()
	back:Play()
	back.Completed:Wait()
	swinging = false
end

-- Petits morceaux qui sautent du bloc quand on tape dessus
local function spawnChips(block)
	local camera = Workspace.CurrentCamera
	local hitPoint = block.Position
	if camera then
		local toCamera = (camera.CFrame.Position - block.Position).Unit
		hitPoint = block.Position + toCamera * (block.Size.X / 2)
	end
	for _ = 1, 4 do
		local chip = Instance.new("Part")
		chip.Size = Vector3.new(0.35, 0.35, 0.35)
		chip.Color = block.Color
		chip.Material = block.Material
		chip.CanCollide = false
		chip.CanQuery = false
		chip.CanTouch = false
		chip.Position = hitPoint
		chip.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), math.random(8, 18), math.random(-10, 10))
		chip.Parent = Workspace
		Debris:AddItem(chip, 0.6)
	end
end

-- Petite secousse de caméra
local function shakeCamera(strength)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	task.spawn(function()
		for _ = 1, 4 do
			humanoid.CameraOffset = Vector3.new(
				(math.random() - 0.5) * strength,
				(math.random() - 0.5) * strength,
				0
			)
			task.wait(0.03)
		end
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end)
end

local function tryMine()
	local tool = getTool()
	if not tool or not targetBlock then return end
	local pickaxeData = PICKAXES[pickaxeTier.Value] or PICKAXES[1]
	local now = os.clock()
	if now - lastSwing < pickaxeData.Cooldown then return end
	lastSwing = now

	local block = targetBlock
	task.spawn(playSwing, pickaxeData.Cooldown)
	SoundService:PlayLocalSound(swingSound)
	-- l'impact arrive au moment où la pioche frappe
	task.delay(math.clamp(pickaxeData.Cooldown * 0.9, 0.14, 0.3) * 0.55, function()
		if block.Parent then
			spawnChips(block)
			shakeCamera(0.15)
			MineBlock:FireServer(block)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		mouseDown = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		mouseDown = false
	end
end)

-- Chaque frame : on regarde quel bloc est visé, et on mine tant que le clic est maintenu
RunService.RenderStepped:Connect(function()
	local tool = getTool()
	targetBlock = tool and getTarget() or nil

	if targetBlock then
		selection.Adornee = targetBlock
		hpGui.Adornee = targetBlock
		hpGui.Enabled = true
		local hp = targetBlock:GetAttribute("HP") or 0
		local maxHp = targetBlock:GetAttribute("MaxHP") or 1
		hpFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
		local minTier = targetBlock:GetAttribute("MinTier") or 1
		if pickaxeTier.Value < minTier then
			hpName.Text = "🔒 " .. (targetBlock:GetAttribute("LayerName") or "")
			hpFill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		else
			hpName.Text = targetBlock:GetAttribute("LayerName") or ""
			hpFill.BackgroundColor3 = Color3.fromRGB(90, 220, 90)
		end
	else
		selection.Adornee = nil
		hpGui.Adornee = nil
		hpGui.Enabled = false
	end

	if mouseDown then
		tryMine()
	end
end)

-- ============================================================
-- LASERS DE MA BASE : je peux passer, les autres non
-- ============================================================
local plotsFolder = Workspace:WaitForChild("Plots")

local function updateLasers(plot)
	local lasers = plot:FindFirstChild("Lasers")
	if not lasers then return end
	local isMine = plot:GetAttribute("OwnerId") == player.UserId
	for _, laser in ipairs(lasers:GetChildren()) do
		-- Changer CanCollide côté client n'affecte que MON personnage
		laser.CanCollide = not isMine
		laser.Transparency = isMine and 0.5 or 0
	end
end

local function watchPlot(plot)
	updateLasers(plot)
	plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
		updateLasers(plot)
	end)
end

for _, plot in ipairs(plotsFolder:GetChildren()) do
	watchPlot(plot)
end
plotsFolder.ChildAdded:Connect(watchPlot)

-- ============================================================
-- MISE A JOUR DE L'UI
-- ============================================================
local function computeIncome()
	local income = 0
	for _, card in ipairs(CARDS) do
		local countValue = cardsFolder:FindFirstChild(card.Name)
		if countValue then
			income += countValue.Value * card.Income
		end
	end
	return math.floor(income * GameConfig.getIncomeMultiplier(rebirths.Value))
end

local function updateUI()
	cashLabel.Text = "💰 Cash: " .. cash.Value
	incomeLabel.Text = "📈 Revenu: " .. computeIncome() .. " /s"
	rebirthsLabel.Text = "🔁 Rebirths: " .. rebirths.Value
	pickaxeLabel.Text = "⛏️ " .. PICKAXES[pickaxeTier.Value].Name

	local nextPickaxe = PICKAXES[pickaxeTier.Value + 1]
	if not nextPickaxe then
		buyButton.Text = "Pioche maximale atteinte !"
		buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	elseif rebirths.Value < nextPickaxe.RequiredRebirths then
		buyButton.Text = nextPickaxe.Name .. " 🔒 (Rebirth " .. nextPickaxe.RequiredRebirths .. ")"
		buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	else
		buyButton.Text = "Acheter " .. nextPickaxe.Name .. " (" .. nextPickaxe.Cost .. " $)"
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
	end

	for name, slot in pairs(cardSlots) do
		local countValue = cardsFolder:FindFirstChild(name)
		local count = countValue and countValue.Value or 0
		slot.badge.Text = "x" .. count
		slot.lock.Visible = count == 0
	end
end

cash.Changed:Connect(updateUI)
rebirths.Changed:Connect(updateUI)
pickaxeTier.Changed:Connect(updateUI)
for _, countValue in ipairs(cardsFolder:GetChildren()) do
	countValue.Changed:Connect(updateUI)
end
updateUI()

-- Profondeur + minuteur de régénération de la mine
task.spawn(function()
	while true do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local depth = math.floor(-(root.Position.Y - 3) / GameConfig.MINE.BlockSize)
			if depth >= 1 then
				local layer = GameConfig.getLayer(depth + 1)
				depthLabel.Text = "📍 Profondeur: " .. depth .. " (" .. layer.Name .. ")"
			else
				depthLabel.Text = "📍 Surface"
			end
		end
		local resetAt = Workspace:GetAttribute("MineResetAt")
		if resetAt then
			local remaining = math.max(0, math.floor(resetAt - Workspace:GetServerTimeNow()))
			resetLabel.Text = string.format("🔄 Mine régénérée dans %d:%02d", remaining // 60, remaining % 60)
		end
		task.wait(0.25)
	end
end)
