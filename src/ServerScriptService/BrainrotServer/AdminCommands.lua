-- ModuleScript : commandes admin dans le chat (pratique pour tester et pour les "admin abuse").
--
--   /give <nom du brainrot> [mutation]   ex : /give sahur lave   ou   /give graipuss arc-en-ciel
--   /cash <montant>                      ex : /cash 1000000
--   /rebirths <nombre>
--   /pickaxe <niveau 1-6>
--   /mutation <mutation>                 donne cette mutation à la carte que tu tiens en main
--
-- Qui est admin : les UserId dans GameConfig.ADMINS, et tout le monde dans Roblox Studio.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local AdminCommands = {}

local deps

local function isAdmin(player)
	return RunService:IsStudio() or table.find(GameConfig.ADMINS, player.UserId) ~= nil
end

local function findMutation(text)
	text = string.lower(text or "")
	for _, name in ipairs(GameConfig.MUTATION_ORDER) do
		if string.lower(name) == text then
			return name
		end
	end
	return nil
end

local function findCard(query)
	query = string.lower(query)
	for _, card in ipairs(GameConfig.CARDS) do
		if string.find(string.lower(card.Name), query, 1, true) then
			return card
		end
	end
	return nil
end

local function run(player, message)
	local words = string.split(message, " ")
	local command = string.lower(table.remove(words, 1) or "")
	local notify = function(text)
		deps.Remotes.notify(player, text, "info")
	end

	if command == "/give" then
		local mutation = findMutation(words[#words])
		if mutation then
			table.remove(words)
		end
		local card = findCard(table.concat(words, " "))
		if not card then
			notify("Brainrot introuvable")
			return
		end
		deps.PlayerData.addItem(player, card.Name, mutation or "Normal", 0)
		notify("🎁 " .. card.Name .. (mutation and (" [" .. mutation .. "]") or "") .. " ajouté à ton inventaire")
	elseif command == "/cash" then
		player.leaderstats.Cash.Value += math.floor(tonumber(words[1]) or 0)
		notify("💰 Cash ajouté")
	elseif command == "/rebirths" then
		player.leaderstats.Rebirths.Value = math.max(0, math.floor(tonumber(words[1]) or 0))
		deps.BaseManager.refresh(player)
		notify("🔁 Rebirths modifiés")
	elseif command == "/pickaxe" then
		player.PickaxeTier.Value = math.clamp(math.floor(tonumber(words[1]) or 1), 1, #GameConfig.PICKAXES)
		deps.givePickaxe(player)
		notify("⛏️ Pioche changée")
	elseif command == "/mutation" then
		local mutation = findMutation(words[1])
		local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
		local item = tool and deps.PlayerData.findItem(player, tool:GetAttribute("ItemId"))
		if not mutation or not item then
			notify("Tiens une carte en main et écris /mutation <nom>")
			return
		end
		item:SetAttribute("Mutation", mutation)
		deps.equipCard(player, item) -- on redonne la carte avec son nouveau look
		notify("✨ Mutation " .. mutation .. " appliquée !")
	end
end

local COMMANDS = {"give", "cash", "rebirths", "pickaxe", "mutation"}

function AdminCommands.init(dependencies)
	deps = dependencies

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		-- Nouveau chat Roblox : on déclare de vraies commandes
		local parent = TextChatService:FindFirstChild("TextChatCommands") or TextChatService
		for _, name in ipairs(COMMANDS) do
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
