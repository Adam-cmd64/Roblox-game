-- ModuleScript client : la fenêtre 🎁 CADEAUX (bouton du menu).
--   - à gauche : les 8 CADEAUX DE SESSION (GameConfig.PLAYTIME_GIFTS) avec le temps qui reste
--   - à droite : les 3 QUÊTES DU JOUR (GameConfig.QUESTS) avec leur barre de progression + le bonus
--   - une pastille rouge sur le bouton 🎁 = le nombre de récompenses à prendre
-- Tout est calculé à partir des attributs du joueur (voir RewardsManager.lua côté serveur).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local GIFTS = GameConfig.PLAYTIME_GIFTS
local QUESTS = GameConfig.QUESTS

local Rewards = {}

local function hasBit(mask, index)
	return math.floor((mask or 0) / 2 ^ (index - 1)) % 2 == 1
end

local function sessionTime()
	return os.time() - (player:GetAttribute("SessionStart") or os.time())
end

-- état d'un cadeau : "claimed", "ready" ou le nombre de secondes qui restent
local function giftState(index)
	if hasBit(player:GetAttribute("GiftsClaimed"), index) then
		return "claimed"
	end
	local left = GIFTS[index].Minutes * 60 - sessionTime()
	return left <= 0 and "ready" or left
end

local function today()
	-- le serveur remet les quêtes à zéro au changement de jour (QuestDay)
	return player:GetAttribute("QuestDay") or GameConfig.getQuestDay()
end

local function questState(index)
	local mask = player:GetAttribute("QuestClaimed") or 0
	if hasBit(mask, index) then
		return "claimed"
	end
	if index == #QUESTS.List + 1 then
		for i = 1, #QUESTS.List do
			if not hasBit(mask, i) then
				return "locked"
			end
		end
		return "ready"
	end
	local progress = player:GetAttribute("Quest" .. index) or 0
	return progress >= GameConfig.getQuestTarget(index, today()) and "ready" or "progress"
end

-- combien de récompenses à prendre (la pastille rouge)
function Rewards.countReady()
	local count = 0
	for i = 1, #GIFTS do
		if giftState(i) == "ready" then count += 1 end
	end
	for i = 1, #QUESTS.List + 1 do
		if questState(i) == "ready" then count += 1 end
	end
	return count
end

-- ============================================================
-- LA FENÊTRE
-- ============================================================
local window = UIKit.window("🎁 Cadeaux & Quêtes", UDim2.new(0, 900, 0, 560), T.Green)
Rewards.window = window
local content = window.content

-- ===== à gauche : cadeaux de session =====
local giftSide = Instance.new("Frame")
giftSide.Name = "Gifts"
giftSide.Size = UDim2.new(0.5, -8, 1, 0)
giftSide.BackgroundTransparency = 1
giftSide.Parent = content
UIKit.label(giftSide, "🎁 CADEAUX DE SESSION", {
	Size = UDim2.new(1, 0, 0, 34),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(255, 230, 120),
})
UIKit.label(giftSide, "Reste connecté pour tout débloquer !", {
	Position = UDim2.new(0, 0, 0, 34),
	Size = UDim2.new(1, 0, 0, 22),
	TextColor3 = T.SubText,
})
local giftGrid = Instance.new("Frame")
giftGrid.Name = "GiftGrid"
giftGrid.Position = UDim2.new(0, 0, 0, 64)
giftGrid.Size = UDim2.new(1, 0, 1, -64)
giftGrid.BackgroundTransparency = 1
giftGrid.Parent = giftSide
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.25, -8, 0.5, -8)
grid.CellPadding = UDim2.new(0, 8, 0, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = giftGrid

local giftTiles = {}
for index, gift in ipairs(GIFTS) do
	local tile = UIKit.box(giftGrid, {Name = "Gift" .. index, LayoutOrder = index, BackgroundTransparency = 0.82})
	local stroke = UIKit.outline(tile, 2.5, gift.Color)
	UIKit.label(tile, gift.Minutes .. " MIN", {
		Name = "Minutes",
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -8, 0, 20),
		Font = UIKit.TitleFont,
		TextColor3 = Color3.fromRGB(220, 220, 240),
	})
	UIKit.label(tile, gift.Icon, {
		Name = "Icon",
		Position = UDim2.new(0.5, -28, 0, 24),
		Size = UDim2.new(0, 56, 0, 56),
		Font = Enum.Font.GothamBold,
	})
	UIKit.label(tile, gift.Name, {
		Name = "RewardName",
		Position = UDim2.new(0, 4, 0, 82),
		Size = UDim2.new(1, -8, 0, 36),
		TextWrapped = true,
	})
	local button = UIKit.button(tile, "", T.Green, {
		Name = "Claim",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -12, 0, 34),
	})
	button.MouseButton1Click:Connect(function()
		if giftState(index) == "ready" then
			Remotes.ClaimGift:FireServer(index)
			Sounds.play("Win")
		end
	end)
	giftTiles[index] = {tile = tile, button = button, stroke = stroke}
