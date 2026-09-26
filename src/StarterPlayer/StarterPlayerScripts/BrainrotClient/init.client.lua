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

Effects.init()
Mining.init()
World.init()
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

-- On cache le classement Roblox par défaut : le HUD affiche déjà tout
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)
