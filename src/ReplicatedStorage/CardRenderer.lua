-- ModuleScript partagé : dessine une carte brainrot façon carte à collectionner.
-- Utilisé partout : sur les podiums de la base (SurfaceGui), dans l'inventaire, l'index,
-- la carte tenue en main, l'ouverture des boosters...
--
-- Tout est en tailles relatives (Scale), donc la carte s'adapte à n'importe quelle taille.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BrainrotModels = require(ReplicatedStorage:WaitForChild("BrainrotModels"))

local CardRenderer = {}

local function corner(parent, scale)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
	return c
end

local function gradient(parent, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function darken(color, factor)
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

local function text(parent, value, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	for key, v in pairs(props) do
		label[key] = v
	end
	label.Parent = parent
	return label
end

-- Couleurs d'une mutation (arc-en-ciel = plusieurs couleurs)
function CardRenderer.mutationSequence(mutationName)
	local mutation = GameConfig.MUTATIONS[mutationName]
	if not mutation or not mutation.Colors then return nil end
	if mutation.Rainbow then
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 40)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 255, 80)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(40, 200, 255)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(120, 80, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 200)),
		})
	end
	return ColorSequence.new(mutation.Colors[1], mutation.Colors[2])
end

-- Crée la carte. Renvoie un Frame de taille (1, 1) à placer dans un conteneur au format 5:7.
function CardRenderer.create(cardName, mutationName, parent)
	local card, cardIndex = GameConfig.getCard(cardName)
	if not card then return nil end
	local rarity = GameConfig.RARITIES[card.Rarity]
	mutationName = mutationName or "Normal"
	local mutation = GameConfig.MUTATIONS[mutationName] or GameConfig.MUTATIONS.Normal
	local mutationSeq = CardRenderer.mutationSequence(mutationName)

	-- Bordure extérieure (couleur de la rareté, ou de la mutation)
	local root = Instance.new("Frame")
	root.Name = "BrainrotCard"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.new(1, 1, 1)
	root.BorderSizePixel = 0
	corner(root, 0.05)
	local border = Instance.new("UIGradient")
	border.Color = mutationSeq or ColorSequence.new(rarity.Color, rarity.Color2)
	border.Rotation = 45
	border.Parent = root
	if mutation.Rainbow then
		CollectionService:AddTag(border, "RainbowGradient")
	end

	-- Intérieur sombre teinté de la couleur du brainrot
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Position = UDim2.new(0.035, 0, 0.025, 0)
	inner.Size = UDim2.new(0.93, 0, 0.95, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.ClipsDescendants = true
	inner.Parent = root
	corner(inner, 0.04)
	gradient(inner, darken(card.Color, 0.55), Color3.fromRGB(12, 12, 20), 90)

	-- En-tête : nom + revenu
	text(inner, card.Name, {
		Position = UDim2.new(0.04, 0, 0.012, 0),
		Size = UDim2.new(0.62, 0, 0.075, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	text(inner, "$" .. GameConfig.format(GameConfig.getItemIncome(cardName, mutationName)) .. "/s", {
		Position = UDim2.new(0.64, 0, 0.012, 0),
		Size = UDim2.new(0.33, 0, 0.075, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 225, 80),
	})

	-- Fenêtre d'illustration
	local artBorder = Instance.new("Frame")
	artBorder.Name = "ArtBorder"
	artBorder.Position = UDim2.new(0.04, 0, 0.1, 0)
	artBorder.Size = UDim2.new(0.92, 0, 0.5, 0)
	artBorder.BackgroundColor3 = Color3.new(1, 1, 1)
	artBorder.BorderSizePixel = 0
	artBorder.Parent = inner
	corner(artBorder, 0.04)
	local artBorderGradient = gradient(artBorder, rarity.Color, rarity.Color2, 90)
	if mutationSeq then
		artBorderGradient.Color = mutationSeq
	end

	local art = Instance.new("Frame")
	art.Name = "Art"
	art.Position = UDim2.new(0.025, 0, 0.025, 0)
	art.Size = UDim2.new(0.95, 0, 0.95, 0)
	art.BackgroundColor3 = Color3.new(1, 1, 1)
	art.BorderSizePixel = 0
	art.ClipsDescendants = true
	art.Parent = artBorder
	corner(art, 0.035)
	gradient(art, card.Color:Lerp(Color3.new(1, 1, 1), 0.35), darken(card.Color, 0.35), 90)

	-- Halo lumineux derrière le brainrot
	local halo = Instance.new("Frame")
	halo.Name = "Halo"
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.new(0.5, 0, 0.55, 0)
	halo.Size = UDim2.new(0.8, 0, 0.8, 0)
	halo.BackgroundColor3 = Color3.new(1, 1, 1)
	halo.BackgroundTransparency = 0.55
	halo.BorderSizePixel = 0
	halo.Parent = art
	corner(halo, 0.5)
	local haloRatio = Instance.new("UIAspectRatioConstraint")
	haloRatio.Parent = halo
	local haloGradient = Instance.new("UIGradient")
	haloGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	haloGradient.Parent = halo

	if card.Image and card.Image ~= "" then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Size = UDim2.new(1, 0, 1, 0)
		image.Image = card.Image
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = art
	else
		BrainrotModels.viewport(cardName, art)
	end

	-- Mutation : bandeau brillant en haut de l'illustration
	if mutationName ~= "Normal" and mutationSeq then
		local tag = Instance.new("Frame")
		tag.Name = "MutationTag"
		tag.AnchorPoint = Vector2.new(0.5, 0)
		tag.Position = UDim2.new(0.5, 0, 0.03, 0)
		tag.Size = UDim2.new(0.62, 0, 0.14, 0)
		tag.BackgroundColor3 = Color3.new(1, 1, 1)
		tag.BorderSizePixel = 0
		tag.Parent = art
		corner(tag, 0.5)
		local tagGradient = Instance.new("UIGradient")
		tagGradient.Color = mutationSeq
		tagGradient.Parent = tag
		if mutation.Rainbow then
			CollectionService:AddTag(tagGradient, "RainbowGradient")
		end
		text(tag, "✦ " .. string.upper(mutationName) .. " x" .. mutation.Multiplier .. " ✦", {
			Size = UDim2.new(0.9, 0, 0.8, 0),
			Position = UDim2.new(0.05, 0, 0.1, 0),
		})
	end

	-- Ruban de rareté
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Rarity"
	ribbon.AnchorPoint = Vector2.new(0.5, 0)
	ribbon.Position = UDim2.new(0.5, 0, 0.615, 0)
	ribbon.Size = UDim2.new(0.7, 0, 0.07, 0)
	ribbon.BackgroundColor3 = Color3.new(1, 1, 1)
	ribbon.BorderSizePixel = 0
	ribbon.Parent = inner
	corner(ribbon, 0.5)
	gradient(ribbon, rarity.Color, rarity.Color2, 0)
	text(ribbon, "★ " .. string.upper(card.Rarity) .. " ★", {
		Size = UDim2.new(0.9, 0, 0.8, 0),
		Position = UDim2.new(0.05, 0, 0.1, 0),
	})

	-- Talent / description
	local talent = Instance.new("Frame")
	talent.Name = "Talent"
	talent.Position = UDim2.new(0.04, 0, 0.7, 0)
	talent.Size = UDim2.new(0.92, 0, 0.2, 0)
	talent.BackgroundColor3 = Color3.new(0, 0, 0)
	talent.BackgroundTransparency = 0.55
	talent.BorderSizePixel = 0
	talent.Parent = inner
	corner(talent, 0.12)

	local pill = Instance.new("Frame")
	pill.Position = UDim2.new(0.03, 0, 0.08, 0)
	pill.Size = UDim2.new(0.45, 0, 0.3, 0)
	pill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	pill.BorderSizePixel = 0
	pill.Parent = talent
	corner(pill, 0.5)
	text(pill, "Revenu passif", {
		Size = UDim2.new(0.9, 0, 0.8, 0),
		Position = UDim2.new(0.05, 0, 0.1, 0),
	})
	text(talent, card.Desc or "", {
		Position = UDim2.new(0.04, 0, 0.42, 0),
		Size = UDim2.new(0.92, 0, 0.54, 0),
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextStrokeTransparency = 1,
		TextColor3 = Color3.fromRGB(230, 230, 240),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	-- Bas de carte
	text(inner, mutationName ~= "Normal" and ("Mutation : " .. mutationName) or "Mine Brainrot", {
		Position = UDim2.new(0.04, 0, 0.915, 0),
		Size = UDim2.new(0.6, 0, 0.055, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(200, 200, 210),
		TextStrokeTransparency = 1,
		Font = Enum.Font.GothamBold,
	})
	text(inner, string.format("#%02d/%02d", cardIndex, #GameConfig.CARDS), {
		Position = UDim2.new(0.66, 0, 0.915, 0),
		Size = UDim2.new(0.3, 0, 0.055, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(200, 200, 210),
		TextStrokeTransparency = 1,
		Font = Enum.Font.GothamBold,
	})

	-- Reflet holographique qui passe sur la carte (animé côté client)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(1, 0, 1, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0
	shine.BorderSizePixel = 0
	shine.ZIndex = 5
	shine.Parent = root
	corner(shine, 0.05)
	local shineGradient = Instance.new("UIGradient")
	shineGradient.Rotation = 25
	shineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, rarity.Order >= 4 and 0.55 or 0.75),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	shineGradient.Offset = Vector2.new(-1, 0)
	shineGradient.Parent = shine
	CollectionService:AddTag(shineGradient, "HoloShine")

	if parent then
		root.Parent = parent
	end
	return root
end

-- Conteneur au bon format (5:7) pour une carte dans l'UI
function CardRenderer.createFitted(cardName, mutationName, parent)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 1, 0)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 5 / 7
	ratio.Parent = holder
	CardRenderer.create(cardName, mutationName, holder)
	if parent then
		holder.Parent = parent
	end
	return holder
end

return CardRenderer
