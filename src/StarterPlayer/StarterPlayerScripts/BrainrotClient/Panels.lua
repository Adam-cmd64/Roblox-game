-- ModuleScript client : les fenêtres du jeu.
--   Sac        : tes cartes pas encore posées (clique pour la prendre en main)
--   Index      : tous les brainrots du jeu
--   Rebirth    : ce que tu débloques + les conditions
--   Boutique   : les pioches (s'ouvre au comptoir de la boutique)
--   Shop       : les boosters Robux + animation d'ouverture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local rebirths = leaderstats:WaitForChild("Rebirths")
local pickaxeTier = player:WaitForChild("PickaxeTier")
local brainrots = player:WaitForChild("Brainrots")

local Panels = {}

local function rarityOrder(cardName)
	local card = GameConfig.getCard(cardName)
	return card and GameConfig.RARITIES[card.Rarity].Order or 0
end

local function clearChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function horizontalList(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, padding)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

-- ============================================================
-- SAC (inventaire)
-- ============================================================
local inventory = UIKit.window("Sac", UDim2.new(0, 820, 0, 540), T.Blue)
Panels.inventory = inventory

local inventoryGrid = UIKit.scrollGrid(inventory.content, UDim2.new(0, 140, 0, 238))
local emptyLabel = UIKit.label(inventory.content, "Ton sac est vide... va miner !", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0.8, 0, 0, 40),
	Font = UIKit.TitleFont,
})

local function renderInventory()
	if not inventory.isOpen() then return end
	clearChildren(inventoryGrid)

	local items = {}
	for _, item in ipairs(brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) == 0 then
			table.insert(items, item)
		end
	end
	table.sort(items, function(a, b)
		local ra, rb = rarityOrder(a.Value), rarityOrder(b.Value)
		if ra ~= rb then return ra > rb end
		return a.Value < b.Value
	end)
	emptyLabel.Visible = #items == 0

	for order, item in ipairs(items) do
		local tile = Instance.new("Frame")
		tile.BackgroundTransparency = 1
		tile.LayoutOrder = order
		tile.Parent = inventoryGrid
		local cardHolder = Instance.new("Frame")
		cardHolder.Size = UDim2.new(1, 0, 0, 196)
		cardHolder.BackgroundTransparency = 1
		cardHolder.Parent = tile
		CardRenderer.createFitted(item.Value, item:GetAttribute("Mutation"), cardHolder)
		local take = UIKit.button(tile, "PRENDRE", T.Green, {
			Size = UDim2.new(1, 0, 0, 36),
			Position = UDim2.new(0, 0, 1, -36),
		})
		take.MouseButton1Click:Connect(function()
			Remotes.EquipBrainrot:FireServer(item.Name)
			inventory.close()
		end)
	end
end
inventory.onOpen = renderInventory

-- ============================================================
-- INDEX
-- ============================================================
local index = UIKit.window("Index", UDim2.new(0, 860, 0, 560), T.Gold)
Panels.index = index
local indexProgress = UIKit.label(index.content, "", {Size = UDim2.new(1, 0, 0, 28), Font = UIKit.TitleFont})
local indexGrid = UIKit.scrollGrid(index.content, UDim2.new(0, 145, 0, 228), {
	Size = UDim2.new(1, 0, 1, -36),
	Position = UDim2.new(0, 0, 0, 36),
})

local function renderIndex()
	clearChildren(indexGrid)
	local owned = {}
	for _, item in ipairs(brainrots:GetChildren()) do
		owned[item.Value] = (owned[item.Value] or 0) + 1
	end
	local found = 0
	for order, card in ipairs(GameConfig.CARDS) do
		local count = owned[card.Name] or 0
		if count > 0 then
			found += 1
		end
		local tile = Instance.new("Frame")
		tile.BackgroundTransparency = 1
		tile.LayoutOrder = order
		tile.Parent = indexGrid
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 200)
		holder.BackgroundTransparency = 1
		holder.Parent = tile
		local fitted = CardRenderer.createFitted(card.Name, "Normal", holder)
		if count == 0 then
			local veil = Instance.new("Frame")
			veil.Size = UDim2.new(1, 0, 1, 0)
			veil.BackgroundColor3 = Color3.new(0, 0, 0)
			veil.BackgroundTransparency = 0.1
			veil.ZIndex = 10
			veil.Parent = fitted
			UIKit.corner(veil, 10)
			UIKit.label(veil, "?", {
				Size = UDim2.new(0.5, 0, 0.3, 0),
				Position = UDim2.new(0.25, 0, 0.28, 0),
				Font = UIKit.TitleFont,
				ZIndex = 11,
			})
			UIKit.label(veil, card.Rarity, {
				Size = UDim2.new(0.9, 0, 0.11, 0),
				Position = UDim2.new(0.05, 0, 0.66, 0),
				TextColor3 = GameConfig.RARITIES[card.Rarity].Color,
				Font = UIKit.TitleFont,
				ZIndex = 11,
			})
		end
		UIKit.label(tile, count > 0 and ("x" .. count) or "???", {
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0, 0, 1, -22),
			TextColor3 = count > 0 and T.Green or Color3.fromRGB(170, 170, 180),
			Font = UIKit.TitleFont,
		})
	end
	indexProgress.Text = found .. " / " .. #GameConfig.CARDS .. " DÉCOUVERTS"
