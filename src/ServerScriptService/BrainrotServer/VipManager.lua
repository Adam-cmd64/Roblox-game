-- ModuleScript : le PACK VIP (Game Pass, voir GameConfig.GAMEPASSES.VIP).
-- Un joueur VIP a :
--   - un tag "👑 VIP" doré au-dessus de la tête (tout le monde le voit)
--   - [VIP] devant son nom dans le chat, et ses messages en vert (voir Vip.lua côté client)
--   - le tapis volant et l'argent x2
--   - 1 minerai de diamant + 1 minerai de netherite (donnés une seule fois)

local VipManager = {}

local deps
local GOLD = Color3.fromRGB(255, 205, 60)

local function addTag(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head or head:FindFirstChild("VIPTag") then return end
	local tag = Instance.new("BillboardGui")
	tag.Name = "VIPTag"
	tag.Size = UDim2.new(0, 120, 0, 36)
	tag.StudsOffset = Vector3.new(0, 2.7, 0)
	tag.MaxDistance = 90
	tag.LightInfluence = 0
	tag.Parent = head
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(1, 0, 1, 0)
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.Parent = tag
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = pill
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 130)),
		ColorSequenceKeypoint.new(0.5, GOLD),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 140, 20)),
	})
	gradient.Rotation = 90
	gradient.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 45, 0)
	stroke.Thickness = 2.5
	stroke.Parent = pill
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = "👑 VIP"
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(110, 55, 0)
	label.Parent = pill
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = pill
end

-- Donne tout ce qui va avec le VIP (on peut l'appeler plusieurs fois sans problème)
function VipManager.apply(player)
	if player:GetAttribute("VIP") ~= true then return end
	player:SetAttribute("FlyingCarpet", true)
	player:SetAttribute("DoubleCash", true)
	player:SetAttribute("AutoCollect", true)
	if player:GetAttribute("VIPMinerals") ~= true then
		player:SetAttribute("VIPMinerals", true)
		deps.PlayerData.addMineral(player, "Diamant", 1)
		deps.PlayerData.addMineral(player, "Netherite", 1)
		deps.Remotes.MineralFound:FireClient(player, "Netherite", "vip")
		task.spawn(deps.PlayerData.save, player)
	end
	deps.BaseManager.refresh(player)
	addTag(player)
end

function VipManager.watch(player)
	player:GetAttributeChangedSignal("VIP"):Connect(function()
		VipManager.apply(player)
	end)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head", 10)
		if player:GetAttribute("VIP") == true then
			addTag(player)
		end
	end)
	VipManager.apply(player)
end

function VipManager.init(dependencies)
	deps = dependencies
end

return VipManager
