-- ModuleScript client : les fenêtres du jeu.
--   Sac        : tes cartes pas encore posées (prendre en main / vendre)
--   Index      : tous les brainrots + bonus d'argent quand une rareté est complète
--   Rebirth    : ce que tu débloques + les conditions
--   Pioches    : touche E au comptoir de la boutique
--   Battes     : touche F au comptoir de la boutique
--   Shop       : boosters, potion, tours de roue (Robux) + animation d'ouverture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local rebirths = leaderstats:WaitForChild("Rebirths")
local pickaxeTier = player:WaitForChild("PickaxeTier")
local batTier = player:WaitForChild("BatTier")
local brainrots = player:WaitForChild("Brainrots")
local indexFolder = player:WaitForChild("Index")

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

local function verticalList(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local function scrollList(parent, props)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 8
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	for key, value in pairs(props or {}) do
		scroll[key] = value
	end
	scroll.Parent = parent
	verticalList(scroll, 8)
	return scroll
end

-- Bouton qui demande confirmation (2e clic dans les 3 secondes)
local function confirmButton(button, normalText, onConfirm)
	local armed = false
	button.MouseButton1Click:Connect(function()
		if armed then
			armed = false
			onConfirm()
			return
		end
		armed = true
		button.Text = "SÛR ?"
		UIKit.setButtonColor(button, T.Red)
		task.delay(3, function()
			if armed and button.Parent then
				armed = false
				button.Text = normalText
				UIKit.setButtonColor(button, T.Orange)
			end
		end)
	end)
end

-- ============================================================
-- SAC (inventaire)
-- ============================================================
local inventory = UIKit.window("Sac", UDim2.new(0, 860, 0, 580), T.Blue)
Panels.inventory = inventory

local sellBar = Instance.new("Frame")
sellBar.Size = UDim2.new(1, 0, 0, 44)
sellBar.BackgroundTransparency = 1
sellBar.Parent = inventory.content
horizontalList(sellBar, 10)
for order, rarity in ipairs({"Commun", "Rare", "Très Rare"}) do
	local text = "VENDRE LES " .. GameConfig.upper(rarity) .. "S"
	local button = UIKit.button(sellBar, text, T.Orange, {Size = UDim2.new(0, 250, 0, 40), LayoutOrder = order})
	confirmButton(button, text, function()
		Remotes.SellAll:FireServer(rarity)
		button.Text = text
		UIKit.setButtonColor(button, T.Orange)
	end)
end

local inventoryGrid = UIKit.scrollGrid(inventory.content, UDim2.new(0, 140, 0, 294), {
	Size = UDim2.new(1, 0, 1, -52),
	Position = UDim2.new(0, 0, 0, 52),
})
local emptyLabel = UIKit.label(inventory.content, "Ton sac est vide... va miner !", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.55, 0),
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
		cardHolder.Size = UDim2.new(1, 0, 0, 224)
		cardHolder.BackgroundTransparency = 1
		cardHolder.Parent = tile
		CardRenderer.createFitted(item.Value, item:GetAttribute("Mutation"), cardHolder, item:GetAttribute("Serial"))
		local take = UIKit.button(tile, "PRENDRE", T.Green, {
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.new(0, 0, 0, 228),
		})
		take.MouseButton1Click:Connect(function()
			Remotes.EquipBrainrot:FireServer(item.Name)
			inventory.close()
		end)
		local priceText = "$" .. GameConfig.format(GameConfig.getSellPrice(item.Value, item:GetAttribute("Mutation")))
		local sell = UIKit.button(tile, priceText, T.Orange, {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 0, 264),
		})
		confirmButton(sell, priceText, function()
			Remotes.SellBrainrot:FireServer(item.Name)
		end)
	end
end
inventory.onOpen = renderInventory

-- ============================================================
-- INDEX
-- ============================================================
local index = UIKit.window("Index", UDim2.new(0, 980, 0, 600), T.Gold)
Panels.index = index