end
index.onOpen = renderIndex

-- ============================================================
-- REBIRTH
-- ============================================================
local rebirth = UIKit.window("Rebirth", UDim2.new(0, 760, 0, 600), T.Purple)
Panels.rebirth = rebirth
local rc = rebirth.content

UIKit.label(rc, "Tu perds ton argent et les brainrots demandés !", {
	Size = UDim2.new(1, 0, 0, 26),
	TextColor3 = Color3.fromRGB(255, 110, 110),
	Font = UIKit.TitleFont,
})
UIKit.label(rc, "TU DÉBLOQUES", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 36), Font = UIKit.TitleFont, TextColor3 = T.Gold})

local unlockRow = Instance.new("Frame")
unlockRow.Size = UDim2.new(1, 0, 0, 108)
unlockRow.Position = UDim2.new(0, 0, 0, 68)
unlockRow.BackgroundTransparency = 1
unlockRow.Parent = rc
horizontalList(unlockRow, 12)

local function unlockTile(icon, color)
	local tile = Instance.new("Frame")
	tile.Size = UDim2.new(0, 158, 1, 0)
	tile.BackgroundColor3 = Color3.new(1, 1, 1)
	tile.BorderSizePixel = 0
	tile.Parent = unlockRow
	UIKit.corner(tile, 14)
	UIKit.outline(tile, 3)
	UIKit.gradient(tile, color:Lerp(Color3.new(1, 1, 1), 0.2), color:Lerp(Color3.new(0, 0, 0), 0.35), 90)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Size = UDim2.new(1, 0, 0, 44)
	iconLabel.Position = UDim2.new(0, 0, 0, 6)
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = tile
	return UIKit.label(tile, "", {
		Size = UDim2.new(0.92, 0, 0, 48),
		Position = UDim2.new(0.04, 0, 0, 54),
		TextWrapped = true,
		Font = UIKit.TitleFont,
	})
end
local unlockIncome = unlockTile("💰", T.Green)
local unlockSlots = unlockTile("🏗️", T.Blue)
local unlockPickaxe = unlockTile("⛏️", T.Orange)
local unlockRank = unlockTile("⭐", T.Pink)

UIKit.label(rc, "CONDITIONS", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 188), Font = UIKit.TitleFont, TextColor3 = T.Gold})
local cashBarBack = Instance.new("Frame")
cashBarBack.Size = UDim2.new(1, -40, 0, 36)
cashBarBack.Position = UDim2.new(0, 20, 0, 222)
cashBarBack.BackgroundColor3 = T.Dark
cashBarBack.BorderSizePixel = 0
cashBarBack.Parent = rc
UIKit.corner(cashBarBack, 12)
UIKit.outline(cashBarBack, 3)
local cashBarFill = Instance.new("Frame")
cashBarFill.Size = UDim2.new(0, 0, 1, 0)
cashBarFill.BackgroundColor3 = Color3.new(1, 1, 1)
cashBarFill.BorderSizePixel = 0
cashBarFill.Parent = cashBarBack
UIKit.corner(cashBarFill, 12)
UIKit.gradient(cashBarFill, Color3.fromRGB(110, 245, 120), Color3.fromRGB(35, 165, 70), 90)
local cashBarText = UIKit.label(cashBarBack, "", {
	Size = UDim2.new(1, 0, 0.8, 0),
	Position = UDim2.new(0, 0, 0.1, 0),
	Font = UIKit.TitleFont,
	ZIndex = 3,
})

