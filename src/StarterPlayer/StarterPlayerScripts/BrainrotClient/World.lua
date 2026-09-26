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
		CardRenderer.create(cardName, part:GetAttribute("Mutation") or "Normal", gui)
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
	if prompt:GetAttribute("Steal") then
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
