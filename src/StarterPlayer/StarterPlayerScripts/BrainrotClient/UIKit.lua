-- ModuleScript client : outils pour construire l'interface.
-- Style "jeu Roblox" : couleurs vives, gros contours noirs, police cartoon, boutons qui rebondissent.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIKit = {}

UIKit.Theme = {
	Dark = Color3.fromRGB(24, 26, 38),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(215, 222, 240),
	Green = Color3.fromRGB(70, 215, 90),
	Blue = Color3.fromRGB(55, 150, 255),
	Purple = Color3.fromRGB(165, 85, 255),
	Gold = Color3.fromRGB(255, 195, 40),
	Orange = Color3.fromRGB(255, 140, 40),
	Pink = Color3.fromRGB(255, 85, 170),
	Teal = Color3.fromRGB(30, 200, 185),
	Red = Color3.fromRGB(240, 60, 60),
	Gray = Color3.fromRGB(110, 115, 130),
}
local T = UIKit.Theme

UIKit.TitleFont = Enum.Font.LuckiestGuy
UIKit.Font = Enum.Font.FredokaOne

local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")
UIKit.ScreenGui = screenGui

-- Crée une instance avec ses propriétés
function UIKit.new(className, props, parent)
	local obj = Instance.new(className)
	for key, value in pairs(props or {}) do
		obj[key] = value
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

function UIKit.corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
	return corner
end

-- Contour autour d'un cadre
function UIKit.outline(parent, thickness, color)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(0, 0, 0)
	stroke.Thickness = thickness or 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

-- Contour autour d'un texte
function UIKit.textOutline(label, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return stroke
end

function UIKit.gradient(parent, c1, c2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(c1, c2)
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

function UIKit.padding(parent, pixels)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
	return padding
end

-- Texte blanc avec contour noir (le style de base)
function UIKit.label(parent, text, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = T.Text
	label.Font = UIKit.Font
	label.TextScaled = true
	label.Size = UDim2.new(1, 0, 0, 24)
	for key, value in pairs(props or {}) do
		label[key] = value
	end
	UIKit.textOutline(label, 2)
	label.Parent = parent
	return label
end

-- Cadre clair semi-transparent (lignes de liste, cases)
function UIKit.box(parent, props)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0.88
	frame.BorderSizePixel = 0
	for key, value in pairs(props or {}) do
		frame[key] = value
	end
	UIKit.corner(frame, 12)
	frame.Parent = parent
	return frame
end

-- Petit rebond au survol / clic
local function bounce(button)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1.06}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1}):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.05), {Scale = 0.92}):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Scale = 1.06}):Play()
	end)
end

local function colorSequenceFor(color)
	return ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.2), color:Lerp(Color3.new(0, 0, 0), 0.3))
end

-- Gros bouton coloré avec contour noir et reflet
function UIKit.button(parent, text, color, props)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = UIKit.TitleFont
	button.TextScaled = true
	button.TextStrokeTransparency = 0
	button.TextStrokeColor3 = Color3.new(0, 0, 0)
	button.Size = UDim2.new(0, 160, 0, 44)
	for key, value in pairs(props or {}) do
		button[key] = value
	end
	UIKit.corner(button, 12)
	UIKit.outline(button, 3)

	local gradient = Instance.new("UIGradient")
	gradient.Name = "Fill"
	gradient.Rotation = 90
	gradient.Color = colorSequenceFor(color)
	gradient.Parent = button

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = 28
	constraint.Parent = button
	UIKit.padding(button, 7)

	-- Reflet brillant en haut du bouton
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.78
	shine.BorderSizePixel = 0
	shine.Position = UDim2.new(0, -3, 0, -4)
	shine.Size = UDim2.new(1, 6, 0.42, 0)
	shine.Parent = button
	UIKit.corner(shine, 10)

	bounce(button)
	button.Parent = parent
	return button
end

-- Change la couleur d'un bouton créé avec UIKit.button
function UIKit.setButtonColor(button, color)
	local gradient = button:FindFirstChild("Fill")
	if gradient and gradient:IsA("UIGradient") then
		gradient.Color = colorSequenceFor(color)
	end
end

