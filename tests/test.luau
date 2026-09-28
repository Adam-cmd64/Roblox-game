local mock = require("./mock")
local SOURCES = require("./sources")
mock.readFile = function(path)
	local s = SOURCES[path]
	assert(s, "fichier introuvable : " .. path)
	return s
end

-- On fait comme si les ID des images de cartes et du fichier de sons étaient collés dans GameConfig
-- (pour tester aussi ce code-là)
do
	local path = "src/ReplicatedStorage/GameConfig.lua"
	local source = SOURCES[path]
	source = (source:gsub('GameConfig.SOUND_FILE = "[^"]*"', 'GameConfig.SOUND_FILE = "1111"'))
	source = (source:gsub("ChestChance = 0%.003", "ChestChance = 0.3")) -- plus de coffres pour les tester
	source = (source:gsub("ChestsPerCycle = {55, 45}", "ChestsPerCycle = {0, 0, 0, 0, 0, 0, 100}"))
	source = (source:gsub('\t"[^"]*", %-%- ID de cartes1', '\t"2222", -- ID de cartes1'))
	source = (source:gsub('\t"[^"]*", %-%- ID de cartes2', '\t"rbxassetid://3333", -- ID de cartes2'))
	source = (source:gsub('\t"[^"]*", %-%- ID de cartes3', '\t"4444", -- ID de cartes3'))
	SOURCES[path] = source
end

local data = mock.data
local game = mock.game
local Enum = mock.Enum
local V3 = mock.Vector3.new

local failures = {}
local function check(cond, msg)
	if not cond then
		table.insert(failures, msg)
	end
end

local function new(className, name, parent)
	local inst = mock.rawNew(className, true)
	data[inst].Name = name
	if parent then inst.Parent = parent end
	return inst
end

local function module(parent, name, path)
	local m = new("ModuleScript", name, parent)
	mock.moduleFiles[m] = path
	return m
end

-- ====== Template Roblox par défaut ======
local workspace = mock.workspace
local baseplate = new("Part", "Baseplate", workspace)
new("SpawnLocation", "SpawnLocation", workspace)

-- ====== Arbre Rojo ======
local RS = mock.getService("ReplicatedStorage")
module(RS, "GameConfig", "src/ReplicatedStorage/GameConfig.lua")
module(RS, "CardRenderer", "src/ReplicatedStorage/CardRenderer.lua")

local SSS = mock.getService("ServerScriptService")
local serverScript = new("Script", "BrainrotServer", SSS)
for _, name in ipairs({"Remotes", "PlayerData", "Loot", "MineManager", "BaseManager", "ShopManager", "Monetization", "TradeManager", "WorldBuilder", "AdminCommands", "PickaxeBuilder", "BatManager", "WheelManager", "Serials", "CarpetManager", "GrappleManager", "LeaderboardManager", "DailyManager", "VipManager", "StarterChest"}) do
	module(serverScript, name, "src/ServerScriptService/BrainrotServer/" .. name .. ".lua")
end

local SP = mock.getService("StarterPlayer")
local SPS = new("StarterPlayerScripts", "StarterPlayerScripts", SP)
local clientScript = new("LocalScript", "BrainrotClient", SPS)
for _, name in ipairs({"UIKit", "Hud", "Panels", "Trade", "Mining", "World", "Sounds", "Effects", "Wheel", "Sky", "Carpet", "Hack", "Grapple", "Carry", "Daily", "Settings", "Vip", "Guide", "Gift", "Pointer"}) do
	module(clientScript, name, "src/StarterPlayer/StarterPlayerScripts/BrainrotClient/" .. name .. ".lua")
end

