-- ModuleScript client : le VIP dans le CHAT.
-- Les messages des joueurs VIP ont "[👑 VIP]" en doré devant le nom, et le texte en vert.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Vip = {}

local GOLD = "#FFD23C"
local GREEN = "#5CFF6E"

function Vip.init()
	pcall(function()
		TextChatService.OnIncomingMessage = function(message)
			local properties = Instance.new("TextChatMessageProperties")
			local source = message.TextSource
			local sender = source and Players:GetPlayerByUserId(source.UserId)
			if sender and sender:GetAttribute("VIP") == true then
				properties.PrefixText = "<font color='" .. GOLD .. "'>[👑 VIP]</font> " .. message.PrefixText
				properties.Text = "<font color='" .. GREEN .. "'>" .. message.Text .. "</font>"
			end
			return properties
		end
	end)
end

return Vip
