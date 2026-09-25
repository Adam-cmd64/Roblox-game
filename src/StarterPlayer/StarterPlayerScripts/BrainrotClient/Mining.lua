-- ModuleScript client : le minage.
-- Viser un bloc (contour noir comme Minecraft), barre de vie, animation de coup de pioche,
-- éclats, secousse de caméra, son. On maintient le clic pour miner en continu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PICKAXES = GameConfig.PICKAXES

local player = Players.LocalPlayer
local pickaxeTier = player:WaitForChild("PickaxeTier")
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local blocksFolder = Workspace:WaitForChild("Mine"):WaitForChild("Blocks")

local Mining = {}

local swingSound = Instance.new("Sound")
swingSound.SoundId = "rbxasset://sounds/swordslash.wav"
swingSound.Volume = 0.35
swingSound.PlaybackSpeed = 1.4
swingSound.Parent = SoundService

-- Contour du bloc visé
local selection = Instance.new("SelectionBox")
selection.Color3 = Color3.new(0, 0, 0)
selection.LineThickness = 0.06
selection.SurfaceTransparency = 1
selection.Parent = player:WaitForChild("PlayerGui")

-- Barre de vie du bloc visé
local hpGui = Instance.new("BillboardGui")
hpGui.Size = UDim2.new(0, 130, 0, 34)
hpGui.StudsOffset = Vector3.new(0, 2.8, 0)
hpGui.AlwaysOnTop = true
hpGui.Enabled = false
hpGui.Parent = player.PlayerGui

local hpBack = Instance.new("Frame")
hpBack.Size = UDim2.new(1, 0, 0.38, 0)
hpBack.Position = UDim2.new(0, 0, 0.62, 0)
hpBack.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
hpBack.Parent = hpGui
Instance.new("UICorner", hpBack).CornerRadius = UDim.new(0, 5)
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(90, 220, 90)
hpFill.Parent = hpBack
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 5)
local hpName = Instance.new("TextLabel")
hpName.Size = UDim2.new(1, 0, 0.6, 0)
hpName.BackgroundTransparency = 1
hpName.TextColor3 = Color3.new(1, 1, 1)
hpName.TextStrokeTransparency = 0
hpName.Font = Enum.Font.FredokaOne
hpName.TextScaled = true
hpName.Parent = hpGui

local targetBlock = nil
local mouseDown = false
local lastSwing = 0

local function getTool()
	local character = player.Character
	return character and character:FindFirstChild("Pioche")
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {blocksFolder}

local function getTarget()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = Workspace.CurrentCamera
	if not root or not camera then return nil end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)
	if not result then return nil end

	local block = result.Instance
	if block.Parent ~= blocksFolder then return nil end
	if (block.Position - root.Position).Magnitude > GameConfig.MINE.MineRange then return nil end
	return block
end

-- Épaule droite (R15 ou R6) pour l'animation
local function getShoulder()
	local character = player.Character
	if not character then return nil end
	local upperArm = character:FindFirstChild("RightUpperArm")
	if upperArm and upperArm:FindFirstChild("RightShoulder") then
		return upperArm.RightShoulder, "R15"
	end
	local torso = character:FindFirstChild("Torso")
	if torso and torso:FindFirstChild("Right Shoulder") then
		return torso["Right Shoulder"], "R6"
	end
	return nil
end

local swinging = false
local function playSwing(cooldown)
	if swinging then return end
	local shoulder, rigType = getShoulder()
	if not shoulder then return end
	swinging = true

	local original = shoulder:GetAttribute("OriginalC0")
	if not original then
		original = shoulder.C0
		shoulder:SetAttribute("OriginalC0", original)
	end

	local function rotation(degrees)
		if rigType == "R15" then
			return original * CFrame.Angles(math.rad(degrees), 0, 0)
		end
		return original * CFrame.Angles(0, 0, math.rad(degrees))
	end

	-- Lève la pioche, frappe fort vers le bas, puis revient
	local total = math.clamp(cooldown * 0.9, 0.14, 0.3)
	local up = TweenService:Create(shoulder, TweenInfo.new(total * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = rotation(70)})
	local down = TweenService:Create(shoulder, TweenInfo.new(total * 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {C0 = rotation(-45)})
	local back = TweenService:Create(shoulder, TweenInfo.new(total * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = original})
	up:Play()
	up.Completed:Wait()
	down:Play()
	down.Completed:Wait()
	back:Play()
	back.Completed:Wait()
	swinging = false
end

local function spawnChips(block)
	local camera = Workspace.CurrentCamera
	local hitPoint = block.Position
	if camera then
		hitPoint = block.Position + (camera.CFrame.Position - block.Position).Unit * (block.Size.X / 2)
	end
	for _ = 1, 4 do
		local chip = Instance.new("Part")
		chip.Size = Vector3.new(0.35, 0.35, 0.35)
		chip.Color = block.Color
		chip.Material = block.Material
		chip.CanCollide = false
		chip.CanQuery = false
		chip.CanTouch = false
		chip.Position = hitPoint
		chip.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), math.random(8, 18), math.random(-10, 10))
		chip.Parent = Workspace
		Debris:AddItem(chip, 0.6)
	end
end

local function shakeCamera(strength)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	task.spawn(function()
		for _ = 1, 4 do
			humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * strength, (math.random() - 0.5) * strength, 0)
			task.wait(0.03)
		end
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end)
end

local function tryMine()
	if not getTool() or not targetBlock then return end
	local pickaxeData = PICKAXES[pickaxeTier.Value] or PICKAXES[1]
	local now = os.clock()
	if now - lastSwing < pickaxeData.Cooldown then return end
	lastSwing = now

	local block = targetBlock
	task.spawn(playSwing, pickaxeData.Cooldown)
	SoundService:PlayLocalSound(swingSound)
	-- l'impact arrive au moment où la pioche frappe
	task.delay(math.clamp(pickaxeData.Cooldown * 0.9, 0.14, 0.3) * 0.55, function()
		if block.Parent then
			spawnChips(block)
			shakeCamera(0.15)
			Remotes.MineBlock:FireServer(block)
		end
	end)
end

function Mining.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			mouseDown = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			mouseDown = false
		end
	end)

	RunService.RenderStepped:Connect(function()
		targetBlock = getTool() and getTarget() or nil

		if targetBlock then
			selection.Adornee = targetBlock
			hpGui.Adornee = targetBlock
			hpGui.Enabled = true
			local hp = targetBlock:GetAttribute("HP") or 0
			local maxHp = targetBlock:GetAttribute("MaxHP") or 1
			hpFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
			local name = targetBlock:GetAttribute("LayerName") or ""
			if targetBlock:GetAttribute("Ore") then
				name = "💎 " .. name
			end
			if pickaxeTier.Value < (targetBlock:GetAttribute("MinTier") or 1) then
				hpName.Text = "🔒 " .. name
				hpFill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
			else
				hpName.Text = name
				hpFill.BackgroundColor3 = Color3.fromRGB(90, 220, 90)
			end
		else
			selection.Adornee = nil
			hpGui.Adornee = nil
			hpGui.Enabled = false
		end

		if mouseDown then
			tryMine()
		end
	end)
end

return Mining
