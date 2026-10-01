-- ModuleScript client : la fenêtre de la MACHINE DE FUSION (bouton E devant la machine).
--   - en haut : une phrase qui explique
--   - 3 cases "+" : on clique -> le sac s'ouvre (trié par rareté) -> on choisit une carte
--   - à droite : l'aperçu du brainrot fusionné (le meilleur des 3, qui rapporte les 3 + 10 %)
--   - bouton FUSIONNER

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local CardPicker = require(script.Parent.CardPicker)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local brainrots = player:WaitForChild("Brainrots")

local CONFIG = GameConfig.FUSION
local VIOLET = Color3.fromRGB(150, 70, 255)

local Fusion = {}

local window = UIKit.window("Machine de Fusion", UDim2.new(0, 900, 0, 600), VIOLET)
Fusion.window = window
local content = window.content

local function clearChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function spinStroke(parent, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = Color3.new(1, 1, 1)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	local gradient = Instance.new("UIGradient")
	gradient.Color = CardRenderer.FUSION_SEQUENCE
	gradient.Parent = stroke
	CollectionService:AddTag(gradient, "SpinGradient")
	return stroke
end

-- ===== Explication en haut =====
UIKit.label(content, "Mets " .. CONFIG.Cards .. " brainrots de ton sac dans la machine : tu gardes le MEILLEUR, et il rapporte l'argent des " .. CONFIG.Cards .. " cartes + " .. math.floor(CONFIG.Bonus * 100 + 0.5) .. " % !", {
	Name = "Explain",
	Size = UDim2.new(1, 0, 0, 52),
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(235, 225, 255),
})

-- ===== Les cases =====
local row = Instance.new("Frame")
row.Name = "Slots"
row.Position = UDim2.new(0, 0, 0, 62)
row.Size = UDim2.new(1, 0, 0, 300)
row.BackgroundTransparency = 1
row.Parent = content
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = row

local function sign(text, order)
	return UIKit.label(row, text, {
		Name = "Sign",
		Size = UDim2.new(0, 38, 0, 60),
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(220, 200, 255),
		LayoutOrder = order,
	})
end

local chosen = {} -- chosen[index] = StringValue (carte du sac)
local slotFrames = {}
local render

local function chosenIds(except)
	local ids = {}
	for index, item in pairs(chosen) do
		if index ~= except then
			ids[item.Name] = true
		end
	end
	return ids
end

local function openPicker(index)
	CardPicker.open({
		Title = "Choisis un brainrot (" .. index .. "/" .. CONFIG.Cards .. ")",
		Subtitle = "Trié par rareté : le meilleur des " .. CONFIG.Cards .. " est gardé et devient FUSIONNÉ",
		Exclude = chosenIds(index),
		Filter = function(item)
			return GameConfig.getFusion(item) == nil -- les cartes déjà fusionnées ne peuvent pas être refusionnées
		end,
		Color = VIOLET,
		ButtonText = "METTRE",
		OnPick = function(item)
			chosen[index] = item
			Sounds.play("Click")
			render()
		end,
	})
end

for index = 1, CONFIG.Cards do
	local slot = Instance.new("TextButton")
	slot.Name = "Slot" .. index
	slot.Text = ""
	slot.AutoButtonColor = false
	slot.Size = UDim2.new(0, 160, 0, 256)
	slot.BackgroundColor3 = Color3.fromRGB(30, 18, 55)
	slot.BackgroundTransparency = 0.25
	slot.LayoutOrder = index * 2 - 1
	slot.Parent = row
	UIKit.corner(slot, 14)
	spinStroke(slot, 3)
	slot.MouseButton1Click:Connect(function()
		openPicker(index)
	end)
	slotFrames[index] = slot
	if index < CONFIG.Cards then
		sign("+", index * 2)
	end
end
sign("=", CONFIG.Cards * 2)

local resultFrame = Instance.new("Frame")
resultFrame.Name = "Result"
resultFrame.Size = UDim2.new(0, 180, 0, 288)
resultFrame.BackgroundColor3 = Color3.fromRGB(45, 20, 80)
resultFrame.BackgroundTransparency = 0.1
resultFrame.LayoutOrder = CONFIG.Cards * 2 + 1
resultFrame.Parent = row
UIKit.corner(resultFrame, 16)
spinStroke(resultFrame, 5)

-- ===== Aperçu du calcul + bouton =====
local preview = UIKit.label(content, "", {
	Name = "Preview",
	Position = UDim2.new(0, 0, 0, 372),
	Size = UDim2.new(1, 0, 0, 38),
	Font = UIKit.TitleFont,
	TextColor3 = T.Gold,
})
local fuseButton = UIKit.button(content, "⚡ FUSIONNER ⚡", T.Gray, {
	Name = "FuseButton",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -4),
	Size = UDim2.new(0, 340, 0, 64),
})
local clearButton = UIKit.button(content, "VIDER", T.Red, {
	Name = "ClearButton",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, -8),
	Size = UDim2.new(0, 140, 0, 50),
})

local function emptySlot(slot, index)
	UIKit.label(slot, "+", {
		Name = "Plus",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		Size = UDim2.new(0.7, 0, 0.4, 0),
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(215, 190, 255),
	})
	UIKit.label(slot, "Carte " .. index, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.7, 0),
		Size = UDim2.new(0.8, 0, 0, 26),
		TextColor3 = T.SubText,
	})
end

