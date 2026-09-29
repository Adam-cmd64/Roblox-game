-- ModuleScript : le numéro de tirage de chaque carte.
-- #1 = la toute première carte de ce brainrot trouvée dans le jeu (tous serveurs confondus), #2 la suivante, etc.
-- Le compteur est gardé dans un DataStore (une clé par brainrot).
-- Sans accès au DataStore (Studio sans "API Services"), on compte seulement sur ce serveur.
--
-- Roblox n'accepte qu'UNE écriture toutes les 6 secondes par clé : pour les cartes qu'on trouve
-- souvent (Communes, Rares...), le serveur RÉSERVE les numéros par paquets (ex : 25 d'un coup) et les
-- distribue lui-même. Les cartes rares (Légendaire et +) restent numérotées une par une (les #1 restent exacts).
-- Si plusieurs cartes du même brainrot arrivent en même temps, une seule demande part au DataStore.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Serials = {}

-- combien de numéros on réserve d'un coup, selon la rareté (1 = une demande par carte)
local BLOCK_BY_ORDER = {25, 15, 8, 4}

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.SERIAL_STORE_NAME)
	end)
	if ok then
		store = result
	end
end

local localCounters = {}
local reserved = {} -- reserved[carte] = {nextNumber, lastNumber} : numéros déjà réservés par ce serveur
local busy = {} -- busy[carte] = true pendant qu'une demande au DataStore est en cours

local function blockSize(cardName)
	local card = GameConfig.getCard(cardName)
	local rarity = card and GameConfig.RARITIES[card.Rarity]
	return rarity and BLOCK_BY_ORDER[rarity.Order] or 1
end

local function take(cardName)
	local block = reserved[cardName]
	if block and block[1] <= block[2] then
		local number = block[1]
		block[1] += 1
		localCounters[cardName] = math.max(localCounters[cardName] or 0, number)
		return number
	end
	return nil
end

-- Donne le prochain numéro pour ce brainrot (attend la réponse du DataStore, quelques dixièmes de seconde)
function Serials.next(cardName)
	local number = take(cardName)
	if number then
		return number
	end
	if store then
		-- une seule demande à la fois par brainrot : les autres attendent son résultat
		local waited = 0
		while busy[cardName] and waited < 10 do
			waited += task.wait(0.1)
		end
		number = take(cardName)
		if number then
			return number
		end
		busy[cardName] = true
		local size = blockSize(cardName)
		local ok, value = pcall(function()
			return store:UpdateAsync(cardName, function(old)
				return (tonumber(old) or 0) + size
			end)
		end)
		busy[cardName] = nil
		local last = ok and tonumber(value) or nil
		if last then
			reserved[cardName] = {last - size + 1, last}
			number = take(cardName)
			if number then
				return number
			end
		end
	end
	localCounters[cardName] = (localCounters[cardName] or 0) + 1
	return localCounters[cardName]
end

return Serials