local indexSide = Instance.new("Frame")
indexSide.Size = UDim2.new(0, 250, 1, 0)
indexSide.BackgroundTransparency = 1
indexSide.Parent = index.content
local indexTotal = UIKit.label(indexSide, "", {Size = UDim2.new(1, 0, 0, 30), Font = UIKit.TitleFont, TextColor3 = T.Green})
local rarityList = scrollList(indexSide, {Size = UDim2.new(1, 0, 1, -38), Position = UDim2.new(0, 0, 0, 38)})

local indexGrid = UIKit.scrollGrid(index.content, UDim2.new(0, 128, 0, 232), {
	Size = UDim2.new(1, -262, 1, 0),
	Position = UDim2.new(0, 262, 0, 0),
})

local function renderIndex()
	clearChildren(indexGrid)
	clearChildren(rarityList)
	local discovered = GameConfig.getDiscovered(player)
	local owned = {}
	for _, item in ipairs(brainrots:GetChildren()) do
		owned[item.Value] = (owned[item.Value] or 0) + 1
	end

	-- Progression par rareté + bonus
	for order, rarityName in ipairs(GameConfig.RARITY_ORDER) do
		local rarity = GameConfig.RARITIES[rarityName]
		local cards = GameConfig.getCardsOfRarity(rarityName)
		local found = 0
		for _, card in ipairs(cards) do
			if discovered[card.Name] then
				found += 1
			end
		end
		local complete = found == #cards
		local row = UIKit.box(rarityList, {Size = UDim2.new(1, -10, 0, 40), LayoutOrder = order})
		if complete then
			row.BackgroundTransparency = 0.65
			row.BackgroundColor3 = rarity.Color
		end
		UIKit.label(row, rarityName, {
			Size = UDim2.new(0.5, 0, 0, 22),
			Position = UDim2.new(0, 8, 0, 3),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = rarity.Color,
			Font = UIKit.TitleFont,
		})
		UIKit.label(row, found .. "/" .. #cards, {
			Size = UDim2.new(0.5, 0, 0, 14),
			Position = UDim2.new(0, 8, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = T.SubText,
		})
		UIKit.label(row, (complete and "✔ " or "") .. "+" .. math.floor(rarity.IndexBonus * 1000 + 0.5) / 10 .. "%", {
			Size = UDim2.new(0.42, 0, 0, 26),
			Position = UDim2.new(0.56, 0, 0, 7),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = complete and T.Green or Color3.fromRGB(170, 170, 180),
			Font = UIKit.TitleFont,
		})
	end
	indexTotal.Text = "BONUS : +" .. math.floor(GameConfig.getIndexBonus(discovered) * 1000 + 0.5) / 10 .. "% $"

	for order, card in ipairs(GameConfig.CARDS) do
		local tile = Instance.new("Frame")
		tile.BackgroundTransparency = 1
		tile.LayoutOrder = order
		tile.Parent = indexGrid
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 205)
		holder.BackgroundTransparency = 1
		holder.Parent = tile
		local fitted = CardRenderer.createFitted(card.Name, "Normal", holder)
		if not discovered[card.Name] then
			local veil = Instance.new("Frame")
			veil.Size = UDim2.new(1, 0, 1, 0)
			veil.BackgroundColor3 = Color3.new(0, 0, 0)
			veil.BackgroundTransparency = 0.08
			veil.ZIndex = 10
			veil.Parent = fitted
			UIKit.corner(veil, 10)
			UIKit.label(veil, "?", {Size = UDim2.new(0.5, 0, 0.3, 0), Position = UDim2.new(0.25, 0, 0.28, 0), Font = UIKit.TitleFont, ZIndex = 11})
			UIKit.label(veil, card.Rarity, {
				Size = UDim2.new(0.9, 0, 0.11, 0),
				Position = UDim2.new(0.05, 0, 0.66, 0),
				TextColor3 = GameConfig.RARITIES[card.Rarity].Color,
				Font = UIKit.TitleFont,
				ZIndex = 11,
			})
		end
		local count = owned[card.Name] or 0
		UIKit.label(tile, discovered[card.Name] and ("x" .. count) or "???", {
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0, 0, 1, -22),
			TextColor3 = count > 0 and T.Green or Color3.fromRGB(170, 170, 180),
			Font = UIKit.TitleFont,
		})
	end
