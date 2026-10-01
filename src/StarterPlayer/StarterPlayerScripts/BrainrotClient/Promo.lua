-- ModuleScript client : rendre les premières minutes ACCROCHANTES.
--   - écran de BIENVENUE pour les nouveaux joueurs (titre animé, confettis, « BOOST DÉBUTANT x2 activé »)
--   - pastille 🚀 BOOST DÉBUTANT x2 avec le temps qui reste (GameConfig.STARTER_BOOST)
--   - CONFETTIS : premier brainrot, carte Légendaire et +, nouvelle pioche, rebirth
--   - POP-UPS D'OFFRES sur le côté de l'écran (game pass / produits Robux) : ils glissent, brillent,
--     et disparaissent tout seuls. Les prix barrés sont de VRAIS prix (le pack VIP vaut la somme de ce
--     qu'il contient, 10 tours de roue = 10 x le prix d'un tour) : jamais de faux prix.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Promo = {}

local FIRST_OFFER = 75 -- secondes avant le 1er pop-up
local OFFER_EVERY = 240 -- puis un pop-up toutes les 4 minutes
local OFFER_DURATION = 14 -- il reste affiché 14 secondes

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotPromo"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
Promo.Gui = gui

local function tween(object, time, props, style, direction)
	local t = TweenService:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- ============================================================