local requiredRow = Instance.new("Frame")
requiredRow.Size = UDim2.new(1, 0, 0, 180)
requiredRow.Position = UDim2.new(0, 0, 0, 268)
requiredRow.BackgroundTransparency = 1
requiredRow.Parent = rc
horizontalList(requiredRow, 12)

local rebirthButton = UIKit.button(rc, "REBIRTH", T.Green, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(0, 320, 0, 56),
})
rebirthButton.MouseButton1Click:Connect(function()
	Remotes.Rebirth:FireServer()
end)

local function updateCashBar()
	local requirement = GameConfig.getRebirth(rebirths.Value + 1)
	cashBarFill.Size = UDim2.new(math.clamp(cash.Value / requirement.Cash, 0, 1), 0, 1, 0)
	cashBarText.Text = "$" .. GameConfig.format(cash.Value) .. " / $" .. GameConfig.format(requirement.Cash)
end

local function renderRebirth()
	local current = rebirths.Value
	local nextNumber = current + 1
	local requirement = GameConfig.getRebirth(nextNumber)

	unlockIncome.Text = "Revenu x" .. GameConfig.getIncomeMultiplier(nextNumber)
	local gained = GameConfig.getUnlockedSlotCount(nextNumber) - GameConfig.getUnlockedSlotCount(current)
	if GameConfig.getFloorCount(nextNumber) > GameConfig.getFloorCount(current) then
		unlockSlots.Text = "Nouvel étage !"
	elseif gained > 0 then
		unlockSlots.Text = "+" .. gained .. " places"
	else
		unlockSlots.Text = "Plus de chance"
	end
	local nextPickaxe
	for _, pickaxe in ipairs(GameConfig.PICKAXES) do
		if pickaxe.RequiredRebirths == nextNumber then
			nextPickaxe = pickaxe
		end
	end
	unlockPickaxe.Text = nextPickaxe and string.gsub(nextPickaxe.Name, "Pioche en ", "Pioche ") or "Boutique"
	unlockRank.Text = "Rebirth " .. nextNumber

	updateCashBar()

	clearChildren(requiredRow)
	local ok = cash.Value >= requirement.Cash
	local used = {}
	for order, cardName in ipairs(requirement.Cards) do
		local has = false
		for _, item in ipairs(brainrots:GetChildren()) do
			if item.Value == cardName and not used[item] then
				used[item] = true
				has = true
				break
			end
		end
		ok = ok and has
		local tile = Instance.new("Frame")
		tile.Size = UDim2.new(0, 116, 1, 0)
		tile.BackgroundTransparency = 1
		tile.LayoutOrder = order
		tile.Parent = requiredRow
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 154)
		holder.BackgroundTransparency = 1
		holder.Parent = tile
		local fitted = CardRenderer.createFitted(cardName, "Normal", holder)
		if not has then
			local veil = Instance.new("Frame")
			veil.Size = UDim2.new(1, 0, 1, 0)
			veil.BackgroundColor3 = Color3.new(0, 0, 0)
			veil.BackgroundTransparency = 0.45
			veil.ZIndex = 10
			veil.Parent = fitted
			UIKit.corner(veil, 10)
		end
		UIKit.label(tile, has and "OK" or "MANQUANT", {
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0, 0, 1, -22),
			TextColor3 = has and T.Green or T.Red,
			Font = UIKit.TitleFont,
		})
	end

	UIKit.setButtonColor(rebirthButton, ok and T.Green or T.Gray)
	rebirthButton.Text = ok and "REBIRTH" or "PAS ENCORE..."
end
rebirth.onOpen = renderRebirth

-- ============================================================
-- BOUTIQUE DE PIOCHES (au comptoir)
-- ============================================================
local shop = UIKit.window("Pioches", UDim2.new(0, 780, 0, 580), T.Orange)
Panels.shop = shop
local shopList = Instance.new("ScrollingFrame")
shopList.Size = UDim2.new(1, 0, 1, 0)
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.ScrollBarThickness = 8
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.CanvasSize = UDim2.new()
shopList.Parent = shop.content
local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList

