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
	source = (source:gsub('GameConfig.SOUND_FILE = ""', 'GameConfig.SOUND_FILE = "1111"'))
	source = (source:gsub('\t"", %-%- ID de cartes1', '\t"2222", -- ID de cartes1'))
	source = (source:gsub('\t"", %-%- ID de cartes2', '\t"rbxassetid://3333", -- ID de cartes2'))
	source = (source:gsub('\t"", %-%- ID de cartes3', '\t"4444", -- ID de cartes3'))
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
for _, name in ipairs({"Remotes", "PlayerData", "Loot", "MineManager", "BaseManager", "ShopManager", "Monetization", "TradeManager", "WorldBuilder", "AdminCommands", "PickaxeBuilder", "BatManager", "WheelManager"}) do
	module(serverScript, name, "src/ServerScriptService/BrainrotServer/" .. name .. ".lua")
end

local SP = mock.getService("StarterPlayer")
local SPS = new("StarterPlayerScripts", "StarterPlayerScripts", SP)
local clientScript = new("LocalScript", "BrainrotClient", SPS)
for _, name in ipairs({"UIKit", "Hud", "Panels", "Trade", "Mining", "World", "Sounds", "Effects", "Wheel"}) do
	module(clientScript, name, "src/StarterPlayer/StarterPlayerScripts/BrainrotClient/" .. name .. ".lua")
end

