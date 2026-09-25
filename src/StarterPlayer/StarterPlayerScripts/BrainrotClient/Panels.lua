-- ModuleScript client : les fenêtres du jeu.
--   🎒 Inventaire : tes cartes pas encore posées (clique pour la prendre en main)
--   📖 Index      : tous les brainrots du jeu (possédés ou non)
--   🔄 Rebirth    : ce que tu débloques + les conditions
--   ⛏️ Boutique   : les pioches (s'ouvre au comptoir de la boutique)
--   💎 Boosters   : la boutique Robux + animation d'ouverture

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

local function clearChildren(parent, className)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(className) then
			child:Destroy()
		end
	end
end

-- ============================================================
-- INVENTAIRE
-- ============================================================
local inventory = UIKit.window("🎒 Inventaire", UDim2.new(0, 820, 0, 540), T.Blue)
Panels.inventory = inventory

UIKit.label(inventory.content, "Clique sur une carte pour la prendre en main, puis va dans ta 🏠 base et appuie sur E devant un emplacement libre.", {
	Size = UDim2.new(1, 0, 0, 20),
	Font = Enum.Font.GothamBold,
	TextColor3 = T.SubText,
	ZIndex = 21,
})
local inventoryGrid = UIKit.scrollGrid(inventory.content, UDim2.new(0, 140, 0, 230), {
	Size = UDim2.new(1, 0, 1, -30),
	Position = UDim2.new(0, 0, 0, 30),
})
local emptyLabel = UIKit.label(inventory.content, "Aucune carte pour l'instant.\nVa miner dans la ⛏️ Mine pour trouver des brainrots !", {
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0.4, 0),
	TextColor3 = T.SubText,
	ZIndex = 22,
})

local function renderInventory()
	if not inventory.overlay.Visible then return end
	clearChildren(inventoryGrid, "Frame")

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
		local tile = UIKit.new("Frame", {BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 21}, inventoryGrid)
		local cardHolder = UIKit.new("Frame", {Size = UDim2.new(1, 0, 0, 196), BackgroundTransparency = 1}, tile)
		CardRenderer.createFitted(item.Value, item:GetAttribute("Mutation"), cardHolder)
		local take = UIKit.button(tile, "✋ Prendre", T.Green, {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 1, -30),
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
local index = UIKit.window("📖 Index des brainrots", UDim2.new(0, 860, 0, 560), T.Gold)
Panels.index = index
local indexProgress = UIKit.label(index.content, "", {Size = UDim2.new(1, 0, 0, 22), TextColor3 = T.SubText, ZIndex = 21})
local indexGrid = UIKit.scrollGrid(index.content, UDim2.new(0, 145, 0, 225), {
	Size = UDim2.new(1, 0, 1, -30),
	Position = UDim2.new(0, 0, 0, 30),
})

local function renderIndex()
	clearChildren(indexGrid, "Frame")
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
		local tile = UIKit.new("Frame", {BackgroundTransparency = 1, LayoutOrder = order}, index.content)
		tile.Parent = indexGrid
		local holder = UIKit.new("Frame", {Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1}, tile)
		local fitted = CardRenderer.createFitted(card.Name, "Normal", holder)
		if count == 0 then
			-- Silhouette : carte pas encore trouvée
			local veil = UIKit.new("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.12,
				ZIndex = 10,
			}, fitted)
			UIKit.corner(veil, 10)
			UIKit.label(veil, "❓", {Size = UDim2.new(0.5, 0, 0.3, 0), Position = UDim2.new(0.25, 0, 0.3, 0), ZIndex = 11})
			UIKit.label(veil, card.Rarity, {
				Size = UDim2.new(0.9, 0, 0.1, 0),
				Position = UDim2.new(0.05, 0, 0.65, 0),
				TextColor3 = GameConfig.RARITIES[card.Rarity].Color,
				ZIndex = 11,
			})
		end
		UIKit.label(tile, count > 0 and ("Possédés : " .. count) or "Pas encore trouvé", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 1, -20),
			TextColor3 = count > 0 and T.Green or T.SubText,
			Font = Enum.Font.GothamBold,
		})
	end
	indexProgress.Text = "Découverts : " .. found .. " / " .. #GameConfig.CARDS
end
index.onOpen = renderIndex

-- ============================================================
-- REBIRTH
-- ============================================================
local rebirth = UIKit.window("🔄 Rebirth", UDim2.new(0, 760, 0, 600), T.Purple)
Panels.rebirth = rebirth
local rc = rebirth.content

