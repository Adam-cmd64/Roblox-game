-- ModuleScript client : voler avec le TAPIS VOLANT (Game Pass).
-- Prends l'outil "Tapis volant" en main : tu voles !
--   ZQSD / flèches / joystick = avancer, Espace = monter, Ctrl ou Shift = descendre.
-- Range le tapis (ou prends un autre objet) pour atterrir.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Carpet = {}

local SPEED = GameConfig.GAMEPASSES.FlyingCarpet.Speed
local MAX_HEIGHT = 160

local flying = nil -- {velocity, align, attachment, connection}

local function stopFlying()
	if not flying then return end
	flying.connection:Disconnect()
	flying.velocity:Destroy()
	flying.align:Destroy()
	flying.attachment:Destroy()
	if flying.humanoid.Parent then
		flying.humanoid.PlatformStand = false
		flying.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	flying = nil
	Remotes.Carpet:FireServer(false)
end

local function startFlying(character)
	if flying then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	if player:GetAttribute("Carrying") then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "CarpetAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.MaxForce = 1e6
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = root

	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxTorque = 1e6
	align.Responsiveness = 18
	align.CFrame = root.CFrame.Rotation
	align.Parent = root

	humanoid.PlatformStand = true
	Remotes.Carpet:FireServer(true)

	local current = Vector3.zero
	local connection = RunService.RenderStepped:Connect(function(dt)
		if not root.Parent or humanoid.Health <= 0 or player:GetAttribute("Carrying") then
			stopFlying()
			return
		end
		-- direction voulue (le joystick / ZQSD donnent MoveDirection, déjà tourné selon la caméra)
		local move = humanoid.MoveDirection
		local vertical = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
			vertical += 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
			vertical -= 1
		end
		if root.Position.Y > MAX_HEIGHT and vertical > 0 then
			vertical = 0
		end
		local target = move * SPEED + Vector3.new(0, vertical * SPEED * 0.6, 0)
		-- petit flottement quand on est immobile
		if target.Magnitude < 0.1 then
			target = Vector3.new(0, math.sin(os.clock() * 2) * 0.8, 0)
		end
		-- accélération douce
		current = current:Lerp(target, math.clamp(dt * 4, 0, 1))
		velocity.VectorVelocity = current

		-- le tapis regarde là où on va (ou vers la caméra) et penche un peu dans les virages
		local camera = Workspace.CurrentCamera
		local look = move.Magnitude > 0.1 and move or (camera and camera.CFrame.LookVector * Vector3.new(1, 0, 1) or root.CFrame.LookVector)
		if look.Magnitude > 0.01 then
			local flat = CFrame.lookAt(Vector3.zero, Vector3.new(look.X, 0, look.Z))
			local sideways = root.CFrame.RightVector:Dot(current) / SPEED
			local climb = current.Y / SPEED
			align.CFrame = flat * CFrame.Angles(math.rad(climb * 12), 0, math.rad(-sideways * 15))
		end
	end)

	flying = {velocity = velocity, align = align, attachment = attachment, humanoid = humanoid, connection = connection}
end

local function watchCharacter(character)
	stopFlying()
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("FlyingCarpet") then
			if player:GetAttribute("Carrying") then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:UnequipTools()
				end
				return
			end
			startFlying(character)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("FlyingCarpet") then
			stopFlying()
		end
	end)
end

function Carpet.init()
	if player.Character then
		watchCharacter(player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
	-- un coup de batte fait tomber du tapis
	Remotes.Stunned.OnClientEvent:Connect(function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if flying and humanoid then
			humanoid:UnequipTools()
			stopFlying()
			humanoid.PlatformStand = true
		end
	end)
end

Carpet.isFlying = function()
	return flying ~= nil
end

return Carpet
