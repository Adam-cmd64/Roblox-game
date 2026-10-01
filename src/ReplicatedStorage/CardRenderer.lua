-- ModuleScript partagé : dessine une carte brainrot façon carte à collectionner.
-- Utilisé partout : sur les podiums de la base (SurfaceGui), dans l'inventaire, l'index,
-- la carte tenue en main, l'ouverture des boosters...
--
--   - fond aux couleurs de la rareté avec des rayons de lumière (qui tournent pour les Légendaires et +)
--   - plus c'est rare, plus c'est beau : liseré, cadre qui brille, étoiles, pierres aux coins, cadre qui tourne
--   - le personnage détouré au centre (image transparente de l'atlas)
--   - HOLOGRAPHIQUE pour les Mythiques et + (reflet arc-en-ciel qui bouge), bord arc-en-ciel pour Secret / OG
--   - MUTATIONS : bord animé, lueur qui pulse et étincelles aux couleurs de la mutation
--   - le numéro de tirage en haut à droite (#1 = la première carte de ce brainrot trouvée dans le jeu)
--   - LIMITED (cartes du Pack Limited) : design à part : cadre doré irisé qui tourne, fond nuit étoilé,
--     « LIMITED » en filigrane doré, rayons dorés, étincelles dorées, lueur qui pulse, diamants aux coins
--
-- Tout est en tailles relatives (Scale), donc la carte s'adapte à n'importe quelle taille.
-- Format de la carte : 5 de large pour 8 de haut (CardRenderer.ASPECT).
-- Les animations sont faites côté client (World.lua) grâce aux tags : RaySpin, HoloFoil, SpinGradient,
-- RainbowGradient, MutationPulse, Sparkle, HoloShine.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local CardRenderer = {}

CardRenderer.ASPECT = 5 / 8

-- Plus la carte est rare, plus elle est belle :
local INNER_LINE_FROM = 3 -- Très Rare et + : liseré blanc à l'intérieur du cadre
local GLOW_FROM = 4 -- Épique et + : le cadre brille
local RAYS_SPIN_FROM = 5 -- Légendaire et + : les rayons tournent + pierres précieuses aux coins
local HOLO_FROM = 6 -- Mythique et + : carte holographique
local SPIN_BORDER_FROM = 8 -- Enfer et + : le cadre tourne en permanence
local RAINBOW_BORDER_FROM = 13 -- Secret et OG : bord arc-en-ciel

-- Où apparaissent les étincelles d'une carte mutée (en fraction de la carte)
local SPARKLE_SPOTS = {
	{0.14, 0.2}, {0.84, 0.17}, {0.1, 0.52}, {0.88, 0.47}, {0.32, 0.1}, {0.72, 0.64},
	{0.2, 0.68}, {0.58, 0.12}, {0.9, 0.3}, {0.08, 0.36}, {0.46, 0.7}, {0.78, 0.08},
}

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

local function tag(object, name)
	CollectionService:AddTag(object, name)
	return object
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

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 255, 80)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(40, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(120, 80, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 200)),
})
CardRenderer.RAINBOW = RAINBOW

-- Or irisé des cartes LIMITED (or → blanc → cyan → magenta → or)
local LIMITED = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.22, Color3.fromRGB(255, 250, 215)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(90, 235, 255)),
	ColorSequenceKeypoint.new(0.7, Color3.fromRGB(235, 90, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 60)),
})
CardRenderer.LIMITED_SEQUENCE = LIMITED
local CRYSTAL_CYAN = Color3.fromRGB(90, 235, 255) -- cartes du monde 2

-- Violet électrique des cartes FUSIONNÉES (violet → cyan → blanc → violet)
local FUSION = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 60, 255)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 220, 255)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(240, 235, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 80, 220)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 60, 255)),
})
CardRenderer.FUSION_SEQUENCE = FUSION
local GOLD = Color3.fromRGB(255, 210, 80)

-- Couleurs d'une mutation (arc-en-ciel = plusieurs couleurs)
function CardRenderer.mutationSequence(mutationName)
	local mutation = GameConfig.MUTATIONS[mutationName]
	if not mutation or not mutation.Colors then return nil end
	if mutation.Rainbow then
		return RAINBOW
	end
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, mutation.Colors[1]),
		ColorSequenceKeypoint.new(0.5, mutation.Colors[2]),
		ColorSequenceKeypoint.new(1, mutation.Colors[1]),
	})
end

