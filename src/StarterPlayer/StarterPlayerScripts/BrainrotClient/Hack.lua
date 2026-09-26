-- ModuleScript client : le mini-jeu de PIRATAGE des lasers.
-- Le serveur envoie les fils et l'ordre à couper. On clique sur les fils dans le bon ordre avant la fin du temps.
-- C'est le serveur qui vérifie chaque coupe (impossible de tricher).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local UIKit = require(script.Parent.UIKit)
local Sounds = require(script.Parent.Sounds)
local T = UIKit.Theme

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local Hack = {}

local current -- {frame, connection}

local function close()
	if not current then return end
	if current.connection then
		current.connection:Disconnect()
	end
	current.frame:Destroy()
	current = nil
end

local function open(info)
	close()
	local frame = Instance.new("Frame")
	frame.Name = "HackGame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 560, 0, 440)
	frame.BackgroundColor3 = Color3.fromRGB(12, 18, 16)
	frame.ZIndex = 60
	frame.Parent = UIKit.ScreenGui
	UIKit.corner(frame, 18)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 255, 140)
	stroke.Thickness = 3
	stroke.Parent = frame

	UIKit.label(frame, "🔓 PIRATAGE DES LASERS", {Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 10), Font = UIKit.TitleFont, TextColor3 = Color3.fromRGB(60, 255, 140), ZIndex = 61})
	local orderLabel = UIKit.label(frame, "Coupe dans l'ordre : " .. table.concat(info.Order, " → "), {
		Size = UDim2.new(0.92, 0, 0, 30),
		Position = UDim2.new(0.04, 0, 0, 54),
		Font = UIKit.TitleFont,
		TextWrapped = true,
		ZIndex = 61,
	})
	if info.Memorize then
		task.delay(3, function()
			if orderLabel.Parent then
				orderLabel.Text = "Tu as mémorisé l'ordre ? Vas-y !"
			end
		end)
	end

	-- barre de temps
	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.new(0.04, 0, 0, 92)
	barBack.Size = UDim2.new(0.92, 0, 0, 12)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 50, 45)
	barBack.ZIndex = 61
	barBack.Parent = frame
	UIKit.corner(barBack, 6)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(60, 255, 140)
	bar.ZIndex = 62
	bar.Parent = barBack
	UIKit.corner(bar, 6)
	TweenService:Create(bar, TweenInfo.new(info.Time, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 60, 60)}):Play()

	-- les fils
	local wireArea = Instance.new("Frame")
	wireArea.Position = UDim2.new(0.04, 0, 0, 118)
	wireArea.Size = UDim2.new(0.92, 0, 0, 250)
	wireArea.BackgroundTransparency = 1
	wireArea.ZIndex = 61
	wireArea.Parent = frame
	local count = #info.Wires
	for index, wire in ipairs(info.Wires) do
		local button = Instance.new("TextButton")
		button.Name = "Wire" .. index
		button.Text = ""
		button.AutoButtonColor = false
		button.Position = UDim2.new(0, 0, (index - 1) / count, 4)
		button.Size = UDim2.new(1, 0, 1 / count, -8)
		button.BackgroundTransparency = 1
		button.ZIndex = 62
		button.Parent = wireArea
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.Position = UDim2.new(0, 70, 0.5, 0)
		line.Size = UDim2.new(1, -140, 0, 12)
		line.BackgroundColor3 = wire.Color
		line.ZIndex = 63
		line.Parent = button
		UIKit.corner(line, 6)
		for _, x in ipairs({0, 1}) do
			local plug = Instance.new("Frame")
			plug.AnchorPoint = Vector2.new(x, 0.5)
			plug.Position = UDim2.new(x, x == 0 and 40 or -40, 0.5, 0)
			plug.Size = UDim2.new(0, 34, 0, 26)
			plug.BackgroundColor3 = Color3.fromRGB(90, 95, 100)
			plug.ZIndex = 63
			plug.Parent = button
			UIKit.corner(plug, 6)
		end
		UIKit.label(button, wire.Name, {Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(0.5, -35, 0, -20), Font = UIKit.TitleFont, TextColor3 = wire.Color, ZIndex = 64})
		button.MouseButton1Click:Connect(function()
			if button:GetAttribute("Cut") then return end
			button:SetAttribute("Cut", true)
			-- le fil est coupé en deux
			line.Size = UDim2.new(0.45, -70, 0, 12)
			local other = line:Clone()
			other.AnchorPoint = Vector2.new(1, 0.5)
			other.Position = UDim2.new(1, -70, 0.5, 0)
			other.Parent = button
			Sounds.play("Click")
			Remotes.Hack:FireServer("cut", index)
		end)
	end

	local cancel = UIKit.button(frame, "ABANDONNER", T.Red, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0, 220, 0, 44),
		ZIndex = 62,
	})
	cancel.MouseButton1Click:Connect(function()
		Remotes.Hack:FireServer("cancel")
		close()
	end)

	current = {frame = frame, orderLabel = orderLabel}
	current.connection = RunService.RenderStepped:Connect(function()
		stroke.Transparency = 0.3 + math.sin(os.clock() * 6) * 0.3
	end)
end

local function flash(text, color)
	if not current then return end
	local frame = current.frame
	UIKit.label(frame, text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.9, 0, 0, 70),
		Font = UIKit.TitleFont,
		TextColor3 = color,
		ZIndex = 70,
	})
	task.delay(1.2, close)
end

function Hack.init()
	Remotes.Hack.OnClientEvent:Connect(function(kind, payload)
		if kind == "start" then
			open(payload)
		elseif kind == "success" then
			Sounds.play("Win")
			flash("ACCÈS AUTORISÉ !", Color3.fromRGB(60, 255, 140))
		elseif kind == "fail" then
			Sounds.play("BatHit")
			flash(tostring(payload or "ÉCHEC"), Color3.fromRGB(255, 70, 70))
		end
	end)
end

return Hack
