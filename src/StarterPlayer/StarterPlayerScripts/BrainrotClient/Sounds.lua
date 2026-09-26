-- ModuleScript client : joue les sons du jeu (définis dans GameConfig.SOUNDS).
-- Tous les sons sont rangés dans un seul fichier audio (GameConfig.SOUND_FILE) :
-- chaque son ne joue que son morceau du fichier (PlaybackRegion).
-- Petite variation de hauteur à chaque fois pour que ce ne soit jamais répétitif.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Sounds = {}

local file = GameConfig.assetId(GameConfig.SOUND_FILE)
local templates = {}
for name, info in pairs(GameConfig.SOUNDS) do
	local own = GameConfig.assetId(info.Id)
	if own ~= "" or file ~= "" then
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.Volume = info.Volume
		sound.PlaybackSpeed = info.Pitch or 1
		if own ~= "" then
			sound.SoundId = own
		else
			sound.SoundId = file
			sound.PlaybackRegionsEnabled = true
			sound.PlaybackRegion = NumberRange.new(info.Start, info.Start + info.Length)
		end
		sound.Parent = SoundService
		templates[name] = sound
	end
end

-- Joue un son. Avec "position", le son vient de cet endroit du monde (on l'entend moins de loin).
function Sounds.play(name, position, pitchScale)
	local template = templates[name]
	if not template then return end
	local info = GameConfig.SOUNDS[name]
	local sound = template:Clone()
	sound.PlaybackSpeed = (info.Pitch or 1) * (pitchScale or 1) * (0.94 + math.random() * 0.12)
	local lifetime = (info.Length or 2) + 1.5
	if position then
		local anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.Position = position
		anchor.Parent = Workspace
		sound.RollOffMaxDistance = 120
		sound.Parent = anchor
		sound:Play()
		Debris:AddItem(anchor, lifetime)
	else
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, lifetime)
	end
end

return Sounds