-- ====== 1. Démarrage du serveur ======
mock.runScript(serverScript, "src/ServerScriptService/BrainrotServer/init.server.lua", "server")
mock.runFor(1)
check(data[baseplate].destroyed, "la Baseplate aurait dû être supprimée")
check(workspace:FindFirstChild("Plots") ~= nil, "pas de dossier Plots")
check(workspace:FindFirstChild("Mine") ~= nil, "pas de Mine")
local blocks = workspace.Mine.Blocks
check(#blocks:GetChildren() == 26 * 26, "la mine devrait avoir 26x26 blocs en surface, a " .. #blocks:GetChildren())

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
chat(adam, "/give graipuss arc-en-ciel")
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
local expectedAtlas = ATLAS_IDS[(placedIndex - 1) // 18 + 1]
check(art ~= nil and art.Image == expectedAtlas, "l'illustration de " .. tostring(placedName) .. " devrait venir de " .. tostring(expectedAtlas) .. " (a " .. tostring(art and art.Image) .. ")")
check(art ~= nil and art.ImageRectSize.X == 170, "l'illustration devrait être découpée dans l'atlas")
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
chat(adam, "/give laril")
chat(adam, "/give boneca")
chat(adam, "/give pesciolone")
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
local shopPrompt = workspace.Shop.Counter:FindFirstChild("PickaxePrompt")
check(shopPrompt ~= nil and shopPrompt.KeyboardKeyCode == Enum.KeyCode.E, "pas de bouton E (pioches) à la boutique")
adamChar:PivotTo(mock.CFrame.new(shopPrompt.Parent.Position + V3(0, 0, 0)))
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

-- ====== 12. Régénération de la mine ======
mock.runFor(620)
check(#blocks:GetChildren() == 26 * 26, "la mine ne s'est pas régénérée (" .. #blocks:GetChildren() .. " blocs)")

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
local adam2 = addPlayer("Adam", 1)
frames(1)
print("Après reconnexion : cash", adam2.leaderstats.Cash.Value, "cartes", #adam2.Brainrots:GetChildren(), "rebirths", adam2.leaderstats.Rebirths.Value)
check(adam2.leaderstats.Cash.Value >= savedCash, "le cash n'a pas été sauvegardé")
check(#adam2.Brainrots:GetChildren() == savedCount, "les cartes n'ont pas été sauvegardées")
check(adam2.leaderstats.Rebirths.Value == 2, "les rebirths n'ont pas été sauvegardés")


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
local laserB = plotB.Lasers:GetChildren()[1]
check(laserB.CanCollide == true and laserB.Transparency == 0, "les lasers de Bob devraient bloquer Adam")
check(plotB:GetAttribute("LockedUntil") > mock.now, "la base de Bob devrait être verrouillée")

-- Adam pose une carte, Bob la vole
chat(adam2, "/give bombardiro")
local target
for _, item in ipairs(adam2.Brainrots:GetChildren()) do
	if item.Value == "Bombardiro Crocodilo" then target = item end
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
check(target:GetAttribute("Slot") == -1 and bob2:GetAttribute("Carrying") == "Bombardiro Crocodilo", "le vol n'a pas démarré")
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
check(target.Parent == adam2.Brainrots and target:GetAttribute("Slot") == 1, "la batte n'a pas fait lâcher le brainrot")
check(bob2:GetAttribute("Carrying") == nil, "Bob porte encore le brainrot")
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
frames(1)
check(wheel:GetAttribute("SpinId") == 1, "la roue n'a pas démarré")
check((disc:GetPivot().Position - pivotBefore.Position).Magnitude < 0.01, "la roue devrait tourner autour de son axe")
check((disc:GetPivot().UpVector - pivotBefore.UpVector).Magnitude > 0.01, "la roue ne tourne pas côté client")
frames(6)
local after16 = adam2.leaderstats.Cash.Value + #adam2.Brainrots:GetChildren() + (adam2:GetAttribute("LuckUntil") or 0)
check(after16 > before16, "la roue n'a rien donné")
check((adam2:GetAttribute("LastFreeSpin") or 0) > 0, "le tour gratuit n'a pas été utilisé")
-- tour acheté, avec le bouton de la fenêtre
chat(adam2, "/spins 1")
if wheelButton then click(wheelButton) end
frames(7)
check(adam2.Spins.Value == 0, "le tour payé n'a pas été utilisé")
-- trop loin : refusé
chat(adam2, "/spins 1")
adamChar2:PivotTo(mock.CFrame.new(0, 5, 0))
mock.context = "client"
RS.RemoteEvents.SpinWheel:FireServer()
mock.context = "server"
frames(0.5)
check(adam2.Spins.Value == 1, "on ne devrait pas pouvoir tourner la roue de loin")

-- ====== 17. Potion + bonus d'index ======
mock.context = "client"
RS.RemoteEvents.BuyProduct:FireServer("LuckPotion")
mock.context = "server"
frames(0.3)
check((adam2:GetAttribute("LuckUntil") or 0) > os.time(), "la potion ne s'est pas activée")
for _, name in ipairs({"laril", "boneca", "pesciolone", "cetriolino", "caffettino", "teierina"}) do
	chat(adam2, "/give " .. name)
end
local GameConfigModule = mock.moduleCache.server[RS.GameConfig].value
check(GameConfigModule.getIndexBonus(GameConfigModule.getDiscovered(adam2)) >= 0.05, "le bonus d'index Commun n'est pas actif")

-- ====== 18. Battes (touche F à la boutique) ======
local armoryPrompt = workspace.Shop.Counter:FindFirstChild("BatPrompt")
check(armoryPrompt ~= nil and armoryPrompt.KeyboardKeyCode == Enum.KeyCode.F, "pas de bouton F (battes) à la boutique")
adamChar2:PivotTo(mock.CFrame.new(armoryPrompt.Parent.Position))
mock.getSignal(armoryPrompt, "Triggered"):Fire(adam2)
frames(0.5)
chat(adam2, "/cash 100000")
local batBuy
for _, b in ipairs(hud:GetDescendants()) do
	if b:IsA("TextButton") and b.Text == "$25K" then batBuy = b end
end
check(batBuy ~= nil, "l'armurerie ne s'est pas ouverte")
if batBuy then click(batBuy) end
check(adam2.BatTier.Value == 2, "l'achat de la batte a échoué")

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
