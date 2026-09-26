-- ModuleScript : construit la pioche "pixel art" façon Minecraft (chaque pixel = un petit cube)
-- et les battes (vendues à la boutique).

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

-- Batte (Tool) : un manche + un gros bout, aux couleurs de la batte
function PickaxeBuilder.buildBat(batData)
	local tool = Instance.new("Tool")
	tool.Name = "Batte"
	tool.ToolTip = batData.Name .. " : fais tomber les voleurs !"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -0.3, 0)
	tool:SetAttribute("Bat", true)

	-- Le manche (Handle) est vertical : c'est lui que la main tient
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 1.6, 0.35)
	handle.CFrame = CFrame.new()
	handle.Color = Color3.fromRGB(40, 30, 25)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(2.6, 0.6, 0.6)
	barrel.CFrame = CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	barrel.Color = batData.Color
	barrel.Material = batData.Material
	barrel.CanCollide = false
	barrel.Massless = true
	barrel.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = barrel
	weld.Parent = barrel

	local cap = Instance.new("Part")
	cap.Name = "Cap"
	cap.Shape = Enum.PartType.Ball
	cap.Size = Vector3.new(0.62, 0.62, 0.62)
	cap.CFrame = CFrame.new(0, 3.4, 0)
	cap.Color = batData.Color
	cap.Material = batData.Material
	cap.CanCollide = false
	cap.Massless = true
	cap.Parent = tool
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = handle
	weld2.Part1 = cap
	weld2.Parent = cap

	return tool
end

return PickaxeBuilder
