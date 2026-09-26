-- ModuleScript client : le minage et les coups de batte.
--   - viser un bloc (contour noir comme Minecraft) + belle barre de vie
--   - vrai coup de pioche : on utilise l'animation "Slash" intégrée à Roblox (tous les joueurs la voient)
--   - éclats, bloc qui tremble, secousse de caméra, sons
--   - avec la batte : coup de batte (le serveur vérifie qui est touché)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Sounds = require(script.Parent.Sounds)
local Effects = require(script.Parent.Effects)
local UIKit = require(script.Parent.UIKit)
local PICKAXES = GameConfig.PICKAXES

local player = Players.LocalPlayer
local pickaxeTier = player:WaitForChild("PickaxeTier")
local batTier = player:WaitForChild("BatTier")
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local blocksFolder = Workspace:WaitForChild("Mine"):WaitForChild("Blocks")

local Mining = {}

-- ====== CONTOUR DU BLOC VISÉ ======
local selection = Instance.new("SelectionBox")
selection.Color3 = Color3.new(0, 0, 0)
selection.LineThickness = 0.07
selection.SurfaceColor3 = Color3.new(0, 0, 0)
selection.SurfaceTransparency = 1
selection.Parent = player:WaitForChild("PlayerGui")

-- ====== BARRE DE VIE DU BLOC ======
local hpGui = Instance.new("BillboardGui")
hpGui.Size = UDim2.new(0, 170, 0, 54)
hpGui.StudsOffset = Vector3.new(0, 3.2, 0)
hpGui.AlwaysOnTop = true
hpGui.Enabled = false
hpGui.Parent = player.PlayerGui

local hpName = UIKit.label(hpGui, "", {Size = UDim2.new(1, 0, 0, 22), Font = UIKit.TitleFont})
local hpBack = Instance.new("Frame")
hpBack.Position = UDim2.new(0, 4, 0, 26)
hpBack.Size = UDim2.new(1, -8, 0, 20)
hpBack.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
hpBack.Parent = hpGui
UIKit.corner(hpBack, 10)
UIKit.outline(hpBack, 2.5)
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.new(1, 1, 1)
hpFill.Parent = hpBack
UIKit.corner(hpFill, 10)
local hpGradient = UIKit.gradient(hpFill, Color3.fromRGB(120, 255, 110), Color3.fromRGB(40, 170, 60), 90)
local hpShine = Instance.new("Frame")
hpShine.Size = UDim2.new(1, 0, 0.45, 0)
hpShine.BackgroundColor3 = Color3.new(1, 1, 1)
hpShine.BackgroundTransparency = 0.7
hpShine.BorderSizePixel = 0
hpShine.Parent = hpFill
UIKit.corner(hpShine, 8)
local hpText = UIKit.label(hpBack, "", {Size = UDim2.new(1, 0, 1, 0), Font = UIKit.TitleFont, ZIndex = 3})

local targetBlock = nil
local mouseDown = false
local lastSwing = 0
local lastBat = 0

local function getEquipped()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Tool")
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

-- Joue l'animation d'attaque intégrée à Roblox (le script "Animate" du personnage la lance)
local function playSlash(tool)
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
end

local function spawnChips(block)
	local camera = Workspace.CurrentCamera
	local hitPoint = block.Position
	if camera then
		hitPoint = block.Position + (camera.CFrame.Position - block.Position).Unit * (block.Size.X / 2)
	end
	for _ = 1, 5 do
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
	-- le bloc "tremble" un instant
	local original = Vector3.one * GameConfig.MINE.BlockSize
	block.Size = original * 0.92
	TweenService:Create(block, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = original}):Play()
end

local function tryMine(tool)
	if not targetBlock then return end
	local pickaxeData = PICKAXES[pickaxeTier.Value] or PICKAXES[1]
	local now = os.clock()
	if now - lastSwing < pickaxeData.Cooldown then return end
	lastSwing = now

	local block = targetBlock
	playSlash(tool)
	Sounds.play("Swing")
	-- l'impact arrive au moment où la pioche frappe
	task.delay(0.12, function()
		if block.Parent then
			spawnChips(block)
			Sounds.play("Hit", block.Position)
			Effects.shakeCamera(0.15, 3)
			Remotes.MineBlock:FireServer(block)
		end
	end)
end

local function tryBat(tool)
	local batData = GameConfig.BATS[batTier.Value] or GameConfig.BATS[1]
	local now = os.clock()
	if now - lastBat < batData.Cooldown then return end
	lastBat = now
	playSlash(tool)
	Sounds.play("Swing", nil, 0.8)
	task.delay(0.15, function()
		Remotes.BatSwing:FireServer()
	end)
end

local function updateTarget()
	local tool = getEquipped()
	targetBlock = tool and tool.Name == "Pioche" and getTarget() or nil

	if not targetBlock then
		selection.Adornee = nil
		hpGui.Adornee = nil
		hpGui.Enabled = false
		return
	end

	selection.Adornee = targetBlock
	hpGui.Adornee = targetBlock
	hpGui.Enabled = true
	local hp = targetBlock:GetAttribute("HP") or 0
	local maxHp = targetBlock:GetAttribute("MaxHP") or 1
	local ratio = math.clamp(hp / maxHp, 0, 1)
	hpFill.Size = UDim2.new(math.max(ratio, 0.04), 0, 1, 0)
	hpText.Text = hp .. " / " .. maxHp
	-- l'ombre du contour s'assombrit quand le bloc est abîmé (fissures)
	selection.SurfaceTransparency = 0.6 + ratio * 0.4

	local name = targetBlock:GetAttribute("LayerName") or ""
	if pickaxeTier.Value < (targetBlock:GetAttribute("MinTier") or 1) then
		local needed = PICKAXES[targetBlock:GetAttribute("MinTier")]
		hpName.Text = "🔒 " .. (needed and needed.Name or name)
		hpName.TextColor3 = Color3.fromRGB(255, 110, 110)
		hpGradient.Color = ColorSequence.new(Color3.fromRGB(255, 110, 110), Color3.fromRGB(170, 30, 30))
	else
		hpName.Text = name
		hpName.TextColor3 = Color3.new(1, 1, 1)
		if ratio > 0.5 then
			hpGradient.Color = ColorSequence.new(Color3.fromRGB(120, 255, 110), Color3.fromRGB(40, 170, 60))
		elseif ratio > 0.25 then
			hpGradient.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(230, 150, 20))
		else
			hpGradient.Color = ColorSequence.new(Color3.fromRGB(255, 120, 90), Color3.fromRGB(200, 40, 30))
		end
	end
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
		updateTarget()
		if not mouseDown then return end
		local tool = getEquipped()
		if not tool then return end
		if tool.Name == "Pioche" then
			tryMine(tool)
		elseif tool:GetAttribute("Bat") then
			tryBat(tool)
		end
	end)
end

return Mining
