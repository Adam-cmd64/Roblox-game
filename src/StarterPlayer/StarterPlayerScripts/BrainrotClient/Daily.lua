-- ModuleScript client : RÉCOMPENSES QUOTIDIENNES + MINERAIS.
--   - le coffre doré dans le monde (couvercle qui s'ouvre, cristaux qui tournent, panneau "dispo !")
--   - on entre dans la zone jaune : le menu des 7 jours s'ouvre
--   - la fenêtre "Minerais" : choisir un minerai puis le brainrot qui le reçoit
--   - le grand message quand on trouve un minerai (coffre de la mine, récompense...)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local mineralsFolder = player:WaitForChild("Minerals")
local brainrots = player:WaitForChild("Brainrots")

local Daily = {}
local REWARDS = GameConfig.DAILY.Rewards

local function state()
	return GameConfig.getDailyState(player:GetAttribute("DailyStreak"), player:GetAttribute("DailyLast"), os.time())
end

local function clear(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIGridLayout") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

-- Une gemme dessinée (losange avec reflets) : l'icône des minerais
function Daily.gemIcon(parent, color, size, position)
	local holder = Instance.new("Frame")
	holder.Name = "Gem"
	holder.BackgroundTransparency = 1
	holder.Size = size
	holder.Position = position or UDim2.new()
	holder.Parent = parent
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = holder
	local gem = Instance.new("Frame")
	gem.AnchorPoint = Vector2.new(0.5, 0.5)
	gem.Position = UDim2.new(0.5, 0, 0.5, 0)
	gem.Size = UDim2.new(0.68, 0, 0.68, 0)
	gem.Rotation = 45
	gem.BackgroundColor3 = Color3.new(1, 1, 1)
	gem.BorderSizePixel = 0
	gem.Parent = holder
	UIKit.corner(gem, 6)
	UIKit.gradient(gem, color:Lerp(Color3.new(1, 1, 1), 0.55), color:Lerp(Color3.new(0, 0, 0), 0.35), 45)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.6)
	stroke.Parent = gem
	local facet = Instance.new("Frame")
	facet.AnchorPoint = Vector2.new(0.5, 0.5)
	facet.Position = UDim2.new(0.5, 0, 0.5, 0)
	facet.Size = UDim2.new(0.5, 0, 0.5, 0)
	facet.BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.25)
	facet.BorderSizePixel = 0
	facet.Parent = gem
	UIKit.corner(facet, 4)
	local shine = Instance.new("Frame")
	shine.Position = UDim2.new(0.12, 0, 0.12, 0)
	shine.Size = UDim2.new(0.22, 0, 0.22, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.15
	shine.BorderSizePixel = 0
	shine.Parent = gem
	UIKit.corner(shine, 4)
	return holder
end

-- ============================================================
-- LE MENU DES 7 JOURS
-- ============================================================
local window = UIKit.window("Récompenses du jour", UDim2.new(0, 1040, 0, 560), Color3.fromRGB(255, 170, 40))
Daily.window = window
local content = window.content

local streakLabel = UIKit.label(content, "", {Size = UDim2.new(0.5, 0, 0, 34), Position = UDim2.new(0, 0, 0, 2), Font = UIKit.TitleFont, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 150, 60)})
local timerLabel = UIKit.label(content, "", {Size = UDim2.new(0.5, 0, 0, 34), Position = UDim2.new(0.5, 0, 0, 2), Font = UIKit.TitleFont, TextXAlignment = Enum.TextXAlignment.Right})

local row = Instance.new("Frame")
row.Name = "Days"
row.Size = UDim2.new(1, 0, 0, 300)
row.Position = UDim2.new(0, 0, 0, 48)
row.BackgroundTransparency = 1
row.Parent = content
local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
rowLayout.Padding = UDim.new(0, 10)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = row

local claimButton = UIKit.button(content, "RÉCUPÉRER !", T.Green, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 368),
	Size = UDim2.new(0, 380, 0, 62),
})
claimButton.Name = "ClaimButton"
UIKit.label(content, "Reviens chaque jour ! Si tu attends plus de 48 h, ta série repart au jour 1.", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 1, -26),
	TextColor3 = T.SubText,
})

