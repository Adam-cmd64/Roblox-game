-- ModuleScript serveur : les ÉVÉNEMENTS DE SERVEUR (voir GameConfig.EVENTS).
--
-- Toutes les 10 minutes, un événement de 3 minutes touche TOUT le serveur :
--   ☄️ Pluie de Météores, 🩸 Lune de Sang, 💰 Ruée vers l'Or, ⚡ Orage Brainrot.
-- L'événement en cours est écrit dans des attributs de ReplicatedStorage (les clients les lisent) :
--   EventId (vide = pas d'événement), EventEnds (os.time() de la fin), NextEvent (os.time() du prochain).
-- Le minage (init.server.lua) demande ici les bonus : luckMultiplier, cashMultiplier, mutate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CONFIG = GameConfig.EVENTS

local EventManager = {}

local deps
local current -- l'événement en cours (table de GameConfig.EVENTS.List) ou nil
local runId = 0 -- change à chaque événement (pour arrêter les boucles de l'ancien)
local lastId -- pour ne pas avoir deux fois le même événement de suite
local meteorFolder

function EventManager.getCurrent()
	return current
end

function EventManager.luckMultiplier()
	return current and current.LuckMultiplier or 1
end

function EventManager.cashMultiplier()
	return current and current.CashMultiplier or 1
end

-- Pendant un événement, un brainrot miné peut recevoir la mutation de l'événement
-- (seulement si elle vaut mieux que celle qu'il a déjà)
function EventManager.mutate(mutation)
	if not current or not current.Mutation or not current.MutationChance then
		return mutation
	end
	local old = GameConfig.MUTATIONS[mutation or "Normal"] or GameConfig.MUTATIONS.Normal
	local new = GameConfig.MUTATIONS[current.Mutation]
	if new and new.Multiplier > old.Multiplier and math.random() < current.MutationChance then
		return current.Mutation
	end
	return mutation
end

-- ============================================================
-- ☄️ LES MÉTÉORES
-- ============================================================
local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = parent
	return p
end

-- Ouvrir un météore : un brainrot (chance x3) avec la mutation MÉTÉORE garantie
local function claimMeteor(player, meteor, world)
	local claimed = meteor:FindFirstChild("Claimed")
	if not claimed or claimed:FindFirstChild(tostring(player.UserId)) then
		deps.Remotes.notify(player, "☄️ Tu as déjà ouvert ce météore !", "error")
		return
	end
	local mark = Instance.new("BoolValue")
	mark.Name = tostring(player.UserId)
	mark.Parent = claimed
	local event = GameConfig.getEvent("Meteores")
	local pickaxe = GameConfig.getPlayerPickaxe(player)
	local luck = pickaxe.Luck * (event.MeteorLuck or 1)
	local cardName = deps.Loot.rollMined(luck, 1, deps.PlayerData.hasLuckPotion(player), world)
	local item = deps.PlayerData.addItem(player, cardName, event.Mutation, 0, nil, "a trouvé dans un météore")
	if item then
		deps.Remotes.CardFound:FireClient(player, cardName, event.Mutation, item:GetAttribute("Serial"))
		deps.Remotes.EventFx:FireClient(player, "reward", {Position = meteor.PrimaryPart and meteor.PrimaryPart.Position})
		task.spawn(deps.PlayerData.save, player)
	end
end

local function spawnMeteor(world, id)
	local center = deps.MineManager.getCenter(world)
	local angle = math.random() * math.pi * 2
	local radius = deps.MineHalf + 10 + math.random() * 20
	local ground = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local sky = ground + Vector3.new(math.random(-90, 90), 260, math.random(-90, 90))

	-- la boule de feu qui tombe
	local fireball = part({
		Name = "FallingMeteor",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9, 9, 9),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 120, 30),
		Position = sky,
	}, meteorFolder)
	local fire = Instance.new("Fire")
	fire.Size = 18
	fire.Heat = 25
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 40, 0)
	fire.Parent = fireball
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 3, 0)
	a0.Parent = fireball
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -3, 0)
	a1.Parent = fireball
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.8
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 40, 0))
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Parent = fireball
	deps.Remotes.EventFx:FireAllClients("falling", {Position = ground, World = world})
	TweenService:Create(fireball, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = ground + Vector3.new(0, 3, 0)}):Play()
	task.wait(2.2)
	fireball:Destroy()
	if runId ~= id then return end -- l'événement s'est arrêté pendant la chute

	-- le cratère + le météore à ouvrir
	local model = Instance.new("Model")
	model.Name = "Meteor"
	model.Parent = meteorFolder
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2
		part({
			Name = "Crater",
			Size = Vector3.new(5, 1.4 + math.random(), 3),
			Material = Enum.Material.Basalt,
			Color = Color3.fromRGB(45, 35, 32),
			CFrame = CFrame.new(ground + Vector3.new(math.cos(a) * 8, 0.4, math.sin(a) * 8)) * CFrame.Angles(0, -a, math.rad(math.random(-25, -10))),
		}, model)
	end
	part({
		Name = "Scorch",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 19, 19),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 90, 20),
		Transparency = 0.55,
		CFrame = CFrame.new(ground + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	}, model)
	local rock = part({
		Name = "Rock",
		Size = Vector3.new(7, 6, 7),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(60, 40, 38),
		CFrame = CFrame.new(ground + Vector3.new(0, 3, 0)) * CFrame.Angles(math.rad(math.random(-20, 20)), math.random() * 6, math.rad(math.random(-20, 20))),
		CanCollide = true,
	}, model)
	local core = part({
		Name = "Core",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(7.6, 7.6, 7.6),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 110, 20),
		Transparency = 0.35,
		Position = rock.Position,
	}, model)
	core:SetAttribute("PulseCore", true)
	model.PrimaryPart = rock
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 130, 40)
	light.Brightness = 3
	light.Range = 26
	light.Parent = rock
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(70, 50, 45)
	smoke.Opacity = 0.18
	smoke.RiseVelocity = 6
	smoke.Size = 6
	smoke.Parent = rock
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "MeteorSparks"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 70, 0))
	sparks.LightEmission = 1
	sparks.Rate = 14
	sparks.Lifetime = NumberRange.new(0.6, 1.2)
	sparks.Speed = NumberRange.new(6, 14)
	sparks.SpreadAngle = Vector2.new(60, 60)
	sparks.Size = NumberSequence.new(0.5, 0)
	sparks.Parent = rock
	local claimed = Instance.new("Folder")
	claimed.Name = "Claimed"
	claimed.Parent = model

	-- l'étiquette au-dessus
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MeteorLabel"
	billboard.Size = UDim2.new(0, 240, 0, 70)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 220
	billboard.Parent = rock
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.LuckiestGuy
	title.TextScaled = true
	title.Text = "☄️ MÉTÉORE"
	title.TextColor3 = Color3.fromRGB(255, 190, 70)
	title.TextStrokeTransparency = 0
	title.Parent = billboard
	local sub = Instance.new("TextLabel")
	sub.Position = UDim2.new(0, 0, 0.6, 0)
	sub.Size = UDim2.new(1, 0, 0.4, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.Text = "Brainrot + mutation MÉTÉORE !"
	sub.TextColor3 = Color3.new(1, 1, 1)
	sub.TextStrokeTransparency = 0
	sub.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenMeteor"
	prompt.ActionText = "Ouvrir le météore"
	prompt.ObjectText = "☄️ Météore"
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = rock
	prompt.Triggered:Connect(function(player)
		if runId ~= id or not model.Parent then return end
		claimMeteor(player, model, world)
	end)
	deps.Remotes.EventFx:FireAllClients("impact", {Position = ground, World = world})
	return model
end
EventManager.spawnMeteor = spawnMeteor

-- ============================================================
-- ⚡ LES ÉCLAIRS de l'orage (sur la mine, pour l'ambiance)
-- ============================================================
local function strike(world)
	local center = deps.MineManager.getCenter(world)
	local spot = center + Vector3.new(math.random(-60, 60), 0, math.random(-60, 60))
	deps.Remotes.EventFx:FireAllClients("lightning", {Position = spot, World = world})