-- ====== 1. Démarrage du serveur ======
mock.runScript(serverScript, "src/ServerScriptService/BrainrotServer/init.server.lua", "server")
mock.runFor(1)
check(data[baseplate].destroyed, "la Baseplate aurait dû être supprimée")
check(workspace:FindFirstChild("Plots") ~= nil, "pas de dossier Plots")
check(workspace:FindFirstChild("Mine") ~= nil, "pas de Mine")
local blocks = workspace.Mine.Blocks
check(#blocks:GetChildren() == 32 * 32, "la mine devrait avoir 32x32 blocs en surface, a " .. #blocks:GetChildren())

-- L'ordre des cartes doit être EXACTEMENT celui des images (cartes1/2/3.png, de gauche à droite puis de haut en bas)
local IMAGE_ORDER = {
	"Cartonino Scatolino",
	"Sassolino Maculato",
	"Teierina Camminina",
	"Bottiglione Zuppone",
	"Riccio Paffutello",
	"Tung Tung Tung Sahur",
	"Topolino Occhialino",
	"Fragolone Cubone",
	"Squalo Cubetto",
	"Tazzina Fiammante",
	"Piccione Aviatore",
	"Gufo Pinetto",
	"Pesciolone Panciuto",
	"Bruno Scarpone",
	"Tralalero Tralala",
	"Cappuccino Assassino",
	"Zuccone Sneakerone",
	"Canguro Coccolino",
	"Orangutini Ananassini",
	"Leonelli Cactuselli",
	"Pandaccini Bananini",
	"Tartaruga Anguria",
	"Anguriello Furioso",
	"Blueberrinni Octopusini",
	"Spiderino Rossino",
	"Tigrrullini Watermellini",
	"Pot Hotspot",
	"La Vaca Saturno Saturnita",
	"Perochello Lemonchello",
	"Tigre Imperiale",
	"Tartarughina Fiorita",
	"La Idra Dorata",
	"Lucky Block",
	"Lucky Block Secret",
	"Lucky Block Arc-en-ciel",
}
local configCards = mock.moduleCache.server[RS.GameConfig].value.CARDS
check(#configCards == #IMAGE_ORDER, "il devrait y avoir " .. #IMAGE_ORDER .. " cartes")
for i, name in ipairs(IMAGE_ORDER) do
	check(configCards[i] and configCards[i].Name == name, "carte n°" .. i .. " : " .. tostring(configCards[i] and configCards[i].Name) .. " au lieu de " .. name .. " (pas dans l'ordre des images)")
end

-- ====== 2. Joueurs ======
local Players = mock.players
local function addPlayer(name, userId)
	local p = mock.rawNew("Player", true)
	data[p].Name = name
	data[p].userId = userId
	data[p].props.DisplayName = name
	new("Backpack", "Backpack", p)
	new("PlayerGui", "PlayerGui", p)
	new("PlayerScripts", "PlayerScripts", p)
	p.Parent = Players
	mock.getSignal(Players, "PlayerAdded"):Fire(p)
	return p
end

local function spawnCharacter(player)
	local model = new("Model", data[player].Name, nil)
	local root = new("Part", "HumanoidRootPart", model)
	root.Size = V3(2, 2, 1)
	root.CFrame = mock.CFrame.new(0, 5, 0)
	new("Humanoid", "Humanoid", model)
	local arm = new("Part", "RightUpperArm", model)
	local shoulder = new("Motor6D", "RightShoulder", arm)
	shoulder.C0 = mock.CFrame.new(1, 0.5, 0)
	data[player].props.Character = model
	model.Parent = workspace
	mock.getSignal(player, "CharacterAdded"):Fire(model)
	return model
end

local adam = addPlayer("Adam", 1)
mock.localPlayer = adam
local bob = addPlayer("Bob", 2)
mock.runFor(0.5)
local adamChar = spawnCharacter(adam)
local bobChar = spawnCharacter(bob)
mock.runFor(1)

check(adam:FindFirstChild("leaderstats") ~= nil, "leaderstats manquant")
check(adamChar:FindFirstChild("Pioche") ~= nil, "la pioche devrait être équipée")
local myPlot
for _, plot in ipairs(workspace.Plots:GetChildren()) do
	if plot:GetAttribute("OwnerId") == 1 then myPlot = plot end
end
check(myPlot ~= nil, "Adam n'a pas de base")

-- ====== 3. Démarrage du client ======
mock.runScript(clientScript, "src/StarterPlayer/StarterPlayerScripts/BrainrotClient/init.client.lua", "client")
mock.runFor(1)
local hud = adam.PlayerGui:FindFirstChild("BrainrotHUD")
check(hud ~= nil, "le HUD n'existe pas")

local runService = mock.getService("RunService")
local function frames(seconds)
	mock.runFor(seconds, function(dt)
		mock.context = "client"
		mock.getSignal(runService, "RenderStepped"):Fire(dt)
		mock.getSignal(runService, "Heartbeat"):Fire(dt)
		mock.context = "server"
	end)
end

local function click(button)
	mock.context = "client"
	mock.getSignal(button, "MouseButton1Click"):Fire()
	mock.context = "server"
	frames(0.3)
end

-- Boutons du menu
local menu = hud:FindFirstChild("Menu")
check(menu ~= nil, "menu introuvable")
local windowsOpened = 0
if menu then
	for _, button in ipairs(menu:GetChildren()) do
		if button:IsA("TextButton") then
			click(button)
			for _, child in ipairs(hud:GetChildren()) do
				if child:IsA("TextButton") and child.Visible then
					windowsOpened += 1
				end
			end
		end
	end
end
check(windowsOpened >= 5, "les boutons du menu devraient ouvrir des fenêtres (ouvertes : " .. windowsOpened .. ")")

-- ====== 4. Minage ======
adamChar:PivotTo(mock.CFrame.new(0, 3, 0))
mock.raycastHook = function(origin, direction, params)
	local rootPos = adamChar.HumanoidRootPart.Position
	local best, bestDist
	for _, block in ipairs(blocks:GetChildren()) do
		local dist = (block.Position - rootPos).Magnitude
		if not bestDist or dist < bestDist then
			best, bestDist = block, dist
		end
	end
	if best then return {Instance = best, Position = best.Position} end
	return nil
end
local cashBefore = adam.leaderstats.Cash.Value
local UIS = mock.getService("UserInputService")
mock.context = "client"
mock.getSignal(UIS, "InputBegan"):Fire({UserInputType = Enum.UserInputType.MouseButton1}, false)
mock.context = "server"
frames(20)
mock.context = "client"
mock.getSignal(UIS, "InputEnded"):Fire({UserInputType = Enum.UserInputType.MouseButton1})
mock.context = "server"
check(adam.leaderstats.Cash.Value > cashBefore, "le minage n'a rien rapporté (cash " .. adam.leaderstats.Cash.Value .. ")")
print("Cash après 20s de minage :", adam.leaderstats.Cash.Value)

-- ====== 5. Commandes admin + poser une carte ======
local function chat(player, message)
	local command
	for _, c in ipairs(mock.getService("TextChatService").TextChatCommands:GetChildren()) do
		if c.PrimaryAlias == "/" .. string.split(message, " ")[1]:sub(2) then command = c end
	end
	check(command ~= nil, "commande introuvable : " .. message)
	if command then
		mock.getSignal(command, "Triggered"):Fire({UserId = data[player].userId}, message)
	end
	frames(0.2)
end
chat(adam, "/give sahur")
chat(adam, "/give tralalero or")
chat(adam, "/give pandaccini arc-en-ciel")
chat(adam, "/give sahur")
-- numéros de tirage : le 1er Tung Tung Tung Sahur du jeu est le #1, le suivant le #2
local sahurSerials = {}
for _, item in ipairs(adam.Brainrots:GetChildren()) do
	if item.Value == "Tung Tung Tung Sahur" then table.insert(sahurSerials, item:GetAttribute("Serial")) end
end
table.sort(sahurSerials)
check(#sahurSerials == 2 and sahurSerials[1] == 1 and sahurSerials[2] == 2, "les numéros de tirage devraient être #1 puis #2 (" .. table.concat(sahurSerials, ",") .. ")")
local items = adam.Brainrots:GetChildren()
check(#items >= 3, "les commandes /give n'ont pas marché (" .. #items .. " cartes)")

-- ouvrir le sac et cliquer PRENDRE sur une carte
local bagButton
for _, b in ipairs(menu:GetChildren()) do
	if b:IsA("TextButton") and b.LayoutOrder == 3 then bagButton = b end
end
click(bagButton)
local takeButton
for _, desc in ipairs(hud:GetDescendants()) do
	if desc:IsA("TextButton") and desc.Text == "PRENDRE" then takeButton = desc break end
end
check(takeButton ~= nil, "pas de bouton PRENDRE dans le sac")
if takeButton then click(takeButton) end
local held = adamChar:FindFirstChildOfClass("Tool")
check(held ~= nil and held:GetAttribute("ItemId") ~= nil, "aucune carte en main après PRENDRE")
check(held and held.Handle:FindFirstChild("CardGui") ~= nil, "la carte en main n'est pas dessinée")
chat(adam, "/mutation lave")

-- poser sur l'emplacement 1
local podium = myPlot:FindFirstChild("Podium1")
local prompt = podium and podium:FindFirstChildOfClass("ProximityPrompt")
check(prompt ~= nil and prompt.Enabled, "le bouton E de l'emplacement 1 devrait être actif côté client")
if prompt then
	mock.getSignal(prompt, "Triggered"):Fire(adam)
	frames(0.5)
end
local placed = 0
local placedName
for _, item in ipairs(adam.Brainrots:GetChildren()) do
	if item:GetAttribute("Slot") > 0 then
		placed += 1
		placedName = item.Value
	end
end
check(placed == 1, "la carte n'a pas été posée")
local cardPart = myPlot:FindFirstChild("CardDisplay", true)
check(cardPart ~= nil, "pas de carte sur le podium")
check(cardPart and cardPart:FindFirstChild("CardGui") ~= nil, "le client n'a pas dessiné la carte")
check(cardPart and cardPart:GetAttribute("CardName") == placedName, "la carte du podium n'est pas la bonne")
check(cardPart and math.abs(cardPart.Size.Y / cardPart.Size.X - 1.6) < 0.01, "la carte du podium devrait être au format 5:8")
local art
for _, desc in ipairs(cardPart:GetDescendants()) do
	if desc:IsA("ImageLabel") and desc.Name == "Art" then art = desc end
end
local ATLAS_IDS = {"rbxassetid://2222", "rbxassetid://3333", "rbxassetid://4444"}
local placedIndex = 0
for index, c in ipairs(mock.moduleCache.server[RS.GameConfig].value.CARDS) do
	if c.Name == placedName then placedIndex = index end
end
local layout = mock.moduleCache.server[RS.GameConfig].value.CARD_ATLAS_LAYOUT
local expectedAtlas = ATLAS_IDS[(placedIndex - 1) // (layout.Columns * layout.Rows) + 1]
check(art ~= nil and art.Image == expectedAtlas, "l'illustration de " .. tostring(placedName) .. " devrait venir de " .. tostring(expectedAtlas) .. " (a " .. tostring(art and art.Image) .. ")")
check(art ~= nil and art.ImageRectSize.X == layout.CellWidth, "l'illustration devrait être découpée dans l'atlas")
-- effets de la carte : mutation Lave (étincelles + lueur), holographique pour Pandaccini (Mythique), numéro de tirage
local CS = mock.getService("CollectionService")
local function hasTag(root, tagName)
	for _, desc in ipairs(root:GetDescendants()) do
		if CS:HasTag(desc, tagName) then return true end
	end
	return false
end
check(hasTag(cardPart, "Sparkle") and hasTag(cardPart, "MutationPulse"), "la carte mutée devrait avoir des étincelles et une lueur")
local serialText = cardPart:FindFirstChild("SerialText", true)
check(serialText ~= nil and serialText.Text:sub(1, 1) == "#", "la carte devrait afficher son numéro de tirage")
local holoFound = false
for _, gui in ipairs(hud:GetDescendants()) do
	if gui.Name == "HoloFoil" then holoFound = true end
end
check(holoFound, "les cartes Mythiques et + devraient être holographiques (dans le sac)")
local soundService = mock.getService("SoundService")
local breakSound = soundService:FindFirstChild("Break")
check(breakSound ~= nil and breakSound.SoundId == "rbxassetid://1111" and breakSound.PlaybackRegionsEnabled, "les sons devraient utiliser le fichier de sons")

-- revenu + COLLECTER
frames(5)
local pad = myPlot:FindFirstChild("CollectPad1")
local cashBeforeCollect = adam.leaderstats.Cash.Value
mock.getSignal(pad, "Touched"):Fire(adamChar.HumanoidRootPart)
frames(0.2)
check(adam.leaderstats.Cash.Value > cashBeforeCollect, "COLLECTER n'a rien donné")

-- ====== 6. Rebirth (via le bouton de la fenêtre) ======
chat(adam, "/cash 5000")
chat(adam, "/give cartonino")
chat(adam, "/give sassolino")
chat(adam, "/give teierina")
local rebirthButton
for _, b in ipairs(menu:GetChildren()) do
	if b:IsA("TextButton") and b.LayoutOrder == 5 then rebirthButton = b end
end
click(rebirthButton)
local doRebirth
for _, desc in ipairs(hud:GetDescendants()) do
	if desc:IsA("TextButton") and desc.Text == "REBIRTH" then doRebirth = desc end
end
check(doRebirth ~= nil, "bouton REBIRTH introuvable (conditions pas remplies ?)")
if doRebirth then click(doRebirth) end
check(adam.leaderstats.Rebirths.Value == 1, "le rebirth n'a pas marché")
check(myPlot:FindFirstChild("Level1") ~= nil, "l'étage 1 aurait dû être construit")
local slot9 = myPlot:FindFirstChild("Podium9", true)
local slot12 = myPlot:FindFirstChild("Podium12", true)
check(slot9 and slot9:FindFirstChildOfClass("ProximityPrompt").Enabled, "emplacement 9 (étage 1 gauche) devrait être débloqué")
check(slot12 and not slot12:FindFirstChildOfClass("ProximityPrompt").Enabled, "emplacement 12 (étage 1 droite) devrait être bloqué jusqu'au rebirth 3")

-- ascenseur
local liftUp = myPlot:FindFirstChild("LiftUp", true)
check(liftUp ~= nil, "pas d'ascenseur")
if liftUp then
	mock.getSignal(liftUp, "Touched"):Fire(adamChar.HumanoidRootPart)
	frames(0.2)
	check(adamChar.HumanoidRootPart.Position.Y > 15, "l'ascenseur n'a pas fait monter (Y=" .. adamChar.HumanoidRootPart.Position.Y .. ")")
end

local liftDown = myPlot.Level1:FindFirstChild("LiftDown")
if liftDown then
	frames(1.2)
	mock.getSignal(liftDown, "Touched"):Fire(adamChar.HumanoidRootPart)
	frames(0.2)
	check(adamChar.HumanoidRootPart.Position.Y < 10, "l'ascenseur n'a pas fait descendre")
end

-- plus de rebirths -> étages 2 et 3
chat(adam, "/rebirths 7")
frames(0.5)
check(myPlot:FindFirstChild("Level3") ~= nil, "l'étage 3 aurait dû être construit au rebirth 7")

-- ====== 7. Boutique de pioches ======
local shopPrompt = workspace.Shop.Counter:FindFirstChild("PickaxePrompt", true)
check(shopPrompt ~= nil and shopPrompt.KeyboardKeyCode == Enum.KeyCode.E, "pas de bouton E (pioches) à la boutique")
adamChar:PivotTo(mock.CFrame.new(workspace.Shop.Counter.Position))
mock.getSignal(shopPrompt, "Triggered"):Fire(adam)
frames(0.5)
chat(adam, "/cash 10000")
local buyButton
for _, desc in ipairs(hud:GetDescendants()) do
	if desc:IsA("TextButton") and desc.Text:sub(1, 1) == "$" then buyButton = desc end
end
check(buyButton ~= nil, "la boutique ne s'est pas ouverte / pas de bouton d'achat")
if buyButton then click(buyButton) end
check(adam.PickaxeTier.Value == 2, "l'achat de la pioche en pierre a échoué (tier " .. adam.PickaxeTier.Value .. ")")

-- ====== 8. Booster (gratuit en Studio) ======
local boosterRemote = RS.RemoteEvents.BuyBooster
local before = #adam.Brainrots:GetChildren()
mock.context = "client"
boosterRemote:FireServer("Commun")
mock.context = "server"
frames(4)
check(#adam.Brainrots:GetChildren() == before + 3, "le booster n'a pas donné 3 cartes")
-- les cartes arrivent face cachée : on clique dessus pour les révéler
local opening = hud:FindFirstChild("BoosterOpening")
check(opening ~= nil, "l'ouverture du booster ne s'affiche pas")
if opening then
	local backs = {}
	for _, desc in ipairs(opening:GetDescendants()) do
		if desc.Name == "CardBack" then table.insert(backs, desc) end
	end
	check(#backs == 3, "il devrait y avoir 3 cartes face cachée (" .. #backs .. ")")
	local fronts = 0
	for _, desc in ipairs(opening:GetDescendants()) do
		if desc.Name == "CardFront" then fronts += 1 end
	end
	check(fronts == 0, "les cartes ne devraient pas se retourner toutes seules")
	for _, back in ipairs(backs) do
		click(back)
	end
	frames(1)
	fronts = 0
	local superButton
	for _, desc in ipairs(opening:GetDescendants()) do
		if desc.Name == "CardFront" then fronts += 1 end
		if desc:IsA("TextButton") and desc.Text == "SUPER !" then superButton = desc end
	end
	check(fronts == 3, "cliquer devrait révéler les 3 cartes (" .. fronts .. ")")
	check(superButton ~= nil and superButton.Visible, "le bouton SUPER ! devrait apparaître")
	if superButton then click(superButton) end
end

-- Booster Céleste : 1 carte, au minimum Angel
local beforeCeleste = {}
for _, item in ipairs(adam.Brainrots:GetChildren()) do beforeCeleste[item] = true end
mock.context = "client"
boosterRemote:FireServer("Celeste")
mock.context = "server"
frames(0.5)
local announced = false
for _, desc in ipairs(hud:GetDescendants()) do
	if desc:IsA("TextLabel") and desc.Text:find("a pack un", 1, true) then announced = true end
end
check(announced, "une grosse carte packée devrait être annoncée")
frames(2.5)
local celesteCards = {}
for _, item in ipairs(adam.Brainrots:GetChildren()) do
	if not beforeCeleste[item] then table.insert(celesteCards, item) end
end
local GC = mock.moduleCache.server[RS.GameConfig].value
local celesteRarity = #celesteCards == 1 and GC.getCard(celesteCards[1].Value).Rarity
check(#celesteCards == 1 and (celesteRarity == "Angel" or celesteRarity == "Secret" or celesteRarity == "OG"), "le Booster Céleste devrait donner 1 carte Angel, Secret ou OG")
local celesteOpening = hud:FindFirstChild("BoosterOpening")
if celesteOpening then
	for _, desc in ipairs(celesteOpening:GetDescendants()) do
		if desc:IsA("TextButton") and desc.Text == "TOUT RÉVÉLER" then click(desc) end
	end
	frames(1)
	celesteOpening:Destroy()
end

-- Game Pass Argent x2 (gratuit dans Studio)
local multiplierBefore = GC.getPlayerMultiplier(adam)
mock.context = "client"
RS.RemoteEvents.BuyProduct:FireServer("DoubleCash")
mock.context = "server"
frames(0.5)
check(adam:GetAttribute("DoubleCash") == true, "le Game Pass Argent x2 n'a pas été donné")
check(math.abs(GC.getPlayerMultiplier(adam) - multiplierBefore * 2) < 1e-6, "Argent x2 devrait doubler le revenu")
local doubleButton = hud:FindFirstChild("DoubleCashButton", true)
check(doubleButton ~= nil and doubleButton.Text == "ACHETÉ ✓", "le bouton Argent x2 devrait afficher ACHETÉ")

-- Game Pass Tapis volant : l'outil apparaît, on le prend en main -> on vole avec le tapis sous les pieds
mock.context = "client"
RS.RemoteEvents.BuyProduct:FireServer("FlyingCarpet")
mock.context = "server"
frames(0.5)
local carpetTool = adam.Backpack:FindFirstChild("Tapis volant")
check(adam:GetAttribute("FlyingCarpet") == true and carpetTool ~= nil, "le tapis volant n'a pas été donné")
if carpetTool then
	carpetTool.Parent = adamChar
	frames(0.5)
	check(adamChar.HumanoidRootPart:FindFirstChildOfClass("LinearVelocity") ~= nil, "le tapis volant ne fait pas voler")
	check(adamChar:FindFirstChild("FlyingCarpet") ~= nil, "le tapis n'apparaît pas sous le joueur")
	carpetTool.Parent = adam.Backpack
	frames(0.5)
	check(adamChar.HumanoidRootPart:FindFirstChildOfClass("LinearVelocity") == nil and adamChar:FindFirstChild("FlyingCarpet") == nil, "ranger le tapis devrait arrêter le vol")
end

-- Décor : statues de brainrots + ciel animé
local statuesFolder = workspace.Decor:FindFirstChild("Statues")
check(statuesFolder ~= nil and #statuesFolder:GetChildren() >= 8, "il devrait y avoir des statues de brainrots dans la map")
local skyFx = workspace:FindFirstChild("SkyFX")
local beams = 0
if skyFx then
	for _, desc in ipairs(skyFx:GetDescendants()) do
		if desc:IsA("Beam") then beams += 1 end
	end
end
check(beams >= 3, "le ciel devrait avoir des aurores")
local shootingSeen = false
for _ = 1, 30 do
	frames(0.2)
	if skyFx and skyFx:FindFirstChild("ShootingStar") then shootingSeen = true break end
end
check(shootingSeen, "il devrait y avoir des étoiles filantes")

-- ====== 9. Échange Adam -> Bob ======
chat(adam, "/rebirths 0")
local remotes = RS.RemoteEvents
mock.context = "client"
remotes.TradeRequest:FireServer(bob)
mock.context = "server"
frames(0.2)
mock.getSignal(remotes.TradeRespond, "OnServerEvent"):Fire(bob, adam, true)
frames(0.2)
local offered
for _, item in ipairs(adam.Brainrots:GetChildren()) do
	if item:GetAttribute("Slot") == 0 then offered = item break end
end
mock.context = "client"
remotes.TradeAction:FireServer("add", offered.Name)
remotes.TradeAction:FireServer("ready")
mock.context = "server"
mock.getSignal(remotes.TradeAction, "OnServerEvent"):Fire(bob, "ready")
frames(5)
check(offered.Parent == bob.Brainrots, "l'échange n'a pas transféré la carte")

-- ====== 10. Tapis roulants ======
local conveyors = workspace.Decor:FindFirstChild("Conveyors")
check(conveyors and #conveyors:GetChildren() >= 14, "il manque des tapis roulants")
local belt = conveyors and conveyors:FindFirstChild("Conveyor"):FindFirstChild("Belt")
check(belt and belt.AssemblyLinearVelocity.Magnitude > 10, "le tapis ne pousse pas")

-- ====== 10b. Cadeau de départ (dans le menu 🎁 Cadeaux) ======
do
	local chest = workspace:FindFirstChild("StarterChest")
	local starterWindow = hud:FindFirstChild("Cadeau de départ")
	local dailyWindow0 = hud:FindFirstChild("Récompenses du jour")
	check(chest ~= nil, "le coffre doré du cadeau de départ devrait être sur la dalle en pierre")
	check(starterWindow ~= nil and dailyWindow0 ~= nil, "il manque le menu du cadeau de départ")
	check(dailyWindow0 and dailyWindow0:FindFirstChild("StarterButton", true) == nil, "le menu du jour ne doit plus avoir le bouton CADEAU DE DÉPART")
	if chest and starterWindow then
		starterWindow.Visible = false
		adamChar:PivotTo(mock.CFrame.new(chest:GetAttribute("Center") + mock.Vector3.new(4, 3, 0)))
		frames(0.6)
		check(starterWindow.Visible, "entrer dans la zone jaune du coffre devrait ouvrir le cadeau de départ")
		-- sans favori ni like : le coffre reste fermé
		local openBtn = starterWindow:FindFirstChild("OpenStarterButton", true)
		local cashStart = adam.leaderstats.Cash.Value
		click(openBtn)
		frames(0.3)
		check(adam:GetAttribute("StarterClaimed") ~= true, "il faut le favori et le like pour ouvrir le cadeau")
		click(starterWindow:FindFirstChild("FavoriteButton", true))
		click(starterWindow:FindFirstChild("LikeButton", true))
		local cardsStart = #adam.Brainrots:GetChildren()
		click(openBtn)
		frames(0.3)
		check(adam:GetAttribute("StarterClaimed") == true, "le cadeau de départ devrait s'ouvrir après favori + like")
		check(adam.leaderstats.Cash.Value >= cashStart + 15000, "le cadeau de départ devrait donner $15 000")
		local gotRare = false
		for _, item in ipairs(adam.Brainrots:GetChildren()) do
			local card = mock.moduleCache.server[RS.GameConfig].value.getCard(item.Value)
			if card and card.Rarity == "Très Rare" then gotRare = true end
		end
		check(#adam.Brainrots:GetChildren() == cardsStart + 1 and gotRare, "le cadeau de départ devrait donner une carte Très Rare")
		click(openBtn)
		frames(0.3)
		check(#adam.Brainrots:GetChildren() == cardsStart + 1, "le cadeau de départ ne s'ouvre qu'une fois")
		starterWindow.Visible = false
		adamChar:PivotTo(mock.CFrame.new(0, 5, 0))
		frames(0.4)
	end
end

-- ====== 11. Minage long (minerais -> cartes) ======
local broken, found = 0, 0
mock.context = "client"
RS.RemoteEvents.Effect.OnClientEvent:Connect(function(kind) if kind == "Break" then broken += 1 end end)
RS.RemoteEvents.CardFound.OnClientEvent:Connect(function() found += 1 end)
mock.context = "server"
chat(adam, "/pickaxe 6")
adamChar:PivotTo(mock.CFrame.new(0, 3, 0))
-- On creuse tout droit au centre : le personnage "tombe" au-dessus du bloc visé
mock.raycastHook = function()
	local best
	for _, block in ipairs(blocks:GetChildren()) do
		local p = block.Position
		if math.abs(p.X) < 6 and math.abs(p.Z) < 6 and (not best or p.Y > best.Position.Y) then
			best = block
		end
	end
	if best then
		adamChar:PivotTo(mock.CFrame.new(best.Position + mock.Vector3.new(0, 5, 0)))
		return {Instance = best, Position = best.Position}
	end
	return nil
end
local cardsBefore = #adam.Brainrots:GetChildren()
mock.context = "client"
mock.getSignal(UIS, "InputBegan"):Fire({UserInputType = Enum.UserInputType.MouseButton1}, false)
mock.context = "server"
frames(40)
mock.context = "client"
mock.getSignal(UIS, "InputEnded"):Fire({UserInputType = Enum.UserInputType.MouseButton1})
mock.context = "server"
print("blocs cassés", broken, "cartes", found)
print("Cartes trouvées en 40s de minage (netherite) :", #adam.Brainrots:GetChildren() - cardsBefore, "cash", adam.leaderstats.Cash.Value)
check(#adam.Brainrots:GetChildren() > cardsBefore, "aucune carte trouvée en minant 40s")
-- on casse aussi un coffre visible (ils apparaissent souvent dans les parois du trou)
mock.raycastHook = nil
local chestBlock
for _, block in ipairs(blocks:GetChildren()) do
	if block.Name == "ChestBlock" then chestBlock = block break end
end
check(chestBlock ~= nil, "il devrait y avoir un coffre visible dans la mine")
if chestBlock then
	for _ = 1, 60 do
		if not chestBlock.Parent then break end
		adamChar:PivotTo(mock.CFrame.new(chestBlock.Position + mock.Vector3.new(0, 5, 0)))
		mock.context = "client"
		RS.RemoteEvents.MineBlock:FireServer(chestBlock)
		mock.context = "server"
		frames(0.3)
	end
end
local mineralTotal = 0
for _, value in ipairs(adam.Minerals:GetChildren()) do mineralTotal += value.Value end
print("Minerais trouvés dans les coffres :", mineralTotal)
check(mineralTotal > 0, "casser des coffres dans la mine devrait donner des minerais")

-- ====== 12. Régénération de la mine ======
mock.runFor(620)
check(#blocks:GetChildren() == 32 * 32, "la mine ne s'est pas régénérée (" .. #blocks:GetChildren() .. " blocs)")

-- ====== 13. Sauvegarde puis reconnexion ======
chat(adam, "/rebirths 2")
local savedCash = adam.leaderstats.Cash.Value
local savedCount = #adam.Brainrots:GetChildren()
mock.getSignal(Players, "PlayerRemoving"):Fire(adam)
frames(0.5)
adam.Parent = nil
check(myPlot:GetAttribute("OwnerId") == 0, "la base aurait dû être libérée")
mock.getSignal(Players, "PlayerRemoving"):Fire(bob)
frames(0.5)
-- on fait comme si Adam était parti depuis 1 heure (gains hors-ligne)
local storeName = mock.moduleCache.server[RS.GameConfig].value.DATASTORE_NAME
local savedData = mock.stores[storeName]["u_1"]
local cashInSave = savedData.Cash
savedData.LastSeen = os.time() - 3600
local adam2 = addPlayer("Adam", 1)
frames(1)
check(adam2.leaderstats.Cash.Value > cashInSave, "les gains hors-ligne auraient dû être donnés (1 h d'absence)")
print("Après reconnexion : cash", adam2.leaderstats.Cash.Value, "cartes", #adam2.Brainrots:GetChildren(), "rebirths", adam2.leaderstats.Rebirths.Value)
check(adam2.leaderstats.Cash.Value >= savedCash, "le cash n'a pas été sauvegardé")
check(#adam2.Brainrots:GetChildren() == savedCount, "les cartes n'ont pas été sauvegardées")
check(adam2.leaderstats.Rebirths.Value == 2, "les rebirths n'ont pas été sauvegardés")
local serialKept = false
for _, item in ipairs(adam2.Brainrots:GetChildren()) do
	if item.Value == "Tung Tung Tung Sahur" and (item:GetAttribute("Serial") or 0) > 0 then serialKept = true end
end
check(serialKept, "les numéros de tirage n'ont pas été sauvegardés")


-- ====== 14. Vente ======
chat(adam2, "/give tralalero")
local adam2Cash = adam2.leaderstats.Cash.Value
local sold
for _, item in ipairs(adam2.Brainrots:GetChildren()) do
	if item.Value == "Tralalero Tralala" and item:GetAttribute("Slot") == 0 then sold = item end
end
mock.localPlayer = adam2
mock.context = "client"
RS.RemoteEvents.SellBrainrot:FireServer(sold.Name)
mock.context = "server"
frames(0.3)
check(sold.Parent == nil and adam2.leaderstats.Cash.Value > adam2Cash, "la vente n'a pas marché")

-- ====== 15. Verrou + vol + batte ======
local bob2 = addPlayer("Bob", 2)
frames(1)
local adamChar2 = spawnCharacter(adam2)
local bobChar2 = spawnCharacter(bob2)
frames(1)
local plotA, plotB
for _, plot in ipairs(workspace.Plots:GetChildren()) do
	if plot:GetAttribute("OwnerId") == 1 then plotA = plot end
	if plot:GetAttribute("OwnerId") == 2 then plotB = plot end
end
check(plotA ~= nil and plotB ~= nil, "les deux joueurs devraient avoir une base")

-- Bob verrouille sa base : pour Adam (client), ses lasers bloquent
local lockPrompt = plotB:FindFirstChild("LockPrompt", true)
mock.getSignal(lockPrompt, "Triggered"):Fire(bob2)
frames(1)
local laserB = plotB.Lasers:FindFirstChild("Laser")
check(laserB.CanCollide == true and laserB.Transparency == 0, "les lasers de Bob devraient bloquer Adam")
check(plotB:GetAttribute("LockedUntil") > mock.now, "la base de Bob devrait être verrouillée")
check(plotB.Lasers.LaserWall.CanCollide == true, "le mur des lasers devrait bloquer Adam (pas de trou entre les lasers)")
-- Adam essaie quand même d'entrer (en se faufilant / par le toit) : il est repoussé dehors
adamChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 30, 0)))
frames(0.3)
adamChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 3, 0)))
frames(0.5)
local relAdam = plotB.Floor.CFrame:PointToObjectSpace(adamChar2.HumanoidRootPart.Position)
check(relAdam.Z < -plotB.Floor.Size.Z / 2, "Adam aurait dû être repoussé hors de la base verrouillée de Bob")
bobChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 3, 0)))
frames(0.5)
local relBob = plotB.Floor.CFrame:PointToObjectSpace(bobChar2.HumanoidRootPart.Position)
check(math.abs(relBob.Z) < 5, "Bob (le propriétaire) doit pouvoir entrer dans sa base verrouillée")
-- Bob active "mes amis passent mes lasers" : Adam est son ami, il peut entrer
mock.friends = {["1:2"] = true}
bob2:SetAttribute("Setting_FriendsCanEnter", true)
adamChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 30, 0)))
frames(0.3)
adamChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 3, 0)))
frames(0.5)
adamChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 30, 0)))
frames(0.3)
adamChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 3, 0)))
frames(0.5)
relAdam = plotB.Floor.CFrame:PointToObjectSpace(adamChar2.HumanoidRootPart.Position)
check(math.abs(relAdam.Z) < 5, "un AMI doit pouvoir entrer quand l'option amis est activée")
mock.friends = {}
bob2:SetAttribute("Setting_FriendsCanEnter", false)
adamChar2:PivotTo(mock.CFrame.new(plotB.Floor.Position + mock.Vector3.new(0, 30, 0)))
frames(0.3)

