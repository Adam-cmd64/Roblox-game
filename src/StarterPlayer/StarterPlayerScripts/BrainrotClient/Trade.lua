-- ModuleScript client : les échanges entre joueurs.
--   - Fenêtre "Échange" : liste des joueurs du serveur (échange possible si 3 rebirths d'écart max)
--   - Demande reçue : petite fenêtre Accepter / Refuser
--   - Échange en cours : ton offre, son offre, ton inventaire, bouton Prêt

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CardRenderer = require(ReplicatedStorage:WaitForChild("CardRenderer"))
local UIKit = require(script.Parent.UIKit)
local T = UIKit.Theme

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local brainrots = player:WaitForChild("Brainrots")

local Trade = {}
local ACCENT = Color3.fromRGB(0, 200, 190)

local function clearChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function rebirthsOf(other)
	local stats = other:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Rebirths")
	return value and value.Value or 0
end

-- ============================================================
-- LISTE DES JOUEURS
-- ============================================================
local list = UIKit.window("🤝 Échanges", UDim2.new(0, 560, 0, 480), ACCENT)
Trade.window = list
UIKit.label(list.content, "Tu peux échanger avec les joueurs qui ont au maximum " .. GameConfig.TRADE.MaxRebirthDifference .. " rebirths d'écart avec toi.", {
	Size = UDim2.new(1, 0, 0, 20),
	TextColor3 = T.SubText,
	Font = Enum.Font.GothamBold,
})
local playerList = UIKit.new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -30),
	Position = UDim2.new(0, 0, 0, 30),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
}, list.content)
UIKit.new("UIListLayout", {Padding = UDim.new(0, 8)}, playerList)

local function renderPlayers()
	clearChildren(playerList)
	local myRebirths = rebirthsOf(player)
	local count = 0
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			count += 1
			local row = UIKit.panel(playerList, {Size = UDim2.new(1, -10, 0, 60), BackgroundColor3 = T.PanelLight})
			UIKit.label(row, other.DisplayName, {Size = UDim2.new(0.5, 0, 0, 26), Position = UDim2.new(0, 14, 0, 6), TextXAlignment = Enum.TextXAlignment.Left})
			local theirs = rebirthsOf(other)
			UIKit.label(row, "🔄 " .. theirs .. " rebirths", {
				Size = UDim2.new(0.5, 0, 0, 18),
				Position = UDim2.new(0, 14, 0, 34),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = T.SubText,
				Font = Enum.Font.GothamBold,
			})
			local allowed = math.abs(theirs - myRebirths) <= GameConfig.TRADE.MaxRebirthDifference
			local button = UIKit.button(row, allowed and "Échanger" or "🔒 Trop d'écart", allowed and ACCENT or T.Gray, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 170, 0, 40),
			})
			if allowed then
				button.MouseButton1Click:Connect(function()
					Remotes.TradeRequest:FireServer(other)
				end)
			end
		end
	end
	if count == 0 then
		UIKit.label(playerList, "Personne d'autre sur le serveur pour l'instant 😢", {Size = UDim2.new(1, 0, 0, 40), TextColor3 = T.SubText})
	end
end
list.onOpen = renderPlayers

-- ============================================================
-- DEMANDE RECUE
-- ============================================================
local function showRequest(from)
	local popup = UIKit.panel(UIKit.ScreenGui, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -160),
		Size = UDim2.new(0, 320, 0, 120),
		BackgroundTransparency = 0.02,
		ZIndex = 35,
	})
	UIKit.stroke(popup, ACCENT, 2.5, 0)
	UIKit.label(popup, "🤝 " .. from.DisplayName .. " veut échanger !", {Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 10)})
	local accept = UIKit.button(popup, "Accepter", T.Green, {Size = UDim2.new(0.44, 0, 0, 42), Position = UDim2.new(0.04, 0, 0, 60)})
	local decline = UIKit.button(popup, "Refuser", T.Red, {Size = UDim2.new(0.44, 0, 0, 42), Position = UDim2.new(0.52, 0, 0, 60)})
	local answered = false
	local function answer(value)
		if answered then return end
		answered = true
		Remotes.TradeRespond:FireServer(from, value)
		popup:Destroy()
	end
	accept.MouseButton1Click:Connect(function() answer(true) end)
	decline.MouseButton1Click:Connect(function() answer(false) end)
	task.delay(25, function()
		if not answered then
			answered = true
			popup:Destroy()
		end
	end)
end

-- ============================================================
-- ECHANGE EN COURS
-- ============================================================
local session = UIKit.window("🤝 Échange", UDim2.new(0, 900, 0, 600), ACCENT)
local sc = session.content
local state = nil

