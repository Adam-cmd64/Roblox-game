-- ModuleScript client : le HUD principal.
--   Haut gauche : menu (Base, Mine, Inventaire, Index, Rebirth, Échange, Boosters)
--   Haut centre : régénération de la mine (+ profondeur quand tu mines)
--   Haut droite : argent à collecter dans ta base + cartes dans l'inventaire
--   Bas : ton argent, tes revenus par seconde, tes rebirths, ta pioche
-- + notifications, popup "carte trouvée", "+$" quand tu collectes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local T = UIKit.Theme

local player = Players.LocalPlayer
local gui = UIKit.ScreenGui

local Hud = {}
Hud.buttons = {}

local function makeSound(id, volume, speed)
	return UIKit.new("Sound", {SoundId = id, Volume = volume, PlaybackSpeed = speed or 1}, SoundService)
end
local cardSound = makeSound("rbxasset://sounds/electronicpingshort.wav", 0.6)
local coinSound = makeSound("rbxasset://sounds/electronicpingshort.wav", 0.35, 1.6)

-- ============================================================
-- MENU HAUT GAUCHE
-- ============================================================
local menu = UIKit.new("Frame", {
	Position = UDim2.new(0, 14, 0, 14),
	Size = UDim2.new(0, 330, 0, 160),
	BackgroundTransparency = 1,
}, gui)
UIKit.new("UIGridLayout", {
	CellSize = UDim2.new(0, 70, 0, 70),
	CellPadding = UDim2.new(0, 10, 0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, menu)

local MENU = {
	{"base", "🏠", "Base", T.Green},
	{"mine", "⛏️", "Mine", Color3.fromRGB(200, 140, 70)},
	{"inventory", "🎒", "Inventaire", T.Blue},
	{"index", "📖", "Index", T.Gold},
	{"rebirth", "🔄", "Rebirth", T.Purple},
	{"trade", "🤝", "Échange", Color3.fromRGB(0, 200, 190)},
	{"boosters", "💎", "Boosters", Color3.fromRGB(255, 90, 160)},
}
for order, entry in ipairs(MENU) do
	local button = UIKit.iconButton(menu, entry[2], entry[3], entry[4])
	button.LayoutOrder = order
	Hud.buttons[entry[1]] = button
end

-- Badge rouge sur l'inventaire (cartes pas encore posées)
local inventoryBadge = UIKit.new("TextLabel", {
	Size = UDim2.new(0, 26, 0, 26),
	Position = UDim2.new(1, -16, 0, -8),
	BackgroundColor3 = T.Red,
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	Text = "0",
	Visible = false,
	ZIndex = 3,
}, Hud.buttons.inventory)
UIKit.corner(inventoryBadge, 13)

-- ============================================================
-- HAUT CENTRE : REGENERATION DE LA MINE
-- ============================================================
local timerPanel = UIKit.panel(gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.new(0, 300, 0, 96),
})
UIKit.label(timerPanel, "💎", {Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0, 10, 0, 12), Font = Enum.Font.GothamBold})
UIKit.label(timerPanel, "Mine en régénération", {Size = UDim2.new(1, -86, 0, 20), Position = UDim2.new(0, 72, 0, 8), TextColor3 = T.SubText})
local timerLabel = UIKit.label(timerPanel, "10:00", {Size = UDim2.new(1, -86, 0, 36), Position = UDim2.new(0, 72, 0, 28)})
local barBack = UIKit.new("Frame", {
	Size = UDim2.new(1, -24, 0, 10),
	Position = UDim2.new(0, 12, 0, 72),
	BackgroundColor3 = T.PanelDark,
	BorderSizePixel = 0,
}, timerPanel)
UIKit.corner(barBack, 5)
local barFill = UIKit.new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, barBack)
UIKit.corner(barFill, 5)
UIKit.gradient(barFill, Color3.fromRGB(90, 255, 120), Color3.fromRGB(30, 180, 80), 0)

local depthPill = UIKit.panel(gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 114),
	Size = UDim2.new(0, 260, 0, 34),
	Visible = false,
})
local depthLabel = UIKit.label(depthPill, "", {Size = UDim2.new(1, -16, 1, -10), Position = UDim2.new(0, 8, 0, 5)})

-- ============================================================
-- HAUT DROITE : A COLLECTER
-- ============================================================
local pendingPanel = UIKit.panel(gui, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.new(0, 200, 0, 110),
})
UIKit.label(pendingPanel, "🪙 À collecter", {Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 8), TextXAlignment = Enum.TextXAlignment.Left})
local pendingLabel = UIKit.label(pendingPanel, "$0", {
	Size = UDim2.new(1, -20, 0, 30),
	Position = UDim2.new(0, 10, 0, 36),
	TextColor3 = Color3.fromRGB(120, 255, 140),
	TextXAlignment = Enum.TextXAlignment.Right,
})
local cardsLabel = UIKit.label(pendingPanel, "🃏 × 0 à poser", {
	Size = UDim2.new(1, -20, 0, 22),
	Position = UDim2.new(0, 10, 0, 76),
	TextColor3 = T.SubText,
	TextXAlignment = Enum.TextXAlignment.Right,
})