-- Adam pirate les lasers de Bob (mini-jeu des fils)
local hackPrompt = plotB:FindFirstChild("HackPrompt", true)
check(hackPrompt ~= nil and hackPrompt.Enabled, "le bouton Pirater devrait être visible pour Adam (base de Bob verrouillée)")
local function playHack(correct)
	adamChar2:PivotTo(mock.CFrame.new(plotB.HackPanel.Position + mock.Vector3.new(0, 0, 0)))
	mock.getSignal(hackPrompt, "Triggered"):Fire(adam2)
	frames(0.3)
	local game = hud:FindFirstChild("HackGame")
	check(game ~= nil, "le mini-jeu de piratage ne s'ouvre pas")
	if not game then return end
	local orderText
	for _, desc in ipairs(game:GetDescendants()) do
		if desc:IsA("TextLabel") and desc.Text:find("Coupe dans l'ordre", 1, true) then orderText = desc.Text end
	end
	local names = {}
	for name in string.gmatch(orderText:gsub("Coupe dans l'ordre : ", ""), "[^ →]+") do table.insert(names, name) end
	local wireByName = {}
	for _, wire in ipairs(game:GetDescendants()) do
		if wire:IsA("TextButton") and wire.Name:sub(1, 4) == "Wire" then
			for _, label in ipairs(wire:GetChildren()) do
				if label:IsA("TextLabel") then wireByName[label.Text] = wire end
			end
		end
	end
	if correct then
		for _, name in ipairs(names) do
			if wireByName[name] then click(wireByName[name]) end
		end
	else
		for name, wire in pairs(wireByName) do
			if name ~= names[1] then click(wire) break end
		end
	end
	frames(1.5)