UIKit.label(rc, "⚠️ Tu perds tout ton argent et les brainrots demandés quand tu fais un rebirth", {
	Size = UDim2.new(1, 0, 0, 22),
	TextColor3 = Color3.fromRGB(255, 110, 110),
	Font = Enum.Font.GothamBold,
})
UIKit.label(rc, "Tu débloques :", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 34)})

local unlockRow = UIKit.new("Frame", {Size = UDim2.new(1, 0, 0, 104), Position = UDim2.new(0, 0, 0, 64), BackgroundTransparency = 1}, rc)
UIKit.new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 12),
}, unlockRow)

local function unlockTile(icon, title, color)
	local tile = UIKit.new("Frame", {Size = UDim2.new(0, 150, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, unlockRow)
	UIKit.corner(tile, 12)
	UIKit.gradient(tile, color, color:Lerp(Color3.new(0, 0, 0), 0.55), 90)
	UIKit.stroke(tile, Color3.new(1, 1, 1), 2, 0.6)
	UIKit.label(tile, icon, {Size = UDim2.new(1, 0, 0, 42), Position = UDim2.new(0, 0, 0, 8), Font = Enum.Font.GothamBold})
	return UIKit.label(tile, title, {Size = UDim2.new(0.9, 0, 0, 40), Position = UDim2.new(0.05, 0, 0, 56), TextWrapped = true})
end
local unlockIncome = unlockTile("💰", "", Color3.fromRGB(60, 200, 90))
local unlockSlot = unlockTile("🧱", "", Color3.fromRGB(60, 140, 255))
local unlockPickaxe = unlockTile("⛏️", "", Color3.fromRGB(210, 140, 70))
local unlockRank = unlockTile("⭐", "", Color3.fromRGB(170, 80, 255))

UIKit.label(rc, "Conditions :", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 180)})
local cashBarBack = UIKit.new("Frame", {
	Size = UDim2.new(1, -40, 0, 34),
	Position = UDim2.new(0, 20, 0, 212),
	BackgroundColor3 = T.PanelLight,
	BorderSizePixel = 0,
}, rc)
UIKit.corner(cashBarBack, 10)
local cashBarFill = UIKit.new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, cashBarBack)
UIKit.corner(cashBarFill, 10)
UIKit.gradient(cashBarFill, Color3.fromRGB(90, 230, 110), Color3.fromRGB(30, 160, 70), 90)
local cashBarText = UIKit.label(cashBarBack, "", {Size = UDim2.new(1, 0, 0.8, 0), Position = UDim2.new(0, 0, 0.1, 0), ZIndex = 3})

local requiredRow = UIKit.new("Frame", {Size = UDim2.new(1, 0, 0, 170), Position = UDim2.new(0, 0, 0, 256), BackgroundTransparency = 1}, rc)
UIKit.new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 12),
}, requiredRow)

local rebirthButton = UIKit.button(rc, "🔄 REBIRTH", T.Green, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(0, 300, 0, 50),
})
rebirthButton.MouseButton1Click:Connect(function()
	Remotes.Rebirth:FireServer()
end)

local function renderRebirth()
	local current = rebirths.Value
	local nextNumber = current + 1
	local requirement = GameConfig.getRebirth(nextNumber)

	unlockIncome.Text = "Revenu x" .. GameConfig.getIncomeMultiplier(nextNumber)
	local slotsNow, slotsNext = GameConfig.getSlotCount(current), GameConfig.getSlotCount(nextNumber)
	unlockSlot.Text = slotsNext > slotsNow and ("+1 emplacement (" .. slotsNext .. ")") or "Emplacements max"
	local nextPickaxe
	for _, pickaxe in ipairs(GameConfig.PICKAXES) do
		if pickaxe.RequiredRebirths == nextNumber then
			nextPickaxe = pickaxe
		end
	end
	unlockPickaxe.Text = nextPickaxe and (nextPickaxe.Name .. " (boutique)") or "Plus de chance"
	unlockRank.Text = "Rebirth " .. nextNumber

	local ratio = math.clamp(cash.Value / requirement.Cash, 0, 1)
	cashBarFill.Size = UDim2.new(ratio, 0, 1, 0)
	cashBarText.Text = "$" .. GameConfig.format(cash.Value) .. " / $" .. GameConfig.format(requirement.Cash)

	clearChildren(requiredRow, "Frame")
	local ok = cash.Value >= requirement.Cash
	local used = {}
	for _, cardName in ipairs(requirement.Cards) do
		local has = false
		for _, item in ipairs(brainrots:GetChildren()) do
			if item.Value == cardName and not used[item] then
				used[item] = true
				has = true
				break
			end
		end
		ok = ok and has
		local tile = UIKit.new("Frame", {Size = UDim2.new(0, 110, 1, 0), BackgroundTransparency = 1}, requiredRow)
		local holder = UIKit.new("Frame", {Size = UDim2.new(1, 0, 0, 148), BackgroundTransparency = 1}, tile)
		local fitted = CardRenderer.createFitted(cardName, "Normal", holder)
		if not has then
			local veil = UIKit.new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 10}, fitted)
			UIKit.corner(veil, 10)
		end
		UIKit.label(tile, has and "✅ Possédé" or "❌ Manquant", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 1, -20),
			TextColor3 = has and T.Green or T.Red,
			Font = Enum.Font.GothamBold,
		})
	end

	rebirthButton.setColor(ok and T.Green or T.Gray)
	rebirthButton.Text = ok and "🔄 REBIRTH" or "🔒 Conditions manquantes"
