-- ModuleScript client : petits outils pour construire une interface propre et cohérente.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIKit = {}

UIKit.Theme = {
	Panel = Color3.fromRGB(22, 30, 52),
	PanelDark = Color3.fromRGB(14, 19, 36),
	PanelLight = Color3.fromRGB(38, 50, 82),
	Stroke = Color3.fromRGB(120, 150, 220),
	Text = Color3.fromRGB(240, 244, 255),
	SubText = Color3.fromRGB(165, 178, 210),
	Green = Color3.fromRGB(60, 210, 100),
	Blue = Color3.fromRGB(60, 140, 255),
	Purple = Color3.fromRGB(150, 80, 255),
	Gold = Color3.fromRGB(255, 200, 50),
	Red = Color3.fromRGB(235, 60, 70),
	Gray = Color3.fromRGB(90, 96, 115),
}
local T = UIKit.Theme

local player = Players.LocalPlayer
UIKit.ScreenGui = Instance.new("ScreenGui")
UIKit.ScreenGui.Name = "BrainrotHUD"
UIKit.ScreenGui.ResetOnSpawn = false
UIKit.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UIKit.ScreenGui.Parent = player:WaitForChild("PlayerGui")

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
	return UIKit.new("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

function UIKit.stroke(parent, color, thickness, transparency)
	return UIKit.new("UIStroke", {
		Color = color or T.Stroke,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0.6,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

function UIKit.gradient(parent, c1, c2, rotation)
	return UIKit.new("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rotation or 90}, parent)
end

function UIKit.padding(parent, all)
	return UIKit.new("UIPadding", {
		PaddingTop = UDim.new(0, all), PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all),
	}, parent)
end

function UIKit.label(parent, text, props)
	local label = UIKit.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = T.Text,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		Size = UDim2.new(1, 0, 0, 24),
	}, parent)
	for key, value in pairs(props or {}) do
		label[key] = value
	end
	return label
end

-- Panneau sombre arrondi (style de la maquette)
function UIKit.panel(parent, props)
	local frame = UIKit.new("Frame", {
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
	}, parent)
	for key, value in pairs(props or {}) do
		frame[key] = value
	end
	UIKit.corner(frame, 14)
	UIKit.stroke(frame, T.Stroke, 1.5, 0.7)
	return frame
end

-- Petit effet quand on survole / clique un bouton
local function bounce(button)
	local scale = UIKit.new("UIScale", {Scale = 1}, button)
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), {Scale = 1.05}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), {Scale = 1}):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), {Scale = 0.94}):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1.05}):Play()
	end)
end

function UIKit.button(parent, text, color, props)
	local button = UIKit.new("TextButton", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		Size = UDim2.new(0, 160, 0, 40),
		BorderSizePixel = 0,
	}, parent)
	for key, value in pairs(props or {}) do
		button[key] = value
	end
	UIKit.corner(button, 10)
	local grad = UIKit.gradient(button, color:Lerp(Color3.new(1, 1, 1), 0.15), color:Lerp(Color3.new(0, 0, 0), 0.25), 90)
	UIKit.stroke(button, Color3.new(0, 0, 0), 2, 0.5)
	UIKit.new("UITextSizeConstraint", {MaxTextSize = 26}, button)
	UIKit.padding(button, 6)
	bounce(button)

	function button.setColor(newColor)
		grad.Color = ColorSequence.new(newColor:Lerp(Color3.new(1, 1, 1), 0.15), newColor:Lerp(Color3.new(0, 0, 0), 0.25))
	end
	return button
end

-- Bouton carré avec icône + texte (menu en haut à gauche)
function UIKit.iconButton(parent, icon, text, accent)
	local button = UIKit.new("TextButton", {
		Size = UDim2.new(0, 70, 0, 70),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.1,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}, parent)
	UIKit.corner(button, 14)
	UIKit.stroke(button, accent or T.Stroke, 2, 0.45)
	UIKit.label(button, icon, {
		Size = UDim2.new(1, 0, 0.55, 0),
		Position = UDim2.new(0, 0, 0.06, 0),
		Font = Enum.Font.GothamBold,
	})
	UIKit.label(button, text, {
		Size = UDim2.new(0.9, 0, 0.24, 0),
		Position = UDim2.new(0.05, 0, 0.66, 0),
		TextColor3 = T.Text,
	})
	bounce(button)
	return button
end

-- ====== FENETRES (une seule ouverte à la fois) ======
local windows = {}

function UIKit.window(title, size, accent)
	accent = accent or T.Blue
	local overlay = UIKit.new("TextButton", {
		Name = title,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 20,
	}, UIKit.ScreenGui)

	local frame = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		BackgroundColor3 = T.PanelDark,
		BorderSizePixel = 0,
		ZIndex = 21,
	}, overlay)
	UIKit.corner(frame, 18)
	UIKit.stroke(frame, accent, 3, 0.1)
	UIKit.new("UISizeConstraint", {MaxSize = Vector2.new(size.X.Offset, size.Y.Offset)}, frame)
	local scale = UIKit.new("UIScale", {Scale = 1}, frame)

	local header = UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 21,
	}, frame)
	UIKit.corner(header, 18)
	UIKit.gradient(header, accent, accent:Lerp(Color3.new(0, 0, 0), 0.5), 0)
	UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 1, -18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 21,
	}, header).Name = "HeaderFill"
	UIKit.gradient(header.HeaderFill, accent, accent:Lerp(Color3.new(0, 0, 0), 0.5), 0)

	UIKit.label(header, title, {
		Size = UDim2.new(1, -120, 0, 36),
		Position = UDim2.new(0, 20, 0, 10),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
	})

	local close = UIKit.button(header, "✕", T.Red, {
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(1, -50, 0, 8),
		ZIndex = 22,
	})

	local content = UIKit.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -32, 1, -76),
		Position = UDim2.new(0, 16, 0, 64),
		BackgroundTransparency = 1,
		ZIndex = 21,
	}, frame)

	local win = {overlay = overlay, frame = frame, content = content, scale = scale, onOpen = nil}

	function win.open()
		for _, other in ipairs(windows) do
			if other ~= win then
				other.overlay.Visible = false
			end
		end
		overlay.Visible = true
		scale.Scale = 0.85
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
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

-- Grille défilante (pour l'inventaire, l'index...)
function UIKit.scrollGrid(parent, cellSize, props)
	local scroll = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = T.Stroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 21,
	}, parent)
	for key, value in pairs(props or {}) do
		scroll[key] = value
	end
	UIKit.new("UIGridLayout", {
		CellSize = cellSize,
		CellPadding = UDim2.new(0, 10, 0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll)
	UIKit.padding(scroll, 6)
	return scroll
end

return UIKit