end
playHack(true)
check((plotB:GetAttribute("LockedUntil") or 0) <= mock.now, "le piratage réussi devrait couper les lasers de Bob")
mock.getSignal(lockPrompt, "Triggered"):Fire(bob2)
frames(0.5)
playHack(false)
check(plotB:GetAttribute("LockedUntil") > mock.now, "un piratage raté ne doit pas ouvrir la base")
mock.getSignal(hackPrompt, "Triggered"):Fire(adam2)
frames(0.3)
check(hud:FindFirstChild("HackGame") == nil, "après un échec, il faut attendre 5 minutes")

-- Adam pose une carte, Bob la vole
chat(adam2, "/give cappuccino")
local target
for _, item in ipairs(adam2.Brainrots:GetChildren()) do
	if item.Value == "Cappuccino Assassino" then target = item end
	if item:GetAttribute("Slot") == 1 then item:SetAttribute("Slot", 0) end
end
target:SetAttribute("Slot", 1)
frames(0.5)
local stealPrompt = plotA:FindFirstChild("Podium1"):FindFirstChild("StealPrompt")
check(stealPrompt ~= nil, "pas de bouton Voler")
local podiumA = plotA:FindFirstChild("Podium1")
bobChar2:PivotTo(mock.CFrame.new(podiumA.Position + mock.Vector3.new(0, 3, 0)))
mock.getSignal(stealPrompt, "Triggered"):Fire(bob2)
frames(0.5)
check(target:GetAttribute("Slot") == -1 and bob2:GetAttribute("Carrying") == "Cappuccino Assassino", "le vol n'a pas démarré")
check(bobChar2:FindFirstChild("StolenBrainrot") ~= nil and bobChar2.StolenBrainrot:FindFirstChildOfClass("Weld") ~= nil, "le voleur devrait tenir la carte en main")
check(hud:FindFirstChild("AlarmBanner", true) ~= nil, "le propriétaire devrait voir l'alarme rouge quand on le vole")
-- Adam frappe Bob avec sa batte
local bat = adam2.Backpack:FindFirstChild("Batte")
check(bat ~= nil, "Adam devrait avoir une batte")
local bobPos = bobChar2.HumanoidRootPart.Position
adamChar2:PivotTo(mock.CFrame.lookAt(bobPos - mock.Vector3.new(0, 0, 4), bobPos))
bat.Parent = adamChar2
mock.context = "client"
RS.RemoteEvents.BatSwing:FireServer()
mock.context = "server"
frames(0.5)
check(bob2:GetAttribute("Carrying") == nil, "Bob porte encore le brainrot")
-- la carte est tombée par terre : Adam (le propriétaire) la ramasse
local dropped = workspace:FindFirstChild("DroppedBrainrot")
check(dropped ~= nil and target:GetAttribute("OnGround") == true, "la carte devrait être tombée par terre")
if dropped then
	adamChar2:PivotTo(mock.CFrame.new(dropped.Position))
	mock.getSignal(dropped.PickupPrompt, "Triggered"):Fire(adam2)
	frames(0.3)
