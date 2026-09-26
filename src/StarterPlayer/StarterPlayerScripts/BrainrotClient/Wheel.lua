-- ModuleScript client : la roue de la fortune.
-- 6 cases, 1 tour gratuit toutes les 24h, tours supplémentaires en Robux.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local spins = player:WaitForChild("Spins")

local Wheel = {}
local PRIZES = GameConfig.WHEEL.Prizes
local SEGMENT = 360 / #PRIZES

local window = UIKit.window("Roue de la fortune", UDim2.new(0, 860, 0, 560), Color3.fromRGB(255, 120, 60))
Wheel.window = window
local content = window.content

-- ====== LA ROUE ======
local wheelSize = 430
local holder = Instance.new("Frame")
holder.Size = UDim2.new(0, wheelSize, 0, wheelSize)
holder.Position = UDim2.new(0, 20, 0.5, -wheelSize / 2 + 10)
holder.BackgroundTransparency = 1
holder.Parent = content

local disc = Instance.new("Frame")
disc.Name = "Disc"
disc.Size = UDim2.new(1, 0, 1, 0)
disc.BackgroundColor3 = Color3.new(1, 1, 1)
disc.Parent = holder
UIKit.corner(disc, wheelSize / 2)
UIKit.outline(disc, 6)
UIKit.gradient(disc, Color3.fromRGB(70, 60, 110), Color3.fromRGB(25, 20, 45), 90)

for index, prize in ipairs(PRIZES) do
	local angle = math.rad((index - 1) * SEGMENT)
	-- séparation entre les cases
	local divider = Instance.new("Frame")
	divider.AnchorPoint = Vector2.new(0.5, 1)
	divider.Position = UDim2.new(0.5, 0, 0.5, 0)
	divider.Size = UDim2.new(0, 5, 0.5, -4)
	divider.Rotation = (index - 1) * SEGMENT + SEGMENT / 2
	divider.BackgroundColor3 = Color3.fromRGB(255, 220, 120)
	divider.BorderSizePixel = 0
	divider.Parent = disc
	-- la pastille de la case
	local radius = 0.33
	local bubble = Instance.new("Frame")
	bubble.AnchorPoint = Vector2.new(0.5, 0.5)
	bubble.Position = UDim2.new(0.5 + math.sin(angle) * radius, 0, 0.5 - math.cos(angle) * radius, 0)
	bubble.Size = UDim2.new(0, 104, 0, 104)
	bubble.Rotation = (index - 1) * SEGMENT
	bubble.BackgroundColor3 = Color3.new(1, 1, 1)
	bubble.Parent = disc
	UIKit.corner(bubble, 52)
	UIKit.outline(bubble, 3)
	UIKit.gradient(bubble, prize.Color:Lerp(Color3.new(1, 1, 1), 0.25), prize.Color:Lerp(Color3.new(0, 0, 0), 0.35), 90)
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0.6, 0, 0.5, 0)
	icon.Position = UDim2.new(0.2, 0, 0.08, 0)
	icon.Text = prize.Icon
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Parent = bubble
	UIKit.label(bubble, prize.Name, {
		Size = UDim2.new(0.9, 0, 0.3, 0),
		Position = UDim2.new(0.05, 0, 0.6, 0),
		Font = UIKit.TitleFont,
		TextWrapped = true,
	})
end

local hub = UIKit.button(holder, "", Color3.fromRGB(255, 200, 60), {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 70, 0, 70),
	ZIndex = 3,
})
hub:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 35)
hub.Text = "★"

-- La flèche en haut
local pointer = Instance.new("Frame")
pointer.AnchorPoint = Vector2.new(0.5, 0.5)
pointer.Position = UDim2.new(0.5, 0, 0, 2)
pointer.Size = UDim2.new(0, 34, 0, 34)
pointer.Rotation = 45
pointer.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
pointer.ZIndex = 4
pointer.Parent = holder
UIKit.outline(pointer, 3)

-- ====== PANNEAU DE DROITE ======
local side = Instance.new("Frame")
side.Size = UDim2.new(1, -wheelSize - 50, 1, 0)
side.Position = UDim2.new(0, wheelSize + 40, 0, 0)
side.BackgroundTransparency = 1
side.Parent = content