end
rebirth.onOpen = renderRebirth

-- ============================================================
-- BOUTIQUE DE PIOCHES (au comptoir)
-- ============================================================
local shop = UIKit.window("⛏️ Boutique de pioches", UDim2.new(0, 760, 0, 560), Color3.fromRGB(200, 130, 60))
Panels.shop = shop
local shopList = UIKit.new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
}, shop.content)
UIKit.new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, shopList)

local function renderShop()
	clearChildren(shopList, "Frame")
	for tier, pickaxe in ipairs(GameConfig.PICKAXES) do
		local row = UIKit.panel(shopList, {Size = UDim2.new(1, -10, 0, 74), LayoutOrder = tier, BackgroundColor3 = T.PanelLight})
		local icon = UIKit.new("Frame", {Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0, 10, 0, 9), BackgroundColor3 = pickaxe.HeadColor, BorderSizePixel = 0}, row)
		UIKit.corner(icon, 10)
		UIKit.gradient(icon, Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 120), 90)
		UIKit.label(icon, "⛏️", {Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.1, 0, 0.1, 0), Font = Enum.Font.GothamBold})
		UIKit.label(row, pickaxe.Name, {Size = UDim2.new(0, 300, 0, 28), Position = UDim2.new(0, 78, 0, 8), TextXAlignment = Enum.TextXAlignment.Left})
		UIKit.label(row, string.format("💥 Dégâts %d   ⚡ %.1f coups/s   🍀 Chance x%s", pickaxe.Damage, 1 / pickaxe.Cooldown, tostring(pickaxe.Luck)), {
			Size = UDim2.new(0, 380, 0, 20),
			Position = UDim2.new(0, 78, 0, 42),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = T.SubText,
			Font = Enum.Font.GothamBold,
		})

		local text, color, clickable
		if tier <= pickaxeTier.Value then
			text, color = tier == pickaxeTier.Value and "✅ Équipée" or "Possédée", T.Gray
		elseif rebirths.Value < pickaxe.RequiredRebirths then
			text, color = "🔒 Rebirth " .. pickaxe.RequiredRebirths, T.Gray
		elseif tier > pickaxeTier.Value + 1 then
			text, color = "Achète la précédente", T.Gray
		else
			text, color, clickable = "Acheter $" .. GameConfig.format(pickaxe.Cost), cash.Value >= pickaxe.Cost and T.Green or T.Red, true
		end
		local buy = UIKit.button(row, text, color, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, 200, 0, 44),
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
-- BOOSTERS (ROBUX)
-- ============================================================
local boosters = UIKit.window("💎 Boosters de brainrots", UDim2.new(0, 900, 0, 520), Color3.fromRGB(255, 90, 160))
Panels.boosters = boosters
UIKit.label(boosters.content, "Obtiens des cartes sans miner ! Chaque booster contient 3 brainrots.", {
	Size = UDim2.new(1, 0, 0, 22),
	TextColor3 = T.SubText,
	Font = Enum.Font.GothamBold,
})
local boosterRow = UIKit.new("Frame", {Size = UDim2.new(1, 0, 1, -34), Position = UDim2.new(0, 0, 0, 34), BackgroundTransparency = 1}, boosters.content)
UIKit.new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 14),
}, boosterRow)

