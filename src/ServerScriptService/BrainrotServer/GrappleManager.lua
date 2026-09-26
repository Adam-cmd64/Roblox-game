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

-- Le pistolet-grappin : poignée, canon, crochet au bout
function GrappleManager.buildTool(data)
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = data.Name .. " : vise et clique pour t'envoler (portée " .. data.Range .. ")"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	tool:SetAttribute("Grapple", true)

	local handle = makePart(tool, "Handle", Vector3.new(0.4, 1.2, 0.5), CFrame.new(), Color3.fromRGB(40, 40, 48))
	local barrel = makePart(tool, "Barrel", Vector3.new(0.45, 0.45, 1.8), handle.CFrame * CFrame.new(0, 0.55, -0.6), data.Color)
	local tip = makePart(tool, "Hook", Vector3.new(0.6, 0.25, 0.25), barrel.CFrame * CFrame.new(0, 0, -1), data.Color:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Neon)
	local tip2 = makePart(tool, "Hook2", Vector3.new(0.25, 0.6, 0.25), barrel.CFrame * CFrame.new(0, 0, -1), data.Color:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Neon)
	for _, part in ipairs({barrel, tip, tip2}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
	end
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, 0.55, -1.7)
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
