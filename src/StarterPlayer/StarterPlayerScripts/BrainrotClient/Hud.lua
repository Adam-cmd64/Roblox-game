-- ModuleScript client : le HUD.
--   À gauche : les gros boutons du menu (Sac, Index, Rebirth, Échange, Shop, Cadeaux)
--   En haut au milieu : [MINE] minuteur de la mine [BASE] (+ la profondeur quand tu mines)
--   En bas à gauche : ton argent
-- Les boutons sont dans UIKit.MenuGui (au-dessus des fenêtres) : on passe d'un menu à l'autre sans fermer.
-- + messages, popup "nouveau brainrot", "+$" quand tu collectes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local Effects = require(script.Parent.Effects)
local T = UIKit.Theme

local player = Players.LocalPlayer
local gui = UIKit.ScreenGui

-- Petit numéro de version en bas à droite
local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "Version"
versionLabel.AnchorPoint = Vector2.new(1, 1)
versionLabel.Position = UDim2.new(1, -8, 1, -4)
versionLabel.Size = UDim2.new(0, 220, 0, 16)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = GameConfig.VERSION or ""
versionLabel.TextColor3 = Color3.new(1, 1, 1)
versionLabel.TextTransparency = 0.4
versionLabel.TextStrokeTransparency = 0.7
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextSize = 12
versionLabel.Parent = gui

local Hud = {}
Hud.buttons = {}

-- ============================================================
-- MENU (à gauche, au milieu de l'écran)
-- ============================================================
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0, 0.5)
menu.Size = UDim2.new(0, 170, 0, 268) -- 2 colonnes x 3 lignes
menu.Position = UDim2.new(0, 14, 0.5, 0)
menu.BackgroundTransparency = 1
menu.Parent = UIKit.MenuGui
UIKit.hudScale(menu)
UIKit.sideMenu = menu
local menuGrid = Instance.new("UIGridLayout")
menuGrid.CellSize = UDim2.new(0, 74, 0, 74)
menuGrid.CellPadding = UDim2.new(0, 14, 0, 20)
menuGrid.SortOrder = Enum.SortOrder.LayoutOrder
menuGrid.Parent = menu

local MENU = {
	{"inventory", "🎒", "Sac", T.Blue},
	{"index", "📖", "Index", T.Gold},
	{"rebirth", "🔄", "Rebirth", T.Purple},
	{"trade", "🤝", "Échange", T.Teal},
	{"boosters", "💎", "Shop", T.Pink},
	{"daily", "🎁", "Cadeaux", T.Orange},
}
for order, entry in ipairs(MENU) do
	local button = UIKit.menuButton(menu, entry[2], entry[3], entry[4])
	button.LayoutOrder = order
	Hud.buttons[entry[1]] = button
end

-- Pastille rouge sur le sac (cartes pas encore posées)
local bagBadge = Instance.new("TextLabel")
bagBadge.AnchorPoint = Vector2.new(0.5, 0.5)
bagBadge.Position = UDim2.new(1, -4, 0, 4)
bagBadge.Size = UDim2.new(0, 28, 0, 28)
bagBadge.BackgroundColor3 = T.Red
bagBadge.TextColor3 = Color3.new(1, 1, 1)
bagBadge.Font = UIKit.TitleFont
bagBadge.TextScaled = true
bagBadge.Text = "0"
bagBadge.Visible = false
bagBadge.ZIndex = 5
bagBadge.Parent = Hud.buttons.inventory
UIKit.corner(bagBadge, 14)
UIKit.outline(bagBadge, 2.5)

-- ============================================================
-- ARGENT (en bas à gauche)
-- ============================================================
local moneyFrame = Instance.new("Frame")
moneyFrame.AnchorPoint = Vector2.new(0, 1)
moneyFrame.Position = UDim2.new(0, 18, 1, -18)
moneyFrame.Size = UDim2.new(0, 360, 0, 86)
moneyFrame.BackgroundTransparency = 1
moneyFrame.Parent = gui
UIKit.hudScale(moneyFrame)