-- ============================================================
-- BAS : STATISTIQUES
-- ============================================================
local statsBar = UIKit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -76),
	Size = UDim2.new(0, 860, 0, 64),
	BackgroundTransparency = 1,
}, gui)
UIKit.new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 12),
}, statsBar)

local function statCard(icon, title, accent, width)
	local card = UIKit.panel(statsBar, {Size = UDim2.new(0, width or 200, 1, 0)})
	local iconBubble = UIKit.new("Frame", {
		Size = UDim2.new(0, 44, 0, 44),
		Position = UDim2.new(0, 10, 0.5, -22),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	}, card)
	UIKit.corner(iconBubble, 22)
	UIKit.label(iconBubble, icon, {Size = UDim2.new(0.75, 0, 0.75, 0), Position = UDim2.new(0.125, 0, 0.125, 0), Font = Enum.Font.GothamBold})
	UIKit.new("Frame", {Size = UDim2.new(0, 3, 0, 40), Position = UDim2.new(0, 62, 0.5, -20), BackgroundColor3 = accent, BorderSizePixel = 0}, card)
	UIKit.label(card, title, {Size = UDim2.new(1, -80, 0, 18), Position = UDim2.new(0, 74, 0, 8), TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left})
	return UIKit.label(card, "0", {Size = UDim2.new(1, -80, 0, 28), Position = UDim2.new(0, 74, 0, 28), TextXAlignment = Enum.TextXAlignment.Left})
end

local cashValue = statCard("💵", "Mon argent", T.Green, 210)
local incomeValue = statCard("📈", "Revenus / sec", Color3.fromRGB(40, 190, 90), 200)
local rebirthValue = statCard("🔄", "Rebirths", T.Purple, 170)
local pickaxeValue = statCard("⛏️", "Pioche", Color3.fromRGB(200, 140, 70), 230)

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local toastHolder = UIKit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 158),
	Size = UDim2.new(0, 520, 0, 200),
	BackgroundTransparency = 1,
}, gui)
UIKit.new("UIListLayout", {
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)

local KIND_COLORS = {
	info = T.Blue,
	success = T.Green,
	error = T.Red,
	warning = T.Gold,
}
local toastCount = 0

function Hud.notify(text, kind)
	toastCount += 1
	local accent = KIND_COLORS[kind or "info"] or T.Blue
	local toast = UIKit.panel(toastHolder, {
		Size = UDim2.new(0, 480, 0, 40),
		LayoutOrder = -toastCount,
		BackgroundTransparency = 0.05,
	})
	UIKit.new("Frame", {Size = UDim2.new(0, 6, 1, -12), Position = UDim2.new(0, 8, 0, 6), BackgroundColor3 = accent, BorderSizePixel = 0}, toast)
	UIKit.label(toast, text, {Size = UDim2.new(1, -36, 1, -12), Position = UDim2.new(0, 22, 0, 6), Font = Enum.Font.GothamBold})
	if #toastHolder:GetChildren() > 5 then
		-- on garde les 4 dernières
		local toasts = {}
		for _, child in ipairs(toastHolder:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(toasts, child)
			end
		end
		table.sort(toasts, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
		for i = 5, #toasts do
			toasts[i]:Destroy()
		end
	end
	task.delay(3, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
			task.wait(0.3)
			toast:Destroy()
		end
	end)
end

-- ============================================================
-- POPUP "CARTE TROUVEE"
-- ============================================================
local popupQueue = {}
local popupBusy = false

local function showNextPopup()
	if popupBusy or #popupQueue == 0 then return end
	popupBusy = true
	local entry = table.remove(popupQueue, 1)
	local card = GameConfig.getCard(entry.name)
	local rarity = GameConfig.RARITIES[card.Rarity]

	SoundService:PlayLocalSound(cardSound)

	-- Flash de couleur pour les raretés hautes
	if rarity.Order >= 4 then
		local flash = UIKit.new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = rarity.Color,
			BackgroundTransparency = 0.35,
			ZIndex = 30,
		}, gui)
		TweenService:Create(flash, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
		Debris:AddItem(flash, 0.9)
	end

	local holder = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.47, 0),
		Size = UDim2.new(0, 220, 0, 308),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, gui)
	local scale = UIKit.new("UIScale", {Scale = 0}, holder)
	CardRenderer.create(entry.name, entry.mutation, holder)

	UIKit.label(holder, "✨ NOUVEAU BRAINROT ✨", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -8),
		Size = UDim2.new(1.6, 0, 0, 34),
		TextColor3 = rarity.Color,
	})
	UIKit.label(holder, "🎒 Ouvre ton inventaire pour le poser dans ta base", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 8),
		Size = UDim2.new(1.8, 0, 0, 22),
		TextColor3 = T.Text,
		Font = Enum.Font.GothamBold,
	})

	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	task.delay(rarity.Order >= 4 and 3 or 2.2, function()
		local out = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
		out:Play()
		out.Completed:Wait()
		holder:Destroy()
		popupBusy = false
		showNextPopup()
	end)
