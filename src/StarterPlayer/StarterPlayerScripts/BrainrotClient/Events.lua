-- ModuleScript client : les ÉVÉNEMENTS DE SERVEUR à l'écran (voir EventManager.lua côté serveur).
--   - une grosse BANNIÈRE quand un événement commence (flash, son, titre géant)
--   - une pastille en haut : l'événement en cours + le temps qui reste (ou le temps avant le prochain)
--   - l'AMBIANCE : 🩸 lune rouge géante + teinte rouge, 💰 pluie de pièces d'or, ⚡ pluie + éclairs + tonnerre,
--     ☄️ boules de feu, impact qui secoue l'écran, cœur des météores qui pulse

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Events = {}

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotEvents"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 6
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
Events.Gui = gui

local function tween(object, time, props, style, direction)
	local t = TweenService:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function myWorld()
	return player:GetAttribute("World") or 1
end

-- ============================================================
-- LA PASTILLE de l'événement en cours : accrochée SOUS la barre du haut (Mine / Monde / Base),
-- elle grandit et rétrécit avec elle (PC, tablette, téléphone).
-- Le compte à rebours du PROCHAIN événement est une petite étiquette collée au minuteur de la mine.
-- ============================================================
local hudGui = player:WaitForChild("PlayerGui"):FindFirstChild("BrainrotMenu")
local topBar = hudGui and hudGui:FindFirstChild("TopBar") or (UIKit.MenuGui and UIKit.MenuGui:FindFirstChild("TopBar"))

local pill = Instance.new("Frame")
pill.Name = "EventPill"
pill.AnchorPoint = Vector2.new(0.5, 0)
pill.Size = UDim2.new(0, 380, 0, 44)
pill.BackgroundColor3 = Color3.new(1, 1, 1)
pill.BorderSizePixel = 0
pill.Visible = false
if topBar then
	pill.Position = UDim2.new(0.5, 0, 1, 6)
	pill.Parent = topBar
else
	pill.Position = UDim2.new(0.5, 0, 0, 100)
	pill.Parent = gui
	UIKit.hudScale(pill)
end
UIKit.corner(pill, 22)
local pillGradient = Instance.new("UIGradient")
pillGradient.Rotation = 90
pillGradient.Parent = pill
local pillStroke = UIKit.outline(pill, 3, Color3.new(1, 1, 1))
local pillStrokeGradient = Instance.new("UIGradient")
pillStrokeGradient.Parent = pillStroke
CollectionService:AddTag(pillStrokeGradient, "SpinGradient")
local pillLabel = UIKit.label(pill, "", {
	Name = "EventLabel",
	Position = UDim2.new(0, 12, 0, 4),
	Size = UDim2.new(1, -24, 1, -8),
	Font = UIKit.TitleFont,
})
local pillHint = UIKit.label(pill, "", {
	Name = "EventHint",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 3),
	Size = UDim2.new(1.3, 0, 0, 20),
	TextColor3 = Color3.fromRGB(255, 245, 210),
})

-- la petite étiquette « prochain événement » (collée au minuteur de la mine)
local nextChip = Instance.new("Frame")
nextChip.Name = "NextEvent"
nextChip.Size = UDim2.new(1, 0, 0, 24)
nextChip.BackgroundColor3 = Color3.fromRGB(30, 22, 60)
nextChip.BackgroundTransparency = 0.15
nextChip.BorderSizePixel = 0
nextChip.Visible = false
UIKit.corner(nextChip, 12)
local nextStroke = UIKit.outline(nextChip, 2, Color3.fromRGB(150, 120, 255))
local nextLabel = UIKit.label(nextChip, "", {
	Name = "NextLabel",
	Position = UDim2.new(0, 8, 0, 2),
	Size = UDim2.new(1, -16, 1, -4),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(225, 215, 255),
})
local function placeNextChip()
	local hud = player.PlayerGui:FindFirstChild("BrainrotHUD")
	local timer = hud and hud:FindFirstChild("MineTimer", true)
	if timer then
		if UIKit.isTouch() then
			-- téléphone : le minuteur est sous l'argent -> l'étiquette va juste en dessous
			nextChip.AnchorPoint = Vector2.new(0, 0)
			nextChip.Position = UDim2.new(0, 0, 1, 4)
		else
			-- PC : le minuteur est en bas à droite -> l'étiquette va juste au-dessus
			nextChip.AnchorPoint = Vector2.new(0, 1)
			nextChip.Position = UDim2.new(0, 0, 0, -4)
		end
		nextChip.Parent = timer
	else
		nextChip.AnchorPoint = Vector2.new(1, 1)
		nextChip.Position = UDim2.new(1, -18, 1, -96)
		nextChip.Size = UDim2.new(0, 230, 0, 24)
		nextChip.Parent = gui
	end
