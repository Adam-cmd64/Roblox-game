-- ModuleScript client : effets dans le monde.
--   - dessine les cartes posées dans les bases et les cartes tenues en main
--   - lasers : allumés seulement quand la base est verrouillée ; le propriétaire passe à travers
--   - boutons E : "poser / reprendre / verrouiller" seulement dans MA base,
--     "voler" seulement dans les bases des autres quand elles sont ouvertes
--   - flèches des tapis, reflets des cartes
--   - compte à rebours du PORTAIL MYSTÈRE

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))

local player = Players.LocalPlayer

local World = {}

-- ====== CARTES DANS LE MONDE ======
local function drawCard(part)
	if not part:IsA("BasePart") or part:FindFirstChild("CardGui") then return end
	local cardName = part:GetAttribute("CardName")
	if not cardName then return end
	local faces = {Enum.NormalId.Front}
	if part:GetAttribute("DoubleSided") then
		table.insert(faces, Enum.NormalId.Back)
	end
	for _, face in ipairs(faces) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "CardGui"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = math.clamp(300 / part.Size.X, 40, 160)
		gui.LightInfluence = 0
		gui.MaxDistance = 90
		CardRenderer.create(cardName, part:GetAttribute("Mutation") or "Normal", gui, part:GetAttribute("Serial"), GameConfig.getFusion(part))
		gui.Parent = part
	end
end

-- ====== BASES ======
local plots = {}

local function isMine(plot)
	return plot:GetAttribute("OwnerId") == player.UserId
end

-- Le propriétaire me laisse passer ses lasers ? (option "amis" + on est amis sur Roblox)
local friendCache = {}
local function friendAllowed(plot)
	local ownerId = plot:GetAttribute("OwnerId") or 0
	if ownerId == 0 or ownerId == player.UserId then return false end
	local owner = Players:GetPlayerByUserId(ownerId)
	if not owner or owner:GetAttribute("Setting_FriendsCanEnter") ~= true then return false end
	if friendCache[ownerId] == nil then
		friendCache[ownerId] = false
		task.spawn(function()
			local ok, result = pcall(function()
				return player:IsFriendsWith(ownerId)
			end)
			friendCache[ownerId] = ok and result == true
		end)
	end
	return friendCache[ownerId]
end

local function isLocked(plot)
	return (plot:GetAttribute("LockedUntil") or 0) > Workspace:GetServerTimeNow()
end

local function applyPrompt(plot, prompt)
	local active = prompt:GetAttribute("Active") ~= false
	if prompt:GetAttribute("Hack") then
		-- Pirater : base d'un autre joueur, VERROUILLÉE, et je ne porte rien
		prompt.Enabled = active
			and not isMine(plot)
			and plot:GetAttribute("OwnerId") ~= 0
			and isLocked(plot)
			and player:GetAttribute("Carrying") == nil
	elseif prompt:GetAttribute("Steal") then
		-- Voler : base d'un autre joueur, ouverte, emplacement occupé, et je ne porte rien
		prompt.Enabled = active
			and not isMine(plot)
			and plot:GetAttribute("OwnerId") ~= 0
			and not isLocked(plot)
			and player:GetAttribute("Carrying") == nil
	else
		prompt.Enabled = active and isMine(plot)
	end
end

-- Suis-je déjà à l'intérieur de cette base (derrière la ligne des lasers) ?
local function isInside(plot)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local floor = plot:FindFirstChild("Floor")
	if not root or not floor then return false end
	local rel = floor.CFrame:PointToObjectSpace(root.Position)
	return math.abs(rel.X) < floor.Size.X / 2 and rel.Z > -floor.Size.Z / 2 + 2.6 and rel.Z < floor.Size.Z / 2 + 1
end

-- Tous les lasers de la base (rez-de-chaussée + chaque étage : des dossiers "Lasers")
-- CanCollide changé côté client = ça ne concerne que MON personnage
local function applyLasers(plot)
	local pass = isMine(plot) or friendAllowed(plot)
	local locked = isLocked(plot)
	local inside = isInside(plot)
	for _, folder in ipairs(plot:GetDescendants()) do
		if folder:IsA("Folder") and folder.Name == "Lasers" then
			for _, laser in ipairs(folder:GetChildren()) do
				if laser:IsA("BasePart") then
					if laser:GetAttribute("Wall") then
						-- le mur invisible : bloque les autres, mais laisse sortir quelqu'un qui est déjà dedans
						laser.CanCollide = locked and not pass and not inside
					else
						laser.CanCollide = locked and not pass
						laser.Transparency = locked and (pass and 0.55 or 0) or 1
					end
				end
			end
		end
	end
end

