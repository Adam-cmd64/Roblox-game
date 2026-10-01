-- ModuleScript : construit les pioches (une vraie pioche 3D : manche, grip, tête courbée en métal)
-- et les battes (vendues à la boutique).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PickaxeBuilder = {}

local WOOD = Color3.fromRGB(125, 84, 48)
local LEATHER = Color3.fromRGB(42, 30, 26)

local function tierOf(pickaxeData)
	if pickaxeData.Divine then
		return #GameConfig.PICKAXES + 1
	end
	for index, pickaxe in ipairs(GameConfig.PICKAXES) do
		if pickaxe.Name == pickaxeData.Name then
			return index
		end
	end
	return 1
end

-- Crée la pioche autour de "origin" (la main tient le bas du manche ; le manche monte en Y,
-- la tête part devant et derrière en Z). scale = 1 pour la pioche tenue en main.
local function makePickaxe(parent, pickaxeData, scale, origin, weldTo)
	local tier = tierOf(pickaxeData)
	local head = pickaxeData.HeadColor
	local glow = pickaxeData.IconGlow or head
	local headDark = head:Lerp(Color3.new(0, 0, 0), 0.4)
	local shine = head:Lerp(Color3.new(1, 1, 1), 0.5)
	local headMaterial = tier == 1 and Enum.Material.Wood or tier == 2 and Enum.Material.Slate or Enum.Material.Metal
	local fancy = tier >= 6 -- les grosses pioches : manche en métal sombre, bords qui brillent
	local divine = pickaxeData.Divine == true
	local crystal = pickaxeData.Crystal == true -- pioches du monde 2 : tête en cristal lumineux
	if crystal then
		headMaterial = Enum.Material.Glass
	end

	local function piece(name, shape, size, cframe, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = shape
		part.Size = size * scale
		part.CFrame = origin * (cframe - cframe.Position + cframe.Position * scale)
		part.Color = color
		part.Material = material
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.Anchored = weldTo == nil
		part.Parent = parent
		if weldTo then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = weldTo
			weld.Part1 = part
			weld.Parent = part
		end
		return part
	end
	local block, cyl, ball = Enum.PartType.Block, Enum.PartType.Cylinder, Enum.PartType.Ball
	local up = CFrame.Angles(0, 0, math.rad(90)) -- un cylindre debout

	-- le manche
	piece("Shaft", cyl, Vector3.new(3.1, 0.2, 0.2), CFrame.new(0, 1.25, 0) * up,
		crystal and Color3.fromRGB(26, 30, 70) or divine and Color3.fromRGB(245, 245, 255) or fancy and Color3.fromRGB(52, 48, 60) or WOOD,
		crystal and Enum.Material.Metal or divine and Enum.Material.Marble or fancy and Enum.Material.Metal or Enum.Material.Wood)
	if crystal then
		-- bagues de néon le long du manche
		for i = 0, 4 do
			piece("NeonRing", cyl, Vector3.new(0.07, 0.25, 0.25), CFrame.new(0, 0.55 + i * 0.42, 0) * up, glow, Enum.Material.Neon)
		end
	end
	-- le grip en cuir (avec de fines bagues de la couleur de la pioche)
	for i = 0, 2 do
		piece("Grip", cyl, Vector3.new(0.24, 0.26, 0.26), CFrame.new(0, -0.15 + i * 0.3, 0) * up, LEATHER, Enum.Material.Fabric)
	end
	for i = 0, 1 do
		piece("GripRing", cyl, Vector3.new(0.05, 0.28, 0.28), CFrame.new(0, 0 + i * 0.3, 0) * up, head, headMaterial)
	end
	piece("Pommel", ball, Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, -0.38, 0), headDark, Enum.Material.Metal)

	-- la douille qui tient la tête
	piece("Socket", block, Vector3.new(0.36, 0.56, 0.46), CFrame.new(0, 2.78, 0), headDark, Enum.Material.Metal)

	-- la tête : deux bras courbés vers le bas qui finissent en pointe
	local lengths = {0.3, 0.3, 0.28, 0.26, 0.22, 0.18}
	local heights = {0.36, 0.33, 0.28, 0.22, 0.16, 0.09}
	local widths = {0.3, 0.28, 0.24, 0.2, 0.16, 0.1}
	for _, side in ipairs({1, -1}) do
		local y, z = 2.9, side * 0.16
		for k = 1, #lengths do
			local angle = math.rad(3 + (k - 1) * 8)
			local dir = Vector3.new(0, -math.sin(angle), side * math.cos(angle))
			local normal = Vector3.new(0, math.cos(angle), side * math.sin(angle)) -- vers le haut de l'arc
			local length = lengths[k]
			local center = Vector3.new(0, y, z) + dir * (length / 2)
			local cframe = CFrame.lookAt(center, center + dir, Vector3.xAxis)
			local headPart = piece("Head", block, Vector3.new(heights[k], widths[k], length + 0.04), cframe, head, headMaterial)
			if crystal then
				headPart.Transparency = 0.15
				headPart.Reflectance = 0.25
			end
			-- le bord du dessus, plus clair (il brille sur les grosses pioches)
			local edgeCenter = center + normal * (heights[k] / 2)
			piece("Edge", block, Vector3.new(0.05, widths[k] * 0.8, length + 0.04), cframe - cframe.Position + edgeCenter,
				(fancy or crystal) and glow:Lerp(Color3.new(1, 1, 1), 0.3) or shine, (fancy or crystal) and Enum.Material.Neon or Enum.Material.SmoothPlastic)
			y, z = y + dir.Y * length * 0.94, z + dir.Z * length * 0.94
		end
	end

	-- PIOCHE DIVINE : un anneau de lumière autour de la tête, un cristal au-dessus,
	-- des spirales dorées sur le manche
	if divine then
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			piece("Halo", ball, Vector3.new(0.12, 0.12, 0.12), CFrame.new(0, 2.8 + math.sin(a) * 0.62, math.cos(a) * 0.62), glow, Enum.Material.Neon)
		end
		piece("Crystal", block, Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, 3.28, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), glow, Enum.Material.Neon)
		for i = 0, 5 do
			piece("Spiral", cyl, Vector3.new(0.06, 0.24, 0.24), CFrame.new(0, 0.85 + i * 0.3, 0) * up, head, Enum.Material.Neon)
		end
	end

	-- PIOCHES DE CRISTAL : un cristal qui flotte au-dessus de la tête, des éclats sur la douille
	if crystal then
		piece("Crystal", block, Vector3.new(0.3, 0.46, 0.3), CFrame.new(0, 3.42, 0) * CFrame.Angles(0, math.rad(45), 0), glow, Enum.Material.Neon)
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2
			piece("Shard", block, Vector3.new(0.09, 0.3, 0.09), CFrame.new(math.cos(a) * 0.2, 3.1, math.sin(a) * 0.2) * CFrame.Angles(math.sin(a) * 0.6, 0, -math.cos(a) * 0.6), head:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.Neon)
		end
	end

	-- une pierre précieuse de chaque côté de la tête (à partir du diamant)
	if tier >= 5 then
		for _, side in ipairs({1, -1}) do
			piece("Gem", ball, Vector3.new(0.22, 0.22, 0.22), CFrame.new(side * 0.17, 2.82, 0), glow, Enum.Material.Neon)
		end
	end