end
placeNextChip()

local soonUntil = 0 -- l'événement arrive bientôt : l'étiquette clignote
local function updatePill()
	local event = GameConfig.getEvent(ReplicatedStorage:GetAttribute("EventId") or "")
	local now = os.time()
	if event then
		local left = math.max(0, (ReplicatedStorage:GetAttribute("EventEnds") or now) - now)
		pillGradient.Color = ColorSequence.new(event.Color, event.Color:Lerp(Color3.fromRGB(20, 10, 30), 0.55))
		pillStrokeGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, event.Color),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, event.Color),
		})
		pillLabel.Text = event.Icon .. " " .. GameConfig.upper(event.Name) .. "  " .. GameConfig.formatTime(left)
		pillHint.Text = event.Description
		pill.Visible = true
		nextChip.Visible = false
		return
	end
	pill.Visible = false
	local nextAt = ReplicatedStorage:GetAttribute("NextEvent")
	if not nextAt or GameConfig.EVENTS.Auto == false then
		nextChip.Visible = false
		return
	end
	local left = math.max(0, nextAt - now)
	local soon = left <= (GameConfig.EVENTS.Warning or 60) or now < soonUntil
	nextLabel.Text = (soon and "⚠️ ÉVÉNEMENT DANS " or "⏳ ÉVÉNEMENT DANS ") .. GameConfig.formatTime(left)
	nextChip.BackgroundColor3 = soon and Color3.fromRGB(150, 30, 60) or Color3.fromRGB(30, 22, 60)
	nextStroke.Color = soon and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(150, 120, 255)
	nextLabel.TextColor3 = soon and (now % 2 == 0 and Color3.fromRGB(255, 240, 120) or Color3.new(1, 1, 1)) or Color3.fromRGB(225, 215, 255)
	nextChip.Visible = true
end
Events.updatePill = updatePill

