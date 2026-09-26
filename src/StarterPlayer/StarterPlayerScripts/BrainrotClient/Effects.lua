-- ModuleScript client : effets visuels et sons envoyés par le serveur.
--   Break  : un bloc casse (débris, onde de choc, son) + "+$" pour celui qui l'a cassé
--   BatHit : quelqu'un s'est pris un coup de batte (étoiles + son)
--   Steal  : un brainrot vient d'être volé (alarme)
--   Stunned: TOI tu t'es pris un coup de batte (tu tombes 2 secondes)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Sounds = require(script.Parent.Sounds)
local UIKit = require(script.Parent.UIKit)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Effects = {}

local function fragment(position, color, material, speed, size)
	local chip = Instance.new("Part")
	chip.Size = Vector3.new(size, size, size)
	chip.Color = color
	chip.Material = material
	chip.CanCollide = false
	chip.CanQuery = false
	chip.CanTouch = false
	chip.Position = position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2
	chip.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * speed, speed * (0.6 + math.random() * 0.6), (math.random() - 0.5) * speed)
	chip.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
	chip.Parent = Workspace
	TweenService:Create(chip, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = Vector3.new(0.05, 0.05, 0.05)}):Play()
	Debris:AddItem(chip, 1.2)
end

local function shockwave(position, color)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Transparency = 0.2
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.2, 9, 9), Transparency = 1}):Play()
	Debris:AddItem(ring, 0.5)
end

local function sparkleBurst(position, color, count)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = position
	anchor.Parent = Workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new(0.6, 0)
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(count)
	Debris:AddItem(anchor, 1.5)
end

local function floatingText(position, text, color)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = Workspace
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 160, 0, 44)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor
	local label = UIKit.label(billboard, text, {Size = UDim2.new(1, 0, 1, 0), TextColor3 = color, Font = UIKit.TitleFont})
	TweenService:Create(anchor, TweenInfo.new(1.1), {Position = position + Vector3.new(0, 5, 0)}):Play()
	TweenService:Create(label, TweenInfo.new(1.1), {TextTransparency = 1}):Play()
	Debris:AddItem(anchor, 1.2)
end
Effects.floatingText = floatingText

function Effects.shakeCamera(strength, count)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	task.spawn(function()
		for _ = 1, count or 4 do
			humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * strength, (math.random() - 0.5) * strength, 0)
			task.wait(0.03)
		end
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end)
end

local handlers = {}

function handlers.Break(payload)
	local position, color = payload.Position, payload.Color or Color3.new(0.5, 0.5, 0.5)
	for _ = 1, 10 do
		fragment(position, color, Enum.Material.Slate, 22, 0.55 + math.random() * 0.4)
	end
	shockwave(position, payload.Ore and Color3.fromRGB(255, 120, 230) or Color3.new(1, 1, 1))
	Sounds.play("Break", position)
	if payload.Ore then
		sparkleBurst(position, Color3.fromRGB(255, 120, 230), 40)
		Sounds.play("OreBreak", position)
	end
	if payload.Miner == player.UserId then
		Effects.shakeCamera(0.35, 5)
		floatingText(position + Vector3.new(0, 2, 0), "+$" .. GameConfig.format(payload.Cash or 0), Color3.fromRGB(120, 255, 120))
	end
end

function handlers.BatHit(payload)
	sparkleBurst(payload.Position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 240, 120), 25)
	Sounds.play("BatHit", payload.Position)
end

function handlers.WheelWin(payload)
	sparkleBurst(payload.Position, payload.Color or Color3.fromRGB(255, 220, 90), 50)
	Sounds.play("Win", payload.Position)
end

function handlers.Steal(payload)
	sparkleBurst(payload.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 60, 60), 30)
	Sounds.play("Tick", payload.Position, 0.6)
end

local function onStunned(direction)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = direction * 45 + Vector3.new(0, 30, 0)
	Effects.shakeCamera(1.2, 10)

	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	flash.BackgroundTransparency = 0.5
	flash.ZIndex = 50
	flash.Parent = UIKit.ScreenGui
	TweenService:Create(flash, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
	Debris:AddItem(flash, 0.7)

	task.delay(GameConfig.STUN_TIME, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

function Effects.init()
	Remotes.Effect.OnClientEvent:Connect(function(kind, payload)
		local handler = handlers[kind]
		if handler then
			handler(payload)
		end
	end)
	Remotes.Stunned.OnClientEvent:Connect(onStunned)
end

return Effects