end

-- ============================================================
-- DÉMARRER / ARRÊTER
-- ============================================================
function EventManager.stop()
	if not current then return end
	local ended = current
	current = nil
	runId += 1
	ReplicatedStorage:SetAttribute("EventId", "")
	ReplicatedStorage:SetAttribute("EventEnds", 0)
	meteorFolder:ClearAllChildren()
	deps.Remotes.EventFx:FireAllClients("stop", {Id = ended.Id})
end

function EventManager.start(eventId, duration)
	local event = GameConfig.getEvent(eventId)
	if not event then return false end
	if current then
		EventManager.stop()
	end
	current = event
	lastId = event.Id
	runId += 1
	local id = runId
	duration = duration or CONFIG.Duration
	local ends = os.time() + duration
	ReplicatedStorage:SetAttribute("EventId", event.Id)
	ReplicatedStorage:SetAttribute("EventEnds", ends)
	deps.Remotes.EventFx:FireAllClients("start", {Id = event.Id, Ends = ends})
	for _, player in ipairs(Players:GetPlayers()) do
		deps.Remotes.notify(player, event.Icon .. " ÉVÉNEMENT : " .. GameConfig.upper(event.Name) .. " ! " .. event.Description, "warning")
	end

	-- ce que fait l'événement pendant qu'il tourne
	if event.Meteors then
		task.spawn(function()
			local gap = (duration - 20) / event.Meteors
			for _ = 1, event.Meteors do
				if runId ~= id then return end
				for _, world in ipairs(GameConfig.WORLDS) do
					task.spawn(spawnMeteor, world.Id, id)
				end
				task.wait(math.max(2.5, gap))
			end
		end)
	end
	if event.Id == "Orage" then
		task.spawn(function()
			while runId == id do
				for _, world in ipairs(GameConfig.WORLDS) do
					strike(world.Id)
				end
				task.wait(2 + math.random() * 3)
			end
		end)
	end
	task.delay(duration, function()
		if runId == id then
			EventManager.stop()
		end
	end)
	return true