end
index.onOpen = renderIndex

-- ============================================================
-- REBIRTH
-- ============================================================
local rebirth = UIKit.window("Rebirth", UDim2.new(0, 780, 0, 620), T.Purple)
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

local function unlockTile(icon, color, order)
	local tile = Instance.new("Frame")
	tile.Size = UDim2.new(0, 160, 1, 0)
	tile.BackgroundColor3 = Color3.new(1, 1, 1)
	tile.BorderSizePixel = 0
	tile.LayoutOrder = order
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
local unlockIncome = unlockTile("💰", T.Green, 1)
local unlockSlots = unlockTile("🏗️", T.Blue, 2)
local unlockPickaxe = unlockTile("⛏️", T.Orange, 3)
local unlockLock = unlockTile("🔒", T.Red, 4)

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
requiredRow.Size = UDim2.new(1, 0, 0, 190)
requiredRow.Position = UDim2.new(0, 0, 0, 268)
requiredRow.BackgroundTransparency = 1
requiredRow.Parent = rc
horizontalList(requiredRow, 14)

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
		unlockSlots.Text = "Base au max"
	end
	local nextPickaxe
	for _, pickaxe in ipairs(GameConfig.PICKAXES) do
		if pickaxe.RequiredRebirths == nextNumber then
			nextPickaxe = pickaxe
		end
	end
	unlockPickaxe.Text = nextPickaxe and (string.gsub(nextPickaxe.Name, "Pioche en ", "Pioche ")) or "Plus d'argent"
	unlockLock.Text = "Verrou " .. GameConfig.getLockDuration(nextNumber) .. "s"

	updateCashBar()

	clearChildren(requiredRow)
	local ok = cash.Value >= requirement.Cash
	local used = {}
	for order, cardName in ipairs(requirement.Cards) do
		local has = false
		for _, item in ipairs(brainrots:GetChildren()) do
			if item.Value == cardName and not used[item] and (item:GetAttribute("Slot") or 0) >= 0 then
				used[item] = true
				has = true
				break
			end
		end
		ok = ok and has
		local tile = Instance.new("Frame")
		tile.Size = UDim2.new(0, 120, 1, 0)
		tile.BackgroundTransparency = 1
		tile.LayoutOrder = order
		tile.Parent = requiredRow
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 164)
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
-- BOUTIQUES (pioches et battes) : même présentation
-- ============================================================
local function shopRow(list, order, color, icon, title, subtitle)
	local row = UIKit.box(list, {Size = UDim2.new(1, -12, 0, 80), LayoutOrder = order})
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 62, 0, 62)
	iconFrame.Position = UDim2.new(0, 9, 0, 9)
	iconFrame.BackgroundColor3 = color
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = row
	UIKit.corner(iconFrame, 12)
	UIKit.outline(iconFrame, 3)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
	iconLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = iconFrame
	UIKit.label(row, title, {
		Size = UDim2.new(0, 330, 0, 30),
		Position = UDim2.new(0, 84, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = UIKit.TitleFont,
	})
	UIKit.label(row, subtitle, {
		Size = UDim2.new(0, 400, 0, 22),
		Position = UDim2.new(0, 84, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = T.SubText,
	})
	return row
end

local function buyButton(row, text, color, onClick)
	local button = UIKit.button(row, text, color, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 220, 0, 52),
	})
	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end
	return button
end

local shop = UIKit.window("Pioches", UDim2.new(0, 800, 0, 600), T.Orange)
Panels.shop = shop
local shopList = scrollList(shop.content)

