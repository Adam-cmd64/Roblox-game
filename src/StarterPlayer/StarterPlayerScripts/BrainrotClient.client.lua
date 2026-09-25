local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PICKAXES = GameConfig.PICKAXES
local CARDS = GameConfig.CARDS

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyPickaxe = RemoteEvents:WaitForChild("BuyPickaxe")
local Rebirth = RemoteEvents:WaitForChild("Rebirth")
local CardFound = RemoteEvents:WaitForChild("CardFound")
local Notify = RemoteEvents:WaitForChild("Notify")

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local rebirths = leaderstats:WaitForChild("Rebirths")
local pickaxeTier = player:WaitForChild("PickaxeTier")
local cardsFolder = player:WaitForChild("Cards")

-- ====== ECRAN ======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
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

local function makeButton(parent, text, color)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 36)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = parent
	addCorner(button, 8)
	return button
end

-- ====== PANNEAU SHOP (haut gauche) ======
local shop = Instance.new("Frame")
shop.Size = UDim2.new(0, 280, 0, 250)
shop.Position = UDim2.new(0, 20, 0, 20)
shop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
shop.BackgroundTransparency = 0.15
shop.Parent = screenGui
addCorner(shop, 12)

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 4)
shopLayout.Parent = shop

local shopPadding = Instance.new("UIPadding")
shopPadding.PaddingTop = UDim.new(0, 8)
shopPadding.PaddingLeft = UDim.new(0, 10)
shopPadding.PaddingRight = UDim.new(0, 10)
shopPadding.Parent = shop

makeLabel(shop, "⛏️ Mine Brainrot", 28)
local cashLabel = makeLabel(shop, "Cash: 0")
local incomeLabel = makeLabel(shop, "Revenu: 0 /s")
local rebirthsLabel = makeLabel(shop, "Rebirths: 0")
local pickaxeLabel = makeLabel(shop, "Pioche: Pioche en Bois")

local buyButton = makeButton(shop, "Acheter pioche suivante", Color3.fromRGB(0, 150, 220))
local rebirthButton = makeButton(
	shop,
	"Rebirth (" .. GameConfig.REBIRTH_COST .. " Cash + 1 Sahur)",
	Color3.fromRGB(200, 60, 200)
)

buyButton.MouseButton1Click:Connect(function()
	BuyPickaxe:FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	Rebirth:FireServer()
end)

-- ====== BASE : COLLECTION DE CARTES (bas de l'écran) ======
local base = Instance.new("Frame")
base.Size = UDim2.new(0, 5 * 110 + 20, 0, 170)
base.AnchorPoint = Vector2.new(0.5, 1)
base.Position = UDim2.new(0.5, 0, 1, -20)
base.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
base.BackgroundTransparency = 0.15
base.Parent = screenGui
addCorner(base, 12)

local baseTitle = makeLabel(base, "🏠 Ta base — tes cartes rapportent du Cash chaque seconde", 20)
baseTitle.Position = UDim2.new(0, 10, 0, 6)
baseTitle.Size = UDim2.new(1, -20, 0, 20)

local cardRow = Instance.new("Frame")
cardRow.Size = UDim2.new(1, -20, 0, 130)
cardRow.Position = UDim2.new(0, 10, 0, 32)
cardRow.BackgroundTransparency = 1
cardRow.Parent = base

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.Padding = UDim.new(0, 10)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = cardRow

-- Construit le visuel d'une carte brainrot (réutilisé pour la popup "carte trouvée")
local function buildCardVisual(card, parent, size)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.BackgroundColor3 = card.Color
	frame.Parent = parent
	addCorner(frame, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 120))
	gradient.Rotation = 90
	gradient.Parent = frame

	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(1, 0, 0.45, 0)
	emoji.Position = UDim2.new(0, 0, 0.05, 0)
	emoji.BackgroundTransparency = 1
	emoji.Text = card.Emoji
	emoji.TextScaled = true
	emoji.Parent = frame

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.9, 0, 0.22, 0)
	name.Position = UDim2.new(0.05, 0, 0.5, 0)
	name.BackgroundTransparency = 1
	name.Text = card.Name
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	name.TextWrapped = true
	name.Parent = frame

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(0.9, 0, 0.14, 0)
	info.Position = UDim2.new(0.05, 0, 0.74, 0)
	info.BackgroundTransparency = 1
	info.Text = card.Rarity .. " • " .. card.Income .. "$/s"
	info.TextColor3 = Color3.new(1, 1, 1)
	info.TextStrokeTransparency = 0.3
	info.Font = Enum.Font.GothamBold
	info.TextScaled = true
	info.Parent = frame

	return frame