local function renderShop()
	clearChildren(shopList)
	for tier, pickaxe in ipairs(GameConfig.PICKAXES) do
		local row = UIKit.box(shopList, {Size = UDim2.new(1, -12, 0, 78), LayoutOrder = tier})
		local icon = Instance.new("Frame")
		icon.Size = UDim2.new(0, 60, 0, 60)
		icon.Position = UDim2.new(0, 9, 0, 9)
		icon.BackgroundColor3 = pickaxe.HeadColor
		icon.BorderSizePixel = 0
		icon.Parent = row
		UIKit.corner(icon, 12)
		UIKit.outline(icon, 3)
		local iconLabel = Instance.new("TextLabel")
		iconLabel.BackgroundTransparency = 1
		iconLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
		iconLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
		iconLabel.Text = "⛏️"
		iconLabel.TextScaled = true
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.Parent = icon

		UIKit.label(row, pickaxe.Name, {
			Size = UDim2.new(0, 330, 0, 30),
			Position = UDim2.new(0, 82, 0, 8),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UIKit.TitleFont,
		})
		UIKit.label(row, string.format("Dégâts %d   •   Vitesse %.1f/s   •   Chance x%s", pickaxe.Damage, 1 / pickaxe.Cooldown, tostring(pickaxe.Luck)), {
			Size = UDim2.new(0, 400, 0, 22),
			Position = UDim2.new(0, 82, 0, 44),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = T.SubText,
		})

		local text, color, clickable
		if tier == pickaxeTier.Value then
			text, color = "ÉQUIPÉE", T.Gray
		elseif tier < pickaxeTier.Value then
			text, color = "POSSÉDÉE", T.Gray
		elseif rebirths.Value < pickaxe.RequiredRebirths then
			text, color = "REBIRTH " .. pickaxe.RequiredRebirths, T.Gray
		elseif tier > pickaxeTier.Value + 1 then
			text, color = "BLOQUÉE", T.Gray
		else
			text, color, clickable = "$" .. GameConfig.format(pickaxe.Cost), cash.Value >= pickaxe.Cost and T.Green or T.Red, true
		end
		local buy = UIKit.button(row, text, color, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, 190, 0, 50),
		})
		if clickable then
			buy.MouseButton1Click:Connect(function()
				Remotes.BuyPickaxe:FireServer(tier)
			end)
		end
	end
end
shop.onOpen = renderShop

-- ============================================================
-- SHOP ROBUX (boosters)
-- ============================================================
local boosters = UIKit.window("Shop", UDim2.new(0, 920, 0, 540), T.Pink)
Panels.boosters = boosters
UIKit.label(boosters.content, "3 brainrots par booster, sans miner !", {Size = UDim2.new(1, 0, 0, 28), Font = UIKit.TitleFont})
local boosterRow = Instance.new("Frame")
boosterRow.Size = UDim2.new(1, 0, 1, -40)
boosterRow.Position = UDim2.new(0, 0, 0, 40)
boosterRow.BackgroundTransparency = 1
boosterRow.Parent = boosters.content
horizontalList(boosterRow, 14)

for order, booster in ipairs(GameConfig.BOOSTERS) do
	local pack = Instance.new("Frame")
	pack.Size = UDim2.new(0, 196, 1, 0)
	pack.BackgroundColor3 = Color3.new(1, 1, 1)
	pack.BorderSizePixel = 0
	pack.LayoutOrder = order
	pack.Parent = boosterRow
	UIKit.corner(pack, 18)
	UIKit.outline(pack, 3.5)
	UIKit.gradient(pack, booster.Color:Lerp(Color3.new(1, 1, 1), 0.25), booster.Color:Lerp(Color3.new(0, 0, 0), 0.55), 90)

	local packIcon = Instance.new("TextLabel")
	packIcon.BackgroundTransparency = 1
	packIcon.Size = UDim2.new(1, 0, 0, 70)
	packIcon.Position = UDim2.new(0, 0, 0, 10)
	packIcon.Text = "🎴"
	packIcon.TextScaled = true
	packIcon.Font = Enum.Font.GothamBold
	packIcon.Parent = pack
	UIKit.label(pack, booster.Name, {Size = UDim2.new(0.92, 0, 0, 34), Position = UDim2.new(0.04, 0, 0, 84), Font = UIKit.TitleFont})

	local odds = Instance.new("Frame")
	odds.Size = UDim2.new(0.88, 0, 0, 170)
	odds.Position = UDim2.new(0.06, 0, 0, 126)
	odds.BackgroundColor3 = Color3.new(0, 0, 0)
	odds.BackgroundTransparency = 0.55
	odds.Parent = pack
	UIKit.corner(odds, 12)
	local oddsLayout = Instance.new("UIListLayout")
	oddsLayout.Padding = UDim.new(0, 2)
	oddsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	oddsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	oddsLayout.Parent = odds
	UIKit.padding(odds, 6)
	for i, entry in ipairs(booster.Odds) do
		UIKit.label(odds, entry[1] .. "  " .. entry[2] .. "%", {
			Size = UDim2.new(1, 0, 0, 24),
			TextColor3 = GameConfig.RARITIES[entry[1]].Color,
			LayoutOrder = i,
		})
	end

	local buy = UIKit.button(pack, "R$ " .. booster.Price, T.Green, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0.86, 0, 0, 52),
	})
	buy.MouseButton1Click:Connect(function()
		Remotes.BuyBooster:FireServer(booster.Id)
	end)