-- CONFETTIS
-- ============================================================
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 230, 120),
	Color3.fromRGB(70, 200, 255), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 255, 255),
}
function Promo.confetti(count)
	local holder = Instance.new("Frame")
	holder.Name = "Confetti"
	holder.Size = UDim2.new(1, 0, 1, 0)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 60
	holder.Parent = gui
	for _ = 1, count or 70 do
		local piece = Instance.new("Frame")
		piece.Name = "Piece"
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		local x = math.random()
		piece.Position = UDim2.new(x, 0, -0.05, 0)
		local w = math.random(8, 16)
		piece.Size = UDim2.new(0, w, 0, math.floor(w * 0.55))
		piece.Rotation = math.random(0, 360)
		piece.BackgroundColor3 = CONFETTI_COLORS[math.random(1, #CONFETTI_COLORS)]
		piece.BorderSizePixel = 0
		piece.ZIndex = 60
		piece.Parent = holder
		local duration = 1.6 + math.random() * 1.4
		tween(piece, duration, {
			Position = UDim2.new(x + (math.random() - 0.5) * 0.25, 0, 1.05, 0),
			Rotation = piece.Rotation + math.random(-540, 540),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	task.delay(3.2, function()
		holder:Destroy()
	end)
end

-- ============================================================
-- LES OFFRES (ce qui s'affiche dans les pop-ups)
-- ============================================================
local passes, products = GameConfig.GAMEPASSES, GameConfig.PRODUCTS
local OFFERS = {
	{Key = "VIP", Icon = "👑", Title = "PACK VIP", Pitch = "Argent x2 + Tapis volant + Collecte auto + 2 minerais",
		Price = passes.VIP.Price, Old = GameConfig.getVipValue(), Badge = "MEILLEURE OFFRE", Color = Color3.fromRGB(255, 190, 40)},
	{Key = "DoubleCash", Icon = "💰", Title = "ARGENT x2", Pitch = "Tout ton argent x2, pour toujours !",
		Price = passes.DoubleCash.Price, Badge = "⭐ LE PLUS ACHETÉ", Color = Color3.fromRGB(70, 210, 90)},
	{Key = "Spin10", Icon = "🎡", Title = "10 TOURS DE ROUE", Pitch = "Des brainrots Épiques et Légendaires à gagner !",
		Price = products.Spin10.Price, Old = products.Spin1.Price * 10, Badge = "PACK", Color = Color3.fromRGB(255, 110, 200)},
	{Key = "AutoCollect", Icon = "🤖", Title = "COLLECTE AUTO", Pitch = "L'argent de ta base arrive tout seul !",
		Price = passes.AutoCollect.Price, Badge = "🔥 PRATIQUE", Color = Color3.fromRGB(60, 200, 255)},
	{Key = "LuckPotion", Icon = "🍀", Title = "POTION CHANCE x2", Pitch = "15 min : les brainrots rares sortent 2x plus !",
		Price = products.LuckPotion.Price, Badge = "⚡ BOOST", Color = Color3.fromRGB(90, 230, 160)},
	{Key = "FlyingCarpet", Icon = "🧞", Title = "TAPIS VOLANT", Pitch = "Vole partout, 2,5x plus vite !",
		Price = passes.FlyingCarpet.Price, Badge = "✨ STYLÉ", Color = Color3.fromRGB(170, 110, 255)},
}
Promo.OFFERS = OFFERS

-- Le joueur l'a déjà ? (le VIP contient argent x2, tapis volant et collecte auto)
local function owned(offer)
	local vip = player:GetAttribute("VIP") == true
	if offer.Key == "VIP" then
		return vip
	end
	if passes[offer.Key] then
		return vip or player:GetAttribute(offer.Key) == true
	end
	return false
end

local current
local function closeOffer(frame)
	if not frame or not frame.Parent then return end
	local outside = frame:GetAttribute("FromLeft") and UDim2.new(0, -420, frame.Position.Y.Scale, 0) or UDim2.new(1, 420, frame.Position.Y.Scale, 0)
	tween(frame, 0.35, {Position = outside}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(0.4, function()
		frame:Destroy()
	end)
	if current == frame then
		current = nil
	end
end

-- Affiche un pop-up d'offre qui glisse sur le côté de l'écran
function Promo.showOffer(offer)
	if current then
		closeOffer(current)
	end
	local fromLeft = UIKit.isTouch() -- sur téléphone, le menu est à droite
	local frame = Instance.new("Frame")
	frame.Name = "OfferPopup"
	frame:SetAttribute("Offer", offer.Key)
	frame:SetAttribute("FromLeft", fromLeft)
	frame.AnchorPoint = Vector2.new(fromLeft and 0 or 1, 0.5)
	frame.Position = fromLeft and UDim2.new(0, -420, 0.42, 0) or UDim2.new(1, 420, 0.56, 0)
	frame.Size = UDim2.new(0, 330, 0, 168)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.ZIndex = 50
	frame.Parent = gui
	current = frame
	UIKit.corner(frame, 20)
	UIKit.gradient(frame, offer.Color:Lerp(Color3.fromRGB(20, 16, 40), 0.35), Color3.fromRGB(16, 12, 34), 90)
	local scale = Instance.new("UIScale")
	scale.Scale = math.max(0.6, UIKit.hudFactor())
	scale.Parent = frame
	-- contour qui tourne
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3.5
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = frame
	local strokeGradient = Instance.new("UIGradient")
	strokeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, offer.Color),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, offer.Color),
	})
	strokeGradient.Parent = stroke
	CollectionService:AddTag(strokeGradient, "SpinGradient")
	-- reflet qui traverse le pop-up
	local glint = Instance.new("Frame")
	glint.Name = "Glint"
	glint.Size = UDim2.new(1, 0, 1, 0)
	glint.BackgroundColor3 = Color3.new(1, 1, 1)
	glint.BackgroundTransparency = 0.5
	glint.BorderSizePixel = 0
	glint.ZIndex = 50
	glint.Parent = frame
	UIKit.corner(glint, 20)
	local glintGradient = Instance.new("UIGradient")
	glintGradient.Rotation = 25
	glintGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.44, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.56, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	glintGradient.Parent = glint
	CollectionService:AddTag(glintGradient, "HoloShine")

	-- ruban "OFFRE" en haut
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Badge"
	ribbon.AnchorPoint = Vector2.new(0.5, 0.5)
	ribbon.Position = UDim2.new(0.5, 0, 0, 0)
	ribbon.Size = UDim2.new(0, 190, 0, 30)
	ribbon.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
	ribbon.BorderSizePixel = 0
	ribbon.ZIndex = 53
	ribbon.Parent = frame
	UIKit.corner(ribbon, 15)
	UIKit.outline(ribbon, 2.5)
	UIKit.label(ribbon, offer.Badge, {Size = UDim2.new(1, -14, 1, -6), Position = UDim2.new(0, 7, 0, 3), Font = UIKit.TitleFont, ZIndex = 54})

	-- grosse icône qui bouge
	local icon = UIKit.label(frame, offer.Icon, {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 56, 0, 70),
		Size = UDim2.new(0, 84, 0, 84),
		Font = Enum.Font.GothamBold,
		ZIndex = 52,
	})
	task.spawn(function()
		local start = os.clock()
		while icon.Parent do
			local t = os.clock() - start
			icon.Rotation = math.sin(t * 3) * 10
			icon.Position = UDim2.new(0, 56, 0, 70 + math.sin(t * 2.2) * 4)
			task.wait(1 / 30)
		end
	end)
	UIKit.label(frame, offer.Title, {
		Name = "Title",
		Position = UDim2.new(0, 108, 0, 22),
		Size = UDim2.new(1, -150, 0, 34),
		Font = UIKit.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
	})
	UIKit.label(frame, offer.Pitch, {
		Name = "Pitch",
		Position = UDim2.new(0, 108, 0, 56),
		Size = UDim2.new(1, -118, 0, 34),
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(230, 225, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
	})
	-- le prix : (vrai prix barré si c'est un pack) + le prix
	if offer.Old and offer.Old > offer.Price then
		local old = UIKit.label(frame, "<s>" .. offer.Old .. " R$</s>", {
			Name = "OldPrice",
			RichText = true,
			Position = UDim2.new(0, 14, 0, 116),
			Size = UDim2.new(0, 84, 0, 22),
			TextColor3 = Color3.fromRGB(255, 120, 120),
			ZIndex = 52,
		})
		old.TextTransparency = 0.1
		UIKit.label(frame, "-" .. math.floor((1 - offer.Price / offer.Old) * 100 + 0.5) .. "%", {
			Name = "Discount",
			Position = UDim2.new(0, 14, 0, 136),
			Size = UDim2.new(0, 84, 0, 22),
			Font = UIKit.TitleFont,
			TextColor3 = Color3.fromRGB(255, 230, 90),
			ZIndex = 52,
		})
	end
	local buy = UIKit.button(frame, "ACHETER  " .. offer.Price .. " R$", T.Green, {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -14),
		Size = UDim2.new(0, 200, 0, 46),
		ZIndex = 52,
	})
	buy.MouseButton1Click:Connect(function()
		Remotes.BuyProduct:FireServer(offer.Key)
		closeOffer(frame)
	end)
	-- le bouton respire pour attirer l'œil
	local buyScale = buy:FindFirstChildOfClass("UIScale")
	task.spawn(function()
		while buy.Parent do
			if buyScale then
				tween(buyScale, 0.45, {Scale = 1.07}, Enum.EasingStyle.Sine)
				task.wait(0.45)
				tween(buyScale, 0.45, {Scale = 1}, Enum.EasingStyle.Sine)
			end
			task.wait(0.5)
		end
	end)
	local close = UIKit.button(frame, "X", T.Red, {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(0, 36, 0, 36),
		ZIndex = 55,
	})
	close.MouseButton1Click:Connect(function()
		closeOffer(frame)
	end)
	-- barre de temps qui se vide
	local bar = Instance.new("Frame")
	bar.Name = "TimeBar"
	bar.Position = UDim2.new(0, 14, 1, -6)
	bar.Size = UDim2.new(1, -28, 0, 3)
	bar.BackgroundColor3 = offer.Color
	bar.BorderSizePixel = 0
	bar.ZIndex = 52
	bar.Parent = frame
	tween(bar, OFFER_DURATION, {Size = UDim2.new(0, 0, 0, 3)}, Enum.EasingStyle.Linear)

	tween(frame, 0.55, {Position = fromLeft and UDim2.new(0, 12, 0.42, 0) or UDim2.new(1, -14, 0.56, 0)}, Enum.EasingStyle.Back)
	pcall(Sounds.play, "Coin")
	task.delay(OFFER_DURATION, function()
		closeOffer(frame)
	end)
	return frame
end

-- La prochaine offre (on saute celles qu'il a déjà)
local nextIndex = 1
function Promo.nextOffer()
	for _ = 1, #OFFERS do
		local offer = OFFERS[nextIndex]
		nextIndex = nextIndex % #OFFERS + 1
		if not owned(offer) then
			return offer
		end
	end
	return nil
end

-- ============================================================
-- BIENVENUE (nouveaux joueurs) + BOOST DÉBUTANT
-- ============================================================
function Promo.welcome()
	local overlay = Instance.new("TextButton")
	overlay.Name = "Welcome"
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(10, 6, 25)
	overlay.BackgroundTransparency = 0.25
	overlay.ZIndex = 70
	overlay.Parent = gui
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.new(0.5, 0, 0.45, 0)
	box.Size = UDim2.new(0, 640, 0, 330)
	box.BackgroundTransparency = 1
	box.ZIndex = 71
	box.Parent = overlay
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = box
	local title = UIKit.label(box, "⛏️ MINE A BRAINROT ⛏️", {
		Name = "WelcomeTitle",
		Size = UDim2.new(1, 0, 0, 90),
		Font = UIKit.TitleFont,
		ZIndex = 72,
	})
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 220, 255)),
	})
	gradient.Parent = title
	CollectionService:AddTag(gradient, "RainbowGradient")
	UIKit.label(box, "Mine des blocs, trouve des brainrots rares, pose-les dans ta base et deviens le plus riche !", {
		Position = UDim2.new(0.05, 0, 0, 100),
		Size = UDim2.new(0.9, 0, 0, 60),
		TextWrapped = true,
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(230, 225, 255),
		ZIndex = 72,
	})
	local boost = UIKit.label(box, "🚀 BOOST DÉBUTANT : ARGENT x" .. GameConfig.STARTER_BOOST.Multiplier .. " pendant " .. GameConfig.STARTER_BOOST.Minutes .. " minutes !", {
		Name = "BoostText",
		Position = UDim2.new(0.05, 0, 0, 170),
		Size = UDim2.new(0.9, 0, 0, 44),
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(120, 255, 150),
		ZIndex = 72,
	})
	local play = UIKit.button(box, "▶  JOUER !", T.Green, {
		Name = "PlayButton",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 240),
		Size = UDim2.new(0, 280, 0, 70),
		ZIndex = 72,
	})
	local function close()
		if not overlay.Parent then return end
		tween(scale, 0.25, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(overlay, 0.3, {BackgroundTransparency = 1})
		task.delay(0.32, function()
			overlay:Destroy()
		end)
	end
	play.MouseButton1Click:Connect(close)
	overlay.MouseButton1Click:Connect(close)
	tween(scale, 0.6, {Scale = UIKit.fitFactor(700, 380, 0.9)}, Enum.EasingStyle.Back)
	task.spawn(function()
		while boost.Parent do
			tween(boost, 0.4, {TextTransparency = 0.25})
			task.wait(0.4)
			tween(boost, 0.4, {TextTransparency = 0})
			task.wait(0.4)
		end
	end)
	Promo.confetti(90)
	pcall(Sounds.play, "Win")
	task.delay(12, close)
	return overlay
end

-- la pastille du boost (au-dessus de l'argent)
local boostPill = Instance.new("Frame")
boostPill.Name = "StarterBoost"
boostPill.AnchorPoint = UIKit.isTouch() and Vector2.new(0, 0) or Vector2.new(0, 1)
boostPill.Position = UIKit.isTouch() and UDim2.new(0, 12, 0, 160) or UDim2.new(0, 22, 1, -150)
boostPill.Size = UDim2.new(0, 300, 0, 34)
boostPill.BackgroundColor3 = Color3.new(1, 1, 1)
boostPill.BorderSizePixel = 0
boostPill.Visible = false
boostPill.Parent = gui
UIKit.hudScale(boostPill)
UIKit.corner(boostPill, 17)
UIKit.gradient(boostPill, Color3.fromRGB(255, 120, 60), Color3.fromRGB(200, 40, 120), 0)
UIKit.outline(boostPill, 2.5, Color3.fromRGB(255, 230, 150))
local boostLabel = UIKit.label(boostPill, "", {
	Name = "BoostLabel",
	Size = UDim2.new(1, -16, 1, -8),
	Position = UDim2.new(0, 8, 0, 4),
	Font = UIKit.TitleFont,
})

function Promo.updateBoost()
	local left = GameConfig.getStarterBoostLeft(player)
	boostPill.Visible = left > 0
	if left > 0 then
		boostLabel.Text = "🚀 BOOST DÉBUTANT x" .. GameConfig.STARTER_BOOST.Multiplier .. "  •  " .. GameConfig.formatTime(left)
	end
end

function Promo.init(options)
	options = options or {}
	local stats = player:WaitForChild("leaderstats")
	local rebirths = stats:WaitForChild("Rebirths")
	local brainrots = player:WaitForChild("Brainrots")
	local pickaxeTier = player:WaitForChild("PickaxeTier")

	-- nouveau joueur : l'écran de bienvenue
	if options.Welcome ~= false and rebirths.Value == 0 and (player:GetAttribute("PlayTime") or 0) < 30 and #brainrots:GetChildren() == 0 then
		task.delay(1.5, Promo.welcome)
	end

	-- confettis aux grands moments
	local hadCards = #brainrots:GetChildren() > 0
	brainrots.ChildAdded:Connect(function()
		if not hadCards then
			hadCards = true
			Promo.confetti(80) -- son tout premier brainrot !
		end
	end)
	Remotes.CardFound.OnClientEvent:Connect(function(cardName)
		local card = GameConfig.getCard(cardName)
		local rarity = card and GameConfig.RARITIES[card.Rarity]
		if rarity and rarity.Order >= 5 then
			Promo.confetti(60 + rarity.Order * 6)
		end
	end)
	local lastTier = pickaxeTier.Value
	pickaxeTier.Changed:Connect(function(value)
		if value > lastTier then
			Promo.confetti(70)
		end
		lastTier = value
	end)
	local lastRebirths = rebirths.Value
	rebirths.Changed:Connect(function(value)
		if value > lastRebirths then
			Promo.confetti(120)
		end
		lastRebirths = value
	end)

	-- le boost débutant + les offres
	task.spawn(function()
		local waited = 0
		local nextAt = FIRST_OFFER
		while true do
			Promo.updateBoost()
			if options.Offers ~= false and waited >= nextAt then
				nextAt = waited + OFFER_EVERY
				local offer = Promo.nextOffer()
				if offer then
					Promo.showOffer(offer)
				end
			end
			task.wait(1)
			waited += 1
		end
	end)
end

return Promo