local cards = {} -- cards[day] = {frame, stroke, status, scale}
local pulses = {}

local function rewardIcon(parent, reward, big)
	local size = big and UDim2.new(0, 110, 0, 110) or UDim2.new(0, 78, 0, 78)
	local position = UDim2.new(0.5, 0, 0, big and 50 or 44)
	if reward.Mineral then
		local mineral = GameConfig.getMineral(reward.Mineral)
		local gem = Daily.gemIcon(parent, mineral.Color, size)
		gem.AnchorPoint = Vector2.new(0.5, 0)
		gem.Position = position
		return gem
	end
	return UIKit.label(parent, reward.Icon, {AnchorPoint = Vector2.new(0.5, 0), Position = position, Size = size, Font = Enum.Font.GothamBold})
end

local function buildCards()
	clear(row)
	table.clear(cards)
	table.clear(pulses)
	for day, reward in ipairs(REWARDS) do
		local big = day == #REWARDS
		local card = Instance.new("Frame")
		card.Name = "Day" .. day
		card.LayoutOrder = day
		card.Size = big and UDim2.new(0, 190, 0, 290) or UDim2.new(0, 116, 0, 236)
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		card.BorderSizePixel = 0
		card.Parent = row
		UIKit.corner(card, 16)
		UIKit.gradient(card, reward.Color:Lerp(Color3.new(1, 1, 1), 0.15), reward.Color:Lerp(Color3.new(0, 0, 0), 0.55), 90)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = big and 5 or 3
		stroke.Color = Color3.fromRGB(20, 15, 30)
		stroke.Parent = card
		if big then
			-- bord arc-en-ciel qui tourne pour le jour 7
			local rainbow = Instance.new("UIGradient")
			rainbow.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 230, 255)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 120, 230)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 220, 90)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 230, 255)),
			})
			rainbow.Parent = stroke
			stroke.Color = Color3.new(1, 1, 1)
			table.insert(pulses, {gradient = rainbow})
		end
		local scale = Instance.new("UIScale")
		scale.Parent = card
		UIKit.label(card, "JOUR " .. day, {Size = UDim2.new(1, 0, 0, big and 36 or 28), Position = UDim2.new(0, 0, 0, 8), Font = UIKit.TitleFont})
		rewardIcon(card, reward, big)
		UIKit.label(card, reward.Name, {
			Size = UDim2.new(0.9, 0, 0, big and 52 or 44),
			Position = UDim2.new(0.05, 0, 0, big and 172 or 130),
			TextWrapped = true,
			Font = UIKit.Font,
		})
		local status = UIKit.label(card, "", {
			AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.new(0.9, 0, 0, 30),
			Position = UDim2.new(0.5, 0, 1, -8),
			Font = UIKit.TitleFont,
		})
		status.Name = "Status"
		local shade = Instance.new("Frame")
		shade.Name = "Shade"
		shade.Size = UDim2.new(1, 0, 1, 0)
		shade.BackgroundColor3 = Color3.new(0, 0, 0)
		shade.BackgroundTransparency = 1
		shade.ZIndex = 5
		shade.Parent = card
		UIKit.corner(shade, 16)
		cards[day] = {frame = card, stroke = stroke, status = status, scale = scale, shade = shade, big = big}
	end
end

