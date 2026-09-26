-- ModuleScript : crée tous les RemoteEvents du jeu (rien à faire à la main dans Studio).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = {
	-- client -> serveur
	"BuyPickaxe", -- (tier) acheter une pioche à la boutique
	"Rebirth", -- () faire un rebirth
	"MineBlock", -- (block) frapper un bloc
	"Teleport", -- ("base" | "mine" | "shop" | "wheel")
	"EquipBrainrot", -- (itemId) prendre une carte de l'inventaire en main
	"BuyBooster", -- (boosterId) acheter un booster Robux
	"TradeRequest", -- (player) demander un échange
	"TradeRespond", -- (player, accept) répondre à une demande
	"TradeAction", -- (action, itemId) ajouter / retirer / prêt / annuler
	"SellBrainrot", -- (itemId) vendre une carte du sac
	"SellAll", -- (rarity) vendre toutes les cartes du sac de cette rareté
	"BuyBat", -- (tier) acheter une batte à la boutique
	"BatSwing", -- () coup de batte
	"SpinWheel", -- () tourner la roue de la fortune (il faut être à côté)
	"BuyProduct", -- (productKey) acheter un produit Robux (potion, tours de roue)
	-- serveur -> client
	"CardFound", -- (cardName, mutation) carte trouvée en minant
	"BlockBroken", -- (position, cash) bloc cassé
	"Notify", -- (text, kind) message à l'écran
	"OpenShop", -- () ouvrir la boutique : les pioches (touche E)
	"BoosterOpened", -- (boosterId, cards) ouverture d'un booster
	"Collected", -- (amount, position) argent collecté dans la base
	"TradeEvent", -- (kind, payload) mises à jour de l'échange
	"OpenBatShop", -- () ouvrir la boutique : les battes (touche F)
	"OpenWheel", -- () ouvrir la fenêtre de la roue (acheter des tours, touche F)
	"WheelResult", -- (prizeIndex, details) résultat de la roue
	"Effect", -- (kind, payload) effets visuels / sons pour tout le monde
	"Stunned", -- (direction) tu t'es fait frapper
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