end

function Hud.showCardFound(cardName, mutation)
	table.insert(popupQueue, {name = cardName, mutation = mutation})
	showNextPopup()
end

-- "+$X" qui s'envole dans le monde
function Hud.floatingText(position, text, color)
	local anchor = UIKit.new("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
		Position = position,
	}, Workspace)
	local billboard = UIKit.new("BillboardGui", {Size = UDim2.new(0, 140, 0, 40), AlwaysOnTop = true}, anchor)
	local label = UIKit.label(billboard, text, {Size = UDim2.new(1, 0, 1, 0), TextColor3 = color, TextStrokeTransparency = 0})
	TweenService:Create(anchor, TweenInfo.new(1.1), {Position = position + Vector3.new(0, 5, 0)}):Play()
	TweenService:Create(label, TweenInfo.new(1.1), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	Debris:AddItem(anchor, 1.2)
end

function Hud.collected(amount, position)
	SoundService:PlayLocalSound(coinSound)
	Hud.floatingText(position + Vector3.new(0, 3, 0), "+$" .. GameConfig.format(amount), Color3.fromRGB(120, 255, 130))
end

-- ============================================================
-- MISE A JOUR
-- ============================================================
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local rebirths = leaderstats:WaitForChild("Rebirths")
local pickaxeTier = player:WaitForChild("PickaxeTier")
local brainrots = player:WaitForChild("Brainrots")

local function computeIncome()
	local total = 0
	for _, item in ipairs(brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) > 0 then
			total += GameConfig.getItemIncome(item.Value, item:GetAttribute("Mutation"))
		end
	end
	return total * GameConfig.getIncomeMultiplier(rebirths.Value)
end

function Hud.refresh()
	cashValue.Text = "$" .. GameConfig.format(cash.Value)
	incomeValue.Text = "+$" .. GameConfig.format(computeIncome())
	rebirthValue.Text = tostring(rebirths.Value)
	pickaxeValue.Text = string.gsub(GameConfig.PICKAXES[pickaxeTier.Value].Name, "Pioche en ", "")

	local inInventory = 0
	for _, item in ipairs(brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) == 0 then
			inInventory += 1
		end
	end
	inventoryBadge.Text = tostring(inInventory)
	inventoryBadge.Visible = inInventory > 0
	cardsLabel.Text = "🃏 × " .. inInventory .. " à poser"
end

-- Petit "pop" quand l'argent change
local cashScale = UIKit.new("UIScale", {Scale = 1}, cashValue)
cash.Changed:Connect(function()
	Hud.refresh()
	cashScale.Scale = 1.12
	TweenService:Create(cashScale, TweenInfo.new(0.2), {Scale = 1}):Play()
end)
rebirths.Changed:Connect(Hud.refresh)
pickaxeTier.Changed:Connect(Hud.refresh)
local function watch(item)
	item.AttributeChanged:Connect(Hud.refresh)
end
for _, item in ipairs(brainrots:GetChildren()) do
	watch(item)
end
brainrots.ChildAdded:Connect(function(item)
	watch(item)
	Hud.refresh()
end)
brainrots.ChildRemoved:Connect(Hud.refresh)
Hud.refresh()

-- Minuteur de la mine + profondeur + argent à collecter
local plotsFolder = Workspace:WaitForChild("Plots")
local function findMyPlot()
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("OwnerId") == player.UserId then
			return plot
		end
	end
	return nil
end

task.spawn(function()
	while true do
		local resetAt = Workspace:GetAttribute("MineResetAt")
		local resetStart = Workspace:GetAttribute("MineResetStart")
		if resetAt and resetStart then
			local remaining = math.max(0, resetAt - Workspace:GetServerTimeNow())
			timerLabel.Text = string.format("%d:%02d", remaining // 60, math.floor(remaining % 60))
			local ratio = 1 - remaining / math.max(1, resetAt - resetStart)
			barFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
		end

		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local depth = math.floor(-(root.Position.Y - 3) / GameConfig.MINE.BlockSize)
			if depth >= 1 then
				local layer = GameConfig.getLayer(depth + 1)
				depthLabel.Text = "📍 Profondeur " .. depth .. " • " .. layer.Name
				depthPill.Visible = true
			else
				depthPill.Visible = false
			end
		end

		local plot = findMyPlot()
		pendingLabel.Text = "$" .. GameConfig.format(plot and plot:GetAttribute("Pending") or 0)
		task.wait(0.25)
	end
end)

-- Adapte la taille du HUD aux petits écrans (téléphone)
local scaled = {menu, timerPanel, depthPill, pendingPanel, statsBar, toastHolder}
local scales = {}
for _, frame in ipairs(scaled) do
	table.insert(scales, UIKit.new("UIScale", {Scale = 1}, frame))
end
local function updateScale()
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local value = math.clamp(camera.ViewportSize.X / 1300, 0.55, 1)
	for _, uiScale in ipairs(scales) do
		uiScale.Scale = value
	end
end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

return Hud