local function renderShop()
	clearChildren(shopList)
	for tier, pickaxe in ipairs(GameConfig.PICKAXES) do
		local row = shopRow(shopList, tier, pickaxe.HeadColor, "⛏️", pickaxe.Name,
			string.format("Dégâts %d  •  Vitesse %.1f/s  •  Chance x%s", pickaxe.Damage, 1 / pickaxe.Cooldown, tostring(pickaxe.Luck)))
		if tier == pickaxeTier.Value then
			buyButton(row, "ÉQUIPÉE", T.Gray)
		elseif tier < pickaxeTier.Value then
			buyButton(row, "POSSÉDÉE", T.Gray)
		elseif tier > pickaxeTier.Value + 1 then
			buyButton(row, "BLOQUÉE", T.Gray)
		elseif rebirths.Value < pickaxe.RequiredRebirths then
			buyButton(row, "REBIRTH " .. pickaxe.RequiredRebirths .. " + $" .. GameConfig.format(pickaxe.Cost), T.Gray)
		else
			buyButton(row, "$" .. GameConfig.format(pickaxe.Cost), cash.Value >= pickaxe.Cost and T.Green or T.Red, function()
				Remotes.BuyPickaxe:FireServer(tier)
			end)
		end
	end
end
shop.onOpen = renderShop

local armory = UIKit.window("Battes", UDim2.new(0, 800, 0, 560), T.Red)
Panels.armory = armory
local armoryList = scrollList(armory.content)

local function renderArmory()
	clearChildren(armoryList)
	for tier, bat in ipairs(GameConfig.BATS) do
		local row = shopRow(armoryList, tier, bat.Color, "🏏", bat.Name,
			string.format("Portée %.1f  •  Recharge %.1fs  •  Fait tomber %ds", bat.Range, bat.Cooldown, GameConfig.STUN_TIME))
		if tier == batTier.Value then
			buyButton(row, "ÉQUIPÉE", T.Gray)
		elseif tier < batTier.Value then
			buyButton(row, "POSSÉDÉE", T.Gray)
		elseif tier > batTier.Value + 1 then
			buyButton(row, "BLOQUÉE", T.Gray)
		else
			buyButton(row, "$" .. GameConfig.format(bat.Cost), cash.Value >= bat.Cost and T.Green or T.Red, function()
				Remotes.BuyBat:FireServer(tier)
			end)
		end
	end
end
armory.onOpen = renderArmory

-- ============================================================
-- SHOP ROBUX
-- ============================================================
local boosters = UIKit.window("Shop", UDim2.new(0, 1320, 0, 660), T.Pink)
Panels.boosters = boosters

