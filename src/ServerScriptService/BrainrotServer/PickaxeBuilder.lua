-- ModuleScript : construit une pioche "pixel art" façon Minecraft.
-- Chaque pixel du dessin 16x16 devient un petit cube 3D (comme un item Minecraft tenu en main).

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

local PIXEL = 0.22
-- Pixel tenu dans la main (colonne, ligne) — en bas du manche
local GRIP_COL, GRIP_ROW = 4, 11

local STICK = Color3.fromRGB(150, 105, 60)
local STICK_DARK = Color3.fromRGB(90, 60, 30)

local function darken(color, factor)
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

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

	local colors = {
		D = darken(pickaxeData.HeadColor, 0.55),
		H = pickaxeData.HeadColor,
		s = STICK_DARK,
		S = STICK,
	}

	-- Le dessin est incliné à 45° : on le tourne pour que le manche soit vertical (+Y)
	-- et que la tête de la pioche soit devant/derrière (axe Z), comme une vraie pioche.
	local angle = math.rad(45)
	local cosA, sinA = math.cos(angle), math.sin(angle)

	for row, line in ipairs(PATTERN) do
		for col = 1, #line do
			local char = string.sub(line, col, col)
			local color = colors[char]
			if color then
				local px = (col - GRIP_COL)
				local py = -(row - GRIP_ROW)
				local rx = px * cosA - py * sinA
				local ry = px * sinA + py * cosA

				local pixel = Instance.new("Part")
				pixel.Name = "Pixel"
				pixel.Size = Vector3.new(PIXEL, PIXEL, PIXEL)
				pixel.Color = color
				pixel.Material = Enum.Material.SmoothPlastic
				pixel.CanCollide = false
				pixel.CanQuery = false
				pixel.CanTouch = false
				pixel.Massless = true
				pixel.CFrame = handle.CFrame
					* CFrame.new(0, ry * PIXEL, -rx * PIXEL)
					* CFrame.Angles(angle, 0, 0)
				pixel.Parent = tool

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = pixel
				weld.Parent = pixel
			end
		end
	end

	-- Petite lumière pour voir au fond de la mine
	local lantern = Instance.new("PointLight")
	lantern.Range = 16
	lantern.Brightness = 0.8
	lantern.Color = Color3.fromRGB(255, 225, 180)
	lantern.Parent = handle

	-- Petit reflet brillant pour les pioches en or / diamant
	if pickaxeData.Damage >= 20 then
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = pickaxeData.HeadColor
		sparkle.Parent = handle
	end

	return tool
end

return PickaxeBuilder
