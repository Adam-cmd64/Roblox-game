-- ModuleScript : échanges de brainrots entre joueurs.
--
-- Règles :
--   - on ne peut échanger qu'avec un joueur qui a au maximum 3 rebirths d'écart (GameConfig.TRADE)
--   - seules les cartes de l'inventaire (pas celles posées dans la base) peuvent être échangées
--   - quand les deux joueurs sont "Prêt", un compte à rebours démarre ; si quelqu'un modifie son offre, tout s'annule

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CONFIG = GameConfig.TRADE

local TradeManager = {}

local deps
local sessions = {} -- sessions[player] = session (la même table pour les 2 joueurs)
local requests = {} -- requests[target] = {from = player, time = os.clock()}

local function rebirthsOf(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats.Rebirths.Value or 0
end

function TradeManager.canTrade(a, b)
	return math.abs(rebirthsOf(a) - rebirthsOf(b)) <= CONFIG.MaxRebirthDifference
end

local function other(session, player)
	return session.a == player and session.b or session.a
end

local function describeOffer(player, ids)
	local list = {}
	for _, itemId in ipairs(ids) do
		local item = deps.PlayerData.findItem(player, itemId)
		if item then
			table.insert(list, {Id = itemId, Name = item.Value, Mutation = item:GetAttribute("Mutation")})
		end
	end
	return list
end

local function sendState(session)
	for _, player in ipairs({session.a, session.b}) do
		local partner = other(session, player)
		deps.Remotes.TradeEvent:FireClient(player, "state", {
			Partner = partner.DisplayName,
			Mine = describeOffer(player, session.offers[player]),
			Theirs = describeOffer(partner, session.offers[partner]),
			MyReady = session.ready[player] == true,
			TheirReady = session.ready[partner] == true,
			Countdown = session.countdownEnd and math.max(0, math.ceil(session.countdownEnd - os.clock())) or nil,
		})
	end
end

local function close(session, reason)
	for _, player in ipairs({session.a, session.b}) do
		if sessions[player] == session then
			sessions[player] = nil
		end
		if player.Parent then
			deps.Remotes.TradeEvent:FireClient(player, "closed", {Reason = reason})
		end
	end
end

local function resetReady(session)
	session.ready = {}
	session.countdownEnd = nil
	session.token += 1
end

-- Vérifie qu'une carte peut être échangée (elle existe, elle est dans l'inventaire)
local function isTradable(player, itemId)
	local item = deps.PlayerData.findItem(player, itemId)
	return item ~= nil and item:GetAttribute("Slot") == 0
end

local function execute(session)
	local a, b = session.a, session.b
	if not a.Parent or not b.Parent then
		close(session, "Un joueur a quitté")
		return
	end
	if not TradeManager.canTrade(a, b) then
		close(session, "Trop d'écart de rebirths")
		return
	end
	for _, player in ipairs({a, b}) do
		for _, itemId in ipairs(session.offers[player]) do
			if not isTradable(player, itemId) then
				close(session, "Une carte n'est plus disponible")
				return
			end
		end
	end

	-- Échange : on déplace les cartes d'un joueur à l'autre
	local moves = {}
	for _, player in ipairs({a, b}) do
		local partner = other(session, player)
		for _, itemId in ipairs(session.offers[player]) do
			table.insert(moves, {item = deps.PlayerData.findItem(player, itemId), from = player, to = partner})
		end
	end
	for _, move in ipairs(moves) do
		deps.PlayerData.destroyHeldTool(move.from, move.item.Name)
		move.item:SetAttribute("Slot", 0)
		move.item.Parent = move.to.Brainrots
	end

	for _, player in ipairs({a, b}) do
		sessions[player] = nil
		deps.Remotes.TradeEvent:FireClient(player, "done", {Partner = other(session, player).DisplayName})
		task.spawn(deps.PlayerData.save, player)
	end
end

function TradeManager.init(dependencies)
	deps = dependencies
	local Remotes = deps.Remotes

	-- Demande d'échange
	Remotes.TradeRequest.OnServerEvent:Connect(function(player, target)
		if typeof(target) ~= "Instance" or not target:IsA("Player") or target == player or not target.Parent then return end
		if sessions[player] or sessions[target] then
			Remotes.notify(player, "Ce joueur est déjà en échange", "error")
			return
		end
		if not TradeManager.canTrade(player, target) then
			Remotes.notify(player, "🔒 Trop d'écart de rebirths (max " .. CONFIG.MaxRebirthDifference .. ")", "error")
			return
		end
		requests[target] = {from = player, time = os.clock()}
		Remotes.TradeEvent:FireClient(target, "request", {From = player})
		Remotes.notify(player, "📨 Demande d'échange envoyée à " .. target.DisplayName, "info")
	end)

	-- Réponse à une demande
	Remotes.TradeRespond.OnServerEvent:Connect(function(player, from, accept)
		local request = requests[player]
		if not request or request.from ~= from or os.clock() - request.time > 30 then return end
		requests[player] = nil
		if not accept then
			if from.Parent then
				Remotes.notify(from, player.DisplayName .. " a refusé l'échange", "error")
			end
			return
		end
		if not from.Parent or sessions[player] or sessions[from] or not TradeManager.canTrade(player, from) then return end

		local session = {a = from, b = player, offers = {[from] = {}, [player] = {}}, ready = {}, token = 0}
		sessions[from] = session
		sessions[player] = session
		Remotes.TradeEvent:FireClient(from, "open", {Partner = player.DisplayName})
		Remotes.TradeEvent:FireClient(player, "open", {Partner = from.DisplayName})
		sendState(session)
	end)

	-- Actions pendant l'échange
	Remotes.TradeAction.OnServerEvent:Connect(function(player, action, itemId)
		local session = sessions[player]
		if not session then return end

		if action == "cancel" then
			close(session, player.DisplayName .. " a annulé l'échange")
			return
		end

		local offer = session.offers[player]
		if action == "add" then
			if #offer >= CONFIG.MaxItems or table.find(offer, itemId) or not isTradable(player, itemId) then return end
			table.insert(offer, itemId)
			resetReady(session)
		elseif action == "remove" then
			local index = table.find(offer, itemId)
			if not index then return end
			table.remove(offer, index)
			resetReady(session)
		elseif action == "ready" then
			session.ready[player] = not session.ready[player]
			local partner = other(session, player)
			if session.ready[player] and session.ready[partner] then
				-- Les deux sont prêts : compte à rebours
				session.token += 1
				local token = session.token
				session.countdownEnd = os.clock() + CONFIG.CountdownSeconds
				task.spawn(function()
					for _ = 1, CONFIG.CountdownSeconds do
						task.wait(1)
						if session.token ~= token then return end
						sendState(session)
					end
					if session.token == token and sessions[player] == session then
						execute(session)
					end
				end)
			else
				session.countdownEnd = nil
				session.token += 1
			end
		else
			return
		end
		sendState(session)
	end)

	Players.PlayerRemoving:Connect(function(player)
		requests[player] = nil
		local session = sessions[player]
		if session then
			close(session, player.DisplayName .. " a quitté le jeu")
		end
	end)
end

return TradeManager