-- TÉLÉPHONE : le joystick est en bas à gauche et le bouton de saut en bas à droite.
-- On met l'argent en haut à gauche et le menu sur le côté droit pour que le pouce ne les cache pas.
local UserInputService = game:GetService("UserInputService")
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	moneyFrame.AnchorPoint = Vector2.new(0, 0)
	moneyFrame.Position = UDim2.new(0, 16, 0, 8)
	menu.AnchorPoint = Vector2.new(1, 0.5)
	menu.Position = UDim2.new(1, -12, 0.53, 0)
end

-- panneau en verre sombre avec un contour doré qui tourne
local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.Size = UDim2.new(1, 0, 0, 62)
moneyPanel.BackgroundColor3 = Color3.new(1, 1, 1)
moneyPanel.BackgroundTransparency = 0.12
moneyPanel.BorderSizePixel = 0
moneyPanel.Parent = moneyFrame
UIKit.corner(moneyPanel, 20)
UIKit.gradient(moneyPanel, Color3.fromRGB(34, 40, 72), Color3.fromRGB(14, 14, 30), 90)
local moneyStroke = UIKit.outline(moneyPanel, 3, Color3.new(1, 1, 1))
local moneyStrokeGradient = Instance.new("UIGradient")
moneyStrokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 255, 140)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 80)),
})
moneyStrokeGradient.Parent = moneyStroke
game:GetService("CollectionService"):AddTag(moneyStrokeGradient, "SpinGradient")
local moneyShine = Instance.new("Frame")
moneyShine.Name = "Shine"
moneyShine.Size = UDim2.new(1, 0, 1, 0)
moneyShine.BackgroundColor3 = Color3.new(1, 1, 1)
moneyShine.BackgroundTransparency = 0.82
moneyShine.BorderSizePixel = 0
moneyShine.Parent = moneyPanel
UIKit.corner(moneyShine, 20)
local moneyShineGradient = Instance.new("UIGradient")
moneyShineGradient.Rotation = 20
moneyShineGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.45, 1),
	NumberSequenceKeypoint.new(0.5, 0.3),
	NumberSequenceKeypoint.new(0.55, 1),
	NumberSequenceKeypoint.new(1, 1),
})
moneyShineGradient.Parent = moneyShine
game:GetService("CollectionService"):AddTag(moneyShineGradient, "HoloShine")

local coinIcon = UIKit.label(moneyPanel, "💰", {
	Name = "CoinIcon",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 8, 0.5, 0),
	Size = UDim2.new(0, 50, 0, 50),
	Font = Enum.Font.GothamBold,
})
local coinScale = Instance.new("UIScale")
coinScale.Parent = coinIcon

local moneyLabel = UIKit.label(moneyPanel, "$0", {
	Name = "Money",
	Position = UDim2.new(0, 62, 0, 4),
	Size = UDim2.new(1, -72, 0, 38),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(110, 255, 125),
	TextXAlignment = Enum.TextXAlignment.Left,
})
moneyLabel:FindFirstChildOfClass("UIStroke").Thickness = 3
local moneyGradient = Instance.new("UIGradient")
moneyGradient.Color = ColorSequence.new(Color3.fromRGB(190, 255, 170), Color3.fromRGB(60, 220, 90))
moneyGradient.Rotation = 90
moneyGradient.Parent = moneyLabel
local moneyScale = Instance.new("UIScale")
moneyScale.Parent = moneyLabel

