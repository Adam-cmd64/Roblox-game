-- ModuleScript : les battes (elles s'achètent à la BOUTIQUE, touche F au comptoir).
-- Un coup de batte fait tomber le joueur touché pendant 2 secondes
-- et lui fait lâcher le brainrot qu'il était en train de voler.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local BatManager = {}

local deps
local lastSwing = {}
local stunned = {}

-- ====== BATTE EN MAIN ======
function BatManager.giveBat(player)
	local tierValue = player:FindFirstChild("BatTier")
	local batData = GameConfig.BATS[tierValue and tierValue.Value or 1] or GameConfig.BATS[1]
	for _, container in ipairs({player:FindFirstChild("Backpack"), player.Character}) do
		if container then
			local old = container:FindFirstChild("Batte")
			if old then
				old:Destroy()
			end
		end
	end
	local tool = deps.PickaxeBuilder.buildBat(batData)
	tool.Parent = player:FindFirstChild("Backpack")
end

-- ====== COUP DE BATTE ======
local function stun(target, attacker, direction)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or stunned[target] then return end
	stunned[target] = true
	humanoid.PlatformStand = true
	deps.Remotes.Stunned:FireClient(target, direction)
	deps.BaseManager.dropStolen(target, "bat")
	deps.Remotes.notify(target, attacker.DisplayName .. " t'a mis un coup de batte !", "error")
	task.delay(GameConfig.STUN_TIME, function()
		stunned[target] = nil
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
end

local function onSwing(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local tool = character and character:FindFirstChild("Batte")
	if not root or not tool or stunned[player] then return end

	local batData = GameConfig.BATS[player.BatTier.Value] or GameConfig.BATS[1]
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < batData.Cooldown * 0.85 then return end
	lastSwing[player] = now

	local look = root.CFrame.LookVector
	for _, other in ipairs(Players:GetPlayers()) do
		local otherRoot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if otherRoot then
			local offset = otherRoot.Position - root.Position
			local distance = offset.Magnitude
			if distance <= batData.Range and distance > 0 and offset.Unit:Dot(look) > 0.25 then
				stun(other, player, look)
				deps.Remotes.Effect:FireAllClients("BatHit", {Position = otherRoot.Position})
			end
		end
	end
end

-- ====== ACHAT ======
local function onBuy(player, tier)
	if typeof(tier) ~= "number" then return end
	local batTier = player.BatTier
	local batData = GameConfig.BATS[tier]
	if not batData then return end
	if not deps.ShopManager.isNear(player) then
		deps.Remotes.notify(player, "Va à la BOUTIQUE (touche F au comptoir) pour acheter une batte", "error")
		return
	end
	if tier ~= batTier.Value + 1 then
		deps.Remotes.notify(player, "Achète d'abord la batte précédente", "error")
		return
	end
	local cash = player.leaderstats.Cash
	if cash.Value < batData.Cost then
		deps.Remotes.notify(player, "Pas assez d'argent ($" .. GameConfig.format(batData.Cost) .. ")", "error")
		return
	end
	cash.Value -= batData.Cost
	batTier.Value = tier
	BatManager.giveBat(player)
	deps.Remotes.notify(player, "Nouvelle arme : " .. batData.Name .. " !", "success")
	task.spawn(deps.PlayerData.save, player)
end

function BatManager.init(dependencies)
	deps = dependencies
	deps.Remotes.BatSwing.OnServerEvent:Connect(onSwing)
	deps.Remotes.BuyBat.OnServerEvent:Connect(onBuy)
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		stunned[player] = nil
	end)
end

return BatManager
