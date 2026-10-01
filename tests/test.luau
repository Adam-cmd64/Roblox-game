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
	-- les vrais ID Robux sont remis à 0 pour les tests : les achats sont alors gratuits (mode Studio)
	source = (source:gsub("GamePassId = %d+", "GamePassId = 0"))
	source = (source:gsub("ProductId = %d+", "ProductId = 0"))
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
module(RS, "Translator", "src/ReplicatedStorage/Translator.lua")

local SSS = mock.getService("ServerScriptService")
local serverScript = new("Script", "BrainrotServer", SSS)
for _, name in ipairs({"Remotes", "PlayerData", "Loot", "MineManager", "BaseManager", "ShopManager", "Monetization", "TradeManager", "WorldBuilder", "AdminCommands", "PickaxeBuilder", "BatManager", "WheelManager", "Serials", "CarpetManager", "GrappleManager", "LeaderboardManager", "DailyManager", "VipManager", "StarterChest", "FusionManager", "World2Builder", "PortalManager"}) do
	module(serverScript, name, "src/ServerScriptService/BrainrotServer/" .. name .. ".lua")
end

local SP = mock.getService("StarterPlayer")
local SPS = new("StarterPlayerScripts", "StarterPlayerScripts", SP)
local clientScript = new("LocalScript", "BrainrotClient", SPS)
for _, name in ipairs({"UIKit", "Hud", "Panels", "Trade", "Mining", "World", "Sounds", "Effects", "Wheel", "Sky", "Carpet", "Hack", "Grapple", "Carry", "Daily", "Settings", "Vip", "Guide", "Gift", "Pointer", "CardPicker", "Fusion", "Portal"}) do
	module(clientScript, name, "src/StarterPlayer/StarterPlayerScripts/BrainrotClient/" .. name .. ".lua")
end

-- ====== 1. Démarrage du serveur ======
mock.runScript(serverScript, "src/ServerScriptService/BrainrotServer/init.server.lua", "server")
mock.runFor(1)
-- où on les trouve : les brainrots du MONDE 2 ne sortent que de la mine du monde 2 ; Galaxie seulement dans le monde 2 ; Lave plus du tout
do
	local LootMod = mock.moduleCache.server[serverScript.Loot].value
	local GC = mock.moduleCache.server[RS.GameConfig].value
	local world1, world2, booster, wheel = {}, {}, {}, {}
	for _ = 1, 400 do
		for _, rarity in ipairs({"Légendaire", "Cosmique", "Épique", "God", "Commun"}) do
			world1[LootMod.rollCardOfRarity(rarity, "Mine", 1)] = true
			world2[LootMod.rollCardOfRarity(rarity, "Mine", 2)] = true
			booster[LootMod.rollCardOfRarity(rarity, "Booster")] = true
			wheel[LootMod.rollCardOfRarity(rarity, "Wheel")] = true
		end
	end
	local leak
	for _, c in ipairs(GC.NEW_CARDS) do
		if world1[c.Name] or booster[c.Name] or wheel[c.Name] then leak = c.Name end
	end
	check(leak == nil, "un brainrot du monde 2 sort ailleurs que dans la mine du monde 2 : " .. tostring(leak))
	check(world2["Aranciotto Baffuto"] and world2["Bombardino Grigio"] and world2["Bidone Zebrato"], "les brainrots du monde 2 devraient sortir de la mine du monde 2")
	check(world1["Leonelli Cactuselli"] and not world2["Leonelli Cactuselli"], "dans le monde 2, on tombe sur les brainrots du monde 2 quand il y en a")
	local galaxy1, galaxy2, lava = 0, 0, 0
	for _ = 1, 20000 do
		local m1 = LootMod.rollMutation(1e6, true, 1)
		local m2 = LootMod.rollMutation(1e6, true, 2)
		if m1 == "Galaxie" then galaxy1 += 1 end
		if m2 == "Galaxie" then galaxy2 += 1 end
		if m1 == "Lave" or m2 == "Lave" then lava += 1 end
	end
	check(galaxy1 == 0 and galaxy2 > 0, "Galaxie : seulement dans le monde 2 (" .. galaxy1 .. " / " .. galaxy2 .. ")")
	check(lava == 0, "la mutation Lave ne doit plus sortir")
end
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
local GC0 = mock.moduleCache.server[RS.GameConfig].value
local configCards = {}
for _, c in ipairs(GC0.CARDS) do
	if c.Atlas <= 3 then table.insert(configCards, c) end -- les autres ont leur propre image (cartes4 / cartes5)