end
check(target.Parent == adam2.Brainrots and target:GetAttribute("Slot") == 1, "en ramassant sa carte, Adam devrait la récupérer sur son podium")
check(workspace:FindFirstChild("DroppedBrainrot") == nil, "la carte ramassée ne devrait plus être par terre")
-- Bob revole et rentre chez lui
frames(2.5)
bobChar2:PivotTo(mock.CFrame.new(podiumA.Position + mock.Vector3.new(0, 3, 0)))
mock.getSignal(stealPrompt, "Triggered"):Fire(bob2)
frames(0.3)
local bobPlotCFrame = plotB.Floor.CFrame
bobChar2:PivotTo(bobPlotCFrame * mock.CFrame.new(0, 3, 0))
frames(1)
check(target.Parent == bob2.Brainrots, "le brainrot volé n'est pas arrivé chez Bob")
check((target:GetAttribute("Slot") or 0) > 0, "le brainrot volé devrait être posé dans la base de Bob")

-- ====== 16. Roue de la fortune (dans le monde : E = tourner, F = acheter des tours) ======
local wheel = workspace:FindFirstChild("FortuneWheel")
check(wheel ~= nil, "pas de roue de la fortune dans le monde")
local spinPrompt = wheel and wheel.Console:FindFirstChild("SpinPrompt")
local buyPrompt = wheel and wheel.Console:FindFirstChild("BuyPrompt")
check(spinPrompt ~= nil and spinPrompt.KeyboardKeyCode == Enum.KeyCode.E, "pas de bouton E à la roue")
check(buyPrompt ~= nil and buyPrompt.KeyboardKeyCode == Enum.KeyCode.F, "pas de bouton F à la roue")
for _, desc in ipairs(menu:GetDescendants()) do
	check(not (desc:IsA("TextLabel") and desc.Text == "Roue"), "la roue ne devrait plus être dans le menu")
end
adamChar2:PivotTo(mock.CFrame.new(wheel.Console.Position + V3(0, 2, -3)))
-- F : la fenêtre d'achat s'ouvre
mock.getSignal(buyPrompt, "Triggered"):Fire(adam2)
frames(0.5)
local wheelButton
for _, b in ipairs(hud:GetDescendants()) do
	if b:IsA("TextButton") and b.Text == "TOURNER !" then wheelButton = b end
end
check(wheelButton ~= nil, "pas de bouton TOURNER dans la fenêtre de la roue")
-- E : tour gratuit
local disc = wheel.Disc
local pivotBefore = disc:GetPivot()
local before16 = adam2.leaderstats.Cash.Value + #adam2.Brainrots:GetChildren() + (adam2:GetAttribute("LuckUntil") or 0)
mock.getSignal(spinPrompt, "Triggered"):Fire(adam2)
local wheelTurned, wheelStayed = false, true
for _ = 1, 10 do
	frames(0.1)
	if (disc:GetPivot().UpVector - pivotBefore.UpVector).Magnitude > 0.01 then wheelTurned = true end
	if (disc:GetPivot().Position - pivotBefore.Position).Magnitude > 0.01 then wheelStayed = false end
end
check(wheel:GetAttribute("SpinId") == 1, "la roue n'a pas démarré")
check(wheelStayed, "la roue devrait tourner autour de son axe")
check(wheelTurned, "la roue ne tourne pas côté client")
frames(6)
local after16 = adam2.leaderstats.Cash.Value + #adam2.Brainrots:GetChildren() + (adam2:GetAttribute("LuckUntil") or 0)
check(after16 > before16, "la roue n'a rien donné")
check((adam2:GetAttribute("LastFreeSpin") or 0) > 0, "le tour gratuit n'a pas été utilisé")
-- tour acheté, avec le bouton de la fenêtre
chat(adam2, "/spins 1")
local spinsBefore = adam2.Spins.Value
if wheelButton then click(wheelButton) end
frames(7)
check(adam2.Spins.Value == spinsBefore - 1, "le tour payé n'a pas été utilisé")
-- trop loin : refusé
chat(adam2, "/spins 1")
local spinsFar = adam2.Spins.Value
adamChar2:PivotTo(mock.CFrame.new(0, 5, 0))
mock.context = "client"
RS.RemoteEvents.SpinWheel:FireServer()
mock.context = "server"
frames(0.5)
check(adam2.Spins.Value == spinsFar, "on ne devrait pas pouvoir tourner la roue de loin")

-- ====== 17. Potion + bonus d'index ======
mock.context = "client"
RS.RemoteEvents.BuyProduct:FireServer("LuckPotion")
mock.context = "server"
frames(0.3)
check((adam2:GetAttribute("LuckUntil") or 0) > os.time(), "la potion ne s'est pas activée")
for _, name in ipairs({"cartonino", "sassolino", "teierina", "bottiglione", "riccio"}) do
	chat(adam2, "/give " .. name)
