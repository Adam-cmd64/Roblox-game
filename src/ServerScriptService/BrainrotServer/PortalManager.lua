-- ModuleScript : les VOYAGES entre les mondes.
--   - Portail Mystère (monde 1) : touche E -> animation de voyage -> NUIT DE CRISTAL (monde 2)
--   - Portail de retour (monde 2) : touche E -> retour au monde 1
-- Ta base (les mêmes cartes, les mêmes podiums) déménage avec toi dans le monde où tu vas.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PortalManager = {}

local deps
local traveling = {}
local TRAVEL_TIME = 1.8 -- secondes d'animation avant d'arriver (le client fait le spectacle)

function PortalManager.isOpen()
	return GameConfig.PORTAL_FORCE_OPEN == true or Workspace:GetServerTimeNow() >= GameConfig.PORTAL_OPENS_AT
end

-- Où on arrive : devant le portail du monde de destination, tourné vers la mine
local function arrivalCFrame(world)
	local portal = world == 2 and deps.ReturnPortalPosition or deps.PortalPosition
	local origin = GameConfig.getWorld(world).Origin
	local direction = (Vector3.new(origin.X, 0, origin.Z) - Vector3.new(portal.X, 0, portal.Z)).Unit
	local position = portal + direction * 18 + Vector3.new(0, 4, 0)
	return CFrame.lookAt(position, position + direction)
end
PortalManager.arrivalCFrame = arrivalCFrame

function PortalManager.travel(player, world)
	if traveling[player] then return false end
	if world == 2 and not PortalManager.isOpen() then
		deps.Remotes.notify(player, "🔒 Le portail n'est pas encore ouvert !", "error")
		return false
	end
	local required = GameConfig.getWorld(world).RequiredRebirths or 0
	local stats = player:FindFirstChild("leaderstats")
	local rebirths = stats and stats:FindFirstChild("Rebirths")
	if rebirths and rebirths.Value < required then
		deps.Remotes.notify(player, "🔒 Il faut être REBIRTH " .. required .. " pour entrer dans la Nuit de Cristal !", "error")
		return false
	end
	if deps.BaseManager.isCarrying(player) then
		deps.Remotes.notify(player, "🚫 Pas de voyage avec un brainrot volé !", "error")
		return false
	end
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
	traveling[player] = true
	deps.Remotes.PortalTravel:FireClient(player, "start", {To = world, Name = GameConfig.getWorld(world).Name})
	task.wait(TRAVEL_TIME)
	local ok, reason = deps.BaseManager.moveToWorld(player, world)
	if not ok then
		traveling[player] = nil
		deps.Remotes.PortalTravel:FireClient(player, "cancel", {})
		deps.Remotes.notify(player, reason or "Voyage impossible", "error")
		return false
	end
	character = player.Character
	if character then
		character:PivotTo(arrivalCFrame(world))
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
	deps.Remotes.PortalTravel:FireClient(player, "arrive", {To = world, Name = GameConfig.getWorld(world).Name})
	task.spawn(deps.PlayerData.save, player)
	traveling[player] = nil
	return true
end

local function addPrompt(part, world, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PortalPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 22
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		task.spawn(PortalManager.travel, player, world)
	end)
	return prompt
end

function PortalManager.init(dependencies)
	deps = dependencies
	local decor = Workspace:FindFirstChild("Decor")
	local portal = decor and decor:FindFirstChild("Portal")
	local vortex = portal and portal:FindFirstChild("Vortex")
	if vortex then
		PortalManager.prompt = addPrompt(vortex, 2, "Entrer", "Nuit de Cristal (Rebirth " .. (GameConfig.getWorld(2).RequiredRebirths or 0) .. ")")
	end
	if deps.ReturnVortex then
		PortalManager.returnPrompt = addPrompt(deps.ReturnVortex, 1, "Retour", "Portail vers le Monde 1")
	end
	Players.PlayerRemoving:Connect(function(player)
		traveling[player] = nil
	end)
end

return PortalManager