for _, booster in ipairs(GameConfig.BOOSTERS) do
	local pack = UIKit.new("Frame", {Size = UDim2.new(0, 196, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, boosterRow)
	UIKit.corner(pack, 16)
	UIKit.gradient(pack, booster.Color, booster.Color:Lerp(Color3.new(0, 0, 0), 0.65), 90)
	UIKit.stroke(pack, Color3.new(1, 1, 1), 2.5, 0.3)
	UIKit.label(pack, "🎴", {Size = UDim2.new(1, 0, 0, 70), Position = UDim2.new(0, 0, 0, 14), Font = Enum.Font.GothamBold})
	UIKit.label(pack, booster.Name, {Size = UDim2.new(0.9, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 92)})
	UIKit.label(pack, booster.Cards .. " cartes", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 124), TextColor3 = T.SubText, Font = Enum.Font.GothamBold})

	local odds = UIKit.new("Frame", {Size = UDim2.new(0.88, 0, 0, 150), Position = UDim2.new(0.06, 0, 0, 152), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6}, pack)
	UIKit.corner(odds, 10)
	UIKit.new("UIListLayout", {Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center}, odds)
	UIKit.padding(odds, 6)
	for _, entry in ipairs(booster.Odds) do
		UIKit.label(odds, entry[1] .. " : " .. entry[2] .. "%", {
			Size = UDim2.new(1, 0, 0, 22),
			TextColor3 = GameConfig.RARITIES[entry[1]].Color,
			Font = Enum.Font.GothamBold,
		})
	end

	local buy = UIKit.button(pack, "R$ " .. booster.Price, Color3.fromRGB(40, 200, 90), {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0.85, 0, 0, 46),
	})
	buy.MouseButton1Click:Connect(function()
		Remotes.BuyBooster:FireServer(booster.Id)
	end)
end

-- Animation d'ouverture d'un booster : les cartes se retournent une par une
local openSound = UIKit.new("Sound", {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5}, SoundService)

function Panels.openBooster(boosterId, cards)
	UIKit.closeAll()
	local booster
	for _, b in ipairs(GameConfig.BOOSTERS) do
		if b.Id == boosterId then
			booster = b
		end
	end
	local overlay = UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		ZIndex = 40,
	}, UIKit.ScreenGui)
	UIKit.label(overlay, (booster and booster.Name or "Booster") .. " !", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.1, 0),
		Size = UDim2.new(0, 500, 0, 50),
		TextColor3 = booster and booster.Color or T.Gold,
	})
	local row = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.52, 0),
		Size = UDim2.new(0, 3 * 230 + 40, 0, 320),
		BackgroundTransparency = 1,
	}, overlay)
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 20),
	}, row)

	for i, result in ipairs(cards) do
		local slot = UIKit.new("Frame", {Size = UDim2.new(0, 220, 0, 308), BackgroundTransparency = 1, LayoutOrder = i}, row)
		-- Dos de la carte
		local back = UIKit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, slot)
		UIKit.corner(back, 14)
		UIKit.gradient(back, booster and booster.Color or T.Purple, Color3.fromRGB(20, 20, 40), 45)
		UIKit.stroke(back, Color3.new(1, 1, 1), 3, 0.2)
		UIKit.label(back, "⛏️\nMINE\nBRAINROT", {Size = UDim2.new(0.8, 0, 0.5, 0), Position = UDim2.new(0.1, 0, 0.25, 0)})

		task.delay(0.7 + i * 0.8, function()
			-- Retournement : le dos se referme puis la carte s'ouvre
			local shrink = TweenService:Create(back, TweenInfo.new(0.18), {Size = UDim2.new(0, 0, 1, 0)})
			shrink:Play()
			shrink.Completed:Wait()
			back:Destroy()
			SoundService:PlayLocalSound(openSound)
			local front = UIKit.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundTransparency = 1,
			}, slot)
			CardRenderer.create(result.Name, result.Mutation, front)
			TweenService:Create(front, TweenInfo.new(0.22, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 1, 0)}):Play()
		end)
	end

	local done = UIKit.button(overlay, "Super ! 🎉", T.Green, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.84, 0),
		Size = UDim2.new(0, 240, 0, 50),
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
local function refreshOpen()
	if inventory.overlay.Visible then renderInventory() end
	if rebirth.overlay.Visible then renderRebirth() end
	if shop.overlay.Visible then renderShop() end
end

local pending = false
local function scheduleRefresh()
	if pending then return end
	pending = true
	task.delay(0.15, function()
		pending = false
		refreshOpen()
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

-- L'argent change souvent : on met à jour seulement la barre du rebirth et la boutique
cash.Changed:Connect(function()
	if rebirth.overlay.Visible then
		local requirement = GameConfig.getRebirth(rebirths.Value + 1)
		cashBarFill.Size = UDim2.new(math.clamp(cash.Value / requirement.Cash, 0, 1), 0, 1, 0)
		cashBarText.Text = "$" .. GameConfig.format(cash.Value) .. " / $" .. GameConfig.format(requirement.Cash)
	end
end)

return Panels
