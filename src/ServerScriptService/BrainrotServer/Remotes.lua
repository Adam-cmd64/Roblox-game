-- ModuleScript : crée tous les RemoteEvents du jeu (rien à faire à la main dans Studio).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = {
	-- client -> serveur
	"BuyPickaxe", -- (tier) acheter une pioche à la boutique
	"Rebirth", -- () faire un rebirth
	"MineBlock", -- (block) frapper un bloc
	"Teleport", -- ("base" | "mine" | "shop")
	"EquipBrainrot", -- (itemId) prendre une carte de l'inventaire en main
	"BuyBooster", -- (boosterId) acheter un booster Robux
	"TradeRequest", -- (player) demander un échange
	"TradeRespond", -- (player, accept) répondre à une demande
	"TradeAction", -- (action, itemId) ajouter / retirer / prêt / annuler
	-- serveur -> client
	"CardFound", -- (cardName, mutation) carte trouvée en minant
	"BlockBroken", -- (position, cash) bloc cassé
	"Notify", -- (text, kind) message à l'écran
	"OpenShop", -- () ouvrir la boutique de pioches
	"BoosterOpened", -- (boosterId, cards) ouverture d'un booster
	"Collected", -- (amount, position) argent collecté dans la base
	"TradeEvent", -- (kind, payload) mises à jour de l'échange
}

local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
end

local Remotes = {}
for _, name in ipairs(NAMES) do
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	Remotes[name] = remote
end

function Remotes.notify(player, text, kind)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

return Remotes
