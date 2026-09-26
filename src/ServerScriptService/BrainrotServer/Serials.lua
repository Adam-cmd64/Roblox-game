-- ModuleScript : le numéro de tirage de chaque carte.
-- #1 = la toute première carte de ce brainrot trouvée dans le jeu (tous serveurs confondus), #2 la suivante, etc.
-- Le compteur est gardé dans un DataStore (une clé par brainrot).
-- Sans accès au DataStore (Studio sans "API Services"), on compte seulement sur ce serveur.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Serials = {}

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

-- Donne le prochain numéro pour ce brainrot (attend la réponse du DataStore, quelques dixièmes de seconde)
function Serials.next(cardName)
	if store then
		local ok, value = pcall(function()
			return store:UpdateAsync(cardName, function(old)
				return (tonumber(old) or 0) + 1
			end)
		end)
		local number = ok and tonumber(value) or nil
		if number then
			localCounters[cardName] = math.max(localCounters[cardName] or 0, number)
			return number
		end
	end
	localCounters[cardName] = (localCounters[cardName] or 0) + 1
	return localCounters[cardName]
end

return Serials
