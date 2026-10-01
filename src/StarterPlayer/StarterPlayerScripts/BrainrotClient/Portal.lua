-- ModuleScript client : l'ANIMATION DU VOYAGE entre les mondes (Portail Mystère, touche E).
--   1. aspiration : la caméra s'élargit (effet "hyper-espace"), flou, couleurs qui saturent,
--      anneaux de lumière qui foncent vers toi, traînées d'étoiles, le nom du monde au centre
--   2. FLASH blanc au moment où on arrive, la caméra revient en douceur
--   3. "BIENVENUE DANS ..." en grand, puis tout disparaît

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Portal = {}

local CYAN = Color3.fromRGB(80, 235, 255)
local PINK = Color3.fromRGB(255, 110, 230)
local VIOLET = Color3.fromRGB(160, 90, 255)

local active -- {gui, blur, color, connection, baseFov}

local function tween(object, time, props, style, direction)
	local t = TweenService:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function cleanup(keepGui)
	if not active then return end
	if active.connection then
		active.connection:Disconnect()
	end
	if active.blur then
		active.blur:Destroy()
	end
	if active.color then
		active.color:Destroy()
	end
	if not keepGui and active.gui then
		active.gui:Destroy()
	end
	local camera = Workspace.CurrentCamera
	if camera and active.baseFov then
		camera.FieldOfView = active.baseFov
	end
	active = nil
end

