-- ModuleScript : les GRAPPINS (vendus à la boutique, touche F).
-- Le joueur vise un endroit et clique : il s'envole jusque là (le mouvement est fait côté client, voir Grapple.lua).
-- Ici : l'outil, l'achat et le niveau du grappin (sauvegardé).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local GrappleManager = {}

local TOOL_NAME = "Grappin"
local deps

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.CanCollide = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Le pistolet-grappin façon sci-fi : poignée avec liseré lumineux, corps en métal, bobine de corde,
-- canon avec anneaux néon et un crochet à 3 griffes au bout. La couleur dépend du niveau du grappin.
function GrappleManager.buildTool(data)
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = data.Name .. " : vise et clique pour t'envoler (portée " .. data.Range .. ")"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	-- tenu comme un pistolet : la poignée dans la main, le canon vers l'avant (-Z de la poignée)
	tool.Grip = CFrame.new(0, -0.15, 0)
	tool:SetAttribute("Grapple", true)

	local accent = data.Color
	local glow = accent:Lerp(Color3.new(1, 1, 1), 0.35)
	local dark = Color3.fromRGB(38, 38, 48)
	local steel = Color3.fromRGB(95, 100, 115)

	local handle = makePart(tool, "Handle", Vector3.new(0.38, 1.1, 0.5), CFrame.new(), dark, Enum.Material.SmoothPlastic)
	local parts = {}
	local function add(name, size, offset, color, material, shape)
		local part = makePart(tool, name, size, handle.CFrame * offset, color, material)
		if shape then
			part.Shape = shape
		end
		table.insert(parts, part)
		return part
	end
	local along = CFrame.Angles(0, math.rad(90), 0) -- un cylindre couché dans le sens du canon

	-- poignée
	add("GripGlow", Vector3.new(0.1, 0.8, 0.52), CFrame.new(0, -0.05, 0.02), glow, Enum.Material.Neon)
	add("GripCap", Vector3.new(0.44, 0.14, 0.56), CFrame.new(0, -0.58, 0), steel)
	add("Trigger", Vector3.new(0.1, 0.3, 0.12), CFrame.new(0, 0.2, -0.36), steel)
	add("TriggerGuard", Vector3.new(0.12, 0.08, 0.42), CFrame.new(0, 0.02, -0.42), dark)
	-- corps
	add("Body", Vector3.new(0.56, 0.56, 1.4), CFrame.new(0, 0.62, -0.35), dark)
	add("Rail", Vector3.new(0.3, 0.12, 1.25), CFrame.new(0, 0.95, -0.35), accent, Enum.Material.Metal)
	add("SideStripe", Vector3.new(0.58, 0.1, 1.1), CFrame.new(0, 0.5, -0.4), glow, Enum.Material.Neon)
	add("Sight", Vector3.new(0.14, 0.2, 0.14), CFrame.new(0, 1.1, -0.85), glow, Enum.Material.Neon)
	-- bobine de corde sur le côté
	add("Spool", Vector3.new(0.26, 0.62, 0.62), CFrame.new(0.4, 0.62, 0.05), Color3.fromRGB(190, 160, 110), Enum.Material.Fabric, Enum.PartType.Cylinder)
	add("SpoolCore", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0.42, 0.62, 0.05), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	-- canon + anneaux lumineux
	add("Barrel", Vector3.new(1.2, 0.38, 0.38), CFrame.new(0, 0.62, -1.35) * along, steel, Enum.Material.Metal, Enum.PartType.Cylinder)
	for _, z in ipairs({-1.05, -1.5}) do
		add("BarrelRing", Vector3.new(0.12, 0.48, 0.48), CFrame.new(0, 0.62, z) * along, glow, Enum.Material.Neon, Enum.PartType.Cylinder)
	end
	-- crochet à 3 griffes
	add("ClawHub", Vector3.new(0.42, 0.42, 0.42), CFrame.new(0, 0.62, -2), accent, Enum.Material.Metal, Enum.PartType.Ball)
	for i = 0, 2 do
		local angle = math.rad(i * 120)
		local out = CFrame.new(0, 0.62, -2.05) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 0.2, -0.18) * CFrame.Angles(math.rad(35), 0, 0)
		add("Claw", Vector3.new(0.1, 0.1, 0.5), out, steel, Enum.Material.Metal)
		add("ClawTip", Vector3.new(0.12, 0.12, 0.14), out * CFrame.new(0, 0.02, -0.28), glow, Enum.Material.Neon)
	end

	for _, part in ipairs(parts) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
	end
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 4
	light.Brightness = 0.8
	light.Parent = handle
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, 0.62, -2.3)
	muzzle.Parent = handle
	return tool
end

function GrappleManager.giveGrapple(player)
	local tier = player:FindFirstChild("GrappleTier")
	local data = tier and GameConfig.GRAPPLES[tier.Value]
	if not data then return end
	for _, container in ipairs({player:FindFirstChild("Backpack"), player.Character}) do
		if container then
			local old = container:FindFirstChild(TOOL_NAME)
			if old then
				old:Destroy()
			end
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		GrappleManager.buildTool(data).Parent = backpack
	end
end

local function onBuy(player, tier)
	if typeof(tier) ~= "number" then return end
	local grappleTier = player.GrappleTier
	local data = GameConfig.GRAPPLES[tier]
	if not data then return end
	if not deps.ShopManager.isNear(player) then
		deps.Remotes.notify(player, "Va à la BOUTIQUE (touche F au comptoir) pour acheter un grappin", "error")
		return
	end
	if tier ~= grappleTier.Value + 1 then
		deps.Remotes.notify(player, "Achète d'abord le grappin précédent", "error")
		return
	end
	local rebirths = player.leaderstats.Rebirths.Value
	if rebirths < (data.RequiredRebirths or 0) then
		deps.Remotes.notify(player, "🔒 Il faut " .. data.RequiredRebirths .. " rebirth(s) pour le " .. data.Name, "error")
		return
	end
	local cash = player.leaderstats.Cash
	if cash.Value < data.Cost then
		deps.Remotes.notify(player, "Pas assez d'argent ($" .. GameConfig.format(data.Cost) .. ")", "error")
		return
	end
	cash.Value -= data.Cost
	grappleTier.Value = tier
	GrappleManager.giveGrapple(player)
	deps.Remotes.notify(player, "🪝 Nouveau grappin : " .. data.Name .. " !", "success")
	task.spawn(deps.PlayerData.save, player)
end

function GrappleManager.init(dependencies)
	deps = dependencies
	deps.Remotes.BuyGrapple.OnServerEvent:Connect(onBuy)
end

GrappleManager.TOOL_NAME = TOOL_NAME

return GrappleManager
