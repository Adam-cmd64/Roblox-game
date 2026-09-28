-- ModuleScript client : le bouton ⚙️ PARAMÈTRES (en haut à droite).
--   🎵 Musique de fond : oui / non
--   🖥️ Graphismes allégés : coupe les ombres, les particules, les lumières... (pour les petits PC et téléphones)
--   🤝 Mes amis passent mes lasers : quand ta base est verrouillée, tes AMIS Roblox peuvent entrer (pas les inconnus)
-- Les choix sont sauvegardés (attributs "Setting_..." du joueur, voir PlayerData).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Settings = {}

local function get(key)
	local value = player:GetAttribute("Setting_" .. key)
	if value == nil then
		return GameConfig.SETTINGS[key]
	end
	return value
end

-- ============================================================
-- MUSIQUE
-- ============================================================
local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.Looped = true
music.Volume = GameConfig.MUSIC_VOLUME
music.SoundId = GameConfig.assetId(GameConfig.MUSIC_FILE)
music.Parent = SoundService
Settings.music = music

local function applyMusic()
	if get("Music") and music.SoundId ~= "" then
		if not music.IsPlaying then
			music:Play()
		end
	else
		music:Stop()
	end
end

-- ============================================================
-- GRAPHISMES ALLÉGÉS
-- ============================================================
local saved = {} -- état d'origine des effets qu'on coupe (pour les remettre)
local lowConnection

local function lighten(object)
	if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("PointLight") or object:IsA("SpotLight") then
		if saved[object] == nil then
			saved[object] = object.Enabled
		end
		object.Enabled = false
	end
end

local function applyGraphics()
	local low = get("LowGraphics")
	local bloom = Lighting:FindFirstChild("BrainrotBloom")
	if low then
		if saved.shadows == nil then
			saved.shadows = Lighting.GlobalShadows
		end
		Lighting.GlobalShadows = false
		if bloom and bloom:IsA("BloomEffect") then
			bloom.Enabled = false
		end
		for _, object in ipairs(Workspace:GetDescendants()) do
			lighten(object)
		end
		if not lowConnection then
			lowConnection = Workspace.DescendantAdded:Connect(lighten)
		end
	else
		if lowConnection then
			lowConnection:Disconnect()
			lowConnection = nil
		end
		if saved.shadows ~= nil then
			Lighting.GlobalShadows = saved.shadows
		end
		if bloom and bloom:IsA("BloomEffect") then
			bloom.Enabled = true
		end
		for object, enabled in pairs(saved) do
			if typeof(object) == "Instance" and object.Parent then
				(object :: any).Enabled = enabled
			end
		end
		table.clear(saved)
	end
end
Settings.isLowGraphics = function()
	return get("LowGraphics") == true
end

-- ============================================================
-- LA FENÊTRE
-- ============================================================
local window = UIKit.window("Paramètres", UDim2.new(0, 560, 0, 400), T.Gray)
Settings.window = window

local toggles = {}

local function toggleRow(order, key, icon, title, hint)
	local row = UIKit.box(window.content, {Size = UDim2.new(1, 0, 0, 92), Position = UDim2.new(0, 0, 0, (order - 1) * 104)})
	UIKit.label(row, icon, {Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0, 10, 0.5, -28), Font = Enum.Font.GothamBold})
	UIKit.label(row, title, {Size = UDim2.new(1, -220, 0, 32), Position = UDim2.new(0, 76, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Font = UIKit.TitleFont})
	UIKit.label(row, hint, {Size = UDim2.new(1, -220, 0, 34), Position = UDim2.new(0, 76, 0, 46), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.SubText, TextWrapped = true})
	local button = UIKit.button(row, "", T.Green, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 120, 0, 50)})
	button.Name = "Toggle_" .. key
	toggles[key] = button
	button.MouseButton1Click:Connect(function()
		local value = not get(key)
		player:SetAttribute("Setting_" .. key, value) -- tout de suite chez moi...
		Remotes.SetSetting:FireServer(key, value) -- ...et sauvegardé par le serveur
		Sounds.play("Click")
	end)
end

toggleRow(1, "Music", "🎵", "Musique", "La musique de fond du jeu")
toggleRow(2, "LowGraphics", "🖥️", "Graphismes allégés", "Moins d'effets : le jeu est plus fluide sur les petits PC et les téléphones")
toggleRow(3, "FriendsCanEnter", "🤝", "Mes amis passent mes lasers", "Quand ta base est verrouillée, tes amis Roblox peuvent entrer (pas les inconnus)")