end

local cardSlots = {}
for index, card in ipairs(CARDS) do
	local slot = buildCardVisual(card, cardRow, UDim2.new(0, 100, 0, 130))
	slot.LayoutOrder = index

	local countBadge = Instance.new("TextLabel")
	countBadge.Size = UDim2.new(0, 36, 0, 22)
	countBadge.AnchorPoint = Vector2.new(1, 0)
	countBadge.Position = UDim2.new(1, -4, 0, 4)
	countBadge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	countBadge.TextColor3 = Color3.new(1, 1, 1)
	countBadge.Font = Enum.Font.GothamBold
	countBadge.TextScaled = true
	countBadge.Text = "x0"
	countBadge.Parent = slot
	addCorner(countBadge, 6)

	-- Voile sombre tant que la carte n'a pas été trouvée
	local lock = Instance.new("TextLabel")
	lock.Size = UDim2.new(1, 0, 1, 0)
	lock.BackgroundColor3 = Color3.new(0, 0, 0)
	lock.BackgroundTransparency = 0.25
	lock.Text = "❓"
	lock.TextScaled = true
	lock.ZIndex = 5
	lock.Parent = slot
	addCorner(lock, 10)

	cardSlots[card.Name] = {badge = countBadge, lock = lock}
end

-- ====== NOTIFICATIONS ======
local notifyLabel = Instance.new("TextLabel")
notifyLabel.Size = UDim2.new(0, 420, 0, 40)
notifyLabel.AnchorPoint = Vector2.new(0.5, 0)
notifyLabel.Position = UDim2.new(0.5, 0, 0, 20)
notifyLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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

-- ====== POPUP "CARTE TROUVEE" ======
CardFound.OnClientEvent:Connect(function(cardName)
	local card = GameConfig.getCard(cardName)
	if not card then return end

	local popup = buildCardVisual(card, screenGui, UDim2.new(0, 0, 0, 0))
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.new(0.5, 0, 0.45, 0)
	popup.ZIndex = 10

	local tweenIn = TweenService:Create(
		popup,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 170, 0, 220)}
	)
	tweenIn:Play()
	showNotification("Nouvelle carte : " .. card.Name .. " (" .. card.Rarity .. ") !")

	task.delay(1.6, function()
		local tweenOut = TweenService:Create(
			popup,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		tweenOut:Play()
		tweenOut.Completed:Wait()
		popup:Destroy()
	end)
end)

-- ====== MISE A JOUR DE L'UI ======
local function computeIncome()
	local income = 0
	for _, card in ipairs(CARDS) do
		local countValue = cardsFolder:FindFirstChild(card.Name)
		if countValue then
			income += countValue.Value * card.Income
		end
	end
	return math.floor(income * (1 + rebirths.Value * GameConfig.REBIRTH_INCOME_MULT_BONUS))
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
		buyButton.Text = nextPickaxe.Name .. " 🔒 (Rebirth " .. nextPickaxe.RequiredRebirths .. " requis)"
		buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	else
		buyButton.Text = "Acheter " .. nextPickaxe.Name .. " (" .. nextPickaxe.Cost .. " Cash)"
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