end

-- un événement au hasard (jamais deux fois le même de suite)
function EventManager.startRandom()
	local choices = {}
	for _, event in ipairs(CONFIG.List) do
		if event.Id ~= lastId then
			table.insert(choices, event)
		end
	end
	local event = choices[math.random(1, #choices)]
	return EventManager.start(event.Id)
end

function EventManager.init(dependencies)
	deps = dependencies
	meteorFolder = Instance.new("Folder")
	meteorFolder.Name = "Meteors"
	meteorFolder.Parent = Workspace
	EventManager.folder = meteorFolder
	ReplicatedStorage:SetAttribute("EventId", "")
	ReplicatedStorage:SetAttribute("EventEnds", 0)
	local nextAt = os.time() + CONFIG.First
	ReplicatedStorage:SetAttribute("NextEvent", nextAt)
	task.spawn(function()
		while true do
			task.wait(1)
			if CONFIG.Auto ~= false and not current and os.time() >= nextAt then
				EventManager.startRandom()
				nextAt = os.time() + CONFIG.Every
				ReplicatedStorage:SetAttribute("NextEvent", nextAt)
			elseif current and os.time() >= nextAt then
				-- un événement lancé à la main dure plus longtemps que prévu : on décale le suivant
				nextAt = os.time() + CONFIG.Every
				ReplicatedStorage:SetAttribute("NextEvent", nextAt)
			end
		end
	end)
end

return EventManager