-- revenu par seconde de la base (sous l'argent)
local incomeLabel = UIKit.label(moneyPanel, "", {
	Name = "IncomeRate",
	Position = UDim2.new(0, 64, 0, 40),
	Size = UDim2.new(1, -74, 0, 18),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(255, 225, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
})

local rebirthLabel = UIKit.label(moneyFrame, "Rebirth 0", {
	Position = UDim2.new(0, 6, 0, 64),
	Size = UDim2.new(0.5, 0, 0, 22),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(215, 165, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- Potion de chance active
local potionLabel = UIKit.label(moneyFrame, "", {
	Position = UDim2.new(0, 2, 0, -30),
	Size = UDim2.new(1, 0, 0, 26),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(110, 255, 170),
	TextXAlignment = Enum.TextXAlignment.Left,
	Visible = false,
})

-- ============================================================
-- MINUTEUR DE LA MINE (en haut)
-- ============================================================
-- La barre du haut : [⛏️ MINE]  minuteur  [🏠 BASE]
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 6)
topBar.Size = UDim2.new(0, 410, 0, 84)
topBar.BackgroundTransparency = 1
topBar.Parent = UIKit.MenuGui
UIKit.hudScale(topBar)

local timerFrame = Instance.new("Frame")
timerFrame.Name = "MineTimer"
timerFrame.AnchorPoint = Vector2.new(0.5, 0)
timerFrame.Position = UDim2.new(0.5, 0, 0, 4)
timerFrame.Size = UDim2.new(0, 230, 0, 58)
timerFrame.BackgroundTransparency = 1
timerFrame.Parent = topBar

for _, entry in ipairs({
	{"mine", "⛏️", "Mine", T.Orange, Vector2.new(0, 0), UDim2.new(0, 0, 0, 0)},
	{"base", "🏠", "Base", T.Green, Vector2.new(1, 0), UDim2.new(1, 0, 0, 0)},
}) do
	local button = UIKit.menuButton(topBar, entry[2], entry[3], entry[4])
	button.Name = entry[3] .. "Button"
	button.AnchorPoint = entry[5]
	button.Position = entry[6]
	button.Size = UDim2.new(0, 70, 0, 70)
	Hud.buttons[entry[1]] = button
end

-- fond en verre sombre derrière le minuteur
local timerGlass = Instance.new("Frame")
timerGlass.Name = "TimerGlass"
timerGlass.AnchorPoint = Vector2.new(0.5, 0)
timerGlass.Position = UDim2.new(0.5, 0, 0, -2)
timerGlass.Size = UDim2.new(1, 8, 1, 4)
timerGlass.BackgroundColor3 = Color3.new(1, 1, 1)
timerGlass.BackgroundTransparency = 0.18
timerGlass.BorderSizePixel = 0
timerGlass.ZIndex = 0
timerGlass.Parent = timerFrame
UIKit.corner(timerGlass, 18)
UIKit.gradient(timerGlass, Color3.fromRGB(40, 36, 80), Color3.fromRGB(14, 12, 32), 90)
local timerStroke = UIKit.outline(timerGlass, 2.5, Color3.new(1, 1, 1))
local timerStrokeGradient = Instance.new("UIGradient")
timerStrokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 235, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 110, 230)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 235, 255)),
})
timerStrokeGradient.Parent = timerStroke
game:GetService("CollectionService"):AddTag(timerStrokeGradient, "SpinGradient")

local timerLabel = UIKit.label(timerFrame, "MINE 10:00", {
	Size = UDim2.new(1, 0, 0, 34),
	Font = UIKit.TitleFont,
})
local barBack = Instance.new("Frame")
barBack.Position = UDim2.new(0.1, 0, 0, 40)
barBack.Size = UDim2.new(0.8, 0, 0, 12)
barBack.BackgroundColor3 = T.Dark
barBack.BorderSizePixel = 0
barBack.Parent = timerFrame
UIKit.corner(barBack, 6)
UIKit.outline(barBack, 2.5)
local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.new(1, 1, 1)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
UIKit.corner(barFill, 6)
UIKit.gradient(barFill, Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 140, 30), 90)

-- le MONDE où on est (sous le minuteur)
local worldChip = Instance.new("Frame")
worldChip.Name = "WorldChip"
worldChip.AnchorPoint = Vector2.new(0.5, 0)
worldChip.Position = UDim2.new(0.5, 0, 0, 62)
worldChip.Size = UDim2.new(0, 210, 0, 24)
worldChip.BackgroundColor3 = Color3.new(1, 1, 1)
worldChip.BorderSizePixel = 0
worldChip.Parent = topBar
UIKit.corner(worldChip, 12)
UIKit.outline(worldChip, 2)
local worldChipGradient = Instance.new("UIGradient")
worldChipGradient.Parent = worldChip
local worldLabel = UIKit.label(worldChip, "", {
	Name = "WorldName",
	Position = UDim2.new(0.05, 0, 0.1, 0),
	Size = UDim2.new(0.9, 0, 0.8, 0),
	Font = UIKit.TitleFont,
})
local WORLD_STYLES = {
	{"🌍 MONDE BRAINROT", Color3.fromRGB(90, 200, 90), Color3.fromRGB(40, 120, 60)},
	{"🌌 NUIT DE CRISTAL", Color3.fromRGB(70, 200, 255), Color3.fromRGB(130, 70, 240)},
}
local shownWorld = 0
local function showWorld(world)
	if world == shownWorld then return end
	shownWorld = world
	local style = WORLD_STYLES[world] or WORLD_STYLES[1]
	worldLabel.Text = style[1]
	worldChipGradient.Color = ColorSequence.new(style[2], style[3])
	local chipScale = worldChip:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	chipScale.Parent = worldChip
	chipScale.Scale = 1.3
	TweenService:Create(chipScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Scale = 1}):Play()
