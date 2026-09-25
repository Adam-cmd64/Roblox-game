-- ModuleScript client : effets dans le monde.
--   - dessine les cartes posées sur les podiums et les cartes tenues en main
--   - les lasers de MA base me laissent passer (les autres joueurs sont bloqués)
--   - les boutons E des emplacements n'apparaissent que dans MA base
--   - flèches des tapis roulants qui défilent
--   - reflet holographique sur les cartes + mutation arc-en-ciel animée

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
		gui.PixelsPerStud = math.clamp(260 / part.Size.X, 40, 160)
		gui.LightInfluence = 0
		gui.MaxDistance = 90
		CardRenderer.create(cardName, part:GetAttribute("Mutation") or "Normal", gui)
		gui.Parent = part
	end
end

-- ====== BASES ======
local function isMine(plot)
	return plot:GetAttribute("OwnerId") == player.UserId
end

local function applyPrompt(plot, prompt)
	prompt.Enabled = isMine(plot) and prompt:GetAttribute("Active") ~= false
end

local function watchPrompt(plot, prompt)
	applyPrompt(plot, prompt)
	prompt:GetAttributeChangedSignal("Active"):Connect(function()
		applyPrompt(plot, prompt)
	end)
end

local function updatePlot(plot)
	local mine = isMine(plot)
	local lasers = plot:FindFirstChild("Lasers")
	if lasers then
		for _, laser in ipairs(lasers:GetChildren()) do
			if laser:IsA("BasePart") then
				-- CanCollide changé côté client = seul MON personnage peut traverser
				laser.CanCollide = not mine
				laser.Transparency = mine and 0.55 or 0
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
	for _, prompt in ipairs(plot:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			watchPrompt(plot, prompt)
		end
	end
	-- Les étages construits plus tard ajoutent de nouveaux boutons
	plot.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			watchPrompt(plot, descendant)
		end
	end)
	plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
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

	track("CardDisplay", cards, function(part)
		task.defer(drawCard, part)
	end)
	track("HoloShine", shines)
	track("RainbowGradient", rainbows)
	track("ConveyorChevron", chevrons)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()

		-- Reflet qui traverse les cartes toutes les 3 secondes
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

		-- Flèches des tapis : une vague lumineuse qui avance
		local wave = t * 1.2
		for arrow in pairs(chevrons) do
			if arrow.Parent then
				local phase = arrow:GetAttribute("Phase") or 0
				local lit = (wave - phase) % 1 < 0.35
				arrow.Transparency = lit and 0 or 0.7
			else
				chevrons[arrow] = nil
			end
		end
	end)
end

return World
