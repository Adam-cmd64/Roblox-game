-- ModuleScript client : la pose du VOLEUR.
-- Quand je porte un brainrot volé (attribut "Carrying"), mon perso tend le bras et tient la carte
-- dans sa main (la carte est soudée à la main par le serveur, voir BaseManager.beginCarry).
-- L'animation est jouée par mon client : Roblox la montre à tout le monde.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Sounds = require(script.Parent.Sounds)

local player = Players.LocalPlayer

local Carry = {}

-- Les animations "tenir un objet" de Roblox (les mêmes que quand on tient un outil)
local HOLD_ANIMATIONS = {
	[Enum.HumanoidRigType.R15] = "rbxassetid://507768375",
	[Enum.HumanoidRigType.R6] = "rbxassetid://182393478",
}

local holdTrack = nil

local function stopHold()
	if holdTrack then
		holdTrack:Stop(0.25)
		holdTrack = nil
	end
end

-- Petit effet quand on attrape la carte : flash doré sur l'écran + son
local function grabFlash()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local screen = gui and gui:FindFirstChild("BrainrotHUD")
	if not screen then return end
	local flash = Instance.new("Frame")
	flash.Name = "GrabFlash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 215, 90)
	flash.BackgroundTransparency = 0.6
	flash.BorderSizePixel = 0
	flash.ZIndex = 40
	flash.Parent = screen
	TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	Debris:AddItem(flash, 0.6)
end

local function startHold()
	stopHold()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local animation = Instance.new("Animation")
	animation.AnimationId = HOLD_ANIMATIONS[humanoid.RigType] or HOLD_ANIMATIONS[Enum.HumanoidRigType.R15]
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and track then
		holdTrack = track
		holdTrack.Priority = Enum.AnimationPriority.Action
		holdTrack.Looped = true
		holdTrack:Play(0.15)
	end
	grabFlash()
	local root = character:FindFirstChild("HumanoidRootPart")
	Sounds.play("Card", root and root.Position)
end

local function onCarryingChanged()
	if player:GetAttribute("Carrying") then
		startHold()
	else
		stopHold()
	end
end

function Carry.init()
	player:GetAttributeChangedSignal("Carrying"):Connect(onCarryingChanged)
	player.CharacterAdded:Connect(function()
		holdTrack = nil
	end)
end

Carry.isHolding = function()
	return holdTrack ~= nil
end

return Carry