local function refresh()
	if not window.isOpen() then return end
	local day, wait, streak = state()
	-- jours déjà pris dans la semaine en cours
	local claimed = wait > 0 and (((streak - 1) % #REWARDS) + 1) or (streak % #REWARDS)
	streakLabel.Text = "🔥 Série : " .. streak .. " jour" .. (streak > 1 and "s" or "")
	if wait > 0 then
		timerLabel.Text = "⏳ Prochaine dans " .. GameConfig.formatTime(wait)
		timerLabel.TextColor3 = T.SubText
		claimButton.Text = GameConfig.formatTime(wait)
		UIKit.setButtonColor(claimButton, T.Gray)
	else
		timerLabel.Text = "✅ Ta récompense est prête !"
		timerLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
		claimButton.Text = "RÉCUPÉRER !"
		UIKit.setButtonColor(claimButton, T.Green)
	end
	for d, card in pairs(cards) do
		local isToday = d == day and wait <= 0
		local isTaken = d <= claimed and not isToday
		card.shade.BackgroundTransparency = isTaken and 0.45 or ((isToday or d == day) and 1 or 0.25)
		card.status.Text = isTaken and "✔ PRIS" or (isToday and "AUJOURD'HUI" or (d == day and "DEMAIN" or "🔒"))
		card.status.TextColor3 = isTaken and Color3.fromRGB(120, 255, 140) or (isToday and Color3.fromRGB(255, 230, 90) or Color3.new(1, 1, 1))
		card.today = isToday
		if not card.big then
			card.stroke.Color = isToday and Color3.fromRGB(255, 230, 90) or Color3.fromRGB(20, 15, 30)
		end
	end
end

window.onOpen = function()
	buildCards()
	refresh()
	-- les cartes arrivent une par une
	for day, card in pairs(cards) do
		card.scale.Scale = 0.2
		TweenService:Create(card.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, day * 0.05), {Scale = 1}):Play()
	end
end

claimButton.MouseButton1Click:Connect(function()
	Remotes.ClaimDaily:FireServer()
end)

-- ============================================================
-- LA FENÊTRE DES MINERAIS
-- ============================================================
local minerals = UIKit.window("Minerais", UDim2.new(0, 980, 0, 600), T.Purple)
Daily.minerals = minerals
local mc = minerals.content
local selected = nil

local chipRow = Instance.new("Frame")
chipRow.Size = UDim2.new(1, 0, 0, 120)
chipRow.BackgroundTransparency = 1
chipRow.Parent = mc
local chipLayout = Instance.new("UIListLayout")
chipLayout.FillDirection = Enum.FillDirection.Horizontal
chipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
chipLayout.Padding = UDim.new(0, 10)
chipLayout.SortOrder = Enum.SortOrder.LayoutOrder
chipLayout.Parent = chipRow

local hint = UIKit.label(mc, "", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 128), Font = UIKit.TitleFont, TextColor3 = Color3.fromRGB(255, 230, 120)})
local grid = UIKit.scrollGrid(mc, UDim2.new(0, 132, 0, 262), {Size = UDim2.new(1, 0, 1, -166), Position = UDim2.new(0, 0, 0, 166)})

local renderMinerals

local function chip(mineral, order)
	local count = mineralsFolder:FindFirstChild(mineral.Id)
	local amount = count and count.Value or 0
	local button = Instance.new("TextButton")
	button.Name = "Chip_" .. mineral.Id
	button.Text = ""
	button.AutoButtonColor = false
	button.LayoutOrder = order
	button.Size = UDim2.new(0, 176, 0, 116)
	button.BackgroundColor3 = Color3.fromRGB(30, 22, 50)
	button.Parent = chipRow
	UIKit.corner(button, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = selected == mineral.Id and 4 or 2
	stroke.Color = selected == mineral.Id and Color3.fromRGB(255, 230, 90) or mineral.Color:Lerp(Color3.new(0, 0, 0), 0.3)
	stroke.Parent = button
	Daily.gemIcon(button, mineral.Color, UDim2.new(0, 64, 0, 64), UDim2.new(0, 6, 0, 8))
	UIKit.label(button, "◆ " .. mineral.Name, {Size = UDim2.new(0, 100, 0, 30), Position = UDim2.new(0, 70, 0, 10), TextXAlignment = Enum.TextXAlignment.Left, Font = UIKit.TitleFont, TextColor3 = mineral.Color:Lerp(Color3.new(1, 1, 1), 0.3)})
	UIKit.label(button, "+" .. math.floor(mineral.Boost * 100) .. " % $", {Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(0, 70, 0, 42), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(120, 255, 140)})
	UIKit.label(button, "x" .. amount, {Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 0, 80), Font = UIKit.TitleFont, TextColor3 = amount > 0 and Color3.new(1, 1, 1) or T.Gray})
	button.MouseButton1Click:Connect(function()
		Sounds.play("Click")
		selected = mineral.Id
		renderMinerals()
	end)