-- ============================================================
-- LA BANNIÈRE (début d'un événement)
-- ============================================================
function Events.banner(event)
	local flash = Instance.new("Frame")
	flash.Name = "EventFlash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = event.Color
	flash.BackgroundTransparency = 0.35
	flash.BorderSizePixel = 0
	flash.ZIndex = 40
	flash.Parent = gui
	tween(flash, 0.9, {BackgroundTransparency = 1})
	task.delay(1, function()
		flash:Destroy()
	end)

	local banner = Instance.new("Frame")
	banner.Name = "EventBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.5, 0, 0.3, 0)
	banner.Size = UDim2.new(0, 640, 0, 190)
	banner.BackgroundColor3 = Color3.new(1, 1, 1)
	banner.BorderSizePixel = 0
	banner.ZIndex = 41
	banner.Parent = gui
	UIKit.corner(banner, 26)
	UIKit.gradient(banner, event.Color, event.Color:Lerp(Color3.fromRGB(15, 8, 30), 0.7), 90)
	local stroke = UIKit.outline(banner, 5, Color3.new(1, 1, 1))
	local strokeGradient = Instance.new("UIGradient")
	strokeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, event.Color),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, event.Color),
	})
	strokeGradient.Parent = stroke
	CollectionService:AddTag(strokeGradient, "SpinGradient")
	local glint = Instance.new("Frame")
	glint.Size = UDim2.new(1, 0, 1, 0)
	glint.BackgroundColor3 = Color3.new(1, 1, 1)
	glint.BackgroundTransparency = 0.45
	glint.BorderSizePixel = 0
	glint.ZIndex = 41
	glint.Parent = banner
	UIKit.corner(glint, 26)
	local glintGradient = Instance.new("UIGradient")
	glintGradient.Rotation = 20
	glintGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(0.55, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	glintGradient.Parent = glint
	CollectionService:AddTag(glintGradient, "HoloShine")
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = banner

	UIKit.label(banner, "⚠️ ÉVÉNEMENT DE SERVEUR ⚠️", {
		Name = "Kicker",
		Position = UDim2.new(0, 20, 0, 12),
		Size = UDim2.new(1, -40, 0, 30),
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(255, 240, 200),
		ZIndex = 43,
	})
	local title = UIKit.label(banner, event.Icon .. " " .. GameConfig.upper(event.Name) .. " " .. event.Icon, {
		Name = "EventTitle",
		Position = UDim2.new(0, 16, 0, 42),
		Size = UDim2.new(1, -32, 0, 80),
		Font = UIKit.TitleFont,
		ZIndex = 43,
	})
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, event.Color:Lerp(Color3.new(1, 1, 1), 0.5)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	titleGradient.Parent = title
	CollectionService:AddTag(titleGradient, "RainbowGradient")
	UIKit.label(banner, event.Description, {
		Name = "EventDescription",
		Position = UDim2.new(0, 24, 0, 124),
		Size = UDim2.new(1, -48, 0, 52),
		TextWrapped = true,
		ZIndex = 43,
	})

	local target = math.max(0.45, UIKit.fitFactor(700, 240, 0.9))
	tween(scale, 0.55, {Scale = target}, Enum.EasingStyle.Back)
	pcall(Sounds.play, "Alarm")
	task.delay(0.4, function()
		pcall(Sounds.play, "Win")
	end)
	-- le titre qui pulse
	task.spawn(function()
		for _ = 1, 4 do
			if not banner.Parent then return end
			tween(scale, 0.35, {Scale = target * 1.06}, Enum.EasingStyle.Sine)
			task.wait(0.35)
			tween(scale, 0.35, {Scale = target}, Enum.EasingStyle.Sine)
			task.wait(0.35)
		end
	end)
	task.delay(5.5, function()
		tween(scale, 0.3, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.32)
		banner:Destroy()
	end)
	return banner
end

-- ============================================================
-- L'AMBIANCE (ciel, couleurs, particules)
-- ============================================================
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "EventColor"
tint.Parent = Lighting

local TINTS = {
	Meteores = {TintColor = Color3.fromRGB(255, 225, 200), Saturation = 0.15, Contrast = 0.08, Brightness = 0},
	LuneDeSang = {TintColor = Color3.fromRGB(255, 150, 150), Saturation = 0.2, Contrast = 0.12, Brightness = -0.04},
	RueeOr = {TintColor = Color3.fromRGB(255, 235, 170), Saturation = 0.25, Contrast = 0.05, Brightness = 0.03},
	Orage = {TintColor = Color3.fromRGB(190, 210, 255), Saturation = -0.2, Contrast = 0.15, Brightness = -0.08},
	AdminAbuse = {TintColor = Color3.fromRGB(255, 220, 245), Saturation = 0.35, Contrast = 0.1, Brightness = 0.02},
}
local NEUTRAL = {TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0, Brightness = 0}

local ambience -- dossier client des décors de l'événement (lune, pluie...)
local function clearAmbience()
	if ambience then
		ambience:Destroy()
		ambience = nil
	end
end

local function followPart(name)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(90, 1, 90)
	p.Parent = ambience
	return p
end

local function rainEmitter(parent, props)
	local emitter = Instance.new("ParticleEmitter")
	for key, value in pairs(props) do
		emitter[key] = value
	end
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Parent = parent
	return emitter
end

local function buildAmbience(event)
	clearAmbience()
	ambience = Instance.new("Folder")
	ambience.Name = "EventAmbience"
	ambience.Parent = Workspace.CurrentCamera or Workspace
	if event.Id == "LuneDeSang" then
		local moon = Instance.new("Part")
		moon.Name = "BloodMoon"
		moon.Shape = Enum.PartType.Ball
		moon.Size = Vector3.new(140, 140, 140)
		moon.Material = Enum.Material.Neon
		moon.Color = Color3.fromRGB(255, 40, 50)
		moon.Anchored = true
		moon.CanCollide = false
		moon.CanQuery = false
		moon.CanTouch = false
		moon.CastShadow = false
		moon.Parent = ambience
		local halo = moon:Clone()
		halo.Name = "MoonHalo"
		halo.Size = Vector3.new(190, 190, 190)
		halo.Transparency = 0.8
		halo.Color = Color3.fromRGB(255, 80, 60)
		halo.Parent = ambience
		local embers = followPart("Embers")
		rainEmitter(embers, {
			Name = "BloodEmbers",
			Color = ColorSequence.new(Color3.fromRGB(255, 80, 70), Color3.fromRGB(120, 0, 10)),
			LightEmission = 0.8,
			Rate = 25,
			Lifetime = NumberRange.new(4, 6),
			Speed = NumberRange.new(3, 6),
			Size = NumberSequence.new(0.35, 0),
			SpreadAngle = Vector2.new(40, 40),
		})
	elseif event.Id == "RueeOr" then
		local coins = followPart("GoldRain")
		rainEmitter(coins, {
			Name = "GoldCoins",
			Color = ColorSequence.new(Color3.fromRGB(255, 225, 80), Color3.fromRGB(255, 170, 20)),
			LightEmission = 0.5,
			Rate = 60,
			Lifetime = NumberRange.new(2.5, 3.5),
			Speed = NumberRange.new(14, 22),
			Size = NumberSequence.new(0.7),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-200, 200),
			SpreadAngle = Vector2.new(15, 15),
		})
	elseif event.Id == "AdminAbuse" then
		local confetti = followPart("GoldRain")
		rainEmitter(confetti, {
			Name = "AbuseRain",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 200)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 225, 80)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 220, 255)),
			}),
			LightEmission = 0.6,
			Rate = 90,
			Lifetime = NumberRange.new(2.5, 3.5),
			Speed = NumberRange.new(14, 22),
			Size = NumberSequence.new(0.6),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-250, 250),
			SpreadAngle = Vector2.new(20, 20),
		})
	elseif event.Id == "Orage" then
		local rain = followPart("StormRain")
		rainEmitter(rain, {
			Name = "Rain",
			Color = ColorSequence.new(Color3.fromRGB(180, 210, 255)),
			Transparency = NumberSequence.new(0.4),
			Rate = 220,
			Lifetime = NumberRange.new(1.2, 1.6),
			Speed = NumberRange.new(60, 75),
			Size = NumberSequence.new(0.12),
			Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
			Squash = NumberSequence.new(3),
		})
	end
