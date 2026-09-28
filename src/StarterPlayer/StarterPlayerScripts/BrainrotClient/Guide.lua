-- ModuleScript client : le GUIDE des débutants.
-- Une petite bannière en haut de l'écran qui dit quoi faire ensuite, étape par étape :
--   1. casser des blocs dans la mine   2. poser sa carte dans sa base   3. collecter son argent
--   4. acheter une meilleure pioche
-- Elle disparaît dès qu'on a acheté sa 2e pioche, et pour toujours après 5 minutes de jeu au total
-- (GameConfig.GUIDE_MINUTES, temps de jeu sauvegardé : attribut "PlayTime").

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local UIKit = require(script.Parent.UIKit)

local player = Players.LocalPlayer
local brainrots = player:WaitForChild("Brainrots")
local pickaxeTier = player:WaitForChild("PickaxeTier")
local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")

local Guide = {}

local banner = Instance.new("Frame")
banner.Name = "Guide"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 104)
banner.Size = UDim2.new(0, 520, 0, 50)
banner.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
banner.BackgroundTransparency = 0.15
banner.Visible = false
banner.Parent = UIKit.ScreenGui
UIKit.corner(banner, 25)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 220, 90)
stroke.Thickness = 2.5
stroke.Parent = banner
local label = UIKit.label(banner, "", {
	Size = UDim2.new(1, -30, 1, -12),
	Position = UDim2.new(0, 15, 0, 6),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(255, 240, 180),
})
label.Name = "Step"
local scale = Instance.new("UIScale")
scale.Parent = banner

local current = nil

local function step()
	if pickaxeTier.Value >= 2 or (player:GetAttribute("PlayTime") or 0) >= GameConfig.GUIDE_MINUTES * 60 then
		return nil -- le joueur a compris (ou joue depuis 5 min) : plus de guide
	end
	local inBag, placed = 0, 0
	for _, item in ipairs(brainrots:GetChildren()) do
		local slot = item:GetAttribute("Slot") or 0
		if slot > 0 then
			placed += 1
		elseif slot == 0 then
			inBag += 1
		end
	end
	if placed == 0 and inBag == 0 then
		return "⛏️ Va à la MINE et casse des blocs pour trouver des cartes !"
	elseif placed == 0 then
		return "🏠 Pose ta carte dans ta BASE : Sac → PRENDRE → touche E sur un podium"
	elseif cash.Value < 1500 then
		return "💰 Ta carte gagne de l'argent : touche les boutons COLLECTER dans ta base !"
	end
	return "🛒 Achète une meilleure pioche à la BOUTIQUE (touche E au comptoir)"
end

local function refresh()
	local text = step()
	if text == current then return end
	current = text
	if not text then
		banner.Visible = false
		return
	end
	label.Text = text
	banner.Visible = true
	-- juste sous la barre du haut, et petit sur téléphone (comme le reste du HUD)
	local target = math.min(UIKit.fitFactor(560, 60, 0.95), UIKit.hudFactor())
	banner.Position = UDim2.new(0.5, 0, 0, 6 + 94 * UIKit.hudFactor())
	scale.Scale = target * 0.6
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target}):Play()
end

function Guide.init()
	brainrots.ChildAdded:Connect(function(item)
		item.AttributeChanged:Connect(refresh)
		refresh()
	end)
	for _, item in ipairs(brainrots:GetChildren()) do
		item.AttributeChanged:Connect(refresh)
	end
	brainrots.ChildRemoved:Connect(refresh)
	pickaxeTier.Changed:Connect(refresh)
	cash.Changed:Connect(refresh)
	player:GetAttributeChangedSignal("PlayTime"):Connect(refresh)
	refresh()
	-- la bordure clignote doucement pour attirer l'œil
	task.spawn(function()
		while true do
			task.wait(0.8)
			if banner.Visible then
				stroke.Transparency = stroke.Transparency > 0.3 and 0 or 0.6
			end
		end
	end)
end

return Guide