-- Le personnage seul (ImageLabel transparente, découpée dans l'atlas).
-- Sans image importée : une étoile aux couleurs de la rareté.
function CardRenderer.art(cardName, parent)
	local card = GameConfig.getCard(cardName) or GameConfig.getComingSoon(cardName)
	if not card then return nil end
	local rarity = GameConfig.RARITIES[card.Rarity]

	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.Size = UDim2.new(1, 0, 1, 0)
	art.BackgroundTransparency = 1
	art.ScaleType = Enum.ScaleType.Fit

	local image, offset, size = GameConfig.getCardImage(cardName)
	if image then
		art.Image = image
		if size.X > 0 then
			art.ImageRectOffset = offset
			art.ImageRectSize = size
		end
	else
		local star = text(art, "★", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.8, 0, 0.8, 0),
			TextStrokeTransparency = 0.5,
		})
		gradient(star, rarity.Color, rarity.Color2, 90)
	end

	if parent then
		art.Parent = parent
	end
	return art
end

-- Rayons de lumière derrière le personnage
local function addRays(parent, spin)
	local rays = Instance.new("Frame")
	rays.Name = "Rays"
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.new(0.5, 0, 0.42, 0)
	rays.Size = UDim2.new(1.9, 0, 1.9, 0)
	rays.BackgroundTransparency = 1
	rays.Parent = parent
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = rays
	for i = 0, 11 do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.new(0.5, 0, 0.5, 0)
		ray.Size = UDim2.new(0.09, 0, 1, 0)
		ray.Rotation = i * 15
		ray.BackgroundColor3 = Color3.new(1, 1, 1)
		ray.BackgroundTransparency = 0.72
		ray.BorderSizePixel = 0
		ray.Parent = rays
		local fade = Instance.new("UIGradient")
		fade.Rotation = 90
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.6),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(0.7, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		fade.Parent = ray
	end
	if spin then
		tag(rays, "RaySpin")
	end
	return rays
end

-- Crée la carte. Renvoie un Frame de taille (1, 1) à placer dans un conteneur au format 5:8.
-- serial : numéro de tirage (#1, #2...), 0 ou nil = pas affiché
-- fusion : nil, ou {Income = revenu/s, Level = 1, 2...} pour une carte sortie de la Machine de Fusion
function CardRenderer.create(cardName, mutationName, parent, serial, fusion)
	local card = GameConfig.getCard(cardName)
	if not card then return nil end
	local rarity = GameConfig.RARITIES[card.Rarity]
	mutationName = mutationName or "Normal"
	local mutation = GameConfig.MUTATIONS[mutationName] or GameConfig.MUTATIONS.Normal
	local mutationSeq = CardRenderer.mutationSequence(mutationName)
	local mutated = mutationName ~= "Normal" and mutationSeq ~= nil
	local limited = rarity.Limited == true
	local crystalWorld = card.World == 2 and not limited -- brainrot du MONDE 2 : design « Nuit de Cristal »

	-- ===== CADRE =====
	local root = Instance.new("Frame")
	root.Name = "BrainrotCard"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.new(1, 1, 1)
	root.BorderSizePixel = 0
	corner(root, 0.07)
	local border = Instance.new("UIGradient")
	border.Rotation = 50
	border.Parent = root
	if mutated then
		border.Color = mutationSeq
		tag(border, mutation.Rainbow and "RainbowGradient" or "SpinGradient")
	elseif limited then
		border.Color = LIMITED
		tag(border, "SpinGradient")
	elseif rarity.Order >= RAINBOW_BORDER_FROM then
		border.Color = RAINBOW
		tag(border, "RainbowGradient")
	else
		border.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarity.Color),
			ColorSequenceKeypoint.new(0.5, rarity.Color:Lerp(Color3.new(1, 1, 1), 0.5)),
			ColorSequenceKeypoint.new(1, rarity.Color2),
		})
		if rarity.Order >= SPIN_BORDER_FROM then
			tag(border, "SpinGradient")
		end
	end
	-- le cadre brille (Épique et +)
	if rarity.Order >= GLOW_FROM or mutated then
		local glowStroke = Instance.new("UIStroke")
		glowStroke.Name = "Glow"
		glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		glowStroke.Color = mutated and mutation.Colors[1] or rarity.Color
		glowStroke.Thickness = limited and 5 or (rarity.Order >= HOLO_FROM and 4 or 3)
		glowStroke.Transparency = limited and 0 or 0.25
		glowStroke.Parent = root
		if limited then
			-- contour lumineux irisé qui tourne aussi
			local strokeGradient = Instance.new("UIGradient")
			strokeGradient.Color = LIMITED
			strokeGradient.Parent = glowStroke
			tag(strokeGradient, "SpinGradient")
		end
	end

	-- ===== FOND =====
	local holder = Instance.new("Frame")
	holder.Name = "ArtHolder"
	holder.Position = UDim2.new(0.045, 0, 0.028, 0)
	holder.Size = UDim2.new(0.91, 0, 0.944, 0)
	holder.BackgroundColor3 = Color3.new(1, 1, 1)
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.Parent = root
	corner(holder, 0.055)
	if limited then
		-- fond « nuit » violet profond → noir
		gradient(holder, Color3.fromRGB(70, 25, 115), Color3.fromRGB(8, 5, 18), 90)
	elseif crystalWorld then
		-- fond bleu nuit avec un reflet de la couleur de la rareté
		gradient(holder, Color3.fromRGB(40, 60, 140):Lerp(rarity.Color, 0.18), Color3.fromRGB(8, 10, 32), 90)
	else
		local top = rarity.Color:Lerp(card.Color, 0.35):Lerp(Color3.new(1, 1, 1), 0.15)
		gradient(holder, top, darken(rarity.Color2:Lerp(card.Color, 0.25), 0.45), 90)
	end

	local rays = addRays(holder, rarity.Order >= RAYS_SPIN_FROM)
	if limited then
		-- rayons dorés
		for _, ray in ipairs(rays:GetChildren()) do
			if ray:IsA("Frame") then
				ray.BackgroundColor3 = GOLD
				ray.BackgroundTransparency = 0.6
			end
		end
		-- ciel étoilé
		for i = 1, 16 do
			local star = Instance.new("Frame")
			star.Name = "Star"
			star.AnchorPoint = Vector2.new(0.5, 0.5)
			star.Position = UDim2.new(((i * 37) % 97) / 97, 0, ((i * 53) % 89) / 89 * 0.7, 0)
			star.Size = UDim2.new(i % 3 == 0 and 0.018 or 0.011, 0, i % 3 == 0 and 0.018 or 0.011, 0)
			star.BackgroundColor3 = Color3.new(1, 1, 1)
			star.BackgroundTransparency = 0.25
			star.BorderSizePixel = 0
			star.Parent = holder
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.Parent = star
			corner(star, 0.5)
		end
		-- « LIMITED » en filigrane doré, en biais, derrière le personnage
		local watermark = text(holder, "LIMITED", {
			Name = "Watermark",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.42, 0),
			Size = UDim2.new(1.3, 0, 0.2, 0),
			Rotation = -22,
			Font = Enum.Font.LuckiestGuy,
			TextColor3 = GOLD,
			TextTransparency = 0.72,
			TextStrokeTransparency = 1,
		})
		local watermarkGradient = Instance.new("UIGradient")
		watermarkGradient.Color = LIMITED
		watermarkGradient.Parent = watermark
		tag(watermarkGradient, "SpinGradient")
	end

	if crystalWorld then
		-- quadrillage néon cyan (comme le sol du monde 2)
		for i = 1, 7 do
			local v = Instance.new("Frame")
			v.Name = "GridLine"
			v.Position = UDim2.new(i / 8, 0, 0, 0)
			v.Size = UDim2.new(0, 1, 1, 0)
			v.BackgroundColor3 = CRYSTAL_CYAN
			v.BackgroundTransparency = 0.72
			v.BorderSizePixel = 0
			v.Parent = holder
		end
		for i = 1, 11 do
			local h = Instance.new("Frame")
			h.Name = "GridLine"
			h.Position = UDim2.new(0, 0, i / 12, 0)
			h.Size = UDim2.new(1, 0, 0, 1)
			h.BackgroundColor3 = CRYSTAL_CYAN
			h.BackgroundTransparency = 0.72
			h.BorderSizePixel = 0
			h.Parent = holder
		end
		-- petits cristaux qui brillent
		for i = 1, 6 do
			local gem = Instance.new("Frame")
			gem.Name = "CrystalGem"
			gem.AnchorPoint = Vector2.new(0.5, 0.5)
			gem.Position = UDim2.new(((i * 41) % 90 + 5) / 100, 0, 0.12 + ((i * 29) % 55) / 100, 0)
			gem.Size = UDim2.new(0.045, 0, 0.045, 0)
			gem.Rotation = 45
			gem.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(255, 120, 235) or CRYSTAL_CYAN
			gem.BackgroundTransparency = 0.15
			gem.BorderSizePixel = 0
			gem.Parent = holder
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.Parent = gem
			gem:SetAttribute("Phase", i * 1.7)
		end
		-- contour intérieur cyan / violet qui tourne
		local crystalStroke = Instance.new("UIStroke")
		crystalStroke.Name = "CrystalStroke"
		crystalStroke.Thickness = 2.5
		crystalStroke.Color = Color3.new(1, 1, 1)
		crystalStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		crystalStroke.Parent = holder
		local crystalGradient = Instance.new("UIGradient")
		crystalGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, CRYSTAL_CYAN),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 100, 255)),
			ColorSequenceKeypoint.new(1, CRYSTAL_CYAN),
		})
		crystalGradient.Parent = crystalStroke
		tag(crystalGradient, "SpinGradient")
	end

	-- Lueur douce derrière le personnage
	local halo = Instance.new("Frame")
	halo.Name = "Halo"
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.new(0.5, 0, 0.44, 0)
	halo.Size = UDim2.new(0.95, 0, 0.95, 0)
	halo.BackgroundColor3 = Color3.new(1, 1, 1)
	halo.BackgroundTransparency = 0.45
	halo.BorderSizePixel = 0
	halo.Parent = holder
	corner(halo, 0.5)
	local haloRatio = Instance.new("UIAspectRatioConstraint")
	haloRatio.Parent = halo
	local haloGradient = Instance.new("UIGradient")
	haloGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	haloGradient.Parent = halo

	-- Holographique (Mythique et +) : un reflet arc-en-ciel qui glisse sur le fond
	if rarity.Order >= HOLO_FROM then
		local foil = Instance.new("Frame")
		foil.Name = "HoloFoil"
		foil.Size = UDim2.new(1, 0, 1, 0)
		foil.BackgroundColor3 = Color3.new(1, 1, 1)
		foil.BackgroundTransparency = limited and 0.55 or (rarity.Order >= 10 and 0.35 or 0.5)
		foil.BorderSizePixel = 0
		foil.Parent = holder
		local foilGradient = Instance.new("UIGradient")
		foilGradient.Color = limited and LIMITED or RAINBOW
		foilGradient.Rotation = 35
		foilGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.25, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(0.75, 0.2),
			NumberSequenceKeypoint.new(1, 0.6),
		})
		foilGradient.Parent = foil
		tag(foilGradient, "HoloFoil")
	end

	-- ===== LE PERSONNAGE =====
	local artFrame = Instance.new("Frame")
	artFrame.Name = "ArtFrame"
	artFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
	artFrame.Size = UDim2.new(0.9, 0, 0.64, 0)
	artFrame.BackgroundTransparency = 1
	artFrame.Parent = holder
	CardRenderer.art(cardName, artFrame)

	-- ===== LIMITED : lueur dorée qui pulse + étincelles dorées partout =====
	if limited and not mutated then
		local glow = Instance.new("Frame")
		glow.Name = "LimitedGlow"
		glow.Size = UDim2.new(1, 0, 1, 0)
		glow.BackgroundColor3 = GOLD
		glow.BackgroundTransparency = 0.7
		glow.BorderSizePixel = 0
		glow.Parent = holder
		local glowGradient = Instance.new("UIGradient")
		glowGradient.Rotation = 90
		glowGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.3, 1),
			NumberSequenceKeypoint.new(0.7, 1),
			NumberSequenceKeypoint.new(1, 0.05),
		})
		glowGradient.Parent = glow
		tag(glow, "MutationPulse")
		for i = 1, #SPARKLE_SPOTS do
			local spot = SPARKLE_SPOTS[i]
			local sparkle = text(holder, i % 3 == 0 and "✧" or "✦", {
				Name = "Sparkle",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(spot[1], 0, spot[2], 0),
				Size = UDim2.new(i % 2 == 0 and 0.13 or 0.09, 0, i % 2 == 0 and 0.13 or 0.09, 0),
				TextColor3 = LIMITED.Keypoints[(i % 4) + 1].Value,
				TextStrokeTransparency = 0.6,
				ZIndex = 3,
			})
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.Parent = sparkle
			sparkle:SetAttribute("Phase", i * 1.3)
			tag(sparkle, "Sparkle")
		end
	end

	-- ===== MUTATION : lueur qui pulse + étincelles =====
	if mutated then
		local glow = Instance.new("Frame")
		glow.Name = "MutationGlow"
		glow.Size = UDim2.new(1, 0, 1, 0)
		glow.BackgroundColor3 = mutation.Colors[1]
		glow.BackgroundTransparency = 0.75
		glow.BorderSizePixel = 0
		glow.Parent = holder
		local glowGradient = Instance.new("UIGradient")
		glowGradient.Rotation = 90
		glowGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.35, 1),
			NumberSequenceKeypoint.new(0.65, 1),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		if mutation.Rainbow then
			glowGradient.Color = RAINBOW
		end
		glowGradient.Parent = glow
		tag(glow, "MutationPulse")

		for i = 1, math.min(mutation.Sparkles or 6, #SPARKLE_SPOTS) do
			local spot = SPARKLE_SPOTS[i]
			local sparkle = text(holder, i % 3 == 0 and "✧" or "✦", {
				Name = "Sparkle",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(spot[1], 0, spot[2], 0),
				Size = UDim2.new(i % 2 == 0 and 0.13 or 0.09, 0, i % 2 == 0 and 0.13 or 0.09, 0),
				TextColor3 = mutation.Rainbow and RAINBOW.Keypoints[(i % 6) + 1].Value or mutation.Colors[(i % 2) + 1]:Lerp(Color3.new(1, 1, 1), 0.3),
				TextStrokeTransparency = 0.6,
				ZIndex = 3,
			})
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.Parent = sparkle
			sparkle:SetAttribute("Phase", i * 1.7)
			tag(sparkle, "Sparkle")
		end
	end

	-- Liseré blanc à l'intérieur du cadre (Très Rare et +)
	if rarity.Order >= INNER_LINE_FROM then
		local line = Instance.new("UIStroke")
		line.Color = Color3.new(1, 1, 1)
		line.Transparency = rarity.Order >= GLOW_FROM and 0.15 or 0.4
		line.Thickness = 2
		line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		line.Parent = holder
	end

	-- Ombre en bas pour que le nom reste lisible
	local fade = Instance.new("Frame")
	fade.Name = "Fade"
	fade.Size = UDim2.new(1, 0, 1, 0)
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.BorderSizePixel = 0
	fade.Parent = holder
	local fadeGradient = Instance.new("UIGradient")
	fadeGradient.Rotation = 90
	fadeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.12, 1),
		NumberSequenceKeypoint.new(0.68, 1),
		NumberSequenceKeypoint.new(0.82, 0.3),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	fadeGradient.Parent = fade

	-- ===== EN HAUT : rareté + numéro de tirage =====
	local chip = Instance.new("Frame")
	chip.Name = "Rarity"
	chip.Position = UDim2.new(0.05, 0, 0.03, 0)
	chip.Size = UDim2.new(0.52, 0, 0.068, 0)
	chip.BackgroundColor3 = Color3.new(1, 1, 1)
	chip.BorderSizePixel = 0
	chip.ZIndex = 4
	chip.Parent = holder
	corner(chip, 0.5)
	local chipGradient = gradient(chip, rarity.Color, rarity.Color2, 0)
	if limited then
		chipGradient.Color = LIMITED
		tag(chipGradient, "SpinGradient")
	elseif rarity.Order >= RAINBOW_BORDER_FROM then
		chipGradient.Color = RAINBOW
		tag(chipGradient, "RainbowGradient")
	end
	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = Color3.new(1, 1, 1)
	chipStroke.Transparency = 0.3
	chipStroke.Parent = chip
	text(chip, limited and "✦ LIMITED ✦" or GameConfig.upper(card.Rarity), {
		Position = UDim2.new(0.08, 0, 0.14, 0),
		Size = UDim2.new(0.84, 0, 0.72, 0),
		TextColor3 = limited and Color3.fromRGB(60, 20, 70) or Color3.new(1, 1, 1),
		TextStrokeTransparency = limited and 1 or 0.1,
		ZIndex = 4,
	})

	if serial and serial > 0 then
		local serialPill = Instance.new("Frame")
		serialPill.Name = "Serial"
		serialPill.AnchorPoint = Vector2.new(1, 0)
		serialPill.Position = UDim2.new(0.95, 0, 0.03, 0)
		serialPill.Size = UDim2.new(0.33, 0, 0.068, 0)
		serialPill.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
		serialPill.BackgroundTransparency = 0.2
		serialPill.BorderSizePixel = 0
		serialPill.ZIndex = 4
		serialPill.Parent = holder
		corner(serialPill, 0.5)
		local serialStroke = Instance.new("UIStroke")
		serialStroke.Color = serial <= 10 and Color3.fromRGB(255, 215, 70) or Color3.fromRGB(200, 200, 215)
		serialStroke.Transparency = 0.2
		serialStroke.Parent = serialPill
		text(serialPill, "#" .. serial, {
			Name = "SerialText",
			Position = UDim2.new(0.08, 0, 0.14, 0),
			Size = UDim2.new(0.84, 0, 0.72, 0),
			TextColor3 = serial <= 10 and Color3.fromRGB(255, 225, 90) or Color3.new(1, 1, 1),
			ZIndex = 4,
		})
	end

	-- Mutation : pastille brillante sous la rareté
	if mutated then
		local mutationTag = Instance.new("Frame")
		mutationTag.Name = "MutationTag"
		mutationTag.Position = UDim2.new(0.05, 0, 0.11, 0)
		mutationTag.Size = UDim2.new(0.66, 0, 0.064, 0)
		mutationTag.BackgroundColor3 = Color3.new(1, 1, 1)
		mutationTag.BorderSizePixel = 0
		mutationTag.ZIndex = 4
		mutationTag.Parent = holder
		corner(mutationTag, 0.5)
		local tagGradient = Instance.new("UIGradient")
		tagGradient.Color = mutationSeq
		tagGradient.Parent = mutationTag
		tag(tagGradient, mutation.Rainbow and "RainbowGradient" or "SpinGradient")
		text(mutationTag, "✦ " .. GameConfig.upper(mutationName) .. " x" .. mutation.Multiplier, {
			Position = UDim2.new(0.06, 0, 0.14, 0),
			Size = UDim2.new(0.88, 0, 0.72, 0),
			ZIndex = 4,
		})
	end

	-- Fusion : pastille électrique violette + cadre intérieur qui tourne
	if fusion and (fusion.Level or 0) > 0 then
		local fusionTag = Instance.new("Frame")
		fusionTag.Name = "FusionTag"
		fusionTag.Position = UDim2.new(0.05, 0, mutated and 0.185 or 0.11, 0)
		fusionTag.Size = UDim2.new(0.58, 0, 0.064, 0)
		fusionTag.BackgroundColor3 = Color3.new(1, 1, 1)
		fusionTag.BorderSizePixel = 0
		fusionTag.ZIndex = 4
		fusionTag.Parent = holder
		corner(fusionTag, 0.5)
		local fusionGradient = Instance.new("UIGradient")
		fusionGradient.Color = FUSION
		fusionGradient.Parent = fusionTag
		tag(fusionGradient, "SpinGradient")
		local fusionStroke = Instance.new("UIStroke")
		fusionStroke.Color = Color3.new(1, 1, 1)
		fusionStroke.Transparency = 0.2
		fusionStroke.Parent = fusionTag
		text(fusionTag, "⚡ FUSION " .. string.rep("+", math.min(fusion.Level, 5)), {
			Name = "FusionText",
			Position = UDim2.new(0.06, 0, 0.14, 0),
			Size = UDim2.new(0.88, 0, 0.72, 0),
			ZIndex = 4,
		})
		local aura = Instance.new("Frame")
		aura.Name = "FusionAura"
		aura.Size = UDim2.new(1, 0, 1, 0)
		aura.BackgroundTransparency = 1
		aura.ZIndex = 5
		aura.Parent = root
		corner(aura, 0.07)
		local auraStroke = Instance.new("UIStroke")
		auraStroke.Thickness = 3
		auraStroke.Color = Color3.new(1, 1, 1)
		auraStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		auraStroke.Parent = aura
		local auraGradient = Instance.new("UIGradient")
		auraGradient.Color = FUSION
		auraGradient.Parent = auraStroke
		tag(auraGradient, "SpinGradient")
	end

	if crystalWorld then
		text(holder, "✦ NUIT DE CRISTAL ✦", {
			Name = "WorldTag",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.672, 0),
			Size = UDim2.new(0.62, 0, 0.042, 0),
			TextColor3 = CRYSTAL_CYAN,
			TextStrokeTransparency = 0.2,
			ZIndex = 4,
		})
	end

	-- Étoiles de rareté (1 à 7) au-dessus du nom
	local stars = math.clamp(math.ceil(rarity.Order / 2), 1, 7)
	text(holder, limited and "♛ ★★★★★ ♛" or string.rep("★", stars), {
		Name = "Stars",
		Position = UDim2.new(0.15, 0, 0.72, 0),
		Size = UDim2.new(0.7, 0, 0.045, 0),
		TextColor3 = rarity.Order >= RAYS_SPIN_FROM and Color3.fromRGB(255, 215, 70) or Color3.fromRGB(235, 235, 245),
		TextStrokeTransparency = 0.3,
		ZIndex = 4,
	})

	-- ===== EN BAS : le nom + le revenu =====
	local nameLabel = text(holder, card.Name, {
		Name = "CardName",
		Position = UDim2.new(0.05, 0, 0.765, 0),
		Size = UDim2.new(0.9, 0, 0.105, 0),
		TextWrapped = true,
		ZIndex = 4,
	})
	if limited then
		-- nom en or irisé
		local nameGradient = Instance.new("UIGradient")
		nameGradient.Color = LIMITED
		nameGradient.Parent = nameLabel
		tag(nameGradient, "SpinGradient")
	end
	local income = Instance.new("Frame")
	income.Name = "Income"
	income.AnchorPoint = Vector2.new(0.5, 0)
	income.Position = UDim2.new(0.5, 0, 0.885, 0)
	income.Size = UDim2.new(0.66, 0, 0.078, 0)
	income.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	income.BackgroundTransparency = 0.2
	income.BorderSizePixel = 0
	income.ZIndex = 4
	income.Parent = holder
	corner(income, 0.5)
	local incomeStroke = Instance.new("UIStroke")
	incomeStroke.Color = Color3.fromRGB(255, 215, 70)
	incomeStroke.Transparency = 0.2
	incomeStroke.Parent = income
	local incomeValue = fusion and fusion.Income or GameConfig.getItemIncome(cardName, mutationName)
	text(income, "$" .. GameConfig.format(incomeValue) .. "/s", {
		Name = "IncomeText",
		Position = UDim2.new(0.08, 0, 0.12, 0),
		Size = UDim2.new(0.84, 0, 0.76, 0),
		TextColor3 = Color3.fromRGB(255, 220, 80),
		ZIndex = 4,
	})

	-- Pierres précieuses aux 4 coins (Légendaire et +)
	if rarity.Order >= RAYS_SPIN_FROM then
		for _, spot in ipairs({{0.045, 0.028}, {0.955, 0.028}, {0.045, 0.972}, {0.955, 0.972}}) do
			local gem = Instance.new("Frame")
			gem.Name = "Gem"
			gem.AnchorPoint = Vector2.new(0.5, 0.5)
			gem.Position = UDim2.new(spot[1], 0, spot[2], 0)
			gem.Size = UDim2.new(0.085, 0, 0.085, 0)
			gem.Rotation = 45
			gem.BackgroundColor3 = Color3.new(1, 1, 1)
			gem.BorderSizePixel = 0
			gem.ZIndex = 6
			gem.Parent = root
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.Parent = gem
			local gemGradient = gradient(gem, Color3.new(1, 1, 1), rarity.Order >= RAINBOW_BORDER_FROM and Color3.fromRGB(255, 80, 200) or rarity.Color, 90)
			if limited then
				gemGradient.Color = LIMITED
				tag(gemGradient, "SpinGradient")
			elseif rarity.Order >= RAINBOW_BORDER_FROM then
				gemGradient.Color = RAINBOW
				tag(gemGradient, "RainbowGradient")
			end
			local gemStroke = Instance.new("UIStroke")
			gemStroke.Color = Color3.fromRGB(30, 25, 40)
			gemStroke.Thickness = 1.5
			gemStroke.Parent = gem
		end
	end

	-- ===== REFLET qui passe sur toute la carte (animé côté client) =====
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
		NumberSequenceKeypoint.new(0.5, limited and 0.25 or ((rarity.Order >= HOLO_FROM or mutated) and 0.45 or 0.75)),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	shineGradient.Offset = Vector2.new(-1, 0)
	shineGradient.Parent = shine
	tag(shineGradient, "HoloShine")

	if parent then
		root.Parent = parent
	end
	return root