local function updatePlot(plot)
	applyLasers(plot)
	for _, prompt in ipairs(plot:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			applyPrompt(plot, prompt)
		end
	end
end

local function watchPlot(plot)
	plots[plot] = {locked = nil}
	for _, prompt in ipairs(plot:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt:GetAttributeChangedSignal("Active"):Connect(function()
				applyPrompt(plot, prompt)
			end)
		end
	end
	-- Les étages construits plus tard ajoutent de nouveaux boutons
	plot.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			applyPrompt(plot, descendant)
			descendant:GetAttributeChangedSignal("Active"):Connect(function()
				applyPrompt(plot, descendant)
			end)
		end
	end)
	plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
		updatePlot(plot)
	end)
	plot:GetAttributeChangedSignal("LockedUntil"):Connect(function()
		updatePlot(plot)
	end)
	updatePlot(plot)
end

-- ====== LISTES D'OBJETS ANIMÉS ======
local function track(tag, list, onAdded)
	for _, obj in ipairs(CollectionService:GetTagged(tag)) do
		list[obj] = true
		if onAdded then onAdded(obj) end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(obj)
		list[obj] = true
		if onAdded then onAdded(obj) end
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(obj)
		list[obj] = nil
	end)
end

local shines = {}
local rainbows = {}
local spinners = {}
local foils = {}
local sparkles = {}
local pulses = {}
local raySpins = {}
local statues = {}
local blinkers = {}
local spinCards = {}
local portalRings = {}
local chevrons = {}
local cards = {}

function World.init()
	local plotsFolder = Workspace:WaitForChild("Plots")
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		watchPlot(plot)
	end
	plotsFolder.ChildAdded:Connect(watchPlot)

	-- Le mur des lasers : on revérifie souvent si je suis dedans ou dehors
	task.spawn(function()
		while true do
			task.wait(0.3)
			for plot in pairs(plots) do
				applyLasers(plot)
			end
		end
	end)

	-- Quand je commence / arrête de porter un brainrot volé, les boutons "Voler" changent
	player:GetAttributeChangedSignal("Carrying"):Connect(function()
		for plot in pairs(plots) do
			updatePlot(plot)
		end
	end)

	-- La fin du verrou n'envoie pas d'événement : on vérifie régulièrement
	task.spawn(function()
		while true do
			task.wait(0.5)
			for plot, state in pairs(plots) do
				local locked = isLocked(plot)
				if locked ~= state.locked then
					state.locked = locked
					updatePlot(plot)
				end
			end
		end
	end)

	track("CardDisplay", cards, function(part)
		task.defer(drawCard, part)
	end)
	track("HoloShine", shines)
	track("RainbowGradient", rainbows)
	track("SpinGradient", spinners)
	track("HoloFoil", foils)
	track("Sparkle", sparkles)
	track("MutationPulse", pulses)
	track("RaySpin", raySpins)
	track("StatueBob", statues)
	track("Blink", blinkers)
	track("SpinCard", spinCards)
	track("PortalSpin", portalRings)
	track("ConveyorChevron", chevrons)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()

		local offset = ((t % 3) / 3) * 3 - 1.5
		for gradient in pairs(shines) do
			if gradient.Parent then
				gradient.Offset = Vector2.new(offset, 0)
			else
				shines[gradient] = nil
			end
		end

		local rotation = (t * 90) % 360
		for gradient in pairs(rainbows) do
			if gradient.Parent then
				gradient.Rotation = rotation
			else
				rainbows[gradient] = nil
			end
		end

		-- Effets des cartes : bord des mutations qui tourne, reflet holographique, étincelles, lueur, rayons
		local spin = (t * 70) % 360
		for gradient in pairs(spinners) do
			if gradient.Parent then
				gradient.Rotation = spin
			else
				spinners[gradient] = nil
			end
		end
		local foilOffset = Vector2.new(math.sin(t * 0.9) * 0.7, math.cos(t * 0.6) * 0.2)
		for gradient in pairs(foils) do
			if gradient.Parent then
				gradient.Offset = foilOffset
				gradient.Rotation = 35 + math.sin(t * 0.5) * 20
			else
				foils[gradient] = nil
			end
		end
		for label in pairs(sparkles) do
			if label.Parent then
				local phase = label:GetAttribute("Phase") or 0
				local wave = (math.sin(t * 3 + phase) + 1) / 2
				label.TextTransparency = 1 - wave
				label.TextStrokeTransparency = 1 - wave * 0.4
				label.Rotation = (t * 45 + phase * 40) % 360
			else
				sparkles[label] = nil
			end
		end
		local pulse = 0.72 + math.sin(t * 2.2) * 0.12
		for frame in pairs(pulses) do
			if frame.Parent then
				frame.BackgroundTransparency = pulse
			else
				pulses[frame] = nil
			end
		end
		-- Ampoules qui clignotent (roue de la fortune)
		local blinkStep = math.floor(t * 3)
		for bulb in pairs(blinkers) do
			if bulb.Parent then
				bulb.Transparency = (blinkStep + (bulb:GetAttribute("Phase") or 0)) % 2 == 0 and 0 or 0.65
			else
				blinkers[bulb] = nil
			end
		end

		-- Les anneaux du portail tournent
		for ring in pairs(portalRings) do
			if ring.Parent then
				local base = ring:GetAttribute("BaseCFrame")
				if not base then
					base = ring.CFrame
					ring:SetAttribute("BaseCFrame", base)
				end
				ring.CFrame = base * CFrame.Angles(0, t * (ring:GetAttribute("SpinSpeed") or 1), 0) -- effet gyroscope
			else
				portalRings[ring] = nil
			end
		end

		-- Les cartes tombées par terre tournent et flottent
		for part in pairs(spinCards) do
			if part.Parent then
				local base = part:GetAttribute("BaseCFrame")
				if not base then
					base = part.CFrame
					part:SetAttribute("BaseCFrame", base)
				end
				part.CFrame = base * CFrame.new(0, math.sin(t * 2.5) * 0.4, 0) * CFrame.Angles(0, t * 2, 0)
			else
				spinCards[part] = nil
			end
		end

		-- Les statues de brainrots flottent doucement
		for gui in pairs(statues) do
			if gui.Parent then
				local phase = gui:GetAttribute("Phase") or 0
				gui.StudsOffset = Vector3.new(0, math.sin(t * 1.2 + phase) * 0.6, 0)
			else
				statues[gui] = nil
			end
		end

		local rayRotation = (t * 10) % 360
		for frame in pairs(raySpins) do
			if frame.Parent then
				frame.Rotation = rayRotation
			else
				raySpins[frame] = nil
			end
		end

		local wave = t * 1.2
		for arrow in pairs(chevrons) do
			if arrow.Parent then
				local phase = arrow:GetAttribute("Phase") or 0
				arrow.Transparency = (wave - phase) % 1 < 0.35 and 0 or 0.7
			else
				chevrons[arrow] = nil
			end
		end
	end)

	-- ====== COMPTE À REBOURS DU PORTAIL ======
	task.spawn(function()
		local anchor
		while true do
			if not (anchor and anchor.Parent) then
				anchor = Workspace:FindFirstChild("PortalTitle", true) -- (il peut arriver plus tard avec le streaming)
			end
			local countdown = anchor and anchor:FindFirstChild("Countdown", true)
			local caption = anchor and anchor:FindFirstChild("Caption", true)
			if countdown and caption then
				World.updatePortal(countdown, caption, (anchor:GetAttribute("OpensAt") or 0) - Workspace:GetServerTimeNow())
			end
			task.wait(0.5)
		end
	end)