-- Illustration d'un booster (paquet de cartes avec le brainrot le plus rare dessus)
local function packArt(parent, booster)
	local pack = Instance.new("Frame")
	pack.Size = UDim2.new(0.78, 0, 0, 150)
	pack.AnchorPoint = Vector2.new(0.5, 0)
	pack.Position = UDim2.new(0.5, 0, 0, 12)
	pack.BackgroundColor3 = Color3.new(1, 1, 1)
	pack.BorderSizePixel = 0
	pack.Parent = parent
	UIKit.corner(pack, 10)
	UIKit.outline(pack, 3)
	UIKit.gradient(pack, booster.Color:Lerp(Color3.new(1, 1, 1), 0.35), booster.Color:Lerp(Color3.new(0, 0, 0), 0.5), 25)
	-- bord dentelé en haut et en bas (comme un vrai paquet)
	for i = 0, 8 do
		for _, y in ipairs({0, 1}) do
			local tooth = Instance.new("Frame")
			tooth.AnchorPoint = Vector2.new(0.5, 0.5)
			tooth.Position = UDim2.new(i / 8, 0, y, 0)
			tooth.Size = UDim2.new(0, 10, 0, 10)
			tooth.Rotation = 45
			tooth.BackgroundColor3 = booster.Color:Lerp(Color3.new(0, 0, 0), 0.35)
			tooth.BorderSizePixel = 0
			tooth.Parent = pack
		end
	end
	-- reflet
	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(1, 0, 1, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0
	shine.BorderSizePixel = 0
	shine.ZIndex = 4
	shine.Parent = pack
	UIKit.corner(shine, 10)
	local shineGradient = Instance.new("UIGradient")
	shineGradient.Rotation = 25
	shineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 1),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(0.55, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	shineGradient.Parent = shine
	game:GetService("CollectionService"):AddTag(shineGradient, "HoloShine")

	-- le brainrot vedette : le plus rare du booster
	local bestRarity = booster.Odds[#booster.Odds][1]
	local featured = GameConfig.getCardsOfRarity(bestRarity)[1]
	if featured then
		local view = Instance.new("Frame")
		view.AnchorPoint = Vector2.new(0.5, 0)
		view.Size = UDim2.new(0.62, 0, 0.62, 0)
		view.Position = UDim2.new(0.5, 0, 0.12, 0)
		view.BackgroundTransparency = 1
		view.Rotation = -6
		view.Parent = pack
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.AspectRatio = CardRenderer.ASPECT
		ratio.Parent = view
		CardRenderer.create(featured.Name, "Normal", view)
	end
	UIKit.label(pack, "BOOSTER", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(0.9, 0, 0, 22),
		Font = UIKit.TitleFont,
		ZIndex = 5,
	})
	return pack
end

UIKit.label(boosters.content, "BOOSTERS : DES BRAINROTS SANS MINER", {Size = UDim2.new(1, 0, 0, 26), Font = UIKit.TitleFont, TextColor3 = T.Gold})
local boosterRow = Instance.new("Frame")
boosterRow.Size = UDim2.new(1, 0, 0, 380)
boosterRow.Position = UDim2.new(0, 0, 0, 32)
boosterRow.BackgroundTransparency = 1
boosterRow.Parent = boosters.content
horizontalList(boosterRow, 12)

for order, booster in ipairs(GameConfig.BOOSTERS) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 178, 1, 0)
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.Parent = boosterRow
	UIKit.corner(card, 18)
	UIKit.outline(card, 3.5)
	UIKit.gradient(card, booster.Color:Lerp(Color3.new(1, 1, 1), 0.15), booster.Color:Lerp(Color3.new(0, 0, 0), 0.6), 90)

	packArt(card, booster)
	UIKit.label(card, booster.Name, {Size = UDim2.new(0.94, 0, 0, 28), Position = UDim2.new(0.03, 0, 0, 170), Font = UIKit.TitleFont})
	UIKit.label(card, booster.Cards .. " carte" .. (booster.Cards > 1 and "s" or "") .. (booster.Exclusive and "  •  EXCLUSIF" or ""), {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 197),
		TextColor3 = booster.Exclusive and T.Gold or T.SubText,
		Font = UIKit.TitleFont,
	})

	local odds = Instance.new("Frame")
	odds.Size = UDim2.new(0.9, 0, 0, 108)
	odds.Position = UDim2.new(0.05, 0, 0, 214)
	odds.BackgroundColor3 = Color3.new(0, 0, 0)
	odds.BackgroundTransparency = 0.55
	odds.Parent = card
	UIKit.corner(odds, 12)
	local oddsGrid = Instance.new("UIGridLayout")
	oddsGrid.CellSize = UDim2.new(0.5, -2, 0, 16)
	oddsGrid.CellPadding = UDim2.new(0, 2, 0, 2)
	oddsGrid.SortOrder = Enum.SortOrder.LayoutOrder
	oddsGrid.Parent = odds
	UIKit.padding(odds, 6)
	for i, entry in ipairs(booster.Odds) do
		UIKit.label(odds, entry[1] .. " " .. entry[2] .. "%", {
			TextColor3 = GameConfig.RARITIES[entry[1]].Color,
			LayoutOrder = i,
		})
	end

	local buy = UIKit.button(card, "R$ " .. booster.Price, T.Green, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(0.86, 0, 0, 46),
	})
	buy.MouseButton1Click:Connect(function()
		Remotes.BuyBooster:FireServer(booster.Id)
	end)
end

-- Potion + tours de roue
local extraRow = Instance.new("Frame")
extraRow.Size = UDim2.new(1, 0, 0, 130)
extraRow.Position = UDim2.new(0, 0, 1, -130)
extraRow.BackgroundTransparency = 1
extraRow.Parent = boosters.content
horizontalList(extraRow, 14)

