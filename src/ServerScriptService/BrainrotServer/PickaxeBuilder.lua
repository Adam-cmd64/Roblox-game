-- ModuleScript : construit la pioche "pixel art" façon Minecraft (chaque pixel = un petit cube)
-- et les battes (vendues à la boutique).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PickaxeBuilder = {}

-- D = contour sombre de la tête, H = tête, s = contour du manche, S = manche
local PATTERN = {
	"................",
	"....DDDDDD......",
	"...DHHHHHHDD....",
	"....DDDDDHHHD...",
	".........sSDHD..",
	"........sSs.DHD.",
	".......sSs...DHD",
	"......sSs....DHD",
	".....sSs......DD",
	"....sSs.........",
	"...sSs..........",
	"..sSs...........",
	".sSs............",
	".ss.............",
	"................",
	"................",
}

local GRIP_COL, GRIP_ROW = 4, 11 -- pixel tenu dans la main (en bas du manche)
local STICK = Color3.fromRGB(150, 105, 60)
local STICK_DARK = Color3.fromRGB(90, 60, 30)

local function darken(color, factor)
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

-- Crée les pixels autour de "origin" (le manche est vertical, la tête devant/derrière)
local function makePixels(parent, headColor, pixel, origin, weldTo)
	local colors = {D = darken(headColor, 0.55), H = headColor, s = STICK_DARK, S = STICK}
	local angle = math.rad(45)
	local cosA, sinA = math.cos(angle), math.sin(angle)
	for row, line in ipairs(PATTERN) do
		for col = 1, #line do
			local color = colors[string.sub(line, col, col)]
			if color then
				local px = col - GRIP_COL
				local py = -(row - GRIP_ROW)
				local rx = px * cosA - py * sinA
				local ry = px * sinA + py * cosA
				local part = Instance.new("Part")
				part.Name = "Pixel"
				part.Size = Vector3.new(pixel, pixel, pixel)
				part.Color = color
				part.Material = Enum.Material.SmoothPlastic
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.Massless = true
				part.Anchored = weldTo == nil
				part.CFrame = origin * CFrame.new(0, ry * pixel, -rx * pixel) * CFrame.Angles(angle, 0, 0)
				part.Parent = parent
				if weldTo then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = weldTo
					weld.Part1 = part
					weld.Parent = part
				end
			end
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

	makePixels(tool, pickaxeData.HeadColor, 0.22, handle.CFrame, handle)

	local lantern = Instance.new("PointLight")
	lantern.Range = 16
	lantern.Brightness = 0.8
	lantern.Color = Color3.fromRGB(255, 225, 180)
	lantern.Parent = handle

	if pickaxeData.Damage >= 20 then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = pickaxeData.HeadColor
		sparkle.Parent = handle
	end

	return tool
end

-- Une pioche décorative (ancrée), de la taille voulue
function PickaxeBuilder.buildDisplay(pickaxeData, pixel, cframe)
	local model = Instance.new("Model")
	model.Name = pickaxeData.Name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CFrame = cframe
	root.Parent = model
	model.PrimaryPart = root
	makePixels(model, pickaxeData.HeadColor, pixel, cframe, nil)
	return model
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
