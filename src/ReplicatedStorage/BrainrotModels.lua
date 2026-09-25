-- ModuleScript partagé : construit les personnages brainrot en 3D avec des Parts.
-- Utilisé par le serveur (podiums des bases) et par le client (visuels 3D des cartes dans l'UI).
--
-- Chaque personnage est une liste de pièces :
--   {forme, taille, position, couleur, rotation (degrés), matériau}
-- forme : "Block", "Ball", "Cylinder" (axe vertical), "Ellipsoid", "Wedge"
-- Le personnage regarde vers -Z et ses pieds sont à Y = 0.

local BrainrotModels = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local V = Vector3.new

local WHITE = rgb(245, 245, 245)
local BLACK = rgb(20, 20, 20)
local SKIN = rgb(235, 190, 160)
local WOOD = rgb(170, 120, 70)
local WOOD_DARK = rgb(120, 80, 45)

-- Yeux "cartoon" : blanc + pupille
local function eyes(list, x, y, z, size)
	size = size or 0.7
	table.insert(list, {"Ball", V(size, size, size), V(-x, y, z), WHITE})
	table.insert(list, {"Ball", V(size, size, size), V(x, y, z), WHITE})
	table.insert(list, {"Ball", V(size * 0.45, size * 0.45, size * 0.45), V(-x, y, z - size * 0.4), BLACK})
	table.insert(list, {"Ball", V(size * 0.45, size * 0.45, size * 0.45), V(x, y, z - size * 0.4), BLACK})
end

local SPECS = {}

SPECS["Tralalero Tralala"] = function()
	local blue = rgb(40, 120, 220)
	local p = {
		{"Ellipsoid", V(2.6, 2.6, 5.5), V(0, 3.6, 0), blue},
		{"Ellipsoid", V(2.1, 1.7, 4.8), V(0, 3.1, -0.1), WHITE},
		{"Wedge", V(0.3, 1.6, 1.8), V(0, 5.3, 0.5), blue},
		{"Wedge", V(0.3, 2.2, 1.6), V(0, 4.1, 3.3), blue, V(0, 180, 0)},
		{"Block", V(1.2, 0.15, 0.1), V(0, 3.0, -2.45), rgb(150, 30, 40)},
		-- 3 jambes avec des baskets
		{"Cylinder", V(0.5, 2.2, 0.5), V(-0.8, 1.4, -1), blue},
		{"Cylinder", V(0.5, 2.2, 0.5), V(0.8, 1.4, -1), blue},
		{"Cylinder", V(0.5, 2.2, 0.5), V(0, 1.4, 1.2), blue},
		{"Block", V(0.8, 0.6, 1.4), V(-0.8, 0.3, -1.2), WHITE},
		{"Block", V(0.8, 0.6, 1.4), V(0.8, 0.3, -1.2), WHITE},
		{"Block", V(0.8, 0.6, 1.4), V(0, 0.3, 1.0), WHITE},
		{"Block", V(0.82, 0.2, 0.6), V(-0.8, 0.35, -1.3), rgb(20, 40, 120)},
		{"Block", V(0.82, 0.2, 0.6), V(0.8, 0.35, -1.3), rgb(20, 40, 120)},
		{"Block", V(0.82, 0.2, 0.6), V(0, 0.35, 0.9), rgb(20, 40, 120)},
	}
	eyes(p, 0.9, 4.2, -2.1, 0.55)
	return p
end

SPECS["Lirilì Larilà"] = function()
	local green = rgb(90, 170, 80)
	local gray = rgb(150, 150, 160)
	local p = {
		{"Cylinder", V(1, 2, 1), V(-0.7, 1.2, 0), gray},
		{"Cylinder", V(1, 2, 1), V(0.7, 1.2, 0), gray},
		{"Block", V(1.2, 0.3, 1.6), V(-0.7, 0.15, -0.1), rgb(140, 90, 40)},
		{"Block", V(1.2, 0.3, 1.6), V(0.7, 0.15, -0.1), rgb(140, 90, 40)},
		-- corps en cactus
		{"Cylinder", V(2.4, 3, 2.4), V(0, 3.6, 0), green, nil, Enum.Material.Grass},
		{"Cylinder", V(0.7, 1.6, 0.7), V(-1.7, 4.2, 0), green, nil, Enum.Material.Grass},
		{"Cylinder", V(0.7, 1.6, 0.7), V(1.7, 4.2, 0), green, nil, Enum.Material.Grass},
		{"Block", V(0.8, 0.6, 0.6), V(-1.3, 3.5, 0), green},
		{"Block", V(0.8, 0.6, 0.6), V(1.3, 3.5, 0), green},
		-- tête d'éléphant
		{"Ball", V(2.4, 2.4, 2.4), V(0, 6.1, -0.2), gray},
		{"Ellipsoid", V(0.3, 1.9, 1.7), V(-1.35, 6.2, 0), gray},
		{"Ellipsoid", V(0.3, 1.9, 1.7), V(1.35, 6.2, 0), gray},
		{"Cylinder", V(0.55, 1.8, 0.55), V(0, 5.1, -1.3), gray, V(-15, 0, 0)},
	}
	eyes(p, 0.5, 6.5, -1.1, 0.45)
	return p
end

SPECS["Boneca Ambalabu"] = function()
	local green = rgb(60, 200, 90)
	local p = {
		{"Cylinder", V(0.5, 2.2, 0.5), V(-0.5, 1.2, 0), SKIN},
		{"Cylinder", V(0.5, 2.2, 0.5), V(0.5, 1.2, 0), SKIN},
		{"Block", V(0.7, 0.4, 1.2), V(-0.5, 0.2, -0.2), BLACK},
		{"Block", V(0.7, 0.4, 1.2), V(0.5, 0.2, -0.2), BLACK},
		-- pneu
		{"Cylinder", V(3.4, 1.4, 3.4), V(0, 3.6, 0), rgb(30, 30, 30), V(90, 0, 0)},
		{"Cylinder", V(1.6, 1.5, 1.6), V(0, 3.6, 0), rgb(160, 160, 160), V(90, 0, 0), Enum.Material.Metal},
		-- tête de grenouille
		{"Ellipsoid", V(2.8, 2, 2.4), V(0, 5.9, 0), green},
		{"Block", V(1.8, 0.15, 0.1), V(0, 5.5, -1.15), rgb(180, 40, 60)},
	}
	eyes(p, 0.7, 6.8, -0.6, 0.9)
	return p
end

SPECS["Bombardiro Crocodilo"] = function()
	local green = rgb(60, 130, 50)
	local metal = rgb(110, 120, 100)
	local p = {
		{"Cylinder", V(0.3, 1.6, 0.3), V(0, 0.8, 0), metal},
		{"Block", V(2, 0.2, 2), V(0, 0.1, 0), metal},
		{"Ellipsoid", V(2.2, 2, 6), V(0, 3, 0), green},
		{"Block", V(1.4, 0.8, 2.6), V(0, 2.8, -3.6), green},
		{"Block", V(1.3, 0.2, 2.4), V(0, 2.35, -3.6), WHITE},
		{"Block", V(8, 0.3, 1.8), V(0, 3.2, -0.3), metal, nil, Enum.Material.Metal},
		{"Block", V(0.3, 1.6, 1.2), V(0, 4.2, 2.8), metal, nil, Enum.Material.Metal},
		{"Block", V(3, 0.2, 1), V(0, 3.3, 2.9), metal, nil, Enum.Material.Metal},
		{"Ellipsoid", V(0.6, 0.6, 1.4), V(-1.8, 2.6, -0.3), BLACK},
		{"Ellipsoid", V(0.6, 0.6, 1.4), V(1.8, 2.6, -0.3), BLACK},
		{"Cylinder", V(0.9, 0.6, 0.9), V(-2.8, 3.0, -1.2), metal, V(90, 0, 0)},
		{"Cylinder", V(0.9, 0.6, 0.9), V(2.8, 3.0, -1.2), metal, V(90, 0, 0)},
	}
	eyes(p, 0.6, 3.9, -2.2, 0.6)
	return p
end

SPECS["Tung Tung Tung Sahur"] = function()
	local p = {
		{"Cylinder", V(0.5, 1.8, 0.5), V(-0.5, 0.9, 0), WOOD, nil, Enum.Material.Wood},
		{"Cylinder", V(0.5, 1.8, 0.5), V(0.5, 0.9, 0), WOOD, nil, Enum.Material.Wood},
		-- le tronc
		{"Cylinder", V(2.4, 4.6, 2.4), V(0, 4.1, 0), WOOD, nil, Enum.Material.Wood},
		{"Cylinder", V(2.2, 0.1, 2.2), V(0, 6.45, 0), WOOD_DARK, nil, Enum.Material.Wood},
		{"Block", V(0.7, 0.15, 0.1), V(-0.5, 6.0, -1.2), BLACK, V(0, 0, -12)},
		{"Block", V(0.7, 0.15, 0.1), V(0.5, 6.0, -1.2), BLACK, V(0, 0, 12)},
		{"Block", V(1.0, 0.2, 0.1), V(0, 4.4, -1.2), BLACK},
		-- bras
		{"Cylinder", V(0.4, 2.2, 0.4), V(-1.5, 3.9, -0.2), WOOD, V(0, 0, -20), Enum.Material.Wood},
		{"Cylinder", V(0.4, 2.2, 0.4), V(1.5, 3.9, -0.2), WOOD, V(0, 0, 20), Enum.Material.Wood},
		-- la batte
		{"Cylinder", V(0.55, 3.8, 0.55), V(2.1, 4.8, -0.6), rgb(210, 170, 110), V(-20, 0, -25), Enum.Material.Wood},
	}
	eyes(p, 0.5, 5.3, -1.05, 0.8)
	return p
end

SPECS["Cappuccino Assassino"] = function()
	local silver = rgb(210, 215, 225)
	local p = {
		{"Cylinder", V(0.5, 1.8, 0.5), V(-0.5, 0.9, 0), BLACK},
		{"Cylinder", V(0.5, 1.8, 0.5), V(0.5, 0.9, 0), BLACK},
		{"Cylinder", V(2.6, 3, 2.6), V(0, 3.3, 0), WHITE, nil, Enum.Material.SmoothPlastic},
		{"Cylinder", V(2.4, 0.1, 2.4), V(0, 4.82, 0), rgb(120, 80, 50)},
		{"Cylinder", V(2.7, 0.6, 2.7), V(0, 3.9, 0), BLACK},
		{"Block", V(0.5, 0.2, 0.1), V(-0.5, 3.9, -1.37), WHITE, V(0, 0, -10)},
		{"Block", V(0.5, 0.2, 0.1), V(0.5, 3.9, -1.37), WHITE, V(0, 0, 10)},
		{"Block", V(0.4, 1.4, 0.4), V(1.5, 3.3, 0), WHITE},
		-- katanas
		{"Block", V(0.15, 3.5, 0.4), V(-2.0, 4.4, -0.4), silver, V(0, 0, 25), Enum.Material.Metal},
		{"Block", V(0.15, 3.5, 0.4), V(2.0, 4.4, -0.4), silver, V(0, 0, -25), Enum.Material.Metal},
		{"Block", V(0.3, 0.9, 0.35), V(-1.35, 2.9, -0.4), BLACK, V(0, 0, 25)},
		{"Block", V(0.3, 0.9, 0.35), V(1.35, 2.9, -0.4), BLACK, V(0, 0, -25)},
	}
	return p
end

SPECS["Brr Brr Patapim"] = function()
	local leaf = rgb(40, 150, 40)
	local p = {
		{"Ellipsoid", V(1.4, 0.8, 2.4), V(-0.9, 0.4, -0.4), SKIN},
		{"Ellipsoid", V(1.4, 0.8, 2.4), V(0.9, 0.4, -0.4), SKIN},
		{"Cylinder", V(0.6, 1.6, 0.6), V(-0.8, 1.5, 0), WOOD, nil, Enum.Material.Wood},
		{"Cylinder", V(0.6, 1.6, 0.6), V(0.8, 1.5, 0), WOOD, nil, Enum.Material.Wood},
		{"Cylinder", V(2.2, 3, 2.2), V(0, 3.6, 0), WOOD, nil, Enum.Material.Wood},
		{"Ellipsoid", V(1.6, 1.6, 0.6), V(0, 4.0, -1.0), SKIN},
		{"Ellipsoid", V(0.6, 0.9, 0.6), V(0, 3.9, -1.35), rgb(220, 150, 130)},
		{"Ball", V(0.3, 0.3, 0.3), V(-0.45, 4.4, -1.25), BLACK},
		{"Ball", V(0.3, 0.3, 0.3), V(0.45, 4.4, -1.25), BLACK},
		{"Ball", V(3.2, 3.2, 3.2), V(0, 6.3, 0), leaf, nil, Enum.Material.Grass},
		{"Ball", V(2.4, 2.4, 2.4), V(-1.4, 5.8, 0.3), leaf, nil, Enum.Material.Grass},
		{"Ball", V(2.4, 2.4, 2.4), V(1.4, 5.8, 0.3), leaf, nil, Enum.Material.Grass},
	}
	return p
end

SPECS["Ballerina Cappuccina"] = function()
	local pink = rgb(255, 130, 200)
	local p = {
		{"Cylinder", V(0.35, 2.4, 0.35), V(-0.35, 1.4, 0), SKIN},
		{"Cylinder", V(0.35, 2.4, 0.35), V(0.35, 1.4, 0), SKIN},
		{"Block", V(0.45, 0.3, 0.8), V(-0.35, 0.15, -0.1), pink},
		{"Block", V(0.45, 0.3, 0.8), V(0.35, 0.15, -0.1), pink},
		{"Cylinder", V(3.4, 0.5, 3.4), V(0, 2.9, 0), pink, nil, Enum.Material.Fabric},
		{"Ellipsoid", V(1.2, 1.6, 1.0), V(0, 3.8, 0), pink},
		{"Cylinder", V(0.3, 1.8, 0.3), V(-0.9, 5.0, 0), SKIN, V(0, 0, 30)},
		{"Cylinder", V(0.3, 1.8, 0.3), V(0.9, 5.0, 0), SKIN, V(0, 0, -30)},
		-- tête = une tasse de cappuccino
		{"Cylinder", V(1.8, 1.6, 1.8), V(0, 5.3, 0), WHITE, nil, Enum.Material.SmoothPlastic},
		{"Cylinder", V(1.6, 0.1, 1.6), V(0, 6.12, 0), rgb(160, 110, 70)},
		{"Ball", V(0.8, 0.8, 0.8), V(0, 6.2, 0), rgb(250, 240, 220)},
		{"Ball", V(0.25, 0.25, 0.25), V(-0.35, 5.4, -0.9), BLACK},
		{"Ball", V(0.25, 0.25, 0.25), V(0.35, 5.4, -0.9), BLACK},
	}
	return p
end

SPECS["Chimpanzini Bananini"] = function()
	local yellow = rgb(255, 220, 40)
	local brown = rgb(110, 70, 40)
	local p = {
		{"Ellipsoid", V(0.8, 0.5, 1.2), V(-0.6, 0.25, -0.3), brown},
		{"Ellipsoid", V(0.8, 0.5, 1.2), V(0.6, 0.25, -0.3), brown},
		{"Ellipsoid", V(2.4, 5, 2.2), V(0, 2.7, 0), yellow, V(0, 0, 8)},
		{"Block", V(0.3, 1.6, 1.0), V(-1.2, 5.0, 0), yellow, V(0, 0, 35)},
		{"Block", V(0.3, 1.6, 1.0), V(1.2, 5.0, 0), yellow, V(0, 0, -35)},
		{"Cylinder", V(0.4, 0.8, 0.4), V(0.4, 5.4, 0), brown},
		{"Ellipsoid", V(1.8, 1.8, 0.8), V(0, 3.6, -0.9), brown},
		{"Ellipsoid", V(1.2, 0.9, 0.5), V(0, 3.3, -1.25), SKIN},
		{"Ball", V(0.3, 0.3, 0.3), V(-0.4, 3.95, -1.3), BLACK},
		{"Ball", V(0.3, 0.3, 0.3), V(0.4, 3.95, -1.3), BLACK},
		{"Ball", V(0.7, 0.7, 0.7), V(-1.0, 3.8, -0.7), brown},
		{"Ball", V(0.7, 0.7, 0.7), V(1.0, 3.8, -0.7), brown},
	}
	return p
end

SPECS["La Vaca Saturno Saturnita"] = function()
	local planet = rgb(230, 150, 60)
	local p = {
		{"Cylinder", V(0.5, 1.8, 0.5), V(-0.7, 0.9, -0.7), WHITE},
		{"Cylinder", V(0.5, 1.8, 0.5), V(0.7, 0.9, -0.7), WHITE},
		{"Cylinder", V(0.5, 1.8, 0.5), V(-0.7, 0.9, 0.7), WHITE},
		{"Cylinder", V(0.5, 1.8, 0.5), V(0.7, 0.9, 0.7), WHITE},
		{"Ball", V(3.4, 3.4, 3.4), V(0, 3.6, 0), planet},
		{"Cylinder", V(6, 0.15, 6), V(0, 3.6, 0), rgb(230, 210, 160), V(15, 0, 0)},
		{"Ellipsoid", V(1.6, 1.4, 1.6), V(0, 4.8, -1.8), WHITE},
		{"Ellipsoid", V(0.6, 0.5, 0.3), V(0.4, 5.1, -2.4), BLACK},
		{"Ellipsoid", V(1.0, 0.6, 0.5), V(0, 4.45, -2.55), rgb(250, 170, 180)},
		{"Ball", V(0.3, 0.3, 0.3), V(-0.45, 5.05, -2.5), BLACK},
		{"Ball", V(0.3, 0.3, 0.3), V(0.45, 5.05, -2.5), BLACK},
		{"Cylinder", V(0.2, 0.6, 0.2), V(-0.6, 5.7, -1.7), rgb(240, 230, 200), V(0, 0, 25)},
		{"Cylinder", V(0.2, 0.6, 0.2), V(0.6, 5.7, -1.7), rgb(240, 230, 200), V(0, 0, -25)},
	}
	return p
end

local function makePart(shape, size, color)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if shape == "Ball" then
		part.Shape = Enum.PartType.Ball
		part.Size = size
	elseif shape == "Cylinder" then
		-- Les cylindres Roblox sont couchés sur l'axe X : on stocke la taille "debout"
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(size.Y, size.X, size.Z)
	elseif shape == "Ellipsoid" then
		part.Size = size
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	elseif shape == "Wedge" then
		part:Destroy()
		part = Instance.new("WedgePart")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Size = size
	else
		part.Size = size
	end
	return part
end

-- Construit le modèle 3D d'un brainrot.
-- Renvoie un Model dont le pivot est au niveau des pieds (Y = 0).
function BrainrotModels.build(cardName, scale)
	scale = scale or 1
	local spec = SPECS[cardName]
	local model = Instance.new("Model")
	model.Name = cardName

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	if not spec then
		local fallback = makePart("Ball", Vector3.new(3, 3, 3) * scale, Color3.fromRGB(200, 0, 200))
		fallback.CFrame = CFrame.new(0, 1.5 * scale, 0)
		fallback.Parent = model
		return model
	end

	for _, entry in ipairs(spec()) do
		local shape, size, pos, color, rot, material = entry[1], entry[2], entry[3], entry[4], entry[5], entry[6]
		local part = makePart(shape, size * scale, color)
		if material then
			part.Material = material
		end
		local cf = CFrame.new(pos * scale)
		if rot then
			cf *= CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
		end
		if shape == "Cylinder" then
			-- redresse le cylindre (axe X -> axe Y)
			cf *= CFrame.Angles(0, 0, math.rad(90))
		end
		part.CFrame = cf
		part.Parent = model
	end

	return model
end

-- Construit une vue 3D (ViewportFrame) d'un brainrot pour l'UI
function BrainrotModels.viewport(cardName, parent)
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.new(1, 0, 1, 0)
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local model = BrainrotModels.build(cardName, 1)
	model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(4, 5.5, -12), Vector3.new(0, 3.4, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	viewport.Parent = parent
	return viewport, model
end

return BrainrotModels
