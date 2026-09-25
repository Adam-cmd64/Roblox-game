-- ModuleScript client : les échanges entre joueurs.
--   - Fenêtre "Échange" : les joueurs du serveur (échange possible avec 3 rebirths d'écart max)
--   - Demande reçue : Accepter / Refuser
--   - Échange en cours : ton offre, son offre, ton sac, bouton Prêt

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
	return value and value:IsA("IntValue") and value.Value or 0
end

-- ============================================================
-- LISTE DES JOUEURS
-- ============================================================
local list = UIKit.window("Échange", UDim2.new(0, 580, 0, 480), T.Teal)
Trade.window = list
UIKit.label(list.content, "Max " .. GameConfig.TRADE.MaxRebirthDifference .. " rebirths d'écart", {
	Size = UDim2.new(1, 0, 0, 26),
	Font = UIKit.TitleFont,
	TextColor3 = T.SubText,
})
local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(1, 0, 1, -34)
playerList.Position = UDim2.new(0, 0, 0, 34)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 8
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.CanvasSize = UDim2.new()
playerList.Parent = list.content
local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 8)
playerLayout.Parent = playerList

local function renderPlayers()
	clearChildren(playerList)
	local myRebirths = rebirthsOf(player)
	local count = 0
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			count += 1
			local row = UIKit.box(playerList, {Size = UDim2.new(1, -12, 0, 66)})
			UIKit.label(row, other.DisplayName, {
				Size = UDim2.new(0.55, 0, 0, 30),
				Position = UDim2.new(0, 14, 0, 6),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = UIKit.TitleFont,
			})
			local theirs = rebirthsOf(other)
			UIKit.label(row, "Rebirth " .. theirs, {
				Size = UDim2.new(0.55, 0, 0, 20),
				Position = UDim2.new(0, 14, 0, 40),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(205, 150, 255),
			})
			local allowed = math.abs(theirs - myRebirths) <= GameConfig.TRADE.MaxRebirthDifference
			local button = UIKit.button(row, allowed and "ÉCHANGER" or "TROP D'ÉCART", allowed and T.Teal or T.Gray, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 180, 0, 46),
			})
			if allowed then
				button.MouseButton1Click:Connect(function()
					Remotes.TradeRequest:FireServer(other)
				end)
			end
		end
	end
	if count == 0 then
		UIKit.label(playerList, "Personne d'autre sur le serveur", {Size = UDim2.new(1, 0, 0, 40), Font = UIKit.TitleFont})
	end
end
list.onOpen = renderPlayers

-- ============================================================
-- DEMANDE RECUE
-- ============================================================
local function showRequest(from)
	local popup = Instance.new("Frame")
	popup.AnchorPoint = Vector2.new(1, 1)
	popup.Position = UDim2.new(1, -16, 1, -120)
	popup.Size = UDim2.new(0, 340, 0, 130)
	popup.BackgroundColor3 = Color3.new(1, 1, 1)
	popup.ZIndex = 35
	popup.Parent = UIKit.ScreenGui
	UIKit.corner(popup, 16)
	UIKit.outline(popup, 3.5)
	UIKit.gradient(popup, T.Teal, T.Teal:Lerp(Color3.new(0, 0, 0), 0.5), 90)
	UIKit.label(popup, from.DisplayName .. " veut échanger !", {
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.new(0, 10, 0, 10),
		Font = UIKit.TitleFont,
	})
	local accept = UIKit.button(popup, "OUI", T.Green, {Size = UDim2.new(0.44, 0, 0, 50), Position = UDim2.new(0.04, 0, 0, 62)})
	local decline = UIKit.button(popup, "NON", T.Red, {Size = UDim2.new(0.44, 0, 0, 50), Position = UDim2.new(0.52, 0, 0, 62)})
	local answered = false
	local function answer(value)
		if answered then return end
		answered = true
		Remotes.TradeRespond:FireServer(from, value)
		popup:Destroy()
	end
	accept.MouseButton1Click:Connect(function()
		answer(true)
	end)
	decline.MouseButton1Click:Connect(function()
		answer(false)
	end)
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
local session = UIKit.window("Échange", UDim2.new(0, 920, 0, 620), T.Teal)
local sc = session.content
local state = nil

local function column(x)
	local box = UIKit.box(sc, {Size = UDim2.new(0.49, 0, 0, 250), Position = UDim2.new(x, 0, 0, 0)})
	local title = UIKit.label(box, "", {Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 6), Font = UIKit.TitleFont})
	local grid = UIKit.scrollGrid(box, UDim2.new(0, 96, 0, 134), {Size = UDim2.new(1, -10, 1, -44), Position = UDim2.new(0, 5, 0, 40)})
	return title, grid
end
local myTitle, myGrid = column(0)
local theirTitle, theirGrid = column(0.51)

UIKit.label(sc, "Ton sac (clique pour ajouter / retirer)", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 0, 258),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = UIKit.TitleFont,
})
local invBox = UIKit.box(sc, {Size = UDim2.new(1, 0, 0, 160), Position = UDim2.new(0, 0, 0, 286)})
local invGrid = UIKit.scrollGrid(invBox, UDim2.new(0, 96, 0, 134), {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5)})

local statusLabel = UIKit.label(sc, "", {
	Size = UDim2.new(0.45, 0, 0, 32),
	Position = UDim2.new(0, 0, 1, -44),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = UIKit.TitleFont,
})
local readyButton = UIKit.button(sc, "PRÊT", T.Green, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -200, 1, 0), Size = UDim2.new(0, 190, 0, 52)})
local cancelButton = UIKit.button(sc, "ANNULER", T.Red, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.new(0, 190, 0, 52)})

readyButton.MouseButton1Click:Connect(function()
	Remotes.TradeAction:FireServer("ready")
end)
cancelButton.MouseButton1Click:Connect(function()
	Remotes.TradeAction:FireServer("cancel")
end)

local function miniCard(parent, name, mutation, order, onClick)
	local button = Instance.new("TextButton")
	button.Text = ""
	button.BackgroundTransparency = 1
	button.LayoutOrder = order
	button.AutoButtonColor = false
	button.Parent = parent
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

	theirTitle.Text = state.Partner .. (state.TheirReady and "  ✔" or "")
	myTitle.Text = "Toi" .. (state.MyReady and "  ✔" or "")

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
		statusLabel.Text = "Échange dans " .. state.Countdown .. "..."
		statusLabel.TextColor3 = T.Gold
	elseif state.MyReady then
		statusLabel.Text = "On attend " .. state.Partner
		statusLabel.TextColor3 = T.SubText
	else
		statusLabel.Text = "Ajoute des cartes"
		statusLabel.TextColor3 = T.SubText
	end
	readyButton.Text = state.MyReady and "PAS PRÊT" or "PRÊT"
	UIKit.setButtonColor(readyButton, state.MyReady and T.Gray or T.Green)
end

-- Fermer la fenêtre = annuler l'échange
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
			if not session.isOpen() then
				session.open()
			end
			render()
		elseif kind == "closed" then
			state = nil
			session.close()
			Hud.notify("Échange annulé : " .. (payload.Reason or ""), "error")
		elseif kind == "done" then
			state = nil
			session.close()
			Hud.notify("Échange réussi avec " .. payload.Partner .. " !", "success")
		end
	end)
end

return Trade
