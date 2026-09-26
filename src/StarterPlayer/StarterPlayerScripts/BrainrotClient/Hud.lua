-- ModuleScript client : le HUD.
--   À gauche : les gros boutons du menu
--   En bas à gauche : ton argent
--   En haut : le minuteur de la mine (+ la profondeur quand tu mines)
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

local Hud = {}
Hud.buttons = {}

-- ============================================================
-- MENU (à gauche, au milieu de l'écran)
-- ============================================================
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0, 0.5)
menu.Position = UDim2.new(0, 14, 0.5, 0)
menu.Size = UDim2.new(0, 170, 0, 380)
menu.Position = UDim2.new(0, 14, 0.52, 0)
menu.BackgroundTransparency = 1
menu.Parent = gui
local menuGrid = Instance.new("UIGridLayout")
menuGrid.CellSize = UDim2.new(0, 74, 0, 74)
menuGrid.CellPadding = UDim2.new(0, 14, 0, 20)
menuGrid.SortOrder = Enum.SortOrder.LayoutOrder
menuGrid.Parent = menu

local MENU = {
	{"base", "🏠", "Base", T.Green},
	{"mine", "⛏️", "Mine", T.Orange},
	{"inventory", "🎒", "Sac", T.Blue},
	{"index", "📖", "Index", T.Gold},
	{"rebirth", "🔄", "Rebirth", T.Purple},
	{"trade", "🤝", "Échange", T.Teal},
	{"boosters", "💎", "Shop", T.Pink},
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

local moneyLabel = UIKit.label(moneyFrame, "$0", {
	Size = UDim2.new(1, 0, 0, 60),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(95, 255, 110),
	TextXAlignment = Enum.TextXAlignment.Left,
})
moneyLabel:FindFirstChildOfClass("UIStroke").Thickness = 3.5
local moneyScale = Instance.new("UIScale")
moneyScale.Parent = moneyLabel

local rebirthLabel = UIKit.label(moneyFrame, "Rebirth 0", {
	Position = UDim2.new(0, 2, 0, 60),
	Size = UDim2.new(0.5, 0, 0, 24),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(205, 150, 255),
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
local timerFrame = Instance.new("Frame")
timerFrame.AnchorPoint = Vector2.new(0.5, 0)
timerFrame.Position = UDim2.new(0.5, 0, 0, 8)
timerFrame.Size = UDim2.new(0, 230, 0, 58)
timerFrame.BackgroundTransparency = 1
timerFrame.Parent = gui

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

local depthLabel = UIKit.label(gui, "", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
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

function Hud.notify(text, kind)
	toastCount += 1
	local toast = UIKit.label(toastHolder, text, {
		Size = UDim2.new(1, 0, 0, 34),
		Font = UIKit.TitleFont,
		TextColor3 = KIND_COLORS[kind or "info"] or KIND_COLORS.info,
		LayoutOrder = -toastCount,
	})
	local stroke = toast:FindFirstChildOfClass("UIStroke")
	stroke.Thickness = 2.5
	local scale = Instance.new("UIScale")
	scale.Scale = 0.5
	scale.Parent = toast
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()

	-- On garde les 4 derniers messages
	local toasts = {}
	for _, child in ipairs(toastHolder:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	for i = 5, #toasts do
		toasts[i]:Destroy()
	end

	task.delay(2.6, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 1}):Play()
			task.wait(0.35)
			toast:Destroy()
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
	CardRenderer.create(entry.name, entry.mutation, holder)

	UIKit.label(holder, card.Rarity, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.new(1.8, 0, 0, 44),
		Font = UIKit.TitleFont,
		TextColor3 = rarity.Color,
	}):FindFirstChildOfClass("UIStroke").Thickness = 3

	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	task.delay(rarity.Order >= 4 and 2.6 or 1.8, function()
		local out = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
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

function Hud.refresh()
	moneyLabel.Text = "$" .. GameConfig.format(cash.Value)
	rebirthLabel.Text = "Rebirth " .. rebirths.Value

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
end)
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
