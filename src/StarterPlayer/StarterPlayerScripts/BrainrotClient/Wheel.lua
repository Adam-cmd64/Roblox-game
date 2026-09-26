-- ModuleScript client : la roue de la fortune.
--   - anime la VRAIE roue dans le monde quand quelqu'un la fait tourner (tout le monde la voit)
--   - écrit au-dessus de la roue MES infos (tour gratuit, nombre de tours)
--   - la fenêtre "acheter des tours" (touche F à la roue) : 1, 3 ou 10 tours

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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

-- ============================================================
-- FENETRE (touche F à la roue)
-- ============================================================
local window = UIKit.window("Roue de la fortune", UDim2.new(0, 520, 0, 470), Color3.fromRGB(255, 120, 60))
Wheel.window = window
local content = window.content

local freeLabel = UIKit.label(content, "", {Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 6), Font = UIKit.TitleFont})
local spinsLabel = UIKit.label(content, "", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 44), Font = UIKit.TitleFont, TextColor3 = T.Gold})
local spinButton = UIKit.button(content, "TOURNER !", T.Green, {Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 82)})

UIKit.label(content, "ACHETER DES TOURS", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 160), Font = UIKit.TitleFont, TextColor3 = T.SubText})
for i, key in ipairs({"Spin1", "Spin3", "Spin10"}) do
	local product = GameConfig.PRODUCTS[key]
	UIKit.button(content, product.Spins .. " TOUR" .. (product.Spins > 1 and "S" or "") .. "  •  R$ " .. product.Price, T.Pink, {
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 0, 192 + (i - 1) * 60),
	}).MouseButton1Click:Connect(function()
		Remotes.BuyProduct:FireServer(key)
	end)
end

local spinning = false

local function refresh()
	local left = freeSpinLeft()
	if left <= 0 then
		freeLabel.Text = "TOUR GRATUIT DISPO !"
		freeLabel.TextColor3 = T.Green
	else
		freeLabel.Text = "Gratuit dans " .. GameConfig.formatTime(left)
		freeLabel.TextColor3 = T.SubText
	end
	spinsLabel.Text = "Tes tours : " .. spins.Value
	local canSpin = left <= 0 or spins.Value > 0
	UIKit.setButtonColor(spinButton, (canSpin and not spinning) and T.Green or T.Gray)
end

spinButton.MouseButton1Click:Connect(function()
	if spinning then return end
	window.close()
	Remotes.SpinWheel:FireServer()
end)

-- ============================================================
-- LA ROUE DANS LE MONDE
-- ============================================================
local wheelModel, disc, baseCFrame, infoGui
local angle = 0 -- rotation actuelle (degrés)

-- Angle où la case "index" est pile sous la flèche
local function restAngle(index, jitter)
	return -(index - 1) * SEGMENT + (jitter or 0)
end

local function setAngle(value)
	angle = value
	if disc and baseCFrame then
		disc:PivotTo(baseCFrame * CFrame.Angles(0, 0, math.rad(value)))
	end
end

local function animateSpin()
	local index = wheelModel:GetAttribute("Result") or 1
	local target = restAngle(index, wheelModel:GetAttribute("Jitter"))
	-- 5 tours complets + ce qu'il faut pour tomber sur la case
	local finalAngle = angle + 360 * 5 + ((target - angle) % 360)
	local duration = wheelModel:GetAttribute("SpinTime") or 5
	spinning = true

	local value = Instance.new("NumberValue")
	value.Value = angle
	local lastSegment = math.floor(angle / SEGMENT + 0.5)
	local position = baseCFrame.Position
	local connection = RunService.RenderStepped:Connect(function()
		setAngle(value.Value)
		local segment = math.floor(value.Value / SEGMENT + 0.5)
		if segment ~= lastSegment then
			lastSegment = segment
			Sounds.play("Tick", position)
		end
	end)
	local tween = TweenService:Create(value, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = finalAngle})
	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	value:Destroy()
	setAngle(finalAngle % 360)
	spinning = false
end

local function refreshBoard()
	if not infoGui then return end
	local freeText = infoGui:FindFirstChild("FreeLabel")
	if freeText and freeText:IsA("TextLabel") then
		local left = freeSpinLeft()
		if left <= 0 then
			freeText.Text = "TOUR GRATUIT DISPO !"
			freeText.TextColor3 = Color3.fromRGB(120, 255, 140)
		else
			freeText.Text = "Gratuit dans " .. GameConfig.formatTime(left) .. "   •   Tes tours : " .. spins.Value
			freeText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

local function setupWorldWheel()
	wheelModel = Workspace:WaitForChild("FortuneWheel", 30)
	if not wheelModel then return end
	disc = wheelModel:WaitForChild("Disc", 10)
	baseCFrame = wheelModel:GetAttribute("DiscCFrame")
	local anchor = wheelModel:FindFirstChild("InfoAnchor")
	infoGui = anchor and anchor:FindFirstChild("WheelInfo")
	-- position de repos (le dernier résultat)
	setAngle(restAngle(wheelModel:GetAttribute("Result") or 1, wheelModel:GetAttribute("Jitter")))
	wheelModel:GetAttributeChangedSignal("SpinId"):Connect(function()
		task.spawn(animateSpin)
	end)
	refreshBoard()
end

function Wheel.init(Panels, Hud)
	task.spawn(setupWorldWheel)

	Remotes.OpenWheel.OnClientEvent:Connect(window.open)
	Remotes.WheelResult.OnClientEvent:Connect(function(index, details)
		local prize = PRIZES[index]
		if prize then
			Hud.notify("🎡 " .. describe(prize, details), "success")
		end
		if details.Card then
			Hud.showCardFound(details.Card, details.Mutation, details.Serial)
		elseif details.Cards then
			task.wait(0.6)
			Panels.openBooster("Galaxie", details.Cards)
		end
	end)
	spins.Changed:Connect(function()
		refresh()
		refreshBoard()
	end)
	window.onOpen = refresh
	task.spawn(function()
		while true do
			if window.isOpen() then
				refresh()
			end
			refreshBoard()
			task.wait(1)
		end
	end)
end

return Wheel