end

-- Ouverture d'un booster : les cartes se retournent une par une
local openSound = Instance.new("Sound")
openSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
openSound.Volume = 0.5
openSound.Parent = SoundService

function Panels.openBooster(boosterId, cards)
	UIKit.closeAll()
	local booster
	for _, b in ipairs(GameConfig.BOOSTERS) do
		if b.Id == boosterId then
			booster = b
		end
	end
	local accent = booster and booster.Color or T.Purple

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.25
	overlay.ZIndex = 40
	overlay.Parent = UIKit.ScreenGui
	UIKit.label(overlay, booster and booster.Name or "Booster", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.08, 0),
		Size = UDim2.new(0, 560, 0, 60),
		Font = UIKit.TitleFont,
		TextColor3 = accent,
	})
	local row = Instance.new("Frame")
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.Size = UDim2.new(0, 3 * 230 + 40, 0, 320)
	row.BackgroundTransparency = 1
	row.Parent = overlay
	horizontalList(row, 20)

	for i, result in ipairs(cards) do
		local slot = Instance.new("Frame")
		slot.Size = UDim2.new(0, 220, 0, 308)
		slot.BackgroundTransparency = 1
		slot.LayoutOrder = i
		slot.Parent = row

		local back = Instance.new("Frame")
		back.AnchorPoint = Vector2.new(0.5, 0.5)
		back.Position = UDim2.new(0.5, 0, 0.5, 0)
		back.Size = UDim2.new(1, 0, 1, 0)
		back.BackgroundColor3 = Color3.new(1, 1, 1)
		back.Parent = slot
		UIKit.corner(back, 16)
		UIKit.outline(back, 4)
		UIKit.gradient(back, accent, Color3.fromRGB(20, 20, 40), 45)
		UIKit.label(back, "?", {Size = UDim2.new(0.6, 0, 0.4, 0), Position = UDim2.new(0.2, 0, 0.3, 0), Font = UIKit.TitleFont})

		task.delay(0.7 + i * 0.8, function()
			local shrink = TweenService:Create(back, TweenInfo.new(0.18), {Size = UDim2.new(0, 0, 1, 0)})
			shrink:Play()
			shrink.Completed:Wait()
			back:Destroy()
			SoundService:PlayLocalSound(openSound)
			local front = Instance.new("Frame")
			front.AnchorPoint = Vector2.new(0.5, 0.5)
			front.Position = UDim2.new(0.5, 0, 0.5, 0)
			front.Size = UDim2.new(0, 0, 1, 0)
			front.BackgroundTransparency = 1
			front.Parent = slot
			CardRenderer.create(result.Name, result.Mutation, front)
			TweenService:Create(front, TweenInfo.new(0.22, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 1, 0)}):Play()
		end)
	end

	local done = UIKit.button(overlay, "SUPER !", T.Green, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.84, 0),
		Size = UDim2.new(0, 260, 0, 58),
		Visible = false,
	})
	task.delay(0.9 + #cards * 0.8, function()
		done.Visible = true
	end)
	done.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)
end

-- ============================================================
-- RAFRAICHISSEMENT AUTOMATIQUE
-- ============================================================
local refreshQueued = false
local function scheduleRefresh()
	if refreshQueued then return end
	refreshQueued = true
	task.delay(0.15, function()
		refreshQueued = false
		if inventory.isOpen() then renderInventory() end
		if rebirth.isOpen() then renderRebirth() end
		if shop.isOpen() then renderShop() end
	end)
end

local function watch(item)
	item.AttributeChanged:Connect(scheduleRefresh)
end
for _, item in ipairs(brainrots:GetChildren()) do
	watch(item)
end
brainrots.ChildAdded:Connect(function(item)
	watch(item)
	scheduleRefresh()
end)
brainrots.ChildRemoved:Connect(scheduleRefresh)
rebirths.Changed:Connect(scheduleRefresh)
pickaxeTier.Changed:Connect(scheduleRefresh)
cash.Changed:Connect(function()
	if rebirth.isOpen() then
		updateCashBar()
	end
end)

return Panels