end
local GameConfigModule = mock.moduleCache.server[RS.GameConfig].value
check(GameConfigModule.getIndexBonus(GameConfigModule.getDiscovered(adam2)) >= 0.05, "le bonus d'index Commun n'est pas actif")
check((adam2:GetAttribute("DexClaimed") or 0) >= 1, "les récompenses de l'Index (paliers) devraient être données")

-- ====== 18. Battes (touche F à la boutique) ======
local armoryPrompt = workspace.Shop.Counter:FindFirstChild("BatPrompt", true)
check(armoryPrompt ~= nil and armoryPrompt.KeyboardKeyCode == Enum.KeyCode.F, "pas de bouton F (battes) à la boutique")
adamChar2:PivotTo(mock.CFrame.new(workspace.Shop.Counter.Position))
mock.getSignal(armoryPrompt, "Triggered"):Fire(adam2)
frames(0.5)
chat(adam2, "/cash 100000")
local batBuy
for _, b in ipairs(hud:GetDescendants()) do
	if b:IsA("TextButton") and b.Text == "$25K" then batBuy = b end
end
check(batBuy ~= nil, "l'armurerie ne s'est pas ouverte")
check(RS:FindFirstChild("ToolPreviews") ~= nil and RS.ToolPreviews:FindFirstChild("Grapple_1") ~= nil and RS.ToolPreviews:FindFirstChild("Bat_5") ~= nil, "les modèles 3D du shop (grappins, battes) devraient être prêts")
local previews = 0
for _, desc in ipairs(hud:GetDescendants()) do
	if desc:IsA("ViewportFrame") and desc.Name == "Preview" then previews += 1 end