end

local function setEvent(event)
	if event then
		tween(tint, 2, TINTS[event.Id] or NEUTRAL)
		buildAmbience(event)
	else
		tween(tint, 2, NEUTRAL)
		clearAmbience()
	end
end

-- la lune et la pluie suivent la caméra ; le cœur des météores pulse
RunService.RenderStepped:Connect(function()
	if not ambience then return end
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local position = camera.CFrame.Position
	local moon = ambience:FindFirstChild("BloodMoon")
	if moon then
		local spot = position + Vector3.new(-0.55, 0.45, -0.7).Unit * 1400
		moon.Position = spot
		local halo = ambience:FindFirstChild("MoonHalo")
		if halo then
			halo.Position = spot
		end
	end
	for _, name in ipairs({"Embers", "GoldRain", "StormRain"}) do
		local p = ambience:FindFirstChild(name)
		if p then
			p.Position = position + Vector3.new(0, 30, 0)
		end
	end
	local meteors = Workspace:FindFirstChild("Meteors")
	if meteors then
		local pulse = 0.35 + math.sin(os.clock() * 4) * 0.2
		for _, meteor in ipairs(meteors:GetChildren()) do
			local core = meteor:FindFirstChild("Core")
			if core then
				core.Transparency = pulse
			end
		end
	end
end)