end

-- Carte MYSTÈRE (pas encore découverte) : juste la silhouette noire du brainrot, sans nom ni couleur
function CardRenderer.createSilhouette(cardName, parent)
	local root = Instance.new("Frame")
	root.Name = "MysteryCard"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.new(1, 1, 1)
	root.BorderSizePixel = 0
	corner(root, 0.07)
	gradient(root, Color3.fromRGB(70, 70, 82), Color3.fromRGB(28, 28, 36), 90)
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size = UDim2.new(0.9, 0, 0.93, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.ClipsDescendants = true
	inner.Parent = root
	corner(inner, 0.06)
	gradient(inner, Color3.fromRGB(52, 52, 62), Color3.fromRGB(20, 20, 26), 90)
	local art = CardRenderer.art(cardName, inner)
	if art then
		art.AnchorPoint = Vector2.new(0.5, 0)
		art.Position = UDim2.new(0.5, 0, 0.1, 0)
		art.Size = UDim2.new(0.92, 0, 0.62, 0)
		art.ImageColor3 = Color3.new(0, 0, 0) -- la silhouette : tout en noir
		art.ImageTransparency = 0.05
		for _, child in ipairs(art:GetDescendants()) do
			if child:IsA("TextLabel") then
				child.TextColor3 = Color3.new(0, 0, 0)
				local grad = child:FindFirstChildOfClass("UIGradient")
				if grad then
					grad:Destroy()
				end
			end
		end
	end
	text(inner, "?", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.4, 0),
		Size = UDim2.new(0.4, 0, 0.25, 0),
		TextColor3 = Color3.fromRGB(150, 150, 165),
		TextTransparency = 0.25,
	})
	text(inner, "???", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.76, 0),
		Size = UDim2.new(0.8, 0, 0.1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 185),
	})
	if parent then
		root.Parent = parent
	end
	return root