end

local mineralLimit = 40
renderMinerals = function()
	if not minerals.isOpen() then return end
	clear(chipRow)
	for order, mineral in ipairs(GameConfig.MINERALS) do
		chip(mineral, order)
	end
	clear(grid)
	local mineral, rank = GameConfig.getMineral(selected)
	if not mineral then
		hint.Text = "Choisis un minerai, puis le brainrot qui va le recevoir"
		return
	end
	local count = mineralsFolder:FindFirstChild(mineral.Id)
	local amount = count and count.Value or 0
	hint.Text = amount > 0 and ("◆ " .. mineral.Name .. " (+" .. math.floor(mineral.Boost * 100) .. " % pour toujours) : à qui le donner ?") or ("Tu n'as pas de minerai " .. mineral.Name .. " : casse des COFFRES dans la mine !")
	local items = {}
	for _, item in ipairs(brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) >= 0 and not item:GetAttribute("OnGround") then
			table.insert(items, item)
		end
	end
	table.sort(items, GameConfig.compareItems) -- la rareté la plus haute d'abord
	for order, item in ipairs(items) do
		if order > mineralLimit then
			-- pas tout d'un coup (sinon ça lague avec beaucoup de cartes)
			local more = UIKit.button(grid, "AFFICHER PLUS (" .. (#items - mineralLimit) .. ")", T.Blue, {Name = "ShowMore", LayoutOrder = order})
			more.MouseButton1Click:Connect(function()
				mineralLimit += 40
				renderMinerals()
			end)
			break
		end
		local tile = Instance.new("Frame")
		tile.BackgroundTransparency = 1
		tile.LayoutOrder = order
		tile.Parent = grid
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 200)
		holder.BackgroundTransparency = 1
		holder.Parent = tile
		CardRenderer.createFitted(item.Value, item:GetAttribute("Mutation"), holder, item:GetAttribute("Serial"), GameConfig.getFusion(item))
		local current, currentRank = GameConfig.getMineral(item:GetAttribute("Mineral"))
		UIKit.label(tile, current and ("◆ " .. current.Name) or "sans minerai", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 202), TextColor3 = current and current.Color or T.SubText})
		local canGive = amount > 0 and currentRank < rank
		local give = UIKit.button(tile, canGive and "DONNER" or (currentRank >= rank and "DÉJÀ" or "---"), canGive and T.Green or T.Gray, {Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 226)})
		give.MouseButton1Click:Connect(function()
			if not canGive then return end
			Remotes.ApplyMineral:FireServer(item.Name, mineral.Id)
		end)
	end
end
minerals.onOpen = function()
	mineralLimit = 40
	if not selected then
		for _, mineral in ipairs(GameConfig.MINERALS) do
			local count = mineralsFolder:FindFirstChild(mineral.Id)
			if count and count.Value > 0 then
				selected = mineral.Id
			end
		end
	end
	renderMinerals()
end