end

-- La pioche que le joueur tient en main (Tool)
function PickaxeBuilder.build(pickaxeData)
	local tool = Instance.new("Tool")
	tool.Name = "Pioche"
	tool.ToolTip = pickaxeData.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, 0, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 0.4)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	makePickaxe(tool, pickaxeData, 1, handle.CFrame, handle)

	local lantern = Instance.new("PointLight")
	lantern.Range = 16
	lantern.Brightness = 0.8
	lantern.Color = Color3.fromRGB(255, 225, 180)
	lantern.Parent = handle

	if pickaxeData.Divine then
		-- lumière divine + étincelles dorées et bleues qui s'envolent
		lantern.Color = pickaxeData.IconGlow
		lantern.Brightness = 2
		lantern.Range = 20
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "DivineSparks"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(pickaxeData.HeadColor, pickaxeData.IconGlow)
		sparks.LightEmission = 1
		sparks.Size = NumberSequence.new(0.3, 0)
		sparks.Lifetime = NumberRange.new(0.6, 1.2)
		sparks.Rate = 18
		sparks.Speed = NumberRange.new(0.5, 1.5)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Acceleration = Vector3.new(0, 2, 0)
		sparks.Parent = tool:FindFirstChild("Crystal") or handle
	elseif pickaxeData.Crystal then
		-- grosse lueur de la couleur de la pioche + éclats de cristal et poussière d'étoiles qui s'échappent
		lantern.Color = pickaxeData.IconGlow or pickaxeData.HeadColor
		lantern.Brightness = 2.4
		lantern.Range = 20
		local colors = pickaxeData.Rainbow and ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 200)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(90, 230, 255)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 240, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 110, 255)),
		}) or ColorSequence.new(pickaxeData.HeadColor, pickaxeData.IconGlow or Color3.new(1, 1, 1))
		local source = tool:FindFirstChild("Crystal") or handle
		local shards = Instance.new("ParticleEmitter")
		shards.Name = "CrystalShards"
		shards.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		shards.Color = colors
		shards.LightEmission = 1
		shards.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
		shards.Lifetime = NumberRange.new(0.7, 1.4)
		shards.Rate = 22
		shards.Speed = NumberRange.new(0.6, 2)
		shards.SpreadAngle = Vector2.new(180, 180)
		shards.Acceleration = Vector3.new(0, 2.5, 0)
		shards.RotSpeed = NumberRange.new(-180, 180)
		shards.Parent = source
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "CrystalAura"
		aura.Color = colors
		aura.LightEmission = 1
		aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 0)})
		aura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
		aura.Lifetime = NumberRange.new(0.4, 0.8)
		aura.Rate = 14
		aura.Speed = NumberRange.new(0.2, 0.6)
		aura.Parent = source
		-- traînée lumineuse quand on frappe
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 3.05, 0.9)
		a0.Parent = handle
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 2.75, 0.9)
		a1.Parent = handle
		local trail = Instance.new("Trail")
		trail.Name = "CrystalTrail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = colors
		trail.LightEmission = 1
		trail.Lifetime = 0.22
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Parent = handle
	elseif pickaxeData.Damage >= 20 then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = pickaxeData.HeadColor
		sparkle.Parent = handle
	end

	return tool