end
showWorld(1)

local depthLabel = UIKit.label(topBar, "", { -- sous le minuteur (il rétrécit avec la barre du haut)
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 92),
	Size = UDim2.new(0, 320, 0, 26),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(255, 210, 120),
	Visible = false,
})

-- ============================================================
-- MESSAGES (texte qui apparaît au centre, style jeu)
-- ============================================================
local toastHolder = Instance.new("Frame")
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0.2, 0)
toastHolder.Size = UDim2.new(0, 640, 0, 200)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui
UIKit.phoneFit(toastHolder, 660, 200, 0.98)
local toastLayout = Instance.new("UIListLayout")
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 2)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local KIND_COLORS = {
	info = Color3.fromRGB(255, 255, 255),
	success = Color3.fromRGB(110, 255, 120),
	error = Color3.fromRGB(255, 90, 90),
	warning = Color3.fromRGB(255, 210, 60),
}
local toastCount = 0

-- chaque message est une pastille sombre avec une bordure de la couleur du message
local KIND_BG = {
	info = Color3.fromRGB(40, 44, 80),
	success = Color3.fromRGB(20, 70, 40),
	error = Color3.fromRGB(90, 20, 30),
	warning = Color3.fromRGB(90, 65, 10),
}
function Hud.notify(text, kind)
	toastCount += 1
	kind = KIND_COLORS[kind or "info"] and kind or "info"
	local pill = Instance.new("Frame")
	pill.Name = "Toast"
	pill.Size = UDim2.new(1, 0, 0, 38)
	pill.BackgroundTransparency = 1
	pill.LayoutOrder = -toastCount
	pill.Parent = toastHolder
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.AnchorPoint = Vector2.new(0.5, 0.5)
	back.Position = UDim2.new(0.5, 0, 0.5, 0)
	back.Size = UDim2.new(0, math.clamp(utf8.len(text) or #text, 8, 60) * 11 + 40, 1, -4)
	back.BackgroundColor3 = KIND_BG[kind]
	back.BackgroundTransparency = 0.2
	back.BorderSizePixel = 0
	back.Parent = pill
	UIKit.corner(back, 16)
	local border = UIKit.outline(back, 2.5, KIND_COLORS[kind])
	local toast = UIKit.label(pill, text, {
		Name = "ToastText",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -20, 0, 28),
		Font = UIKit.TitleFont,
		TextColor3 = KIND_COLORS[kind],
		ZIndex = 2,
	})
	local stroke = toast:FindFirstChildOfClass("UIStroke")
	stroke.Thickness = 2.5
	local scale = Instance.new("UIScale")
	scale.Scale = 0.5
	scale.Parent = pill
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()

	-- On garde les 4 derniers messages
	local toasts = {}
	for _, child in ipairs(toastHolder:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Toast" then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	for i = 5, #toasts do
		toasts[i]:Destroy()
	end

	task.delay(2.6, function()
		if pill.Parent then
			TweenService:Create(toast, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 1}):Play()
			TweenService:Create(back, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
			TweenService:Create(border, TweenInfo.new(0.35), {Transparency = 1}):Play()
			task.wait(0.35)
			pill:Destroy()
		end
	end)
end

-- ============================================================
-- POPUP "NOUVEAU BRAINROT"
-- ============================================================
local popupQueue = {}
local popupBusy = false

local function showNextPopup()
	if popupBusy or #popupQueue == 0 then return end
	popupBusy = true
	local entry = table.remove(popupQueue, 1)
	local card = GameConfig.getCard(entry.name)
	local rarity = GameConfig.RARITIES[card.Rarity]

	Sounds.play(rarity.Order >= 4 and "RareCard" or "Card")

	if rarity.Order >= 4 then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = rarity.Color
		flash.BackgroundTransparency = 0.35
		flash.ZIndex = 30
		flash.Parent = gui
		TweenService:Create(flash, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
		Debris:AddItem(flash, 0.9)
	end

	-- rayons de lumière qui tournent derrière la carte
	local burst = Instance.new("Frame")
	burst.Name = "CardBurst"
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.new(0.5, 0, 0.48, 0)
	burst.Size = UDim2.new(0, 560, 0, 560)
	burst.BackgroundTransparency = 1
	burst.ZIndex = 30
	burst.Parent = gui
	for i = 1, 12 do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.new(0.5, 0, 0.5, 0)
		ray.Size = UDim2.new(0.07, 0, 1, 0)
		ray.Rotation = i * 15
		ray.BackgroundColor3 = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.4)
		ray.BackgroundTransparency = 0.55
		ray.BorderSizePixel = 0
		ray.ZIndex = 30
		ray.Parent = burst
		local fade = Instance.new("UIGradient")
		fade.Rotation = 90
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		fade.Parent = ray
	end
	game:GetService("CollectionService"):AddTag(burst, "RaySpin")
	local burstScale = Instance.new("UIScale")
	burstScale.Scale = 0
	burstScale.Parent = burst
	TweenService:Create(burstScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = UIKit.fitFactor(620, 620, 0.9)}):Play()

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.48, 0)
	holder.Size = UDim2.new(0, 210, 0, 336)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 31
	holder.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = holder
	CardRenderer.create(entry.name, entry.mutation, holder, entry.serial)

	UIKit.label(holder, card.Rarity, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.new(1.8, 0, 0, 44),
		Font = UIKit.TitleFont,
		TextColor3 = rarity.Color,
	}):FindFirstChildOfClass("UIStroke").Thickness = 3

	-- bandeau "NOUVEAU !" sous la carte
	local banner = UIKit.label(holder, "✨ NOUVEAU BRAINROT ! ✨", {
		Name = "NewBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 8),
		Size = UDim2.new(1.6, 0, 0, 34),
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(255, 230, 120),
	})
	banner.Visible = not entry.known

	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = UIKit.fitFactor(420, 440, 0.8)}):Play()
	task.delay(rarity.Order >= 4 and 2.6 or 1.8, function()
		local out = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
		out:Play()
		TweenService:Create(burstScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0}):Play()
		out.Completed:Wait()
		holder:Destroy()
		burst:Destroy()
		popupBusy = false
		showNextPopup()
	end)