-- Bouton carré du menu (icône + nom en dessous)
function UIKit.menuButton(parent, icon, text, color)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 74, 0, 74)
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Text = ""
	button.Parent = parent
	UIKit.corner(button, 16)
	UIKit.outline(button, 3.5)
	UIKit.gradient(button, color:Lerp(Color3.new(1, 1, 1), 0.25), color:Lerp(Color3.new(0, 0, 0), 0.25), 90)

	local shine = Instance.new("Frame")
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.8
	shine.BorderSizePixel = 0
	shine.Position = UDim2.new(0.08, 0, 0.06, 0)
	shine.Size = UDim2.new(0.84, 0, 0.36, 0)
	shine.Parent = button
	UIKit.corner(shine, 10)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Size = UDim2.new(0.72, 0, 0.62, 0)
	iconLabel.Position = UDim2.new(0.14, 0, 0.08, 0)
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = button

	UIKit.label(button, text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.92, 0),
		Size = UDim2.new(1.15, 0, 0.34, 0),
		Font = UIKit.TitleFont,
		ZIndex = 2,
	})

	bounce(button)
	return button
end

-- ====== FENETRES (une seule ouverte à la fois) ======
local windows = {}

function UIKit.window(title, size, color)
	color = color or T.Blue
	local overlay = Instance.new("TextButton")
	overlay.Name = title
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.AutoButtonColor = false
	overlay.Text = ""
	overlay.Visible = false
	overlay.ZIndex = 20
	overlay.Parent = screenGui

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.52, 0)
	frame.Size = size
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.Parent = overlay
	UIKit.corner(frame, 20)
	UIKit.outline(frame, 4)
	UIKit.gradient(frame, color:Lerp(Color3.new(1, 1, 1), 0.1), color:Lerp(Color3.new(0, 0, 0), 0.45), 90)

	local scale = Instance.new("UIScale")
	scale.Parent = frame

	-- Titre qui dépasse en haut à gauche
	UIKit.label(frame, title, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 22, 0, 6),
		Size = UDim2.new(0.7, 0, 0, 48),
		Font = UIKit.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}):FindFirstChildOfClass("UIStroke").Thickness = 3.5

	-- Bouton X rouge
	local close = UIKit.button(frame, "X", T.Red, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.new(0, 50, 0, 50),
		ZIndex = 3,
	})

	-- Zone de contenu (fond sombre)
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Position = UDim2.new(0, 14, 0, 40)
	inner.Size = UDim2.new(1, -28, 1, -54)
	inner.BackgroundColor3 = Color3.new(0, 0, 0)
	inner.BackgroundTransparency = 0.45
	inner.BorderSizePixel = 0
	inner.Parent = frame
	UIKit.corner(inner, 14)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -24, 1, -24)
	content.Position = UDim2.new(0, 12, 0, 12)
	content.BackgroundTransparency = 1
	content.Parent = inner

	-- Adapte la fenêtre aux petits écrans
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(size.X.Offset, size.Y.Offset)
	sizeLimit.Parent = frame

	local win = {overlay = overlay, frame = frame, content = content, onOpen = nil}

	function win.isOpen()
		return overlay.Visible
	end

	function win.open()
		for _, other in ipairs(windows) do
			if other ~= win then
				other.overlay.Visible = false
			end
		end
		overlay.Visible = true
		scale.Scale = 0.7
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		if win.onOpen then
			win.onOpen()
		end
	end

	function win.close()
		overlay.Visible = false
	end

	function win.toggle()
		if overlay.Visible then
			win.close()
		else
			win.open()
		end
	end

	close.MouseButton1Click:Connect(win.close)
	table.insert(windows, win)
	return win
end

function UIKit.closeAll()
	for _, win in ipairs(windows) do
		win.overlay.Visible = false
	end
end

-- Grille défilante (inventaire, index...)
function UIKit.scrollGrid(parent, cellSize, props)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = Color3.new(1, 1, 1)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	for key, value in pairs(props or {}) do
		scroll[key] = value
	end
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = cellSize
	grid.CellPadding = UDim2.new(0, 10, 0, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll
	UIKit.padding(scroll, 6)
	scroll.Parent = parent
	return scroll
end

return UIKit