-- ============================================================
-- GRAND MESSAGE : MINERAI TROUVÉ
-- ============================================================
function Daily.showMineral(mineralId, source)
	local mineral = GameConfig.getMineral(mineralId)
	if not mineral then return end
	Sounds.play("RareCard")
	local frame = Instance.new("Frame")
	frame.Name = "MineralPopup"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.4, 0)
	frame.Size = UDim2.new(0, 460, 0, 250)
	frame.BackgroundColor3 = Color3.fromRGB(25, 18, 45)
	frame.BackgroundTransparency = 0.1
	frame.ZIndex = 45
	frame.Parent = UIKit.ScreenGui
	UIKit.corner(frame, 22)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = mineral.Color
	stroke.Parent = frame
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = frame
	UIKit.label(frame, source == "chest" and "📦 COFFRE OUVERT !" or (source == "vip" and "👑 BIENVENUE VIP !" or "🎁 CADEAU !"), {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 0, 12), Font = UIKit.TitleFont, TextColor3 = Color3.fromRGB(255, 220, 90), ZIndex = 46})
	local gem = Daily.gemIcon(frame, mineral.Color, UDim2.new(0, 110, 0, 110), UDim2.new(0.5, -55, 0, 58))
	gem.ZIndex = 46
	UIKit.label(frame, "◆ Minerai " .. mineral.Name .. "  (+" .. math.floor(mineral.Boost * 100) .. " % $)", {Size = UDim2.new(0.92, 0, 0, 34), Position = UDim2.new(0.04, 0, 0, 176), Font = UIKit.TitleFont, TextColor3 = mineral.Color:Lerp(Color3.new(1, 1, 1), 0.3), ZIndex = 46})
	UIKit.label(frame, "Donne-le à un brainrot : Sac → MINERAIS", {Size = UDim2.new(0.92, 0, 0, 22), Position = UDim2.new(0.04, 0, 0, 214), TextColor3 = T.SubText, ZIndex = 46})
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = UIKit.fitFactor(460, 250, 0.9)}):Play()
	local spin = RunService.RenderStepped:Connect(function()
		gem.Rotation = math.sin(os.clock() * 3) * 12
	end)
	task.delay(2.8, function()
		spin:Disconnect()
		TweenService:Create(scale, TweenInfo.new(0.25), {Scale = 0}):Play()
		Debris:AddItem(frame, 0.3)
	end)
end

-- ============================================================
-- GAINS HORS-LIGNE : "Pendant ton absence, ta base t'a rapporté..."
-- ============================================================
function Daily.showOffline(amount, seconds)
	local frame = Instance.new("Frame")
	frame.Name = "OfflinePopup"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.45, 0)
	frame.Size = UDim2.new(0, 480, 0, 230)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.ZIndex = 44
	frame.Parent = UIKit.ScreenGui
	UIKit.corner(frame, 22)
	UIKit.outline(frame, 4)
	UIKit.gradient(frame, Color3.fromRGB(70, 200, 110), Color3.fromRGB(20, 80, 50), 90)
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = frame
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local away = hours > 0 and (hours .. " h " .. minutes .. " min") or (minutes .. " min")
	UIKit.label(frame, "🌙 BON RETOUR !", {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 0, 12), Font = UIKit.TitleFont, TextColor3 = Color3.fromRGB(255, 230, 110), ZIndex = 45})
	UIKit.label(frame, "Pendant ton absence (" .. away .. "), ta base t'a rapporté :", {Size = UDim2.new(0.92, 0, 0, 26), Position = UDim2.new(0.04, 0, 0, 60), ZIndex = 45, TextWrapped = true})
	UIKit.label(frame, "+$" .. GameConfig.format(amount), {Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 92), Font = UIKit.TitleFont, TextColor3 = Color3.fromRGB(120, 255, 140), ZIndex = 45})
	local ok = UIKit.button(frame, "SUPER !", T.Gold, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(0, 200, 0, 48), ZIndex = 45})
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = UIKit.fitFactor(480, 230, 0.9)}):Play()
	Sounds.play("Coin")
	ok.MouseButton1Click:Connect(function()
		frame:Destroy()
	end)
	task.delay(10, function()
		if frame.Parent then
			frame:Destroy()
		end
	end)
end

-- ============================================================
-- LE CADEAU DE DÉPART (coffre doré) : favori + like => carte Très Rare + argent
-- ============================================================
local starter = UIKit.window("Cadeau de départ", UDim2.new(0, 760, 0, 520), Color3.fromRGB(0, 190, 170))
Daily.starter = starter
local sc = starter.content
local favorited, liked = false, false

UIKit.label(sc, "🎁 Ton cadeau de bienvenue !", {Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 4), Font = UIKit.TitleFont, TextColor3 = Color3.fromRGB(255, 230, 110)})