end

-- ===== à droite : quêtes du jour =====
local questSide = Instance.new("Frame")
questSide.Name = "Quests"
questSide.Position = UDim2.new(0.5, 8, 0, 0)
questSide.Size = UDim2.new(0.5, -8, 1, 0)
questSide.BackgroundTransparency = 1
questSide.Parent = content
UIKit.label(questSide, "📜 QUÊTES DU JOUR", {
	Size = UDim2.new(1, 0, 0, 34),
	Font = UIKit.TitleFont,
	TextColor3 = Color3.fromRGB(140, 220, 255),
})
local resetLabel = UIKit.label(questSide, "", {
	Name = "Reset",
	Position = UDim2.new(0, 0, 0, 34),
	Size = UDim2.new(1, 0, 0, 22),
	TextColor3 = T.SubText,
})

local questRows = {}
local function questRow(index, icon, rewardText)
	local row = UIKit.box(questSide, {
		Name = "Quest" .. index,
		Position = UDim2.new(0, 0, 0, 64 + (index - 1) * 104),
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundTransparency = 0.82,
	})
	local title = UIKit.label(row, "", {
		Name = "Title",
		Position = UDim2.new(0, 12, 0, 6),
		Size = UDim2.new(1, -150, 0, 28),
		Font = UIKit.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local barBack = Instance.new("Frame")
	barBack.Name = "Bar"
	barBack.Position = UDim2.new(0, 12, 0, 40)
	barBack.Size = UDim2.new(1, -150, 0, 18)
	barBack.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	barBack.BorderSizePixel = 0
	barBack.Parent = row
	UIKit.corner(barBack, 9)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = barBack
	UIKit.corner(fill, 9)
	UIKit.gradient(fill, Color3.fromRGB(90, 230, 255), Color3.fromRGB(60, 140, 255), 0)
	local progressLabel = UIKit.label(barBack, "", {
		Name = "Progress",
		Size = UDim2.new(1, 0, 1, 0),
		Font = UIKit.TitleFont,
		ZIndex = 3,
	})
	UIKit.label(row, "Récompense : " .. icon .. " " .. rewardText, {
		Name = "Reward",
		Position = UDim2.new(0, 12, 0, 64),
		Size = UDim2.new(1, -150, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 230, 140),
	})
	local button = UIKit.button(row, "", T.Green, {
		Name = "Claim",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 124, 0, 50),
	})
	button.MouseButton1Click:Connect(function()
		if questState(index) == "ready" then
			Remotes.ClaimQuest:FireServer(index)
			Sounds.play("Win")
		end
	end)
	questRows[index] = {row = row, title = title, fill = fill, progress = progressLabel, button = button}
end
for index, quest in ipairs(QUESTS.List) do
	questRow(index, quest.Reward.Icon, quest.Reward.Name)
end
questRow(#QUESTS.List + 1, QUESTS.Bonus.Icon, QUESTS.Bonus.Name)

-- ============================================================
-- MISE À JOUR (chaque seconde, et à chaque changement d'attribut)
-- ============================================================
local function setButton(button, state, waitText)
	if state == "claimed" then
		button.Text = "✓ PRIS"
		UIKit.setButtonColor(button, T.Gray)
	elseif state == "ready" then
		button.Text = "PRENDRE !"
		UIKit.setButtonColor(button, T.Green)
	else
		button.Text = waitText or "..."
		UIKit.setButtonColor(button, T.Gray)
	end
end

local badge
function Rewards.refresh()
	for index, tiles in ipairs(giftTiles) do
		local state = giftState(index)
		if type(state) == "number" then
			setButton(tiles.button, "wait", GameConfig.formatTime(state))
		else
			setButton(tiles.button, state)
		end
		tiles.stroke.Thickness = state == "ready" and 4 or 2.5
		tiles.tile.BackgroundTransparency = state == "claimed" and 0.93 or 0.82
	end
	local day = today()
	for index, rowData in ipairs(questRows) do
		local state = questState(index)
		if index <= #QUESTS.List then
			local target = GameConfig.getQuestTarget(index, day)
			local progress = math.min(player:GetAttribute("Quest" .. index) or 0, target)
			rowData.title.Text = GameConfig.getQuestText(index, day)
			rowData.fill.Size = UDim2.new(progress / target, 0, 1, 0)
			rowData.progress.Text = progress .. " / " .. target
			setButton(rowData.button, state, "EN COURS")
		else
			local done = 0
			for i = 1, #QUESTS.List do
				if hasBit(player:GetAttribute("QuestClaimed"), i) then done += 1 end
			end
			rowData.title.Text = "🏆 BONUS : fais les 3 quêtes"
			rowData.fill.Size = UDim2.new(done / #QUESTS.List, 0, 1, 0)
			rowData.progress.Text = done .. " / " .. #QUESTS.List
			setButton(rowData.button, state, "🔒")
		end
	end
	local nextDay = (GameConfig.getQuestDay() + 1) * 86400
	resetLabel.Text = "Nouvelles quêtes dans " .. GameConfig.formatTime(math.max(0, nextDay - os.time()))
	if badge then
		local count = Rewards.countReady()
		badge.Text = tostring(count)
		badge.Visible = count > 0
	end
end

function Rewards.init(Hud)
	local menuButton = Hud and Hud.buttons and Hud.buttons.rewards
	if menuButton then
		menuButton.MouseButton1Click:Connect(window.toggle)
		badge = Instance.new("TextLabel")
		badge.Name = "RewardsBadge"
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.new(1, -4, 0, 4)
		badge.Size = UDim2.new(0, 28, 0, 28)
		badge.BackgroundColor3 = T.Red
		badge.TextColor3 = Color3.new(1, 1, 1)
		badge.Font = UIKit.TitleFont
		badge.TextScaled = true
		badge.Visible = false
		badge.ZIndex = 5
		badge.Parent = menuButton
		UIKit.corner(badge, 14)
		UIKit.outline(badge, 2.5)
	end
	window.onOpen = Rewards.refresh
	for _, name in ipairs({"GiftsClaimed", "SessionStart", "QuestDay", "QuestClaimed", "Quest1", "Quest2", "Quest3"}) do
		player:GetAttributeChangedSignal(name):Connect(Rewards.refresh)
	end
	-- prévenir quand un cadeau devient prêt
	local announced = {}
	task.spawn(function()
		while true do
			for index, gift in ipairs(GIFTS) do
				if giftState(index) == "ready" and not announced[index] and player:GetAttribute("SessionStart") then
					announced[index] = true
					if Hud and Hud.notify then
						Hud.notify("🎁 Un cadeau t'attend : " .. gift.Name .. " ! (bouton 🎁)", "success")
					end
				end
			end
			Rewards.refresh()
			task.wait(1)
		end
	end)
	Rewards.refresh()
end

return Rewards