end
check(previews >= #mock.moduleCache.server[RS.GameConfig].value.GRAPPLES, "les grappins du shop devraient avoir une vraie icône 3D (" .. previews .. ")")
if batBuy then click(batBuy) end
check(adam2.BatTier.Value == 2, "l'achat de la batte a échoué")

-- ====== 19. Mutations : plus de chance = plus de mutations ======
local LootModule = mock.moduleCache.server[serverScript.Loot].value
local function mutatedRatio(luck, potion)
	local count = 0
	for _ = 1, 4000 do
		if LootModule.rollMutation(luck, potion) ~= "Normal" then count += 1 end
	end
	return count / 4000
end
local lowLuck, highLuck = mutatedRatio(1, false), mutatedRatio(20, true)
print("Mutations : chance normale", lowLuck, "grosse chance + potion", highLuck)
check(highLuck > lowLuck * 3, "la chance devrait rendre les mutations beaucoup plus fréquentes")

-- ====== 20. Grappin (touche F à la boutique) ======
adamChar2:PivotTo(mock.CFrame.new(workspace.Shop.Counter.Position))
chat(adam2, "/cash 10000")
mock.context = "client"
RS.RemoteEvents.BuyGrapple:FireServer(1)
mock.context = "server"
frames(0.3)
check(adam2.GrappleTier.Value == 1, "l'achat du grappin a échoué")
local hasGrapple = false
for _, container in ipairs({adam2.Backpack, adamChar2}) do
	for _, tool in ipairs(container:GetChildren()) do
		if tool:GetAttribute("Grapple") then hasGrapple = true end
	end
end
check(hasGrapple, "Adam devrait avoir un grappin dans son sac")
mock.context = "client"
RS.RemoteEvents.BuyGrapple:FireServer(3)
mock.context = "server"
frames(0.3)
check(adam2.GrappleTier.Value == 1, "on ne doit pas pouvoir sauter un grappin")

-- ====== 21. Portail + boutique ======
check(workspace:FindFirstChild("Portal", true) ~= nil, "le portail devrait être dans la carte")
local shopPickaxes = 0
for _, child in ipairs(workspace.Shop:GetChildren()) do
	for _, data in ipairs(GameConfigModule.PICKAXES) do
		if child:IsA("Model") and child.Name == data.Name then shopPickaxes += 1 end
	end
end
check(shopPickaxes == #GameConfigModule.PICKAXES, "toutes les pioches devraient être exposées à la boutique (" .. shopPickaxes .. ")")

-- ====== 22. Alt+F4 : le voleur garde la carte ======
chat(adam2, "/give cappuccino")
local lastCard
for _, item in ipairs(adam2.Brainrots:GetChildren()) do
	if item.Value == "Cappuccino Assassino" and item:GetAttribute("Slot") == 0 then lastCard = item end
	if item:GetAttribute("Slot") == 1 then item:SetAttribute("Slot", 0) end
end
lastCard:SetAttribute("Slot", 1)
frames(3)
bobChar2:PivotTo(mock.CFrame.new(podiumA.Position + mock.Vector3.new(0, 3, 0)))
mock.getSignal(stealPrompt, "Triggered"):Fire(bob2)
frames(0.3)
check(bob2:GetAttribute("Carrying") == "Cappuccino Assassino", "le 2e vol n'a pas démarré")
mock.getSignal(Players, "PlayerRemoving"):Fire(bob2)
frames(0.3)
check(lastCard.Parent == bob2.Brainrots, "si le voleur quitte (Alt+F4), il doit garder la carte")

-- ====== 23. /all (admin) ======
chat(adam2, "/all")
frames(0.5)
local ownedNames = {}
for _, item in ipairs(adam2.Brainrots:GetChildren()) do ownedNames[item.Value] = true end
local ownedCount = 0
for _ in pairs(ownedNames) do ownedCount += 1 end
check(ownedCount == #GameConfigModule.CARDS, "/all devrait donner toutes les cartes (" .. ownedCount .. ")")
check(adam2.PickaxeTier.Value == #GameConfigModule.PICKAXES and adam2.BatTier.Value == #GameConfigModule.BATS and adam2.GrappleTier.Value == #GameConfigModule.GRAPPLES, "/all devrait donner les meilleurs outils")
check(adam2.leaderstats.Rebirths.Value == #GameConfigModule.REBIRTHS and adam2:GetAttribute("FlyingCarpet") == true, "/all devrait donner rebirths max + tapis")

-- ====== 24. Classements ======
local boardsFolder = workspace:FindFirstChild("Leaderboards")
check(boardsFolder ~= nil and #boardsFolder:GetChildren() == 2, "il devrait y avoir 2 panneaux de classement")
for _, item in ipairs(adam2.Brainrots:GetChildren()) do
	if item.Value == "La Idra Dorata" then item:SetAttribute("Slot", 1) break end
end
frames(0.5)
local LeaderboardModule = mock.moduleCache.server[serverScript.LeaderboardManager].value
mock.context = "server"
LeaderboardModule.update()
frames(0.2)
local function firstRow(id)
	local screen = boardsFolder["Leaderboard_" .. id].Panel.Screen
	local row = screen:FindFirstChild("Row1", true)
	return row and row.PlayerName.Text, row and row.Value.Text
end
local richName, richValue = firstRow("Cash")
check(richName == adam2.DisplayName, "Adam (avec /all) devrait être 1er des plus riches, pas " .. tostring(richName))
check(richValue ~= nil and richValue:sub(1, 1) == "$", "la valeur du classement devrait être en $")
check((adam2:GetAttribute("Income") or 0) > 0, "le revenu par seconde de la base devrait être connu")
local incomeName, incomeValue = firstRow("Income")
check(incomeName ~= "—" and incomeValue:find("/s") ~= nil, "le classement des bases devrait afficher des $/s")

-- ====== 25. Récompenses quotidiennes + minerais ======
do
	local dailyWindow = hud:FindFirstChild("Récompenses du jour")
	check(dailyWindow ~= nil, "pas de menu des récompenses")
	-- le menu des récompenses s'ouvre avec le bouton 🎁 Cadeaux (et tout seul à l'arrivée dans le jeu)
	local giftsButton
	for _, label in ipairs(hud:GetDescendants()) do
		if label:IsA("TextLabel") and label.Text == "Cadeaux" and label.Parent:IsA("TextButton") then giftsButton = label.Parent end
	end
	if dailyWindow then dailyWindow.Visible = false end
	if giftsButton then click(giftsButton) end
	frames(0.3)
	check(dailyWindow and dailyWindow.Visible, "le bouton 🎁 Cadeaux devrait ouvrir le menu des récompenses")
	local claim = dailyWindow and dailyWindow:FindFirstChild("ClaimButton", true)
	local cash25 = adam2.leaderstats.Cash.Value
	adam2:SetAttribute("DailyStreak", 0)
	adam2:SetAttribute("DailyLast", 0)
	if claim then click(claim) end
	frames(0.3)
	check(adam2:GetAttribute("DailyStreak") == 1 and adam2.leaderstats.Cash.Value > cash25, "le jour 1 devrait donner de l'argent")
	if claim then click(claim) end
	frames(0.3)
	check(adam2:GetAttribute("DailyStreak") == 1, "on ne doit pas pouvoir récupérer 2 fois le même jour")
	-- on avance d'un jour à chaque fois jusqu'au jour 7
	local diamondsBefore = adam2.Minerals.Diamant.Value
	for _ = 2, 7 do
		adam2:SetAttribute("DailyLast", os.time() - 25 * 3600)
		if claim then click(claim) end
		frames(0.3)
	end
	check(adam2:GetAttribute("DailyStreak") == 7, "la série devrait être à 7 jours (" .. tostring(adam2:GetAttribute("DailyStreak")) .. ")")
	check(adam2.Minerals.Diamant.Value == diamondsBefore + 1, "le jour 7 devrait donner un minerai de diamant")
	check(hud:FindFirstChild("MineralPopup", true) ~= nil, "un beau message devrait annoncer le minerai")
	-- plus de 48 h sans venir : la série repart au jour 1
	adam2:SetAttribute("DailyLast", os.time() - 50 * 3600)
	if claim then click(claim) end
	frames(0.3)
	check(adam2:GetAttribute("DailyStreak") == 1, "après 48 h, la série devrait repartir au jour 1")

	-- donner le diamant à un brainrot posé
	local placed
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) > 0 then placed = item end
	end
	local incomeBefore = adam2:GetAttribute("Income") or 0
	mock.context = "client"
	RS.RemoteEvents.ApplyMineral:FireServer(placed.Name, "Diamant")
	mock.context = "server"
	frames(0.3)
	check(placed:GetAttribute("Mineral") == "Diamant", "le brainrot devrait avoir le minerai de diamant")
	check((adam2:GetAttribute("Income") or 0) > incomeBefore, "le minerai devrait augmenter l'argent par seconde")
	check(adam2.Minerals.Diamant.Value == diamondsBefore, "le diamant devrait être consommé")
	adam2.Minerals.Argent.Value += 1
	mock.context = "client"
	RS.RemoteEvents.ApplyMineral:FireServer(placed.Name, "Argent")
	mock.context = "server"
	frames(0.3)
	check(placed:GetAttribute("Mineral") == "Diamant", "un minerai moins fort ne doit pas remplacer le diamant")
	-- la fenêtre des minerais s'ouvre depuis le sac
	local mineralWindow = hud:FindFirstChild("Minerais")
	local mineralsBtn
	for _, b in ipairs(hud:GetDescendants()) do
		if b:IsA("TextButton") and b.Text == "◆ MINERAIS" then mineralsBtn = b end
	end
	if mineralsBtn then click(mineralsBtn) end
	frames(0.2)
	check(mineralWindow ~= nil and mineralWindow.Visible, "le bouton MINERAIS du sac devrait ouvrir la fenêtre")
end

-- ====== 26. Minerais rares ======
do
	local LootModule26 = mock.moduleCache.server[serverScript.Loot].value
	local counts = {}
	for _ = 1, 20000 do
		local id = LootModule26.rollMineral()
		counts[id] = (counts[id] or 0) + 1
	end
	local rare = ((counts.Diamant or 0) + (counts.Netherite or 0)) / 20000
	print("Coffre de la mine : diamant + netherite =", rare * 100, "%")
	check(rare < 0.05, "le diamant et la netherite devraient être très rares dans les coffres")
	check((counts.Netherite or 0) / 20000 < 0.01, "la netherite devrait être ultra rare")
end

-- ====== 27. Pack VIP ======
do
	-- (/all donne déjà le VIP : on repart d'un joueur sans VIP pour tester l'achat)
	adam2:SetAttribute("VIP", nil)
	adam2:SetAttribute("VIPMinerals", nil)
	adam2:SetAttribute("DoubleCash", nil)
	local diamonds, netherite = adam2.Minerals.Diamant.Value, adam2.Minerals.Netherite.Value
	adam2:SetAttribute("FlyingCarpet", nil)
	mock.context = "client"
	RS.RemoteEvents.BuyProduct:FireServer("VIP")
	mock.context = "server"
	frames(0.5)
	check(adam2:GetAttribute("VIP") == true, "l'achat du VIP a échoué")
	check(adam2:GetAttribute("FlyingCarpet") == true and adam2:GetAttribute("DoubleCash") == true, "le VIP devrait donner le tapis volant et l'argent x2")
	check(adam2.Minerals.Diamant.Value == diamonds + 1 and adam2.Minerals.Netherite.Value == netherite + 1, "le VIP devrait donner 1 diamant + 1 netherite")
	local head = adamChar2:FindFirstChild("Head")
	check(head == nil or head:FindFirstChild("VIPTag") ~= nil, "le tag VIP devrait être au-dessus de la tête")
	-- les minerais du VIP ne sont donnés qu'une fois
	adam2:SetAttribute("VIP", false)
	adam2:SetAttribute("VIP", true)
	frames(0.2)
	check(adam2.Minerals.Diamant.Value == diamonds + 1, "les minerais du VIP ne doivent être donnés qu'une fois")
	local oldPrice = hud:FindFirstChild("OldPrice", true)
	check(oldPrice ~= nil and oldPrice.Text:find("<s>", 1, true) ~= nil, "le prix barré du VIP devrait être affiché")
end

-- ====== 28. Index : silhouettes + BIENTÔT ======
do
	local indexWindow = hud:FindFirstChild("Index")
	local indexButton
	for _, label in ipairs(hud:GetDescendants()) do
		if label:IsA("TextLabel") and label.Text == "Index" and label.Parent:IsA("TextButton") then indexButton = label.Parent end
	end
	if indexButton then click(indexButton) end
	frames(0.3)
	local coming, mystery = 0, 0
	for _, desc in ipairs(indexWindow:GetDescendants()) do
		if desc.Name == "ComingSoonCard" then coming += 1 end
		if desc.Name == "MysteryCard" then mystery += 1 end
	end
	check(coming == 5, "l'Index devrait montrer 5 cartes BIENTÔT (" .. coming .. ")")
	print("Index : cartes mystère (silhouettes) =", mystery)
end

-- ====== 29. Paramètres ======
do
	local settingsButton = hud:FindFirstChild("SettingsButton")
	check(settingsButton ~= nil, "il manque le bouton ⚙️ Paramètres")
	if settingsButton then click(settingsButton) end
	frames(0.2)
	local settingsWindow = hud:FindFirstChild("Paramètres")
	check(settingsWindow ~= nil and settingsWindow.Visible, "le bouton ⚙️ devrait ouvrir les paramètres")
	local friendsToggle = settingsWindow and settingsWindow:FindFirstChild("Toggle_FriendsCanEnter", true)
	if friendsToggle then click(friendsToggle) end
	frames(0.2)
	check(adam2:GetAttribute("Setting_FriendsCanEnter") == true, "l'option amis devrait être activée (et sauvegardée par le serveur)")
	local lowToggle = settingsWindow and settingsWindow:FindFirstChild("Toggle_LowGraphics", true)
	if lowToggle then click(lowToggle) end
	frames(0.2)
	check(adam2:GetAttribute("Setting_LowGraphics") == true, "les graphismes allégés devraient s'activer")
end

-- ====== 30. Vendre par rareté + meilleurs en base ======
do
	local sellWindow = hud:FindFirstChild("Vendre")
	local sellMenuButton = hud:FindFirstChild("SellMenuButton", true)
	check(sellMenuButton ~= nil and sellWindow ~= nil, "il manque le bouton / menu VENDRE")
	if sellMenuButton then click(sellMenuButton) end
	frames(0.3)
	check(sellWindow and sellWindow.Visible, "le bouton VENDRE devrait ouvrir le menu des raretés")
	check(sellWindow and sellWindow:FindFirstChild("Sell_OG", true) ~= nil and sellWindow:FindFirstChild("Sell_Commun", true) ~= nil, "le menu VENDRE devrait aller de Commun jusqu'à OG")
	for _, label in ipairs(hud:GetDescendants()) do
		check(not (label:IsA("TextButton") and label.Text:find("VENDRE LES", 1, true)), "les anciens boutons VENDRE LES ... ne doivent plus être là")
	end

	-- meilleurs en base
	chat(adam2, "/give idra dorata")
	chat(adam2, "/give lucky block secret galaxie")
	frames(0.3)
	mock.context = "client"
	RS.RemoteEvents.PlaceBest:FireServer()
	mock.context = "server"
	frames(0.5)
	local GC = mock.moduleCache.server[RS.GameConfig].value
	local function incomeOf(item)
		return GC.getItemIncome(item.Value, item:GetAttribute("Mutation")) * GC.getMineralMultiplier(item:GetAttribute("Mineral"))
	end
	local worstPlaced, bestInBag = math.huge, 0
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do
		local slot = item:GetAttribute("Slot") or 0
		if slot > 0 then
			worstPlaced = math.min(worstPlaced, incomeOf(item))
		elseif slot == 0 then
			bestInBag = math.max(bestInBag, incomeOf(item))
		end
	end
	check(worstPlaced >= bestInBag, "MEILLEURS EN BASE : un brainrot du sac rapporte plus qu'un brainrot posé")
	local topPlaced = false
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do
		if item.Value == "Lucky Block Secret" and item:GetAttribute("Mutation") == "Galaxie" and (item:GetAttribute("Slot") or 0) > 0 then topPlaced = true end
	end
	check(topPlaced, "le Lucky Block Secret Galaxie devrait être posé dans la base")
end

-- ====== 31. Index des mutations ======
do
	check(adam2.IndexMutations:FindFirstChild("Lucky Block Secret|Galaxie") ~= nil, "la carte Galaxie devrait entrer dans l'index des mutations")
	local indexWindow = hud:FindFirstChild("Index")
	local galaxyTab = indexWindow and indexWindow:FindFirstChild("Tab_Galaxie", true)
	check(galaxyTab ~= nil, "l'Index devrait avoir un onglet par mutation")
	if galaxyTab then click(galaxyTab) end
	frames(0.2)
	local mystery = 0
	for _, desc in ipairs(indexWindow:GetDescendants()) do
		if desc.Name == "MysteryCard" then mystery += 1 end
	end
	check(mystery > 0, "dans l'onglet Galaxie, les cartes pas encore eues en Galaxie devraient être des silhouettes")
end

-- ====== 32. Téléphone : les fenêtres rentrent dans l'écran ======
do
	local camera = workspace.CurrentCamera
	mock.data[camera].props.ViewportSize = mock.Vector2.new(812, 375) -- iPhone en paysage
	local bag = hud:FindFirstChild("Sac")
	local bagButton
	for _, label in ipairs(hud:GetDescendants()) do
		if label:IsA("TextLabel") and label.Text == "Sac" and label.Parent:IsA("TextButton") then bagButton = label.Parent end
	end
	if bag then bag.Visible = false end
	if bagButton then click(bagButton) end
	frames(0.5)
	local frame = bag and bag:FindFirstChildOfClass("Frame")
	local fit = frame and frame:FindFirstChildOfClass("UIScale")
	check(fit ~= nil and fit.Scale < 0.62, "sur un téléphone, le Sac devrait rétrécir pour rentrer dans l'écran (" .. tostring(fit and fit.Scale) .. ")")
	mock.data[camera].props.ViewportSize = nil
end

-- ====== 33. Commandes admin (viser un autre joueur avec @) ======
do
	for _, old in ipairs(Players:GetPlayers()) do
		if old.Name == "Bob" then old.Parent = nil end -- l'ancien Bob a quitté le serveur
	end
	local bob3 = addPlayer("Bob", 2)
	frames(1)
	chat(adam2, "/vip @bob")
	frames(0.3)
	check(bob3:GetAttribute("VIP") == true and bob3:GetAttribute("FlyingCarpet") == true, "/vip @bob devrait donner le VIP à Bob")
	local bobCash = bob3.leaderstats.Cash.Value
	chat(adam2, "/cash @bob 2m")
	check(bob3.leaderstats.Cash.Value == bobCash + 2000000, "/cash @bob 2m devrait donner 2 000 000 à Bob")
	local bobCards = #bob3.Brainrots:GetChildren()
	chat(adam2, "/give @bob sahur galaxie 3")
	local galaxySahur = 0
	for _, item in ipairs(bob3.Brainrots:GetChildren()) do
		if item.Value == "Tung Tung Tung Sahur" and item:GetAttribute("Mutation") == "Galaxie" then galaxySahur += 1 end
	end
	check(#bob3.Brainrots:GetChildren() == bobCards + 3 and galaxySahur >= 3, "/give @bob sahur galaxie 3 devrait donner 3 Sahur Galaxie à Bob")
	local diamonds = bob3.Minerals.Diamant.Value
	chat(adam2, "/mineral @bob diamant 2")
	check(bob3.Minerals.Diamant.Value == diamonds + 2, "/mineral @bob diamant 2")
	chat(adam2, "/grapple @bob 3")
	check(bob3.GrappleTier.Value == 3, "/grapple @bob 3")
	chat(adam2, "/setcash @all 5k")
	check(bob3.leaderstats.Cash.Value == 5000 and adam2.leaderstats.Cash.Value == 5000, "/setcash @all 5k devrait viser tout le monde")
	chat(adam2, "/rebirths @bob 0")
	check(bob3.leaderstats.Rebirths.Value == 0, "/rebirths @bob 0")
	chat(adam2, "/dex @bob")
	check(#bob3.Index:GetChildren() == #mock.moduleCache.server[RS.GameConfig].value.CARDS, "/dex @bob devrait débloquer tout l'Index")
	chat(adam2, "/unvip @bob")
	check(bob3:GetAttribute("VIP") == false, "/unvip @bob")
	chat(adam2, "/aide")
	frames(0.2)
	local helpWindow = hud:FindFirstChild("Commandes admin")
	check(helpWindow ~= nil and helpWindow.Visible, "/aide devrait ouvrir la liste des commandes")
	chat(adam2, "/resetmine")
	check(#workspace.Mine.Blocks:GetChildren() == 32 * 32, "/resetmine devrait régénérer la mine")
end

-- ====== 35. Carte en main : G pour ranger, maintenir E 3 s pour donner ======
do
	local bob4
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == "Bob" and p.Parent then bob4 = p end
	end
	if bob4 and not bob4.Character then
		spawnCharacter(bob4)
		frames(0.5)
	end
	local adamChar3, bobChar4 = adam2.Character, bob4 and bob4.Character
	check(bob4 ~= nil and bobChar4 ~= nil, "Bob devrait être là")
	if bob4 and bobChar4 and adamChar3 then
		chat(adam2, "/rebirths 1")
		chat(adam2, "/give tralalero")
		local card
		for _, item in ipairs(adam2.Brainrots:GetChildren()) do
			if item.Value == "Tralalero Tralala" and (item:GetAttribute("Slot") or 0) == 0 then card = item end
		end
		local function equip()
			mock.context = "client"
			RS.RemoteEvents.EquipBrainrot:FireServer(card.Name)
			mock.context = "server"
			frames(0.3)
		end
		local function heldTool()
			local tool = adamChar3:FindFirstChildOfClass("Tool")
			return tool and tool:GetAttribute("ItemId") and tool or nil
		end
		equip()
		check(heldTool() ~= nil, "la carte devrait être en main")
		mock.context = "client"
		RS.RemoteEvents.StoreCard:FireServer()
		mock.context = "server"
		frames(0.3)
		check(heldTool() == nil and card.Parent == adam2.Brainrots, "touche G : la carte devrait retourner dans le sac")

		-- donner la carte à Bob (1 rebirth d'écart : OK)
		local giftPrompt = bobChar4.HumanoidRootPart:FindFirstChild("GiftPrompt")
		check(giftPrompt ~= nil and giftPrompt.HoldDuration == 3, "chaque joueur devrait avoir un bouton Donner la carte (maintenir E 3 s)")
		equip()
		adamChar3:PivotTo(bobChar4.HumanoidRootPart.CFrame * mock.CFrame.new(0, 0, 4))
		frames(0.2)
		if giftPrompt then mock.getSignal(giftPrompt, "Triggered"):Fire(adam2) end
		frames(0.3)
		check(card.Parent == bob4.Brainrots, "Bob devrait avoir reçu la carte")
		-- trop d'écart de rebirths : refusé
		chat(adam2, "/rebirths 6")
		chat(adam2, "/give tralalero")
		for _, item in ipairs(adam2.Brainrots:GetChildren()) do
			if item.Value == "Tralalero Tralala" and (item:GetAttribute("Slot") or 0) == 0 then card = item end
		end
		equip()
		adamChar3:PivotTo(bobChar4.HumanoidRootPart.CFrame * mock.CFrame.new(0, 0, 4))
		frames(0.2)
		if giftPrompt then mock.getSignal(giftPrompt, "Triggered"):Fire(adam2) end
		frames(0.3)
		check(card.Parent == adam2.Brainrots, "on ne doit pas pouvoir donner une carte avec plus de 3 rebirths d'écart")
	end
end

-- ====== 36. Shop en catégories ======
do
	local shopWindow = hud:FindFirstChild("Shop")
	local pages = shopWindow and shopWindow:FindFirstChild("ShopPages", true)
	local sections = 0
	for _, child in ipairs(pages and pages:GetChildren() or {}) do
		if child.Name:sub(1, 5) == "Page_" then sections += 1 end
	end
	check(pages ~= nil and pages:IsA("ScrollingFrame") and sections == 5, "le shop devrait être une page qui défile avec 5 catégories")
	check(pages and pages.Page_boosters.Visible and pages.Page_vip.Visible, "toutes les catégories sont sur la même page")
	check(pages and pages.Page_boosters.LayoutOrder > pages.Page_vip.LayoutOrder and pages.Page_minerals.LayoutOrder > pages.Page_pass.LayoutOrder, "les catégories devraient être dans l'ordre")
	local tab = shopWindow and shopWindow:FindFirstChild("Tab_boosters", true)
	check(tab ~= nil, "les onglets raccourcis devraient être là")
	if tab then click(tab) end
end

-- ====== 34. Les rayons de la roue restent sur la roue ======
do
	local wheelModel = workspace.FortuneWheel
	frames(1)
	local haloHome = wheelModel:GetAttribute("HaloCFrame")
	local center = wheelModel.Halo.HaloCenter
	check(haloHome ~= nil and (center.Position - haloHome.Position).Magnitude < 0.5, "les rayons de la roue ne doivent pas quitter la roue")
	for _, ray in ipairs(wheelModel.Halo:GetChildren()) do
		check((ray.Position - haloHome.Position).Magnitude < 25, "un rayon de la roue est parti loin de la roue")
	end
	local pointerHome = wheelModel:GetAttribute("PointerCFrame")
	check(pointerHome ~= nil and (wheelModel.PointerModel.PointerPivot.Position - pointerHome.Position).Magnitude < 0.5, "la flèche de la roue doit rester en haut de la roue")
end

-- ====== RESULTATS ======
print("\n===== ERREURS DE SCRIPT (" .. #mock.errors .. ") =====")
local seen = {}
for _, err in ipairs(mock.errors) do
	local key = err:sub(1, 300)
	if not seen[key] then
		seen[key] = true
		print(err)
		print("---")
	end
end
print("\n===== TESTS ÉCHOUÉS (" .. #failures .. ") =====")
for _, f in ipairs(failures) do
	print(" - " .. f)
end
local warnSeen = {}
print("\n===== AVERTISSEMENTS =====")
for _, w in ipairs(mock.warnings) do
	if not warnSeen[w] then
		warnSeen[w] = true
		print(" ~ " .. w)
	end
end