-- les 2 cadeaux
local giftRow = Instance.new("Frame")
giftRow.Size = UDim2.new(1, 0, 0, 150)
giftRow.Position = UDim2.new(0, 0, 0, 52)
giftRow.BackgroundTransparency = 1
giftRow.Parent = sc
local giftLayout = Instance.new("UIListLayout")
giftLayout.FillDirection = Enum.FillDirection.Horizontal
giftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
giftLayout.Padding = UDim.new(0, 18)
giftLayout.Parent = giftRow
local rarityColor = GameConfig.RARITIES[GameConfig.STARTER.Rarity].Color
for _, gift in ipairs({
	{"🃏", "1 carte " .. GameConfig.STARTER.Rarity, "au hasard !", rarityColor},
	{"💰", "$" .. GameConfig.format(GameConfig.STARTER.Cash), "pour bien commencer", Color3.fromRGB(80, 210, 90)},
}) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 250, 1, 0)
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.Parent = giftRow
	UIKit.corner(card, 18)
	UIKit.gradient(card, gift[4]:Lerp(Color3.new(1, 1, 1), 0.1), gift[4]:Lerp(Color3.new(0, 0, 0), 0.55), 90)
	UIKit.outline(card, 3)
	UIKit.label(card, gift[1], {Size = UDim2.new(1, 0, 0, 64), Position = UDim2.new(0, 0, 0, 10), Font = Enum.Font.GothamBold})
	UIKit.label(card, gift[2], {Size = UDim2.new(0.9, 0, 0, 34), Position = UDim2.new(0.05, 0, 0, 78), Font = UIKit.TitleFont})
	UIKit.label(card, gift[3], {Size = UDim2.new(0.9, 0, 0, 24), Position = UDim2.new(0.05, 0, 0, 114), TextColor3 = T.SubText})
end

-- les 2 étapes
UIKit.label(sc, "Pour le récupérer :", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 214), Font = UIKit.TitleFont})
local favoriteButton = UIKit.button(sc, "⭐ 1. METTRE EN FAVORI", T.Gold, {Size = UDim2.new(0, 330, 0, 54), Position = UDim2.new(0.5, -340, 0, 250)})
favoriteButton.Name = "FavoriteButton"
local likeButton = UIKit.button(sc, "👍 2. J'AI MIS UN LIKE", T.Blue, {Size = UDim2.new(0, 330, 0, 54), Position = UDim2.new(0.5, 10, 0, 250)})
likeButton.Name = "LikeButton"
UIKit.label(sc, "Le like : clique sur 👍 sur la page du jeu Roblox (sous le bouton Jouer), puis sur ce bouton.", {
	Size = UDim2.new(1, 0, 0, 22),
	Position = UDim2.new(0, 0, 0, 312),
	TextColor3 = T.SubText,
	TextWrapped = true,
})
local openButton = UIKit.button(sc, "RÉCUPÉRER MON CADEAU !", T.Gray, {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 400, 0, 64), Position = UDim2.new(0.5, 0, 0, 350)})
openButton.Name = "OpenStarterButton"

local function refreshStarter()
	local claimed = player:GetAttribute("StarterClaimed") == true
	favoriteButton.Text = favorited and "⭐ FAVORI ✔" or "⭐ 1. METTRE EN FAVORI"
	UIKit.setButtonColor(favoriteButton, favorited and T.Green or T.Gold)
	likeButton.Text = liked and "👍 LIKE ✔" or "👍 2. J'AI MIS UN LIKE"
	UIKit.setButtonColor(likeButton, liked and T.Green or T.Blue)
	if claimed then
		openButton.Text = "✔ DÉJÀ OUVERT"
		UIKit.setButtonColor(openButton, T.Gray)
	else
		openButton.Text = "RÉCUPÉRER MON CADEAU !"
		UIKit.setButtonColor(openButton, (favorited and liked) and T.Green or T.Gray)
	end
end

-- Le favori : Roblox affiche sa fenêtre "Ajouter aux favoris" et nous dit si c'est fait
local function avatarEditor()
	local ok, service = pcall(function()
		return game:GetService("AvatarEditorService")
	end)
	return ok and service or nil
end

