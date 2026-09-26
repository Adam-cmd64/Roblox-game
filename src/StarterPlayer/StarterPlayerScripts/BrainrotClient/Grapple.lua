-- ModuleScript client : le GRAPPIN.
-- Prends le grappin en main, vise un endroit (un mur, un toit, un arbre...) et clique :
-- une corde part et tu t'envoles jusque là. Impossible en portant un brainrot volé.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Sounds = require(script.Parent.Sounds)

local player = Players.LocalPlayer
local grappleTier = player:WaitForChild("GrappleTier")

local Grapple = {}

local lastUse = 0
local pulling = nil

local function stopPull()
	if not pulling then return end
	pulling.connection:Disconnect()
	pulling.anchor:Destroy()
	pulling.beam:Destroy()
	if pulling.startAttachment.Name == "GrappleStart" then
		pulling.startAttachment:Destroy()
	end
	pulling = nil
end

local function fire(tool)
	local data = GameConfig.GRAPPLES[grappleTier.Value]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = Workspace.CurrentCamera
	if not data or not root or not humanoid or not camera or humanoid.Health <= 0 then return end
	if player:GetAttribute("Carrying") then return end
	if os.clock() - lastUse < data.Cooldown then return end

	-- où vise la souris (ou le centre de l'écran)
	local location = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(location.X, location.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	local result = Workspace:Raycast(ray.Origin, ray.Direction * (data.Range + 60), params)
	if not result or (result.Position - root.Position).Magnitude > data.Range then return end

	lastUse = os.clock()
	stopPull()
	Sounds.play("Grapple", root.Position)

	-- la corde (un Beam entre le grappin et le point visé)
	local anchor = Instance.new("Part")
	anchor.Name = "GrapplePoint"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = result.Position
	anchor.Parent = Workspace
	local target = Instance.new("Attachment")
	target.Parent = anchor
	local handle = tool:FindFirstChild("Handle")
	local startAttachment = handle and handle:FindFirstChild("Muzzle")
	if not startAttachment then
		startAttachment = Instance.new("Attachment")
		startAttachment.Name = "GrappleStart"
		startAttachment.Parent = root
	end
	local beam = Instance.new("Beam")
	beam.Attachment0 = startAttachment
	beam.Attachment1 = target
	beam.Width0 = 0.25
	beam.Width1 = 0.25
	beam.Color = ColorSequence.new(data.Color)
	beam.LightEmission = 0.6
	beam.FaceCamera = true
	beam.Parent = anchor

	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	local started = os.clock()
	local connection = RunService.RenderStepped:Connect(function()
		local offset = result.Position - root.Position
		if not root.Parent or offset.Magnitude < 6 or os.clock() - started > 2.5 or player:GetAttribute("Carrying") then
			root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.3 + Vector3.new(0, 25, 0)
			stopPull()
			return
		end
		root.AssemblyLinearVelocity = offset.Unit * data.Speed
	end)
	pulling = {connection = connection, anchor = anchor, beam = beam, startAttachment = startAttachment}
end

local function watchTool(tool)
	if not tool:IsA("Tool") or not tool:GetAttribute("Grapple") or tool:GetAttribute("Wired") then return end
	tool:SetAttribute("Wired", true)
	tool.Activated:Connect(function()
		fire(tool)
	end)
	tool.Unequipped:Connect(stopPull)
end

local function watchContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		watchTool(child)
	end
	container.ChildAdded:Connect(watchTool)
end

function Grapple.init()
	local backpack = player:WaitForChild("Backpack", 10)
	if backpack then
		watchContainer(backpack)
	end
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			watchContainer(child)
		end
	end)
	player.CharacterAdded:Connect(function(character)
		stopPull()
		watchContainer(character)
	end)
	if player.Character then
		watchContainer(player.Character)
	end
end

Grapple.fire = fire

return Grapple