local freeLabel = UIKit.label(side, "", {Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 10), Font = UIKit.TitleFont})
local spinsLabel = UIKit.label(side, "", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 50), Font = UIKit.TitleFont, TextColor3 = T.Gold})
local spinButton = UIKit.button(side, "TOURNER !", T.Green, {Size = UDim2.new(1, 0, 0, 64), Position = UDim2.new(0, 0, 0, 90)})
local resultLabel = UIKit.label(side, "", {Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 166), Font = UIKit.TitleFont, TextWrapped = true})

UIKit.label(side, "PLUS DE TOURS", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 250), Font = UIKit.TitleFont, TextColor3 = T.SubText})
for i, key in ipairs({"Spin1", "Spin3", "Spin10"}) do
	local product = GameConfig.PRODUCTS[key]
	UIKit.button(side, product.Spins .. " TOUR" .. (product.Spins > 1 and "S" or "") .. "  •  R$ " .. product.Price, T.Pink, {
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.new(0, 0, 0, 280 + (i - 1) * 56),
	}).MouseButton1Click:Connect(function()
		Remotes.BuyProduct:FireServer(key)
	end)
end

-- ====== ANIMATION ======
local spinning = false
local rotation = 0

local function freeSpinLeft()
	return GameConfig.WHEEL.FreeCooldown - (os.time() - (player:GetAttribute("LastFreeSpin") or 0))
end

local function describe(prize, details)
	if details.Cash then
		return "+$" .. GameConfig.format(details.Cash) .. " !"
	elseif details.Card then
		return details.Card .. (details.Mutation and details.Mutation ~= "Normal" and (" [" .. details.Mutation .. "]") or "") .. " !"
	elseif details.Minutes then
		return "Chance x2 pendant " .. details.Minutes .. " min !"
	elseif details.Booster then
		return "BOOSTER OG !"
	end
	return prize.Name
end

local function animateTo(index, details, onDone)
	spinning = true
	resultLabel.Text = ""
	local target = math.ceil(rotation / 360) * 360 + 360 * 6 - (index - 1) * SEGMENT + (math.random() - 0.5) * SEGMENT * 0.6
	local value = Instance.new("NumberValue")
	value.Value = rotation
	local lastSegment = math.floor(rotation / SEGMENT)
	local connection = RunService.RenderStepped:Connect(function()
		disc.Rotation = value.Value
		local segment = math.floor((value.Value + SEGMENT / 2) / SEGMENT)
		if segment ~= lastSegment then
			lastSegment = segment
			Sounds.play("Tick")
		end
	end)
	local tween = TweenService:Create(value, TweenInfo.new(4.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = target})
	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	rotation = target
	disc.Rotation = target
	value:Destroy()
	spinning = false

	local prize = PRIZES[index]
	Sounds.play("Win")
	resultLabel.Text = describe(prize, details)
	resultLabel.TextColor3 = prize.Color
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = resultLabel
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	task.delay(0.5, function()
		scale:Destroy()
	end)
	if onDone then
		onDone()
	end
end

local function refresh()
	local left = freeSpinLeft()
	if left <= 0 then
		freeLabel.Text = "TOUR GRATUIT DISPO !"
		freeLabel.TextColor3 = T.Green
	else
		freeLabel.Text = "Gratuit dans " .. GameConfig.formatTime(left)
		freeLabel.TextColor3 = T.SubText
	end
	spinsLabel.Text = "Tours : " .. spins.Value
	local canSpin = left <= 0 or spins.Value > 0
	UIKit.setButtonColor(spinButton, (canSpin and not spinning) and T.Green or T.Gray)
end

spinButton.MouseButton1Click:Connect(function()
	if spinning then return end
	Remotes.SpinWheel:FireServer()
end)
hub.MouseButton1Click:Connect(function()
	if spinning then return end
	Remotes.SpinWheel:FireServer()
end)

function Wheel.init(Panels)
	Remotes.WheelResult.OnClientEvent:Connect(function(index, details)
		if not window.isOpen() then
			window.open()
		end
		task.spawn(animateTo, index, details, function()
			if details.Cards then
				task.wait(1)
				Panels.openBooster("OG", details.Cards)
			end
		end)
	end)
	spins.Changed:Connect(refresh)
	window.onOpen = refresh
	task.spawn(function()
		while true do
			if window.isOpen() then
				refresh()
			end
			task.wait(1)
		end
	end)
end

return Wheel
