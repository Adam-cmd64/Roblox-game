-- ModuleScript : commandes ADMIN dans le chat (pour tester, et pour les "admin abuse").
-- Tape /aide dans le chat pour voir la liste dans le jeu.
--
-- Pour viser un autre joueur, mets @pseudo juste après la commande (le début du pseudo suffit) :
--   /vip @Bob            /give @Bob sahur galaxie        /cash @all 1m
--   Le @ est facultatif : "/vip Bob" marche aussi. @all (ou @tous) = tout le serveur, @moi = toi.
--   Sans pseudo, la commande est pour toi.
-- Les montants acceptent k, m, b, t (1k = 1 000, 1m = 1 000 000, 1b = 1 milliard, 1t = 1 000 milliards).
--
-- Qui est admin : les UserId dans GameConfig.ADMINS, tout le monde dans Roblox Studio,
-- et ceux à qui un admin a donné /admin (jusqu'à la fin du serveur).

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local AdminCommands = {}

local deps
local sessionAdmins = {} -- sessionAdmins[userId] = true : admins temporaires (/admin)

local function isOwnerAdmin(player)
	return RunService:IsStudio() or table.find(GameConfig.ADMINS, player.UserId) ~= nil
end

local function isAdmin(player)
	return isOwnerAdmin(player) or sessionAdmins[player.UserId] == true
end

-- La liste affichée par /aide : {commande, explication}
local HELP = {
	{"/aide", "affiche cette liste"},
	{"/all", "TOUT : argent, rebirths max, meilleurs outils, tapis, VIP, toutes les cartes"},
	{"/give [@joueur] <brainrot> [mutation] [nombre]", "donne une carte (ex : /give @Bob sahur galaxie 3)"},
	{"/cash [@joueur] <montant>", "ajoute de l'argent (ex : /cash 10m)"},
	{"/setcash [@joueur] <montant>", "met l'argent à ce montant"},
	{"/rebirths [@joueur] <nombre>", "change les rebirths (0 = les enlever)"},
	{"/pickaxe [@joueur] <1-" .. #GameConfig.PICKAXES .. ">", "change la pioche"},
	{"/pioche [@joueur]", "✨ PIOCHE DIVINE : casse tout en 1 coup (même les futures couches)"},
	{"/unpioche [@joueur]", "enlève la Pioche Divine (retour à la pioche normale)"},
	{"/bat [@joueur] <1-" .. #GameConfig.BATS .. ">", "change la batte"},
	{"/grapple [@joueur] <0-" .. #GameConfig.GRAPPLES .. ">", "change le grappin (0 = aucun)"},
	{"/mutation [@joueur] <mutation>", "met une mutation sur la carte tenue en main"},
	{"/mineral [@joueur] <argent|or|emeraude|diamant|netherite> [nombre]", "donne des minerais"},
	{"/spins [@joueur] <nombre>", "ajoute des tours de roue"},
	{"/potion [@joueur] <minutes>", "potion Chance x2"},
	{"/vip [@joueur]", "donne le Pack VIP (tag, chat vert, tapis, x2, minerais)"},
	{"/unvip [@joueur]", "enlève le VIP"},
	{"/promo [@joueur] [bienvenue]", "affiche tout de suite un pop-up d'offre (ou l'écran de bienvenue)"},
	{"/carpet [@joueur]", "donne le tapis volant"},
	{"/x2 [@joueur]", "donne l'argent x2"},
	{"/autocollect [@joueur]", "donne la collecte auto (l'argent de la base arrive tout seul)"},
	{"/dex [@joueur]", "débloque tout l'Index (toutes les cartes et mutations)"},
	{"/daily [@joueur]", "récompense quotidienne disponible tout de suite"},
	{"/starter [@joueur]", "le cadeau de départ peut être repris"},
	{"/speed [@joueur] <vitesse>", "vitesse de marche (16 = normal)"},
	{"/tp @joueur", "te téléporte sur ce joueur"},
	{"/bring @joueur", "téléporte ce joueur sur toi"},
	{"/lock [@joueur]", "verrouille la base (lasers)"},
	{"/unlock [@joueur]", "ouvre la base (coupe les lasers)"},
	{"/resetmine", "régénère la mine maintenant"},
	{"/event <meteore|lune|or|orage|stop> [secondes]", "lance un ÉVÉNEMENT DE SERVEUR tout de suite (ou l'arrête)"},
	{"/abuse [secondes]", "👑 ADMIN ABUSE : chance x5, argent x3, météores et toutes les mutations d'événement (5 min par défaut)"},
	{"/announce <message>", "message pour tout le serveur"},
	{"/kick @joueur [raison]", "expulse un joueur"},
	{"/admin @joueur", "donne les commandes admin à ce joueur (jusqu'à la fin du serveur)"},
	{"/unadmin @joueur", "enlève les commandes admin"},
}
AdminCommands.HELP = HELP

-- ====== OUTILS ======
local function findMutation(text)
	text = string.lower(text or "")
	for _, name in ipairs(GameConfig.MUTATION_ORDER) do
		if string.lower(name) == text or string.lower(GameConfig.upper(name)) == text then
			return name
		end
	end
	return nil
end

local function findMineral(text)
	text = string.lower(text or ""):gsub("é", "e"):gsub("É", "e")
	for _, mineral in ipairs(GameConfig.MINERALS) do
		if string.lower(mineral.Id) == text then
			return mineral
		end
	end
	return nil
end

local function findCard(query)
	query = string.lower(query)
	if query == "" then return nil end
	for _, card in ipairs(GameConfig.CARDS) do
		if string.lower(card.Name) == query then
			return card
		end
	end
	for _, card in ipairs(GameConfig.CARDS) do
		if string.find(string.lower(card.Name), query, 1, true) then
			return card
		end
	end
	return nil
end

-- "10m" -> 10 000 000, "2.5k" -> 2500, "1e12" -> 1e12
local SUFFIXES = {k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15}
local function parseAmount(text)
	text = string.lower(text or "")
	local number, suffix = string.match(text, "^([%d%.e%+]+)(%a*)$")
	local value = tonumber(number)
	if not value then return nil end
	if suffix ~= "" then
		if not SUFFIXES[suffix] then return nil end
		value *= SUFFIXES[suffix]
	end
	return math.floor(math.min(value, 9e15))
end

-- "@bob" -> {Bob}, "@all" -> tout le monde, "@moi" -> toi
local function findTargets(token, caller)
	local name = string.lower(string.sub(token, 2))
	if name == "all" or name == "tous" then
		return Players:GetPlayers()
	elseif name == "moi" or name == "me" then
		return {caller}
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if string.lower(other.Name) == name or string.lower(other.DisplayName) == name then
			return {other}
		end
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(other.Name), 1, #name) == name or string.sub(string.lower(other.DisplayName), 1, #name) == name then
			return {other}
		end
	end
	return {}
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- ====== LES COMMANDES ======
-- Chaque commande reçoit : (joueur visé, mots restants, fonction pour répondre à l'admin, l'admin)
-- et renvoie le texte du cadeau à montrer au joueur visé (ou nil).
local handlers = {}

handlers.all = function(target)
	target.leaderstats.Cash.Value += 1e15
	target.leaderstats.Rebirths.Value = #GameConfig.REBIRTHS
	deps.BaseManager.refresh(target)
	target.PickaxeTier.Value = #GameConfig.PICKAXES
	deps.givePickaxe(target)
	target.BatTier.Value = #GameConfig.BATS
	deps.BatManager.giveBat(target)
	target.GrappleTier.Value = #GameConfig.GRAPPLES
	deps.GrappleManager.giveGrapple(target)
	target:SetAttribute("FlyingCarpet", true)
	target:SetAttribute("VIP", true)
	target.Spins.Value += 50
	deps.PlayerData.addLuckMinutes(target, 60)
	-- une carte de chaque (numéro 0 = pas de #, pour ne pas voler les #1 des vrais joueurs ni spammer le chat)
	local owned = {}
	for _, item in ipairs(deps.PlayerData.getItems(target)) do
		owned[item.Value] = true
	end
	for _, card in ipairs(GameConfig.CARDS) do
		if not owned[card.Name] then
			deps.PlayerData.addItem(target, card.Name, "Normal", 0, 0)
		end
	end
	return "👑 TOUT débloqué : argent, rebirths max, meilleurs outils, tapis volant, VIP et toutes les cartes !"
end

handlers.give = function(target, words, reply)
	local count = 1
	if #words > 1 and tonumber(words[#words]) then
		count = math.clamp(math.floor(tonumber(table.remove(words)) :: number), 1, 50)
	end
	local mutation = findMutation(words[#words])
	if mutation then
		table.remove(words)
	end
	local card = findCard(table.concat(words, " "))
	if not card then
		reply("Brainrot introuvable")
		return nil
	end
	for _ = 1, count do
		deps.PlayerData.addItem(target, card.Name, mutation or "Normal", 0)
	end
	return "🎁 " .. (count > 1 and (count .. " x ") or "") .. card.Name .. (mutation and (" [" .. mutation .. "]") or "") .. " !"
end

handlers.cash = function(target, words, reply)
	local amount = parseAmount(words[1])
	if not amount then
		reply("Écris un montant, ex : /cash 10m")
		return nil
	end
	target.leaderstats.Cash.Value += amount
	return "💰 +$" .. GameConfig.format(amount)
end

handlers.setcash = function(target, words, reply)
	local amount = parseAmount(words[1])
	if not amount then
		reply("Écris un montant, ex : /setcash 0")
		return nil
	end
	target.leaderstats.Cash.Value = math.max(0, amount)
	return "💰 Ton argent : $" .. GameConfig.format(amount)
end

handlers.rebirths = function(target, words)
	target.leaderstats.Rebirths.Value = math.clamp(math.floor(tonumber(words[1]) or 0), 0, 999)
	deps.BaseManager.refresh(target)
	return "🔁 Rebirths : " .. target.leaderstats.Rebirths.Value
end

handlers.pickaxe = function(target, words)
	target.PickaxeTier.Value = math.clamp(math.floor(tonumber(words[1]) or 1), 1, #GameConfig.PICKAXES)
	deps.givePickaxe(target)
	return "⛏️ " .. GameConfig.PICKAXES[target.PickaxeTier.Value].Name
end

handlers.pioche = function(target)
	target:SetAttribute("DivinePickaxe", true)
	deps.givePickaxe(target)
	task.spawn(deps.PlayerData.save, target)
	return "✨ " .. GameConfig.DIVINE_PICKAXE.Name .. " : tout casse en 1 coup !"
end

handlers.unpioche = function(target)
	target:SetAttribute("DivinePickaxe", nil)
	deps.givePickaxe(target)
	task.spawn(deps.PlayerData.save, target)
	return "⛏️ " .. GameConfig.getPlayerPickaxe(target).Name
end

handlers.bat = function(target, words)
	target.BatTier.Value = math.clamp(math.floor(tonumber(words[1]) or 1), 1, #GameConfig.BATS)
	deps.BatManager.giveBat(target)
	return "🏏 " .. GameConfig.BATS[target.BatTier.Value].Name
end

handlers.grapple = function(target, words)
	target.GrappleTier.Value = math.clamp(math.floor(tonumber(words[1]) or 1), 0, #GameConfig.GRAPPLES)
	deps.GrappleManager.giveGrapple(target)
	local data = GameConfig.GRAPPLES[target.GrappleTier.Value]
	return data and ("🪝 " .. data.Name) or nil
end

handlers.mutation = function(target, words, reply)
	local mutation = findMutation(words[1])
	local tool = target.Character and target.Character:FindFirstChildOfClass("Tool")
	local item = tool and deps.PlayerData.findItem(target, tool:GetAttribute("ItemId"))
	if not mutation or not item then
		reply("Il faut tenir une carte en main, et écrire /mutation <nom>")
		return nil
	end
	item:SetAttribute("Mutation", mutation)
	deps.equipCard(target, item) -- on redonne la carte avec son nouveau look
	return "✨ Mutation " .. mutation .. " !"
end

handlers.mineral = function(target, words, reply)
	local mineral = findMineral(words[1])
	if not mineral then
		reply("Minerais : argent, or, emeraude, diamant, netherite")
		return nil
	end
	local count = math.clamp(math.floor(tonumber(words[2]) or 1), 1, 1000)
	deps.PlayerData.addMineral(target, mineral.Id, count)
	return "◆ +" .. count .. " minerai(s) " .. mineral.Name
end

handlers.spins = function(target, words)
	local count = math.floor(tonumber(words[1]) or 1)
	target.Spins.Value = math.max(0, target.Spins.Value + count)
	return "🎡 +" .. count .. " tour(s) de roue"
end

handlers.potion = function(target, words)
	local minutes = tonumber(words[1]) or 15
	deps.PlayerData.addLuckMinutes(target, minutes)
	return "🍀 Potion Chance x2 : " .. minutes .. " min"
end

handlers.vip = function(target)
	target:SetAttribute("VIP", true)
	return "👑 Tu es VIP !"
end

handlers.promo = function(target, words)
	local first = words[1] and string.lower(words[1]):sub(1, 3)
	local welcome = first == "bie" or first == "wel"
	deps.Remotes.ShowPromo:FireClient(target, welcome and "welcome" or "offer")
	return nil
end

handlers.unvip = function(target)
	target:SetAttribute("VIP", false)
	local head = target.Character and target.Character:FindFirstChild("Head")
	local tag = head and head:FindFirstChild("VIPTag")
	if tag then
		tag:Destroy()
	end
	return nil
end

handlers.carpet = function(target)
	target:SetAttribute("FlyingCarpet", true)
	return "🧞 Tapis volant !"
end

handlers.x2 = function(target)
	target:SetAttribute("DoubleCash", true)
	return "💰 Argent x2 pour toujours !"
end

handlers.autocollect = function(target)
	target:SetAttribute("AutoCollect", true)
	return "🤖 Collecte auto : l'argent de ta base arrive tout seul !"
end

handlers.dex = function(target)
	for _, card in ipairs(GameConfig.CARDS) do
		deps.PlayerData.discover(target, card.Name)
		for _, mutation in ipairs(GameConfig.MUTATION_ORDER) do
			deps.PlayerData.discoverMutation(target, card.Name, mutation)
		end
	end
	deps.BaseManager.refresh(target)
	return "📖 Tout l'Index est débloqué !"
end

handlers.daily = function(target)
	target:SetAttribute("DailyLast", os.time() - GameConfig.DAILY.Cooldown - 1)
	return "🎁 Ta récompense quotidienne est prête !"
end

handlers.starter = function(target)
	target:SetAttribute("StarterClaimed", nil)
	return "🎁 Tu peux reprendre le cadeau de départ"
end

handlers.speed = function(target, words)
	local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = math.clamp(tonumber(words[1]) or 16, 1, 250)
	end
	return nil
end

handlers.tp = function(target, _, reply, caller)
	local from, to = getRoot(caller), getRoot(target)
	if not from or not to or target == caller then
		reply("Écris /tp @joueur")
		return nil
	end
	caller.Character:PivotTo(to.CFrame * CFrame.new(0, 0, 4))
	return nil
end

handlers.bring = function(target, _, reply, caller)
	local here, there = getRoot(caller), getRoot(target)
	if not here or not there or target == caller then
		reply("Écris /bring @joueur")
		return nil
	end
	target.Character:PivotTo(here.CFrame * CFrame.new(0, 0, -4))
	return nil
end

handlers.lock = function(target, _, reply)
	local plot = deps.BaseManager.getPlot(target)
	if not plot then
		reply(target.DisplayName .. " n'a pas de base")
		return nil
	end
	deps.BaseManager.lock(plot, target)
	return nil
end

handlers.unlock = function(target, _, reply)
	local plot = deps.BaseManager.getPlot(target)
	if not plot then
		reply(target.DisplayName .. " n'a pas de base")
		return nil
	end
	plot.model:SetAttribute("LockedUntil", 0)
	deps.BaseManager.updateLockDisplay(plot)
	return nil
end

handlers.kick = function(target, words, reply, caller)
	if target == caller or isOwnerAdmin(target) then
		reply("Impossible d'expulser ce joueur")
		return nil
	end
	local reason = table.concat(words, " ")
	target:Kick(reason ~= "" and reason or "Expulsé par un admin")
	return nil
end

handlers.admin = function(target, _, reply, caller)
	if not isOwnerAdmin(caller) then
		reply("Seul le créateur du jeu peut donner les commandes admin")
		return nil
	end
	sessionAdmins[target.UserId] = true
	return "🛡️ Tu as les commandes admin ! Tape /aide pour la liste"
end

handlers.unadmin = function(target, _, reply, caller)
	if not isOwnerAdmin(caller) then
		reply("Seul le créateur du jeu peut enlever les commandes admin")
		return nil
	end
	sessionAdmins[target.UserId] = nil
	return nil
end

-- Commandes qui ne visent personne
local globals = {}

globals.aide = function(caller)
	deps.Remotes.AdminHelp:FireClient(caller, HELP)
end
globals.commandes = globals.aide -- (pas /help : Roblox l'utilise déjà)

globals.resetmine = function(caller)
	deps.MineManager.reset()
	deps.Remotes.notify(caller, "⛏️ La mine est régénérée", "success")
end

globals.event = function(caller, words)
	local name = string.lower(words[1] or "")
	if name == "stop" then
		deps.EventManager.stop()
		deps.Remotes.notify(caller, "Événement arrêté", "success")
		return
	end
	local event = name == "" and GameConfig.EVENTS.List[math.random(1, 4)] or GameConfig.findEvent(name)
	if not event then
		deps.Remotes.notify(caller, "Événements : meteore, lune, or, orage, abuse (ou stop)", "error")
		return
	end
	deps.EventManager.start(event.Id, tonumber(words[2]))
end

globals.abuse = function(caller, words)
	deps.EventManager.start("AdminAbuse", tonumber(words[1]) or 300)
end

globals.announce = function(caller, words)
	local text = table.concat(words, " ")
	if text == "" then return end
	for _, other in ipairs(Players:GetPlayers()) do
		deps.Remotes.notify(other, "📢 " .. caller.DisplayName .. " : " .. text, "warning")
	end
end

-- Sans @ : le 1er mot est-il un pseudo ? (le nom complet, ou au moins 3 lettres du début)
-- Pour /give, /mutation et /mineral, on vérifie aussi que ce mot n'est pas un brainrot / une mutation / un minerai.
local function looksLikePlayer(word, command, words)
	local lower = string.lower(word)
	local exact = false
	for _, other in ipairs(Players:GetPlayers()) do
		if string.lower(other.Name) == lower or string.lower(other.DisplayName) == lower then
			exact = true
		end
	end
	if not exact and #word < 3 then
		return false
	end
	if tonumber(word) or parseAmount(word) then
		return false -- un nombre / un montant, pas un pseudo
	end
	if command == "give" and not exact then
		-- "/give sahur" : si le mot est un brainrot, ce n'est pas un joueur
		if findCard(word) and not findCard(table.concat(words, " ", 2)) then
			return false
		end
	end
	if (command == "mutation" and findMutation(word)) or (command == "mineral" and findMineral(word)) then
		return exact
	end
	return true
end

-- Les commandes qui DOIVENT viser quelqu'un avec @
local NEEDS_TARGET = {tp = true, bring = true, kick = true, admin = true, unadmin = true}

local function run(player, message)
	local words = string.split(message, " ")
	for i = #words, 1, -1 do
		if words[i] == "" then
			table.remove(words, i)
		end
	end
	local command = string.lower(string.sub(table.remove(words, 1) or "", 2))
	local reply = function(text)
		deps.Remotes.notify(player, text, "info")
	end

	if globals[command] then
		globals[command](player, words)
		return
	end
	local handler = handlers[command]
	if not handler then return end

	local targets = {player}
	if words[1] and string.sub(words[1], 1, 1) == "@" then
		targets = findTargets(table.remove(words, 1) :: string, player)
		if #targets == 0 then
			reply("Joueur introuvable : " .. tostring(words[1] or ""))
			return
		end
	elseif words[1] and #findTargets("@" .. words[1], player) > 0 and looksLikePlayer(words[1], command, words) then
		-- sans @ aussi : "/vip Bob" ou "/give Bob sahur" visent Bob
		targets = findTargets("@" .. (table.remove(words, 1) :: string), player)
	elseif NEEDS_TARGET[command] then
		reply("Il faut viser un joueur : /" .. command .. " @pseudo")
		return
	end

	local done = 0
	for _, target in ipairs(targets) do
		if target.Parent and target:FindFirstChild("leaderstats") then
			local copy = table.clone(words)
			local ok, gift = pcall(handler, target, copy, reply, player)
			if not ok then
				warn("[Admin] /" .. command .. " : " .. tostring(gift))
			else
				done += 1
				if gift then
					if target ~= player then
						deps.Remotes.notify(target, "🎁 Cadeau d'un admin : " .. gift, "success")
					else
						deps.Remotes.notify(player, gift, "success")
					end
				end
			end
		end
	end
	if done > 0 and (#targets > 1 or targets[1] ~= player) then
		local names = #targets > 1 and (#targets .. " joueurs") or targets[1].DisplayName
		reply("✔ /" .. command .. " → " .. names)
	end
end

AdminCommands.run = run

-- tous les noms de commandes (pour le chat Roblox)
local function commandNames()
	local names = {}
	for name in pairs(handlers) do
		table.insert(names, name)
	end
	for name in pairs(globals) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function AdminCommands.init(dependencies)
	deps = dependencies

	Players.PlayerRemoving:Connect(function(player)
		sessionAdmins[player.UserId] = nil
	end)

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		-- Nouveau chat Roblox : on déclare de vraies commandes
		local parent = TextChatService:FindFirstChild("TextChatCommands") or TextChatService
		for _, name in ipairs(commandNames()) do
			local command = Instance.new("TextChatCommand")
			command.Name = "BrainrotAdmin_" .. name
			command.PrimaryAlias = "/" .. name
			command.Parent = parent
			command.Triggered:Connect(function(textSource, message)
				local player = Players:GetPlayerByUserId(textSource.UserId)
				if player and isAdmin(player) then
					run(player, message)
				end
			end)
		end
	else
		-- Ancien chat
		local function listen(player)
			player.Chatted:Connect(function(message)
				if string.sub(message, 1, 1) == "/" and isAdmin(player) then
					run(player, message)
				end
			end)
		end
		Players.PlayerAdded:Connect(listen)
		for _, player in ipairs(Players:GetPlayers()) do
			listen(player)
		end
	end
end

return AdminCommands
