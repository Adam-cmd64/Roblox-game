-- ModuleScript partagé : dessine une carte brainrot "full art" (l'illustration remplit toute la carte).
-- Utilisé partout : sur les podiums de la base (SurfaceGui), dans l'inventaire, l'index,
-- la carte tenue en main, l'ouverture des boosters...
--
-- Tout est en tailles relatives (Scale), donc la carte s'adapte à n'importe quelle taille.
-- Format de la carte : 5 de large pour 8 de haut (CardRenderer.ASPECT).
-- Plus tard, les effets de mutation pourront être ajoutés autour du cadre ("Root").

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local CardRenderer = {}

CardRenderer.ASPECT = 5 / 8

-- Zone de l'illustration dans la carte (le reste = le cadre)
local ART_POSITION = UDim2.new(0.045, 0, 0.028, 0)
local ART_SIZE = UDim2.new(0.91, 0, 0.944, 0)
local ART_ASPECT = CardRenderer.ASPECT * 0.91 / 0.944
local FOCUS = 0.4 -- 0 = on garde le haut de l'image, 1 = le bas

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
	label.TextStrokeTransparency = 0.1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
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

-- L'illustration seule (ImageLabel recadrée au format demandé).
-- Sans image importée : un emblème aux couleurs de la rareté.
function CardRenderer.art(cardName, parent, aspect)
	local card = GameConfig.getCard(cardName)
	if not card then return nil end
	local rarity = GameConfig.RARITIES[card.Rarity]
	aspect = aspect or ART_ASPECT

	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.Size = UDim2.new(1, 0, 1, 0)
	art.BackgroundColor3 = Color3.new(1, 1, 1)
	art.BorderSizePixel = 0
	art.ScaleType = Enum.ScaleType.Crop

	local image, offset, size = GameConfig.getCardImage(cardName)
	if image then
		-- (pas de UIGradient ici : il teinterait l'image)
		art.BackgroundTransparency = 1
		art.Image = image
		if size.X > 0 then
			-- On découpe la case de l'atlas au bon format (on garde surtout le haut : les têtes)
			local cropHeight = math.min(size.Y, size.X / aspect)
			art.ImageRectOffset = offset + Vector2.new(0, (size.Y - cropHeight) * FOCUS)
			art.ImageRectSize = Vector2.new(size.X, cropHeight)
		end
	else
		gradient(art, card.Color:Lerp(Color3.new(1, 1, 1), 0.25), darken(card.Color, 0.3), 90)
		local star = text(art, "★", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.42, 0),
			Size = UDim2.new(0.75, 0, 0.5, 0),
			TextStrokeTransparency = 0.5,
		})
		gradient(star, rarity.Color, rarity.Color2, 90)
	end

	if parent then
		art.Parent = parent
	end
	return art
end

