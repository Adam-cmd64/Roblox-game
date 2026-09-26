-- ModuleScript client : effets dans le monde.
--   - dessine les cartes posées dans les bases et les cartes tenues en main
--   - lasers : allumés seulement quand la base est verrouillée ; le propriétaire passe à travers
--   - boutons E : "poser / reprendre / verrouiller" seulement dans MA base,
--     "voler" seulement dans les bases des autres quand elles sont ouvertes
--   - flèches des tapis, reflets des cartes

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
		CardRenderer.create(cardName, part:GetAttribute("Mutation") or "Normal", gui, part:GetAttribute("Serial"))
		gui.Parent = part
	end
end

-- ====== BASES ======
local plots = {}

local function isMine(plot)
	return plot:GetAttribute("OwnerId") == player.UserId
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

local function updatePlot(plot)
	local mine = isMine(plot)
	local locked = isLocked(plot)
	local lasers = plot:FindFirstChild("Lasers")
	if lasers then
		for _, laser in ipairs(lasers:GetChildren()) do
			if laser:IsA("BasePart") then
				-- CanCollide changé côté client = ça ne concerne que MON personnage
				laser.CanCollide = locked and not mine
				laser.Transparency = locked and (mine and 0.55 or 0) or 1
			end
		end
	end
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
end

return World