end
check(#configCards == #IMAGE_ORDER - 1, "il devrait y avoir " .. (#IMAGE_ORDER - 1) .. " cartes dans les 3 premières images (" .. #configCards .. ")")
for i, name in ipairs(IMAGE_ORDER) do
	local c = GC0.getCard(name)
	if name == "Pesciolone Panciuto" then
		check(c and c.Atlas == 5 and c.Cell == 0, "Pesciolone Panciuto devrait avoir sa nouvelle image (cartes5, case 0)")
	else
		check(c and c.Atlas == (i - 1) // 12 + 1 and c.Cell == (i - 1) % 12, "carte " .. name .. " : mauvaise place dans les images")
	end
end
-- AUCUN doublon : jamais 2 brainrots sur la même image
local usedCells = {}
local allArt = table.clone(GC0.CARDS)
for _, soon in ipairs(GC0.COMING_SOON) do table.insert(allArt, soon) end
for _, c in ipairs(allArt) do
	local key = c.Atlas .. ":" .. c.Cell
	check(usedCells[key] == nil, "doublon d'image : " .. c.Name .. " et " .. tostring(usedCells[key]))
	usedCells[key] = c.Name
	check(GC0.getCard(c.Name) == nil or GC0.getComingSoon(c.Name) == nil, c.Name .. " ne peut pas être obtenable ET bientôt")
end
check(#GC0.NEW_CARDS == 11 and #GC0.COMING_SOON == 0, "les 11 brainrots d'hier sont débloqués dans le monde 2")

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

-- Boutons du menu (dans un 2e écran, au-dessus des fenêtres)
local menuGui = adam.PlayerGui:FindFirstChild("BrainrotMenu")
local menu = menuGui and menuGui:FindFirstChild("Menu")
check(menu ~= nil, "menu introuvable")
local topBar = menuGui and menuGui:FindFirstChild("TopBar")
check(topBar ~= nil and topBar:FindFirstChild("MineButton") ~= nil and topBar:FindFirstChild("BaseButton") ~= nil and topBar:FindFirstChild("WorldBadge") ~= nil,
	"en haut : MINE à gauche du monde, BASE à droite")
if topBar and topBar:FindFirstChild("MineButton") then
	check(topBar.MineButton.Position.X.Scale < topBar.WorldBadge.Position.X.Scale and topBar.BaseButton.Position.X.Scale > topBar.WorldBadge.Position.X.Scale, "MINE à gauche, BASE à droite du badge du monde")
end
local mineTimer = hud:FindFirstChild("MineTimer")
check(mineTimer ~= nil and mineTimer.AnchorPoint.X == 1 and mineTimer.AnchorPoint.Y == 1, "le minuteur de la mine devrait être en bas à droite")
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
-- on passe d'un menu à l'autre sans fermer : Sac ouvert → clic sur Index → l'Index remplace le Sac
if menu then
	local bagButton, indexButton
	for _, button in ipairs(menu:GetChildren()) do
		if button:IsA("TextButton") and button.LayoutOrder == 1 then bagButton = button end
		if button:IsA("TextButton") and button.LayoutOrder == 2 then indexButton = button end
	end
	for _, child in ipairs(hud:GetChildren()) do
		if child:IsA("TextButton") then child.Visible = false end
	end
	if bagButton and indexButton then
		click(bagButton)
		click(indexButton)
		local opened = {}
		for _, child in ipairs(hud:GetChildren()) do
			if child:IsA("TextButton") and child.Visible then table.insert(opened, child.Name) end
		end
		check(#opened == 1 and opened[1] == "Index", "cliquer sur Index avec le Sac ouvert devrait passer directement à l'Index (" .. table.concat(opened, ", ") .. ")")
		click(indexButton)
	end
end

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
	if b:IsA("TextButton") and b.LayoutOrder == 1 then bagButton = b end
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
local placedCard = mock.moduleCache.server[RS.GameConfig].value.getCard(placedName)
local expectedAtlas = placedCard and ATLAS_IDS[placedCard.Atlas]
local layout = mock.moduleCache.server[RS.GameConfig].value.CARD_ATLAS_LAYOUT
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
	if b:IsA("TextButton") and b.LayoutOrder == 3 then rebirthButton = b end
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
do
	-- le pseudo sur la poutre du rez-de-chaussée ne doit pas être caché par la dalle de l'étage 1
	local beam, slab = myPlot:FindFirstChild("FrontBeam"), myPlot.Level1:FindFirstChild("Slab")
	if beam and slab then
		local look = beam.CFrame.LookVector
		local beamFront = beam.Position:Dot(look) + beam.Size.Z / 2
		local slabFront = slab.Position:Dot(look) + slab.Size.Z / 2
		check(beamFront > slabFront, "la poutre avec le pseudo doit dépasser devant la dalle de l'étage (sinon le pseudo est caché)")
	end
end
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

-- ====== 9b. MACHINE DE FUSION (3 brainrots -> 1 fusionné +10 %) + sélecteur trié + échange avec ➕ ======
do
	local GCfg = mock.moduleCache.server[RS.GameConfig].value
	local machine = workspace:FindFirstChild("FusionMachine")
	check(machine ~= nil, "la Machine de Fusion devrait être construite dans le monde")
	local fusionPrompt = machine and machine:FindFirstChild("FusionPrompt", true)
	check(fusionPrompt ~= nil, "la machine devrait avoir un bouton E")
	-- rien d'autre (arbres, statues) ne doit pousser sur la machine
	local nature = workspace.Decor:FindFirstChild("Nature")
	local blocked = 0
	for _, part in ipairs(nature and nature:GetDescendants() or {}) do
		if part:IsA("BasePart") then
			local offset = part.Position - GCfg.FUSION.Position
			if mock.Vector3.new(offset.X, 0, offset.Z).Magnitude < 18 then blocked += 1 end
		end
	end
	check(blocked == 0, "des arbres poussent dans la Machine de Fusion (" .. blocked .. ")")

	local before = {}
	for _, item in ipairs(adam.Brainrots:GetChildren()) do before[item] = true end
	chat(adam, "/give squalo")
	chat(adam, "/give topolino")
	chat(adam, "/give fragolone")
	frames(0.3)
	local fresh = {}
	for _, item in ipairs(adam.Brainrots:GetChildren()) do
		if not before[item] then table.insert(fresh, item) end
	end
	check(#fresh == 3, "il faudrait 3 nouvelles cartes pour la fusion (" .. #fresh .. ")")

	-- 3 raretés différentes : refusé (il faut la même rareté)
	chat(adam, "/give tralalero")
	frames(0.3)
	local epic
	for _, item in ipairs(adam.Brainrots:GetChildren()) do
		if item.Value == "Tralalero Tralala" and (item:GetAttribute("Slot") or 0) == 0 then epic = item end
	end
	adamChar:PivotTo(mock.CFrame.new(GCfg.FUSION.Position + mock.Vector3.new(10, 3, 0)))
	frames(0.2)
	mock.getSignal(RS.RemoteEvents.Fuse, "OnServerEvent"):Fire(adam, {fresh[1].Name, fresh[2].Name, epic.Name})
	frames(0.2)
	check(fresh[1].Parent ~= nil and fresh[2].Parent ~= nil and epic.Parent ~= nil and not GCfg.getFusion(fresh[1]), "on ne doit pas pouvoir fusionner des raretés différentes")
	-- trop loin : refusé
	adamChar:PivotTo(mock.CFrame.new(GCfg.FUSION.Position + mock.Vector3.new(200, 3, 0)))
	frames(0.2)
	local ids = {}
	for _, item in ipairs(fresh) do table.insert(ids, item.Name) end
	mock.getSignal(RS.RemoteEvents.Fuse, "OnServerEvent"):Fire(adam, ids)
	frames(0.2)
	check(fresh[1].Parent ~= nil and fresh[2].Parent ~= nil and fresh[3].Parent ~= nil, "on ne doit pas pouvoir fusionner loin de la machine")

	-- devant la machine : bouton E -> la fenêtre s'ouvre
	adamChar:PivotTo(mock.CFrame.new(GCfg.FUSION.Position + mock.Vector3.new(10, 3, 0)))
	frames(0.2)
	local fusionWindow = hud:FindFirstChild("Machine de Fusion")
	check(fusionWindow ~= nil, "il manque la fenêtre de la Machine de Fusion")
	if fusionPrompt then mock.getSignal(fusionPrompt, "Triggered"):Fire(adam) end
	frames(0.4)
	check(fusionWindow and fusionWindow.Visible, "le bouton E de la machine devrait ouvrir la fenêtre")
	check(fusionWindow and fusionWindow:FindFirstChild("Explain", true) ~= nil, "il manque la phrase d'explication en haut")
	local picker = adam.PlayerGui:FindFirstChild("BrainrotPicker")
	check(picker ~= nil, "il manque le sélecteur de cartes")

	-- chaque case "+" ouvre le sac (trié par rareté) ; on choisit nos 3 cartes
	local function pickerTiles()
		local list = {}
		for _, tile in ipairs(picker:FindFirstChild("Cards", true):GetChildren()) do
			if tile.Name == "PickTile" then table.insert(list, tile) end
		end
		table.sort(list, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		return list
	end
	for index, item in ipairs(fresh) do
		click(fusionWindow:FindFirstChild("Slot" .. index, true))
		check(picker.Enabled, "cliquer sur + devrait ouvrir le sac")
		check(fusionWindow.Visible, "le sac s'ouvre PAR-DESSUS la machine (elle reste ouverte)")
		local tiles = pickerTiles()
		if index == 1 then
			-- trié par rareté : jamais une rareté plus haute après une plus basse
			local sorted = true
			for i = 2, #tiles do
				local a = GCfg.getCard(adam.Brainrots:FindFirstChild(tiles[i - 1]:GetAttribute("ItemId")).Value)
				local b = GCfg.getCard(adam.Brainrots:FindFirstChild(tiles[i]:GetAttribute("ItemId")).Value)
				if GCfg.RARITIES[a.Rarity].Order < GCfg.RARITIES[b.Rarity].Order then sorted = false end
			end
			check(#tiles >= 3 and sorted, "le sac du sélecteur devrait être trié par rareté")
		end
		local target
		for _, tile in ipairs(tiles) do
			if tile:GetAttribute("ItemId") == item.Name then target = tile end
			check(index == 1 or tile:GetAttribute("ItemId") ~= fresh[1].Name, "une carte déjà dans la machine ne doit plus être proposée")
		end
		check(target ~= nil, "la carte devrait être dans le sélecteur")
		if target then click(target:FindFirstChild("Pick")) end
		check(not picker.Enabled, "choisir une carte devrait refermer le sac")
	end
	local previewLabel = fusionWindow:FindFirstChild("Preview", true)
	local expected = math.floor((GCfg.getItemValue(fresh[1]) + GCfg.getItemValue(fresh[2]) + GCfg.getItemValue(fresh[3])) * 1.1)
	check(previewLabel and string.find(previewLabel.Text, "$" .. GCfg.format(expected), 1, true) ~= nil, "l'aperçu devrait montrer le revenu fusionné (" .. (previewLabel and previewLabel.Text or "?") .. ")")
	check(fusionWindow:FindFirstChild("Result", true):FindFirstChild("FusionTag", true) ~= nil, "l'aperçu devrait montrer la carte FUSION")

	click(fusionWindow:FindFirstChild("FuseButton", true))
	frames(0.5)
	local kept = {}
	for _, item in ipairs(fresh) do
		if item.Parent == adam.Brainrots then table.insert(kept, item) end
	end
	check(#kept == 1, "la fusion devrait garder 1 carte sur 3 (" .. #kept .. ")")
	local fused = kept[1]
	check(fused and fused.Value == "Squalo Cubetto", "la carte gardée devrait être la meilleure des 3")
	check(fused and fused:GetAttribute("FusionIncome") == expected and fused:GetAttribute("FusionLevel") == 1, "le revenu fusionné devrait être la somme des 3 + 10 %")
	check(fused and GCfg.getItemValue(fused) == expected, "getItemValue devrait donner le revenu fusionné")
	print("Fusion : 3 cartes ->", fused and fused.Value, "revenu", fused and fused:GetAttribute("FusionIncome"), "niveau", fused and fused:GetAttribute("FusionLevel"))
	check(fusionWindow:FindFirstChild("Reveal", true).Visible, "la carte fusionnée devrait être montrée")
	-- les cartes fusionnées se revendent plus cher et gardent le badge dans le sac
	check(fused and GCfg.getItemSellPrice(fused) > GCfg.getSellPrice("Squalo Cubetto", "Normal"), "une carte fusionnée devrait se vendre plus cher")
	local closeFusion = fusionWindow:FindFirstChild("X", true)
	for _, child in ipairs(fusionWindow:GetDescendants()) do
		if child:IsA("TextButton") and child.Text == "X" then closeFusion = child end
	end
	if closeFusion then click(closeFusion) end
	check(not fusionWindow.Visible, "la croix devrait fermer la machine")

	-- sac normal : trié par rareté aussi, et la carte fusionnée a son badge
	local PanelsMod = mock.moduleCache.client[clientScript.Panels].value
	mock.context = "client"
	PanelsMod.inventory.open()
	mock.context = "server"
	frames(0.2)
	local invWindow = hud:FindFirstChild("Sac")
	check(invWindow and invWindow:FindFirstChild("FusionTag", true) ~= nil, "la carte fusionnée devrait avoir le badge FUSION dans le sac")
	mock.context = "client"
	PanelsMod.inventory.close()
	mock.context = "server"

	-- ÉCHANGE : la case ➕ ouvre le grand sac trié ; la carte choisie part dans l'offre
	mock.context = "client"
	RS.RemoteEvents.TradeRequest:FireServer(bob)
	mock.context = "server"
	frames(0.2)
	mock.getSignal(RS.RemoteEvents.TradeRespond, "OnServerEvent"):Fire(bob, adam, true)
	frames(0.3)
	local tradeWindow
	for _, child in ipairs(hud:GetChildren()) do
		if child.Name == "Échange" and child:FindFirstChild("MyOffer", true) then tradeWindow = child end
	end
	check(tradeWindow and tradeWindow.Visible, "la fenêtre d'échange devrait s'ouvrir")
	local addTile = tradeWindow and tradeWindow:FindFirstChild("AddCard", true)
	check(addTile ~= nil, "l'échange devrait avoir la case ➕ AJOUTER")
	check(tradeWindow and tradeWindow:FindFirstChild("TradeHint", true) ~= nil, "l'échange n'a plus de petit sac en bas, juste une phrase d'aide")
	if addTile then click(addTile) end
	check(picker.Enabled and tradeWindow.Visible, "➕ devrait ouvrir le sac par-dessus l'échange")
	local tiles = pickerTiles()
	local chosenId = tiles[1] and tiles[1]:GetAttribute("ItemId")
	if tiles[1] then click(tiles[1]) end
	frames(0.3)
	local offerCards = 0
	for _, child in ipairs(tradeWindow:FindFirstChild("MyOffer", true):GetChildren()) do
		if child.Name == "OfferCard" then offerCards += 1 end
	end
	check(chosenId ~= nil and offerCards == 1, "la carte choisie devrait être dans mon offre (" .. offerCards .. ")")
	-- la machine refuse pendant un échange
	mock.getSignal(RS.RemoteEvents.Fuse, "OnServerEvent"):Fire(adam, {fused.Name, fused.Name, fused.Name})
	mock.context = "client"
	RS.RemoteEvents.TradeAction:FireServer("cancel")
	mock.context = "server"
	frames(0.3)
	check(not tradeWindow.Visible, "annuler devrait fermer l'échange")
end

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
local fusionKept = false
for _, item in ipairs(adam2.Brainrots:GetChildren()) do
	if item.Value == "Squalo Cubetto" and (item:GetAttribute("FusionLevel") or 0) == 1 and (item:GetAttribute("FusionIncome") or 0) > 12 then fusionKept = true end
end
check(fusionKept, "la carte fusionnée n'a pas été sauvegardée")


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
local lockedBefore = (plotB:GetAttribute("LockedUntil") or 0) - mock.now
playHack(true)
local lockedAfter = (plotB:GetAttribute("LockedUntil") or 0) - mock.now
check(lockedAfter > 0, "un piratage réussi ne coupe plus les lasers d'un coup")
check(lockedAfter < lockedBefore - 5, "un piratage réussi devrait enlever du temps de verrouillage (" .. lockedBefore .. " -> " .. lockedAfter .. ")")
mock.getSignal(hackPrompt, "Triggered"):Fire(adam2)
frames(0.3)
check(hud:FindFirstChild("HackGame") == nil, "après un piratage réussi, il faut attendre 1 minute avant de repirater")
frames(62) -- la minute d'attente passe (et les lasers de Bob finissent par s'éteindre)
check((plotB:GetAttribute("LockedUntil") or 0) <= mock.now, "les lasers finissent par s'éteindre")
mock.getSignal(lockPrompt, "Triggered"):Fire(bob2)
frames(0.5)
playHack(false)
check(plotB:GetAttribute("LockedUntil") > mock.now, "un piratage raté ne doit pas ouvrir la base")
mock.getSignal(hackPrompt, "Triggered"):Fire(adam2)
frames(0.3)
check(hud:FindFirstChild("HackGame") == nil, "après un échec, il faut attendre 2 minutes")

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
-- avec le brainrot volé en main, Bob ne peut pas se téléporter chez lui (ni à la mine)
do
	local before = bobChar2.HumanoidRootPart.Position
	for _, destination in ipairs({"base", "mine"}) do
		mock.getSignal(RS.RemoteEvents.Teleport, "OnServerEvent"):Fire(bob2, destination)
	end
	frames(0.2)
	check((bobChar2.HumanoidRootPart.Position - before).Magnitude < 2 and bob2:GetAttribute("Carrying") ~= nil, "on ne doit pas pouvoir se téléporter avec un brainrot volé")
end
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
for _, name in ipairs({"cartonino", "sassolino", "teierina", "bottiglione", "riccio", "bidone"}) do
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
check(RS:FindFirstChild("ToolPreviews") ~= nil and RS.ToolPreviews:FindFirstChild("Grapple_1") ~= nil and RS.ToolPreviews:FindFirstChild("Bat_5") ~= nil and RS.ToolPreviews:FindFirstChild("Pickaxe_10") ~= nil, "les modèles 3D du shop (grappins, battes) devraient être prêts")
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
-- le grappin renforcé demande 3 rebirths (comme les pioches)
do
	local savedRebirths = adam2.leaderstats.Rebirths.Value
	adam2.leaderstats.Rebirths.Value = 2
	chat(adam2, "/cash 1m")
	mock.context = "client"
	RS.RemoteEvents.BuyGrapple:FireServer(2)
	mock.context = "server"
	frames(0.3)
	check(adam2.GrappleTier.Value == 1, "le grappin renforcé ne doit pas s'acheter avant 3 rebirths")
	adam2.leaderstats.Rebirths.Value = 3
	mock.context = "client"
	RS.RemoteEvents.BuyGrapple:FireServer(2)
	mock.context = "server"
	frames(0.3)
	check(adam2.GrappleTier.Value == 2, "avec 3 rebirths, le grappin renforcé devrait s'acheter")
	adam2.GrappleTier.Value = 1
	adam2.leaderstats.Rebirths.Value = savedRebirths
end

-- ====== 21. Portail + boutique ======
check(workspace:FindFirstChild("Portal", true) ~= nil, "le portail devrait être dans la carte")
local shopPickaxes = 0
for _, child in ipairs(workspace.Shop:GetChildren()) do
	for _, data in ipairs(GameConfigModule.PICKAXES) do
		if child:IsA("Model") and child.Name == data.Name then shopPickaxes += 1 end
	end
end
check(shopPickaxes == 10, "les 10 pioches du monde 1 devraient être exposées à la boutique (" .. shopPickaxes .. ")")
local crystalPickaxes = 0
for _, child in ipairs(workspace.CrystalShop:GetChildren()) do
	for _, data in ipairs(GameConfigModule.PICKAXES) do
		if child:IsA("Model") and child.Name == data.Name and data.World == 2 then crystalPickaxes += 1 end
	end
end
check(crystalPickaxes == 8, "les 8 pioches de cristal devraient être exposées à la Cristallerie (" .. crystalPickaxes .. ")")

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
	-- le menu des récompenses s'ouvre tout seul à l'arrivée dans le jeu ; le 6e bouton du menu = ⛏️ Pioches (téléportation)
	local pickaxesButton
	for _, label in ipairs(menuGui:GetDescendants()) do
		if label:IsA("TextLabel") and label.Text == "Pioches" and label.Parent:IsA("TextButton") then pickaxesButton = label.Parent end
	end
	check(pickaxesButton ~= nil, "il devrait y avoir le bouton ⛏️ Pioches à la place de Cadeaux")
	local shopModel = workspace:FindFirstChild("Shop")
	mock.localPlayer = adam2
	if pickaxesButton then click(pickaxesButton) end
	frames(0.3)
	local adamRoot = adam2.Character and adam2.Character:FindFirstChild("HumanoidRootPart")
	check(adamRoot and shopModel and (adamRoot.Position - shopModel:GetPivot().Position).Magnitude < 40, "le bouton Pioches devrait téléporter à la boutique de pioches")
	if dailyWindow then dailyWindow.Visible = false end
	mock.context = "client"
	mock.moduleCache.client[clientScript.Daily].value.window.open()
	mock.context = "server"
	frames(0.3)
	check(dailyWindow and dailyWindow.Visible, "le menu des récompenses devrait s'ouvrir")
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
	check(coming == 4, "l'Index devrait montrer 4 cartes BIENTÔT (" .. coming .. ")")
	print("Index : cartes mystère (silhouettes) =", mystery)
end

-- ====== 29. Paramètres ======
do
	local settingsButton = adam.PlayerGui:FindFirstChild("SettingsButton", true)
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
	for _, label in ipairs(menuGui:GetDescendants()) do
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
	-- une vieille sauvegarde où l'argent avait débordé (devenu négatif) est réparée
	local bobSave = mock.stores[storeName]["u_2"]
	if bobSave then bobSave.Cash = 8e18 - 2 ^ 64 end
	local bob3 = addPlayer("Bob", 2)
	frames(1)
	check(bob3.leaderstats.Cash:IsA("NumberValue"), "l'argent doit être un NumberValue (un IntValue devient négatif après 9,2 Qi)")
	if bobSave then
		check(bob3.leaderstats.Cash.Value > 7e18, "l'argent négatif d'une vieille sauvegarde devrait être réparé (" .. tostring(bob3.leaderstats.Cash.Value) .. ")")
	end
	bob3.leaderstats.Cash.Value = 9e18
	bob3.leaderstats.Cash.Value += 9e18
	check(bob3.leaderstats.Cash.Value > 1e19, "l'argent ne doit plus déborder")
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
	-- (Adam et Bob ont la collecte auto grâce au VIP : 1 seconde de revenus peut arriver juste après)
	local adamIncome = adam2:GetAttribute("Income") or 0
	local bobIncome = bob3:GetAttribute("Income") or 0
	check(bob3.leaderstats.Cash.Value >= 5000 and bob3.leaderstats.Cash.Value <= 5000 + bobIncome * 2 + 1 and adam2.leaderstats.Cash.Value >= 5000 and adam2.leaderstats.Cash.Value <= 5000 + adamIncome * 2 + 1, "/setcash @all 5k devrait viser tout le monde (" .. tostring(bob3.leaderstats.Cash.Value) .. ", " .. tostring(adam2.leaderstats.Cash.Value) .. ")")
	chat(adam2, "/rebirths @bob 0")
	check(bob3.leaderstats.Rebirths.Value == 0, "/rebirths @bob 0")
	chat(adam2, "/dex @bob")
	check(#bob3.Index:GetChildren() == #mock.moduleCache.server[RS.GameConfig].value.CARDS, "/dex @bob devrait débloquer tout l'Index")
	chat(adam2, "/unvip @bob")
	check(bob3:GetAttribute("VIP") == false, "/unvip @bob")
	-- sans @ aussi
	chat(adam2, "/vip Bob")
	check(bob3:GetAttribute("VIP") == true, "/vip Bob (sans @) devrait viser Bob")
	chat(adam2, "/unvip bob")
	check(bob3:GetAttribute("VIP") == false, "/unvip bob (sans @, en minuscules)")
	local before = #bob3.Brainrots:GetChildren()
	chat(adam2, "/give Bob tralalero")
	check(#bob3.Brainrots:GetChildren() == before + 1, "/give Bob tralalero (sans @) devrait donner à Bob")
	local adamBefore = #adam2.Brainrots:GetChildren()
	chat(adam2, "/give sahur")
	check(#adam2.Brainrots:GetChildren() == adamBefore + 1, "/give sahur (sans pseudo) reste pour moi")
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
	check(pages ~= nil and pages:IsA("ScrollingFrame") and sections == 6, "le shop devrait être une page qui défile avec 6 catégories")
	check(pages and pages.Page_boosters.Visible and pages.Page_vip.Visible, "toutes les catégories sont sur la même page")
	check(pages and pages.Page_boosters.LayoutOrder > pages.Page_vip.LayoutOrder and pages.Page_minerals.LayoutOrder > pages.Page_pass.LayoutOrder, "les catégories devraient être dans l'ordre")
	local tab = shopWindow and shopWindow:FindFirstChild("Tab_boosters", true)
	check(tab ~= nil, "les onglets raccourcis devraient être là")
	if tab then click(tab) end
	-- boosters : des paquets MYSTÈRE (on ne voit pas la carte dedans)
	local mysteries, upTo, cardsInPacks = 0, {}, 0
	for _, d in ipairs(pages and pages.Page_boosters:GetDescendants() or {}) do
		if d.Name == "Mystery" then mysteries += 1 end
		if d.Name == "UpTo" then table.insert(upTo, d.Text) end
		if d.Name == "CardName" then cardsInPacks += 1 end
	end
	check(mysteries == 6, "chaque booster devrait avoir son médaillon mystère (" .. mysteries .. ")")
	check(cardsInPacks == 0, "on ne doit plus voir de carte sur les boosters")
	check(upTo[#upTo] ~= nil and upTo[#upTo]:find("OG") ~= nil, "le Booster Céleste devrait annoncer « JUSQU'À : OG »")
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

-- ====== 41. Les chances de la roue sont affichées avant l'achat ======
do
	local GCfg = mock.moduleCache.server[RS.GameConfig].value
	local text = GCfg.getWheelOddsText()
	check(string.find(text, "Argent 32 %", 1, true) ~= nil and string.find(text, "Booster Galaxie 3 %", 1, true) ~= nil, "les chances de la roue devraient être écrites (" .. text .. ")")
	local shown = 0
	for _, d in ipairs(hud:GetDescendants()) do
		if d.Name == "WheelOdds" and d:IsA("TextLabel") and string.find(d.Text, "Jackpot", 1, true) then shown += 1 end
	end
	check(shown >= 2, "les chances de la roue devraient être affichées au shop ET dans la fenêtre de la roue (" .. shown .. ")")
end

-- ====== 39. Le guide des débutants disparaît après 5 minutes de jeu ======
do
	local guide = hud:FindFirstChild("Guide")
	local savedTier = adam.PickaxeTier.Value
	adam.PickaxeTier.Value = 1
	local savedRebirthsGuide = adam.leaderstats.Rebirths.Value
	adam.leaderstats.Rebirths.Value = 0
	adam:SetAttribute("PlayTime", 10)
	frames(0.3)
	check(guide ~= nil and guide.Visible, "au début, le guide des débutants devrait s'afficher")
	check(guide.AnchorPoint.X == 1, "le guide devrait être en haut à droite (vers ⚙️)")
	adam.leaderstats.Rebirths.Value = 1
	adam:SetAttribute("PlayTime", 11)
	frames(0.3)
	check(not guide.Visible, "un joueur qui a déjà fait un rebirth n'est plus un débutant : pas de guide")
	adam.leaderstats.Rebirths.Value = 0
	adam:SetAttribute("PlayTime", 12)
	frames(0.3)
	adam:SetAttribute("PlayTime", 301)
	frames(0.3)
	check(guide ~= nil and not guide.Visible, "après 5 minutes de jeu, le guide ne doit plus s'afficher")
	adam.leaderstats.Rebirths.Value = savedRebirthsGuide
	adam.PickaxeTier.Value = savedTier
	check(adam2:GetAttribute("PlayTime") ~= nil and adam2:GetAttribute("PlayTime") > 0, "le temps de jeu devrait être compté")
end

-- ====== 40. Version anglaise (joueurs non francophones) ======
do
	mock.context = "client"
	local Tr = mock.moduleCache.client[RS.Translator]
	Tr = Tr and Tr.value
	mock.context = "server"
	check(Tr ~= nil, "le module de traduction devrait être chargé par le client")
	if Tr then
		local cases = {
			{"Sac", "Bag"},
			{"🔒 Il faut 3 rebirth(s) pour la Batte en or", "🔒 You need 3 rebirth(s) for the Golden Bat"},
			{"Dégâts 300  •  Vitesse 7.1/s  •  Chance x9", "Damage 300  •  Speed 7.1/s  •  Luck x9"},
			{"JUSQU'À : TRÈS RARE", "UP TO: VERY RARE"},
			{"Base de Bob", "Base of Bob"},
			{"◆ Argent", "◆ Silver"},
			{"Argent x2", "Money x2"},
			{"Ordre", "Ordre"}, -- "Or" n'est remplacé que si c'est un mot entier
			{"Tung Tung Tung Sahur", "Tung Tung Tung Sahur"}, -- les noms des brainrots ne changent pas
			{"⚗️ Approche-toi de la Machine de Fusion", "⚗️ Get closer to the Fusion Machine"},
			{"Choisis un brainrot (2/3)", "Pick a brainrot (2/3)"},
		}
		for _, case in ipairs(cases) do
			local got = Tr.translate(case[1])
			check(got == case[2], "traduction de « " .. case[1] .. " » : « " .. tostring(got) .. " » au lieu de « " .. case[2] .. " »")
		end
		-- on active l'anglais : tout l'écran est traduit (et ce qui apparaît ensuite aussi)
		local savedLocal = mock.localPlayer
		mock.localPlayer = adam -- l'écran qu'on regarde dans ces tests est celui du premier Adam
		mock.context = "client"
		Tr.start(true)
		mock.context = "server"
		mock.localPlayer = savedLocal
		frames(0.3)
		local bagLabel, frenchLeft = false, {}
		for _, d in ipairs(adam.PlayerGui:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				if d.Text == "Bag" then bagLabel = true end
				for _, word in ipairs({"PRENDRE", "Récompenses du jour", "Paramètres", "Tes tours", "Machine de Fusion", "FUSIONNER", "Mets 3 brainrots", "Clique sur ➕"}) do
					if string.find(d.Text, word, 1, true) then table.insert(frenchLeft, d.Text) end
				end
			end
		end
		check(bagLabel, "en anglais, le bouton Sac devrait s'appeler Bag")
		check(#frenchLeft == 0, "il reste du français à l'écran : " .. table.concat(frenchLeft, " | "))
		chat(adam2, "/cash 1")
		frames(0.3)
	end
end

-- ====== 38. Collecte auto ======
do
	local plot
	for _, p in ipairs(workspace.Plots:GetChildren()) do
		if p:GetAttribute("OwnerId") == adam2.UserId then plot = p end
	end
	chat(adam2, "/autocollect")
	frames(0.3)
	check(adam2:GetAttribute("AutoCollect") == true, "/autocollect devrait donner la collecte auto")
	local before = adam2.leaderstats.Cash.Value
	frames(3)
	if plot and (adam2:GetAttribute("Income") or 0) > 0 then
		check(adam2.leaderstats.Cash.Value > before, "avec la collecte auto, l'argent de la base arrive tout seul")
		check((plot:GetAttribute("Pending") or 0) < 1, "avec la collecte auto, rien ne doit rester sur les boutons COLLECTER")
	end
end

-- ====== 37. Pioche Divine (/pioche) : tout casse en 1 coup ======
do
	local GCfg = mock.moduleCache.server[RS.GameConfig].value
	local MineM = mock.moduleCache.server[serverScript.MineManager].value
	adam2.PickaxeTier.Value = 1
	chat(adam2, "/pioche")
	frames(0.5)
	check(adam2:GetAttribute("DivinePickaxe") == true, "/pioche devrait donner la Pioche Divine")
	local tool = (adam2.Character and adam2.Character:FindFirstChild("Pioche")) or adam2.Backpack:FindFirstChild("Pioche")
	check(tool ~= nil and tool:FindFirstChild("Crystal") ~= nil and tool:FindFirstChild("Halo") ~= nil, "la Pioche Divine devrait avoir son cristal et son anneau de lumière")
	local pick = GCfg.getPlayerPickaxe(adam2)
	check(pick.Divine == true and pick.Damage == math.huge, "la Pioche Divine devrait faire des dégâts infinis")
	-- le bloc le plus dur de la mine casse en 1 coup, même avec la pioche en bois achetée
	local hardest
	for _, block in ipairs(blocks:GetChildren()) do
		if not hardest or (block:GetAttribute("MaxHP") or 0) > (hardest:GetAttribute("MaxHP") or 0) then hardest = block end
	end
	if hardest then
		local result, err = MineM.hit(hardest, pick.Damage, math.huge)
		check(result ~= nil and err == nil and hardest.Parent == nil, "la Pioche Divine devrait casser le bloc le plus dur en 1 coup")
	end
	chat(adam2, "/unpioche")
	frames(0.5)
	check(adam2:GetAttribute("DivinePickaxe") == nil and GCfg.getPlayerPickaxe(adam2).Name == GCfg.PICKAXES[1].Name, "/unpioche devrait remettre la pioche normale")
	-- les Secret sont bien plus rares qu'avant, même avec la meilleure pioche tout au fond
	local Loot = mock.moduleCache.server[serverScript.Loot].value
	local secrets = 0
	for _ = 1, 20000 do
		if Loot.rollRarity(22 * (1 + 59 * GCfg.MINE.LuckPerLayer), false) == "Secret" then secrets += 1 end
	end
	check(secrets < 40, "les Secret tombent trop souvent (" .. secrets .. " sur 20000)")
end

-- ====== 43. Numéros de tirage : réservés par paquets (moins de demandes au DataStore) ======
do
	local PD = mock.moduleCache.server[serverScript.PlayerData].value
	local callsBefore = mock.updateCalls or 0
	local serials = {}
	for _ = 1, 30 do
		local item = PD.addItem(adam2, "Cartonino Scatolino", "Normal", 0, nil, "a miné")
		serials[item:GetAttribute("Serial")] = true
	end
	local unique = 0
	for _ in pairs(serials) do unique += 1 end
	check(unique == 30, "30 cartes communes devraient avoir 30 numéros différents (" .. unique .. ")")
	local calls = (mock.updateCalls or 0) - callsBefore
	check(calls <= 6, "les numéros des cartes communes devraient être réservés par paquets (" .. calls .. " demandes au DataStore pour 30 cartes)")
end

-- ====== 45. Compte à rebours du portail ======
do
	local anchor = workspace:FindFirstChild("PortalTitle", true)
	local countdown = anchor and anchor:FindFirstChild("Countdown", true)
	check(countdown ~= nil and anchor:GetAttribute("OpensAt") ~= nil, "le portail devrait avoir un compte à rebours")
	frames(1)
	check(countdown ~= nil and countdown.Text ~= "12:00:00", "le compte à rebours devrait se mettre à jour tout seul")
	local W = mock.moduleCache.client[clientScript.World].value
	local caption = anchor and anchor:FindFirstChild("Caption", true)
	if countdown and caption then
		W.updatePortal(countdown, caption, 12 * 3600)
		check(countdown.Text == "12:00:00", "12 h avant : 12:00:00 (" .. countdown.Text .. ")")
		W.updatePortal(countdown, caption, 3 * 3600 + 25 * 60 + 7)
		check(countdown.Text == "03:25:07", "3 h 25 min 7 s avant : 03:25:07 (" .. countdown.Text .. ")")
		W.updatePortal(countdown, caption, -5)
		check(countdown.Text == "✦ MONDE 2 ✦" or countdown.Text == "✦ WORLD 2 ✦", "après l'heure : le portail est OUVERT (" .. countdown.Text .. ")") -- (l'anglais est activé plus haut)
	end
end

-- ====== 44. PACK LIMITED ======
do
	local GCfg = mock.moduleCache.server[RS.GameConfig].value
	local Loot = mock.moduleCache.server[serverScript.Loot].value
	check(#GCfg.getCardsOfRarity("Limited") == 4, "il devrait y avoir 4 cartes Limited")
	check(GCfg.RARITIES.Limited and GCfg.RARITIES.Limited.Weight == 0, "les Limited ne doivent jamais sortir de la mine")
	-- jamais dans la mine, même avec une chance énorme
	local minedLimited = 0
	for _ = 1, 5000 do
		if Loot.rollRarity(500, true) == "Limited" then minedLimited += 1 end
	end
	check(minedLimited == 0, "une carte Limited ne doit jamais sortir de la mine")
	-- les chances du pack : 50 / 35 / 14 / 1 %
	local counts = {}
	for _ = 1, 20000 do
		local name = Loot.rollLimited()
		counts[name] = (counts[name] or 0) + 1
	end
	local function pct(name) return (counts[name] or 0) / 200 end
	check(math.abs(pct("Cappuccina Principessa") - 50) < 2.5 and math.abs(pct("Gattino Smeraldino") - 35) < 2.5
		and math.abs(pct("Ranapesce Gigante") - 14.5) < 2 and pct("Gorillo Avocadillo") > 0.1 and pct("Gorillo Avocadillo") < 1.2,
		"les chances du pack Limited devraient être 50 / 35 / 14,5 / 0,5 % (" .. pct("Cappuccina Principessa") .. " / " .. pct("Gattino Smeraldino") .. " / " .. pct("Ranapesce Gigante") .. " / " .. pct("Gorillo Avocadillo") .. ")")
	-- revenus demandés
	check(GCfg.getCard("Cappuccina Principessa").Income == 30e6 and GCfg.getCard("Gattino Smeraldino").Income == 60e6
		and GCfg.getCard("Ranapesce Gigante").Income == 110e6 and GCfg.getCard("Gorillo Avocadillo").Income == 200e6, "revenus des Limited : 30M, 60M, 110M, 200M")
	-- prix des offres
	check(GCfg.getLimitedOffer("Limited1").Price == 80 and GCfg.getLimitedOffer("Limited5").Price == 450 and GCfg.getLimitedOffer("Limited10").Price == 699, "prix des packs : 80 / 450 / 699")
	-- achat de 10 packs (gratuit en mode Studio) : 10 cartes Limited numérotées
	local before = {}
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do before[item] = true end
	mock.getSignal(RS.RemoteEvents.BuyBooster, "OnServerEvent"):Fire(adam2, "Limited10")
	frames(0.5)
	local got, numbered = 0, 0
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do
		if not before[item] then
			local card = GCfg.getCard(item.Value)
			if card and card.Rarity == "Limited" then got += 1 end
			if (item:GetAttribute("Serial") or 0) > 0 then numbered += 1 end
		end
	end
	check(got == 10 and numbered == 10, "10 packs Limited devraient donner 10 cartes Limited numérotées (" .. got .. ", " .. numbered .. ")")
	-- vendre « tout » en Limited ne fait rien
	mock.getSignal(RS.RemoteEvents.SellAll, "OnServerEvent"):Fire(adam2, "Limited")
	frames(0.3)
	local left = 0
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do
		if not before[item] then left += 1 end
	end
	check(left == 10, "les cartes Limited ne doivent pas se vendre en lot")
	-- la boutique : 4 cartes + 3 offres, la meilleure avec l'ancien prix barré
	local banner = hud:FindFirstChild("LimitedBanner", true)
	local shown, offers = 0, 0
	for _, d in ipairs(banner and banner:GetDescendants() or {}) do
		if d.Name == "LimitedCard" then shown += 1 end
		if d:IsA("TextButton") and string.sub(d.Name, 1, 7) == "Limited" then offers += 1 end
	end
	check(shown == 4 and offers == 3, "la section Limited devrait montrer 4 cartes et 3 offres (" .. shown .. ", " .. offers .. ")")
	check(banner and banner:FindFirstChild("Discount", true) ~= nil and banner:FindFirstChild("OldPrice", true) ~= nil, "l'offre 10 packs devrait avoir le prix barré et la remise")
	-- le design Limited
	mock.context = "client"
	local CR = mock.moduleCache.client[RS.CardRenderer].value
	local limitedCard = CR.create("Gorillo Avocadillo", "Normal", nil, 7)
	local normalCard = CR.create("Tung Tung Tung Sahur", "Normal", nil, 7)
	mock.context = "server"
	check(limitedCard:FindFirstChild("Watermark", true) ~= nil and limitedCard:FindFirstChild("LimitedGlow", true) ~= nil, "une carte Limited devrait avoir son filigrane LIMITED et sa lueur dorée")
	check(normalCard:FindFirstChild("Watermark", true) == nil, "les cartes normales n'ont pas le design Limited")
	-- l'Index : les Limited sont SEULEMENT dans l'onglet LIMITED
	local indexWindow = hud:FindFirstChild("Index")
	local indexButton
	for _, b in ipairs(menu:GetChildren()) do
		if b:IsA("TextButton") and b.LayoutOrder == 2 then indexButton = b end
	end
	if indexButton then click(indexButton) end
	frames(0.2)
	local function tilesNamed(name)
		local n = 0
		for _, d in ipairs(indexWindow and indexWindow:GetDescendants() or {}) do
			if d.Name == name then n += 1 end
		end
		return n
	end
	local limitedInNormal = 0
	for _, d in ipairs(indexWindow and indexWindow:GetDescendants() or {}) do
		if d.Name == "CardName" and (d.Text == "Gorillo Avocadillo" or d.Text == "Gattino Smeraldino" or d.Text == "Cappuccina Principessa" or d.Text == "Ranapesce Gigante") then limitedInNormal += 1 end
	end
	check(tilesNamed("LimitedTile") == 0 and limitedInNormal == 0, "les Limited ne doivent pas être dans la grille normale de l'Index")
	local limitedTab = indexWindow and indexWindow:FindFirstChild("Tab_Limited", true)
	check(limitedTab ~= nil, "l'Index devrait avoir un onglet LIMITED")
	if limitedTab then click(limitedTab) end
	frames(0.2)
	check(tilesNamed("LimitedTile") == 4 and tilesNamed("ComingSoon") == 0, "l'onglet LIMITED devrait montrer les 4 cartes Limited (" .. tilesNamed("LimitedTile") .. ")")
	local normalTab = indexWindow and indexWindow:FindFirstChild("Tab_Normal", true)
	if normalTab then click(normalTab) end
	if indexButton then click(indexButton) end
	-- pas de ligne Limited dans le menu de vente
	check(hud:FindFirstChild("Sell_Limited", true) == nil, "le menu de vente ne doit pas proposer les Limited")
end

-- ====== 43. LE MONDE 2 (Nuit de Cristal) + le portail ======
do
	local GCfg = mock.moduleCache.server[RS.GameConfig].value
	local world2 = workspace:FindFirstChild("World2")
	check(world2 ~= nil, "le monde 2 devrait être construit")
	check(workspace:FindFirstChild("Mine2") and #workspace.Mine2.Blocks:GetChildren() == 32 * 32, "le monde 2 devrait avoir sa mine de cristal")
	local holograms = world2 and world2:FindFirstChild("Holograms")
	check(holograms and #holograms:GetChildren() == 11, "il devrait y avoir 11 statues hologrammes (les brainrots du monde 2)")
	check(world2 and world2:FindFirstChild("ReturnPortal") ~= nil, "il manque le portail de retour")
	local plots2 = 0
	for _, plot in ipairs(workspace.Plots:GetChildren()) do
		if plot:GetAttribute("World") == 2 then
			plots2 += 1
			check(plot:GetPivot().Position.Z > GCfg.WORLD_BORDER_Z, "les bases du monde 2 doivent être dans le monde 2")
		end
	end
	check(plots2 == 8, "il devrait y avoir 8 bases dans le monde 2 (" .. plots2 .. ")")

	-- le portail : touche E -> voyage -> la base déménage (avec les mêmes cartes)
	local PM = mock.moduleCache.server[serverScript.PortalManager].value
	check(PM.prompt ~= nil and PM.returnPrompt ~= nil, "les portails devraient avoir un bouton E")
	local placedBefore = 0
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) > 0 then placedBefore += 1 end
	end
	GCfg.PORTAL_FORCE_OPEN = true
	-- pas rebirth 10 : refusé
	local savedRebirths = adam2.leaderstats.Rebirths.Value
	adam2.leaderstats.Rebirths.Value = 9
	mock.getSignal(PM.prompt, "Triggered"):Fire(adam2)
	frames(2.5)
	check(adam2:GetAttribute("World") == 1, "il faut être REBIRTH 10 pour passer le portail")
	adam2.leaderstats.Rebirths.Value = 10
	mock.getSignal(PM.prompt, "Triggered"):Fire(adam2)
	frames(2.5)
	local myPlot
	for _, plot in ipairs(workspace.Plots:GetChildren()) do
		if plot:GetAttribute("OwnerId") == 1 then myPlot = plot end
	end
	check(adam2:GetAttribute("World") == 2 and myPlot and myPlot:GetAttribute("World") == 2, "après le portail, la base d'Adam devrait être dans le monde 2")
	check(adamChar2.HumanoidRootPart.Position.Z > GCfg.WORLD_BORDER_Z, "Adam devrait être téléporté dans le monde 2")
	local placedAfter = 0
	for _, item in ipairs(adam2.Brainrots:GetChildren()) do
		if (item:GetAttribute("Slot") or 0) > 0 then placedAfter += 1 end
	end
	check(placedAfter == placedBefore, "les cartes posées doivent suivre la base dans le monde 2")
	local cardsShown = 0
	for _, d in ipairs(myPlot and myPlot:GetDescendants() or {}) do
		if d.Name == "CardDisplay" then cardsShown += 1 end
	end
	check(placedBefore == 0 or cardsShown > 0, "les cartes devraient être affichées sur les podiums du monde 2")
	-- MINE et BASE téléportent dans le monde 2
	mock.getSignal(RS.RemoteEvents.Teleport, "OnServerEvent"):Fire(adam2, "mine")
	frames(0.2)
	check(adamChar2.HumanoidRootPart.Position.Z > GCfg.WORLD_BORDER_Z, "le bouton MINE devrait aller à la mine du monde 2")
	-- miner dans le monde 2 : 2x plus d'argent
	local MM = mock.moduleCache.server[serverScript.MineManager].value
	local block2 = workspace.Mine2.Blocks:GetChildren()[1]
	local result
	for _ = 1, 50 do
		result = MM.hit(block2, 1000, 99)
		if result then break end
	end
	check(result and result.world == 2, "les blocs de la mine 2 sont dans le monde 2")
	local MiningMod = mock.moduleCache.client[clientScript.Mining].value
	local seesMine2 = false
	for _, folder in ipairs(MiningMod.blockFolders) do
		if folder == workspace.Mine2.Blocks then seesMine2 = true end
	end
	check(seesMine2, "le joueur doit pouvoir viser (et miner) les blocs de la mine du monde 2")
	-- monde 2 : blocs 4500x plus solides, il faut une pioche du Vide minimum, et la pioche de cristal plus loin
	local block3 = workspace.Mine2.Blocks:GetChildren()[5]
	check(block3:GetAttribute("MaxHP") == 22500 and block3:GetAttribute("MinTier") == 10 and block3:GetAttribute("LayerName") == "Poussière d'étoiles", "monde 2 : ses propres couches (Poussière d'étoiles, 22500 PV, Pioche du Vide minimum)")
	check(#GCfg.LAYERS_W2 >= 10 and GCfg.LAYERS_W2[#GCfg.LAYERS_W2].To == 72 and GCfg.getLayer(70, 2).MinTier == 18, "la mine du monde 2 devrait avoir 72 couches, jusqu'à la Pioche Astrale")
	check(GCfg.MAX_REBIRTHS == 18 and #GCfg.REBIRTHS == 18, "18 rebirths (8 de plus pour les pioches de cristal)")
	for k = 11, 18 do
		check(GCfg.PICKAXES[k].RequiredRebirths == k, "la pioche " .. k .. " demande le rebirth " .. k)
	end
	local _, weak = MM.hit(block3, 100000, 5)
	check(weak ~= nil and string.find(weak, "Pioche du Vide", 1, true) ~= nil, "avec une petite pioche, le monde 2 demande la Pioche du Vide")
	-- la chance de la pioche est divisée par 22 dans le monde 2 : la Pioche Astrale y vaut à peu près la Cosmique du monde 1
	local LootMod = mock.moduleCache.server[serverScript.Loot].value
	local rare1, rare2 = 0, 0
	for _ = 1, 4000 do
		local c1 = GCfg.getCard((LootMod.rollMined(16, 30, false, 1)))
		local c2 = GCfg.getCard((LootMod.rollMined(352, 30, false, 2)))
		if GCfg.RARITIES[c1.Rarity].Order >= 5 then rare1 += 1 end
		if GCfg.RARITIES[c2.Rarity].Order >= 5 then rare2 += 1 end
		check(c2.World == 2, "dans le monde 2, on ne trouve que des brainrots du monde 2 (" .. c2.Name .. ")")
	end
	check(math.abs(rare1 - rare2) < 250, "même difficulté dans les 2 mondes (Légendaire+ : " .. rare1 .. " / " .. rare2 .. ")")
	-- la Cristallerie : acheter la 1re pioche de cristal
	local crystalShop = workspace:FindFirstChild("CrystalShop")
	check(crystalShop ~= nil and crystalShop:GetPivot().Position.Z > GCfg.WORLD_BORDER_Z, "la Cristallerie devrait être dans le monde 2")
	local savedTier = adam2.PickaxeTier.Value
	adam2.PickaxeTier.Value = 10
	adam2.leaderstats.Cash.Value = 1e9
	-- il faut le rebirth 11 pour la 1re pioche de cristal
	adamChar2:PivotTo(mock.CFrame.new(crystalShop.Counter.Position + mock.Vector3.new(0, 2, -4)))
	frames(0.2)
	mock.getSignal(RS.RemoteEvents.BuyPickaxe, "OnServerEvent"):Fire(adam2, 11)
	frames(0.3)
	check(adam2.PickaxeTier.Value == 10, "la Pioche de Cristal demande le rebirth 11")
	adam2.leaderstats.Rebirths.Value = 11
	adamChar2:PivotTo(mock.CFrame.new(crystalShop.Counter.Position + mock.Vector3.new(0, 2, -4)))
	frames(0.2)
	mock.getSignal(RS.RemoteEvents.BuyPickaxe, "OnServerEvent"):Fire(adam2, 11)
	frames(0.3)
	check(adam2.PickaxeTier.Value == 11, "on devrait pouvoir acheter la Pioche de Cristal à la Cristallerie")
	local tool = adamChar2:FindFirstChild("Pioche") or adam2.Backpack:FindFirstChild("Pioche")
	check(tool and tool:FindFirstChild("CrystalShards", true) ~= nil and tool:FindFirstChild("CrystalTrail", true) ~= nil, "la pioche de cristal devrait avoir des particules et une traînée")
	adam2.PickaxeTier.Value = savedTier
	adam2.leaderstats.Rebirths.Value = savedRebirths
	-- l'animation de voyage (client)
	local PortalMod = mock.moduleCache.client[clientScript.Portal].value
	mock.context = "client"
	PortalMod.start({To = 2, Name = "Nuit de Cristal"})
	mock.context = "server"
	frames(0.5)
	local warp
	for _, c in ipairs(adam.PlayerGui:GetChildren()) do
		if c.Name == "PortalWarp" and c:FindFirstChild("WarpTitle") then warp = c end
	end
	check(warp ~= nil and warp:FindFirstChild("WarpTitle") ~= nil, "le voyage devrait afficher une animation")
	mock.context = "client"
	PortalMod.arrive({To = 2, Name = "Nuit de Cristal"})
	mock.context = "server"
	frames(0.3)
	check(warp and warp:FindFirstChild("WelcomeWorld") ~= nil, "à l'arrivée : BIENVENUE DANS ...")
	frames(4)
	check(warp.Parent == nil, "l'animation devrait disparaître après l'arrivée")
	-- retour au monde 1
	mock.getSignal(PM.returnPrompt, "Triggered"):Fire(adam2)
	frames(2.5)
	check(adam2:GetAttribute("World") == 1 and adamChar2.HumanoidRootPart.Position.Z < GCfg.WORLD_BORDER_Z, "le portail de retour ramène au monde 1")
	-- avec un brainrot volé : pas de voyage
	GCfg.PORTAL_FORCE_OPEN = nil
end

-- ====== 44. TÉLÉPHONE : le joystick (bas gauche) et la caméra (doigt qui glisse) ne minent pas ======
do
	local P = mock.moduleCache.client[clientScript.Pointer].value
	local UIS = mock.getService("UserInputService")
	local function touch(x, y)
		return {UserInputType = Enum.UserInputType.Touch, Position = mock.Vector3.new(x, y, 0)}
	end
	check(P.isControlZone(mock.Vector2.new(100, 650)) and P.isControlZone(mock.Vector2.new(1200, 650)), "bas gauche (joystick) et bas droite (saut) = zones de contrôle")
	check(not P.isControlZone(mock.Vector2.new(640, 300)), "le milieu de l'écran sert à viser")
	-- doigt sur le joystick : pas de minage
	local joy = touch(120, 620)
	mock.context = "client"
	mock.getSignal(UIS, "InputBegan"):Fire(joy, false)
	mock.context = "server"
	frames(0.4)
	check(not P.isHoldingAim(), "le joystick ne doit pas miner")
	mock.context = "client"
	mock.getSignal(UIS, "InputEnded"):Fire(joy)
	mock.context = "server"
	check(not P.consumeTap(), "lâcher le joystick ne doit pas faire de coup")
	-- doigt qui glisse (caméra) : pas de minage
	local cam = touch(700, 300)
	mock.context = "client"
	mock.getSignal(UIS, "InputBegan"):Fire(cam, false)
	cam.Position = mock.Vector3.new(780, 320, 0)
	mock.getSignal(UIS, "InputChanged"):Fire(cam)
	mock.context = "server"
	frames(0.4)
	check(not P.isHoldingAim(), "tourner la caméra ne doit pas miner")
	mock.context = "client"
	mock.getSignal(UIS, "InputEnded"):Fire(cam)
	mock.context = "server"
	check(not P.consumeTap(), "un glissement n'est pas un tap")
	-- doigt posé sans bouger au milieu : on mine ; petit tap : un coup
	local aim = touch(640, 300)
	mock.context = "client"
	mock.getSignal(UIS, "InputBegan"):Fire(aim, false)
	mock.context = "server"
	frames(0.4)
	check(P.isHoldingAim(), "doigt posé au milieu sans bouger : on mine")
	mock.context = "client"
	mock.getSignal(UIS, "InputEnded"):Fire(aim)
	local tap = touch(600, 280)
	mock.getSignal(UIS, "InputBegan"):Fire(tap, false)
	mock.getSignal(UIS, "InputEnded"):Fire(tap)
	mock.context = "server"
	check(P.consumeTap() and not P.consumeTap(), "un tap = un seul coup de pioche")
	-- les cartes : ruban du nom, ombre du personnage, billet vert
	local CR = mock.moduleCache.client[RS.CardRenderer].value
	mock.context = "client"
	local cardFrame = CR.create("Leonelli Cactuselli", "Normal", nil, 3)
	mock.context = "server"
	check(cardFrame and cardFrame:FindFirstChild("NamePlate", true) and cardFrame:FindFirstChild("ArtShadow", true) and cardFrame:FindFirstChild("FloorShadow", true), "les cartes devraient avoir un ruban, une ombre et une ombre au sol")
	local sparkles = 0
	for _, d in ipairs(cardFrame:GetDescendants()) do
		if d.Name == "Sparkle" then sparkles += 1 end
	end
	check(sparkles >= 3, "une Légendaire devrait scintiller")
end

-- ====== 45. OG : chance FIXE (la même avec toutes les pioches) ======
do
	local LootMod = mock.moduleCache.server[serverScript.Loot].value
	local function ogRate(luck, layer, potion)
		local count = 0
		for _ = 1, 600000 do
			if LootMod.rollRarity(luck * (1 + (layer - 1) * 0.03), potion) == "OG" then count += 1 end
		end
		return count / 600000
	end
	local wood = ogRate(1, 1, false)
	local astral = ogRate(352, 60, true)
	print("Chance OG : bois surface", wood, " astrale au fond + potion", astral)
	check(wood > 0.00005 and wood < 0.00012 and astral > 0.00005 and astral < 0.00012, "l'OG devrait être 1 sur 12000 avec n'importe quelle pioche")
end

-- ====== 42. VRAI JEU : un inconnu qui arrive pour la 1re fois n'a RIEN de payant gratuitement ======
do
	local GCfg = mock.moduleCache.server[RS.GameConfig].value
	local MS = game:GetService("MarketplaceService")
	mock.studio = false -- on n'est plus dans Studio : plus d'achats gratuits, plus d'admin pour tous
	-- de vrais ID, comme dans le jeu publié
	GCfg.GAMEPASSES.VIP.GamePassId = 1998357389
	GCfg.GAMEPASSES.DoubleCash.GamePassId = 1999701304
	GCfg.BOOSTERS[6].ProductId = 3715325306
	local rando = addPlayer("Rando", 777)
	frames(1)
	local paid = {"VIP", "DoubleCash", "FlyingCarpet", "AutoCollect", "DivinePickaxe", "VIPMinerals"}
	local function hasPaidStuff()
		for _, key in ipairs(paid) do
			if rando:GetAttribute(key) == true then return key end
		end
		return nil
	end
	check(hasPaidStuff() == nil, "un nouveau joueur ne doit rien avoir de payant (" .. tostring(hasPaidStuff()) .. ")")
	local cardsBefore = #rando.Brainrots:GetChildren()
	-- il essaie les commandes admin : refusé
	for _, command in ipairs({"/vip", "/all", "/x2", "/carpet", "/autocollect", "/pioche", "/cash 1b", "/give sahur", "/admin @Rando"}) do
		chat(rando, command)
	end
	frames(0.3)
	check(hasPaidStuff() == nil and rando.leaderstats.Cash.Value < 1e9, "un joueur normal ne doit pas pouvoir utiliser les commandes admin (" .. tostring(hasPaidStuff()) .. ")")
	-- il clique sur acheter : Roblox lui demande de payer, rien n'est donné avant
	mock.prompts = {}
	mock.getSignal(RS.RemoteEvents.BuyProduct, "OnServerEvent"):Fire(rando, "VIP")
	mock.getSignal(RS.RemoteEvents.BuyProduct, "OnServerEvent"):Fire(rando, "DoubleCash")
	mock.getSignal(RS.RemoteEvents.BuyBooster, "OnServerEvent"):Fire(rando, "Celeste")
	frames(0.3)
	check(#mock.prompts == 3, "cliquer sur acheter devrait ouvrir la fenêtre de paiement Roblox (" .. #mock.prompts .. ")")
	check(hasPaidStuff() == nil and #rando.Brainrots:GetChildren() == cardsBefore, "rien ne doit être donné avant d'avoir payé")
	-- il ferme la fenêtre sans payer : toujours rien
	mock.getSignal(MS, "PromptGamePassPurchaseFinished"):Fire(rando, 1998357389, false)
	frames(0.3)
	check(rando:GetAttribute("VIP") ~= true, "fermer la fenêtre sans payer ne doit pas donner le VIP")
	-- il paie vraiment : il reçoit le VIP
	mock.getSignal(MS, "PromptGamePassPurchaseFinished"):Fire(rando, 1998357389, true)
	frames(0.5)
	check(rando:GetAttribute("VIP") == true, "après avoir payé, le VIP devrait être donné")
	mock.studio = nil
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