-- ⚡ un éclair (client) : zigzag de néon du ciel au sol + flash + tonnerre
function Events.lightning(position)
	local folder = Instance.new("Folder")
	folder.Name = "Lightning"
	folder.Parent = Workspace.CurrentCamera or Workspace
	local top = position + Vector3.new(math.random(-20, 20), 220, math.random(-20, 20))
	local last = top
	for i = 1, 8 do
		local alpha = i / 8
		local nextPoint = top:Lerp(position, alpha) + (i < 8 and Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)) or Vector3.zero)
		local bolt = Instance.new("Part")
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.CanQuery = false
		bolt.CanTouch = false
		bolt.Material = Enum.Material.Neon
		bolt.Color = Color3.fromRGB(200, 230, 255)
		bolt.Size = Vector3.new(1.2, 1.2, (nextPoint - last).Magnitude)
		bolt.CFrame = CFrame.lookAt((last + nextPoint) / 2, nextPoint)
		bolt.Parent = folder
		tween(bolt, 0.35, {Transparency = 1})
		last = nextPoint
	end
	task.delay(0.4, function()
		folder:Destroy()
	end)
	tint.Brightness = 0.35
	local event = GameConfig.getEvent(ReplicatedStorage:GetAttribute("EventId") or "")
	tween(tint, 0.3, {Brightness = (event and TINTS[event.Id] or NEUTRAL).Brightness})
	pcall(Sounds.play, "Break", position, 0.35)
end

-- ☄️ impact d'un météore : onde de choc + l'écran tremble si on est près
function Events.impact(position)
	local ring = Instance.new("Part")
	ring.Name = "Shockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 150, 50)
	ring.Size = Vector3.new(0.5, 4, 4)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace.CurrentCamera or Workspace
	tween(ring, 0.7, {Size = Vector3.new(0.5, 70, 70), Transparency = 1})
	task.delay(0.75, function()
		ring:Destroy()
	end)
	pcall(Sounds.play, "Break", position, 0.5)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position - position).Magnitude < 180 then
		Effects.shakeCamera(1.6, 10)
	end
end

local handlers = {}
function handlers.start(payload)
	local event = GameConfig.getEvent(payload.Id)
	if not event then return end
	Events.banner(event)
	setEvent(event)
	updatePill()
end
function handlers.stop()
	setEvent(nil)
	updatePill()
end
function handlers.lightning(payload)
	if payload.World == myWorld() then
		Events.lightning(payload.Position)
	end
end
function handlers.impact(payload)
	if payload.World == myWorld() then
		Events.impact(payload.Position)
	end
end
function handlers.soon()
	soonUntil = os.time() + 3
	pcall(Sounds.play, "Alarm")
	updatePill()
end
function handlers.reward()
	pcall(Sounds.play, "RareCard")
end

function Events.init()
	Remotes.EventFx.OnClientEvent:Connect(function(kind, payload)
		local handler = handlers[kind]
		if handler then
			handler(payload or {})
		end
	end)
	-- un événement déjà en cours quand on arrive
	local current = GameConfig.getEvent(ReplicatedStorage:GetAttribute("EventId") or "")
	if current then
		setEvent(current)
	end
	updatePill()
	task.spawn(function()
		while true do
			updatePill()
			task.wait(1)
		end
	end)
end

return Events