local function column(title, x)
	local box = UIKit.new("Frame", {Size = UDim2.new(0.49, 0, 0, 250), Position = UDim2.new(x, 0, 0, 0), BackgroundColor3 = T.Panel, BorderSizePixel = 0}, sc)
	UIKit.corner(box, 12)
	local label = UIKit.label(box, title, {Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 6)})
	local grid = UIKit.scrollGrid(box, UDim2.new(0, 96, 0, 134), {Size = UDim2.new(1, -10, 1, -40), Position = UDim2.new(0, 5, 0, 36)})
	return box, label, grid
end
local _, myTitle, myGrid = column("Ton offre", 0)
local _, theirTitle, theirGrid = column("Son offre", 0.51)

UIKit.label(sc, "Ton inventaire (clique pour ajouter / retirer) :", {
	Size = UDim2.new(1, 0, 0, 22),
	Position = UDim2.new(0, 0, 0, 258),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold,
})
local invBox = UIKit.new("Frame", {Size = UDim2.new(1, 0, 0, 160), Position = UDim2.new(0, 0, 0, 284), BackgroundColor3 = T.Panel, BorderSizePixel = 0}, sc)
UIKit.corner(invBox, 12)
local invGrid = UIKit.scrollGrid(invBox, UDim2.new(0, 96, 0, 134), {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5)})

local statusLabel = UIKit.label(sc, "", {Size = UDim2.new(0.5, 0, 0, 30), Position = UDim2.new(0, 0, 1, -44), TextXAlignment = Enum.TextXAlignment.Left})
local readyButton = UIKit.button(sc, "✅ Prêt", T.Green, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -190, 1, 0), Size = UDim2.new(0, 180, 0, 46)})
local cancelButton = UIKit.button(sc, "Annuler", T.Red, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.new(0, 170, 0, 46)})

readyButton.MouseButton1Click:Connect(function()
	Remotes.TradeAction:FireServer("ready")
end)
cancelButton.MouseButton1Click:Connect(function()
	Remotes.TradeAction:FireServer("cancel")
end)

local function miniCard(parent, name, mutation, order, onClick)
	local button = UIKit.new("TextButton", {Text = "", BackgroundTransparency = 1, LayoutOrder = order, AutoButtonColor = false}, parent)
	CardRenderer.createFitted(name, mutation, button)
	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end
	return button
end

local function render()
	if not state then return end
	clearChildren(myGrid)
	clearChildren(theirGrid)
	clearChildren(invGrid)

	theirTitle.Text = "Offre de " .. state.Partner .. (state.TheirReady and "  ✅" or "")
	myTitle.Text = "Ton offre" .. (state.MyReady and "  ✅" or "")

	local offered = {}
	for i, entry in ipairs(state.Mine) do
		offered[entry.Id] = true
		miniCard(myGrid, entry.Name, entry.Mutation, i, function()
			Remotes.TradeAction:FireServer("remove", entry.Id)
		end)
	end
	for i, entry in ipairs(state.Theirs) do
		miniCard(theirGrid, entry.Name, entry.Mutation, i)
	end

	local order = 0
	for _, item in ipairs(brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) == 0 and not offered[item.Name] then
			order += 1
			miniCard(invGrid, item.Value, item:GetAttribute("Mutation"), order, function()
				Remotes.TradeAction:FireServer("add", item.Name)
			end)
		end
	end

	if state.Countdown then
		statusLabel.Text = "⏳ Échange dans " .. state.Countdown .. "..."
		statusLabel.TextColor3 = T.Gold
	elseif state.MyReady then
		statusLabel.Text = "En attente de " .. state.Partner .. "..."
		statusLabel.TextColor3 = T.SubText
	else
		statusLabel.Text = "Ajoute des cartes puis clique sur Prêt"
		statusLabel.TextColor3 = T.SubText
	end
	readyButton.Text = state.MyReady and "↩️ Pas prêt" or "✅ Prêt"
	readyButton.setColor(state.MyReady and T.Gray or T.Green)
end

-- Fermer la fenêtre avec la croix = annuler l'échange
session.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
	if not session.overlay.Visible and state then
		Remotes.TradeAction:FireServer("cancel")
	end
end)

function Trade.init(Hud)
	Remotes.TradeEvent.OnClientEvent:Connect(function(kind, payload)
		if kind == "request" then
			showRequest(payload.From)
		elseif kind == "open" then
			state = {Partner = payload.Partner, Mine = {}, Theirs = {}}
			session.open()
			render()
		elseif kind == "state" then
			state = payload
			if not session.overlay.Visible then
				session.open()
			end
			render()
		elseif kind == "closed" then
			state = nil
			session.close()
			Hud.notify("❌ Échange annulé : " .. (payload.Reason or ""), "error")
		elseif kind == "done" then
			state = nil
			session.close()
			Hud.notify("🎉 Échange réussi avec " .. payload.Partner .. " !", "success")
		end
	end)
end

return Trade