end

-- ALERTE ROUGE (quelqu'un te vole un brainrot) : bandeau qui clignote + bords rouges + alarme, 2 secondes
function Hud.alarm(text)
	Sounds.play("Alarm")
	local banner = Instance.new("Frame")
	banner.Name = "AlarmBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 90)
	banner.Size = UDim2.new(0, 620, 0, 74)
	banner.BackgroundColor3 = Color3.fromRGB(200, 20, 30)
	banner.ZIndex = 55
	banner.Parent = gui
	UIKit.phoneFit(banner, 640, 74, 0.96)
	UIKit.corner(banner, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 4
	stroke.Parent = banner
	UIKit.label(banner, "🚨 " .. text .. " 🚨", {Size = UDim2.new(0.94, 0, 0.8, 0), Position = UDim2.new(0.03, 0, 0.1, 0), Font = UIKit.TitleFont, ZIndex = 56})
	local edges = Instance.new("Frame")
	edges.Size = UDim2.new(1, 0, 1, 0)
	edges.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	edges.BackgroundTransparency = 1
	edges.ZIndex = 54
	edges.Parent = gui
	local vignette = Instance.new("UIStroke")
	vignette.Color = Color3.fromRGB(255, 30, 30)
	vignette.Thickness = 24
	vignette.Parent = edges
	task.spawn(function()
		for i = 1, 8 do
			local on = i % 2 == 1
			banner.BackgroundColor3 = on and Color3.fromRGB(230, 25, 35) or Color3.fromRGB(120, 10, 20)
			vignette.Transparency = on and 0.2 or 0.7
			task.wait(0.25)
		end
		banner:Destroy()
		edges:Destroy()
	end)
end

function Hud.showCardFound(cardName, mutation, serial)
	-- (le serveur a déjà ajouté la carte à l'Index : "NOUVEAU" si c'est le premier exemplaire)
	local owned = 0
	for _, item in ipairs(player:WaitForChild("Brainrots"):GetChildren()) do
		if item.Value == cardName then
			owned += 1
		end
	end
	table.insert(popupQueue, {name = cardName, mutation = mutation, serial = serial, known = owned > 1})
	showNextPopup()
end

Hud.floatingText = Effects.floatingText

function Hud.collected(amount, position)
	Sounds.play("Coin")
	Hud.floatingText(position + Vector3.new(0, 3, 0), "+$" .. GameConfig.format(amount), Color3.fromRGB(110, 255, 120))
end

-- ============================================================
-- MISE A JOUR
-- ============================================================
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local rebirths = leaderstats:WaitForChild("Rebirths")
local brainrots = player:WaitForChild("Brainrots")

-- l'argent défile jusqu'à la nouvelle valeur (compteur qui roule)
local shownCash = cash.Value
local rolling = Instance.new("NumberValue")
rolling.Value = shownCash
rolling.Changed:Connect(function(value)
	moneyLabel.Text = "$" .. GameConfig.format(math.floor(value + 0.5))
end)

function Hud.refresh()
	if math.abs(cash.Value - shownCash) > 0 then
		local gain = cash.Value > shownCash
		shownCash = cash.Value
		if gain and cash.Value - rolling.Value < 1e15 then
			TweenService:Create(rolling, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Value = cash.Value}):Play()
		else
			rolling.Value = cash.Value
		end
	end
	moneyLabel.Text = "$" .. GameConfig.format(math.floor(rolling.Value + 0.5))
	rebirthLabel.Text = "🔄 Rebirth " .. rebirths.Value
	local income = player:GetAttribute("Income") or 0
	incomeLabel.Text = income > 0 and ("+$" .. GameConfig.format(income) .. "/s") or "Pose tes brainrots dans ta base !"

	local inBag = 0
	for _, item in ipairs(brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) == 0 then
			inBag += 1
		end
	end
	bagBadge.Text = tostring(inBag)
	bagBadge.Visible = inBag > 0
end

cash.Changed:Connect(function()
	Hud.refresh()
	moneyScale.Scale = 1.1
	TweenService:Create(moneyScale, TweenInfo.new(0.2), {Scale = 1}):Play()
	coinScale.Scale = 1.25
	TweenService:Create(coinScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
end)
player:GetAttributeChangedSignal("Income"):Connect(Hud.refresh)
rebirths.Changed:Connect(Hud.refresh)
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

task.spawn(function()
	while true do
		local resetAt = Workspace:GetAttribute("MineResetAt")
		local resetStart = Workspace:GetAttribute("MineResetStart")
		if resetAt and resetStart then
			local remaining = math.max(0, resetAt - Workspace:GetServerTimeNow())
			timerLabel.Text = string.format("MINE %d:%02d", remaining // 60, math.floor(remaining % 60))
			local ratio = 1 - remaining / math.max(1, resetAt - resetStart)
			barFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
		end

		local luckUntil = player:GetAttribute("LuckUntil") or 0
		local luckLeft = luckUntil - os.time()
		potionLabel.Visible = luckLeft > 0
		if luckLeft > 0 then
			potionLabel.Text = "🍀 Chance x2  " .. GameConfig.formatTime(luckLeft)
		end

		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local camera = Workspace.CurrentCamera
		if camera then
			showWorld(GameConfig.getWorldAt(camera.CFrame.Position))
		end
		if root and root:IsA("BasePart") then
			local depth = math.floor(-(root.Position.Y - 3) / GameConfig.MINE.BlockSize)
			if depth >= 1 then
				depthLabel.Text = "Profondeur " .. depth .. " • " .. GameConfig.getLayer(depth + 1).Name
				depthLabel.Visible = true
			else
				depthLabel.Visible = false
			end
		end
		task.wait(0.25)
	end
end)

-- Adapte la taille du HUD aux petits écrans (téléphone)
local scaled = {menu, moneyFrame, timerFrame, depthLabel, toastHolder}
local scales = {}
for _, frame in ipairs(scaled) do
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = frame
	table.insert(scales, uiScale)
end
local function updateScale()
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local value = math.clamp(camera.ViewportSize.Y / 800, 0.6, 1.1)
	for _, uiScale in ipairs(scales) do
		uiScale.Scale = value
	end
end
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
updateScale()

return Hud
