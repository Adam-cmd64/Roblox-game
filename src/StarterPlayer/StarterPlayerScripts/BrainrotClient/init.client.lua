-- Script client principal : il démarre tous les modules de l'interface et relie les boutons.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local UIKit = require(script.UIKit)
local Effects = require(script.Effects)
local Hud = require(script.Hud)
local Panels = require(script.Panels)
local Trade = require(script.Trade)
local Wheel = require(script.Wheel)
local Mining = require(script.Mining)
local World = require(script.World)
local Sky = require(script.Sky)

Effects.init()
Mining.init()
World.init()
Sky.init()
Trade.init(Hud)
Wheel.init(Panels, Hud)

-- ====== MENU ======
local buttons = Hud.buttons
buttons.base.MouseButton1Click:Connect(function()
	UIKit.closeAll()
	Remotes.Teleport:FireServer("base")
end)
buttons.mine.MouseButton1Click:Connect(function()
	UIKit.closeAll()
	Remotes.Teleport:FireServer("mine")
end)
buttons.inventory.MouseButton1Click:Connect(Panels.inventory.toggle)
buttons.index.MouseButton1Click:Connect(Panels.index.toggle)
buttons.rebirth.MouseButton1Click:Connect(Panels.rebirth.toggle)
buttons.trade.MouseButton1Click:Connect(Trade.window.toggle)
buttons.boosters.MouseButton1Click:Connect(Panels.boosters.toggle)

-- ====== EVENEMENTS DU SERVEUR ======
Remotes.Notify.OnClientEvent:Connect(Hud.notify)
Remotes.CardFound.OnClientEvent:Connect(Hud.showCardFound)
Remotes.OpenShop.OnClientEvent:Connect(Panels.shop.open)
Remotes.OpenBatShop.OnClientEvent:Connect(Panels.armory.open)
Remotes.BoosterOpened.OnClientEvent:Connect(Panels.openBooster)
Remotes.Collected.OnClientEvent:Connect(Hud.collected)

-- ====== ANNONCES DANS LE CHAT : "Adam a pack un OG : Lucky Block Arc-en-ciel #1 !" ======
local TextChatService = game:GetService("TextChatService")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RAINBOW = {"#ff4040", "#ffc828", "#50ff50", "#28c8ff", "#7850ff", "#ff3cc8"}

local function hex(color)
	return string.format("#%02x%02x%02x", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end
local function rainbowText(text)
	local out, i = {}, 0
	for _, char in utf8.codes(text) do
		i += 1
		table.insert(out, string.format('<font color="%s">%s</font>', RAINBOW[(i - 1) % #RAINBOW + 1], utf8.char(char)))
	end
	return table.concat(out)
end

Remotes.Announce.OnClientEvent:Connect(function(playerName, verb, cardName, mutation, serial)
	local card = GameConfig.getCard(cardName)
	if not card then return end
	local rarity = GameConfig.RARITIES[card.Rarity]
	local rarityText = GameConfig.upper(card.Rarity)
	rarityText = rarity.Order >= 13 and rainbowText(rarityText) or string.format('<font color="%s">%s</font>', hex(rarity.Color), rarityText)
	local mutationText = ""
	if mutation and mutation ~= "Normal" and GameConfig.MUTATIONS[mutation] then
		local mutationData = GameConfig.MUTATIONS[mutation]
		mutationText = mutationData.Rainbow and (" " .. rainbowText("[" .. mutation .. "]")) or string.format(' <font color="%s">[%s]</font>', hex(mutationData.Colors[1]), mutation)
	end
	local message = string.format('<b>🌟 <font color="#ffffff">%s</font> %s un %s : <font color="%s">%s</font>%s%s !</b>',
		playerName, verb, rarityText, hex(rarity.Color:Lerp(Color3.new(1, 1, 1), 0.3)), cardName, mutationText,
		(serial and serial > 0) and (" #" .. serial) or "")
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general then
			general:DisplaySystemMessage(message)
		end
	end)
	Hud.notify(playerName .. " " .. verb .. " un " .. GameConfig.upper(card.Rarity) .. " : " .. cardName .. " !", "success")
end)

-- On cache le classement Roblox par défaut : le HUD affiche déjà tout
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)
