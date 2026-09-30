-- ModuleScript client : le SÉLECTEUR DE CARTES (grande fenêtre avec tout le sac, trié par rareté).
-- Utilisé par la Machine de Fusion et par les échanges : on clique sur "+" -> on choisit une carte.
-- Il s'ouvre PAR-DESSUS la fenêtre en cours (il ne la ferme pas).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local T = UIKit.Theme

local player = Players.LocalPlayer
local brainrots = player:WaitForChild("Brainrots")

local CardPicker = {}

local WIDTH, HEIGHT = 860, 600

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotPicker"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8 -- au-dessus des fenêtres et du menu
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
CardPicker.Gui = gui

local overlay = Instance.new("TextButton")
overlay.Name = "PickerOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.AutoButtonColor = false
overlay.Text = ""
overlay.Parent = gui

local frame = Instance.new("Frame")
frame.Name = "Picker"
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
frame.BackgroundColor3 = Color3.new(1, 1, 1)
frame.BorderSizePixel = 0
frame.Parent = overlay
UIKit.corner(frame, 20)
UIKit.outline(frame, 4)
UIKit.gradient(frame, T.Purple:Lerp(Color3.new(1, 1, 1), 0.1), T.Purple:Lerp(Color3.new(0, 0, 0), 0.5), 90)
local fitScale = UIKit.autoFit(frame, WIDTH + 30, HEIGHT + 40, 0.96)

local title = UIKit.label(frame, "Choisis une carte", {
	Name = "Title",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 22, 0, 6),
	Size = UDim2.new(0.75, 0, 0, 46),
	Font = UIKit.TitleFont,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 3,
})
local subtitle = UIKit.label(frame, "", {
	Name = "Subtitle",
	Position = UDim2.new(0, 22, 0, 34),
	Size = UDim2.new(1, -44, 0, 24),
	TextColor3 = T.SubText,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local closeButton = UIKit.button(frame, "X", T.Red, {
	Name = "Close",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.new(0, 50, 0, 50),
	ZIndex = 3,
})

local inner = Instance.new("Frame")
inner.Name = "Inner"
inner.Position = UDim2.new(0, 14, 0, 64)
inner.Size = UDim2.new(1, -28, 1, -78)
inner.BackgroundColor3 = Color3.new(0, 0, 0)
inner.BackgroundTransparency = 0.45
inner.BorderSizePixel = 0
inner.Parent = frame
UIKit.corner(inner, 14)

local grid = UIKit.scrollGrid(inner, UDim2.new(0, 142, 0, 256), {
	Name = "Cards",
	Size = UDim2.new(1, -12, 1, -12),
	Position = UDim2.new(0, 6, 0, 6),
})
local emptyLabel = UIKit.label(inner, "Aucune carte dans ton sac... va miner !", {
	Name = "Empty",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0.8, 0, 0, 40),
	Font = UIKit.TitleFont,
	Visible = false,
})

local current = nil -- {onPick, exclude, filter}

local function clear()
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function CardPicker.isOpen()
	return gui.Enabled
end

function CardPicker.close()
	gui.Enabled = false
	current = nil
	clear()
end

-- Les cartes proposées : celles du SAC, triées par rareté (la plus haute d'abord) puis par revenu
function CardPicker.getChoices(exclude, filter)
	local items = {}
	for _, item in ipairs(brainrots:GetChildren()) do
		if item:IsA("StringValue") and (item:GetAttribute("Slot") or 0) == 0 and not (exclude and exclude[item.Name]) and (not filter or filter(item)) then
			table.insert(items, item)
		end
	end
	table.sort(items, GameConfig.compareItems)
	return items
end

local function render()
	clear()
	if not current then return end
	local items = CardPicker.getChoices(current.exclude, current.filter)
	emptyLabel.Visible = #items == 0
	for order, item in ipairs(items) do
		local tile = Instance.new("TextButton")
		tile.Name = "PickTile"
		tile.Text = ""
		tile.AutoButtonColor = false
		tile.BackgroundTransparency = 1
		tile.LayoutOrder = order
		tile:SetAttribute("ItemId", item.Name)
		tile.Parent = grid
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 222)
		holder.BackgroundTransparency = 1
		holder.Parent = tile
		CardRenderer.createFitted(item.Value, item:GetAttribute("Mutation"), holder, item:GetAttribute("Serial"), GameConfig.getFusion(item))
		local pick = UIKit.button(tile, current.buttonText or "CHOISIR", current.color or T.Green, {
			Name = "Pick",
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 226),
		})
		local function choose()
			local onPick = current and current.onPick
			CardPicker.close()
			if onPick and item.Parent then
				onPick(item)
			end
		end
		pick.MouseButton1Click:Connect(choose)
		tile.MouseButton1Click:Connect(choose)
	end
end

-- options : {Title, Subtitle, Exclude = {[itemId] = true}, Filter = function(item), OnPick = function(item), ButtonText, Color}
function CardPicker.open(options)
	current = {
		onPick = options.OnPick,
		exclude = options.Exclude,
		filter = options.Filter,
		buttonText = options.ButtonText,
		color = options.Color,
	}
	title.Text = options.Title or "Choisis une carte"
	subtitle.Text = options.Subtitle or "Trié par rareté : les meilleures cartes en premier"
	gui.Enabled = true
	render()
	local target = UIKit.fitFactor(WIDTH + 30, HEIGHT + 40, 0.96)
	fitScale.Scale = target * 0.8
	TweenService:Create(fitScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target}):Play()
end

closeButton.MouseButton1Click:Connect(CardPicker.close)

-- Le sac change pendant qu'on choisit (carte vendue, volée...) : on met à jour
local pending = false
local function refresh()
	if not gui.Enabled or pending then return end
	pending = true
	task.defer(function()
		pending = false
		if gui.Enabled then
			render()
		end
	end)
end
brainrots.ChildAdded:Connect(refresh)
brainrots.ChildRemoved:Connect(refresh)

return CardPicker