local function refresh()
	for key, button in pairs(toggles) do
		local on = get(key) == true
		button.Text = on and "OUI" or "NON"
		UIKit.setButtonColor(button, on and T.Green or T.Red)
	end
end

-- ============================================================
-- LE BOUTON ⚙️ EN HAUT À DROITE
-- ============================================================
local gear = Instance.new("TextButton")
gear.Name = "SettingsButton"
gear.AnchorPoint = Vector2.new(1, 0)
gear.Position = UDim2.new(1, -10, 0, 10) -- tout en haut à droite
gear.Size = UDim2.new(0, 58, 0, 58)
gear.BackgroundColor3 = Color3.fromRGB(40, 42, 58)
gear.Text = "⚙️"
gear.TextScaled = true
gear.Font = Enum.Font.GothamBold
gear.TextColor3 = Color3.new(1, 1, 1)
gear.Parent = UIKit.MenuGui -- au-dessus des fenêtres, comme le menu
UIKit.hudScale(gear)
UIKit.corner(gear, 14)
UIKit.outline(gear, 3)
local gearPadding = Instance.new("UIPadding")
gearPadding.PaddingTop = UDim.new(0, 8)
gearPadding.PaddingBottom = UDim.new(0, 8)
gearPadding.PaddingLeft = UDim.new(0, 8)
gearPadding.PaddingRight = UDim.new(0, 8)
gearPadding.Parent = gear
gear.MouseButton1Click:Connect(window.toggle)

-- ============================================================
-- LISTE DES COMMANDES ADMIN (/aide dans le chat)
-- ============================================================
local helpWindow = UIKit.window("Commandes admin", UDim2.new(0, 900, 0, 600), T.Gold)
Settings.helpWindow = helpWindow
UIKit.label(helpWindow.content, "Vise un joueur avec son pseudo (ex : /vip Bob ou /vip @Bob) • @all = tout le serveur • montants : 1k, 1m, 1b, 1t", {
	Size = UDim2.new(1, 0, 0, 26),
	TextColor3 = Color3.fromRGB(255, 230, 120),
	TextWrapped = true,
})
local helpList = Instance.new("ScrollingFrame")
helpList.Name = "HelpList"
helpList.Size = UDim2.new(1, 0, 1, -34)
helpList.Position = UDim2.new(0, 0, 0, 34)
helpList.BackgroundTransparency = 1
helpList.BorderSizePixel = 0
helpList.ScrollBarThickness = 8
helpList.AutomaticCanvasSize = Enum.AutomaticSize.Y
helpList.CanvasSize = UDim2.new()
helpList.Parent = helpWindow.content
local helpLayout = Instance.new("UIListLayout")
helpLayout.Padding = UDim.new(0, 4)
helpLayout.SortOrder = Enum.SortOrder.LayoutOrder
helpLayout.Parent = helpList

function Settings.showHelp(list)
	for _, child in ipairs(helpList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for order, entry in ipairs(list) do
		local row = UIKit.box(helpList, {Size = UDim2.new(1, -12, 0, 34), LayoutOrder = order})
		UIKit.label(row, entry[1], {Size = UDim2.new(0.46, 0, 1, -8), Position = UDim2.new(0, 8, 0, 4), TextXAlignment = Enum.TextXAlignment.Left, Font = UIKit.TitleFont, TextColor3 = Color3.fromRGB(255, 220, 110)})
		UIKit.label(row, entry[2], {Size = UDim2.new(0.52, 0, 1, -8), Position = UDim2.new(0.47, 0, 0, 4), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
	end
	helpWindow.open()
end

function Settings.init()
	Remotes.AdminHelp.OnClientEvent:Connect(Settings.showHelp)
	window.onOpen = refresh
	for key in pairs(GameConfig.SETTINGS) do
		player:GetAttributeChangedSignal("Setting_" .. key):Connect(function()
			refresh()
			if key == "Music" then
				applyMusic()
			elseif key == "LowGraphics" then
				applyGraphics()
			end
		end)
	end
	refresh()
	applyMusic()
	applyGraphics()
end

return Settings