function render()
	-- une carte a quitté le sac (vendue, posée...) : on l'enlève de la machine
	for index, item in pairs(chosen) do
		if item.Parent ~= brainrots or (item:GetAttribute("Slot") or 0) ~= 0 then
			chosen[index] = nil
		end
	end

	local items = {}
	for index, slot in ipairs(slotFrames) do
		clearChildren(slot)
		local item = chosen[index]
		if item then
			table.insert(items, item)
			local holder = Instance.new("Frame")
			holder.Size = UDim2.new(1, -10, 1, -10)
			holder.Position = UDim2.new(0, 5, 0, 5)
			holder.BackgroundTransparency = 1
			holder.Parent = slot
			CardRenderer.createFitted(item.Value, item:GetAttribute("Mutation"), holder, item:GetAttribute("Serial"), GameConfig.getFusion(item))
			local remove = UIKit.button(slot, "✕", T.Red, {
				Name = "Remove",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.new(0, 38, 0, 38),
				ZIndex = 8,
			})
			remove.MouseButton1Click:Connect(function()
				chosen[index] = nil
				render()
			end)
		else
			emptySlot(slot, index)
		end
	end

	clearChildren(resultFrame)
	local ready = #items == CONFIG.Cards
	if ready then
		local income, level, best = GameConfig.getFusionResult(items)
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, -12, 1, -12)
		holder.Position = UDim2.new(0, 6, 0, 6)
		holder.BackgroundTransparency = 1
		holder.Parent = resultFrame
		CardRenderer.createFitted(best.Value, best:GetAttribute("Mutation"), holder, best:GetAttribute("Serial"), {Income = income, Level = level})
		local parts = {}
		for _, item in ipairs(items) do
			table.insert(parts, "$" .. GameConfig.format(GameConfig.getItemValue(item)))
		end
		preview.Text = table.concat(parts, " + ") .. " + " .. math.floor(CONFIG.Bonus * 100 + 0.5) .. " % = $" .. GameConfig.format(income) .. "/s"
	else
		UIKit.label(resultFrame, "?", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.42, 0),
			Size = UDim2.new(0.6, 0, 0.36, 0),
			Font = UIKit.TitleFont,
			TextColor3 = Color3.fromRGB(215, 190, 255),
		})
		UIKit.label(resultFrame, "Résultat", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.7, 0),
			Size = UDim2.new(0.8, 0, 0, 26),
			TextColor3 = T.SubText,
		})
		preview.Text = "Clique sur les + pour choisir " .. CONFIG.Cards .. " brainrots (" .. #items .. "/" .. CONFIG.Cards .. ")"
	end
	UIKit.setButtonColor(fuseButton, ready and VIOLET or T.Gray)
	fuseButton:SetAttribute("Ready", ready)
end

fuseButton.MouseButton1Click:Connect(function()
	local ids = {}
	for index = 1, CONFIG.Cards do
		if not chosen[index] then
			openPicker(index)
			return
		end
		table.insert(ids, chosen[index].Name)
	end
	Remotes.Fuse:FireServer(ids)
end)
clearButton.MouseButton1Click:Connect(function()
	chosen = {}
	render()
end)

-- ===== Révélation du brainrot fusionné =====
local reveal = Instance.new("TextButton")
reveal.Name = "Reveal"
reveal.Text = ""
reveal.AutoButtonColor = false
reveal.Size = UDim2.new(1, 0, 1, 0)
reveal.BackgroundColor3 = Color3.fromRGB(20, 8, 40)
reveal.BackgroundTransparency = 0.05
reveal.Visible = false
reveal.ZIndex = 10
reveal.Parent = content
UIKit.corner(reveal, 14)

local function showResult(result)
	clearChildren(reveal)
	reveal.Visible = true
	UIKit.label(reveal, "⚡ FUSION RÉUSSIE ! ⚡", {
		Name = "RevealTitle",
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, 0, 0, 50),
		Font = UIKit.TitleFont,
		TextColor3 = T.Gold,
		ZIndex = 11,
	})
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.52, 0)
	holder.Size = UDim2.new(0, 220, 0, 352)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 11
	holder.Parent = reveal
	CardRenderer.createFitted(result.Name, result.Mutation, holder, result.Serial, result.Fusion)
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = holder
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	UIKit.label(reveal, result.Fusion and ("$" .. GameConfig.format(result.Fusion.Income) .. "/s") or "", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(0.8, 0, 0, 40),
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(120, 255, 140),
		ZIndex = 11,
	})
	Sounds.play("Win")
	task.delay(3, function()
		reveal.Visible = false
	end)
end
reveal.MouseButton1Click:Connect(function()
	reveal.Visible = false
end)

window.onOpen = function()
	reveal.Visible = false
	render()
end

-- Le sac change : on met à jour la machine si elle est ouverte
local pending = false
local function refresh()
	if pending or not window.isOpen() then return end
	pending = true
	task.defer(function()
		pending = false
		render()
	end)
end
brainrots.ChildRemoved:Connect(refresh)

-- Fermer la machine ferme aussi le sélecteur
window.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
	if not window.overlay.Visible and CardPicker.isOpen() then
		CardPicker.close()
	end
end)

function Fusion.init()
	Remotes.OpenFusion.OnClientEvent:Connect(window.open)
	Remotes.FusionResult.OnClientEvent:Connect(function(result)
		chosen = {}
		if not window.isOpen() then
			window.open()
		end
		render()
		showResult(result)
	end)
end

Fusion.render = function()
	render()
end
Fusion.choose = function(index, item)
	chosen[index] = item
	render()
end

return Fusion
