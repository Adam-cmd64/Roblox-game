-- ModuleScript client : OÙ LE JOUEUR VISE, sur PC comme sur téléphone.
--   PC : la souris.
--   Téléphone / tablette : l'endroit où le doigt a touché l'écran en dernier
--   (sur un écran tactile, la position de la "souris" n'est pas fiable).

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Pointer = {}

local lastTouch = nil -- Vector2, en coordonnées "écran" (sans la barre du haut de Roblox)
local usingTouch = false

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Touch then
		if not processed then
			lastTouch = Vector2.new(input.Position.X, input.Position.Y)
			usingTouch = true
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseMovement then
		usingTouch = false
	end
end)
UserInputService.InputChanged:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Touch and not processed then
		lastTouch = Vector2.new(input.Position.X, input.Position.Y)
		usingTouch = true
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		usingTouch = false
	end
end)

-- true si le joueur joue au doigt (téléphone / tablette sans clavier)
function Pointer.isTouch()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
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