local function productCard(order, color, icon, title, subtitle, width)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, width, 1, 0)
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.Parent = extraRow
	UIKit.corner(card, 18)
	UIKit.outline(card, 3.5)
	UIKit.gradient(card, color:Lerp(Color3.new(1, 1, 1), 0.15), color:Lerp(Color3.new(0, 0, 0), 0.55), 90)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Size = UDim2.new(0, 90, 0, 90)
	iconLabel.Position = UDim2.new(0, 14, 0.5, -45)
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = card
	UIKit.label(card, title, {Size = UDim2.new(1, -120, 0, 30), Position = UDim2.new(0, 112, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Font = UIKit.TitleFont})
	UIKit.label(card, subtitle, {Size = UDim2.new(1, -120, 0, 20), Position = UDim2.new(0, 112, 0, 44), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.SubText})
	return card
end

local potion = GameConfig.PRODUCTS.LuckPotion
local potionCard = productCard(1, Color3.fromRGB(40, 200, 140), "🧪", potion.Name, potion.Minutes .. " min : raretés x2", 290)
UIKit.button(potionCard, "R$ " .. potion.Price, T.Green, {
	Position = UDim2.new(0, 112, 1, -56),
	Size = UDim2.new(0, 160, 0, 44),
}).MouseButton1Click:Connect(function()
	Remotes.BuyProduct:FireServer("LuckPotion")
end)

local spinsCard = productCard(2, Color3.fromRGB(255, 120, 60), "🎡", "Tours de roue", "Tente ta chance sur la roue !", 480)

-- Game Pass : argent x2 à vie
local doubleCash = GameConfig.GAMEPASSES.DoubleCash
local doubleCard = productCard(3, Color3.fromRGB(255, 190, 40), "💰", doubleCash.Name .. " (à vie)", doubleCash.Description, 260)
local doubleButton = UIKit.button(doubleCard, "R$ " .. doubleCash.Price, T.Green, {
	Position = UDim2.new(0, 112, 1, -56),
	Size = UDim2.new(0, 130, 0, 44),
})
doubleButton.Name = "DoubleCashButton"
doubleButton.MouseButton1Click:Connect(function()
	Remotes.BuyProduct:FireServer("DoubleCash")
end)
local function refreshDoubleCash()
	local owned = player:GetAttribute("DoubleCash") == true
	doubleButton.Text = owned and "ACHETÉ ✓" or ("R$ " .. doubleCash.Price)
	UIKit.setButtonColor(doubleButton, owned and T.Gray or T.Green)
end
player:GetAttributeChangedSignal("DoubleCash"):Connect(refreshDoubleCash)
refreshDoubleCash()

-- Game Pass : tapis volant
local carpetPass = GameConfig.GAMEPASSES.FlyingCarpet
local carpetCard = productCard(4, Color3.fromRGB(150, 70, 230), "🧞", carpetPass.Name, carpetPass.Description, 260)
local carpetButton = UIKit.button(carpetCard, "R$ " .. carpetPass.Price, T.Green, {
	Position = UDim2.new(0, 112, 1, -56),
	Size = UDim2.new(0, 130, 0, 44),
})
carpetButton.Name = "CarpetButton"
carpetButton.MouseButton1Click:Connect(function()
	Remotes.BuyProduct:FireServer("FlyingCarpet")
end)
local function refreshCarpet()
	local owned = player:GetAttribute("FlyingCarpet") == true
	carpetButton.Text = owned and "ACHETÉ ✓" or ("R$ " .. carpetPass.Price)
	UIKit.setButtonColor(carpetButton, owned and T.Gray or T.Green)
end
player:GetAttributeChangedSignal("FlyingCarpet"):Connect(refreshCarpet)
refreshCarpet()
for i, key in ipairs({"Spin1", "Spin3", "Spin10"}) do
	local product = GameConfig.PRODUCTS[key]
	UIKit.button(spinsCard, product.Spins .. " • R$" .. product.Price, T.Green, {
		Position = UDim2.new(0, 112 + (i - 1) * 122, 1, -56),
		Size = UDim2.new(0, 116, 0, 44),
	}).MouseButton1Click:Connect(function()
		Remotes.BuyProduct:FireServer(key)
	end)
end

-- ============================================================
-- OUVERTURE D'UN BOOSTER : les cartes arrivent face cachée, on CLIQUE dessus pour les révéler.
-- Une carte rare a une lueur de sa couleur au dos (suspense !) et fait un flash quand on la retourne.
-- ============================================================
local function cardBack(slot, accent, rarity, boosterName)
	local button = Instance.new("TextButton")
	button.Name = "CardBack"
	button.Text = ""
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.new(0.5, 0, 0.5, 0)
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.ZIndex = 42
	button.Parent = slot
	UIKit.corner(button, 16)
	UIKit.gradient(button, accent:Lerp(Color3.new(1, 1, 1), 0.15), Color3.fromRGB(18, 16, 32), 60)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = Color3.new(1, 1, 1)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button

	-- motif en losanges
	for i = 0, 5 do
		for j = 0, 8 do
			local diamond = Instance.new("Frame")
			diamond.AnchorPoint = Vector2.new(0.5, 0.5)
			diamond.Position = UDim2.new((i + (j % 2) * 0.5) / 5, 0, j / 8, 0)
			diamond.Size = UDim2.new(0, 16, 0, 16)
			diamond.Rotation = 45
			diamond.BackgroundColor3 = Color3.new(1, 1, 1)
			diamond.BackgroundTransparency = 0.9
			diamond.BorderSizePixel = 0
			diamond.ZIndex = 42
			diamond.Parent = button
		end
	end
	local emblem = Instance.new("Frame")
	emblem.AnchorPoint = Vector2.new(0.5, 0.5)
	emblem.Position = UDim2.new(0.5, 0, 0.45, 0)
	emblem.Size = UDim2.new(0, 110, 0, 110)
	emblem.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
	emblem.ZIndex = 43
	emblem.Parent = button
	UIKit.corner(emblem, 55)
	local emblemStroke = Instance.new("UIStroke")
	emblemStroke.Thickness = 4
	emblemStroke.Color = accent
	emblemStroke.Parent = emblem
	UIKit.label(emblem, "?", {Size = UDim2.new(0.7, 0, 0.7, 0), Position = UDim2.new(0.15, 0, 0.15, 0), Font = UIKit.TitleFont, ZIndex = 44})
	UIKit.label(button, boosterName, {Size = UDim2.new(0.9, 0, 0, 26), Position = UDim2.new(0.05, 0, 0.72, 0), Font = UIKit.TitleFont, ZIndex = 43})
	UIKit.label(button, "CLIQUE !", {Size = UDim2.new(0.9, 0, 0, 22), Position = UDim2.new(0.05, 0, 0.82, 0), Font = UIKit.TitleFont, TextColor3 = T.Gold, ZIndex = 43})

	-- Lueur de la rareté derrière la carte (à partir d'Épique)
	if rarity.Order >= 4 then
		local glow = Instance.new("Frame")
		glow.Name = "RarityGlow"
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.Size = UDim2.new(1.25, 0, 1.15, 0)
		glow.BackgroundColor3 = rarity.Color
		glow.BackgroundTransparency = 0.45
		glow.ZIndex = 41
		glow.Parent = slot
		UIKit.corner(glow, 40)
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		fade.Parent = glow
		game:GetService("CollectionService"):AddTag(glow, "MutationPulse")
	end

	-- petit grossissement au survol
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), {Scale = 1.05}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), {Scale = 1}):Play()
	end)
	return button