local function checkFavorite()
	local service = avatarEditor()
	if not service or game.PlaceId == 0 then return end
	local ok, result = pcall(function()
		return service:GetFavorite(game.PlaceId, Enum.AvatarItemType.Asset)
	end)
	if ok and result == true then
		favorited = true
		refreshStarter()
	end
end

favoriteButton.MouseButton1Click:Connect(function()
	if favorited then return end
	local service = avatarEditor()
	if game.PlaceId == 0 or not service then
		favorited = true -- dans Studio (jeu pas publié), on ne peut pas mettre en favori : on valide
		refreshStarter()
		return
	end
	pcall(function()
		service:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
end)
likeButton.MouseButton1Click:Connect(function()
	liked = true
	Sounds.play("Click")
	refreshStarter()
end)
openButton.MouseButton1Click:Connect(function()
	if player:GetAttribute("StarterClaimed") or not (favorited and liked) then return end
	Remotes.ClaimStarter:FireServer(favorited, liked)
end)
starter.onOpen = function()
	refreshStarter()
	task.spawn(checkFavorite)
end
player:GetAttributeChangedSignal("StarterClaimed"):Connect(refreshStarter)
do
	local service = avatarEditor()
	if service then
		pcall(function()
			service.PromptSetFavoriteCompleted:Connect(function(result)
				if result == Enum.AvatarPromptResult.Success then
					favorited = true
					refreshStarter()
				else
					task.spawn(checkFavorite)
				end
			end)
		end)
	end
end

-- ============================================================
-- LE COFFRE DORÉ DANS LE MONDE (cadeau de départ, voir StarterChest.lua côté serveur)
-- ============================================================
local function setupChest()
	local chest = Workspace:WaitForChild("StarterChest", 30)
	if not chest then return end
	local center = chest:GetAttribute("Center")
	local lidBase = chest:GetAttribute("LidCFrame")
	local radius = chest:GetAttribute("Radius") or GameConfig.STARTER.ZoneRadius
	local lid = chest:WaitForChild("Lid", 10)
	if not center then return end
	-- le couvercle : on retient la place de chaque pièce par rapport à la charnière (quand elles sont toutes là)
	local lidParts, lidOffsets = {}, {}
	local deadline = os.clock() + 15
	while lid and os.clock() < deadline do
		local parts = {}
		for _, part in ipairs(lid:GetDescendants()) do
			if part:IsA("BasePart") then
				table.insert(parts, part)
			end
		end
		if #parts >= (chest:GetAttribute("LidParts") or 0) then
			for _, part in ipairs(parts) do
				table.insert(lidParts, part)
				table.insert(lidOffsets, lidBase:ToObjectSpace(part.CFrame))
			end
			break
		end
		task.wait(0.2)
	end
	local orbit, zone = {}, nil
	for _, part in ipairs(chest:GetChildren()) do
		if part:IsA("BasePart") and part.Name == "OrbitCrystal" then
			table.insert(orbit, {part = part, angle = part:GetAttribute("Angle") or 0, y = part.Position.Y})
		elseif part:IsA("BasePart") and part.Name == "Zone" then
			zone = part
		end
	end
	local sign = chest:FindFirstChild("Sign")
	local info = sign and sign:FindFirstChild("DailyInfo")
	local statusLabel = info and info:FindFirstChild("Status")
	local lidOpen = 0

	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local camera = workspace.CurrentCamera
		if camera and (camera.CFrame.Position - center).Magnitude > 250 then return end
		-- couvercle : s'ouvre quand le menu est ouvert (et bouge un peu tant que le cadeau n'est pas pris)
		local claimed = player:GetAttribute("StarterClaimed") == true
		local target = starter.isOpen() and 1 or (not claimed and 0.18 + math.sin(t * 4) * 0.08 or 0)
		lidOpen += (target - lidOpen) * math.clamp((dt or 0) * 8, 0, 1)
		if lidBase and #lidParts > 0 then
			local hinge = lidBase * CFrame.Angles(math.rad(75 * lidOpen), 0, 0)
			for i, part in ipairs(lidParts) do
				part.CFrame = hinge * lidOffsets[i]
			end
		end
		for _, entry in ipairs(orbit) do
			local angle = math.rad(entry.angle) + t * 0.9
			entry.part.CFrame = CFrame.new(center.X + math.cos(angle) * 4.2, entry.y + math.sin(t * 2 + entry.angle) * 0.4, center.Z + math.sin(angle) * 4.2) * CFrame.Angles(0, t * 2, 0)
		end
		if zone then
			zone.Transparency = 0.55 + math.sin(t * 3) * 0.15
		end
	end)

	-- entrer dans la zone jaune = ouvrir le menu du cadeau
	local inZone = false
	task.spawn(function()
		while true do
			task.wait(0.25)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local now = false
			if root then
				local offset = root.Position - center
				now = Vector2.new(offset.X, offset.Z).Magnitude <= radius and math.abs(offset.Y) < 10
			end
			if now and not inZone then
				starter.open()
			end
			inZone = now
			if statusLabel then
				local claimed = player:GetAttribute("StarterClaimed") == true
				statusLabel.Text = claimed and "✔ Déjà ouvert" or "⭐ Favori + 👍 Like = cadeau !"
				statusLabel.TextColor3 = claimed and Color3.fromRGB(200, 200, 210) or Color3.fromRGB(120, 255, 140)
			end
		end
	end)