local function label(parent, text, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextScaled = true
	l.Font = UIKit.TitleFont
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0
	l.TextStrokeColor3 = Color3.fromRGB(30, 0, 70)
	for key, value in pairs(props) do
		l[key] = value
	end
	l.Parent = parent
	return l
end

function Portal.start(info)
	cleanup()
	local camera = Workspace.CurrentCamera
	local gui = Instance.new("ScreenGui")
	gui.Name = "PortalWarp"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	active = {gui = gui, baseFov = camera and camera.FieldOfView or 70, rings = {}}

	-- voile violet qui arrive par les bords (vignette)
	local veil = Instance.new("Frame")
	veil.Name = "Veil"
	veil.Size = UDim2.new(1, 0, 1, 0)
	veil.BackgroundColor3 = Color3.fromRGB(20, 0, 50)
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.Parent = gui
	tween(veil, 1.4, {BackgroundTransparency = 0.35})

	-- le cœur du tunnel (une boule de lumière qui grossit au centre)
	local core = Instance.new("Frame")
	core.Name = "Core"
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.new(0.5, 0, 0.5, 0)
	core.Size = UDim2.new(0, 10, 0, 10)
	core.BackgroundColor3 = Color3.new(1, 1, 1)
	core.BorderSizePixel = 0
	core.ZIndex = 3
	core.Parent = gui
	local coreCorner = Instance.new("UICorner")
	coreCorner.CornerRadius = UDim.new(0.5, 0)
	coreCorner.Parent = core
	local coreGradient = Instance.new("UIGradient")
	coreGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), CYAN)
	coreGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.6)})
	coreGradient.Parent = core
	tween(core, 1.8, {Size = UDim2.new(0.5, 0, 0.5, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = core

	-- le nom du monde au centre
	local title = label(gui, "🌌 " .. string.upper(info.Name or "Nuit de Cristal") .. " 🌌", {
		Name = "WarpTitle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.8, 0, 0.1, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
	})
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CYAN),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, PINK),
	})
	titleGradient.Parent = title
	tween(title, 0.8, {TextTransparency = 0, TextStrokeTransparency = 0})
	local subtitle = label(gui, "VOYAGE DIMENSIONNEL...", {
		Name = "WarpSubtitle",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.56, 0),
		Size = UDim2.new(0.5, 0, 0.045, 0),
		TextColor3 = Color3.fromRGB(255, 220, 110),
		TextTransparency = 1,
		ZIndex = 6,
	})
	tween(subtitle, 1, {TextTransparency = 0})

	-- caméra "hyper-espace", flou et couleurs
	if camera then
		tween(camera, 1.8, {FieldOfView = 120}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	local blur = Instance.new("BlurEffect")
	blur.Name = "PortalBlur"
	blur.Size = 0
	blur.Parent = Lighting
	active.blur = blur
	tween(blur, 1.8, {Size = 18}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "PortalColor"
	color.Parent = Lighting
	active.color = color
	tween(color, 1.6, {Saturation = 0.8, Contrast = 0.3, TintColor = Color3.fromRGB(210, 170, 255)})

	-- anneaux de lumière qui foncent vers la caméra + traînées d'étoiles
	local start = os.clock()
	local lastRing = 0
	local streaks = {}
	for i = 1, 24 do
		local streak = Instance.new("Frame")
		streak.Name = "Streak"
		streak.AnchorPoint = Vector2.new(0, 0.5)
		streak.Position = UDim2.new(0.5, 0, 0.5, 0)
		streak.Size = UDim2.new(0, 0, 0, 3)
		streak.BackgroundColor3 = i % 3 == 0 and PINK or (i % 3 == 1 and CYAN or Color3.new(1, 1, 1))
		streak.BorderSizePixel = 0
		streak.Rotation = i * 15 + math.random(-6, 6)
		streak.ZIndex = 2
		streak.Parent = gui
		table.insert(streaks, {frame = streak, speed = math.random(70, 130) / 100, phase = math.random()})
	end
	active.connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local radius = viewport.Magnitude * 0.6
		-- les traînées : elles partent du centre et filent vers les bords
		for _, s in ipairs(streaks) do
			local progress = ((t * s.speed + s.phase) % 1)
			local length = radius * progress * math.min(1, t)
			s.frame.Size = UDim2.new(0, length * 0.55, 0, 2 + progress * 4)
			s.frame.Position = UDim2.new(0.5, math.cos(math.rad(s.frame.Rotation)) * length * 0.45, 0.5, math.sin(math.rad(s.frame.Rotation)) * length * 0.45)
			s.frame.BackgroundTransparency = 1 - progress * 0.9
		end
		-- un nouvel anneau toutes les 0.14 s
		if t - lastRing > 0.14 then
			lastRing = t
			local ring = Instance.new("Frame")
			ring.Name = "WarpRing"
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Position = UDim2.new(0.5, 0, 0.5, 0)
			ring.Size = UDim2.new(0, 20, 0, 20)
			ring.BackgroundTransparency = 1
			ring.ZIndex = 4
			ring.Parent = gui
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = ring
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 3
			stroke.Color = ({CYAN, PINK, VIOLET})[math.random(1, 3)]
			stroke.Parent = ring
			tween(ring, 0.9, {Size = UDim2.new(0, radius * 2.2, 0, radius * 2.2)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tween(stroke, 0.9, {Thickness = 14, Transparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.95, function()
				ring:Destroy()
			end)
		end
		-- la caméra tremble un peu
		if camera and t < 2.2 then
			local shake = math.min(t, 1.6) * 0.004
			camera.CFrame = camera.CFrame * CFrame.Angles(math.random(-10, 10) * shake * 0.1, math.random(-10, 10) * shake * 0.1, 0)
		end
	end)
	pcall(Sounds.play, "RareCard")
end

function Portal.arrive(info)
	local state = active
	if not state then return end
	local gui = state.gui
	local camera = Workspace.CurrentCamera
	-- FLASH blanc
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = gui
	pcall(Sounds.play, "Win")
	if state.connection then
		state.connection:Disconnect()
		state.connection = nil
	end
	for _, child in ipairs(gui:GetChildren()) do
		if child.Name ~= "Flash" then
			child:Destroy()
		end
	end
	if camera then
		camera.FieldOfView = 120
		tween(camera, 1.2, {FieldOfView = state.baseFov}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	if state.blur then
		tween(state.blur, 1, {Size = 0})
	end
	if state.color then
		tween(state.color, 1.2, {Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1)})
	end
	tween(flash, 1.1, {BackgroundTransparency = 1})

	-- BIENVENUE
	local welcome = label(gui, "BIENVENUE DANS", {
		Name = "Welcome",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.3, 0),
		Size = UDim2.new(0.4, 0, 0.05, 0),
		TextColor3 = Color3.fromRGB(255, 220, 110),
		ZIndex = 11,
	})
	local worldName = label(gui, string.upper(info.Name or ""), {
		Name = "WelcomeWorld",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.38, 0),
		Size = UDim2.new(0.75, 0, 0.11, 0),
		ZIndex = 11,
	})
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CYAN),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, PINK),
	})
	gradient.Parent = worldName
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = worldName
	tween(scale, 0.6, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local blur, color = state.blur, state.color
	active = nil
	task.delay(2.6, function()
		tween(welcome, 0.6, {TextTransparency = 1, TextStrokeTransparency = 1})
		tween(worldName, 0.6, {TextTransparency = 1, TextStrokeTransparency = 1})
		task.delay(0.7, function()
			gui:Destroy()
			if blur then blur:Destroy() end
			if color then color:Destroy() end
		end)
	end)
end

function Portal.init()
	Remotes.PortalTravel.OnClientEvent:Connect(function(kind, info)
		if kind == "start" then
			Portal.start(info or {})
		elseif kind == "arrive" then
			Portal.arrive(info or {})
		elseif kind == "cancel" then
			cleanup()
		end
	end)
end

return Portal
