-- ModuleScript client : le minage et les coups de batte.
--   - viser un bloc (contour noir comme Minecraft) + belle barre de vie
--   - vrai coup de pioche : on utilise l'animation "Slash" intégrée à Roblox (tous les joueurs la voient)
--   - fissures sur le bloc (comme Minecraft) qui grandissent à chaque coup, éclats, secousse de caméra, sons
--   - avec la batte : coup de batte (le serveur vérifie qui est touché)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

-- ====== FISSURES (comme dans Minecraft) ======
-- Un cube invisible un tout petit peu plus grand que le bloc visé, avec des traits sombres sur chaque face.
-- Plus le bloc est abîmé, plus il y a de traits.
local CRACK_LINES = 12
local crackPart = Instance.new("Part")
crackPart.Name = "BlockCracks"
crackPart.Anchored = true
crackPart.CanCollide = false
crackPart.CanQuery = false
crackPart.CanTouch = false
crackPart.CastShadow = false
crackPart.Transparency = 1
crackPart.Size = Vector3.one * (GameConfig.MINE.BlockSize + 0.06)
local crackLines = {}
do
	local random = Random.new(3)
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		gui.LightInfluence = 1
		gui.Parent = crackPart
		for i = 1, CRACK_LINES do
			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			-- les premiers traits partent du centre, les suivants s'étalent
			local spread = 0.15 + (i / CRACK_LINES) * 0.3
			line.Position = UDim2.new(0.5 + random:NextNumber(-spread, spread), 0, 0.5 + random:NextNumber(-spread, spread), 0)
			line.Size = UDim2.new(random:NextNumber(0.25, 0.55), 0, 0, random:NextInteger(2, 4))
			line.Rotation = random:NextNumber(0, 180)
			line.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
			line.BackgroundTransparency = 0.25
			line.BorderSizePixel = 0
			line.Visible = false
			line.Parent = gui
			crackLines[i] = crackLines[i] or {}
			table.insert(crackLines[i], line)
		end
	end
end
local crackStage = -1

local function updateCracks(block)
	if not block then
		crackPart.Parent = nil
		crackStage = -1
		return
	end
	crackPart.CFrame = block.CFrame
	crackPart.Parent = Workspace
	local hp = block:GetAttribute("HP") or 1
	local maxHp = block:GetAttribute("MaxHP") or 1
	local stage = math.clamp(math.floor((1 - hp / maxHp) * CRACK_LINES + 0.5), 0, CRACK_LINES)
	if stage == crackStage then return end
	crackStage = stage
	for i, lines in ipairs(crackLines) do
		for _, line in ipairs(lines) do
			line.Visible = i <= stage
		end
	end
end

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
	-- le contour flashe en blanc au moment de l'impact (sans toucher au bloc lui-même)
	selection.Color3 = Color3.new(1, 1, 1)
	selection.LineThickness = 0.12
	task.delay(0.08, function()
		selection.Color3 = Color3.new(0, 0, 0)
		selection.LineThickness = 0.07
	end)
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

	updateCracks(targetBlock)
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