end

function Daily.init(Hud)
	task.spawn(setupChest)
	Remotes.OpenDaily.OnClientEvent:Connect(window.open)
	Remotes.OpenStarter.OnClientEvent:Connect(starter.open)
	Remotes.MineralFound.OnClientEvent:Connect(Daily.showMineral)
	Remotes.OfflineEarnings.OnClientEvent:Connect(Daily.showOffline)
	Remotes.DailyResult.OnClientEvent:Connect(function(day, details)
		local reward = REWARDS[day]
		if day == 0 then
			-- cadeau de départ : argent + carte Très Rare
			starter.close()
			Hud.notify("🎁 Cadeau de départ : +$" .. GameConfig.format(details.Cash or 0) .. " !", "success")
			if details.Card then
				Hud.showCardFound(details.Card, details.Mutation, details.Serial)
			end
			return
		end
		if details.Cash then
			Hud.notify("🎁 Jour " .. day .. " : +$" .. GameConfig.format(details.Cash) .. " !", "success")
		elseif details.Card then
			Hud.showCardFound(details.Card, details.Mutation, details.Serial)
		elseif reward and not details.Mineral then
			Hud.notify("🎁 Jour " .. day .. " : " .. reward.Name .. " !", "success")
		end
		refresh()
	end)
	for _, attribute in ipairs({"DailyStreak", "DailyLast"}) do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	local function watchCounts()
		if minerals.isOpen() then renderMinerals() end
	end
	for _, value in ipairs(mineralsFolder:GetChildren()) do
		value.Changed:Connect(watchCounts)
	end
	brainrots.ChildAdded:Connect(watchCounts)
	brainrots.ChildRemoved:Connect(watchCounts)
	local function watchItem(item)
		item:GetAttributeChangedSignal("Mineral"):Connect(watchCounts)
	end
	for _, item in ipairs(brainrots:GetChildren()) do
		watchItem(item)
	end
	brainrots.ChildAdded:Connect(watchItem)
	-- en arrivant dans le jeu : le pop-up des récompenses s'ouvre tout seul s'il y en a une à prendre
	task.delay(3, function()
		local _, wait = state()
		if wait <= 0 and not window.isOpen() then
			window.open()
		end
	end)
	-- le chrono du menu
	task.spawn(function()
		while true do
			task.wait(1)
			refresh()
			for _, pulse in ipairs(pulses) do
				pulse.gradient.Rotation = (pulse.gradient.Rotation + 30) % 360
			end
			for _, card in pairs(cards) do
				if card.today then
					TweenService:Create(card.scale, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Scale = card.scale.Scale > 1.02 and 1 or 1.06}):Play()
				end
			end
		end
	end)
end

return Daily
