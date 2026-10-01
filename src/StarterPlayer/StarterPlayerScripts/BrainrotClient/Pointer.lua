-- ModuleScript client : OÙ LE JOUEUR VISE, sur PC comme sur téléphone.
--   PC : la souris.
--   Téléphone / tablette : l'endroit où le doigt "vise" (pas le joystick, pas la caméra).
--
-- TÉLÉPHONE / TABLETTE (comme dans les autres jeux) :
--   - la ZONE DE DÉPLACEMENT en bas à gauche (le joystick) et la zone du SAUT en bas à droite
--     ne cassent JAMAIS de bloc ;
--   - si le doigt GLISSE (on tourne la caméra), ça ne casse rien non plus ;
--   - on mine en APPUYANT sans bouger (tap = 1 coup, doigt posé = on continue de miner).

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Pointer = {}

local MOVE_ZONE = {Right = 0.42, Top = 0.42} -- bas à gauche : x < 42 % de l'écran, y > 42 %
local JUMP_ZONE = {Left = 0.74, Top = 0.55} -- bas à droite : le bouton de saut
local DRAG_PIXELS = 16 -- au-delà, c'est la caméra qui tourne
local HOLD_DELAY = 0.18 -- doigt posé (sans bouger) depuis ce temps-là : on mine
local TAP_MAX = 0.35 -- un tap plus court que ça = 1 coup

local lastTouch = nil -- Vector2, en coordonnées "écran" (sans la barre du haut de Roblox)
local usingTouch = false
local touches = {} -- touches[input] = {start, began, moved, control}
local pendingTap = false

local function viewport()
	local camera = Workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- Ce point est-il dans la zone du joystick (bas gauche) ou du saut (bas droite) ?
function Pointer.isControlZone(position)
	local size = viewport()
	local x, y = position.X / size.X, position.Y / size.Y
	if x < MOVE_ZONE.Right and y > MOVE_ZONE.Top then
		return true
	end
	if x > JUMP_ZONE.Left and y > JUMP_ZONE.Top then
		return true
	end
	return false
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Touch then
		usingTouch = true
		if processed then return end -- un bouton de l'interface
		local position = Vector2.new(input.Position.X, input.Position.Y)
		local control = Pointer.isControlZone(position)
		touches[input] = {start = position, began = os.clock(), moved = false, control = control}
		if not control then
			lastTouch = position
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseMovement then
		usingTouch = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local touch = touches[input]
		if not touch or touch.control then return end
		local position = Vector2.new(input.Position.X, input.Position.Y)
		if (position - touch.start).Magnitude > DRAG_PIXELS then
			touch.moved = true -- le doigt glisse : c'est la caméra, on ne mine pas
		end
		if not touch.moved then
			lastTouch = position
		end
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		usingTouch = false
	end
end)
UserInputService.InputEnded:Connect(function(input)
	local touch = touches[input]
	if not touch then return end
	touches[input] = nil
	if not touch.control and not touch.moved and os.clock() - touch.began <= TAP_MAX then
		pendingTap = true -- un petit tap : un coup de pioche
	end
end)

-- true si le joueur joue au doigt (téléphone / tablette sans clavier)
function Pointer.isTouch()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Un doigt est posé hors des zones de contrôle, sans glisser, depuis assez longtemps : on mine
function Pointer.isHoldingAim()
	local now = os.clock()
	for _, touch in pairs(touches) do
		if not touch.control and not touch.moved and now - touch.began >= HOLD_DELAY then
			return true
		end
	end
	return false
end

-- Un tap vient d'être fait (renvoie true une seule fois)
function Pointer.consumeTap()
	local tapped = pendingTap
	pendingTap = false
	return tapped
end

-- Le rayon qui part de la caméra vers l'endroit visé
function Pointer.ray()
	local camera = Workspace.CurrentCamera
	if not camera then return nil end
	if usingTouch and lastTouch then
		return camera:ScreenPointToRay(lastTouch.X, lastTouch.Y)
	end
	local mouse = UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(mouse.X, mouse.Y)
end

return Pointer