-- Crée la carte. Renvoie un Frame de taille (1, 1) à placer dans un conteneur au format 5:8.
function CardRenderer.create(cardName, mutationName, parent)
	local card, cardIndex = GameConfig.getCard(cardName)
	if not card then return nil end
	local rarity = GameConfig.RARITIES[card.Rarity]
	mutationName = mutationName or "Normal"
	local mutation = GameConfig.MUTATIONS[mutationName] or GameConfig.MUTATIONS.Normal
	local mutationSeq = CardRenderer.mutationSequence(mutationName)

	-- Cadre extérieur : dégradé de la rareté (ou de la mutation)
	local root = Instance.new("Frame")
	root.Name = "BrainrotCard"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.new(1, 1, 1)
	root.BorderSizePixel = 0
	corner(root, 0.07)
	local border = Instance.new("UIGradient")
	border.Color = mutationSeq or ColorSequence.new({
		ColorSequenceKeypoint.new(0, rarity.Color),
		ColorSequenceKeypoint.new(0.5, rarity.Color:Lerp(Color3.new(1, 1, 1), 0.45)),
		ColorSequenceKeypoint.new(1, rarity.Color2),
	})
	border.Rotation = 50
	border.Parent = root
	if mutation.Rainbow then
		CollectionService:AddTag(border, "RainbowGradient")
	end

	-- Illustration (remplit tout l'intérieur du cadre)
	local holder = Instance.new("Frame")
	holder.Name = "ArtHolder"
	holder.Position = ART_POSITION
	holder.Size = ART_SIZE
	holder.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
	holder.BorderSizePixel = 0
	holder.Parent = root
	corner(holder, 0.055)
	local art = CardRenderer.art(cardName, holder)
	if art then
		corner(art, 0.055)
	end

	-- Liseré intérieur
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.55
	stroke.Thickness = 1.5
	stroke.Parent = holder

	-- Ombre en haut et en bas pour que les textes restent lisibles
	local fade = Instance.new("Frame")
	fade.Name = "Fade"
	fade.Size = UDim2.new(1, 0, 1, 0)
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.BorderSizePixel = 0
	fade.Parent = holder
	corner(fade, 0.055)
	local fadeGradient = Instance.new("UIGradient")
	fadeGradient.Rotation = 90
	fadeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.16, 1),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(0.8, 0.35),
		NumberSequenceKeypoint.new(1, 0.08),
	})
	fadeGradient.Parent = fade

	-- En haut : rareté + numéro
	local chip = Instance.new("Frame")
	chip.Name = "Rarity"
	chip.Position = UDim2.new(0.05, 0, 0.03, 0)
	chip.Size = UDim2.new(0.56, 0, 0.068, 0)
	chip.BackgroundColor3 = Color3.new(1, 1, 1)
	chip.BorderSizePixel = 0
	chip.Parent = holder
	corner(chip, 0.5)
	gradient(chip, rarity.Color, rarity.Color2, 0)
	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = Color3.new(1, 1, 1)
	chipStroke.Transparency = 0.3
	chipStroke.Parent = chip
	text(chip, GameConfig.upper(card.Rarity), {
		Position = UDim2.new(0.08, 0, 0.14, 0),
		Size = UDim2.new(0.84, 0, 0.72, 0),
	})
	text(holder, string.format("#%02d", cardIndex), {
		Position = UDim2.new(0.66, 0, 0.035, 0),
		Size = UDim2.new(0.29, 0, 0.055, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(235, 235, 245),
	})

	-- Mutation : pastille brillante sous la rareté
	if mutationName ~= "Normal" and mutationSeq then
		local tag = Instance.new("Frame")
		tag.Name = "MutationTag"
		tag.Position = UDim2.new(0.05, 0, 0.11, 0)
		tag.Size = UDim2.new(0.64, 0, 0.064, 0)
		tag.BackgroundColor3 = Color3.new(1, 1, 1)
		tag.BorderSizePixel = 0
		tag.Parent = holder
		corner(tag, 0.5)
		local tagGradient = Instance.new("UIGradient")
		tagGradient.Color = mutationSeq
		tagGradient.Parent = tag
		if mutation.Rainbow then
			CollectionService:AddTag(tagGradient, "RainbowGradient")
		end
		text(tag, "✦ " .. GameConfig.upper(mutationName) .. " x" .. mutation.Multiplier, {
			Position = UDim2.new(0.06, 0, 0.14, 0),
			Size = UDim2.new(0.88, 0, 0.72, 0),
		})
	end

	-- En bas : le nom + le revenu
	text(holder, card.Name, {
		Name = "CardName",
		Position = UDim2.new(0.05, 0, 0.765, 0),
		Size = UDim2.new(0.9, 0, 0.105, 0),
		TextWrapped = true,
	})
	local income = Instance.new("Frame")
	income.Name = "Income"
	income.AnchorPoint = Vector2.new(0.5, 0)
	income.Position = UDim2.new(0.5, 0, 0.885, 0)
	income.Size = UDim2.new(0.66, 0, 0.078, 0)
	income.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	income.BackgroundTransparency = 0.25
	income.BorderSizePixel = 0
	income.Parent = holder
	corner(income, 0.5)
	local incomeStroke = Instance.new("UIStroke")
	incomeStroke.Color = Color3.fromRGB(255, 215, 70)
	incomeStroke.Transparency = 0.2
	incomeStroke.Parent = income
	text(income, "$" .. GameConfig.format(GameConfig.getItemIncome(cardName, mutationName)) .. "/s", {
		Position = UDim2.new(0.08, 0, 0.12, 0),
		Size = UDim2.new(0.84, 0, 0.76, 0),
		TextColor3 = Color3.fromRGB(255, 220, 80),
	})

	-- Reflet holographique qui passe sur la carte (animé côté client)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(1, 0, 1, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BorderSizePixel = 0
	shine.ZIndex = 5
	shine.Parent = root
	corner(shine, 0.07)
	local shineGradient = Instance.new("UIGradient")
	shineGradient.Rotation = 25
	shineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, rarity.Order >= 4 and 0.6 or 0.8),
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

-- Conteneur au bon format (5:8) pour une carte dans l'UI
function CardRenderer.createFitted(cardName, mutationName, parent)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 1, 0)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = CardRenderer.ASPECT
	ratio.Parent = holder
	CardRenderer.create(cardName, mutationName, holder)
	if parent then
		holder.Parent = parent
	end
	return holder
end

return CardRenderer