end

-- Batte (Tool) : une vraie batte de baseball. Pommeau, poignée avec du grip, manche qui s'élargit
-- petit à petit jusqu'au gros bout arrondi, une bande de couleur et le logo. Les meilleures battes brillent.
function PickaxeBuilder.buildBat(batData)
	local tool = Instance.new("Tool")
	tool.Name = "Batte"
	tool.ToolTip = batData.Name .. " : fais tomber les voleurs !"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -0.3, 0)
	tool:SetAttribute("Bat", true)

	local color, material = batData.Color, batData.Material
	local tier = 1
	for index, bat in ipairs(GameConfig.BATS) do
		if bat.Name == batData.Name then
			tier = index
		end
	end
	local gripColor = tier >= 3 and Color3.fromRGB(25, 20, 35) or Color3.fromRGB(45, 32, 26)
	local tapeColor = tier >= 4 and color:Lerp(Color3.new(1, 1, 1), 0.3) or Color3.fromRGB(200, 40, 50)
	local accent = tier >= 3 and Color3.fromRGB(255, 225, 120) or Color3.fromRGB(245, 245, 245)

	-- Le manche (Handle) est vertical : c'est lui que la main tient (la poignée avec du grip)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 1.6, 0.3)
	handle.CFrame = CFrame.new()
	handle.Color = gripColor
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local up = CFrame.Angles(0, 0, math.rad(90)) -- un cylindre debout (dans le sens de la batte)
	local function piece(name, shape, size, y, pieceColor, pieceMaterial)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = shape
		part.Size = size
		part.CFrame = CFrame.new(0, y, 0) * (shape == Enum.PartType.Cylinder and up or CFrame.new())
		part.Color = pieceColor
		part.Material = pieceMaterial
		part.CanCollide = false
		part.CanQuery = false
		part.Massless = true
		part.Parent = tool
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
		return part
	end
	local cyl, ball = Enum.PartType.Cylinder, Enum.PartType.Ball

	-- pommeau en bas
	piece("Knob", cyl, Vector3.new(0.14, 0.5, 0.5), -0.84, color, material)
	piece("KnobRing", cyl, Vector3.new(0.06, 0.52, 0.52), -0.76, accent, Enum.Material.Metal)
	-- grip enroulé autour de la poignée
	for i = 0, 3 do
		piece("GripTape", cyl, Vector3.new(0.12, 0.33, 0.33), -0.6 + i * 0.36, tapeColor, Enum.Material.Fabric)
	end
	-- le manche s'élargit petit à petit
	piece("Taper1", cyl, Vector3.new(0.5, 0.34, 0.34), 1.02, color, material)
	piece("Taper2", cyl, Vector3.new(0.5, 0.42, 0.42), 1.48, color, material)
	piece("Taper3", cyl, Vector3.new(0.5, 0.52, 0.52), 1.94, color, material)
	-- le gros bout
	piece("Barrel", cyl, Vector3.new(1.35, 0.62, 0.62), 2.8, color, material)
	piece("Cap", ball, Vector3.new(0.62, 0.62, 0.62), 3.47, color, material)
	-- la bande de couleur et le logo (une petite étoile de chaque côté)
	piece("Band", cyl, Vector3.new(0.12, 0.64, 0.64), 2.3, accent, tier >= 3 and Enum.Material.Metal or Enum.Material.SmoothPlastic)
	piece("Band2", cyl, Vector3.new(0.06, 0.64, 0.64), 2.46, tapeColor, Enum.Material.SmoothPlastic)
	for _, side in ipairs({-1, 1}) do
		local logo = piece("Logo", Enum.PartType.Block, Vector3.new(0.22, 0.22, 0.05), 2.8, accent, tier >= 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		logo.CFrame = CFrame.new(0, 2.8, side * 0.31) * CFrame.Angles(0, 0, math.rad(45))
	end

	-- les meilleures battes brillent
	if tier >= 3 then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 6
		light.Brightness = tier >= 4 and 1.4 or 0.7
		light.Parent = tool:FindFirstChild("Barrel")
	end
	if tier >= 4 then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new(0.25, 0)
		sparkle.Lifetime = NumberRange.new(0.4, 0.8)
		sparkle.Rate = 8
		sparkle.Speed = NumberRange.new(0.3, 1)
		sparkle.Parent = tool:FindFirstChild("Barrel")
	end
	return tool
end

return PickaxeBuilder