end

-- Carte "BIENTÔT" : un brainrot qui arrivera dans une prochaine mise à jour
-- (cardName : sa silhouette noire apparaît derrière le cadenas)
function CardRenderer.createComingSoon(parent, cardName)
	local root = Instance.new("Frame")
	root.Name = "ComingSoonCard"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = Color3.new(1, 1, 1)
	root.BorderSizePixel = 0
	corner(root, 0.07)
	local border = gradient(root, Color3.fromRGB(255, 120, 230), Color3.fromRGB(90, 200, 255), 50)
	if border then
		tag(border, "SpinGradient")
	end
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size = UDim2.new(0.9, 0, 0.93, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.Parent = root
	corner(inner, 0.06)
	gradient(inner, Color3.fromRGB(60, 35, 100), Color3.fromRGB(20, 14, 40), 90)
	local art = cardName and CardRenderer.art(cardName, inner)
	if art then
		art.Name = "SoonSilhouette"
		art.AnchorPoint = Vector2.new(0.5, 0)
		art.Position = UDim2.new(0.5, 0, 0.06, 0)
		art.Size = UDim2.new(0.92, 0, 0.56, 0)
		art.ImageColor3 = Color3.new(0, 0, 0) -- silhouette noire
		art.ImageTransparency = 0.1
		for _, child in ipairs(art:GetDescendants()) do
			if child:IsA("TextLabel") then
				child.TextColor3 = Color3.new(0, 0, 0)
				local grad = child:FindFirstChildOfClass("UIGradient")
				if grad then
					grad:Destroy()
				end
			end
		end
	end
	text(inner, "🔒", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, art and 0.46 or 0.36, 0),
		Size = UDim2.new(art and 0.34 or 0.6, 0, art and 0.17 or 0.3, 0),
	})
	local title = text(inner, "BIENTÔT", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.new(0.86, 0, 0.12, 0),
		TextColor3 = Color3.fromRGB(255, 220, 110),
	})
	title.Name = "ComingSoon"
	text(inner, "Prochaine mise à jour", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.76, 0),
		Size = UDim2.new(0.86, 0, 0.07, 0),
		TextColor3 = Color3.fromRGB(200, 190, 230),
	})
	if parent then
		root.Parent = parent
	end
	return root
end

-- Conteneur au bon format (5:8) pour une carte dans l'UI
function CardRenderer.createFitted(cardName, mutationName, parent, serial, fusion)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 1, 0)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = CardRenderer.ASPECT
	ratio.Parent = holder
	CardRenderer.create(cardName, mutationName, holder, serial, fusion)
	if parent then
		holder.Parent = parent
	end
	return holder
end

return CardRenderer