end

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
	overlay.Name = "BoosterOpening"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.2
	overlay.ZIndex = 40
	overlay.Parent = UIKit.ScreenGui
	UIKit.label(overlay, booster and booster.Name or "Booster", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.05, 0),
		Size = UDim2.new(0, 560, 0, 60),
		Font = UIKit.TitleFont,
		TextColor3 = accent,
		ZIndex = 41,
	})
	local hint = UIKit.label(overlay, "Clique sur les cartes pour les révéler !", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.05, 62),
		Size = UDim2.new(0, 560, 0, 30),
		Font = UIKit.TitleFont,
		ZIndex = 41,
	})
	local row = Instance.new("Frame")
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.Size = UDim2.new(0, #cards * 250 + 20, 0, 380)
	row.BackgroundTransparency = 1
	row.ZIndex = 41
	row.Parent = overlay
	horizontalList(row, 30)

	local done = UIKit.button(overlay, "SUPER !", T.Green, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.86, 0),
		Size = UDim2.new(0, 260, 0, 58),
		Visible = false,
		ZIndex = 41,
	})
	local revealAll = UIKit.button(overlay, "TOUT RÉVÉLER", T.Purple, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.86, 0),
		Size = UDim2.new(0, 260, 0, 58),
		ZIndex = 41,
	})

	local hidden = #cards
	local reveals = {}

	for i, result in ipairs(cards) do
		local card = GameConfig.getCard(result.Name)
		local rarity = card and GameConfig.RARITIES[card.Rarity] or GameConfig.RARITIES.Commun

		local slot = Instance.new("Frame")
		slot.Size = UDim2.new(0, 220, 0, 352)
		slot.BackgroundTransparency = 1
		slot.LayoutOrder = i
		slot.ZIndex = 41
		slot.Parent = row

		-- les cartes arrivent en glissant
		local drop = Instance.new("UIScale")
		drop.Scale = 0
		drop.Parent = slot
		task.delay(0.1 + i * 0.15, function()
			TweenService:Create(drop, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
		end)

		local back = cardBack(slot, accent, rarity, booster and booster.Name or "Booster")
		local revealed = false
		local function reveal()
			if revealed then return end
			revealed = true
			hidden -= 1
			local glow = slot:FindFirstChild("RarityGlow")
			local shrink = TweenService:Create(back, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 1, 0)})
			shrink:Play()
			shrink.Completed:Wait()
			back:Destroy()
			if glow then
				glow:Destroy()
			end
			Sounds.play(rarity.Order >= 5 and "RareCard" or "Card")

			-- flash de lumière pour les cartes rares
			if rarity.Order >= 4 then
				local burst = Instance.new("Frame")
				burst.AnchorPoint = Vector2.new(0.5, 0.5)
				burst.Position = UDim2.new(0.5, 0, 0.5, 0)
				burst.Size = UDim2.new(0.4, 0, 0.25, 0)
				burst.BackgroundColor3 = rarity.Color
				burst.BackgroundTransparency = 0.2
				burst.ZIndex = 41
				burst.Parent = slot
				UIKit.corner(burst, 200)
				TweenService:Create(burst, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {Size = UDim2.new(2.2, 0, 1.4, 0), BackgroundTransparency = 1}):Play()
				Debris:AddItem(burst, 0.7)
				UIKit.label(slot, GameConfig.upper(card.Rarity) .. " !", {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 0, -8),
					Size = UDim2.new(1.3, 0, 0, 36),
					Font = UIKit.TitleFont,
					TextColor3 = rarity.Color,
					ZIndex = 45,
				})
			end

			local front = Instance.new("Frame")
			front.Name = "CardFront"
			front.AnchorPoint = Vector2.new(0.5, 0.5)
			front.Position = UDim2.new(0.5, 0, 0.5, 0)
			front.Size = UDim2.new(0, 0, 1, 0)
			front.BackgroundTransparency = 1
			front.ZIndex = 42
			front.Parent = slot
			CardRenderer.create(result.Name, result.Mutation, front, result.Serial)
			TweenService:Create(front, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 1, 0)}):Play()

			if hidden == 0 then
				revealAll.Visible = false
				hint.Text = ""
				task.delay(0.4, function()
					done.Visible = true
				end)
			end
		end
		reveals[i] = reveal
		back.MouseButton1Click:Connect(function()
			task.spawn(reveal)
		end)
	end

	revealAll.MouseButton1Click:Connect(function()
		for i, reveal in ipairs(reveals) do
			task.delay((i - 1) * 0.3, reveal)
		end
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
		if armory.isOpen() then renderArmory() end
		if index.isOpen() then renderIndex() end
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
indexFolder.ChildAdded:Connect(scheduleRefresh)
rebirths.Changed:Connect(scheduleRefresh)
pickaxeTier.Changed:Connect(scheduleRefresh)
batTier.Changed:Connect(scheduleRefresh)
cash.Changed:Connect(function()
	if rebirth.isOpen() then
		updateCashBar()
	end
end)

return Panels
