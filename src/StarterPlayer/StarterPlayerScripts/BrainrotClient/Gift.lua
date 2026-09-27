-- ModuleScript client : la carte tenue EN MAIN.
--   - touche G (ou le bouton "RANGER" sur téléphone) : la carte retourne dans le sac
--   - maintenir E 3 secondes sur un autre joueur : tu lui DONNES la carte (max 3 rebirths d'écart)
--     (le bouton "Donner la carte" n'apparaît que quand tu tiens une carte)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UIKit = require(script.Parent.UIKit)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Gift = {}

local function holdingCard()
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("ItemId") ~= nil
end

local function store()
	if holdingCard() then
		Remotes.StoreCard:FireServer()
	end
end

-- bouton pour les téléphones (pas de clavier)
local storeButton = UIKit.button(UIKit.ScreenGui, "🎒 RANGER (G)", T.Blue, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -96),
	Size = UDim2.new(0, 200, 0, 46),
	Visible = false,
})
storeButton.Name = "StoreCardButton"
UIKit.hudScale(storeButton)
storeButton.MouseButton1Click:Connect(store)

local function refresh()
	local holding = holdingCard()
	storeButton.Visible = holding
	for _, other in ipairs(Players:GetPlayers()) do
		local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		local prompt = root and root:FindFirstChild("GiftPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			-- jamais sur moi-même ; sur les autres seulement si je tiens une carte
			prompt.Enabled = holding and other ~= player
		end
	end
end
Gift.refresh = refresh

function Gift.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.G then
			store()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.3)
			refresh()
		end
	end)
end

return Gift
