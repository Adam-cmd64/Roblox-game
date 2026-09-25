-- ModuleScript client : effets dans le monde.
--   - les lasers de MA base me laissent passer (les autres joueurs sont bloqués)
--   - les boutons E des emplacements n'apparaissent que dans MA base
--   - reflet holographique qui passe sur toutes les cartes
--   - dégradé arc-en-ciel animé pour la mutation Arc-en-ciel

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

local World = {}

local function isMine(plot)
	return plot:GetAttribute("OwnerId") == player.UserId
end

local function applyPrompt(plot, prompt)
	prompt.Enabled = isMine(plot) and prompt:GetAttribute("Active") ~= false
end

local function updatePlot(plot)
	local mine = isMine(plot)
	local lasers = plot:FindFirstChild("Lasers")
	if lasers then
		for _, laser in ipairs(lasers:GetChildren()) do
			-- CanCollide changé côté client = seul MON personnage peut traverser
			laser.CanCollide = not mine
			laser.Transparency = mine and 0.55 or 0
		end
	end
	for _, prompt in ipairs(plot:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			applyPrompt(plot, prompt)
		end
	end
end

local function watchPlot(plot)
	updatePlot(plot)
	plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
		updatePlot(plot)
	end)
	for _, prompt in ipairs(plot:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			prompt:GetAttributeChangedSignal("Active"):Connect(function()
				applyPrompt(plot, prompt)
			end)
		end
	end
end

-- Liste des dégradés animés
local shines = {}
local rainbows = {}
local function track(tag, list)
	for _, obj in ipairs(CollectionService:GetTagged(tag)) do
		list[obj] = true
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(obj)
		list[obj] = true
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(obj)
		list[obj] = nil
	end)
end

function World.init()
	local plotsFolder = Workspace:WaitForChild("Plots")
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		watchPlot(plot)
	end
	plotsFolder.ChildAdded:Connect(function(plot)
		task.wait(1)
		watchPlot(plot)
	end)

	track("HoloShine", shines)
	track("RainbowGradient", rainbows)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		-- le reflet traverse la carte toutes les 3 secondes
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
	end)
end

return World