end

-- Affiche le temps restant avant l'ouverture du portail (HH:MM:SS)
function World.updatePortal(countdown, caption, remaining)
	if remaining <= 0 then
		-- OUVERT : touche E pour partir dans le monde 2 (il faut être rebirth 10)
		local stats = player:FindFirstChild("leaderstats")
		local rebirths = stats and stats:FindFirstChild("Rebirths")
		local required = GameConfig.getWorld(2).RequiredRebirths or 0
		if rebirths and rebirths.Value < required then
			caption.Text = "🔒 IL FAUT ÊTRE REBIRTH " .. required
			countdown.Text = "✦ MONDE 2 ✦"
			countdown.TextColor3 = Color3.fromRGB(255, 120, 120)
			return
		end
		caption.Text = "OUVERT ! TOUCHE E"
		countdown.Text = "✦ MONDE 2 ✦"
		countdown.TextColor3 = (math.floor(os.clock() * 2) % 2 == 0) and Color3.fromRGB(120, 240, 255) or Color3.fromRGB(255, 140, 235)
		return
	end
	remaining = math.floor(remaining)
	caption.Text = "S'OUVRE DANS"
	local hours = remaining // 3600
	if hours >= 100 then
		countdown.Text = string.format("%dj %02dh", hours // 24, hours % 24) -- très loin : en jours
	else
		countdown.Text = string.format("%02d:%02d:%02d", hours, (remaining % 3600) // 60, remaining % 60)
	end
	-- la dernière minute : ça clignote
	if remaining < 60 and remaining % 2 == 0 then
		countdown.TextColor3 = Color3.fromRGB(255, 90, 200)
	else
		countdown.TextColor3 = Color3.fromRGB(120, 240, 255)
	end
end

return World
